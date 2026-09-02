import '../../../../shared/entities/clinic.dart';
import '../repositories/clinic_repository.dart';

class GetNearbyClinicsUseCase {
  final ClinicRepository _repository;

  GetNearbyClinicsUseCase(this._repository);

  Future<List<Clinic>> call({double? lat, double? lng}) {
    return _repository.getNearbyClinics(lat: lat, lng: lng);
  }
}
