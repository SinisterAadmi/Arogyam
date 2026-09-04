import { Router } from 'express';
const router = Router();
router.get('/ping', (req, res) => res.json({ message: 'Admin route stub' }));
export default router;
