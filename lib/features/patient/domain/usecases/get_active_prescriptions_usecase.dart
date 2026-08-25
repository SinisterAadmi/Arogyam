import '../../../../shared/entities/prescription.dart';
import '../../data/prescription_repository.dart';

class GetActivePrescriptionsUseCase {
  final PrescriptionRepository _repository;

  GetActivePrescriptionsUseCase({PrescriptionRepository? repository})
      : _repository = repository ?? PrescriptionRepositoryImpl();

  Future<List<Prescription>> call() {
    return _repository.getActivePrescriptions();
  }
}
