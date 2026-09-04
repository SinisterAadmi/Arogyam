import { Router } from 'express';
import { VapiWebhookController } from '../controllers/vapiWebhookController';

const router = Router();

// Public Vapi webhook endpoint
router.post('/vapi', VapiWebhookController.handleWebhook);

export default router;
