import '../../../patient/data/models/queue_status_model.dart';

abstract class QueueRepository {
  Future<QueueStatusModel> getQueueStatus();
  Future<QueueStatusModel> joinQueue(String clinicId);
  Future<QueueStatusModel> autoCheckIn(String clinicId);
}
