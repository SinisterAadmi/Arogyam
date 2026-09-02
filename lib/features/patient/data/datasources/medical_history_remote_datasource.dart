import '../../../../core/network/api_client.dart';
import '../../presentation/providers/medical_history_provider.dart';

abstract class MedicalHistoryRemoteDatasource {
  Future<List<MedicalRecord>> getMedicalHistory();
}

class MedicalHistoryRemoteDatasourceImpl implements MedicalHistoryRemoteDatasource {
  final ApiClient _client;

  MedicalHistoryRemoteDatasourceImpl(this._client);

  @override
  Future<List<MedicalRecord>> getMedicalHistory() async {
    final response = await _client.get('/patients/medical-history');
    return (response.data as List).map((json) => MedicalRecord(
      id: json['id'],
      title: json['title'],
      category: json['category'],
      date: json['date'], // Backend returns string in realistic mock
      doctorName: json['doctorName'],
      facilityName: json['facilityName'],
    )).toList();
  }
}
