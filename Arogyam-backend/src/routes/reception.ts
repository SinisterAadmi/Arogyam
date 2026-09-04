import { Router } from 'express';
import { Role } from '@prisma/client';
import { protect } from '../middleware/authMiddleware';
import { ReceptionController } from '../controllers/receptionController';

const router = Router();

router.get('/queue', protect([Role.reception]), ReceptionController.getQueue);
router.get('/queue/upcoming', protect([Role.reception]), ReceptionController.getUpcomingAppointments);
router.patch('/queue/:tokenId/status', protect([Role.reception]), ReceptionController.updateTokenStatus);
router.get('/ai-callbacks', protect([Role.reception]), ReceptionController.getAiCallbacks);
router.patch('/ai-callbacks/:id/resolve', protect([Role.reception]), ReceptionController.resolveAiCallback);
router.get('/analytics', protect([Role.reception]), ReceptionController.getAnalytics);
router.get('/clinic', protect([Role.reception]), ReceptionController.getClinic);
router.patch('/clinic', protect([Role.reception]), ReceptionController.updateClinic);

export default router;
