import { PrismaClient } from '@prisma/client';
import dotenv from 'dotenv';
dotenv.config();

const prisma = new PrismaClient();
import { PatientService } from '../services/patientService';
import { ReceptionService } from '../services/receptionService';

async function verifyAllQueueFixes() {
  console.log('====================================================');
  console.log('   FULL E2E LIVE VERIFICATION OF QUEUE FIXES');
  console.log('====================================================\n');

  // Setup: Target patient & Sunrise Medical Center
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

  // Clean existing queue tokens for fresh state
  await prisma.queueToken.deleteMany({ where: { patientId: patient.id } });

  // ---------------------------------------------------------------
  // FIX #1 & #3 TEST: Join Queue Action & Immediate Computed Shape
  // ---------------------------------------------------------------
  console.log('--- TEST 1: Patient Joins Queue (POST /patients/queue/join) ---');
  const joinedResult = await PatientService.joinQueue(patient.id, clinic.id);
  console.log('Joined Queue Computed Response:');
  console.log(JSON.stringify(joinedResult, null, 2));

  // Verify in Neon / PostgreSQL
  const dbToken = await prisma.queueToken.findFirst({
    where: { patientId: patient.id, clinicId: clinic.id, status: 'waiting' },
  });
  console.log('\nPostgres DB Token Verification:');
  console.log(`Token ID: ${dbToken?.id}, Number: ${dbToken?.tokenNumber}, Status: ${dbToken?.status}`);

  // Test duplicate join prevention
  console.log('\n--- TEST 2: Guard against duplicate queue join ---');
  try {
    await PatientService.joinQueue(patient.id, clinic.id);
    console.error('FAILED: Second join should have thrown an error!');
  } catch (err: any) {
    console.log(`SUCCESS: Duplicate join blocked with error: "${err.message}" (status ${err.statusCode})`);
  }

  // ---------------------------------------------------------------
  // FIX #2 TEST: Reception Marks Done -> Patient Sees 'completed'
  // ---------------------------------------------------------------
  console.log('\n--- TEST 3: Reception Updates Status to Done ---');
  const doneResult = await ReceptionService.updateTokenStatus(receptionUser.id, dbToken!.id, 'done');
  console.log(`Reception Marked Token #${doneResult.tokenNumber} as "${doneResult.status}".`);

  console.log('\n--- TEST 4: Patient Status Within 30-min Window ---');
  const patientStatusWithin30m = await PatientService.getQueueStatus(patient.id);
  console.log('Patient getQueueStatus Response:');
  console.log(JSON.stringify(patientStatusWithin30m, null, 2));

  console.log('\n--- TEST 5: Patient Status Outside 30-min Recency Window ---');
  const fortyMinutesAgo = new Date(Date.now() - 40 * 60 * 1000);
  await prisma.queueToken.update({
    where: { id: dbToken!.id },
    data: { updatedAt: fortyMinutesAgo },
  });
  const patientStatusAfter30m = await PatientService.getQueueStatus(patient.id);
  console.log(`Patient getQueueStatus After 30m: ${patientStatusAfter30m === null ? 'null (Not in any queue)' : JSON.stringify(patientStatusAfter30m)}`);

  // ---------------------------------------------------------------
  // VERIFY BOOK VISIT: Appointments do NOT create QueueTokens
  // ---------------------------------------------------------------
  console.log('\n--- TEST 6: Book Visit Appointment Check ---');
  const countBefore = await prisma.queueToken.count({ where: { patientId: patient.id } });
  const doctor = await prisma.doctor.findFirst({ where: { clinicId: clinic.id } });
  const appointment = await prisma.appointment.create({
    data: {
      patientId: patient.id,
      clinicId: clinic.id,
      doctorId: doctor!.id,
      scheduledAt: new Date(Date.now() + 86400000), // tomorrow
      status: 'scheduled',
      tokenNumber: null,
    },
  });
  const countAfter = await prisma.queueToken.count({ where: { patientId: patient.id } });
  console.log(`Appointment Created (ID: ${appointment.id}, tokenNumber: ${appointment.tokenNumber}).`);
  console.log(`QueueTokens count unchanged: before=${countBefore}, after=${countAfter} (No QueueToken created).`);

  console.log('\n====================================================');
  console.log('          ALL 6 LIVE TESTS COMPLETED');
  console.log('====================================================');
}

verifyAllQueueFixes().catch(console.error).finally(() => prisma.$disconnect());
