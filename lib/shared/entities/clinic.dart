class DoctorInfo {
  final String id;
  final String name;
  final String specialty;

  const DoctorInfo({
    required this.id,
    required this.name,
    required this.specialty,
  });

  factory DoctorInfo.fromJson(Map<String, dynamic> json) {
    return DoctorInfo(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      specialty: json['specialty']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'specialty': specialty,
    };
  }
}

class Clinic {
  final String id;
  final String name;
  final String address;
  final String? phone;
  final String? specialty;
  final String? operatingHours;
  final String? description;
  final double latitude;
  final double longitude;
  final double distanceKm;
  final int waitTimeMinutes;
  final bool isLiveQueueActive;
  final double rating;
  final int reviewCount;
  final List<DoctorInfo> doctors;

  const Clinic({
    required this.id,
    required this.name,
    required this.address,
    this.phone,
    this.specialty,
    this.operatingHours,
    this.description,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
    required this.waitTimeMinutes,
    required this.isLiveQueueActive,
    required this.rating,
    required this.reviewCount,
    this.doctors = const [],
  });
}
