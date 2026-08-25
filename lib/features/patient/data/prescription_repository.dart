import '../../../shared/entities/prescription.dart';
import 'prescription_datasource.dart';

abstract class PrescriptionRepository {
  Future<List<Prescription>> getActivePrescriptions();
}

class PrescriptionRepositoryImpl implements PrescriptionRepository {
  final PrescriptionDatasource _datasource;

  PrescriptionRepositoryImpl({PrescriptionDatasource? datasource})
      : _datasource = datasource ?? MockPrescriptionDatasource();

  @override
  Future<List<Prescription>> getActivePrescriptions() {
    return _datasource.getActivePrescriptions();
  }
}
