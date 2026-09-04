import '../../../../core/network/api_client.dart';
import '../../../../shared/entities/prescription.dart';
import '../../../../shared/enums/prescription_status.dart';

abstract class PrescriptionRemoteDatasource {
  Future<List<Prescription>> getActivePrescriptions();
}

class PrescriptionRemoteDatasourceImpl implements PrescriptionRemoteDatasource {
  final ApiClient _client;

  PrescriptionRemoteDatasourceImpl(this._client);

  @override
  Future<List<Prescription>> getActivePrescriptions() async {
    final response = await _client.get('/patients/prescriptions/active');
    return (response.data as List).map((json) => Prescription(
      id: json['id'],
      medicineName: json['medicineName'],
      dosageInstructions: json['dosageInstructions'],
      prescribedBy: json['prescribedBy'],
      clinicName: json['clinicName'],
      expiryDate: DateTime.parse(json['expiryDate']),
      status: PrescriptionStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => PrescriptionStatus.active,
      ),
    )).toList();
  }
}
