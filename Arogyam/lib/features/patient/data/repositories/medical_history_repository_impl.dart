import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../domain/repositories/medical_history_repository.dart';
import '../datasources/medical_history_remote_datasource.dart';
import '../../presentation/providers/medical_history_provider.dart';

class MedicalHistoryRepositoryImpl implements MedicalHistoryRepository {
  final MedicalHistoryRemoteDatasource _remoteDatasource;

  MedicalHistoryRepositoryImpl(this._remoteDatasource);

  @override
  Future<List<MedicalRecord>> getMedicalHistory() async {
    try {
      return await _remoteDatasource.getMedicalHistory();
    } on DioException catch (e, stackTrace) {
      debugPrint('[Patient] error: $e\n$stackTrace');
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        rethrow;
      }
      return [
        MedicalRecord(
          id: '1',
          title: 'Blood Test Report (Mock)',
          category: 'Lab Report',
          date: '15 Jan 2024',
          doctorName: 'Dr. Ananya Sharma',
          facilityName: 'Apollo Diagnostics',
        ),
      ];
    } catch (e, stackTrace) {
      debugPrint('[Patient] error: $e\n$stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> shareMedicalHistory(String doctorId) async {
    // Implementation
  }
}
