import '../../data/models/appointment_model.dart';

abstract class AppointmentRepository {
  Future<List<AppointmentModel>> getUpcomingAppointments();
  Future<AppointmentModel> bookAppointment(String clinicId, String doctorId, DateTime scheduledAt);
}
