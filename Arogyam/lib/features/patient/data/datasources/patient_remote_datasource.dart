import '../../../../core/network/api_client.dart';
import '../models/patient_model.dart';

abstract class PatientRemoteDatasource {
  Future<PatientModel> getMe();
  Future<PatientModel> updateMe(Map<String, dynamic> data);
  Future<void> uploadAvatar(String filePath);
  Future<List<Map<String, dynamic>>> getAccessHistory();
  Future<Map<String, dynamic>> getPrivacySettings();
  Future<Map<String, dynamic>> updatePrivacySettings(Map<String, dynamic> data);
}

class PatientRemoteDatasourceImpl implements PatientRemoteDatasource {
  final ApiClient _client;

  PatientRemoteDatasourceImpl(this._client);

  @override
  Future<PatientModel> getMe() async {
    final response = await _client.get('/patients/me');
    return PatientModel.fromJson(response.data);
  }

  @override
  Future<PatientModel> updateMe(Map<String, dynamic> data) async {
    final response = await _client.patch('/patients/me', data: data);
    return PatientModel.fromJson(response.data);
  }

  @override
  Future<void> uploadAvatar(String filePath) async {
    // Logic for multipart upload would go here
    // For now, stub as per backend
    await _client.post('/patients/me/avatar', data: {'filePath': filePath});
  }

  @override
  Future<List<Map<String, dynamic>>> getAccessHistory() async {
    final response = await _client.get('/patients/me/access-history');
    if (response.data is List) {
      return (response.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  @override
  Future<Map<String, dynamic>> getPrivacySettings() async {
    final response = await _client.get('/patients/me/privacy-settings');
    return Map<String, dynamic>.from(response.data as Map);
  }

  @override
  Future<Map<String, dynamic>> updatePrivacySettings(Map<String, dynamic> data) async {
    final response = await _client.patch('/patients/me/privacy-settings', data: data);
    return Map<String, dynamic>.from(response.data as Map);
  }
}
