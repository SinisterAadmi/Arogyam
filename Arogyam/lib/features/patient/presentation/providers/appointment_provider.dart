import 'package:flutter/material.dart';
import '../../../../shared/entities/clinic.dart';
import '../../domain/usecases/book_appointment.dart';

class AppointmentProvider extends ChangeNotifier {
  final BookAppointment _bookAppointmentUseCase;

  DateTime? _selectedDate;
  String? _selectedSlot;
  String _reason = '';
  String? _selectedDoctorId;
  bool _isLoading = false;
  String? _error;

  AppointmentProvider({required this._bookAppointmentUseCase});

  DateTime? get selectedDate => _selectedDate;
  String? get selectedSlot => _selectedSlot;
  String get reason => _reason;
  String? get selectedDoctorId => _selectedDoctorId;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void setDoctorId(String doctorId) {
    _selectedDoctorId = doctorId;
    notifyListeners();
  }

  void setDate(DateTime date) {
    _selectedDate = date;
    _selectedSlot = null; // Reset slot when date changes
    notifyListeners();
  }

  void setSlot(String slot) {
    _selectedSlot = slot;
    notifyListeners();
  }

  void setReason(String reason) {
    _reason = reason;
    notifyListeners();
  }

  Future<bool> bookAppointment(Clinic clinic) async {
    if (_selectedDate == null || _selectedSlot == null) {
      _error = 'Please select date and time slot';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final doctorId = _selectedDoctorId ??
          (clinic.doctors.isNotEmpty ? clinic.doctors.first.id : '1');

      // Combine selected date with selected time slot
      DateTime scheduledDateTime = _selectedDate!;
      if (_selectedSlot != null) {
        final match = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$', caseSensitive: false)
            .firstMatch(_selectedSlot!.trim());
        if (match != null) {
          int hour = int.parse(match.group(1)!);
          final minute = int.parse(match.group(2)!);
          final period = match.group(3)!.toUpperCase();
          if (period == 'PM' && hour < 12) hour += 12;
          if (period == 'AM' && hour == 12) hour = 0;
          scheduledDateTime = DateTime(
            _selectedDate!.year,
            _selectedDate!.month,
            _selectedDate!.day,
            hour,
            minute,
          );
        }
      }

      await _bookAppointmentUseCase(clinic.id, doctorId, scheduledDateTime);
      return true;
    } catch (e, stackTrace) {
      debugPrint('[Patient] error: $e\n$stackTrace');
      _error = 'Booking failed. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    _selectedDate = null;
    _selectedSlot = null;
    _reason = '';
    _selectedDoctorId = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
