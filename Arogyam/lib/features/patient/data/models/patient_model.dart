class PatientModel {
  final String id;
  final String name;
  final String? abhaId;
  final String? imageUrl;
  final bool isAbhaLinked;
  final DateTime? dob;
  final String? gender;
  final String? bloodGroup;
  final String? address;
  final String? phoneNumber;
  final String? email;
  final String? emergencyContactName;
  final String? emergencyContactPhone;

  PatientModel({
    required this.id,
    required this.name,
    this.abhaId,
    this.imageUrl,
    this.isAbhaLinked = false,
    this.dob,
    this.gender,
    this.bloodGroup,
    this.address,
    this.phoneNumber,
    this.email,
    this.emergencyContactName,
    this.emergencyContactPhone,
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDob;
    if (json['dob'] != null) {
      parsedDob = DateTime.tryParse(json['dob'].toString());
    }

    return PatientModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Patient',
      abhaId: json['abhaId']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      isAbhaLinked: json['isAbhaLinked'] == true,
      dob: parsedDob,
      gender: json['gender']?.toString(),
      bloodGroup: json['bloodGroup']?.toString(),
      address: json['address']?.toString(),
      phoneNumber: json['phoneNumber']?.toString(),
      email: json['email']?.toString(),
      emergencyContactName: json['emergencyContactName']?.toString(),
      emergencyContactPhone: json['emergencyContactPhone']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'abhaId': abhaId,
      'imageUrl': imageUrl,
      'isAbhaLinked': isAbhaLinked,
      'dob': dob?.toIso8601String(),
      'gender': gender,
      'bloodGroup': bloodGroup,
      'address': address,
      'phoneNumber': phoneNumber,
      'email': email,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
    };
  }

  PatientModel copyWith({
    String? id,
    String? name,
    String? abhaId,
    String? imageUrl,
    bool? isAbhaLinked,
    DateTime? dob,
    String? gender,
    String? bloodGroup,
    String? address,
    String? phoneNumber,
    String? email,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) {
    return PatientModel(
      id: id ?? this.id,
      name: name ?? this.name,
      abhaId: abhaId ?? this.abhaId,
      imageUrl: imageUrl ?? this.imageUrl,
      isAbhaLinked: isAbhaLinked ?? this.isAbhaLinked,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
    );
  }
}
