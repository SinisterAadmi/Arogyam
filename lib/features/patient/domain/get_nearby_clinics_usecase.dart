import '../../../shared/entities/clinic.dart';
import '../data/clinic_repository.dart';

class GetNearbyClinicsUseCase {
  final ClinicRepository _repository;

  GetNearbyClinicsUseCase({ClinicRepository? repository})
      : _repository = repository ?? ClinicRepositoryImpl();

  Future<List<Clinic>> call() {
    return _repository.getNearbyClinics();
  }
}
