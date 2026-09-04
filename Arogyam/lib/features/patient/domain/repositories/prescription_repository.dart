import '../../../../shared/entities/prescription.dart';

abstract class PrescriptionRepository {
  Future<List<Prescription>> getActivePrescriptions();
}
