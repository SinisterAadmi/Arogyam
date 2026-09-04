import { PrismaClient, Role } from '@prisma/client';
import dotenv from 'dotenv';
dotenv.config();

const prisma = new PrismaClient();

async function main() {
  const clinic = await prisma.clinic.findFirst({
    where: { name: { contains: 'Sunrise Medical Center', mode: 'insensitive' } },
  });
  if (!clinic) throw new Error('Clinic not found');

  // Find or create patients
  let p1User = await prisma.user.upsert({
    where: { firebaseUid: 'patient-aarav-test' },
    update: { email: 'aarav.sharma@example.com', role: Role.patient },
    create: { firebaseUid: 'patient-aarav-test', email: 'aarav.sharma@example.com', role: Role.patient },
  });
  let patient1 = await prisma.patient.upsert({
    where: { userId: p1User.id },
    update: { name: 'Aarav Sharma' },
    create: { userId: p1User.id, name: 'Aarav Sharma', isAbhaLinked: true },
  });

  let p2User = await prisma.user.upsert({
    where: { firebaseUid: 'patient-neha-test' },
    update: { email: 'neha.gupta@example.com', role: Role.patient },
    create: { firebaseUid: 'patient-neha-test', email: 'neha.gupta@example.com', role: Role.patient },
  });
  let patient2 = await prisma.patient.upsert({
    where: { userId: p2User.id },
    update: { name: 'Neha Gupta' },
    create: { userId: p2User.id, name: 'Neha Gupta', isAbhaLinked: true },
  });

  // Create queue tokens
  const token1 = await prisma.queueToken.create({
    data: {
      clinicId: clinic.id,
      patientId: patient1.id,
      tokenNumber: 101,
      status: 'waiting',
    },
  });

  const token2 = await prisma.queueToken.create({
    data: {
      clinicId: clinic.id,
      patientId: patient2.id,
      tokenNumber: 102,
      status: 'waiting',
    },
  });

  console.log('Successfully added patients to Sunrise Medical Center queue:', {
    token1: { id: token1.id, tokenNumber: token1.tokenNumber, patient: patient1.name },
    token2: { id: token2.id, tokenNumber: token2.tokenNumber, patient: patient2.name },
  });
}

main().catch(console.error).finally(() => prisma.$disconnect());
