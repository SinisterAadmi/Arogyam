import 'package:flutter_test/flutter_test.dart';
import 'package:arogyam_flutter/features/patient/presentation/providers/abha_provider.dart';

void main() {
  late AbhaProvider abhaProvider;

  setUp(() {
    abhaProvider = AbhaProvider();
  });

  group('AbhaProvider Tests', () {
    test('initial state should be empty', () {
      expect(abhaProvider.abhaId, '');
      expect(abhaProvider.otp, '');
      expect(abhaProvider.otpSent, false);
      expect(abhaProvider.isLinked, false);
    });

    test('validateAbhaId should return false for invalid ID', () {
      abhaProvider.setAbhaId('123');
      expect(abhaProvider.validateAbhaId(), false);
      expect(abhaProvider.error, 'Please enter a valid 14-digit ABHA ID');
    });

    test('validateAbhaId should return true for valid 14-digit ID', () {
      abhaProvider.setAbhaId('91-8273-1284-9102');
      expect(abhaProvider.validateAbhaId(), true);
      expect(abhaProvider.error, null);
    });

    test('sendOtp should set otpSent to true on success', () async {
      abhaProvider.setAbhaId('91-8273-1284-9102');
      await abhaProvider.sendOtp();
      expect(abhaProvider.otpSent, true);
    });

    test('verifyOtpAndLink should set isLinked to true', () async {
      abhaProvider.setAbhaId('91-8273-1284-9102');
      await abhaProvider.sendOtp();
      abhaProvider.setOtp('123456');
      final result = await abhaProvider.verifyOtpAndLink();
      expect(result, true);
      expect(abhaProvider.isLinked, true);
    });
  });
}
