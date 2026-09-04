import prisma from '../lib/prisma';
import { QueueStatus } from '@prisma/client';
import { getISTMidnight, getISTDayBounds, toIST } from '../utils/timezone';

export class ReceptionService {
  static async getReceptionByUserId(userId: string) {
    const reception = await prisma.reception.findUnique({
      where: { userId },
      include: { clinic: true },
    });
    if (!reception) {
      const error: any = new Error('Reception record not found for user');
      error.statusCode = 404;
      throw error;
    }
    return reception;
  }

  static async getLiveQueue(userId: string) {
    const reception = await this.getReceptionByUserId(userId);
    const todayMidnight = getISTMidnight();

    const tokens = await prisma.queueToken.findMany({
      where: {
        clinicId: reception.clinicId,
        queueDate: todayMidnight,
      },
      include: {
        patient: true,
      },
      orderBy: {
        tokenNumber: 'asc',
      },
    });

    // Fetch appointments for today's tokens to include appointmentStatus
    const tokenNumbers = tokens.map((t) => t.tokenNumber);
    const appointments = await prisma.appointment.findMany({
      where: {
        clinicId: reception.clinicId,
        tokenNumber: { in: tokenNumbers },
      },
      select: {
        tokenNumber: true,
        status: true,
      },
    });
    const appointmentStatusMap = new Map<number, string>();
    for (const appt of appointments) {
      if (appt.tokenNumber !== null) {
        appointmentStatusMap.set(appt.tokenNumber, appt.status);
      }
    }

    const waitingCount = tokens.filter((t) => t.status === 'waiting').length;
    const servingToken = tokens.find((t) => t.status === 'serving');

    return {
      clinic: {
        id: reception.clinic.id,
        name: reception.clinic.name,
        isLiveQueueActive: reception.clinic.isLiveQueueActive,
      },
      stats: {
        totalToday: tokens.length,
        waitingCount,
        currentlyServing: servingToken ? servingToken.tokenNumber : null,
      },
      tokens: tokens.map((t) => ({
        id: t.id,
        tokenNumber: t.tokenNumber,
        status: t.status,
        appointmentStatus: appointmentStatusMap.get(t.tokenNumber) ?? null,
        patientId: t.patientId,
        patientName: t.patient.name,
        phoneNumber: t.patient.emergencyContactPhone || null,
        joinedAt: t.joinedAt.toISOString(),
        updatedAt: t.updatedAt.toISOString(),
      })),
    };
  }

  static async getUpcomingAppointments(userId: string) {
    const reception = await this.getReceptionByUserId(userId);
    const { end: todayISTEnd } = getISTDayBounds();

    const appointments = await prisma.appointment.findMany({
      where: {
        clinicId: reception.clinicId,
        scheduledAt: { gt: todayISTEnd },
      },
      include: {
        patient: true,
        doctor: true,
      },
      orderBy: {
        scheduledAt: 'asc',
      },
    });

    return appointments.map((a) => ({
      id: a.id,
      patientId: a.patientId,
      patientName: a.patient.name,
      doctorName: a.doctor.name,
      specialty: a.doctor.specialty,
      scheduledAt: a.scheduledAt.toISOString(),
      status: a.status,
      tokenNumber: a.tokenNumber ?? null,
      notes: a.notes,
    }));
  }

  static async updateTokenStatus(userId: string, tokenId: string, newStatus: string) {
    const reception = await this.getReceptionByUserId(userId);

    // Validate status value
    const validStatuses = Object.values(QueueStatus);
    if (!validStatuses.includes(newStatus as QueueStatus)) {
      const error: any = new Error(`Invalid status. Must be one of: ${validStatuses.join(', ')}`);
      error.statusCode = 400;
      throw error;
    }

    // Verify token belongs to reception's clinic
    const token = await prisma.queueToken.findUnique({
      where: { id: tokenId },
      include: { patient: true },
    });

    if (!token) {
      const error: any = new Error('Queue token not found');
      error.statusCode = 404;
      throw error;
    }

    if (token.clinicId !== reception.clinicId) {
      const error: any = new Error('Forbidden: Token does not belong to your clinic');
      error.statusCode = 403;
      throw error;
    }

    const updated = await prisma.queueToken.update({
      where: { id: tokenId },
      data: { status: newStatus as QueueStatus },
      include: { patient: true, clinic: true },
    });

    return {
      id: updated.id,
      tokenNumber: updated.tokenNumber,
      status: updated.status,
      patientId: updated.patientId,
      patientName: updated.patient.name,
      clinicId: updated.clinicId,
      clinicName: updated.clinic.name,
      joinedAt: updated.joinedAt.toISOString(),
      updatedAt: updated.updatedAt.toISOString(),
    };
  }

  static async getAiCallbacks(userId: string) {
    const reception = await this.getReceptionByUserId(userId);

    const callbacks = await prisma.aiCallbackRequest.findMany({
      where: {
        clinicId: reception.clinicId,
        status: 'pending',
      },
      include: { patient: true },
      orderBy: { createdAt: 'desc' },
    });

    return callbacks.map((cb) => ({
      id: cb.id,
      patientId: cb.patientId,
      patientName: cb.patient.name,
      phone: cb.phone,
      status: cb.status,
      requestedSlot: cb.requestedSlot.toISOString(),
      createdAt: cb.createdAt.toISOString(),
    }));
  }

  static async resolveAiCallback(userId: string, callbackId: string) {
    const reception = await this.getReceptionByUserId(userId);

    const callback = await prisma.aiCallbackRequest.findUnique({
      where: { id: callbackId },
    });

    if (!callback) {
      const error: any = new Error('AI Callback request not found');
      error.statusCode = 404;
      throw error;
    }

    if (callback.clinicId !== reception.clinicId) {
      const error: any = new Error('Forbidden: Callback request does not belong to your clinic');
      error.statusCode = 403;
      throw error;
    }

    const updated = await prisma.aiCallbackRequest.update({
      where: { id: callbackId },
      data: { status: 'resolved' },
    });

    return {
      success: true,
      message: 'AI Callback request marked as resolved',
      id: updated.id,
      status: updated.status,
    };
  }

  static async getAnalytics(userId: string) {
    const reception = await this.getReceptionByUserId(userId);
    const todayMidnight = getISTMidnight();
    const { start: todayISTStart, end: todayISTEnd } = getISTDayBounds();

    // Get today's queue tokens
    const tokens = await prisma.queueToken.findMany({
      where: {
        clinicId: reception.clinicId,
        queueDate: todayMidnight,
      },
      include: { patient: true },
      orderBy: { joinedAt: 'asc' },
    });

    // Get today's appointments
    const appointmentsCount = await prisma.appointment.count({
      where: {
        clinicId: reception.clinicId,
        scheduledAt: { gte: todayISTStart, lte: todayISTEnd },
      },
    });

    const servedTokens = tokens.filter((t) => t.status === 'done');
    const waitingTokens = tokens.filter((t) => t.status === 'waiting');
    const servingToken = tokens.find((t) => t.status === 'serving');

    // Calculate real average wait time for served / serving tokens
    let totalWaitMinutes = 0;
    const completedOrServingTokens = tokens.filter((t) => t.status === 'done' || t.status === 'serving');
    for (const t of completedOrServingTokens) {
      const waitMs = t.updatedAt.getTime() - t.joinedAt.getTime();
      const waitMins = Math.max(1, Math.round(waitMs / (1000 * 60)));
      totalWaitMinutes += waitMins;
    }

    const avgWaitTime = completedOrServingTokens.length > 0
      ? Math.round(totalWaitMinutes / completedOrServingTokens.length)
      : (waitingTokens.length * 10 || 0);

    // Compute hourly patient flow breakdown (e.g. 08:00 to 18:00) in IST
    const hours = ['08:00', '09:00', '10:00', '11:00', '12:00', '13:00', '14:00', '15:00', '16:00', '17:00', '18:00'];
    const hourlyFlow = hours.map((hourStr) => {
      const hourNum = parseInt(hourStr.split(':')[0], 10);
      const count = tokens.filter((t) => {
        // Convert joinedAt to IST to get the accurate Indian Standard Time hour
        const istDate = toIST(t.joinedAt);
        const tokenHour = istDate.getUTCHours();
        return tokenHour === hourNum;
      }).length;
      return { hour: hourStr, count };
    });

    return {
      clinic: {
        id: reception.clinic.id,
        name: reception.clinic.name,
      },
      stats: {
        totalPatientsToday: tokens.length,
        patientsServedToday: servedTokens.length,
        currentlyWaiting: waitingTokens.length,
        currentlyServing: servingToken ? servingToken.tokenNumber : null,
        averageWaitTimeMinutes: avgWaitTime,
        totalAppointmentsToday: appointmentsCount,
      },
      hourlyFlow,
    };
  }

  static async getClinic(userId: string) {
    const reception = await this.getReceptionByUserId(userId);
    return {
      id: reception.clinic.id,
      name: reception.clinic.name,
      address: reception.clinic.address,
      phone: reception.clinic.phone || '+91 22 2700 3300',
      specialty: reception.clinic.specialty || 'General & Multi-Specialty',
      operatingHours: reception.clinic.operatingHours || 'Mon-Sat 9:00 AM - 8:00 PM',
      description: reception.clinic.description || 'Comprehensive outpatient healthcare clinic with modern digital queuing.',
      latitude: reception.clinic.latitude,
      longitude: reception.clinic.longitude,
      isLiveQueueActive: reception.clinic.isLiveQueueActive,
      isOpen: (reception.clinic as any).isOpen ?? true,
      rating: reception.clinic.rating,
      reviewCount: reception.clinic.reviewCount,
    };
  }

  static async updateClinic(
    userId: string,
    data: {
      name?: string;
      address?: string;
      phone?: string;
      specialty?: string;
      operatingHours?: string;
      description?: string;
      latitude?: number;
      longitude?: number;
      isOpen?: boolean;
    }
  ) {
    const reception = await this.getReceptionByUserId(userId);

    // Whitelisted editable fields only (rating, reviewCount, isLiveQueueActive strictly ignored)
    const updateData: any = {};
    if (data.name !== undefined && data.name.trim() !== '') {
      updateData.name = data.name.trim();
    }
    if (data.address !== undefined && data.address.trim() !== '') {
      updateData.address = data.address.trim();
    }
    if (data.phone !== undefined) {
      updateData.phone = data.phone.trim();
    }
    if (data.specialty !== undefined) {
      updateData.specialty = data.specialty.trim();
    }
    if (data.operatingHours !== undefined) {
      updateData.operatingHours = data.operatingHours.trim();
    }
    if (data.description !== undefined) {
      updateData.description = data.description.trim();
    }
    if (data.latitude !== undefined && typeof data.latitude === 'number') {
      updateData.latitude = data.latitude;
    }
    if (data.longitude !== undefined && typeof data.longitude === 'number') {
      updateData.longitude = data.longitude;
    }
    if (typeof data.isOpen === 'boolean') {
      updateData.isOpen = data.isOpen;
    }

    const updated = await prisma.clinic.update({
      where: { id: reception.clinicId },
      data: updateData,
    });

    return {
      id: updated.id,
      name: updated.name,
      address: updated.address,
      phone: updated.phone || '+91 22 2700 3300',
      specialty: updated.specialty || 'General & Multi-Specialty',
      operatingHours: updated.operatingHours || 'Mon-Sat 9:00 AM - 8:00 PM',
      description: updated.description || 'Comprehensive outpatient healthcare clinic with modern digital queuing.',
      latitude: updated.latitude,
      longitude: updated.longitude,
      isLiveQueueActive: updated.isLiveQueueActive,
      isOpen: (updated as any).isOpen ?? true,
      rating: updated.rating,
      reviewCount: updated.reviewCount,
    };
  }
}
