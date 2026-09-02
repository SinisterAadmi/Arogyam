# Patient Module Implementation Plan

Implement and improve the Patient module in the Arogyam project following Clean Architecture principles.

## User Review Required

> [!IMPORTANT]
> The implementation uses mock data and simulated API delays as the backend services are not yet fully available.

## Proposed Changes

### 1. Patient Home Dashboard
- [MODIFY] [patient_home_page.dart](file:///D:/Arogyam/lib/features/patient/presentation/pages/patient_home/patient_home_page.dart): Update to use `PatientHomeProvider` and integrate all required widgets.
- [MODIFY] [patient_home_provider.dart](file:///D:/Arogyam/lib/features/patient/presentation/providers/patient_home_provider.dart): Implement logic to fetch dashboard data.

### 2. ABHA Linking (Mock Verification Flow)
- [MODIFY] [abha_linking_page.dart](file:///D:/Arogyam/lib/features/patient/presentation/pages/abha_linking/abha_linking_page.dart): Add validation, OTP flow, and privacy notice.
- [MODIFY] [abha_provider.dart](file:///D:/Arogyam/lib/features/patient/presentation/providers/abha_provider.dart): Add state management for the verification flow.
- [MODIFY] [link_abha_id.dart](file:///D:/Arogyam/lib/features/patient/domain/usecases/link_abha_id.dart): Implement usecase logic.
- [MODIFY] [patient_repository_impl.dart](file:///D:/Arogyam/lib/features/patient/data/repositories/patient_repository_impl.dart): Implement ABHA linking repository logic.

### 3. Nearby Clinics (Map & List)
- [MODIFY] [nearby_clinics_page.dart](file:///D:/Arogyam/lib/features/patient/presentation/pages/nearby_clinics/nearby_clinics_page.dart): Implement map/list toggle and filters.
- [MODIFY] [nearby_clinics_provider.dart](file:///D:/Arogyam/lib/features/patient/presentation/providers/nearby_clinics_provider.dart): Add location permission handling and clinic fetching.

### 4. Appointment Booking
- [MODIFY] [appointment_booking_page.dart](file:///D:/Arogyam/lib/features/patient/presentation/pages/appointment_booking/appointment_booking_page.dart): Implement booking flow with slot selection and confirmation.
- [MODIFY] [appointment_provider.dart](file:///D:/Arogyam/lib/features/patient/presentation/providers/appointment_provider.dart): Manage booking state.

### 5. Queue Status & Secure Check-in
- [MODIFY] [queue_status_page.dart](file:///D:/Arogyam/lib/features/patient/presentation/pages/queue_status/queue_status_page.dart): Implement queue tracking and geofence-assisted check-in.
- [MODIFY] [queue_provider.dart](file:///D:/Arogyam/lib/features/patient/presentation/providers/queue_provider.dart): Implement polling and check-in logic.

### 6. Prescriptions & Medical History
- [MODIFY] [active_prescriptions_page.dart](file:///D:/Arogyam/lib/features/patient/presentation/pages/active_prescriptions/active_prescriptions_page.dart)
- [MODIFY] [medical_history_page.dart](file:///D:/Arogyam/lib/features/patient/presentation/pages/medical_history/medical_history_page.dart)
- [MODIFY] [prescriptions_provider.dart](file:///D:/Arogyam/lib/features/patient/presentation/providers/prescriptions_provider.dart)
- [MODIFY] [medical_history_provider.dart](file:///D:/Arogyam/lib/features/patient/presentation/providers/medical_history_provider.dart)

### 7. NFC Sharing
- [MODIFY] [nfc_share_page.dart](file:///D:/Arogyam/lib/features/patient/presentation/pages/nfc_share/nfc_share_page.dart): Implement consent-based sharing flow.

## Verification Plan

### Automated Tests
- Unit tests for:
  - ABHA format validation
  - Appointment booking validation
  - Queue check-in logic
  - NFC consent generation
- Location: `test/features/patient/`

### Manual Verification
- Walkthrough of each feature in the emulator/device.
- Verify state transitions (loading -> success/error).
- Check persistence of ABHA linking status.
