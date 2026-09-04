import 'package:flutter/material.dart';
import '../../data/models/appointment_model.dart';
import '../../domain/usecases/get_appointment_by_id.dart';
import '../../domain/usecases/cancel_appointment.dart';

class AppointmentDetailsProvider extends ChangeNotifier {
  final GetAppointmentByIdUseCase _getAppointmentByIdUseCase;
  final CancelAppointmentUseCase _cancelAppointmentUseCase;

  AppointmentModel? _appointment;
  bool _isLoading = false;
  bool _isCancelling = false;
  String? _errorMessage;

  AppointmentDetailsProvider({
    required GetAppointmentByIdUseCase appointmentByIdUseCase,
    required CancelAppointmentUseCase cancelUseCase,
  })  : _getAppointmentByIdUseCase = appointmentByIdUseCase,
        _cancelAppointmentUseCase = cancelUseCase;

  AppointmentModel? get appointment => _appointment;
  bool get isLoading => _isLoading;
  bool get isCancelling => _isCancelling;
  String? get errorMessage => _errorMessage;

  Future<void> fetchAppointment(String appointmentId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _appointment = await _getAppointmentByIdUseCase(appointmentId);
    } catch (e, stackTrace) {
      debugPrint('[AppointmentDetailsProvider] fetch error: $e\n$stackTrace');
      _errorMessage = 'Failed to load appointment details';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cancelAppointment(String appointmentId) async {
    _isCancelling = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _cancelAppointmentUseCase(appointmentId);
      _appointment = updated;
      return true;
    } catch (e, stackTrace) {
      debugPrint('[AppointmentDetailsProvider] cancel error: $e\n$stackTrace');
      _errorMessage = 'Failed to cancel appointment. Please try again.';
      return false;
    } finally {
      _isCancelling = false;
      notifyListeners();
    }
  }
}
