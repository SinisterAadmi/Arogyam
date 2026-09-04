import '../../data/models/appointment_model.dart';
import '../repositories/appointment_repository.dart';

class GetUpcomingAppointmentsUseCase {
  final AppointmentRepository _repository;

  GetUpcomingAppointmentsUseCase(this._repository);

  Future<List<AppointmentModel>> call() {
    return _repository.getUpcomingAppointments();
  }
}
