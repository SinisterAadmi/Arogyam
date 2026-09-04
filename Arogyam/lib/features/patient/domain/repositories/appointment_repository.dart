import '../../data/models/appointment_model.dart';

abstract class AppointmentRepository {
  Future<List<AppointmentModel>> getUpcomingAppointments();
  Future<AppointmentModel> getAppointmentById(String id);
  Future<AppointmentModel> cancelAppointment(String id);
  Future<AppointmentModel> bookAppointment(String clinicId, String doctorId, DateTime scheduledAt);
}
