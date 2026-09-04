import { PrismaClient, Role } from '@prisma/client';
import { auth } from '../lib/firebase';

const prisma = new PrismaClient();
const BASE_URL = 'http://localhost:3000';

async function main() {
  console.log('--- TEST: RECEPTION BACKEND ENDPOINTS ---');

  // 1. Get Firebase User for reception
  const receptionUser = await auth.getUserByEmail('reception.sunrise@arogyam.test');
  console.log('Testing /api/auth/login with reception user...');
  const dbUser = await prisma.user.findUnique({
    where: { firebaseUid: receptionUser.uid },
    include: { reception: { include: { clinic: true } } },
  });
  console.log('Seeded Reception User:', {
    id: dbUser?.id,
    email: dbUser?.email,
    role: dbUser?.role,
    clinic: dbUser?.reception?.clinic.name,
  });

  // Let's create a patient and add them to Sunrise Medical Center queue
  const sunriseClinic = dbUser!.reception!.clinic;
  let patient = await prisma.patient.findFirst({
    where: { user: { role: Role.patient } },
  });

  if (!patient) {
    const pUser = await prisma.user.create({
      data: {
        firebaseUid: 'test-patient-qa-uid',
        email: 'test.patient.qa@arogyam.test',
        role: Role.patient,
      },
    });
    patient = await prisma.patient.create({
      data: {
        userId: pUser.id,
        name: 'Aarav Sharma',
        isAbhaLinked: true,
      },
    });
  }

  // Create queue token in Sunrise clinic
  const token = await prisma.queueToken.create({
    data: {
      clinicId: sunriseClinic.id,
      patientId: patient.id,
      tokenNumber: Math.floor(Math.random() * 900) + 100,
      status: 'waiting',
    },
  });
  console.log('Created QueueToken in Sunrise clinic:', {
    id: token.id,
    tokenNumber: token.tokenNumber,
    clinic: sunriseClinic.name,
  });

  // Create another clinic & token to test scoping
  let otherClinic = await prisma.clinic.findFirst({
    where: { id: { not: sunriseClinic.id } },
  });
  if (!otherClinic) {
    otherClinic = await prisma.clinic.create({
      data: {
        name: 'Other Health Center',
        address: '999 Other St',
        latitude: 19.1,
        longitude: 72.9,
      },
    });
  }
  const otherToken = await prisma.queueToken.create({
    data: {
      clinicId: otherClinic.id,
      patientId: patient.id,
      tokenNumber: 999,
      status: 'waiting',
    },
  });

  // Test ReceptionService directly to verify logic & scoping
  const { ReceptionService } = await import('../services/receptionService');
  const liveQueue = await ReceptionService.getLiveQueue(dbUser!.id);
  console.log('Live Queue for Sunrise Medical Center:', {
    clinic: liveQueue.clinic.name,
    totalToday: liveQueue.stats.totalToday,
    waitingCount: liveQueue.stats.waitingCount,
    tokensCount: liveQueue.tokens.length,
    foundOurToken: liveQueue.tokens.some((t) => t.id === token.id),
    otherClinicTokenExcluded: !liveQueue.tokens.some((t) => t.id === otherToken.id),
  });

  if (!liveQueue.tokens.some((t) => t.id === token.id)) {
    throw new Error('Sunrise token was not found in Sunrise clinic live queue!');
  }
  if (liveQueue.tokens.some((t) => t.id === otherToken.id)) {
    throw new Error('Other clinic token leaked into Sunrise clinic live queue!');
  }
  console.log('PASS: Scoping check 1: Only Sunrise tokens returned.');

  // Test updating status: waiting -> serving
  const servingResult = await ReceptionService.updateTokenStatus(dbUser!.id, token.id, 'serving');
  console.log('Updated token status to serving:', servingResult.status);
  if (servingResult.status !== 'serving') throw new Error('Failed to set status to serving');

  // Test updating status: serving -> done
  const doneResult = await ReceptionService.updateTokenStatus(dbUser!.id, token.id, 'done');
  console.log('Updated token status to done:', doneResult.status);
  if (doneResult.status !== 'done') throw new Error('Failed to set status to done');

  // Test scoping check 2: Attempting to update otherClinic token must throw 403
  let scopingBlocked = false;
  try {
    await ReceptionService.updateTokenStatus(dbUser!.id, otherToken.id, 'serving');
  } catch (err: any) {
    if (err.statusCode === 403) {
      scopingBlocked = true;
      console.log('PASS: Scoping check 2: Cross-clinic token update properly blocked with 403 Forbidden.');
    }
  }
  if (!scopingBlocked) {
    throw new Error('Security vulnerability: Cross-clinic token update was NOT blocked!');
  }

  // Cleanup test tokens
  await prisma.queueToken.deleteMany({
    where: { id: { in: [token.id, otherToken.id] } },
  });

  console.log('ALL RECEPTION BACKEND SERVICE & SCOPING CHECKS PASSED!');
}

main()
  .catch((e) => {
    console.error('Backend test failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
