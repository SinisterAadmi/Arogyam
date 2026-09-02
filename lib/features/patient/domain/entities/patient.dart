class Patient {
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

  const Patient({
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
}
