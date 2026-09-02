class UserModel {
  final String id;
  final String firebaseUid;
  final String? phoneNumber;
  final String? email;
  final String role;
  final PatientProfile? patient;
  final ReceptionProfile? reception;

  UserModel({
    required this.id,
    required this.firebaseUid,
    this.phoneNumber,
    this.email,
    required this.role,
    this.patient,
    this.reception,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      firebaseUid: json['firebaseUid'] ?? '',
      phoneNumber: json['phoneNumber'],
      email: json['email'],
      role: json['role'] ?? 'patient',
      patient: json['patient'] != null ? PatientProfile.fromJson(json['patient']) : null,
      reception: json['reception'] != null ? ReceptionProfile.fromJson(json['reception']) : null,
    );
  }
}

class ReceptionProfile {
  final String id;
  final String clinicId;
  final String name;
  final String? clinicName;

  ReceptionProfile({
    required this.id,
    required this.clinicId,
    required this.name,
    this.clinicName,
  });

  factory ReceptionProfile.fromJson(Map<String, dynamic> json) {
    return ReceptionProfile(
      id: json['id'] ?? '',
      clinicId: json['clinicId'] ?? '',
      name: json['name'] ?? 'Reception Staff',
      clinicName: json['clinic'] != null && json['clinic'] is Map ? json['clinic']['name'] : null,
    );
  }
}

class PatientProfile {
  final String id;
  final String name;
  final String? abhaId;
  final String? dob;
  final String? gender;

  PatientProfile({
    required this.id,
    required this.name,
    this.abhaId,
    this.dob,
    this.gender,
  });

  factory PatientProfile.fromJson(Map<String, dynamic> json) {
    return PatientProfile(
      id: json['id'],
      name: json['name'],
      abhaId: json['abhaId'],
      dob: json['dob'],
      gender: json['gender'],
    );
  }
}

class AuthResponse {
  final String status;
  final UserModel? user;
  final String? firebaseUid;
  final String? phoneNumber;

  AuthResponse({
    required this.status,
    this.user,
    this.firebaseUid,
    this.phoneNumber,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      status: json['status'],
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      firebaseUid: json['firebaseUid'],
      phoneNumber: json['phoneNumber'],
    );
  }
}
