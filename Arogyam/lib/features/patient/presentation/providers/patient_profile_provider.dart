import 'package:flutter/material.dart';
import '../../../../core/security/biometric_service.dart';
import '../../data/models/patient_model.dart';
import '../../domain/repositories/patient_repository.dart';
import '../../domain/usecases/update_patient_profile.dart';

class PatientProfileProvider extends ChangeNotifier {
  final PatientRepository _patientRepository;
  final UpdatePatientProfile _updatePatientProfileUseCase;

  PatientModel? _patient;
  bool _isLoading = false;
  bool _isBiometricEnabled = false;
  List<Map<String, dynamic>> _accessHistory = [];
  bool _isLoadingHistory = false;

  PatientProfileProvider({
    required PatientRepository patientRepository,
    UpdatePatientProfile? updatePatientProfileUseCase,
  })  : _patientRepository = patientRepository,
        _updatePatientProfileUseCase = updatePatientProfileUseCase ?? UpdatePatientProfile(patientRepository);

  PatientModel? get patient => _patient;
  bool get isLoading => _isLoading;
  bool get isBiometricEnabled => _isBiometricEnabled;
  List<Map<String, dynamic>> get accessHistory => _accessHistory;
  bool get isLoadingHistory => _isLoadingHistory;

  void setPatient(PatientModel patient) {
    _patient = patient;
    notifyListeners();
  }

  Future<void> loadProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      final patientEntity = await _patientRepository.getPatientMe();
      if (patientEntity != null) {
        _patient = PatientModel(
          id: patientEntity.id,
          name: patientEntity.name,
          abhaId: patientEntity.abhaId,
          imageUrl: patientEntity.imageUrl,
          isAbhaLinked: patientEntity.isAbhaLinked,
          dob: patientEntity.dob,
          gender: patientEntity.gender,
          bloodGroup: patientEntity.bloodGroup,
          address: patientEntity.address,
          phoneNumber: patientEntity.phoneNumber,
          email: patientEntity.email,
          emergencyContactName: patientEntity.emergencyContactName,
          emergencyContactPhone: patientEntity.emergencyContactPhone,
        );
      }
    } catch (e, stackTrace) {
      debugPrint('[PatientProfileProvider] loadProfile error: $e\n$stackTrace');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(PatientModel updatedPatient) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _updatePatientProfileUseCase.execute(updatedPatient);
      _patient = updatedPatient;
    } catch (e, stackTrace) {
      debugPrint('[PatientProfileProvider] updateProfile error: $e\n$stackTrace');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAccessHistory() async {
    _isLoadingHistory = true;
    notifyListeners();

    try {
      _accessHistory = await _patientRepository.getAccessHistory();
    } catch (e) {
      debugPrint('[PatientProfileProvider] fetchAccessHistory error: $e');
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  Future<void> toggleBiometrics(bool value) async {
    if (value) {
      final success = await BiometricService().authenticate(
        localizedReason: 'Authenticate to enable biometric app lock',
      );
      if (success) {
        _isBiometricEnabled = true;
        BiometricService().setAppLockEnabled(true);
      }
    } else {
      _isBiometricEnabled = false;
      BiometricService().setAppLockEnabled(false);
    }
    notifyListeners();
  }
}
