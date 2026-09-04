import 'package:flutter/material.dart';
import '../../data/models/patient_model.dart';
import '../../data/models/appointment_model.dart';
import '../../data/models/queue_status_model.dart';
import '../../domain/usecases/get_upcoming_appointments.dart';
import '../../domain/usecases/get_active_prescriptions_usecase.dart';
import '../../../queue/domain/usecases/get_queue_status.dart';
import '../../domain/repositories/patient_repository.dart';
import '../../../../shared/entities/prescription.dart';

class PatientHomeProvider extends ChangeNotifier {
  final PatientRepository _patientRepository;
  final GetUpcomingAppointmentsUseCase _getUpcomingAppointmentsUseCase;
  final GetQueueStatus _getQueueStatusUseCase;
  final GetActivePrescriptionsUseCase _getActivePrescriptionsUseCase;

  PatientModel? _patient;
  AppointmentModel? _upcomingAppointment;
  QueueStatusModel? _queueStatus;
  int _activePrescriptionsCount = 0;
  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _isFetching = false;
  String? _errorMessage;
  DateTime? _lastPatientFetchTime;

  PatientHomeProvider({
    required this._patientRepository,
    required this._getUpcomingAppointmentsUseCase,
    required this._getQueueStatusUseCase,
    required this._getActivePrescriptionsUseCase,
  });

  PatientModel? get patient => _patient;
  AppointmentModel? get upcomingAppointment => _upcomingAppointment;
  QueueStatusModel? get queueStatus => _queueStatus;
  int get activePrescriptionsCount => _activePrescriptionsCount;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get errorMessage => _errorMessage;

  Future<void> loadDashboardData({bool isRefresh = false, bool forceProfile = false}) async {
    if (_isFetching) return;
    _isFetching = true;

    if (_patient == null) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    } else {
      _isRefreshing = true;
      notifyListeners();
    }

    try {
      // Guard against /patients/me over-fetching:
      // Only fetch profile if not yet loaded, explicitly forced, or expired (> 10 mins).
      final shouldFetchProfile = _patient == null ||
          forceProfile ||
          (_lastPatientFetchTime == null ||
              DateTime.now().difference(_lastPatientFetchTime!).inMinutes >= 10);

      if (shouldFetchProfile) {
        try {
          final patientEntity = await _patientRepository.getPatientMe();
          if (patientEntity != null) {
            _patient = PatientModel(
              id: patientEntity.id,
              name: patientEntity.name,
              abhaId: patientEntity.abhaId,
              isAbhaLinked: patientEntity.isAbhaLinked,
              imageUrl: patientEntity.imageUrl,
              dob: patientEntity.dob,
              gender: patientEntity.gender,
              bloodGroup: patientEntity.bloodGroup,
              address: patientEntity.address,
              phoneNumber: patientEntity.phoneNumber,
              email: patientEntity.email,
              emergencyContactName: patientEntity.emergencyContactName,
              emergencyContactPhone: patientEntity.emergencyContactPhone,
            );
            _lastPatientFetchTime = DateTime.now();
          }
        } catch (e, stackTrace) {
          debugPrint('[Patient] error fetching patient profile: $e\n$stackTrace');
        }
      }

      // Concurrently fetch dynamic home data (appointments, queue status, active prescriptions)
      final results = await Future.wait([
        _getUpcomingAppointmentsUseCase().catchError((e, stackTrace) {
          debugPrint('[Patient] error fetching upcoming appointments: $e');
          return <AppointmentModel>[];
        }),
        _getQueueStatusUseCase().catchError((e, stackTrace) {
          debugPrint('[Patient] error fetching queue status: $e');
          return QueueStatusModel.notInQueue();
        }),
        _getActivePrescriptionsUseCase().catchError((e, stackTrace) {
          debugPrint('[Patient] error fetching active prescriptions: $e');
          return <Prescription>[];
        }),
      ]);

      final appointments = results[0] as List<AppointmentModel>;
      final activeAppointments = appointments.where((a) {
        final st = a.status.toLowerCase();
        return st != 'cancelled' && st != 'completed' && st != 'no_show';
      }).toList();
      _upcomingAppointment = activeAppointments.isNotEmpty ? activeAppointments.first : null;

      _queueStatus = results[1] as QueueStatusModel;

      final prescriptions = results[2] as List;
      _activePrescriptionsCount = prescriptions.length;

      _errorMessage = null;
    } catch (e, stackTrace) {
      debugPrint('[Patient] error: $e\n$stackTrace');
      if (_patient == null) {
        _errorMessage = 'Failed to load dashboard data. Please try again.';
      }
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      _isFetching = false;
      notifyListeners();
    }
  }

  void setPatient(PatientModel patient) {
    _patient = patient;
    notifyListeners();
  }

  /// Refreshes dynamic dashboard data while preserving existing content.
  Future<void> refresh({bool forceProfile = false}) =>
      loadDashboardData(isRefresh: true, forceProfile: forceProfile);
}
