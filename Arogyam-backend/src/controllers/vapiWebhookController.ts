import { Request, Response } from 'express';
import { VapiService } from '../services/vapiService';

export class VapiWebhookController {
  /**
   * Handles incoming Vapi webhook requests (e.g. end-of-call-report, status-update)
   */
  static async handleWebhook(req: Request, res: Response) {
    try {
      // 1. Verify Vapi webhook secret/signature
      const isAuthentic = VapiService.verifyWebhookSignature(req.headers);
      if (!isAuthentic) {
        console.warn('[VapiWebhookController] Rejected unauthorized webhook payload');
        return res.status(401).json({ message: 'Unauthorized webhook signature' });
      }

      // 2. Process event and update appointment record
      const result = await VapiService.processWebhookEvent(req.body);

      return res.status(200).json({
        received: true,
        outcome: result.outcome,
        appointmentId: result.appointmentId,
      });
    } catch (error: any) {
      console.error('[VapiWebhookController] Error processing webhook:', error);
      return res.status(500).json({ message: error.message || 'Webhook processing failed' });
    }
  }
}
