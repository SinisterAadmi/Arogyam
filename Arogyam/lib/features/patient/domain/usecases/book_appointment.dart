import '../repositories/appointment_repository.dart';
import '../../data/models/appointment_model.dart';

class BookAppointment {
  final AppointmentRepository _repository;

  BookAppointment(this._repository);

  Future<AppointmentModel> call(String clinicId, String doctorId, DateTime scheduledAt) {
    return _repository.bookAppointment(clinicId, doctorId, scheduledAt);
  }
}
