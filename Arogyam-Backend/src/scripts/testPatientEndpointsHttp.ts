import { PrismaClient } from '@prisma/client';
import dotenv from 'dotenv';
dotenv.config();

const prisma = new PrismaClient();

async function testHttpEndpoints() {
  console.log('=== TESTING REAL HTTP ENDPOINTS ON PORT 3000 ===\n');

  // Let's create a test JWT/auth flow or test directly against controller logic
  const patient = await prisma.patient.findFirst({
    where: { user: { phoneNumber: '+917276633833' } },
    include: { user: true },
  });
  if (!patient) throw new Error('Patient not found');

  const clinic = await prisma.clinic.findFirst({
    where: { name: { contains: 'Sunrise Medical Center', mode: 'insensitive' } },
  });
  if (!clinic) throw new Error('Clinic not found');

  // Clean existing queue tokens for this patient to start fresh
  await prisma.queueToken.deleteMany({
    where: { patientId: patient.id },
  });

  const { PatientService } = await import('../services/patientService');

  // 1. Join queue directly
  const joinedStatus = await PatientService.joinQueue(patient.id, clinic.id);
  console.log('1. PatientService.joinQueue returned object (computed status):');
  console.log(JSON.stringify(joinedStatus, null, 2));

  // 2. Try joining again -> should throw duplicate active queue error
  try {
    await PatientService.joinQueue(patient.id, clinic.id);
    console.error('ERROR: Duplicate join should have failed!');
  } catch (err: any) {
    console.log('2. Duplicate join correctly rejected with error:', err.message);
  }

  // 3. Reception updates status to serving
  const receptionUser = await prisma.user.findFirst({
    where: { email: 'reception.sunrise@arogyam.test' },
  });
  const { ReceptionService } = await import('../services/receptionService');
  const tokens = await prisma.queueToken.findMany({ where: { patientId: patient.id, status: 'waiting' } });
  const tokenId = tokens[0].id;

  const servingToken = await ReceptionService.updateTokenStatus(receptionUser!.id, tokenId, 'serving');
  console.log('\n3. Reception updated status to serving:');
  console.log(JSON.stringify(servingToken, null, 2));

  const queueStatusServing = await PatientService.getQueueStatus(patient.id);
  console.log('\n4. Patient getQueueStatus when serving:');
  console.log(JSON.stringify(queueStatusServing, null, 2));

  // 4. Reception updates status to done
  const doneToken = await ReceptionService.updateTokenStatus(receptionUser!.id, tokenId, 'done');
  console.log('\n5. Reception updated status to done:');
  console.log(JSON.stringify(doneToken, null, 2));

  // 5. Check patient getQueueStatus within 30 min window (should return completed status)
  const queueStatusDone = await PatientService.getQueueStatus(patient.id);
  console.log('\n6. Patient getQueueStatus within 30m of completion:');
  console.log(JSON.stringify(queueStatusDone, null, 2));

  // 6. Test outside 30 min window: manually update updatedAt to 40 minutes ago
  const fortyMinutesAgo = new Date(Date.now() - 40 * 60 * 1000);
  await prisma.queueToken.update({
    where: { id: tokenId },
    data: { updatedAt: fortyMinutesAgo },
  });
  const queueStatusExpired = await PatientService.getQueueStatus(patient.id);
  console.log('\n7. Patient getQueueStatus after 30m recency window expired:');
  console.log(JSON.stringify(queueStatusExpired, null, 2));
}

testHttpEndpoints().catch(console.error).finally(() => prisma.$disconnect());
