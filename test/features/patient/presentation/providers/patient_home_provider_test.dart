import 'package:flutter_test/flutter_test.dart';
import 'package:arogyam_flutter/features/patient/presentation/providers/patient_home_provider.dart';

void main() {
  late PatientHomeProvider provider;

  setUp(() {
    provider = PatientHomeProvider();
  });

  group('PatientHomeProvider Tests', () {
    test('loadDashboardData should populate data', () async {
      expect(provider.patient, null);
      
      await provider.loadDashboardData();
      
      expect(provider.patient, isNotNull);
      expect(provider.patient?.name, 'Rajesh Kumar');
      expect(provider.upcomingAppointment, isNotNull);
      expect(provider.queueStatus, isNotNull);
      expect(provider.activePrescriptionsCount, 3);
    });
  });
}
