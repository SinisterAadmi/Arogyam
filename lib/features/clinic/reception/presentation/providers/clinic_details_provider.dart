import 'package:flutter/material.dart';
import '../../data/datasources/reception_remote_datasource.dart';
import '../../data/models/reception_queue_models.dart';

class ClinicDetailsProvider extends ChangeNotifier {
  final ReceptionRemoteDataSource _dataSource;

  ReceptionClinicModel? _clinic;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;

  ReceptionClinicModel? get clinic => _clinic;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  ClinicDetailsProvider({ReceptionRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? ReceptionRemoteDataSource();

  Future<void> fetchClinicDetails() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _clinic = await _dataSource.getClinic();
    } catch (e, stackTrace) {
      debugPrint('[ClinicDetailsProvider] fetchClinicDetails error: $e\n$stackTrace');
      _errorMessage = 'Failed to load clinic details';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveClinicDetails({
    String? name,
    String? address,
    String? phone,
    String? specialty,
    String? operatingHours,
    String? description,
    double? latitude,
    double? longitude,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      _clinic = await _dataSource.updateClinic(
        name: name,
        address: address,
        phone: phone,
        specialty: specialty,
        operatingHours: operatingHours,
        description: description,
        latitude: latitude,
        longitude: longitude,
      );
      _successMessage = 'Clinic details updated successfully';
      return true;
    } catch (e, stackTrace) {
      debugPrint('[ClinicDetailsProvider] saveClinicDetails error: $e\n$stackTrace');
      _errorMessage = 'Failed to update clinic details. Please try again.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
