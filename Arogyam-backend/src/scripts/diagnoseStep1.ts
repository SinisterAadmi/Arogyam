import { PrismaClient } from '@prisma/client';
import dotenv from 'dotenv';
dotenv.config();

const prisma = new PrismaClient();

async function runStep1() {
  console.log('=== STEP 1: TEST SETUP CONFIRMATION ===');
  
  // 1. Check Reception row for reception.sunrise@arogyam.test
  const user = await prisma.user.findFirst({
    where: { email: 'reception.sunrise@arogyam.test' },
    include: { reception: { include: { clinic: true } } },
  });

  console.log('Reception User:', JSON.stringify(user, null, 2));

  // 2. Check all clinics in DB
  const clinics = await prisma.clinic.findMany();
  console.log('All Clinics in DB:', JSON.stringify(clinics, null, 2));

  // 3. Check Patient user (e.g. 7276633833 or patient-aarav-test or other patients)
  const patients = await prisma.patient.findMany({
    include: { user: true },
  });
  console.log('Patients in DB:', JSON.stringify(patients.map(p => ({
    id: p.id,
    name: p.name,
    userId: p.userId,
    firebaseUid: p.user.firebaseUid,
    phoneNumber: p.user.phoneNumber,
    email: p.user.email
  })), null, 2));
}

runStep1().catch(console.error).finally(() => prisma.$disconnect());
