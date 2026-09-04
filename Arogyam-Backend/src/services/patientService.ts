import prisma from '../lib/prisma';
import { getISTMidnight, getISTDateString } from '../utils/timezone';

function calculateHaversineDistanceKm(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 6371; // Earth radius in km
  const dLat = (lat2 - lat1) * (Math.PI / 180);
  const dLon = (lon2 - lon1) * (Math.PI / 180);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * (Math.PI / 180)) * Math.cos(lat2 * (Math.PI / 180)) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  const d = R * c;
  return Math.round(d * 10) / 10;
}

export class PatientService {
  static async getProfile(userId: string) {
    const patient = await prisma.patient.findUnique({
      where: { userId },
      include: { user: { select: { phoneNumber: true, email: true } } },
    });
    if (!patient) return null;
    return {
      id: patient.id,
      name: patient.name,
      abhaId: patient.abhaId,
      imageUrl: patient.imageUrl,
      isAbhaLinked: patient.isAbhaLinked,
      dob: patient.dob,
      gender: patient.gender,
      bloodGroup: patient.bloodGroup,
      address: patient.address,
      emergencyContactName: patient.emergencyContactName,
      emergencyContactPhone: patient.emergencyContactPhone,
      phoneNumber: patient.user?.phoneNumber,
      email: patient.user?.email,
    };
  }

  static async updateProfile(userId: string, data: any) {
    const { email, phoneNumber, dob, id, isAbhaLinked, abhaId, createdAt, updatedAt, ...patientData } = data;
    if (email !== undefined || phoneNumber !== undefined) {
      await prisma.user.update({
        where: { id: userId },
        data: {
          ...(email !== undefined ? { email } : {}),
          ...(phoneNumber !== undefined ? { phoneNumber } : {}),
        },
      });
    }
    const updatePayload: any = { ...patientData };
    if (dob !== undefined) {
      updatePayload.dob = dob ? new Date(dob) : null;
    }
    const patient = await prisma.patient.update({
      where: { userId },
      data: updatePayload,
      include: { user: { select: { phoneNumber: true, email: true } } },
    });
    return {
      id: patient.id,
      name: patient.name,
      abhaId: patient.abhaId,
      imageUrl: patient.imageUrl,
      isAbhaLinked: patient.isAbhaLinked,
      dob: patient.dob,
      gender: patient.gender,
      bloodGroup: patient.bloodGroup,
      address: patient.address,
      emergencyContactName: patient.emergencyContactName,
      emergencyContactPhone: patient.emergencyContactPhone,
      phoneNumber: patient.user?.phoneNumber,
      email: patient.user?.email,
    };
  }

  static async getPrivacySettings(patientId: string) {
    return prisma.privacySettings.upsert({
      where: { patientId },
      update: {},
      create: { patientId },
    });
  }

  static async updatePrivacySettings(patientId: string, data: any) {
    return prisma.privacySettings.update({
      where: { patientId },
      data,
    });
  }

  static async getAccessHistory(patientId: string) {
    return prisma.accessHistory.findMany({
      where: { patientId },
      orderBy: { timestamp: 'desc' },
      take: 20,
    });
  }

  static async getNearbyClinics(lat: number, lng: number) {
    const clinics = await prisma.clinic.findMany({
      include: { doctors: true },
    });
    return clinics.map(c => {
      const distance = (typeof lat === 'number' && typeof lng === 'number' && !isNaN(lat) && !isNaN(lng))
        ? calculateHaversineDistanceKm(lat, lng, c.latitude, c.longitude)
        : 1.5;
      return {
        id: c.id,
        name: c.name,
        address: c.address,
        phone: c.phone || '+91 22 2700 3300',
        specialty: c.specialty || 'General & Multi-Specialty',
        operatingHours: c.operatingHours || 'Mon-Sat 9:00 AM - 8:00 PM',
        description: c.description || 'Comprehensive outpatient healthcare clinic with modern digital queuing.',
        latitude: c.latitude,
        longitude: c.longitude,
        distanceKm: distance,
        waitTimeMinutes: 25,
        isLiveQueueActive: c.isLiveQueueActive,
        isOpen: (c as any).isOpen ?? true,
        rating: c.rating,
        reviewCount: c.reviewCount,
        doctors: c.doctors.map(d => ({
          id: d.id,
          name: d.name,
          specialty: d.specialty,
        })),
      };
    });
  }

  static async getUpcomingAppointments(patientId: string) {
    const appointments = await prisma.appointment.findMany({
      where: {
        patientId,
        scheduledAt: { gte: new Date() },
        status: { in: ['scheduled', 'pending', 'reschedule_requested'] },
      },
      include: { doctor: true, clinic: true },
      orderBy: { scheduledAt: 'asc' },
    });
    return appointments.map(a => ({
      id: a.id, doctorName: a.doctor.name, specialty: a.doctor.specialty,
      clinicName: a.clinic.name, appointmentTime: a.scheduledAt.toISOString(),
      tokenNumber: a.tokenNumber, status: a.status,
    }));
  }

  /**
   * Generates the next daily QueueToken for a clinic with per-day advisory lock.
   * Shared by manual patient queue join, Vapi confirmation, and automated check-ins.
   */
  static async generateQueueToken(patientId: string, clinicId: string) {
    return await prisma.$transaction(async (tx) => {
      // 1. Compute today's date in IST normalized to midnight UTC
      const todayDateStr = getISTDateString(); // YYYY-MM-DD in IST
      const todayMidnight = getISTMidnight();

      // 2. Advisory lock keyed on BOTH clinicId and today's IST date string
      const lockKey = `${clinicId}-${todayDateStr}`;
      await tx.$executeRaw`SELECT pg_advisory_xact_lock(hashtext(${lockKey}))`;

      // 3. Find highest token for this clinic on this queueDate
      const lastToken = await tx.queueToken.findFirst({
        where: { clinicId, queueDate: todayMidnight },
        orderBy: { tokenNumber: 'desc' },
      });

      const nextToken = (lastToken?.tokenNumber || 0) + 1;

      // 4. Create QueueToken with queueDate set to todayMidnight
      return (tx.queueToken as any).create({
        data: {
          patientId,
          clinicId,
          tokenNumber: nextToken,
          status: 'waiting',
          queueDate: todayMidnight,
        },
        include: { clinic: true },
      });
    });
  }

  static async joinQueue(patientId: string, clinicId: string) {
    // 1. Guard against duplicate active queue joins
    const existingActive = await prisma.queueToken.findFirst({
      where: { patientId, status: { in: ['waiting', 'serving'] } },
      include: { clinic: true },
    });
    if (existingActive) {
      const error: any = new Error(`You're already in an active queue at ${existingActive.clinic.name} (Token #${existingActive.tokenNumber})`);
      error.statusCode = 400;
      throw error;
    }

    await this.generateQueueToken(patientId, clinicId);

    // Return the full computed queue status shape immediately
    const computedStatus = await this.getQueueStatus(patientId);
    return computedStatus;
  }

  static async getQueueStatus(patientId: string) {
    const activeToken = await prisma.queueToken.findFirst({
      where: { patientId, status: { in: ['waiting', 'serving'] } },
      include: { clinic: true },
      orderBy: { joinedAt: 'desc' },
    });

    if (activeToken) {
      const peopleAhead = await prisma.queueToken.count({
        where: { clinicId: activeToken.clinicId, status: 'waiting', joinedAt: { lt: activeToken.joinedAt } },
      });
      const currentlyServing = await prisma.queueToken.findFirst({
        where: { clinicId: activeToken.clinicId, status: 'serving' },
        orderBy: { tokenNumber: 'desc' },
      });
      return {
        clinicName: activeToken.clinic.name,
        tokenNumber: activeToken.tokenNumber,
        peopleAhead,
        currentlyServing: currentlyServing?.tokenNumber || 0,
        estimatedWaitTime: peopleAhead * 10,
        status: activeToken.status,
      };
    }

    return null;
  }

  static async getActivePrescriptions(patientId: string) {
    const prescriptions = await prisma.prescription.findMany({
      where: { patientId, status: 'active' },
      include: { doctor: true, clinic: true },
    });
    return prescriptions.map(p => ({
      id: p.id, medicineName: p.medicineName, dosageInstructions: p.dosageInstructions,
      prescribedBy: p.doctor.name, clinicName: p.clinic.name,
      expiryDate: p.expiryDate.toISOString(), status: p.status,
    }));
  }

  static async getMedicalHistory(patientId: string) {
    const records = await prisma.medicalRecord.findMany({
      where: { patientId },
      orderBy: { date: 'desc' },
    });
    return records.map(r => ({
      id: r.id, title: r.title, category: r.category,
      date: r.date.toISOString(), doctorName: r.doctorName, facilityName: r.facilityName,
    }));
  }
}
