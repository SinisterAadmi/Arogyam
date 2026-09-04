import prisma from '../lib/prisma';
import { auth } from '../lib/firebase';
import { Role } from '@prisma/client';

export class AuthService {
  static async login(idToken: string) {
    const decodedToken = await auth.verifyIdToken(idToken);
    const { uid, phone_number, email } = decodedToken;

    const user = await prisma.user.findUnique({
      where: { firebaseUid: uid },
      include: { patient: true, doctor: true, reception: true, pharmacy: true },
    });

    if (!user) {
      return { status: 'new_user', firebaseUid: uid, phoneNumber: phone_number, email };
    }

    return { status: 'success', user };
  }

  static async registerPatient(idToken: string, data: { name: string; dob?: string; gender?: string }) {
    const decodedToken = await auth.verifyIdToken(idToken);
    const { uid, phone_number, email } = decodedToken;

    const result = await prisma.$transaction(async (tx) => {
      const user = await tx.user.create({
        data: {
          firebaseUid: uid,
          phoneNumber: phone_number || null,
          email: email || null,
          role: Role.patient,
          patient: {
            create: {
              name: data.name,
              dob: data.dob ? new Date(data.dob) : null,
              gender: data.gender,
            },
          },
        },
        include: { patient: true },
      });

      // Set custom claims in Firebase
      await auth.setCustomUserClaims(uid, { role: Role.patient });

      return user;
    });

    return result;
  }
}
