import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../domain/repositories/appointment_repository.dart';
import '../datasources/appointment_remote_datasource.dart';
import '../models/appointment_model.dart';

class AppointmentRepositoryImpl implements AppointmentRepository {
  final AppointmentRemoteDatasource _remoteDatasource;

  AppointmentRepositoryImpl(this._remoteDatasource);

  @override
  Future<List<AppointmentModel>> getUpcomingAppointments() async {
    try {
      return await _remoteDatasource.getUpcomingAppointments();
    } on DioException catch (e, stackTrace) {
      debugPrint('[Patient] error: $e\n$stackTrace');
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        rethrow;
      }
      return [
        AppointmentModel(
          id: '101',
          doctorName: 'Dr. Ananya Sharma (Mock)',
          specialty: 'Cardiologist',
          clinicName: 'Apollo Health City',
          appointmentTime: 'Tomorrow, 10:30 AM',
          tokenNumber: '15',
          status: 'Confirmed',
        ),
      ];
    } catch (e, stackTrace) {
      debugPrint('[Patient] error: $e\n$stackTrace');
      rethrow;
    }
  }

  @override
  Future<AppointmentModel> getAppointmentById(String id) async {
    return await _remoteDatasource.getAppointmentById(id);
  }

  @override
  Future<AppointmentModel> cancelAppointment(String id) async {
    return await _remoteDatasource.cancelAppointment(id);
  }

  @override
  Future<AppointmentModel> bookAppointment(String clinicId, String doctorId, DateTime scheduledAt) async {
    return await _remoteDatasource.createAppointment(clinicId, doctorId, scheduledAt.toIso8601String());
  }
}
