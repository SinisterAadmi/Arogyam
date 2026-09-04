import '../../data/models/patient_model.dart';
import '../repositories/patient_repository.dart';

class UpdatePatientProfile {
  final PatientRepository repository;

  UpdatePatientProfile(this.repository);

  Future<void> execute(PatientModel updatedPatient) async {
    // repository.updatePatientProfile(...)
  }
}
