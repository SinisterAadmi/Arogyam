import { PrismaClient, Role, QueueStatus } from '@prisma/client';
import dotenv from 'dotenv';
dotenv.config();

const prisma = new PrismaClient();
const BASE_URL = 'http://127.0.0.1:3000/api';

async function runDiagnosis() {
  console.log('=====================================================');
  console.log('DIAGNOSIS: PATIENT <-> RECEPTION QUEUE SYNC');
  console.log('=====================================================\n');

  // STEP 1 — Verify Setup & Clinic IDs
  console.log('--- STEP 1: Verify Clinic & Account Association ---');
  const receptionUser = await prisma.user.findFirst({
    where: { email: 'reception.sunrise@arogyam.test' },
    include: { reception: { include: { clinic: true } } },
  });
  if (!receptionUser || !receptionUser.reception) {
    throw new Error('Reception user not found');
  }
  const receptionClinicId = receptionUser.reception.clinicId;
  const receptionClinicName = receptionUser.reception.clinic.name;
  console.log(`[Step 1] Reception Staff User: ${receptionUser.email} (ID: ${receptionUser.id})`);
  console.log(`[Step 1] Reception Linked Clinic: "${receptionClinicName}" (ID: ${receptionClinicId})`);

  const patient = await prisma.patient.findFirst({
    where: { user: { phoneNumber: '+917276633833' } },
    include: { user: true },
  });
  if (!patient) throw new Error('Patient (+917276633833) not found');
  console.log(`[Step 1] Patient User: ${patient.name} (${patient.user.phoneNumber}) (Patient ID: ${patient.id}, User ID: ${patient.userId})\n`);

  // Clean existing queue tokens for this patient today to have a deterministic test
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  await prisma.queueToken.deleteMany({
    where: { patientId: patient.id },
  });

  // STEP 2 — Patient joins queue at Sunrise Medical Center
  console.log('--- STEP 2: Patient Joins Queue & Reception Visibility ---');
  console.log(`[Step 2.1] Simulating Patient joining queue at clinicId: ${receptionClinicId}`);
  
  // Directly execute PatientService.joinQueue logic / API contract
  const joinResult = await prisma.$transaction(async (tx) => {
    const lockKey = 101;
    await tx.$executeRawUnsafe(`SELECT pg_advisory_xact_lock(${lockKey})`);
    const lastToken = await tx.queueToken.findFirst({
      where: { clinicId: receptionClinicId, joinedAt: { gte: today } },
      orderBy: { tokenNumber: 'desc' },
    });
    const nextToken = (lastToken?.tokenNumber || 0) + 1;
    return tx.queueToken.create({
      data: { patientId: patient.id, clinicId: receptionClinicId, tokenNumber: nextToken, status: 'waiting' },
      include: { clinic: true },
    });
  });

  console.log('[Step 2.1] DB QueueToken created:', {
    id: joinResult.id,
    tokenNumber: joinResult.tokenNumber,
    clinicId: joinResult.clinicId,
    patientId: joinResult.patientId,
    status: joinResult.status,
    joinedAt: joinResult.joinedAt,
  });

  // Query Postgres directly to confirm row exists
  const dbToken = await prisma.queueToken.findUnique({
    where: { id: joinResult.id },
    include: { clinic: true, patient: true },
  });
  console.log('[Step 2.2] Postgres Direct Query Result for new Token:');
  console.log(JSON.stringify(dbToken, null, 2));

  // Test Reception Service getLiveQueue for this clinic
  const { ReceptionService } = await import('../services/receptionService');
  const receptionQueue = await ReceptionService.getLiveQueue(receptionUser.id);
  console.log('[Step 2.3] Reception getLiveQueue response for Sunrise Medical Center:');
  console.log(JSON.stringify(receptionQueue, null, 2));

  const isTokenInReception = receptionQueue.tokens.some((t: any) => t.id === joinResult.id);
  console.log(`[Step 2.4] Is new patient token present in Reception Queue? => ${isTokenInReception ? 'YES (PASS)' : 'NO (FAIL)'}\n`);

  // STEP 3 — Reception updates status to 'serving' and then 'done', check Patient Status
  console.log('--- STEP 3: Reception Updates Status -> Check Patient View ---');
  console.log(`[Step 3.1] Reception updating token #${joinResult.tokenNumber} to 'serving'...`);
  const updatedToServing = await ReceptionService.updateTokenStatus(receptionUser.id, joinResult.id, 'serving');
  console.log('[Step 3.1] Reception update response (serving):', JSON.stringify(updatedToServing, null, 2));

  const dbTokenServing = await prisma.queueToken.findUnique({ where: { id: joinResult.id } });
  console.log(`[Step 3.2] Postgres status after update to serving: "${dbTokenServing?.status}"`);

  // Check Patient getQueueStatus
  const { PatientService } = await import('../services/patientService');
  const patientStatusServing = await PatientService.getQueueStatus(patient.id);
  console.log('[Step 3.3] Patient getQueueStatus response when status = "serving":');
  console.log(JSON.stringify(patientStatusServing, null, 2));

  console.log(`\n[Step 3.4] Reception updating token #${joinResult.tokenNumber} to 'done'...`);
  const updatedToDone = await ReceptionService.updateTokenStatus(receptionUser.id, joinResult.id, 'done');
  console.log('[Step 3.4] Reception update response (done):', JSON.stringify(updatedToDone, null, 2));

  const dbTokenDone = await prisma.queueToken.findUnique({ where: { id: joinResult.id } });
  console.log(`[Step 3.5] Postgres status after update to done: "${dbTokenDone?.status}"`);

  const patientStatusDone = await PatientService.getQueueStatus(patient.id);
  console.log('[Step 3.6] Patient getQueueStatus response when status = "done":');
  console.log(JSON.stringify(patientStatusDone, null, 2));

  console.log('\n=====================================================');
  console.log('DIAGNOSIS COMPLETE');
  console.log('=====================================================');
}

runDiagnosis().catch(console.error).finally(() => prisma.$disconnect());
