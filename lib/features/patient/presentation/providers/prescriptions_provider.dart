import 'package:flutter/foundation.dart';
import '../../../../shared/entities/prescription.dart';
import '../../domain/usecases/get_active_prescriptions_usecase.dart';

class PrescriptionsProvider extends ChangeNotifier {
  final GetActivePrescriptionsUseCase _getActivePrescriptionsUseCase;

  List<Prescription> _prescriptions = [];
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _errorMessage;

  PrescriptionsProvider({required this._getActivePrescriptionsUseCase}) {
    fetchPrescriptions();
  }

  List<Prescription> get prescriptions => _prescriptions;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get errorMessage => _errorMessage;

  bool _isFetching = false;

  Future<void> fetchPrescriptions({bool isRefresh = false}) async {
    if (_isFetching) return;
    _isFetching = true;

    if (_prescriptions.isEmpty) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    } else {
      _isRefreshing = true;
      notifyListeners();
    }

    try {
      _prescriptions = await _getActivePrescriptionsUseCase();
      _errorMessage = null;
    } catch (e, stackTrace) {
      debugPrint('[Patient] error: $e\n$stackTrace');
      if (_prescriptions.isEmpty) {
        _errorMessage = e.toString();
      }
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      _isFetching = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => fetchPrescriptions(isRefresh: true);
}
