class AppointmentModel {
  final String id;
  final String doctorName;
  final String specialty;
  final String clinicName;
  final String appointmentTime;
  final String tokenNumber;
  final String status;

  AppointmentModel({
    required this.id,
    required this.doctorName,
    required this.specialty,
    required this.clinicName,
    required this.appointmentTime,
    required this.tokenNumber,
    required this.status,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id']?.toString() ?? '',
      doctorName: json['doctorName']?.toString() ?? '',
      specialty: json['specialty']?.toString() ?? '',
      clinicName: json['clinicName']?.toString() ?? '',
      appointmentTime: json['appointmentTime']?.toString() ?? '',
      tokenNumber: json['tokenNumber']?.toString() ?? '',
      status: json['status']?.toString() ?? 'scheduled',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'doctorName': doctorName,
      'specialty': specialty,
      'clinicName': clinicName,
      'appointmentTime': appointmentTime,
      'tokenNumber': tokenNumber,
      'status': status,
    };
  }
}
