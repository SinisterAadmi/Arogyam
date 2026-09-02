import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../domain/repositories/ai_callback_repository.dart';
import '../datasources/ai_callback_remote_datasource.dart';

class AiCallbackRepositoryImpl implements AiCallbackRepository {
  final AiCallbackRemoteDatasource _remoteDatasource;

  AiCallbackRepositoryImpl(this._remoteDatasource);

  @override
  Future<Map<String, dynamic>> requestCallback(String clinicId, String phone, String scheduledAt) async {
    try {
      return await _remoteDatasource.requestCallback(clinicId, phone, scheduledAt);
    } on DioException catch (e, stackTrace) {
      debugPrint('[AICallback] error: $e\n$stackTrace');
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        rethrow;
      }
      return {'message': 'AI Callback requested (mock)', 'requestId': 'cb_local_123'};
    } catch (e, stackTrace) {
      debugPrint('[AICallback] error: $e\n$stackTrace');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getCallbackStatus() async {
    try {
      return await _remoteDatasource.getCallbackStatus();
    } on DioException catch (e, stackTrace) {
      debugPrint('[AICallback] error: $e\n$stackTrace');
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        rethrow;
      }
      return {'status': 'pending (mock)', 'requestedAt': DateTime.now().toIso8601String()};
    } catch (e, stackTrace) {
      debugPrint('[AICallback] error: $e\n$stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> cancelCallback() async {
    try {
      await _remoteDatasource.cancelCallback();
    } on DioException catch (e, stackTrace) {
      debugPrint('[AICallback] error: $e\n$stackTrace');
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        rethrow;
      }
    } catch (e, stackTrace) {
      debugPrint('[AICallback] error: $e\n$stackTrace');
      rethrow;
    }
  }
}
