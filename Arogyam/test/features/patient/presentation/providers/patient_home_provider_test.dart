import 'package:flutter_test/flutter_test.dart';
import 'package:arogyam_flutter/features/patient/presentation/providers/patient_home_provider.dart';
import 'package:arogyam_flutter/features/patient/domain/repositories/patient_repository.dart';
import 'package:arogyam_flutter/features/patient/domain/repositories/appointment_repository.dart';
import 'package:arogyam_flutter/features/queue/domain/repositories/queue_repository.dart';
import 'package:arogyam_flutter/features/patient/domain/repositories/prescription_repository.dart';
import 'package:arogyam_flutter/features/patient/domain/usecases/get_upcoming_appointments.dart';
import 'package:arogyam_flutter/features/queue/domain/usecases/get_queue_status.dart';
import 'package:arogyam_flutter/features/patient/domain/usecases/get_active_prescriptions_usecase.dart';
import 'package:arogyam_flutter/features/patient/domain/entities/patient.dart';
import 'package:arogyam_flutter/features/patient/data/models/patient_model.dart';
import 'package:arogyam_flutter/features/patient/data/models/appointment_model.dart';
import 'package:arogyam_flutter/features/patient/data/models/queue_status_model.dart';
import 'package:arogyam_flutter/shared/entities/prescription.dart';

class MockPatientRepo extends PatientRepository {
  @override Future<Patient?> getPatientMe() async => null;
  @override Future<void> linkAbhaId(String abhaId, String otp) async {}
  @override Future<void> updatePatientProfile(PatientModel patient) async {}
  @override Future<List<Map<String, dynamic>>> getAccessHistory() async => [];
}

class MockAppointRepo extends AppointmentRepository {
  @override Future<List<AppointmentModel>> getUpcomingAppointments() async => [];
  @override Future<AppointmentModel> getAppointmentById(String id) async => throw UnimplementedError();
  @override Future<AppointmentModel> cancelAppointment(String id) async => throw UnimplementedError();
  @override Future<AppointmentModel> bookAppointment(String clinicId, String doctorId, DateTime scheduledAt) async => throw UnimplementedError();
}

class MockQueueRepo extends QueueRepository {
  @override Future<QueueStatusModel> getQueueStatus() async => throw UnimplementedError();
  @override Future<QueueStatusModel> joinQueue(String clinicId) async => throw UnimplementedError();
  @override Future<QueueStatusModel> autoCheckIn(String clinicId) async => throw UnimplementedError();
}

class MockPrescriptionRepo extends PrescriptionRepository {
  @override Future<List<Prescription>> getActivePrescriptions() async => [];
}

void main() {
  test('PatientHomeProvider initializes correctly', () {
    final patientRepo = MockPatientRepo();
    final appointRepo = MockAppointRepo();
    final queueRepo = MockQueueRepo();
    final prescriptionRepo = MockPrescriptionRepo();

    final provider = PatientHomeProvider(
      patientRepository: patientRepo,
      getUpcomingAppointmentsUseCase: GetUpcomingAppointmentsUseCase(appointRepo),
      getQueueStatusUseCase: GetQueueStatus(queueRepo),
      getActivePrescriptionsUseCase: GetActivePrescriptionsUseCase(prescriptionRepo),
    );

    expect(provider.isLoading, isFalse);
    expect(provider.patient, isNull);
  });
}
