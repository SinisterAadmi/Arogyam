import 'package:flutter/material.dart';
import '../../domain/usecases/get_medical_history.dart';

class MedicalRecord {
  final String id;
  final String title;
  final String category;
  final String date;
  final String doctorName;
  final String facilityName;

  MedicalRecord({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    required this.doctorName,
    required this.facilityName,
  });
}

class MedicalHistoryProvider extends ChangeNotifier {
  final GetMedicalHistory _getMedicalHistory;
  List<MedicalRecord> _records = [];
  bool _isLoading = false;
  bool _isRefreshing = false;

  List<MedicalRecord> get records => _records;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;

  MedicalHistoryProvider({required this._getMedicalHistory}) {
    fetchHistory();
  }

  bool _isFetching = false;

  Future<void> fetchHistory({bool isRefresh = false}) async {
    if (_isFetching) return;
    _isFetching = true;

    if (_records.isEmpty) {
      _isLoading = true;
      notifyListeners();
    } else {
      _isRefreshing = true;
      notifyListeners();
    }

    try {
      _records = await _getMedicalHistory();
    } catch (e, stackTrace) {
      debugPrint('[Patient] error: $e\n$stackTrace');
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      _isFetching = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => fetchHistory(isRefresh: true);
}
