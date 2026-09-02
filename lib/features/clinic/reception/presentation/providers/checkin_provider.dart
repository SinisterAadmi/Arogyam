import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../data/datasources/reception_remote_datasource.dart';
import '../../data/models/reception_queue_models.dart';

class CheckInProvider extends ChangeNotifier {
  final ReceptionRemoteDataSource _dataSource;

  bool _isVerifying = false;
  String? _errorMessage;
  ConsentVerificationResult? _verifiedResult;

  // AI Callbacks
  List<AiCallbackItem> _aiCallbacks = [];
  bool _isLoadingCallbacks = false;
  bool _isRefreshingCallbacks = false;

  bool get isVerifying => _isVerifying;
  String? get errorMessage => _errorMessage;
  ConsentVerificationResult? get verifiedResult => _verifiedResult;
  List<AiCallbackItem> get aiCallbacks => _aiCallbacks;
  bool get isLoadingCallbacks => _isLoadingCallbacks;
  bool get isRefreshingCallbacks => _isRefreshingCallbacks;

  CheckInProvider({ReceptionRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? ReceptionRemoteDataSource();

  void resetVerification() {
    _verifiedResult = null;
    _errorMessage = null;
    _isVerifying = false;
    notifyListeners();
  }

  Future<bool> verifyShortCode(String code) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.length != 6) {
      _errorMessage = 'Please enter a valid 6-character code';
      notifyListeners();
      return false;
    }

    _isVerifying = true;
    _errorMessage = null;
    _verifiedResult = null;
    notifyListeners();

    try {
      final result = await _dataSource.verifyShortCode(cleanCode);
      _verifiedResult = result;
      _errorMessage = null;
      return true;
    } catch (e, stackTrace) {
      debugPrint('[CheckInProvider] verifyShortCode error: $e\n$stackTrace');
      if (e is DioException) {
        if (e.response?.data != null && e.response?.data is Map && e.response?.data['message'] != null) {
          _errorMessage = e.response!.data['message'].toString();
        } else if (e.response?.statusCode == 404) {
          _errorMessage = 'Invalid short code. Session not found.';
        } else if (e.response?.statusCode == 400) {
          _errorMessage = 'Session is expired or has already been used.';
        } else {
          _errorMessage = 'Failed to verify consent code. Please try again.';
        }
      } else {
        _errorMessage = e.toString();
      }
      return false;
    } finally {
      _isVerifying = false;
      notifyListeners();
    }
  }

  Future<bool> verifyQrData(String qrRawData) async {
    final trimmed = qrRawData.trim();
    if (trimmed.isEmpty) {
      _errorMessage = 'Invalid QR code';
      notifyListeners();
      return false;
    }

    // Extract qrToken or shortCode if format is JSON or URL
    String token = trimmed;
    if (trimmed.contains('code=')) {
      final uri = Uri.tryParse(trimmed);
      token = uri?.queryParameters['code'] ?? trimmed;
    } else if (trimmed.contains('token=')) {
      final uri = Uri.tryParse(trimmed);
      token = uri?.queryParameters['token'] ?? trimmed;
    }

    _isVerifying = true;
    _errorMessage = null;
    _verifiedResult = null;
    notifyListeners();

    try {
      // If 6 characters, try short code verification first
      if (token.length == 6 && RegExp(r'^[A-Za-z0-9]{6}$').hasMatch(token)) {
        final result = await _dataSource.verifyShortCode(token);
        _verifiedResult = result;
      } else {
        final result = await _dataSource.verifyQrToken(token);
        _verifiedResult = result;
      }
      _errorMessage = null;
      return true;
    } catch (e, stackTrace) {
      debugPrint('[CheckInProvider] verifyQrData error: $e\n$stackTrace');
      if (e is DioException) {
        if (e.response?.data != null && e.response?.data is Map && e.response?.data['message'] != null) {
          _errorMessage = e.response!.data['message'].toString();
        } else {
          _errorMessage = 'QR verification failed or session expired.';
        }
      } else {
        _errorMessage = e.toString();
      }
      return false;
    } finally {
      _isVerifying = false;
      notifyListeners();
    }
  }

  Future<void> fetchAiCallbacks({bool isSilent = false}) async {
    if (_aiCallbacks.isEmpty && !isSilent) {
      _isLoadingCallbacks = true;
      notifyListeners();
    } else {
      _isRefreshingCallbacks = true;
      notifyListeners();
    }

    try {
      _aiCallbacks = await _dataSource.getAiCallbacks();
    } catch (e, stackTrace) {
      debugPrint('[CheckInProvider] fetchAiCallbacks error: $e\n$stackTrace');
    } finally {
      _isLoadingCallbacks = false;
      _isRefreshingCallbacks = false;
      notifyListeners();
    }
  }

  Future<bool> resolveCallback(String callbackId) async {
    try {
      await _dataSource.resolveAiCallback(callbackId);
      _aiCallbacks = _aiCallbacks.map((cb) {
        if (cb.id == callbackId) {
          return AiCallbackItem(
            id: cb.id,
            patientId: cb.patientId,
            patientName: cb.patientName,
            phone: cb.phone,
            status: 'resolved',
            requestedSlot: cb.requestedSlot,
            createdAt: cb.createdAt,
          );
        }
        return cb;
      }).where((cb) => cb.status == 'pending').toList();
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      debugPrint('[CheckInProvider] resolveCallback error: $e\n$stackTrace');
      return false;
    }
  }
}
