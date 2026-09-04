import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _auth = LocalAuthentication();

  // App-level biometric session state
  bool _isAppLockEnabled = false;
  bool _isVaultUnlocked = false;

  bool get isAppLockEnabled => _isAppLockEnabled;
  bool get isVaultUnlocked => _isVaultUnlocked;

  void setAppLockEnabled(bool enabled) {
    _isAppLockEnabled = enabled;
  }

  void setVaultUnlocked(bool unlocked) {
    _isVaultUnlocked = unlocked;
  }

  /// Checks whether device hardware supports biometric authentication
  Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (e) {
      debugPrint('[BiometricService] isDeviceSupported error: $e');
      return false;
    }
  }

  /// Checks whether biometrics can be checked and evaluated
  Future<bool> canCheckBiometrics() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (e) {
      debugPrint('[BiometricService] canCheckBiometrics error: $e');
      return false;
    }
  }

  /// Retrieves list of enrolled biometric types (e.g. fingerprint, face)
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('[BiometricService] getAvailableBiometrics error: $e');
      return [];
    }
  }

  /// Authenticate with biometric hardware or device credentials fallback (PIN/pattern/passcode).
  /// If the device lacks biometric hardware or no biometrics are enrolled,
  /// returns true when [bypassIfUnsupported] is set to true (graceful fallback).
  Future<bool> authenticate({
    String localizedReason = 'Authenticate to access your Arogyam Health Records',
    bool bypassIfUnsupported = true,
  }) async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;

      if (!isSupported || !canCheck) {
        debugPrint('[BiometricService] Biometrics not supported on device. Graceful fallback.');
        return bypassIfUnsupported;
      }

      final available = await _auth.getAvailableBiometrics();
      if (available.isEmpty) {
        debugPrint('[BiometricService] No biometrics enrolled on device. Graceful fallback.');
        return bypassIfUnsupported;
      }

      final didAuthenticate = await _auth.authenticate(
        localizedReason: localizedReason,
        biometricOnly: false, // allows PIN/pattern device fallback
        persistAcrossBackgrounding: true,
      );

      debugPrint('[BiometricService] Authenticated: $didAuthenticate');
      return didAuthenticate;
    } on PlatformException catch (e) {
      debugPrint('[BiometricService] PlatformException: ${e.code} - ${e.message}');
      if (e.code == 'NotAvailable' || e.code == 'PasscodeNotSet' || e.code == 'NotEnrolled') {
        return bypassIfUnsupported;
      }
      return false;
    } catch (e, stackTrace) {
      debugPrint('[BiometricService] General authentication error: $e\n$stackTrace');
      return false;
    }
  }
}
