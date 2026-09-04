import '../../../../shared/entities/clinic.dart';

abstract class ClinicRepository {
  Future<List<Clinic>> getNearbyClinics({double? lat, double? lng});
}
