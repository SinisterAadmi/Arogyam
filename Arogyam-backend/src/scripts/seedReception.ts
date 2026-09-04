import { PrismaClient, Role } from '@prisma/client';
import { auth } from '../lib/firebase';

const prisma = new PrismaClient();

async function main() {
  const email = 'reception.sunrise@arogyam.test';
  const password = 'TestPassword123!';
  const displayName = 'Sunrise Reception Staff';

  console.log(`Setting up Firebase Auth user: ${email}...`);
  let firebaseUser;
  try {
    firebaseUser = await auth.getUserByEmail(email);
    console.log(`Found existing Firebase user with UID: ${firebaseUser.uid}`);
    await auth.updateUser(firebaseUser.uid, {
      password,
      displayName,
    });
  } catch (error: any) {
    if (error.code === 'auth/user-not-found') {
      firebaseUser = await auth.createUser({
        email,
        password,
        displayName,
      });
      console.log(`Created new Firebase user with UID: ${firebaseUser.uid}`);
    } else {
      throw error;
    }
  }

  // Set custom user claims for role: 'reception'
  await auth.setCustomUserClaims(firebaseUser.uid, { role: 'reception' });
  console.log(`Custom claims set: { role: 'reception' } for UID: ${firebaseUser.uid}`);

  // Find Sunrise Medical Center clinic
  let clinic = await prisma.clinic.findFirst({
    where: { name: { contains: 'Sunrise Medical Center', mode: 'insensitive' } },
  });

  if (!clinic) {
    console.log('Sunrise Medical Center not found, checking any clinic...');
    clinic = await prisma.clinic.findFirst();
  }

  if (!clinic) {
    console.log('No clinic found. Creating Sunrise Medical Center...');
    clinic = await prisma.clinic.create({
      data: {
        name: 'Sunrise Medical Center',
        address: '789 East Blvd, Mumbai',
        latitude: 19.095,
        longitude: 72.8999,
        isLiveQueueActive: true,
        rating: 4.8,
        reviewCount: 200,
      },
    });
  }

  console.log(`Using Clinic: ${clinic.name} (${clinic.id})`);

  // Upsert Postgres User
  const user = await prisma.user.upsert({
    where: { firebaseUid: firebaseUser.uid },
    update: {
      email,
      role: Role.reception,
    },
    create: {
      firebaseUid: firebaseUser.uid,
      email,
      role: Role.reception,
    },
  });

  console.log(`Postgres User ID: ${user.id}`);

  // Upsert Postgres Reception
  const reception = await prisma.reception.upsert({
    where: { userId: user.id },
    update: {
      clinicId: clinic.id,
      name: displayName,
    },
    create: {
      userId: user.id,
      clinicId: clinic.id,
      name: displayName,
    },
  });

  console.log(`Postgres Reception ID: ${reception.id}, Clinic: ${clinic.name}`);
  console.log('Reception seeding complete!');
}

main()
  .catch((e) => {
    console.error('Seed error:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
