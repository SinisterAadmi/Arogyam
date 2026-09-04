import { Router } from 'express';
import { PatientController } from '../controllers/patientController';
import { protect } from '../middleware/authMiddleware';

const router = Router();

router.get('/me', protect(['patient']), PatientController.getMe);
router.patch('/me', protect(['patient']), PatientController.updateMe);
router.post('/me/avatar', protect(['patient']), PatientController.uploadAvatar);
router.get('/me/privacy-settings', protect(['patient']), PatientController.getPrivacySettings);
router.patch('/me/privacy-settings', protect(['patient']), PatientController.updatePrivacySettings);
router.get('/me/access-history', protect(['patient']), PatientController.getAccessHistory);
router.get('/clinics/nearby', protect(['patient']), PatientController.getNearbyClinics);
router.get('/clinics/:clinicId/doctors', protect(['patient']), PatientController.getClinicDoctors);
router.get('/appointments/upcoming', protect(['patient']), PatientController.getUpcomingAppointments);
router.post('/appointments', protect(['patient']), PatientController.createAppointment);
router.get('/appointments/:id', protect(['patient']), PatientController.getAppointmentById);
router.patch('/appointments/:id/cancel', protect(['patient']), PatientController.cancelAppointment);
router.get('/queue/status', protect(['patient']), PatientController.getQueueStatus);
router.post('/queue/join', protect(['patient']), PatientController.joinQueue);
router.post('/queue/auto-check-in', protect(['patient']), PatientController.autoCheckIn);
router.get('/prescriptions/active', protect(['patient']), PatientController.getActivePrescriptions);
router.get('/medical-history', protect(['patient']), PatientController.getMedicalHistory);
router.get('/abha/status', protect(['patient']), PatientController.getAbhaStatus);
router.post('/abha/link', protect(['patient']), PatientController.linkAbha);
router.post('/nfc/session', protect(['patient']), PatientController.createNfcSession);
router.post('/nfc/session/:sessionId/revoke', protect(['patient']), PatientController.revokeNfcSession);
router.get('/ai/callback/status', protect(['patient']), PatientController.getAiCallbackStatus);
router.post('/ai/callback/cancel', protect(['patient']), PatientController.cancelAiCallback);
router.post('/ai/callback', protect(['patient']), PatientController.requestAiCallback);
router.post('/ai/vapi-callback', protect(['patient']), PatientController.triggerVapiCallback);

export default router;
