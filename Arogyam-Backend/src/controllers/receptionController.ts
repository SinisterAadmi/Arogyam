import { Response } from 'express';
import { AuthRequest } from '../middleware/authMiddleware';
import { ReceptionService } from '../services/receptionService';

export class ReceptionController {
  static async getQueue(req: AuthRequest, res: Response) {
    try {
      const queueData = await ReceptionService.getLiveQueue(req.user!.dbUserId);
      res.json(queueData);
    } catch (error: any) {
      console.error('Reception getQueue Error:', error);
      const statusCode = error.statusCode || 500;
      res.status(statusCode).json({ message: error.message || 'Failed to fetch queue' });
    }
  }

  static async getUpcomingAppointments(req: AuthRequest, res: Response) {
    try {
      const appointments = await ReceptionService.getUpcomingAppointments(req.user!.dbUserId);
      res.json(appointments);
    } catch (error: any) {
      console.error('Reception getUpcomingAppointments Error:', error);
      const statusCode = error.statusCode || 500;
      res.status(statusCode).json({ message: error.message || 'Failed to fetch upcoming appointments' });
    }
  }

  static async updateTokenStatus(req: AuthRequest, res: Response) {
    try {
      const { tokenId } = req.params;
      const { status } = req.body;
      if (!status) {
        return res.status(400).json({ message: 'status field is required' });
      }
      const updated = await ReceptionService.updateTokenStatus(req.user!.dbUserId, tokenId, status);
      res.json(updated);
    } catch (error: any) {
      console.error('Reception updateTokenStatus Error:', error);
      const statusCode = error.statusCode || 500;
      res.status(statusCode).json({ message: error.message || 'Failed to update token status' });
    }
  }

  static async getAiCallbacks(req: AuthRequest, res: Response) {
    try {
      const callbacks = await ReceptionService.getAiCallbacks(req.user!.dbUserId);
      res.json(callbacks);
    } catch (error: any) {
      console.error('Reception getAiCallbacks Error:', error);
      const statusCode = error.statusCode || 500;
      res.status(statusCode).json({ message: error.message || 'Failed to fetch AI callbacks' });
    }
  }

  static async resolveAiCallback(req: AuthRequest, res: Response) {
    try {
      const { id } = req.params;
      const result = await ReceptionService.resolveAiCallback(req.user!.dbUserId, id);
      res.json(result);
    } catch (error: any) {
      console.error('Reception resolveAiCallback Error:', error);
      const statusCode = error.statusCode || 500;
      res.status(statusCode).json({ message: error.message || 'Failed to resolve callback' });
    }
  }

  static async getAnalytics(req: AuthRequest, res: Response) {
    try {
      const analytics = await ReceptionService.getAnalytics(req.user!.dbUserId);
      res.json(analytics);
    } catch (error: any) {
      console.error('Reception getAnalytics Error:', error);
      const statusCode = error.statusCode || 500;
      res.status(statusCode).json({ message: error.message || 'Failed to fetch analytics' });
    }
  }

  static async getClinic(req: AuthRequest, res: Response) {
    try {
      const clinic = await ReceptionService.getClinic(req.user!.dbUserId);
      res.json(clinic);
    } catch (error: any) {
      console.error('Reception getClinic Error:', error);
      const statusCode = error.statusCode || 500;
      res.status(statusCode).json({ message: error.message || 'Failed to fetch clinic details' });
    }
  }

  static async updateClinic(req: AuthRequest, res: Response) {
    try {
      const { name, address, phone, specialty, operatingHours, description, latitude, longitude, isOpen } = req.body;
      const updated = await ReceptionService.updateClinic(req.user!.dbUserId, {
        name,
        address,
        phone,
        specialty,
        operatingHours,
        description,
        latitude: typeof latitude === 'number' ? latitude : (latitude ? parseFloat(latitude) : undefined),
        longitude: typeof longitude === 'number' ? longitude : (longitude ? parseFloat(longitude) : undefined),
        isOpen: typeof isOpen === 'boolean' ? isOpen : undefined,
      });
      res.json(updated);
    } catch (error: any) {
      console.error('Reception updateClinic Error:', error);
      const statusCode = error.statusCode || 500;
      res.status(statusCode).json({ message: error.message || 'Failed to update clinic' });
    }
  }
}
