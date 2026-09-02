import '../../data/models/patient_model.dart';
import '../entities/patient.dart';

abstract class PatientRepository {
  Future<void> linkAbhaId(String abhaId, String otp);
  Future<Patient?> getPatientMe();
  Future<void> updatePatientProfile(PatientModel patient);
  Future<List<Map<String, dynamic>>> getAccessHistory();
}
