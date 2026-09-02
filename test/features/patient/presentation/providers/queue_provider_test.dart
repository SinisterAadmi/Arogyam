import 'package:flutter_test/flutter_test.dart';
import 'package:arogyam_flutter/features/patient/presentation/providers/queue_provider.dart';

void main() {
  late QueueProvider queueProvider;

  setUp(() {
    queueProvider = QueueProvider();
  });

  group('QueueProvider Tests', () {
    test('initial state should fetch status', () async {
      // Small delay to allow initial fetch
      await Future.delayed(const Duration(milliseconds: 100));
      expect(queueProvider.status, isNotNull);
      expect(queueProvider.status?.tokenNumber, '15');
      expect(queueProvider.checkInStatus, CheckInStatus.none);
    });

    test('updateArrivedNearby should change check-in status', () async {
      await queueProvider.updateArrivedNearby();
      expect(queueProvider.checkInStatus, CheckInStatus.nearby);
    });

    test('checkInViaQR should set status to checkedIn', () async {
      await queueProvider.updateArrivedNearby();
      final result = await queueProvider.checkInViaQR('MOCK_QR');
      expect(result, true);
      expect(queueProvider.checkInStatus, CheckInStatus.checkedIn);
    });
  });
}
