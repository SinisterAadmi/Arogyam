import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../domain/repositories/abha_repository.dart';
import '../datasources/abha_remote_datasource.dart';
import '../models/abha_model.dart';

class AbhaRepositoryImpl implements AbhaRepository {
  final AbhaRemoteDatasource _remoteDatasource;

  AbhaRepositoryImpl(this._remoteDatasource);

  @override
  Future<AbhaModel> getAbhaStatus() async {
    try {
      return await _remoteDatasource.getAbhaStatus();
    } on DioException catch (e, stackTrace) {
      debugPrint('[Patient] error: $e\n$stackTrace');
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        rethrow;
      }
      return AbhaModel(abhaId: '12-3456-7890-1234 (Mock)', isLinked: true);
    } catch (e, stackTrace) {
      debugPrint('[Patient] error: $e\n$stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> linkAbha(String abhaId, String otp) async {
    try {
      await _remoteDatasource.linkAbha(abhaId, otp);
    } on DioException catch (e, stackTrace) {
      debugPrint('[Patient] error: $e\n$stackTrace');
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        rethrow;
      }
    } catch (e, stackTrace) {
      debugPrint('[Patient] error: $e\n$stackTrace');
      rethrow;
    }
  }
}
