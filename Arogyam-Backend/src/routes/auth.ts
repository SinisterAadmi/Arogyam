import { Router, Request, Response } from 'express';
import { protect, AuthRequest } from '../middleware/authMiddleware';
import * as authController from '../controllers/authController';

const router = Router();

router.post('/login', authController.login);
router.post('/signup', authController.signup);

router.post('/logout', protect(), async (req: AuthRequest, res: Response) => {
  // Any server side session cleanup could go here
  res.json({ message: 'Logout successful' });
});

export default router;
