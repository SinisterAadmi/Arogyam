import { Router } from 'express';
const router = Router();
router.get('/ping', (req, res) => res.json({ message: 'Pharmacy route stub' }));
export default router;
