import 'package:flutter/material.dart';
import '../../../../core/security/token_manager.dart';
import '../../domain/repositories/abha_repository.dart';

class AbhaProvider extends ChangeNotifier {
  final AbhaRepository _repository;

  String _abhaId = '';
  String _otp = '';
  bool _isLoading = false;
  String? _error;
  bool _otpSent = false;
  bool _isLinked = false;

  AbhaProvider({required this._repository});

  String get abhaId => _abhaId;
  String get otp => _otp;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get otpSent => _otpSent;
  bool get isLinked => _isLinked;

  void setAbhaId(String value) {
    _abhaId = value;
    _error = null;
    notifyListeners();
  }

  void setOtp(String value) {
    _otp = value;
    _error = null;
    notifyListeners();
  }

  bool validateAbhaId() {
    // Basic format: 14 digits, maybe with hyphens
    final cleanId = _abhaId.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanId.length != 14) {
      _error = 'Please enter a valid 14-digit ABHA ID';
      notifyListeners();
      return false;
    }
    return true;
  }

  Future<void> sendOtp() async {
    if (!validateAbhaId()) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      _otpSent = true;
    } catch (e, stackTrace) {
      debugPrint('[Patient] error: $e\n$stackTrace');
      _error = 'Failed to send OTP. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyOtpAndLink() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.linkAbha(_abhaId, _otp);
      _isLinked = true;
      await TokenManager().saveAbhaId(_abhaId);
      return true;
    } catch (e, stackTrace) {
      debugPrint('[Patient] error: $e\n$stackTrace');
      _error = 'Verification failed. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    _abhaId = '';
    _otp = '';
    _otpSent = false;
    _error = null;
    notifyListeners();
  }
}
