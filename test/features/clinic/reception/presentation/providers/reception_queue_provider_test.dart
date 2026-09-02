import 'package:flutter_test/flutter_test.dart';
import 'package:arogyam_flutter/features/clinic/reception/data/models/reception_queue_models.dart';
import 'package:arogyam_flutter/features/clinic/reception/domain/repositories/reception_repository.dart';
import 'package:arogyam_flutter/features/clinic/reception/presentation/providers/reception_queue_provider.dart';

class MockReceptionRepository implements ReceptionRepository {
  ReceptionLiveQueueResponse mockQueue = ReceptionLiveQueueResponse(
    clinicId: 'c1',
    clinicName: 'Sunrise Medical Center',
    isLiveQueueActive: true,
    stats: ReceptionClinicStats(totalToday: 2, waitingCount: 1, currentlyServing: 101),
    tokens: [
      ReceptionQueueToken(
        id: 't1',
        tokenNumber: 101,
        status: 'serving',
        patientId: 'p1',
        patientName: 'Rohan Mehta',
        joinedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      ReceptionQueueToken(
        id: 't2',
        tokenNumber: 102,
        status: 'waiting',
        patientId: 'p2',
        patientName: 'Priya Singh',
        joinedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ],
  );

  @override
  Future<ReceptionLiveQueueResponse> getLiveQueue() async => mockQueue;

  @override
  Future<ReceptionQueueToken> updateTokenStatus(String tokenId, String status) async {
    return ReceptionQueueToken(
      id: tokenId,
      tokenNumber: 102,
      status: status,
      patientId: 'p2',
      patientName: 'Priya Singh',
      joinedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

void main() {
  group('ReceptionQueueProvider Tests', () {
    late ReceptionQueueProvider provider;
    late MockReceptionRepository repository;

    setUp(() {
      repository = MockReceptionRepository();
      provider = ReceptionQueueProvider(repository: repository);
    });

    test('initial values are correct', () {
      expect(provider.isLoading, false);
      expect(provider.queueData, isNull);
      expect(provider.selectedFilter, 'all');
      expect(provider.allTokens.isEmpty, true);
    });

    test('fetchQueue loads and populates queue data', () async {
      await provider.fetchQueue();
      expect(provider.queueData, isNotNull);
      expect(provider.clinicName, 'Sunrise Medical Center');
      expect(provider.totalToday, 2);
      expect(provider.waitingCount, 1);
      expect(provider.currentlyServing, 101);
      expect(provider.allTokens.length, 2);
    });

    test('setFilter updates filtered tokens correctly', () async {
      await provider.fetchQueue();
      provider.setFilter('waiting');
      expect(provider.filteredTokens.length, 1);
      expect(provider.filteredTokens.first.tokenNumber, 102);

      provider.setFilter('serving');
      expect(provider.filteredTokens.length, 1);
      expect(provider.filteredTokens.first.tokenNumber, 101);

      provider.setFilter('all');
      expect(provider.filteredTokens.length, 2);
    });

    test('updateStatus modifies the token in-place and notifies listeners', () async {
      await provider.fetchQueue();
      final success = await provider.updateStatus('t2', 'serving');
      expect(success, true);
      final updatedToken = provider.allTokens.firstWhere((t) => t.id == 't2');
      expect(updatedToken.status, 'serving');
    });
  });
}
