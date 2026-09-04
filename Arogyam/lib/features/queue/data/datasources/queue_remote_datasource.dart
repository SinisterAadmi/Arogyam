import '../../../../core/network/api_client.dart';
import '../../../patient/data/models/queue_status_model.dart';

abstract class QueueRemoteDatasource {
  Future<QueueStatusModel> getQueueStatus();
  Future<QueueStatusModel> joinQueue(String clinicId);
  Future<QueueStatusModel> autoCheckIn(String clinicId);
}

class QueueRemoteDatasourceImpl implements QueueRemoteDatasource {
  final ApiClient _client;

  QueueRemoteDatasourceImpl(this._client);

  @override
  Future<QueueStatusModel> getQueueStatus() async {
    final response = await _client.get('/patients/queue/status');
    return QueueStatusModel.fromJson(response.data);
  }

  @override
  Future<QueueStatusModel> joinQueue(String clinicId) async {
    final response = await _client.post('/patients/queue/join', data: {'clinicId': clinicId});
    return QueueStatusModel.fromJson(response.data);
  }

  @override
  Future<QueueStatusModel> autoCheckIn(String clinicId) async {
    final response = await _client.post('/patients/queue/auto-check-in', data: {'clinicId': clinicId});
    return QueueStatusModel.fromJson(response.data);
  }
}
