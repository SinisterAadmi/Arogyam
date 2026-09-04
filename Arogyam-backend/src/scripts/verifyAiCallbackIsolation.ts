import { PrismaClient } from '@prisma/client';
import dotenv from 'dotenv';
dotenv.config();

const prisma = new PrismaClient();
import { ReceptionService } from '../services/receptionService';

async function verifyAiCallbackIsolation() {
  console.log('===========================================================');
  console.log('  TEST: AI CALLBACK CLINIC ISOLATION VERIFICATION');
  console.log('===========================================================\n');

  // 1. Identify Sunrise Medical Center & its Reception User
  const sunriseClinic = await prisma.clinic.findFirst({
    where: { name: 'Sunrise Medical Center' },
  });
  if (!sunriseClinic) throw new Error('Sunrise Medical Center clinic not found');

  const sunriseReceptionUser = await prisma.user.findFirst({
    where: { email: 'reception.sunrise@arogyam.test' },
  });
  if (!sunriseReceptionUser) throw new Error('Sunrise reception user not found');

  // 2. Identify or find a second clinic (e.g. City Care Hospital)
  let otherClinic = await prisma.clinic.findFirst({
    where: { id: { not: sunriseClinic.id } },
  });
  if (!otherClinic) {
    otherClinic = await prisma.clinic.create({
      data: {
        name: 'City Care Hospital',
        address: '456 MG Road, Bangalore',
        latitude: 12.9716,
        longitude: 77.5946,
        isLiveQueueActive: true,
      },
    });
  }

  console.log(`Clinic A (Target): "${sunriseClinic.name}" (ID: ${sunriseClinic.id})`);
  console.log(`Clinic B (Other):  "${otherClinic.name}" (ID: ${otherClinic.id})`);
  console.log(`Reception User:    "${sunriseReceptionUser.email}" (ID: ${sunriseReceptionUser.id})\n`);

  const patient = await prisma.patient.findFirst({
    include: { user: true },
  });
  if (!patient) throw new Error('Patient not found');

  // 3. Create a unique AI callback request for Clinic B (Other Clinic)
  const otherClinicCallback = await prisma.aiCallbackRequest.create({
    data: {
      patientId: patient.id,
      clinicId: otherClinic.id,
      phone: '+919999988888',
      status: 'pending',
      requestedSlot: new Date(Date.now() + 30 * 60 * 1000),
    },
  });
  console.log(`Created Callback at OTHER clinic (${otherClinic.name}): ID=${otherClinicCallback.id}, Phone=${otherClinicCallback.phone}`);

  // 4. Create a unique AI callback request for Sunrise Clinic
  const sunriseCallback = await prisma.aiCallbackRequest.create({
    data: {
      patientId: patient.id,
      clinicId: sunriseClinic.id,
      phone: '+917276633833',
      status: 'pending',
      requestedSlot: new Date(Date.now() + 15 * 60 * 1000),
    },
  });
  console.log(`Created Callback at SUNRISE clinic (${sunriseClinic.name}): ID=${sunriseCallback.id}, Phone=${sunriseCallback.phone}\n`);

  // 5. Query Reception AI callbacks as Sunrise reception user
  console.log('--- Calling ReceptionService.getAiCallbacks(sunriseReceptionUser.id) ---');
  const result = await ReceptionService.getAiCallbacks(sunriseReceptionUser.id);
  console.log(`Total callbacks returned: ${result.length}`);
  console.log('Actual Response Payload:');
  console.log(JSON.stringify(result, null, 2));

  // 6. Assert isolation
  const containsSunrise = result.some((cb) => cb.id === sunriseCallback.id);
  const containsOther = result.some((cb) => cb.id === otherClinicCallback.id);

  console.log('\n--- Verification Results ---');
  console.log(`Contains Sunrise Callback (${sunriseCallback.id}): ${containsSunrise ? 'YES (PASS)' : 'NO (FAIL)'}`);
  console.log(`Contains Other Clinic Callback (${otherClinicCallback.id}): ${containsOther ? 'YES (LEAK/FAIL)' : 'NO (ISOLATED/PASS)'}`);

  // 7. Test cross-clinic resolution authorization guard
  console.log('\n--- Cross-Clinic Resolve Guard Test ---');
  try {
    await ReceptionService.resolveAiCallback(sunriseReceptionUser.id, otherClinicCallback.id);
    console.error('FAIL: Should have blocked resolving another clinic callback!');
  } catch (err: any) {
    console.log(`PASS: Cross-clinic resolve blocked with: "${err.message}" (HTTP ${err.statusCode})`);
  }

  // Cleanup test-created records
  await prisma.aiCallbackRequest.deleteMany({
    where: { id: { in: [otherClinicCallback.id, sunriseCallback.id] } },
  });
}

verifyAiCallbackIsolation()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
