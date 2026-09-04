import { PrismaClient } from '@prisma/client';
import crypto from 'crypto';

const prisma = new PrismaClient();

const SHORT_CODE_CHARS = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';

export class ConsentSessionService {
  private static generateShortCode(): string {
    let result = '';
    const bytes = crypto.randomBytes(6);
    for (let i = 0; i < 6; i++) {
      result += SHORT_CODE_CHARS[bytes[i] % SHORT_CODE_CHARS.length];
    }
    return result;
  }

  static async createSession(patientId: string) {
    // Invalidate any existing active sessions for this patient
    await prisma.consentSession.updateMany({
      where: {
        patientId,
        status: 'active',
      },
      data: {
        status: 'expired',
      },
    });

    let shortCode = this.generateShortCode();
    // Ensure code uniqueness among active sessions
    let existing = await prisma.consentSession.findFirst({
      where: { shortCode, status: 'active' },
    });
    while (existing) {
      shortCode = this.generateShortCode();
      existing = await prisma.consentSession.findFirst({
        where: { shortCode, status: 'active' },
      });
    }

    const now = new Date();
    const sessionExpiresAt = new Date(now.getTime() + 5 * 60 * 1000); // 5 minutes
    const codeExpiresAt = new Date(now.getTime() + 2 * 60 * 1000); // 2 minutes

    const session = await prisma.consentSession.create({
      data: {
        patientId,
        shortCode,
        status: 'active',
        sessionExpiresAt,
        codeExpiresAt,
        codeFailedAttempts: 0,
      },
    });

    return {
      sessionId: session.id,
      shortCode: session.shortCode,
      qrToken: session.qrToken,
      expiresAt: session.sessionExpiresAt.toISOString(),
      codeExpiresAt: session.codeExpiresAt.toISOString(),
      status: session.status,
    };
  }

  static async verifyCode(sessionId: string, inputCode: string) {
    const session = await prisma.consentSession.findUnique({
      where: { id: sessionId },
    });

    if (!session) {
      const error: any = new Error('Consent session not found');
      error.statusCode = 404;
      throw error;
    }

    const now = new Date();

    if (session.status !== 'active') {
      const error: any = new Error(`Session is no longer active (current status: ${session.status})`);
      error.statusCode = 400;
      throw error;
    }

    if (now > session.sessionExpiresAt) {
      await prisma.consentSession.update({
        where: { id: sessionId },
        data: { status: 'expired' },
      });
      const error: any = new Error('Consent session has expired');
      error.statusCode = 400;
      throw error;
    }

    if (now > session.codeExpiresAt) {
      const error: any = new Error('Short code has expired (QR and NFC remain active)');
      error.statusCode = 400;
      throw error;
    }

    const cleanInput = inputCode.replace(/[^A-Za-z0-9]/g, '').toUpperCase();
    const cleanTarget = session.shortCode.replace(/[^A-Za-z0-9]/g, '').toUpperCase();

    if (cleanInput !== cleanTarget) {
      const attempts = session.codeFailedAttempts + 1;
      if (attempts >= 5) {
        await prisma.consentSession.update({
          where: { id: sessionId },
          data: {
            codeFailedAttempts: attempts,
            status: 'expired',
          },
        });
        const error: any = new Error('Maximum failed attempts reached. Session has been locked out.');
        error.statusCode = 403;
        throw error;
      }

      await prisma.consentSession.update({
        where: { id: sessionId },
        data: { codeFailedAttempts: attempts },
      });

      const remainingAttempts = 5 - attempts;
      const error: any = new Error(`Invalid short code. ${remainingAttempts} attempts remaining.`);
      error.statusCode = 400;
      throw error;
    }

    // Match success! Mark session as used
    const updated = await prisma.consentSession.update({
      where: { id: sessionId },
      data: {
        status: 'used',
        usedMethod: 'code',
        usedAt: now,
      },
      include: { patient: true },
    });

    return {
      success: true,
      message: 'Short code verified successfully. Medical consent granted.',
      sessionId: updated.id,
      patientId: updated.patientId,
      patient: {
        id: updated.patient.id,
        name: updated.patient.name,
        abhaId: updated.patient.abhaId,
        isAbhaLinked: updated.patient.isAbhaLinked,
        gender: updated.patient.gender,
        bloodGroup: updated.patient.bloodGroup,
      },
      usedMethod: 'code',
      usedAt: updated.usedAt?.toISOString(),
    };
  }

  static async verifyCodeOnly(inputCode: string) {
    if (!inputCode) {
      const error: any = new Error('Short code is required');
      error.statusCode = 400;
      throw error;
    }

    const cleanInput = inputCode.replace(/[^A-Za-z0-9]/g, '').toUpperCase();
    const session = await prisma.consentSession.findFirst({
      where: { shortCode: cleanInput },
      include: { patient: true },
    });

    if (!session) {
      const error: any = new Error('Invalid short code. Consent session not found.');
      error.statusCode = 404;
      throw error;
    }

    const now = new Date();

    if (session.status !== 'active') {
      const error: any = new Error(`Session is already ${session.status}`);
      error.statusCode = 400;
      throw error;
    }

    if (now > session.sessionExpiresAt) {
      await prisma.consentSession.update({
        where: { id: session.id },
        data: { status: 'expired' },
      });
      const error: any = new Error('Consent session has expired');
      error.statusCode = 400;
      throw error;
    }

    if (now > session.codeExpiresAt) {
      const error: any = new Error('Short code has expired (QR and NFC remain active)');
      error.statusCode = 400;
      throw error;
    }

    if (session.codeFailedAttempts >= 5) {
      const error: any = new Error('Maximum failed attempts reached. Session has been locked out.');
      error.statusCode = 403;
      throw error;
    }

    // Mark as used
    const updated = await prisma.consentSession.update({
      where: { id: session.id },
      data: {
        status: 'used',
        usedMethod: 'code',
        usedAt: now,
      },
      include: { patient: true },
    });

    return {
      success: true,
      message: 'Medical consent short code verified successfully.',
      sessionId: updated.id,
      patientId: updated.patientId,
      patient: {
        id: updated.patient.id,
        name: updated.patient.name,
        abhaId: updated.patient.abhaId,
        isAbhaLinked: updated.patient.isAbhaLinked,
        gender: updated.patient.gender,
        bloodGroup: updated.patient.bloodGroup,
      },
      usedMethod: 'code',
      usedAt: updated.usedAt?.toISOString(),
    };
  }

  static async verifyQrOrToken(tokenOrId: string) {
    if (!tokenOrId) {
      const error: any = new Error('QR Token or Session ID is required');
      error.statusCode = 400;
      throw error;
    }

    const session = await prisma.consentSession.findFirst({
      where: {
        OR: [
          { qrToken: tokenOrId },
          { id: tokenOrId },
        ],
      },
      include: { patient: true },
    });

    if (!session) {
      const error: any = new Error('Invalid QR code. Consent session not found.');
      error.statusCode = 404;
      throw error;
    }

    const now = new Date();

    if (session.status !== 'active') {
      const error: any = new Error(`QR session is already ${session.status}`);
      error.statusCode = 400;
      throw error;
    }

    if (now > session.sessionExpiresAt) {
      await prisma.consentSession.update({
        where: { id: session.id },
        data: { status: 'expired' },
      });
      const error: any = new Error('QR session has expired');
      error.statusCode = 400;
      throw error;
    }

    const updated = await prisma.consentSession.update({
      where: { id: session.id },
      data: {
        status: 'used',
        usedMethod: 'qr',
        usedAt: now,
      },
      include: { patient: true },
    });

    return {
      success: true,
      message: 'QR code verified successfully. Medical consent granted.',
      sessionId: updated.id,
      patientId: updated.patientId,
      patient: {
        id: updated.patient.id,
        name: updated.patient.name,
        abhaId: updated.patient.abhaId,
        isAbhaLinked: updated.patient.isAbhaLinked,
        gender: updated.patient.gender,
        bloodGroup: updated.patient.bloodGroup,
      },
      usedMethod: 'qr',
      usedAt: updated.usedAt?.toISOString(),
    };
  }

  static async markUsed(sessionId: string, method: 'nfc' | 'qr' | 'code' | 'revoked') {
    const session = await prisma.consentSession.findUnique({
      where: { id: sessionId },
    });

    if (!session) {
      const error: any = new Error('Consent session not found');
      error.statusCode = 404;
      throw error;
    }

    const now = new Date();

    if (session.status !== 'active') {
      const error: any = new Error(`Session is already ${session.status}`);
      error.statusCode = 400;
      throw error;
    }

    if (now > session.sessionExpiresAt) {
      await prisma.consentSession.update({
        where: { id: sessionId },
        data: { status: 'expired' },
      });
      const error: any = new Error('Consent session has expired');
      error.statusCode = 400;
      throw error;
    }

    const newStatus = method === 'revoked' ? 'revoked' : 'used';
    const updated = await prisma.consentSession.update({
      where: { id: sessionId },
      data: {
        status: newStatus,
        usedMethod: method,
        usedAt: now,
      },
    });

    return {
      success: true,
      sessionId: updated.id,
      status: updated.status,
      usedMethod: updated.usedMethod,
      usedAt: updated.usedAt?.toISOString(),
    };
  }

  static async revokeSession(sessionId: string) {
    const session = await prisma.consentSession.findUnique({
      where: { id: sessionId },
    });

    if (!session) {
      const error: any = new Error('Consent session not found');
      error.statusCode = 404;
      throw error;
    }

    const updated = await prisma.consentSession.update({
      where: { id: sessionId },
      data: {
        status: 'revoked',
        usedMethod: 'revoked',
        usedAt: new Date(),
      },
    });

    return {
      success: true,
      message: 'Session revoked successfully',
      sessionId: updated.id,
      status: updated.status,
    };
  }

  static async getSessionStatus(sessionId: string) {
    const session = await prisma.consentSession.findUnique({
      where: { id: sessionId },
    });

    if (!session) {
      const error: any = new Error('Consent session not found');
      error.statusCode = 404;
      throw error;
    }

    const now = new Date();
    let currentStatus = session.status;

    if (currentStatus === 'active' && now > session.sessionExpiresAt) {
      currentStatus = 'expired';
      await prisma.consentSession.update({
        where: { id: sessionId },
        data: { status: 'expired' },
      });
    }

    return {
      sessionId: session.id,
      status: currentStatus,
      usedMethod: session.usedMethod,
      usedAt: session.usedAt?.toISOString() || null,
      sessionExpiresAt: session.sessionExpiresAt.toISOString(),
      codeExpiresAt: session.codeExpiresAt.toISOString(),
      isCodeExpired: now > session.codeExpiresAt,
      codeFailedAttempts: session.codeFailedAttempts,
    };
  }
}
