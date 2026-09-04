import prisma from '../lib/prisma';
import { ReceptionController } from '../controllers/receptionController';
import { Response } from 'express';
import { AuthRequest } from '../middleware/authMiddleware';

async function testMaliciousPatch() {
  console.log('=== TESTING MALICIOUS PATCH /reception/clinic REQUEST ===\n');

  const receptionUser = await prisma.user.findFirst({
    where: { role: 'reception' },
    include: { reception: { include: { clinic: true } } },
  });

  if (!receptionUser || !receptionUser.reception) {
    throw new Error('No reception user found');
  }

  const initialClinic = await prisma.clinic.findUnique({
    where: { id: receptionUser.reception.clinicId },
  });

  console.log('1. INITIAL POSTGRES CLINIC ROW:');
  console.log({
    id: initialClinic?.id,
    name: initialClinic?.name,
    rating: initialClinic?.rating,
    reviewCount: initialClinic?.reviewCount,
    isLiveQueueActive: initialClinic?.isLiveQueueActive,
  });

  // Prepare malicious payload attempting to manipulate protected fields:
  // rating: 1.0 (or 0.0), reviewCount: 99999, isLiveQueueActive: false/true toggled
  const maliciousPayload = {
    name: initialClinic?.name, // valid field
    rating: 1.0,               // PROTECTED FIELD
    reviewCount: 99999,        // PROTECTED FIELD
    isLiveQueueActive: !initialClinic?.isLiveQueueActive, // PROTECTED FIELD
  };

  console.log('\n2. SENDING MALICIOUS PAYLOAD TO ReceptionController.updateClinic:');
  console.log(maliciousPayload);

  let responseData: any = null;
  let statusCode: number = 200;

  const req = {
    user: {
      uid: receptionUser.firebaseUid,
      email: receptionUser.email,
      role: receptionUser.role,
      dbUserId: receptionUser.id,
    },
    body: maliciousPayload,
  } as unknown as AuthRequest;

  const res = {
    status(code: number) {
      statusCode = code;
      return this;
    },
    json(data: any) {
      responseData = data;
      return this;
    },
  } as unknown as Response;

  await ReceptionController.updateClinic(req, res);

  console.log('\n3. CONTROLLER RESPONSE (Status Code:', statusCode, '):');
  console.log(responseData);

  // Now query the actual Postgres row from the database directly
  const finalClinic = await prisma.clinic.findUnique({
    where: { id: receptionUser.reception.clinicId },
  });

  console.log('\n4. ACTUAL POSTGRES CLINIC ROW AFTER PATCH:');
  console.log({
    id: finalClinic?.id,
    name: finalClinic?.name,
    rating: finalClinic?.rating,
    reviewCount: finalClinic?.reviewCount,
    isLiveQueueActive: finalClinic?.isLiveQueueActive,
  });

  const ratingUnchanged = finalClinic?.rating === initialClinic?.rating;
  const reviewCountUnchanged = finalClinic?.reviewCount === initialClinic?.reviewCount;
  const isLiveQueueActiveUnchanged = finalClinic?.isLiveQueueActive === initialClinic?.isLiveQueueActive;

  console.log('\n5. VERIFICATION SUMMARY:');
  console.log(`- rating protected: ${ratingUnchanged} (Initial: ${initialClinic?.rating}, Final: ${finalClinic?.rating})`);
  console.log(`- reviewCount protected: ${reviewCountUnchanged} (Initial: ${initialClinic?.reviewCount}, Final: ${finalClinic?.reviewCount})`);
  console.log(`- isLiveQueueActive protected: ${isLiveQueueActiveUnchanged} (Initial: ${initialClinic?.isLiveQueueActive}, Final: ${finalClinic?.isLiveQueueActive})`);

  if (!ratingUnchanged || !reviewCountUnchanged || !isLiveQueueActiveUnchanged) {
    console.error('CRITICAL: Protected fields were overwritten!');
  } else {
    console.log('SUCCESS: All protected fields remained strictly unchanged in the Postgres database.');
  }

  // Now test toggling isOpen to false and back to true
  console.log('\n=== TESTING CLINIC IS_OPEN TOGGLE ===');
  const toggleReq = {
    user: {
      uid: receptionUser.firebaseUid,
      email: receptionUser.email,
      role: receptionUser.role,
      dbUserId: receptionUser.id,
    },
    body: { isOpen: false },
  } as unknown as AuthRequest;

  await ReceptionController.updateClinic(toggleReq, res);
  console.log('Toggled isOpen: false -> Response isOpen:', responseData.isOpen);

  let checkRow = await prisma.clinic.findUnique({
    where: { id: receptionUser.reception.clinicId },
  });
  console.log('Postgres row isOpen after toggling false:', (checkRow as any)?.isOpen);

  // Toggle back to true
  toggleReq.body = { isOpen: true };
  await ReceptionController.updateClinic(toggleReq, res);
  console.log('Toggled isOpen: true -> Response isOpen:', responseData.isOpen);

  checkRow = await prisma.clinic.findUnique({
    where: { id: receptionUser.reception.clinicId },
  });
  console.log('Postgres row isOpen after toggling true:', (checkRow as any)?.isOpen);
  console.log('SUCCESS: isOpen toggling verified end-to-end.');
}

testMaliciousPatch()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
