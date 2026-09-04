import '../repositories/medical_history_repository.dart';
import '../../presentation/providers/medical_history_provider.dart';

class GetMedicalHistory {
  final MedicalHistoryRepository _repository;

  GetMedicalHistory(this._repository);

  Future<List<MedicalRecord>> call() {
    return _repository.getMedicalHistory();
  }
}
