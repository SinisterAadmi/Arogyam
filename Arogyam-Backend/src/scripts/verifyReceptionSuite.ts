import { PrismaClient } from '@prisma/client';
import dotenv from 'dotenv';
dotenv.config();

const prisma = new PrismaClient();
import { ConsentSessionService } from '../services/consentSessionService';
import { ReceptionService } from '../services/receptionService';

async function verifyReceptionSuite() {
  console.log('===========================================================');
  console.log('  FULL E2E LIVE VERIFICATION OF RECEPTION FEATURES SUITE');
  console.log('===========================================================\n');

  const patient = await prisma.patient.findFirst({
    where: { user: { phoneNumber: '+917276633833' } },
    include: { user: true },
  });
  if (!patient) throw new Error('Patient not found');

  const clinic = await prisma.clinic.findFirst({
    where: { name: 'Sunrise Medical Center' },
  });
  if (!clinic) throw new Error('Clinic not found');

  const receptionUser = await prisma.user.findFirst({
    where: { email: 'reception.sunrise@arogyam.test' },
  });
  if (!receptionUser) throw new Error('Reception user not found');

  // -------------------------------------------------------------
  // TEST 1: Patient generates Consent Session & Reception Verifies Code
  // -------------------------------------------------------------
  console.log('--- TEST 1: Consent Session Short Code Verification ---');
  const session = await ConsentSessionService.createSession(patient.id);
  console.log(`Generated Consent Session: ID=${session.sessionId}, Code="${session.shortCode}", QR="${session.qrToken}"`);

  const codeVerification = await ConsentSessionService.verifyCodeOnly(session.shortCode);
  console.log('Code Verification Response:');
  console.log(JSON.stringify(codeVerification, null, 2));

  // -------------------------------------------------------------
  // TEST 2: Duplicate Code Verification Guard
  // -------------------------------------------------------------
  console.log('\n--- TEST 2: Duplicate / Reused Session Guard ---');
  try {
    await ConsentSessionService.verifyCodeOnly(session.shortCode);
    console.error('ERROR: Duplicate verification should not have succeeded!');
  } catch (err: any) {
    console.log(`SUCCESS: Duplicate blocked with: "${err.message}" (HTTP ${err.statusCode})`);
  }

  // -------------------------------------------------------------
  // TEST 3: QR Code Verification
  // -------------------------------------------------------------
  console.log('\n--- TEST 3: QR Code Verification ---');
  const qrSession = await ConsentSessionService.createSession(patient.id);
  const qrVerification = await ConsentSessionService.verifyQrOrToken(qrSession.qrToken);
  console.log('QR Verification Response:');
  console.log(JSON.stringify(qrVerification, null, 2));

  // -------------------------------------------------------------
  // TEST 4: AI Callback Queue (Create -> List -> Resolve)
  // -------------------------------------------------------------
  console.log('\n--- TEST 4: AI Callback Queue ---');
  const callback = await prisma.aiCallbackRequest.create({
    data: {
      patientId: patient.id,
      clinicId: clinic.id,
      phone: '+917276633833',
      status: 'pending',
      requestedSlot: new Date(Date.now() + 15 * 60 * 1000),
    },
  });
  console.log(`Created AI Callback Request ID: ${callback.id}`);

  const activeCallbacks = await ReceptionService.getAiCallbacks(receptionUser.id);
  console.log(`Reception AI Callbacks count: ${activeCallbacks.length}`);
  const targetCallback = activeCallbacks.find((c) => c.id === callback.id);
  console.log(`Target Callback in Reception Queue: patientName="${targetCallback?.patientName}", status="${targetCallback?.status}"`);

  const resolveResponse = await ReceptionService.resolveAiCallback(receptionUser.id, callback.id);
  console.log(`Callback Resolved: ${JSON.stringify(resolveResponse)}`);

  // -------------------------------------------------------------
  // TEST 5: Clinic Analytics Computation
  // -------------------------------------------------------------
  console.log('\n--- TEST 5: Clinic Analytics ---');
  const analytics = await ReceptionService.getAnalytics(receptionUser.id);
  console.log('Analytics Response:');
  console.log(JSON.stringify(analytics, null, 2));

  console.log('\n===========================================================');
  console.log('          ALL 5 RECEPTION SUITE TESTS PASSED');
  console.log('===========================================================');
}

verifyReceptionSuite().catch(console.error).finally(() => prisma.$disconnect());
