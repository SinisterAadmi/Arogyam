abstract class AiCallbackRepository {
  Future<Map<String, dynamic>> requestCallback(String clinicId, String phone, String scheduledAt);
  Future<Map<String, dynamic>> triggerVapiCallback({
    required String clinicId,
    String? doctorId,
    String? scheduledAt,
    String? phone,
  });
  Future<Map<String, dynamic>> getCallbackStatus();
  Future<void> cancelCallback();
}
