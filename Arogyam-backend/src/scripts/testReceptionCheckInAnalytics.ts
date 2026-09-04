import { PrismaClient } from '@prisma/client';
import dotenv from 'dotenv';
dotenv.config();

const prisma = new PrismaClient();
import { ConsentSessionService } from '../services/consentSessionService';
import { ReceptionService } from '../services/receptionService';

async function testReceptionFeatures() {
  console.log('=== TESTING RECEPTION CHECK-IN, AI CALLBACKS & ANALYTICS ===\n');

  const patient = await prisma.patient.findFirst({
    where: { user: { phoneNumber: '+917276633833' } },
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

  // 1. Test short code only verification
  console.log('1. Creating consent session for patient...');
  const session = await ConsentSessionService.createSession(patient.id);
  console.log(`Session created: shortCode=${session.shortCode}, qrToken=${session.qrToken}`);

  console.log('Verifying via verifyCodeOnly (POST /consent-sessions/verify-code)...');
  const verifyResult = await ConsentSessionService.verifyCodeOnly(session.shortCode);
  console.log('Verification Success:');
  console.log(JSON.stringify(verifyResult, null, 2));

  // 2. Test re-verification should fail with "already used"
  console.log('\n2. Testing duplicate verification failure...');
  try {
    await ConsentSessionService.verifyCodeOnly(session.shortCode);
    console.error('ERROR: Duplicate verification should fail!');
  } catch (err: any) {
    console.log(`SUCCESS: Duplicate blocked with: "${err.message}" (status ${err.statusCode})`);
  }

  // 3. Test AI Callback creation and reception listing
  console.log('\n3. Creating pending AI Callback Request for Sunrise Medical Center...');
  const callback = await prisma.aiCallbackRequest.create({
    data: {
      patientId: patient.id,
      clinicId: clinic.id,
      phone: '+917276633833',
      status: 'pending',
      requestedSlot: new Date(Date.now() + 30 * 60 * 1000),
    },
  });
  console.log(`Created Callback ID: ${callback.id}`);

  console.log('Fetching AI callbacks for reception (GET /reception/ai-callbacks)...');
  const callbacks = await ReceptionService.getAiCallbacks(receptionUser.id);
  console.log(`Found ${callbacks.length} callbacks for reception clinic.`);
  console.log(JSON.stringify(callbacks[0], null, 2));

  console.log('\nResolving callback (PATCH /reception/ai-callbacks/:id/resolve)...');
  const resolveResult = await ReceptionService.resolveAiCallback(receptionUser.id, callback.id);
  console.log(JSON.stringify(resolveResult, null, 2));

  // 4. Test Analytics computation
  console.log('\n4. Fetching clinic analytics (GET /reception/analytics)...');
  const analytics = await ReceptionService.getAnalytics(receptionUser.id);
  console.log(JSON.stringify(analytics, null, 2));

  console.log('\n=== ALL RECEPTION BACKEND FEATURES VERIFIED! ===');
}

testReceptionFeatures().catch(console.error).finally(() => prisma.$disconnect());
