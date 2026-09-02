import 'package:flutter/material.dart';
import '../../data/datasources/reception_remote_datasource.dart';
import '../../data/models/reception_queue_models.dart';

class ReceptionStatsProvider extends ChangeNotifier {
  final ReceptionRemoteDataSource _dataSource;

  ClinicAnalytics? _analytics;
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _errorMessage;

  ClinicAnalytics? get analytics => _analytics;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get errorMessage => _errorMessage;

  ReceptionStatsProvider({ReceptionRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? ReceptionRemoteDataSource();

  Future<void> fetchAnalytics({bool isSilent = false}) async {
    if (_analytics == null && !isSilent) {
      _isLoading = true;
      notifyListeners();
    } else {
      _isRefreshing = true;
      notifyListeners();
    }

    try {
      _analytics = await _dataSource.getAnalytics();
      _errorMessage = null;
    } catch (e, stackTrace) {
      debugPrint('[ReceptionStatsProvider] fetchAnalytics error: $e\n$stackTrace');
      _errorMessage = 'Failed to load analytics data';
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => fetchAnalytics(isSilent: true);
}
