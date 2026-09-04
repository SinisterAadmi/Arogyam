import { Router } from 'express';
const router = Router();
router.get('/ping', (req, res) => res.json({ message: 'Doctor route stub' }));
export default router;
