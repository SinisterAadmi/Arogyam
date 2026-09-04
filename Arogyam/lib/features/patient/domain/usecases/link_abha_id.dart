import '../repositories/patient_repository.dart';

class LinkAbhaId {
  final PatientRepository repository;

  LinkAbhaId(this.repository);

  Future<void> execute(String abhaId, String otp) async {
    // Implementation will go here
  }
}
