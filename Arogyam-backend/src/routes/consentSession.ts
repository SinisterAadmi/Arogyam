import { Router } from 'express';
import { ConsentSessionController } from '../controllers/consentSessionController';

const router = Router();

router.post('/verify-code', ConsentSessionController.verifyCodeOnly);
router.post('/verify-qr', ConsentSessionController.verifyQr);
router.post('/:sessionId/verify-code', ConsentSessionController.verifyCode);
router.post('/:sessionId/mark-used', ConsentSessionController.markUsed);
router.post('/:sessionId/revoke', ConsentSessionController.revoke);
router.get('/:sessionId/status', ConsentSessionController.getStatus);

export default router;
