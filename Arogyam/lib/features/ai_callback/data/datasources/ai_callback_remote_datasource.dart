import '../../../../core/network/api_client.dart';

abstract class AiCallbackRemoteDatasource {
  Future<Map<String, dynamic>> requestCallback(String clinicId, String phone, String scheduledAt);
  Future<Map<String, dynamic>> triggerVapiCallback({
    required String clinicId,
    String? doctorId,
    String? scheduledAt,
    String? phone,
  });
  Future<Map<String, dynamic>> getCallbackStatus();
  Future<void> cancelCallback();
}

class AiCallbackRemoteDatasourceImpl implements AiCallbackRemoteDatasource {
  final ApiClient _client;

  AiCallbackRemoteDatasourceImpl(this._client);

  @override
  Future<Map<String, dynamic>> requestCallback(String clinicId, String phone, String scheduledAt) async {
    final response = await _client.post('/patients/ai/callback', data: {
      'clinicId': clinicId,
      'phone': phone,
      'scheduledAt': scheduledAt,
    });
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> triggerVapiCallback({
    required String clinicId,
    String? doctorId,
    String? scheduledAt,
    String? phone,
  }) async {
    final payload = <String, dynamic>{'clinicId': clinicId};
    if (doctorId != null) payload['doctorId'] = doctorId;
    if (scheduledAt != null) payload['scheduledAt'] = scheduledAt;
    if (phone != null) payload['phone'] = phone;

    final response = await _client.post('/patients/ai/vapi-callback', data: payload);
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> getCallbackStatus() async {
    final response = await _client.get('/patients/ai/callback/status');
    return response.data;
  }

  @override
  Future<void> cancelCallback() async {
    await _client.post('/patients/ai/callback/cancel');
  }
}
