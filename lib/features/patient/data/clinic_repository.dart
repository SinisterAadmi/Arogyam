import '../../../shared/entities/clinic.dart';
import 'clinic_datasource.dart';

abstract class ClinicRepository {
  Future<List<Clinic>> getNearbyClinics();
}

class ClinicRepositoryImpl implements ClinicRepository {
  final ClinicDatasource _datasource;

  ClinicRepositoryImpl({ClinicDatasource? datasource})
      : _datasource = datasource ?? MockClinicDatasource();

  @override
  Future<List<Clinic>> getNearbyClinics() {
    return _datasource.getNearbyClinics();
  }
}
