import 'package:flutter_test/flutter_test.dart';
import 'package:arogyam_flutter/features/patient/presentation/providers/appointment_provider.dart';
import 'package:arogyam_flutter/features/patient/domain/usecases/book_appointment.dart';
import 'package:arogyam_flutter/features/patient/domain/repositories/appointment_repository.dart';
import 'package:arogyam_flutter/features/patient/data/models/appointment_model.dart';
import 'package:arogyam_flutter/shared/entities/clinic.dart';

class MockAppointmentRepository extends AppointmentRepository {
  @override Future<List<AppointmentModel>> getUpcomingAppointments() async => [];
  @override
  Future<AppointmentModel> bookAppointment(String clinicId, String doctorId, DateTime scheduledAt) async {
    return AppointmentModel(
      id: '1',
      doctorName: 'Dr. Test',
      specialty: 'General',
      clinicName: 'Test Clinic',
      appointmentTime: scheduledAt.toIso8601String(),
      tokenNumber: '1',
      status: 'scheduled',
    );
  }
}

void main() {
  late AppointmentProvider provider;
  late MockAppointmentRepository repository;

  setUp(() {
    repository = MockAppointmentRepository();
    final useCase = BookAppointment(repository);
    provider = AppointmentProvider(bookAppointmentUseCase: useCase);
  });

  const testClinic = Clinic(
    id: '1',
    name: 'Test Clinic',
    address: 'Test Address',
    latitude: 0,
    longitude: 0,
    distanceKm: 0,
    waitTimeMinutes: 0,
    isLiveQueueActive: true,
    rating: 5,
    reviewCount: 1,
  );

  test('initial state is correct', () {
    expect(provider.selectedDate, isNull);
    expect(provider.selectedSlot, isNull);
    expect(provider.isLoading, isFalse);
  });

  test('setDate updates selectedDate', () {
    final date = DateTime.now();
    provider.setDate(date);
    expect(provider.selectedDate, date);
  });

  test('bookAppointment returns true on success', () async {
    provider.setDate(DateTime.now());
    provider.setSlot('10:00 AM');
    
    final result = await provider.bookAppointment(testClinic);
    
    expect(result, isTrue);
    expect(provider.isLoading, isFalse);
  });
}
