import 'package:flutter_test/flutter_test.dart';
import 'package:arogyam_flutter/features/clinic/reception/data/datasources/reception_remote_datasource.dart';
import 'package:arogyam_flutter/features/clinic/reception/data/models/reception_queue_models.dart';
import 'package:arogyam_flutter/features/clinic/reception/presentation/providers/checkin_provider.dart';

class MockReceptionRemoteDataSource extends ReceptionRemoteDataSource {
  @override
  Future<ConsentVerificationResult> verifyShortCode(String code) async {
    if (code == 'EXPIRE') {
      throw Exception('Consent session has expired');
    }
    return ConsentVerificationResult(
      success: true,
      message: 'Medical consent short code verified successfully.',
      sessionId: 'sess-123',
      patientId: 'pat-123',
      patientName: 'Aarav Sharma',
      abhaId: '12-3456-7890-1234',
      isAbhaLinked: true,
      usedMethod: 'code',
      usedAt: DateTime.now(),
    );
  }

  @override
  Future<ConsentVerificationResult> verifyQrToken(String qrToken) async {
    return ConsentVerificationResult(
      success: true,
      message: 'QR code verified successfully.',
      sessionId: 'sess-123',
      patientId: 'pat-123',
      patientName: 'Aarav Sharma',
      abhaId: '12-3456-7890-1234',
      isAbhaLinked: true,
      usedMethod: 'qr',
      usedAt: DateTime.now(),
    );
  }

  @override
  Future<List<AiCallbackItem>> getAiCallbacks() async {
    return [
      AiCallbackItem(
        id: 'cb-1',
        patientId: 'pat-123',
        patientName: 'Aarav Sharma',
        phone: '+917276633833',
        status: 'pending',
        requestedSlot: DateTime.now(),
        createdAt: DateTime.now(),
      ),
    ];
  }

  @override
  Future<void> resolveAiCallback(String id) async {}
}

void main() {
  group('CheckInProvider Tests', () {
    late CheckInProvider provider;
    late MockReceptionRemoteDataSource mockDataSource;

    setUp(() {
      mockDataSource = MockReceptionRemoteDataSource();
      provider = CheckInProvider(dataSource: mockDataSource);
    });

    test('initial values are correct', () {
      expect(provider.isVerifying, isFalse);
      expect(provider.verifiedResult, isNull);
      expect(provider.errorMessage, isNull);
      expect(provider.aiCallbacks, isEmpty);
    });

    test('verifyShortCode succeeds for valid 6-char code', () async {
      final success = await provider.verifyShortCode('77DW6M');
      expect(success, isTrue);
      expect(provider.verifiedResult?.patientName, 'Aarav Sharma');
      expect(provider.verifiedResult?.usedMethod, 'code');
      expect(provider.errorMessage, isNull);
    });

    test('verifyShortCode fails for invalid code length', () async {
      final success = await provider.verifyShortCode('123');
      expect(success, isFalse);
      expect(provider.errorMessage, contains('valid 6-character code'));
    });

    test('verifyQrData succeeds', () async {
      final success = await provider.verifyQrData('qr_token_abc_123');
      expect(success, isTrue);
      expect(provider.verifiedResult?.patientName, 'Aarav Sharma');
      expect(provider.verifiedResult?.usedMethod, 'qr');
    });

    test('fetchAiCallbacks populates list and resolveCallback updates it', () async {
      await provider.fetchAiCallbacks();
      expect(provider.aiCallbacks.length, 1);
      expect(provider.aiCallbacks.first.patientName, 'Aarav Sharma');

      final resolved = await provider.resolveCallback('cb-1');
      expect(resolved, isTrue);
      expect(provider.aiCallbacks, isEmpty);
    });
  });
}
