import '../repositories/appointment_repository.dart';
import '../../data/models/appointment_model.dart';

class GetAppointmentByIdUseCase {
  final AppointmentRepository _repository;

  GetAppointmentByIdUseCase(this._repository);

  Future<AppointmentModel> call(String id) {
    return _repository.getAppointmentById(id);
  }
}
