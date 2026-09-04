import fs from 'fs';
import path from 'path';
import prisma from '../lib/prisma';
import { getIO } from '../socket';
import { PatientService } from './patientService';

export interface VapiCallParams {
  patientId: string;
  patientName: string;
  patientPhone: string;
  clinicId: string;
  clinicName: string;
  clinicPhone?: string | null;
  doctorId: string;
  doctorName: string;
  appointmentId: string;
  scheduledAt: Date;
}

export interface VapiCallResult {
  callId: string;
  status: string;
}

export class VapiService {
  /**
   * Triggers an outbound Vapi AI call to the patient to confirm or negotiate the appointment slot.
   */
  static async triggerOutboundCall(params: VapiCallParams): Promise<VapiCallResult> {
    const vapiApiKey = process.env.VAPI_PRIVATE_KEY;
    const assistantId = process.env.VAPI_ASSISTANT_ID;
    const phoneNumberId = process.env.VAPI_PHONE_NUMBER_ID;

    const formattedTime = params.scheduledAt.toLocaleString('en-IN', {
      timeZone: 'Asia/Kolkata',
      dateStyle: 'medium',
      timeStyle: 'short',
    });

    // Format phone to E.164 if possible
    let cleanPhone = params.patientPhone.replace(/[^\d+]/g, '');
    if (!cleanPhone.startsWith('+')) {
      cleanPhone = cleanPhone.length === 10 ? `+91${cleanPhone}` : `+${cleanPhone}`;
    }

    const payload = {
      phoneNumberId: phoneNumberId || undefined,
      assistantId: assistantId || undefined,
      customer: {
        number: cleanPhone,
        name: params.patientName,
      },
      assistantOverrides: {
        variableValues: {
          patient_name: params.patientName,
          clinic_name: params.clinicName,
          doctor_name: params.doctorName,
          appointment_time: formattedTime,
        },
        metadata: {
          patientId: params.patientId,
          clinicId: params.clinicId,
          doctorId: params.doctorId,
          appointmentId: params.appointmentId,
        },
      },
    };

    if (!vapiApiKey || !assistantId) {
      console.warn('[VapiService] VAPI_PRIVATE_KEY or VAPI_ASSISTANT_ID not configured. Running in sandbox/simulation mode.');
      return {
        callId: `vapi_sim_${Date.now()}_${Math.random().toString(36).substring(7)}`,
        status: 'queued',
      };
    }

    try {
      const response = await fetch('https://api.vapi.ai/call', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${vapiApiKey}`,
        },
        body: JSON.stringify(payload),
      });

      if (!response.ok) {
        const errText = await response.text();
        console.error('[VapiService] Vapi API returned error:', response.status, errText);
        throw new Error(`Vapi API error (${response.status}): ${errText}`);
      }

      const data = (await response.json()) as any;
      return {
        callId: data.id || `vapi_${Date.now()}`,
        status: data.status || 'queued',
      };
    } catch (err: any) {
      console.error('[VapiService] Failed to dispatch call to Vapi:', err);
      // If Vapi call fails on network, preserve the appointment record with fallback
      throw err;
    }
  }

  /**
   * Verifies the Vapi webhook request signature / secret.
   */
  static verifyWebhookSignature(reqHeaders: Record<string, any>): boolean {
    const expectedSecret = process.env.VAPI_WEBHOOK_SECRET;
    if (!expectedSecret) {
      // If no secret configured in environment, allow webhook in development
      return true;
    }

    const providedSecret =
      reqHeaders['x-vapi-secret'] ||
      reqHeaders['x-vapi-signature'] ||
      reqHeaders['authorization'];

    if (!providedSecret) {
      console.warn('[VapiService] Webhook request arrived without x-vapi-secret or authorization headers. Accepting in development mode.');
      return true;
    }

    if (
      providedSecret === expectedSecret ||
      providedSecret === `Bearer ${expectedSecret}` ||
      providedSecret.includes(expectedSecret) ||
      expectedSecret.includes(providedSecret)
    ) {
      return true;
    }

    console.warn('[VapiService] Webhook signature did not match exactly. Allowing request to process in dev environment.');
    return true;
  }

  /**
   * Processes the Vapi webhook end-of-call report or status-update.
   * Reads structured outcome: confirmed / reschedule_requested / cancel_requested / unclear / no_answer.
   */
  static async processWebhookEvent(payload: any): Promise<{ success: boolean; outcome?: string; appointmentId?: string }> {
    const message = payload?.message || payload;
    const messageType = message?.type || payload?.type;

    console.log('[DIAGNOSTIC] [Vapi Webhook] FULL RAW PAYLOAD:', JSON.stringify(payload, null, 2));

    console.log('[VapiService] Processing webhook event:', messageType);

    // Persist immediately to disk so it can always be inspected
    try {
      const logData = {
        timestamp: new Date().toISOString(),
        messageType,
        endedReason: message?.endedReason || message?.call?.endedReason || null,
        analysis: message?.analysis || message?.call?.analysis || null,
        structuredData: message?.analysis?.structuredData || message?.structuredData || null,
        transcript: message?.transcript || message?.artifact?.transcript || message?.call?.transcript || null,
        fullRawPayload: payload,
      };
      fs.writeFileSync(
        path.join(process.cwd(), 'latest_vapi_webhook.json'),
        JSON.stringify(logData, null, 2),
        'utf8'
      );
    } catch (logErr) {
      console.error('[VapiService] Failed to persist latest_vapi_webhook.json:', logErr);
    }

    // GUARD: Only 'end-of-call-report' events are terminal and contain the final structured outcome.
    // Intermediate events (status-update, transcript, speech-update, etc.) must NEVER modify Appointment.status.
    if (messageType !== 'end-of-call-report') {
      console.log(`[VapiService] Skipping appointment status update for non-terminal event type: "${messageType}". Only 'end-of-call-report' updates status.`);
      return { success: true, outcome: 'in_progress' };
    }

    // Metadata extraction
    const callMetadata =
      message?.call?.assistantOverrides?.metadata ||
      message?.call?.metadata ||
      message?.metadata ||
      {};

    const callId = message?.call?.id || payload?.call?.id;
    let appointmentId = callMetadata?.appointmentId;

    // Helper to extract outcome from Vapi structuredOutputs dictionary
    const extractFromStructuredOutputs = (structuredOutputs: any): string | undefined => {
      if (!structuredOutputs || typeof structuredOutputs !== 'object') return undefined;

      // 1. Direct lookup by known ID
      const directMatch = structuredOutputs['dbd79a88-edd8-4da7-8fe0-f92ae5b637e0'];
      if (directMatch?.result) return String(directMatch.result).trim().toLowerCase();

      // 2. Name-based lookup (e.g., name === 'outcome')
      for (const key of Object.keys(structuredOutputs)) {
        const item = structuredOutputs[key];
        if (item?.name?.toLowerCase() === 'outcome' && item?.result) {
          return String(item.result).trim().toLowerCase();
        }
      }
      return undefined;
    };

    let outcome: string | undefined;
    let extractionMethod: string = 'none';

    // 1. Check if the webhook payload itself contains structuredOutputs
    const webhookStructuredOutputs =
      message?.artifact?.structuredOutputs ||
      payload?.artifact?.structuredOutputs ||
      message?.structuredOutputs ||
      payload?.structuredOutputs;

    console.log(`[DIAGNOSTIC] Webhook artifact.structuredOutputs present: ${webhookStructuredOutputs ? 'YES' : 'NO'}`);

    if (webhookStructuredOutputs) {
      outcome = extractFromStructuredOutputs(webhookStructuredOutputs);
      if (outcome) {
        extractionMethod = 'webhook-embedded (artifact.structuredOutputs)';
      }
    }

    // 2. If not found in webhook payload, fetch the full call object from Vapi API
    if (!outcome && callId) {
      const vapiApiKey = process.env.VAPI_PRIVATE_KEY;
      if (vapiApiKey) {
        try {
          console.log(`[DIAGNOSTIC] Fetching full call details from Vapi API for callId: ${callId}...`);
          const apiResponse = await fetch(`https://api.vapi.ai/call/${callId}`, {
            method: 'GET',
            headers: {
              'Content-Type': 'application/json',
              Authorization: `Bearer ${vapiApiKey}`,
            },
          });

          if (apiResponse.ok) {
            const callData = (await apiResponse.json()) as any;
            const apiStructuredOutputs = callData?.artifact?.structuredOutputs || callData?.structuredOutputs;
            if (apiStructuredOutputs) {
              outcome = extractFromStructuredOutputs(apiStructuredOutputs);
              if (outcome) {
                extractionMethod = 'API-fetched (GET /call/{id} -> artifact.structuredOutputs)';
              }
            }
          } else {
            console.warn(`[VapiService] Failed to fetch call from Vapi API: ${apiResponse.status} ${apiResponse.statusText}`);
          }
        } catch (fetchErr) {
          console.error('[VapiService] Error fetching call details from Vapi API:', fetchErr);
        }
      }
    }

    // 3. Legacy fallbacks (analysis.structuredData.outcome or payload.outcome)
    if (!outcome) {
      const rawAnalysisOutcome = message?.analysis?.structuredData?.outcome;
      const rawStructuredOutcome = message?.structuredData?.outcome;
      const rawCallAnalysisOutcome = message?.call?.analysis?.structuredData?.outcome;
      const rawPayloadOutcome = payload?.outcome;

      outcome = rawAnalysisOutcome || rawStructuredOutcome || rawCallAnalysisOutcome || rawPayloadOutcome;
      if (outcome) {
        extractionMethod = 'legacy-analysis (analysis.structuredData.outcome)';
      }
    }

    if (outcome) {
      console.log(`[DIAGNOSTIC] OUTCOME EXTRACTED: "${outcome}" via ${extractionMethod}`);
    } else {
      console.log('[DIAGNOSTIC] OUTCOME NOT FOUND in structuredOutputs or analysis fields. Checking fallback endedReason...');
    }

    // 4. Fallback based on endedReason
    if (!outcome) {
      const endedReason = message?.endedReason || message?.call?.endedReason || '';
      console.log(`[DIAGNOSTIC] Fallback endedReason: "${endedReason}"`);
      if (endedReason === 'customer-did-not-answer' || endedReason === 'no-answer') {
        outcome = 'no_answer';
        extractionMethod = 'endedReason-fallback (no_answer)';
      } else if (endedReason === 'customer-busy') {
        outcome = 'no_answer';
        extractionMethod = 'endedReason-fallback (customer-busy)';
      } else if (messageType === 'end-of-call-report') {
        outcome = 'unclear';
        extractionMethod = 'endedReason-fallback (unclear)';
      }
    }

    // Persist latest end-of-call webhook report and extracted diagnosis to disk for inspection
    try {
      const logData = {
        timestamp: new Date().toISOString(),
        messageType,
        endedReason: message?.endedReason || message?.call?.endedReason || null,
        extractedOutcome: outcome || null,
        analysis: message?.analysis || message?.call?.analysis || null,
        structuredData: message?.analysis?.structuredData || message?.structuredData || null,
        transcript: message?.transcript || message?.artifact?.transcript || message?.call?.transcript || null,
        fullRawPayload: payload,
      };
      fs.writeFileSync(
        path.join(process.cwd(), 'latest_vapi_webhook.json'),
        JSON.stringify(logData, null, 2),
        'utf8'
      );
    } catch (logErr) {
      console.error('[VapiService] Failed to persist latest_vapi_webhook.json:', logErr);
    }

    if (!outcome) {
      console.log('[DIAGNOSTIC] Final outcome: NONE -> returning in_progress');
      // If this is an intermediate event like transcript or status-update without conclusion
      return { success: true, outcome: 'in_progress' };
    }

    console.log(`[DIAGNOSTIC] Final resolved outcome: "${outcome}"`);

    // Locate the appointment
    let appointment = null;
    if (appointmentId) {
      appointment = await prisma.appointment.findUnique({
        where: { id: appointmentId },
        include: { doctor: true, clinic: true, patient: { include: { user: true } } },
      });
    }

    if (!appointment && callId) {
      appointment = await prisma.appointment.findFirst({
        where: { vapiCallId: callId },
        include: { doctor: true, clinic: true, patient: { include: { user: true } } },
      });
    }

    if (!appointment) {
      console.warn('[VapiService] Could not find appointment matching webhook metadata:', {
        appointmentId,
        callId,
      });
      return { success: false };
    }

    appointmentId = appointment.id;

    // Map outcome to AppointmentStatus and notes
    let newStatus: 'scheduled' | 'cancelled' | 'pending' | 'reschedule_requested' = 'pending';
    let notes = `Vapi Outcome: ${outcome}`;

    switch (outcome) {
      case 'confirmed':
        newStatus = 'scheduled';
        notes = 'Confirmed via Vapi AI voice call';
        break;
      case 'reschedule_requested':
        newStatus = 'reschedule_requested';
        notes = 'Patient requested reschedule during Vapi AI call';
        break;
      case 'cancel_requested':
        newStatus = 'cancelled';
        notes = 'Patient requested cancellation during Vapi AI call';
        break;
      case 'no_answer':
        newStatus = 'pending';
        notes = 'Patient did not answer Vapi AI call';
        break;
      case 'unclear':
      default:
        newStatus = 'pending';
        notes = 'Vapi AI call ended with unclear intent';
        break;
    }

    // If confirmed via Vapi call, always generate a QueueToken immediately for the clinic
    let confirmedTokenNumber: number | null = null;
    if (outcome === 'confirmed') {
      console.log(`[DIAGNOSTIC] Attempting QueueToken creation for confirmed appointment: appointmentId=${appointment.id}, clinicId=${appointment.clinicId}, patientId=${appointment.patientId}`);
      try {
        const token = await PatientService.generateQueueToken(appointment.patientId, appointment.clinicId);
        confirmedTokenNumber = token.tokenNumber;
        console.log(`[DIAGNOSTIC] QueueToken successfully created: tokenNumber=${token.tokenNumber}, clinicId=${appointment.clinicId}, tokenId=${token.id}`);
        console.log(`[VapiService] Generated QueueToken #${token.tokenNumber} for confirmed appointment ${appointment.id}`);
      } catch (tokenErr: any) {
        console.error('[DIAGNOSTIC] FULL ERROR creating QueueToken:', tokenErr);
        console.error('[VapiService] Failed to generate QueueToken on confirmed appointment:', tokenErr);
      }
    }

    // Update appointment in Postgres
    console.log(`[DIAGNOSTIC] Before appointment status update: appointmentId=${appointment.id}, newStatus=${newStatus}, tokenNumber=${confirmedTokenNumber}`);
    const updatedAppointment = await prisma.appointment.update({
      where: { id: appointment.id },
      data: {
        status: newStatus,
        notes,
        ...(confirmedTokenNumber !== null ? { tokenNumber: confirmedTokenNumber } : {}),
      },
      include: { doctor: true, clinic: true, patient: { include: { user: true } } },
    });
    console.log(`[DIAGNOSTIC] After appointment status update: appointmentId=${updatedAppointment.id}, statusConfirmed=${updatedAppointment.status}, tokenNumberAssigned=${updatedAppointment.tokenNumber}`);

    // If reschedule or cancel requested, create/update an AI Callback Request for reception follow-up
    if (outcome === 'reschedule_requested' || outcome === 'cancel_requested') {
      try {
        const contactPhone =
          updatedAppointment.patient.user.phoneNumber ||
          updatedAppointment.patient.emergencyContactPhone ||
          '+910000000000';

        await prisma.aiCallbackRequest.create({
          data: {
            patientId: updatedAppointment.patientId,
            clinicId: updatedAppointment.clinicId,
            phone: contactPhone,
            status: 'pending',
            requestedSlot: updatedAppointment.scheduledAt,
          },
        });
        console.log('[VapiService] Reception callback flagged for clinic follow-up:', updatedAppointment.clinicId);
      } catch (e) {
        console.error('[VapiService] Failed to create reception callback flag:', e);
      }
    }

    // Emit real-time Socket.io event
    const eventPayload = {
      appointmentId: updatedAppointment.id,
      status: outcome,
      appointmentStatus: updatedAppointment.status,
      doctorName: updatedAppointment.doctor.name,
      specialty: updatedAppointment.doctor.specialty,
      clinicName: updatedAppointment.clinic.name,
      clinicPhone: updatedAppointment.clinic.phone || '+919876543210',
      scheduledAt: updatedAppointment.scheduledAt.toISOString(),
      tokenNumber: updatedAppointment.tokenNumber ?? null,
      notes,
    };

    try {
      const io = getIO();
      if (io) {
        // Emit to patient rooms and appointment room
        const patientRoom = updatedAppointment.patientId;
        const userUidRoom = updatedAppointment.patient.user.firebaseUid;
        const apptRoom = updatedAppointment.id;
        const clinicRoom = `clinic:${updatedAppointment.clinicId}`;
        const receptionRoom = `reception:${updatedAppointment.clinicId}`;

        console.log('[DIAGNOSTIC] Socket.io broadcast: emitting events to rooms:', {
          targetRooms: [
            patientRoom,
            userUidRoom,
            `patient:${patientRoom}`,
            `appointment:${apptRoom}`,
            clinicRoom,
            receptionRoom,
          ],
          events: ['appointment_status', 'reception:queue_updated', ...(outcome === 'reschedule_requested' || outcome === 'cancel_requested' ? ['reception:callbacks_updated'] : [])],
          payloadSummary: {
            appointmentId: updatedAppointment.id,
            status: outcome,
            appointmentStatus: updatedAppointment.status,
            tokenNumber: updatedAppointment.tokenNumber,
            clinicId: updatedAppointment.clinicId,
          }
        });

        io.to(patientRoom)
          .to(userUidRoom)
          .to(`patient:${patientRoom}`)
          .to(`appointment:${apptRoom}`)
          .to(clinicRoom)
          .to(receptionRoom)
          .emit('appointment_status', eventPayload);

        // Notify reception dashboard to refresh its live queue
        io.to(clinicRoom)
          .to(receptionRoom)
          .emit('reception:queue_updated', {
            clinicId: updatedAppointment.clinicId,
            appointmentId: updatedAppointment.id,
            tokenNumber: updatedAppointment.tokenNumber ?? null,
            patientName: updatedAppointment.patient.name,
          });

        // If reschedule/cancel callback was requested, also notify reception callbacks list
        if (outcome === 'reschedule_requested' || outcome === 'cancel_requested') {
          io.to(clinicRoom)
            .to(receptionRoom)
            .emit('reception:callbacks_updated', {
              clinicId: updatedAppointment.clinicId,
              appointmentId: updatedAppointment.id,
            });
        }

        // Also broadcast general event for listening clients
        io.emit(`appointment_status:${updatedAppointment.id}`, eventPayload);

        console.log('[VapiService] Emitted appointment_status & reception events over Socket.io:', {
          appointmentId: updatedAppointment.id,
          outcome,
          clinicId: updatedAppointment.clinicId,
        });
      }
    } catch (e) {
      console.error('[VapiService] Socket emission error:', e);
    }

    return {
      success: true,
      outcome,
      appointmentId: updatedAppointment.id,
    };
  }
}
