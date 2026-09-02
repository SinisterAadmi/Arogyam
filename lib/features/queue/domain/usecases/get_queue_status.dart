import '../repositories/queue_repository.dart';
import '../../../patient/data/models/queue_status_model.dart';

class GetQueueStatus {
  final QueueRepository _repository;

  GetQueueStatus(this._repository);

  Future<QueueStatusModel> call() {
    return _repository.getQueueStatus();
  }
}
