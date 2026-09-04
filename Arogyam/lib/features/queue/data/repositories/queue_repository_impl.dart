import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../domain/repositories/queue_repository.dart';
import '../datasources/queue_remote_datasource.dart';
import '../../../patient/data/models/queue_status_model.dart';

class QueueRepositoryImpl implements QueueRepository {
  final QueueRemoteDatasource _remoteDatasource;

  QueueRepositoryImpl(this._remoteDatasource);

  @override
  Future<QueueStatusModel> getQueueStatus() async {
    try {
      return await _remoteDatasource.getQueueStatus();
    } on DioException catch (e, stackTrace) {
      debugPrint('[Queue] error: $e\n$stackTrace');
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        rethrow;
      }
      return QueueStatusModel(
        clinicName: 'Apollo Health City (Mock)',
        tokenNumber: '15',
        peopleAhead: 4,
        currentlyServing: '11',
        estimatedWaitTime: '25 mins',
        status: 'In Queue',
      );
    } catch (e, stackTrace) {
      debugPrint('[Queue] error: $e\n$stackTrace');
      rethrow;
    }
  }

  @override
  Future<QueueStatusModel> joinQueue(String clinicId) async {
    return await _remoteDatasource.joinQueue(clinicId);
  }

  @override
  Future<QueueStatusModel> autoCheckIn(String clinicId) async {
    return await _remoteDatasource.autoCheckIn(clinicId);
  }
}
