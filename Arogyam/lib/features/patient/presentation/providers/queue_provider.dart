import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../data/models/queue_status_model.dart';
import '../../../queue/domain/usecases/get_queue_status.dart';
import '../../../queue/domain/usecases/join_queue.dart';
import '../../../queue/domain/usecases/auto_check_in_patient.dart';

enum CheckInStatus { none, nearby, checkedIn }

class QueueProvider extends ChangeNotifier {
  final GetQueueStatus _getQueueStatus;
  final JoinQueue _joinQueue;
  final AutoCheckInPatient _autoCheckInPatient;

  QueueStatusModel? _status;
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _errorMessage;
  CheckInStatus _checkInStatus = CheckInStatus.none;

  QueueStatusModel? get status => _status;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get errorMessage => _errorMessage;
  CheckInStatus get checkInStatus => _checkInStatus;

  QueueProvider({
    required this._getQueueStatus,
    required this._joinQueue,
    required this._autoCheckInPatient,
  });

  bool _isFetching = false;

  Future<void> fetchStatus({bool isSilent = false}) async {
    if (_isFetching) return;
    _isFetching = true;

    if (_status == null && !isSilent) {
      _isLoading = true;
      notifyListeners();
    } else {
      _isRefreshing = true;
      notifyListeners();
    }

    try {
      _status = await _getQueueStatus();
    } catch (e, stackTrace) {
      debugPrint('[Patient] error: $e\n$stackTrace');
      _status ??= QueueStatusModel.notInQueue();
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      _isFetching = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => fetchStatus(isSilent: true);

  Future<void> updateArrivedNearby() async {
    if (_checkInStatus == CheckInStatus.none) {
      _checkInStatus = CheckInStatus.nearby;
      notifyListeners();
    }
  }

  Future<bool> joinQueue(String clinicId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _status = await _joinQueue(clinicId);
      _checkInStatus = CheckInStatus.checkedIn;
      return true;
    } catch (e, stackTrace) {
      debugPrint('[Patient] error: $e\n$stackTrace');
      if (e is DioException) {
        if (e.response?.data != null && e.response?.data is Map && e.response?.data['message'] != null) {
          _errorMessage = e.response!.data['message'].toString();
        } else {
          _errorMessage = 'Unable to connect to server. Please try again.';
        }
      } else {
        _errorMessage = e.toString();
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> checkInViaQR(String qrData) async {
    _isLoading = true;
    notifyListeners();

    try {
      // In a real app, qrData would contain clinicId
      final clinicId = qrData; 
      _status = await _joinQueue(clinicId);
      _checkInStatus = CheckInStatus.checkedIn;
      return true;
    } catch (e, stackTrace) {
      debugPrint('[Patient] error: $e\n$stackTrace');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> autoCheckIn(String clinicId) async {
    try {
      _status = await _autoCheckInPatient(clinicId);
      _checkInStatus = CheckInStatus.checkedIn;
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('[Patient] error: $e\n$stackTrace');
      // Fallback
    }
  }
}
