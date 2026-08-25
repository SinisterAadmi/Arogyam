import '../../../shared/entities/prescription.dart';
import '../../../shared/enums/prescription_status.dart';

abstract class PrescriptionDatasource {
  Future<List<Prescription>> getActivePrescriptions();
}

class MockPrescriptionDatasource implements PrescriptionDatasource {
  @override
  Future<List<Prescription>> getActivePrescriptions() async {
    // Simulate brief network delay
    await Future.delayed(const Duration(milliseconds: 300));

    return [
      Prescription(
        id: '1',
        medicineName: 'Telmisartan 40mg',
        dosageInstructions: '1 Tablet Daily (Morning)',
        prescribedBy: 'Dr. Ananya Sharma',
        clinicName: 'Apollo Health City',
        expiryDate: DateTime(2026, 2, 12),
        status: PrescriptionStatus.active,
      ),
      Prescription(
        id: '2',
        medicineName: 'Atorvastatin 10mg',
        dosageInstructions: '1 Tablet Nightly (Post-Dinner)',
        prescribedBy: 'Dr. Ananya Sharma',
        clinicName: 'Apollo Health City',
        expiryDate: DateTime(2026, 2, 12),
        status: PrescriptionStatus.expiringSoon,
      ),
      Prescription(
        id: '3',
        medicineName: 'Amoxicillin 500mg',
        dosageInstructions: '1 Cap 3 times daily (After food)',
        prescribedBy: 'Dr. Vijay Iyer',
        clinicName: 'Care Clinic',
        expiryDate: DateTime(2026, 2, 12),
        status: PrescriptionStatus.active,
      ),
    ];
  }
}
