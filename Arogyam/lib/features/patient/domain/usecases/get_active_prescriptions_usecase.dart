import '../../../../shared/entities/prescription.dart';
import '../repositories/prescription_repository.dart';

class GetActivePrescriptionsUseCase {
  final PrescriptionRepository _repository;

  GetActivePrescriptionsUseCase(this._repository);

  Future<List<Prescription>> call() {
    return _repository.getActivePrescriptions();
  }
}
