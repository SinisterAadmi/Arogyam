import '../repositories/appointment_repository.dart';
import '../../data/models/appointment_model.dart';

class CancelAppointmentUseCase {
  final AppointmentRepository _repository;

  CancelAppointmentUseCase(this._repository);

  Future<AppointmentModel> call(String id) {
    return _repository.cancelAppointment(id);
  }
}
