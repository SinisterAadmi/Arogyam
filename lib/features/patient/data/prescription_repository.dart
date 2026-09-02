import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../shared/entities/prescription.dart';
import '../../../shared/enums/prescription_status.dart';
import '../domain/repositories/prescription_repository.dart';
import 'datasources/prescription_remote_datasource.dart';

class PrescriptionRepositoryImpl implements PrescriptionRepository {
  final PrescriptionRemoteDatasource _datasource;

  PrescriptionRepositoryImpl(this._datasource);

  @override
  Future<List<Prescription>> getActivePrescriptions() async {
    try {
      return await _datasource.getActivePrescriptions();
    } on DioException catch (e, stackTrace) {
      debugPrint('[Patient] error: $e\n$stackTrace');
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        rethrow;
      }
      return [
        Prescription(
          id: '1',
          medicineName: 'Amoxicillin 500mg (Mock)',
          dosageInstructions: '1 tablet twice a day after meals',
          prescribedBy: 'Dr. Ananya Sharma',
          clinicName: 'Apollo Health City',
          expiryDate: DateTime.now().add(const Duration(days: 5)),
          status: PrescriptionStatus.active,
        ),
      ];
    } catch (e, stackTrace) {
      debugPrint('[Patient] error: $e\n$stackTrace');
      rethrow;
    }
  }
}
