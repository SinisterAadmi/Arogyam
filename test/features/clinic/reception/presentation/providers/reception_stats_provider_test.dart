import 'package:flutter_test/flutter_test.dart';
import 'package:arogyam_flutter/features/clinic/reception/data/datasources/reception_remote_datasource.dart';
import 'package:arogyam_flutter/features/clinic/reception/data/models/reception_queue_models.dart';
import 'package:arogyam_flutter/features/clinic/reception/presentation/providers/reception_stats_provider.dart';

class MockStatsDataSource extends ReceptionRemoteDataSource {
  @override
  Future<ClinicAnalytics> getAnalytics() async {
    return ClinicAnalytics(
      clinicId: 'clinic-123',
      clinicName: 'Sunrise Medical Center',
      totalPatientsToday: 10,
      patientsServedToday: 7,
      currentlyWaiting: 2,
      currentlyServing: 108,
      averageWaitTimeMinutes: 5,
      totalAppointmentsToday: 12,
      hourlyFlow: [
        HourlyFlowItem(hour: '09:00', count: 3),
        HourlyFlowItem(hour: '10:00', count: 7),
      ],
    );
  }
}

void main() {
  group('ReceptionStatsProvider Tests', () {
    late ReceptionStatsProvider provider;
    late MockStatsDataSource mockDataSource;

    setUp(() {
      mockDataSource = MockStatsDataSource();
      provider = ReceptionStatsProvider(dataSource: mockDataSource);
    });

    test('initial values are correct', () {
      expect(provider.isLoading, isFalse);
      expect(provider.analytics, isNull);
      expect(provider.errorMessage, isNull);
    });

    test('fetchAnalytics loads clinic stats correctly', () async {
      await provider.fetchAnalytics();
      expect(provider.analytics, isNotNull);
      expect(provider.analytics?.clinicName, 'Sunrise Medical Center');
      expect(provider.analytics?.totalPatientsToday, 10);
      expect(provider.analytics?.patientsServedToday, 7);
      expect(provider.analytics?.averageWaitTimeMinutes, 5);
      expect(provider.analytics?.hourlyFlow.length, 2);
    });
  });
}
