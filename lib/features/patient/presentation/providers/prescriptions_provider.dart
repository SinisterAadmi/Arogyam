import 'package:flutter/foundation.dart';
import '../../../../shared/entities/prescription.dart';
import '../../domain/usecases/get_active_prescriptions_usecase.dart';

class PrescriptionsProvider extends ChangeNotifier {
  final GetActivePrescriptionsUseCase _getActivePrescriptionsUseCase;

  List<Prescription> _prescriptions = [];
  bool _isLoading = false;
  String? _errorMessage;

  PrescriptionsProvider({GetActivePrescriptionsUseCase? getActivePrescriptionsUseCase})
      : _getActivePrescriptionsUseCase = getActivePrescriptionsUseCase ?? GetActivePrescriptionsUseCase() {
    fetchPrescriptions();
  }

  List<Prescription> get prescriptions => _prescriptions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchPrescriptions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _prescriptions = await _getActivePrescriptionsUseCase();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
