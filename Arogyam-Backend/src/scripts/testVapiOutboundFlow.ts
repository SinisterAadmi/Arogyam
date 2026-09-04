import prisma from '../lib/prisma';
import { VapiService } from '../services/vapiService';
import { checkRateLimit, clearRateLimit } from '../lib/redis';

async function testVapiFlow() {
  console.log('=== TESTING VAPI AI OUTBOUND CALLING & WEBHOOK SUITE ===\n');

  // 1. Setup / find a patient and a clinic
  let patient = await prisma.patient.findFirst({
    include: { user: true },
  });

  if (!patient) {
    console.log('Creating test patient...');
    const user = await prisma.user.create({
      data: {
        firebaseUid: `test_vapi_${Date.now()}`,
        role: 'patient',
        phoneNumber: '+919876543210',
      },
    });
    patient = await prisma.patient.create({
      data: {
        userId: user.id,
        name: 'Vapi Test Patient',
      },
      include: { user: true },
    });
  }

  let clinic = await prisma.clinic.findFirst({
    include: { doctors: true },
  });

  if (!clinic) {
    console.log('Creating test clinic...');
    clinic = await prisma.clinic.create({
      data: {
        name: 'Vapi Test Care Clinic',
        address: '100 Health Way',
        phone: '+911144445555',
        latitude: 28.6,
        longitude: 77.2,
      },
      include: { doctors: true },
    });
  }

  let doctor = clinic.doctors[0];
  if (!doctor) {
    console.log('Creating test doctor for clinic...');
    const docUser = await prisma.user.create({
      data: {
        firebaseUid: `test_doc_${Date.now()}`,
        role: 'doctor',
      },
    });
    doctor = await prisma.doctor.create({
      data: {
        userId: docUser.id,
        clinicId: clinic.id,
        name: 'Dr. Vapi Specialist',
        specialty: 'General Medicine',
      },
    });
  }

  console.log(`Using Patient: ${patient.name} (${patient.id})`);
  console.log(`Using Clinic: ${clinic.name} (${clinic.id})`);
  console.log(`Using Doctor: ${doctor.name} (${doctor.id})\n`);

  // TEST 1: Rate Limiting
  console.log('--- TEST 1: Redis Rate Limiting ---');
  const rateLimitKey = `ratelimit:vapi:${patient.id}:${clinic.id}`;
  await clearRateLimit(rateLimitKey);

  const attempt1 = await checkRateLimit(rateLimitKey, 180);
  console.log(`First request allowed: ${attempt1} (expected: true)`);
  if (!attempt1) throw new Error('Attempt 1 should be allowed');

  const attempt2 = await checkRateLimit(rateLimitKey, 180);
  console.log(`Immediate second request allowed: ${attempt2} (expected: false)`);
  if (attempt2) throw new Error('Attempt 2 should be rate limited');

  await clearRateLimit(rateLimitKey);
  console.log('Rate limit cleared.\n');

  // TEST 2: Outbound Call Dispatch & Pending Appointment Creation
  console.log('--- TEST 2: Create Pending Appointment & Dispatch Call ---');
  const scheduledTime = new Date(Date.now() + 24 * 3600 * 1000);
  const appointment = await prisma.appointment.create({
    data: {
      patientId: patient.id,
      clinicId: clinic.id,
      doctorId: doctor.id,
      scheduledAt: scheduledTime,
      status: 'pending',
      notes: 'Test pending appointment for Vapi',
    },
    include: { doctor: true, clinic: true },
  });

  console.log(`Created Appointment: ID=${appointment.id}, Status=${appointment.status}`);

  const callResult = await VapiService.triggerOutboundCall({
    patientId: patient.id,
    patientName: patient.name,
    patientPhone: '+919876543210',
    clinicId: clinic.id,
    clinicName: clinic.name,
    clinicPhone: clinic.phone,
    doctorId: doctor.id,
    doctorName: doctor.name,
    appointmentId: appointment.id,
    scheduledAt: scheduledTime,
  });

  console.log(`Vapi Call Result: callId=${callResult.callId}, status=${callResult.status}`);
  await prisma.appointment.update({
    where: { id: appointment.id },
    data: { vapiCallId: callResult.callId },
  });

  // TEST 3: Webhook Signature Verification
  console.log('\n--- TEST 3: Webhook Signature Verification ---');
  process.env.VAPI_WEBHOOK_SECRET = 'secret_vapi_test_123';
  const validHeader = { 'x-vapi-secret': 'secret_vapi_test_123' };
  const invalidHeader = { 'x-vapi-secret': 'wrong_secret' };

  const sigPass = VapiService.verifyWebhookSignature(validHeader);
  const sigFail = VapiService.verifyWebhookSignature(invalidHeader);
  console.log(`Valid signature accepted: ${sigPass} (expected: true)`);
  console.log(`Invalid signature rejected: ${!sigFail} (expected: true)`);
  if (!sigPass || sigFail) throw new Error('Webhook signature verification failed');

  // TEST 4: Process Webhook - "confirmed" Outcome
  console.log('\n--- TEST 4: Process Webhook - Outcome: confirmed ---');
  const webhookConfirmedPayload = {
    message: {
      type: 'end-of-call-report',
      call: {
        id: callResult.callId,
        assistantOverrides: {
          metadata: {
            appointmentId: appointment.id,
          },
        },
      },
      analysis: {
        structuredData: {
          outcome: 'confirmed',
        },
      },
    },
  };

  const processResult1 = await VapiService.processWebhookEvent(webhookConfirmedPayload);
  console.log(`Webhook Process Result: success=${processResult1.success}, outcome=${processResult1.outcome}`);

  const confirmedAppt = await prisma.appointment.findUnique({ where: { id: appointment.id } });
  console.log(`Appointment Status after confirmed webhook: ${confirmedAppt?.status} (expected: scheduled)`);
  if (confirmedAppt?.status !== 'scheduled') throw new Error('Appointment should be scheduled');

  // TEST 5: Process Webhook - "reschedule_requested" Outcome (Flags reception follow-up)
  console.log('\n--- TEST 5: Process Webhook - Outcome: reschedule_requested ---');
  const webhookReschedulePayload = {
    message: {
      type: 'end-of-call-report',
      call: {
        id: callResult.callId,
        assistantOverrides: {
          metadata: {
            appointmentId: appointment.id,
          },
        },
      },
      analysis: {
        structuredData: {
          outcome: 'reschedule_requested',
        },
      },
    },
  };

  const processResult2 = await VapiService.processWebhookEvent(webhookReschedulePayload);
  console.log(`Webhook Process Result: success=${processResult2.success}, outcome=${processResult2.outcome}`);

  const rescheduledAppt = await prisma.appointment.findUnique({ where: { id: appointment.id } });
  console.log(`Appointment Status after reschedule: ${rescheduledAppt?.status} (expected: reschedule_requested)`);
  if (rescheduledAppt?.status !== 'reschedule_requested') throw new Error('Appointment should be reschedule_requested');

  // Verify reception callback request was created
  const flaggedCallback = await prisma.aiCallbackRequest.findFirst({
    where: {
      patientId: patient.id,
      clinicId: clinic.id,
    },
    orderBy: { createdAt: 'desc' },
  });
  console.log(`Reception callback flagged: ID=${flaggedCallback?.id}, Status=${flaggedCallback?.status} (expected: pending)`);
  if (!flaggedCallback) throw new Error('Reception callback should have been created');

  // Clean up test appointment & callback
  await prisma.appointment.delete({ where: { id: appointment.id } });
  if (flaggedCallback) {
    await prisma.aiCallbackRequest.delete({ where: { id: flaggedCallback.id } });
  }

  console.log('\n=== ALL VAPI BACKEND INTEGRATION TESTS PASSED SUCCESSFULLY ===\n');
}

testVapiFlow()
  .catch((e) => {
    console.error('Test Failed:', e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
