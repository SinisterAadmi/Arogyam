import '../repositories/ai_callback_repository.dart';

class CancelCallback {
  final AiCallbackRepository _repository;

  CancelCallback(this._repository);

  Future<void> call() {
    return _repository.cancelCallback();
  }
}
