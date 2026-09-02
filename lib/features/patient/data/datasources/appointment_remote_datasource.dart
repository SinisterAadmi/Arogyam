import '../../../../core/network/api_client.dart';
import '../models/appointment_model.dart';

abstract class AppointmentRemoteDatasource {
  Future<List<AppointmentModel>> getUpcomingAppointments();
  Future<AppointmentModel> createAppointment(String clinicId, String doctorId, String scheduledAt);
}

class AppointmentRemoteDatasourceImpl implements AppointmentRemoteDatasource {
  final ApiClient _client;

  AppointmentRemoteDatasourceImpl(this._client);

  @override
  Future<List<AppointmentModel>> getUpcomingAppointments() async {
    final response = await _client.get('/patients/appointments/upcoming');
    return (response.data as List).map((json) => AppointmentModel.fromJson(json)).toList();
  }

  @override
  Future<AppointmentModel> createAppointment(String clinicId, String doctorId, String scheduledAt) async {
    final response = await _client.post('/patients/appointments', data: {
      'clinicId': clinicId,
      'doctorId': doctorId,
      'scheduledAt': scheduledAt,
    });
    return AppointmentModel.fromJson(response.data);
  }
}
