import '../../presentation/providers/medical_history_provider.dart';

abstract class MedicalHistoryRepository {
  Future<List<MedicalRecord>> getMedicalHistory();
  Future<void> shareMedicalHistory(String doctorId);
}
