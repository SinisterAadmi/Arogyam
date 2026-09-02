import '../repositories/ai_callback_repository.dart';

class RequestCallback {
  final AiCallbackRepository _repository;

  RequestCallback(this._repository);

  Future<Map<String, dynamic>> call(String clinicId, String phone, String scheduledAt) {
    return _repository.requestCallback(clinicId, phone, scheduledAt);
  }
}
