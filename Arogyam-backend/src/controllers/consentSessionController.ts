import { Request, Response } from 'express';
import { ConsentSessionService } from '../services/consentSessionService';
import { AuthRequest } from '../middleware/authMiddleware';

export class ConsentSessionController {
  static async createSession(req: AuthRequest, res: Response) {
    try {
      const patientId = req.user?.dbUserId;
      if (!patientId) {
        return res.status(401).json({ message: 'Unauthorized' });
      }
      const session = await ConsentSessionService.createSession(patientId);
      return res.status(201).json(session);
    } catch (error: any) {
      const statusCode = error.statusCode || 500;
      return res.status(statusCode).json({ message: error.message || 'Internal server error' });
    }
  }

  static async verifyCode(req: Request, res: Response) {
    try {
      const { sessionId } = req.params;
      const { code } = req.body;
      if (!code) {
        return res.status(400).json({ message: 'Short code is required' });
      }
      const result = await ConsentSessionService.verifyCode(sessionId, code);
      return res.json(result);
    } catch (error: any) {
      const statusCode = error.statusCode || 500;
      return res.status(statusCode).json({ message: error.message || 'Internal server error' });
    }
  }

  static async verifyCodeOnly(req: Request, res: Response) {
    try {
      const { code } = req.body;
      if (!code) {
        return res.status(400).json({ message: 'Short code is required' });
      }
      const result = await ConsentSessionService.verifyCodeOnly(code);
      return res.json(result);
    } catch (error: any) {
      const statusCode = error.statusCode || 500;
      return res.status(statusCode).json({ message: error.message || 'Internal server error' });
    }
  }

  static async verifyQr(req: Request, res: Response) {
    try {
      const { qrToken, sessionId } = req.body;
      const target = qrToken || sessionId;
      if (!target) {
        return res.status(400).json({ message: 'qrToken or sessionId is required' });
      }
      const result = await ConsentSessionService.verifyQrOrToken(target);
      return res.json(result);
    } catch (error: any) {
      const statusCode = error.statusCode || 500;
      return res.status(statusCode).json({ message: error.message || 'Internal server error' });
    }
  }

  static async markUsed(req: Request, res: Response) {
    try {
      const { sessionId } = req.params;
      const { method } = req.body;

      if (!method || !['nfc', 'qr', 'code', 'revoked'].includes(method)) {
        return res.status(400).json({ message: 'Invalid or missing usedMethod (must be nfc, qr, code, or revoked)' });
      }

      const result = await ConsentSessionService.markUsed(sessionId, method);
      return res.json(result);
    } catch (error: any) {
      const statusCode = error.statusCode || 500;
      return res.status(statusCode).json({ message: error.message || 'Internal server error' });
    }
  }

  static async revoke(req: Request, res: Response) {
    try {
      const { sessionId } = req.params;
      const result = await ConsentSessionService.revokeSession(sessionId);
      return res.json(result);
    } catch (error: any) {
      const statusCode = error.statusCode || 500;
      return res.status(statusCode).json({ message: error.message || 'Internal server error' });
    }
  }

  static async getStatus(req: Request, res: Response) {
    try {
      const { sessionId } = req.params;
      const result = await ConsentSessionService.getSessionStatus(sessionId);
      return res.json(result);
    } catch (error: any) {
      const statusCode = error.statusCode || 500;
      return res.status(statusCode).json({ message: error.message || 'Internal server error' });
    }
  }
}
