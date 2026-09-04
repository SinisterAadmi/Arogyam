import '../enums/prescription_status.dart';

class Prescription {
  final String id;
  final String medicineName;
  final String dosageInstructions;
  final String prescribedBy;
  final String clinicName;
  final DateTime expiryDate;
  final PrescriptionStatus status;

  const Prescription({
    required this.id,
    required this.medicineName,
    required this.dosageInstructions,
    required this.prescribedBy,
    required this.clinicName,
    required this.expiryDate,
    required this.status,
  });
}
