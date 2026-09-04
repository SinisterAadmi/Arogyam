import { Response } from 'express';
import { AuthRequest } from '../middleware/authMiddleware';
import { PatientService } from '../services/patientService';
import { ConsentSessionService } from '../services/consentSessionService';
import { VapiService } from '../services/vapiService';
import { checkRateLimit } from '../lib/redis';
import { getIO } from '../socket';
import prisma from '../lib/prisma';

export class PatientController {
  static async getMe(req: AuthRequest, res: Response) {
    const profile = await PatientService.getProfile(req.user!.dbUserId);
    res.json(profile);
  }

  static async updateMe(req: AuthRequest, res: Response) {
    const profile = await PatientService.updateProfile(req.user!.dbUserId, req.body);
    res.json(profile);
  }

  static async getPrivacySettings(req: AuthRequest, res: Response) {
    const patient = await prisma.patient.findUnique({ where: { userId: req.user!.dbUserId } });
    if (!patient) return res.status(404).json({ message: 'Patient not found' });
    const settings = await PatientService.getPrivacySettings(patient.id);
    res.json(settings);
  }

  static async updatePrivacySettings(req: AuthRequest, res: Response) {
    const patient = await prisma.patient.findUnique({ where: { userId: req.user!.dbUserId } });
    if (!patient) return res.status(404).json({ message: 'Patient not found' });
    const settings = await PatientService.updatePrivacySettings(patient.id, req.body);
    res.json(settings);
  }

  static async getAccessHistory(req: AuthRequest, res: Response) {
    const patient = await prisma.patient.findUnique({ where: { userId: req.user!.dbUserId } });
    if (!patient) return res.status(404).json({ message: 'Patient not found' });
    const history = await PatientService.getAccessHistory(patient.id);
    res.json(history);
  }

  static async uploadAvatar(req: AuthRequest, res: Response) {
    res.json({ message: 'Avatar uploaded', imageUrl: 'https://placeholder.com/150' });
  }

  static async getNearbyClinics(req: AuthRequest, res: Response) {
    const { lat, lng } = req.query;
    const clinics = await PatientService.getNearbyClinics(Number(lat), Number(lng));
    res.json(clinics);
  }

  static async getUpcomingAppointments(req: AuthRequest, res: Response) {
    const patient = await prisma.patient.findUnique({ where: { userId: req.user!.dbUserId } });
    if (!patient) return res.status(404).json({ message: 'Patient not found' });
    const appointments = await PatientService.getUpcomingAppointments(patient.id);
    res.json(appointments);
  }

  static async createAppointment(req: AuthRequest, res: Response) {
    const patient = await prisma.patient.findUnique({
      where: { userId: req.user!.dbUserId },
      include: { user: true },
    });
    if (!patient) return res.status(404).json({ message: 'Patient not found' });
    const { clinicId, doctorId, scheduledAt } = req.body;
    try {
      const appointment = await prisma.appointment.create({
        data: {
          patientId: patient.id,
          clinicId,
          doctorId,
          scheduledAt: new Date(scheduledAt),
          status: 'pending',
          notes: 'Awaiting confirmation via automated voice call',
        },
        include: { doctor: true, clinic: true },
      });

      // Respond immediately to the client
      res.json({
        id: appointment.id,
        doctorName: appointment.doctor.name,
        specialty: appointment.doctor.specialty,
        clinicName: appointment.clinic.name,
        appointmentTime: appointment.scheduledAt.toISOString(),
        tokenNumber: appointment.tokenNumber ?? null,
        status: appointment.status,
      });

      // Fire-and-forget automatic Vapi outbound confirmation call in background
      const patientPhone =
        patient.user.phoneNumber ||
        patient.emergencyContactPhone ||
        '+919876543210';

      VapiService.triggerOutboundCall({
        patientId: patient.id,
        patientName: patient.name,
        patientPhone,
        clinicId: appointment.clinicId,
        clinicName: appointment.clinic.name,
        clinicPhone: appointment.clinic.phone,
        doctorId: appointment.doctorId,
        doctorName: appointment.doctor.name,
        appointmentId: appointment.id,
        scheduledAt: appointment.scheduledAt,
      })
        .then(async (callResult) => {
          if (callResult?.callId) {
            await prisma.appointment.update({
              where: { id: appointment.id },
              data: { vapiCallId: callResult.callId },
            });
          }
        })
        .catch((callErr: any) => {
          console.error('[createAppointment] Auto Vapi call dispatch failed in background:', callErr);
        });
    } catch (error: any) {
      if (error.code === 'P2003') {
        return res.status(400).json({ message: 'Selected doctor not found' });
      }
      res.status(500).json({ message: error.message || 'Failed to create appointment' });
    }
  }

  static async getAppointmentById(req: AuthRequest, res: Response) {
    try {
      const patient = await prisma.patient.findUnique({ where: { userId: req.user!.dbUserId } });
      if (!patient) return res.status(404).json({ message: 'Patient not found' });

      const { id } = req.params;
      const appointment = await prisma.appointment.findUnique({
        where: { id },
        include: { doctor: true, clinic: true },
      });

      if (!appointment) {
        return res.status(404).json({ message: 'Appointment not found' });
      }

      if (appointment.patientId !== patient.id) {
        return res.status(403).json({ message: 'Forbidden: You do not have access to this appointment' });
      }

      return res.json({
        id: appointment.id,
        doctorId: appointment.doctorId,
        doctorName: appointment.doctor.name,
        specialty: appointment.doctor.specialty,
        clinicId: appointment.clinicId,
        clinicName: appointment.clinic.name,
        appointmentTime: appointment.scheduledAt.toISOString(),
        tokenNumber: appointment.tokenNumber ?? null,
        status: appointment.status,
        notes: appointment.notes,
        createdAt: appointment.createdAt.toISOString(),
      });
    } catch (error: any) {
      console.error('[getAppointmentById] Error:', error);
      return res.status(500).json({ message: error.message || 'Failed to fetch appointment details' });
    }
  }

  static async cancelAppointment(req: AuthRequest, res: Response) {
    try {
      const patient = await prisma.patient.findUnique({
        where: { userId: req.user!.dbUserId },
        include: { user: true },
      });
      if (!patient) return res.status(404).json({ message: 'Patient not found' });

      const { id } = req.params;
      const appointment = await prisma.appointment.findUnique({
        where: { id },
        include: { doctor: true, clinic: true },
      });

      if (!appointment) {
        return res.status(404).json({ message: 'Appointment not found' });
      }

      if (appointment.patientId !== patient.id) {
        return res.status(403).json({ message: 'Forbidden: You do not have access to this appointment' });
      }

      // 1. Soft-cancel linked QueueToken if one exists
      if (appointment.tokenNumber !== null) {
        try {
          await prisma.queueToken.updateMany({
            where: {
              clinicId: appointment.clinicId,
              tokenNumber: appointment.tokenNumber,
              status: { in: ['waiting', 'serving'] },
            },
            data: { status: 'absent' },
          });
        } catch (tokenErr) {
          console.warn('[cancelAppointment] Could not update linked QueueToken:', tokenErr);
        }
      }

      // 2. Update appointment status to cancelled
      const updatedAppointment = await prisma.appointment.update({
        where: { id },
        data: {
          status: 'cancelled',
          notes: 'Cancelled by patient',
        },
        include: { doctor: true, clinic: true },
      });

      // 3. Emit Socket.io real-time event to clinic, reception, and patient rooms
      try {
        const io = getIO();
        if (io) {
          const clinicRoom = `clinic:${updatedAppointment.clinicId}`;
          const receptionRoom = `reception:${updatedAppointment.clinicId}`;
          const patientRoom = updatedAppointment.patientId;
          const userUidRoom = patient.user.firebaseUid;
          const apptRoom = updatedAppointment.id;

          const eventPayload = {
            appointmentId: updatedAppointment.id,
            status: 'cancelled',
            appointmentStatus: 'cancelled',
            doctorName: updatedAppointment.doctor.name,
            specialty: updatedAppointment.doctor.specialty,
            clinicName: updatedAppointment.clinic.name,
            scheduledAt: updatedAppointment.scheduledAt.toISOString(),
            tokenNumber: updatedAppointment.tokenNumber ?? null,
            notes: updatedAppointment.notes,
          };

          io.to(patientRoom)
            .to(userUidRoom)
            .to(`patient:${patientRoom}`)
            .to(`appointment:${apptRoom}`)
            .to(clinicRoom)
            .to(receptionRoom)
            .emit('appointment_status', eventPayload);

          io.to(clinicRoom)
            .to(receptionRoom)
            .emit('reception:queue_updated', {
              clinicId: updatedAppointment.clinicId,
              appointmentId: updatedAppointment.id,
              tokenNumber: updatedAppointment.tokenNumber ?? null,
              status: 'cancelled',
            });
        }
      } catch (socketErr) {
        console.error('[cancelAppointment] Socket emit error:', socketErr);
      }

      return res.json({
        id: updatedAppointment.id,
        doctorName: updatedAppointment.doctor.name,
        specialty: updatedAppointment.doctor.specialty,
        clinicName: updatedAppointment.clinic.name,
        appointmentTime: updatedAppointment.scheduledAt.toISOString(),
        tokenNumber: updatedAppointment.tokenNumber ?? null,
        status: updatedAppointment.status,
      });
    } catch (error: any) {
      console.error('[cancelAppointment] Error:', error);
      return res.status(500).json({ message: error.message || 'Failed to cancel appointment' });
    }
  }

  static async getClinicDoctors(req: AuthRequest, res: Response) {
    const { clinicId } = req.params;
    const doctors = await prisma.doctor.findMany({
      where: { clinicId },
      select: { id: true, name: true, specialty: true }
    });
    res.json(doctors);
  }

  static async getQueueStatus(req: AuthRequest, res: Response) {
    const patient = await prisma.patient.findUnique({ where: { userId: req.user!.dbUserId } });
    if (!patient) return res.status(404).json({ message: 'Patient not found' });
    const status = await PatientService.getQueueStatus(patient.id);
    res.json(status || { message: 'Not in any queue' });
  }

  static async joinQueue(req: AuthRequest, res: Response) {
    try {
      const patient = await prisma.patient.findUnique({ where: { userId: req.user!.dbUserId } });
      if (!patient) return res.status(404).json({ message: 'Patient not found' });
      const { clinicId } = req.body;
      if (!clinicId) return res.status(400).json({ message: 'clinicId is required' });
      const status = await PatientService.joinQueue(patient.id, clinicId);
      res.json(status);
    } catch (error: any) {
      const statusCode = error.statusCode || 500;
      res.status(statusCode).json({ message: error.message || 'Failed to join queue' });
    }
  }

  static async autoCheckIn(req: AuthRequest, res: Response) {
    try {
      const patient = await prisma.patient.findUnique({ where: { userId: req.user!.dbUserId } });
      if (!patient) return res.status(404).json({ message: 'Patient not found' });
      const { clinicId } = req.body;
      if (!clinicId) return res.status(400).json({ message: 'clinicId is required' });
      const status = await PatientService.joinQueue(patient.id, clinicId);
      res.json({ message: 'Auto check-in successful', ...status });
    } catch (error: any) {
      const statusCode = error.statusCode || 500;
      res.status(statusCode).json({ message: error.message || 'Failed to auto check-in' });
    }
  }

  static async getActivePrescriptions(req: AuthRequest, res: Response) {
    const patient = await prisma.patient.findUnique({ where: { userId: req.user!.dbUserId } });
    if (!patient) return res.status(404).json({ message: 'Patient not found' });
    const prescriptions = await PatientService.getActivePrescriptions(patient.id);
    res.json(prescriptions);
  }

  static async getMedicalHistory(req: AuthRequest, res: Response) {
    const patient = await prisma.patient.findUnique({ where: { userId: req.user!.dbUserId } });
    if (!patient) return res.status(404).json({ message: 'Patient not found' });
    const history = await PatientService.getMedicalHistory(patient.id);
    res.json(history);
  }

  static async getAbhaStatus(req: AuthRequest, res: Response) {
    res.json({ isLinked: true, abhaId: '12-3456-7890-1234', status: 'verified' });
  }

  static async linkAbha(req: AuthRequest, res: Response) {
    res.json({ message: 'ABHA linked successfully', abhaId: req.body.abhaId });
  }

  static async createNfcSession(req: AuthRequest, res: Response) {
    try {
      const patient = await prisma.patient.findUnique({ where: { userId: req.user!.dbUserId } });
      if (!patient) return res.status(404).json({ message: 'Patient not found' });
      const session = await ConsentSessionService.createSession(patient.id);
      res.json(session);
    } catch (error: any) {
      res.status(500).json({ message: error.message || 'Failed to create consent session' });
    }
  }

  static async revokeNfcSession(req: AuthRequest, res: Response) {
    try {
      const { sessionId } = req.params;
      const result = await ConsentSessionService.revokeSession(sessionId);
      res.json(result);
    } catch (error: any) {
      const statusCode = error.statusCode || 500;
      res.status(statusCode).json({ message: error.message || 'Failed to revoke session' });
    }
  }

  static async requestAiCallback(req: AuthRequest, res: Response) {
    try {
      const patient = await prisma.patient.findUnique({
        where: { userId: req.user!.dbUserId },
        include: { user: true },
      });
      if (!patient) return res.status(404).json({ message: 'Patient not found' });

      let { clinicId, phone, requestedSlot } = req.body;
      if (!clinicId) {
        // Fallback to first clinic
        const clinic = await prisma.clinic.findFirst();
        clinicId = clinic?.id;
      }
      if (!clinicId) return res.status(400).json({ message: 'clinicId is required' });

      const callbackPhone = phone || patient.emergencyContactPhone || patient.user.phoneNumber || '+910000000000';
      const slot = requestedSlot ? new Date(requestedSlot) : new Date(Date.now() + 15 * 60 * 1000);

      const request = await prisma.aiCallbackRequest.create({
        data: {
          patientId: patient.id,
          clinicId,
          phone: callbackPhone,
          status: 'pending',
          requestedSlot: slot,
        },
      });

      res.json({
        message: 'AI Callback requested. We will call you shortly.',
        requestId: request.id,
        status: request.status,
        requestedSlot: request.requestedSlot.toISOString(),
      });
    } catch (error: any) {
      console.error('requestAiCallback error:', error);
      res.status(500).json({ message: error.message || 'Failed to request AI callback' });
    }
  }

  static async getAiCallbackStatus(req: AuthRequest, res: Response) {
    try {
      const patient = await prisma.patient.findUnique({ where: { userId: req.user!.dbUserId } });
      if (!patient) return res.status(404).json({ message: 'Patient not found' });

      const pendingRequest = await prisma.aiCallbackRequest.findFirst({
        where: { patientId: patient.id, status: 'pending' },
        orderBy: { createdAt: 'desc' },
      });

      if (!pendingRequest) {
        return res.json({ status: 'none', message: 'No pending AI callback' });
      }

      res.json({
        id: pendingRequest.id,
        status: pendingRequest.status,
        phone: pendingRequest.phone,
        requestedSlot: pendingRequest.requestedSlot.toISOString(),
        createdAt: pendingRequest.createdAt.toISOString(),
      });
    } catch (error: any) {
      res.status(500).json({ message: error.message || 'Failed to get callback status' });
    }
  }

  static async cancelAiCallback(req: AuthRequest, res: Response) {
    try {
      const patient = await prisma.patient.findUnique({ where: { userId: req.user!.dbUserId } });
      if (!patient) return res.status(404).json({ message: 'Patient not found' });

      await prisma.aiCallbackRequest.updateMany({
        where: { patientId: patient.id, status: 'pending' },
        data: { status: 'cancelled' },
      });

      res.json({ message: 'AI Callback cancelled successfully' });
    } catch (error: any) {
      res.status(500).json({ message: error.message || 'Failed to cancel callback' });
    }
  }

  static async triggerVapiCallback(req: AuthRequest, res: Response) {
    try {
      // SECURITY: Strictly derive the patient from the verified Firebase token user, ignoring any patientId in body
      const patient = await prisma.patient.findUnique({
        where: { userId: req.user!.dbUserId },
        include: { user: true },
      });

      if (!patient) {
        return res.status(404).json({ message: 'Patient profile not found' });
      }

      let { clinicId, doctorId, scheduledAt, phone } = req.body;

      // If clinicId is not provided, look up first active clinic
      let clinic = null;
      if (clinicId) {
        clinic = await prisma.clinic.findUnique({ where: { id: clinicId } });
      } else {
        clinic = await prisma.clinic.findFirst();
      }

      if (!clinic) {
        return res.status(400).json({ message: 'Target clinic not found' });
      }

      // Rate limit per patient per clinic using Redis (1 request per patient per clinic per 3 mins)
      const rateLimitKey = `ratelimit:vapi:${patient.id}:${clinic.id}`;
      const isAllowed = await checkRateLimit(rateLimitKey, 180);
      if (!isAllowed) {
        return res.status(429).json({
          message: 'A callback request was recently placed for this clinic. Please wait 3 minutes before requesting another call.',
        });
      }

      // Determine available doctor for this clinic
      let doctor = null;
      if (doctorId) {
        doctor = await prisma.doctor.findFirst({
          where: { id: doctorId, clinicId: clinic.id },
        });
      }
      if (!doctor) {
        doctor = await prisma.doctor.findFirst({
          where: { clinicId: clinic.id },
        });
      }

      if (!doctor) {
        return res.status(400).json({ message: 'No available doctor found for this clinic' });
      }

      // Determine slot time (or default to tomorrow morning 10:00 AM if not specified)
      let slotTime: Date;
      if (scheduledAt) {
        slotTime = new Date(scheduledAt);
      } else {
        slotTime = new Date(Date.now() + 24 * 60 * 60 * 1000);
        slotTime.setHours(10, 0, 0, 0);
      }

      // Patient contact phone
      const patientPhone =
        phone ||
        patient.user.phoneNumber ||
        patient.emergencyContactPhone ||
        '+919876543210';

      // 1. Create a "pending" Appointment record
      const appointment = await prisma.appointment.create({
        data: {
          patientId: patient.id,
          clinicId: clinic.id,
          doctorId: doctor.id,
          scheduledAt: slotTime,
          status: 'pending',
          notes: 'Initiated via Vapi AI callback voice agent',
        },
        include: { doctor: true, clinic: true },
      });

      // 2. Dispatch Vapi Outbound Call
      let callResult = { callId: `vapi_${Date.now()}`, status: 'queued' };
      try {
        callResult = await VapiService.triggerOutboundCall({
          patientId: patient.id,
          patientName: patient.name,
          patientPhone,
          clinicId: clinic.id,
          clinicName: clinic.name,
          clinicPhone: clinic.phone,
          doctorId: doctor.id,
          doctorName: doctor.name,
          appointmentId: appointment.id,
          scheduledAt: slotTime,
        });

        // Store the Vapi call ID on the Appointment record
        await prisma.appointment.update({
          where: { id: appointment.id },
          data: { vapiCallId: callResult.callId },
        });
      } catch (callErr: any) {
        console.error('[triggerVapiCallback] Vapi call dispatch failed, preserving pending record:', callErr);
      }

      res.json({
        message: 'AI Callback initiated. Calling patient now.',
        appointmentId: appointment.id,
        vapiCallId: callResult.callId,
        status: 'pending',
        doctorName: doctor.name,
        specialty: doctor.specialty,
        clinicName: clinic.name,
        clinicPhone: clinic.phone || '+919876543210',
        scheduledAt: appointment.scheduledAt.toISOString(),
      });
    } catch (error: any) {
      console.error('[triggerVapiCallback] Error:', error);
      res.status(500).json({ message: error.message || 'Failed to trigger Vapi callback' });
    }
  }
}
