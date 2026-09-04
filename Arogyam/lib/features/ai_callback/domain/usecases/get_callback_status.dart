import '../repositories/ai_callback_repository.dart';

class GetCallbackStatus {
  final AiCallbackRepository _repository;

  GetCallbackStatus(this._repository);

  Future<Map<String, dynamic>> call() {
    return _repository.getCallbackStatus();
  }
}
