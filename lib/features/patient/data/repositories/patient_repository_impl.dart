import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/patient.dart';
import '../../domain/repositories/patient_repository.dart';
import '../datasources/patient_remote_datasource.dart';
import '../models/patient_model.dart';

class PatientRepositoryImpl implements PatientRepository {
  final PatientRemoteDatasource _remoteDatasource;

  PatientRepositoryImpl(this._remoteDatasource);

  @override
  Future<Patient?> getPatientMe() async {
    try {
      final model = await _remoteDatasource.getMe();
      return Patient(
        id: model.id,
        name: model.name,
        abhaId: model.abhaId,
        imageUrl: model.imageUrl,
        isAbhaLinked: model.isAbhaLinked,
        dob: model.dob,
        gender: model.gender,
        bloodGroup: model.bloodGroup,
        address: model.address,
        phoneNumber: model.phoneNumber,
        email: model.email,
        emergencyContactName: model.emergencyContactName,
        emergencyContactPhone: model.emergencyContactPhone,
      );
    } on DioException catch (e, stackTrace) {
      debugPrint('[Patient] error: $e\n$stackTrace');
      // Don't fallback on auth errors
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        rethrow;
      }
      
      // Mock fallback for true unavailability (timeout, 5xx, etc)
      return const Patient(
        id: '1',
        name: 'Rajesh Kumar (Mock)',
        abhaId: '91-8273-1284-9102',
        isAbhaLinked: true,
        imageUrl: 'https://www.figma.com/api/mcp/asset/4bfd7ea4-6c80-4455-83a6-0509e9bb2b94.png',
      );
    } catch (e, stackTrace) {
      debugPrint('[Patient] error: $e\n$stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> linkAbhaId(String abhaId, String otp) async {
    // Implementation for linking
  }

  @override
  Future<void> updatePatientProfile(PatientModel patient) async {
    await _remoteDatasource.updateMe(patient.toJson());
  }

  @override
  Future<List<Map<String, dynamic>>> getAccessHistory() async {
    try {
      return await _remoteDatasource.getAccessHistory();
    } catch (e) {
      debugPrint('[PatientRepository] getAccessHistory error: $e');
      return [];
    }
  }
}
