import 'package:flutter_test/flutter_test.dart';
import 'package:arogyam_flutter/features/patient/presentation/providers/appointment_provider.dart';
import 'package:arogyam_flutter/shared/entities/clinic.dart';

void main() {
  late AppointmentProvider appointmentProvider;
  const mockClinic = Clinic(
    id: '1',
    name: 'Test Clinic',
    address: 'Test Address',
    latitude: 0,
    longitude: 0,
    distanceKm: 0,
    waitTimeMinutes: 0,
    isLiveQueueActive: true,
    rating: 0,
    reviewCount: 0,
  );

  setUp(() {
    appointmentProvider = AppointmentProvider();
  });

  group('AppointmentProvider Tests', () {
    test('initial state should be empty', () {
      expect(appointmentProvider.selectedDate, null);
      expect(appointmentProvider.selectedSlot, null);
      expect(appointmentProvider.reason, '');
    });

    test('setDate should update date and reset slot', () {
      final date = DateTime.now();
      appointmentProvider.setSlot('10:00 AM');
      appointmentProvider.setDate(date);
      expect(appointmentProvider.selectedDate, date);
      expect(appointmentProvider.selectedSlot, null);
    });

    test('bookAppointment should return false if date or slot is missing', () async {
      final result = await appointmentProvider.bookAppointment(mockClinic);
      expect(result, false);
      expect(appointmentProvider.error, 'Please select date and time slot');
    });

    test('bookAppointment should return true on success', () async {
      appointmentProvider.setDate(DateTime.now());
      appointmentProvider.setSlot('10:00 AM');
      final result = await appointmentProvider.bookAppointment(mockClinic);
      expect(result, true);
      expect(appointmentProvider.error, null);
    });
  });
}
