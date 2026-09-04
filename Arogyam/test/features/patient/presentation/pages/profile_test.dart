import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:arogyam_flutter/app/router/app_router.dart';
import 'package:arogyam_flutter/app/router/route_names.dart';
import 'package:arogyam_flutter/app/router/navigation_provider.dart';
import 'package:arogyam_flutter/features/patient/presentation/providers/patient_home_provider.dart';
import 'package:arogyam_flutter/features/patient/presentation/providers/abha_provider.dart';
import 'package:arogyam_flutter/features/patient/presentation/providers/appointment_provider.dart';
import 'package:arogyam_flutter/features/patient/presentation/providers/queue_provider.dart';
import 'package:arogyam_flutter/features/patient/presentation/providers/prescriptions_provider.dart';
import 'package:arogyam_flutter/features/patient/presentation/providers/medical_history_provider.dart';
import 'package:arogyam_flutter/features/patient/presentation/providers/nearby_clinics_provider.dart';
import 'package:arogyam_flutter/features/patient/presentation/providers/patient_profile_provider.dart';
import 'package:arogyam_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:arogyam_flutter/features/patient/presentation/pages/patient_main/patient_main_screen.dart';
import 'package:arogyam_flutter/features/patient/data/models/patient_model.dart';
import 'package:arogyam_flutter/features/patient/domain/repositories/patient_repository.dart';
import 'package:arogyam_flutter/features/patient/domain/entities/patient.dart';
import 'package:arogyam_flutter/features/patient/domain/repositories/appointment_repository.dart';
import 'package:arogyam_flutter/features/patient/data/models/appointment_model.dart';
import 'package:arogyam_flutter/features/queue/domain/repositories/queue_repository.dart';
import 'package:arogyam_flutter/features/patient/data/models/queue_status_model.dart';
import 'package:arogyam_flutter/features/patient/domain/repositories/prescription_repository.dart';
import 'package:arogyam_flutter/shared/entities/prescription.dart';
import 'package:arogyam_flutter/features/patient/domain/repositories/clinic_repository.dart';
import 'package:arogyam_flutter/shared/entities/clinic.dart';
import 'package:arogyam_flutter/features/patient/domain/repositories/medical_history_repository.dart';
import 'package:arogyam_flutter/features/patient/domain/repositories/abha_repository.dart';
import 'package:arogyam_flutter/features/patient/data/models/abha_model.dart';
import 'package:arogyam_flutter/features/patient/domain/usecases/get_upcoming_appointments.dart';
import 'package:arogyam_flutter/features/queue/domain/usecases/get_queue_status.dart';
import 'package:arogyam_flutter/features/patient/domain/usecases/get_active_prescriptions_usecase.dart';
import 'package:arogyam_flutter/features/patient/domain/usecases/book_appointment.dart';
import 'package:arogyam_flutter/features/queue/domain/usecases/join_queue.dart';
import 'package:arogyam_flutter/features/queue/domain/usecases/auto_check_in_patient.dart';
import 'package:arogyam_flutter/features/patient/domain/usecases/get_medical_history.dart';
import 'package:arogyam_flutter/features/patient/domain/usecases/get_nearby_clinics_usecase.dart';
import 'package:arogyam_flutter/features/patient/domain/usecases/update_patient_profile.dart';
import 'package:arogyam_flutter/features/ai_callback/domain/repositories/ai_callback_repository.dart';
import 'package:arogyam_flutter/features/ai_callback/domain/usecases/request_callback.dart';
import 'package:arogyam_flutter/features/ai_callback/domain/usecases/cancel_callback.dart';
import 'package:arogyam_flutter/features/ai_callback/domain/usecases/get_callback_status.dart';
import 'package:arogyam_flutter/features/ai_callback/presentation/providers/ai_callback_provider.dart';

// Mock implementations
class MockPatientRepository extends PatientRepository {
  @override Future<Patient?> getPatientMe() async => null;
  @override Future<void> linkAbhaId(String abhaId, String otp) async {}
  @override Future<void> updatePatientProfile(PatientModel patient) async {}
  @override Future<List<Map<String, dynamic>>> getAccessHistory() async => [];
}

class MockAiCallbackRepository extends AiCallbackRepository {
  @override Future<Map<String, dynamic>> requestCallback(String clinicId, String phone, String scheduledAt) async => {};
  @override Future<Map<String, dynamic>> triggerVapiCallback({required String clinicId, String? doctorId, String? scheduledAt, String? phone}) async => {};
  @override Future<Map<String, dynamic>> getCallbackStatus() async => {'status': 'none'};
  @override Future<void> cancelCallback() async {}
}

class MockAppointmentRepository extends AppointmentRepository {
  @override Future<List<AppointmentModel>> getUpcomingAppointments() async => [];
  @override Future<AppointmentModel> getAppointmentById(String id) async => throw UnimplementedError();
  @override Future<AppointmentModel> cancelAppointment(String id) async => throw UnimplementedError();
  @override Future<AppointmentModel> bookAppointment(String clinicId, String doctorId, DateTime scheduledAt) async => throw UnimplementedError();
}

class MockQueueRepository extends QueueRepository {
  @override Future<QueueStatusModel> getQueueStatus() async => QueueStatusModel.notInQueue();
  @override Future<QueueStatusModel> joinQueue(String clinicId) async => QueueStatusModel.notInQueue();
  @override Future<QueueStatusModel> autoCheckIn(String clinicId) async => QueueStatusModel.notInQueue();
}

class MockPrescriptionRepository extends PrescriptionRepository {
  @override Future<List<Prescription>> getActivePrescriptions() async => [];
}

class MockClinicRepository extends ClinicRepository {
  @override Future<List<Clinic>> getNearbyClinics({double? lat, double? lng}) async => [];
}

class MockMedicalHistoryRepository extends MedicalHistoryRepository {
  @override Future<List<MedicalRecord>> getMedicalHistory() async => [];
  @override Future<void> shareMedicalHistory(String doctorId) async {}
}

class MockAbhaRepository extends AbhaRepository {
  @override Future<AbhaModel> getAbhaStatus() async => AbhaModel(abhaId: '');
  @override Future<void> linkAbha(String abhaId, String otp) async {}
}

class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
    HttpOverrides.global = MockHttpOverrides();
    
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall methodCall) async {
        if (methodCall.method == 'SystemNavigator.pop') {
          return null;
        }
        return null;
      },
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return '.';
      },
    );
  });

  Widget createTestWidget() {
    final patientRepo = MockPatientRepository();
    final appointRepo = MockAppointmentRepository();
    final queueRepo = MockQueueRepository();
    final prescriptionRepo = MockPrescriptionRepository();
    final clinicRepo = MockClinicRepository();
    final historyRepo = MockMedicalHistoryRepository();
    final abhaRepo = MockAbhaRepository();
    final aiRepo = MockAiCallbackRepository();

    final getUpcoming = GetUpcomingAppointmentsUseCase(appointRepo);
    final getQueue = GetQueueStatus(queueRepo);
    final getPrescriptions = GetActivePrescriptionsUseCase(prescriptionRepo);
    final bookAppoint = BookAppointment(appointRepo);
    final joinQ = JoinQueue(queueRepo);
    final autoCheck = AutoCheckInPatient(queueRepo);
    final getHistory = GetMedicalHistory(historyRepo);
    final getClinics = GetNearbyClinicsUseCase(clinicRepo);
    final updateProfile = UpdatePatientProfile(patientRepo);

    final reqCb = RequestCallback(aiRepo);
    final cancelCb = CancelCallback(aiRepo);
    final getCbStatus = GetCallbackStatus(aiRepo);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => PatientHomeProvider(
          patientRepository: patientRepo,
          getUpcomingAppointmentsUseCase: getUpcoming,
          getQueueStatusUseCase: getQueue,
          getActivePrescriptionsUseCase: getPrescriptions,
        )),
        ChangeNotifierProvider(create: (_) => AbhaProvider(repository: abhaRepo)),
        ChangeNotifierProvider(create: (_) => AppointmentProvider(
          bookAppointmentUseCase: bookAppoint,
        )),
        ChangeNotifierProvider(create: (_) => QueueProvider(
          getQueueStatus: getQueue,
          joinQueue: joinQ,
          autoCheckInPatient: autoCheck,
        )),
        ChangeNotifierProvider(create: (_) => PrescriptionsProvider(
          getActivePrescriptionsUseCase: getPrescriptions,
        )),
        ChangeNotifierProvider(create: (_) => MedicalHistoryProvider(
          getMedicalHistory: getHistory,
        )),
        ChangeNotifierProvider(create: (_) => NearbyClinicsProvider(
          getNearbyClinicsUseCase: getClinics,
        )),
        ChangeNotifierProvider(create: (_) => PatientProfileProvider(
          patientRepository: patientRepo,
          updatePatientProfileUseCase: updateProfile,
        )),
        ChangeNotifierProvider(create: (_) => AiCallbackProvider(
          requestCallbackUseCase: reqCb,
          cancelCallbackUseCase: cancelCb,
          getCallbackStatusUseCase: getCbStatus,
        )),
      ],
      child: MaterialApp(
        onGenerateRoute: AppRouter.onGenerateRoute,
        initialRoute: RouteNames.patientHome,
      ),
    );
  }

  Future<void> settle(WidgetTester tester) async {
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('Profile tab is shown and masked ABHA ID is displayed', (WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(createTestWidget());
      
      final profileProvider = tester.element(find.byType(MaterialApp)).read<PatientProfileProvider>();
      profileProvider.setPatient(PatientModel(
        id: '1',
        name: 'Test Patient',
        abhaId: '91-1234-5678-9012',
        isAbhaLinked: true,
      ));

      // Go to Profile tab
      final navProvider = tester.element(find.byType(PatientMainScreen)).read<NavigationProvider>();
      navProvider.setIndex(4);
      await settle(tester);

      expect(find.text('Personal Details'), findsOneWidget);
      expect(find.textContaining('XXXX-XXXX-9012'), findsWidgets);
    });
  });
}
