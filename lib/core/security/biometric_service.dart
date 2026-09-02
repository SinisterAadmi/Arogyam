class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  Future<bool> canCheckBiometrics() async => true;

  Future<bool> authenticate() async {
    // Simulate biometric authentication
    await Future.delayed(const Duration(milliseconds: 800));
    return true;
  }
}
