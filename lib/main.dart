import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app/router/app_router.dart';
import 'app/router/navigation_provider.dart';
import 'app/theme/app_colors.dart';
import 'app/theme/app_theme.dart';
import 'core/network/api_client.dart';
import 'features/patient/presentation/providers/patient_home_provider.dart';
import 'features/patient/presentation/providers/abha_provider.dart';
import 'features/patient/presentation/providers/appointment_provider.dart';
import 'features/patient/presentation/providers/queue_provider.dart';
import 'features/patient/presentation/providers/prescriptions_provider.dart';
import 'features/patient/presentation/providers/medical_history_provider.dart';
import 'features/patient/presentation/providers/nearby_clinics_provider.dart';
import 'features/patient/presentation/providers/patient_profile_provider.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/patient/presentation/pages/patient_main/patient_main_screen.dart';
import 'features/patient/data/datasources/patient_remote_datasource.dart';
import 'features/patient/data/repositories/patient_repository_impl.dart';
import 'features/patient/data/datasources/appointment_remote_datasource.dart';
import 'features/patient/data/repositories/appointment_repository_impl.dart';
import 'features/queue/data/datasources/queue_remote_datasource.dart';
import 'features/queue/data/repositories/queue_repository_impl.dart';
import 'features/queue/domain/usecases/get_queue_status.dart';
import 'features/queue/domain/usecases/join_queue.dart';
import 'features/queue/domain/usecases/auto_check_in_patient.dart';
import 'features/patient/data/datasources/prescription_remote_datasource.dart';
import 'features/patient/data/prescription_repository.dart';
import 'features/patient/domain/usecases/get_upcoming_appointments.dart';
import 'features/patient/domain/usecases/get_active_prescriptions_usecase.dart';
import 'features/patient/data/datasources/clinic_remote_datasource.dart';
import 'features/patient/data/clinic_repository.dart';
import 'features/patient/domain/usecases/get_nearby_clinics_usecase.dart';
import 'features/patient/data/datasources/medical_history_remote_datasource.dart';
import 'features/patient/data/repositories/medical_history_repository_impl.dart';
import 'features/patient/domain/usecases/get_medical_history.dart';
import 'features/ai_callback/data/datasources/ai_callback_remote_datasource.dart';
import 'features/ai_callback/data/repositories/ai_callback_repository_impl.dart';
import 'features/ai_callback/domain/usecases/request_callback.dart';
import 'features/ai_callback/domain/usecases/cancel_callback.dart';
import 'features/ai_callback/domain/usecases/get_callback_status.dart';
import 'features/ai_callback/presentation/providers/ai_callback_provider.dart';
import 'features/patient/domain/usecases/update_patient_profile.dart';
import 'features/patient/domain/usecases/book_appointment.dart';

import 'features/patient/data/datasources/abha_remote_datasource.dart';
import 'features/patient/data/repositories/abha_repository_impl.dart';
import 'features/clinic/reception/data/datasources/reception_remote_datasource.dart';
import 'features/clinic/reception/data/repositories/reception_repository_impl.dart';
import 'features/clinic/reception/presentation/providers/checkin_provider.dart';
import 'features/clinic/reception/presentation/providers/reception_stats_provider.dart';
import 'features/clinic/reception/presentation/providers/clinic_details_provider.dart';
import 'features/clinic/reception/presentation/providers/reception_queue_provider.dart';
import 'features/clinic/reception/presentation/pages/reception_main/reception_main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.card,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Core
  final apiClient = ApiClient();

  // Datasources
  final patientRemoteDatasource = PatientRemoteDatasourceImpl(apiClient);
  final appointmentRemoteDatasource = AppointmentRemoteDatasourceImpl(apiClient);
  final queueRemoteDatasource = QueueRemoteDatasourceImpl(apiClient);
  final prescriptionRemoteDatasource = PrescriptionRemoteDatasourceImpl(apiClient);
  final clinicRemoteDatasource = ClinicRemoteDatasourceImpl(apiClient);
  final medicalHistoryRemoteDatasource = MedicalHistoryRemoteDatasourceImpl(apiClient);
  final aiCallbackRemoteDatasource = AiCallbackRemoteDatasourceImpl(apiClient);
  final abhaRemoteDatasource = AbhaRemoteDatasourceImpl(apiClient);
  final receptionRemoteDatasource = ReceptionRemoteDataSource();

  // Repositories
  final patientRepository = PatientRepositoryImpl(patientRemoteDatasource);
  final appointmentRepository = AppointmentRepositoryImpl(appointmentRemoteDatasource);
  final queueRepository = QueueRepositoryImpl(queueRemoteDatasource);
  final prescriptionRepository = PrescriptionRepositoryImpl(prescriptionRemoteDatasource);
  final clinicRepository = ClinicRepositoryImpl(clinicRemoteDatasource);
  final medicalHistoryRepository = MedicalHistoryRepositoryImpl(medicalHistoryRemoteDatasource);
  final aiCallbackRepository = AiCallbackRepositoryImpl(aiCallbackRemoteDatasource);
  final abhaRepository = AbhaRepositoryImpl(abhaRemoteDatasource);
  final receptionRepository = ReceptionRepositoryImpl(remoteDataSource: receptionRemoteDatasource);

  // Usecases
  final getQueueStatus = GetQueueStatus(queueRepository);
  final joinQueue = JoinQueue(queueRepository);
  final autoCheckInPatient = AutoCheckInPatient(queueRepository);
  final getUpcomingAppointments = GetUpcomingAppointmentsUseCase(appointmentRepository);
  final getActivePrescriptions = GetActivePrescriptionsUseCase(prescriptionRepository);
  final getNearbyClinics = GetNearbyClinicsUseCase(clinicRepository);
  final getMedicalHistory = GetMedicalHistory(medicalHistoryRepository);
  final requestCallback = RequestCallback(aiCallbackRepository);
  final cancelCallback = CancelCallback(aiCallbackRepository);
  final getCallbackStatus = GetCallbackStatus(aiCallbackRepository);
  final bookAppointment = BookAppointment(appointmentRepository);
  final updatePatientProfile = UpdatePatientProfile(patientRepository);

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: requestCallback),
        Provider.value(value: cancelCallback),
        Provider.value(value: getCallbackStatus),
        ChangeNotifierProvider(
          create: (_) => AiCallbackProvider(
            requestCallbackUseCase: requestCallback,
            cancelCallbackUseCase: cancelCallback,
            getCallbackStatusUseCase: getCallbackStatus,
          ),
        ),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(
          create: (_) => PatientHomeProvider(
            patientRepository: patientRepository,
            getUpcomingAppointmentsUseCase: getUpcomingAppointments,
            getQueueStatusUseCase: getQueueStatus,
            getActivePrescriptionsUseCase: getActivePrescriptions,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => AbhaProvider(
            repository: abhaRepository,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => AppointmentProvider(
            bookAppointmentUseCase: bookAppointment,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => QueueProvider(
            getQueueStatus: getQueueStatus,
            joinQueue: joinQueue,
            autoCheckInPatient: autoCheckInPatient,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => PrescriptionsProvider(
            getActivePrescriptionsUseCase: getActivePrescriptions,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => MedicalHistoryProvider(
            getMedicalHistory: getMedicalHistory,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => NearbyClinicsProvider(
            getNearbyClinicsUseCase: getNearbyClinics,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => PatientProfileProvider(
            patientRepository: patientRepository,
            updatePatientProfileUseCase: updatePatientProfile,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ReceptionQueueProvider(
            repository: receptionRepository,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => CheckInProvider(
            dataSource: receptionRemoteDatasource,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ReceptionStatsProvider(
            dataSource: receptionRemoteDatasource,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ClinicDetailsProvider(
            dataSource: receptionRemoteDatasource,
          ),
        ),
      ],
      child: const ArogyamApp(),
    ),
  );
}

class ArogyamApp extends StatelessWidget {
  const ArogyamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arogyam / HealthQ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      navigatorObservers: [AppRouter.routeObserver],
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isAuthenticated) {
            if (auth.user?.role.toLowerCase() == 'reception') {
              return const ReceptionMainScreen();
            }
            return const PatientMainScreen();
          }
          return const LoginPage();
        },
      ),
    );
  }
}
