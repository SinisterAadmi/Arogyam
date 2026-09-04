import '../repositories/queue_repository.dart';
import '../../../patient/data/models/queue_status_model.dart';

class AutoCheckInPatient {
  final QueueRepository _repository;

  AutoCheckInPatient(this._repository);

  Future<QueueStatusModel> call(String clinicId) {
    return _repository.autoCheckIn(clinicId);
  }
}
