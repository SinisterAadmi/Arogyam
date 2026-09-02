import 'package:flutter_test/flutter_test.dart';
import 'package:arogyam_flutter/features/patient/presentation/providers/queue_provider.dart';
import 'package:arogyam_flutter/features/queue/domain/usecases/get_queue_status.dart';
import 'package:arogyam_flutter/features/queue/domain/usecases/join_queue.dart';
import 'package:arogyam_flutter/features/queue/domain/usecases/auto_check_in_patient.dart';
import 'package:arogyam_flutter/features/queue/domain/repositories/queue_repository.dart';
import 'package:arogyam_flutter/features/patient/data/models/queue_status_model.dart';

class MockQueueRepo extends QueueRepository {
  @override
  Future<QueueStatusModel> getQueueStatus() async {
    return QueueStatusModel(
      clinicName: 'Sunrise Medical Center',
      tokenNumber: '101',
      peopleAhead: 0,
      currentlyServing: '101',
      estimatedWaitTime: '0',
      status: 'waiting',
    );
  }

  @override
  Future<QueueStatusModel> joinQueue(String clinicId) async {
    return QueueStatusModel(
      clinicName: 'Sunrise Medical Center',
      tokenNumber: '102',
      peopleAhead: 1,
      currentlyServing: '101',
      estimatedWaitTime: '10 mins',
      status: 'waiting',
    );
  }

  @override
  Future<QueueStatusModel> autoCheckIn(String clinicId) async => throw UnimplementedError();
}

void main() {
  group('QueueProvider & QueueStatusModel Tests', () {
    test('QueueProvider initializes correctly', () {
      final repo = MockQueueRepo();
      final provider = QueueProvider(
        getQueueStatus: GetQueueStatus(repo),
        joinQueue: JoinQueue(repo),
        autoCheckInPatient: AutoCheckInPatient(repo),
      );

      expect(provider.isLoading, isFalse);
      expect(provider.checkInStatus, CheckInStatus.none);
    });

    test('QueueProvider joinQueue succeeds and updates status', () async {
      final repo = MockQueueRepo();
      final provider = QueueProvider(
        getQueueStatus: GetQueueStatus(repo),
        joinQueue: JoinQueue(repo),
        autoCheckInPatient: AutoCheckInPatient(repo),
      );

      final success = await provider.joinQueue('clinic-123');
      expect(success, isTrue);
      expect(provider.status?.tokenNumber, '102');
      expect(provider.status?.clinicName, 'Sunrise Medical Center');
      expect(provider.checkInStatus, CheckInStatus.checkedIn);
    });

    test('QueueStatusModel.fromJson parses completed status correctly', () {
      final json = {
        'clinicName': 'Sunrise Medical Center',
        'tokenNumber': 105,
        'peopleAhead': 0,
        'currentlyServing': 0,
        'estimatedWaitTime': 0,
        'status': 'completed',
        'completedAt': '2026-08-31T12:00:00.000Z',
        'message': 'Your consultation is complete',
      };

      final model = QueueStatusModel.fromJson(json);
      expect(model.clinicName, 'Sunrise Medical Center');
      expect(model.tokenNumber, '105');
      expect(model.status, 'completed');
      expect(model.isInQueue, isTrue);
      expect(model.completedAt, '2026-08-31T12:00:00.000Z');
      expect(model.message, 'Your consultation is complete');
    });

    test('QueueStatusModel.fromJson parses absent status correctly', () {
      final json = {
        'clinicName': 'Sunrise Medical Center',
        'tokenNumber': 105,
        'peopleAhead': 0,
        'currentlyServing': 0,
        'estimatedWaitTime': 0,
        'status': 'absent',
        'message': 'You were marked absent',
      };

      final model = QueueStatusModel.fromJson(json);
      expect(model.status, 'absent');
      expect(model.isInQueue, isTrue);
    });

    test('QueueStatusModel.fromJson parses notInQueue fallback', () {
      final json = {'message': 'Not in any queue'};
      final model = QueueStatusModel.fromJson(json);
      expect(model.status, 'none');
      expect(model.isInQueue, isFalse);
    });
  });
}
