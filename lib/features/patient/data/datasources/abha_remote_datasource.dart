import '../../../../core/network/api_client.dart';
import '../models/abha_model.dart';

abstract class AbhaRemoteDatasource {
  Future<AbhaModel> getAbhaStatus();
  Future<void> linkAbha(String abhaId, String otp);
}

class AbhaRemoteDatasourceImpl implements AbhaRemoteDatasource {
  final ApiClient _client;

  AbhaRemoteDatasourceImpl(this._client);

  @override
  Future<AbhaModel> getAbhaStatus() async {
    final response = await _client.get('/patients/abha/status');
    return AbhaModel.fromJson(response.data);
  }

  @override
  Future<void> linkAbha(String abhaId, String otp) async {
    await _client.post('/patients/abha/link', data: {'abhaId': abhaId, 'otp': otp});
  }
}
