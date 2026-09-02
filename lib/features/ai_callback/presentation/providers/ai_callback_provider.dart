import 'package:flutter/foundation.dart';
import '../../domain/usecases/request_callback.dart';
import '../../domain/usecases/cancel_callback.dart';
import '../../domain/usecases/get_callback_status.dart';

class AiCallbackProvider extends ChangeNotifier {
  final RequestCallback _requestCallbackUseCase;
  final CancelCallback _cancelCallbackUseCase;
  final GetCallbackStatus _getCallbackStatusUseCase;

  bool _isLoading = false;
  bool _isRequested = false;
  String? _requestId;
  String? _status;
  DateTime? _requestedAt;
  String? _errorMessage;

  AiCallbackProvider({
    required RequestCallback requestCallbackUseCase,
    required CancelCallback cancelCallbackUseCase,
    required GetCallbackStatus getCallbackStatusUseCase,
  })  : _requestCallbackUseCase = requestCallbackUseCase, // ignore: prefer_initializing_formals
        _cancelCallbackUseCase = cancelCallbackUseCase, // ignore: prefer_initializing_formals
        _getCallbackStatusUseCase = getCallbackStatusUseCase; // ignore: prefer_initializing_formals

  bool get isLoading => _isLoading;
  bool get isRequested => _isRequested;
  String? get requestId => _requestId;
  String? get status => _status;
  DateTime? get requestedAt => _requestedAt;
  String? get errorMessage => _errorMessage;

  Future<void> fetchStatus() async {
    try {
      final res = await _getCallbackStatusUseCase.call();
      if (res['status'] != null) {
        _status = res['status'] as String?;
        if (res['requestedAt'] != null) {
          _requestedAt = DateTime.tryParse(res['requestedAt'] as String);
        }
        _isRequested = _status == 'pending';
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[AiCallbackProvider] fetchStatus error: $e');
    }
  }

  Future<String?> requestCallback({
    required String clinicId,
    required String phone,
    required String scheduledAt,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _requestCallbackUseCase.call(clinicId, phone, scheduledAt);
      _isRequested = true;
      _requestId = res['requestId'] as String? ?? 'cb_pending';
      _status = 'pending';
      _requestedAt = DateTime.now();
      _isLoading = false;
      notifyListeners();
      return _requestId;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> cancelCallback() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _cancelCallbackUseCase.call();
      _isRequested = false;
      _status = 'cancelled';
      _requestId = null;
      _requestedAt = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void reset() {
    _isLoading = false;
    _isRequested = false;
    _requestId = null;
    _status = null;
    _requestedAt = null;
    _errorMessage = null;
    notifyListeners();
  }
}
