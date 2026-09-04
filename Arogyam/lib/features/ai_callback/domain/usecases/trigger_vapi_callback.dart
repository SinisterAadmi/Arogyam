import '../repositories/ai_callback_repository.dart';

class TriggerVapiCallback {
  final AiCallbackRepository _repository;

  TriggerVapiCallback(this._repository);

  Future<Map<String, dynamic>> call({
    required String clinicId,
    String? doctorId,
    String? scheduledAt,
    String? phone,
  }) async {
    return _repository.triggerVapiCallback(
      clinicId: clinicId,
      doctorId: doctorId,
      scheduledAt: scheduledAt,
      phone: phone,
    );
  }
}
