import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/usecases/request_callback.dart';
import '../../domain/usecases/cancel_callback.dart';
import '../../domain/usecases/get_callback_status.dart';
import '../../domain/usecases/trigger_vapi_callback.dart';
import '../../../../core/socket/socket_service.dart';

class AiCallbackProvider extends ChangeNotifier {
  final RequestCallback _requestCallbackUseCase;
  final CancelCallback _cancelCallbackUseCase;
  final GetCallbackStatus _getCallbackStatusUseCase;
  final TriggerVapiCallback? _triggerVapiCallbackUseCase;

  bool _isLoading = false;
  bool _isRequested = false;
  bool _isCalling = false;
  String? _requestId;
  String? _activeAppointmentId;
  String? _vapiCallId;
  String? _status;
  String? _outcome; // 'calling' | 'confirmed' | 'reschedule_requested' | 'cancel_requested' | 'no_answer' | 'unclear'
  String? _doctorName;
  String? _specialty;
  String? _clinicName;
  String? _clinicPhone;
  DateTime? _scheduledAt;
  DateTime? _requestedAt;
  String? _errorMessage;

  StreamSubscription? _socketSubscription;

  AiCallbackProvider({
    required RequestCallback requestCallbackUseCase,
    required CancelCallback cancelCallbackUseCase,
    required GetCallbackStatus getCallbackStatusUseCase,
    TriggerVapiCallback? triggerVapiCallbackUseCase,
  })  : _requestCallbackUseCase = requestCallbackUseCase, // ignore: prefer_initializing_formals
        _cancelCallbackUseCase = cancelCallbackUseCase, // ignore: prefer_initializing_formals
        _getCallbackStatusUseCase = getCallbackStatusUseCase, // ignore: prefer_initializing_formals
        _triggerVapiCallbackUseCase = triggerVapiCallbackUseCase { // ignore: prefer_initializing_formals
    _initSocketListener();
  }

  bool get isLoading => _isLoading;
  bool get isRequested => _isRequested;
  bool get isCalling => _isCalling;
  String? get requestId => _requestId;
  String? get activeAppointmentId => _activeAppointmentId;
  String? get vapiCallId => _vapiCallId;
  String? get status => _status;
  String? get outcome => _outcome;
  String? get doctorName => _doctorName;
  String? get specialty => _specialty;
  String? get clinicName => _clinicName;
  String? get clinicPhone => _clinicPhone;
  DateTime? get scheduledAt => _scheduledAt;
  DateTime? get requestedAt => _requestedAt;
  String? get errorMessage => _errorMessage;

  void _initSocketListener() {
    _socketSubscription?.cancel();
    _socketSubscription = SocketService().appointmentStatusStream.listen((data) {
      final apptId = data['appointmentId'];
      if (_activeAppointmentId == null || _activeAppointmentId == apptId) {
        _outcome = data['status'] as String?;
        _status = (data['appointmentStatus'] ?? data['status']) as String?;
        if (data['doctorName'] != null) _doctorName = data['doctorName'] as String?;
        if (data['specialty'] != null) _specialty = data['specialty'] as String?;
        if (data['clinicName'] != null) _clinicName = data['clinicName'] as String?;
        if (data['clinicPhone'] != null) _clinicPhone = data['clinicPhone'] as String?;
        if (data['scheduledAt'] != null) {
          _scheduledAt = DateTime.tryParse(data['scheduledAt'] as String);
        }
        _isCalling = false;
        notifyListeners();
      }
    });
  }

  void setupSocketAuth(String token) {
    SocketService().connect(token: token);
    if (_activeAppointmentId != null) {
      SocketService().subscribeToAppointment(_activeAppointmentId!);
    }
  }

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

  Future<void> triggerVapiCall({
    required String clinicId,
    String? doctorId,
    String? scheduledAt,
    String? phone,
    String? token,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _isCalling = true;
    _outcome = 'calling';
    notifyListeners();

    if (token != null) {
      SocketService().connect(token: token);
    }

    try {
      final Map<String, dynamic> res;
      final triggerUseCase = _triggerVapiCallbackUseCase;
      if (triggerUseCase != null) {
        res = await triggerUseCase.call(
          clinicId: clinicId,
          doctorId: doctorId,
          scheduledAt: scheduledAt,
          phone: phone,
        );
      } else {
        res = await _requestCallbackUseCase.call(clinicId, phone ?? '', scheduledAt ?? '');
      }

      _activeAppointmentId = res['appointmentId'] as String?;
      _vapiCallId = res['vapiCallId'] as String?;
      _doctorName = res['doctorName'] as String?;
      _specialty = res['specialty'] as String?;
      _clinicName = res['clinicName'] as String?;
      _clinicPhone = res['clinicPhone'] as String?;
      if (res['scheduledAt'] != null) {
        _scheduledAt = DateTime.tryParse(res['scheduledAt'] as String);
      }
      _isRequested = true;
      _status = 'pending';
      _isLoading = false;

      if (_activeAppointmentId != null) {
        SocketService().subscribeToAppointment(_activeAppointmentId!);
      }

      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _isCalling = false;
      _outcome = null;
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
      _isCalling = false;
      _status = 'cancelled';
      _outcome = null;
      _requestId = null;
      _activeAppointmentId = null;
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
    _isCalling = false;
    _requestId = null;
    _activeAppointmentId = null;
    _vapiCallId = null;
    _status = null;
    _outcome = null;
    _doctorName = null;
    _specialty = null;
    _clinicName = null;
    _clinicPhone = null;
    _scheduledAt = null;
    _requestedAt = null;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    super.dispose();
  }
}
