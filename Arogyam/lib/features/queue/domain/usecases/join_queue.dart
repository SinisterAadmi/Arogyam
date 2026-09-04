import '../repositories/queue_repository.dart';
import '../../../patient/data/models/queue_status_model.dart';

class JoinQueue {
  final QueueRepository _repository;

  JoinQueue(this._repository);

  Future<QueueStatusModel> call(String clinicId) {
    return _repository.joinQueue(clinicId);
  }
}
