import 'package:flutter/material.dart';
import '../../../../core/security/biometric_service.dart';
import '../../data/models/patient_model.dart';

class PatientProfileProvider extends ChangeNotifier {
  PatientModel? _patient;
  bool _isLoading = false;
  bool _isBiometricEnabled = false;

  PatientModel? get patient => _patient;
  bool get isLoading => _isLoading;
  bool get isBiometricEnabled => _isBiometricEnabled;

  void setPatient(PatientModel patient) {
    _patient = patient;
    notifyListeners();
  }

  Future<void> updateProfile(PatientModel updatedPatient) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      _patient = updatedPatient;
    } catch (e) {
      // Error handling
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleBiometrics(bool value) async {
    if (value) {
      final success = await BiometricService().authenticate();
      if (success) {
        _isBiometricEnabled = true;
      }
    } else {
      _isBiometricEnabled = false;
    }
    notifyListeners();
  }
}
