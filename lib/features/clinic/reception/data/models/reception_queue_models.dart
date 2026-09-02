class ReceptionQueueToken {
  final String id;
  final int tokenNumber;
  final String status; // waiting, serving, done, absent
  final String patientId;
  final String patientName;
  final String? phoneNumber;
  final DateTime joinedAt;
  final DateTime updatedAt;

  ReceptionQueueToken({
    required this.id,
    required this.tokenNumber,
    required this.status,
    required this.patientId,
    required this.patientName,
    this.phoneNumber,
    required this.joinedAt,
    required this.updatedAt,
  });

  factory ReceptionQueueToken.fromJson(Map<String, dynamic> json) {
    return ReceptionQueueToken(
      id: json['id'] ?? '',
      tokenNumber: json['tokenNumber'] ?? 0,
      status: json['status'] ?? 'waiting',
      patientId: json['patientId'] ?? '',
      patientName: json['patientName'] ?? 'Unknown Patient',
      phoneNumber: json['phoneNumber'],
      joinedAt: json['joinedAt'] != null ? DateTime.parse(json['joinedAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
    );
  }
}

class ReceptionClinicStats {
  final int totalToday;
  final int waitingCount;
  final int? currentlyServing;

  ReceptionClinicStats({
    required this.totalToday,
    required this.waitingCount,
    this.currentlyServing,
  });

  factory ReceptionClinicStats.fromJson(Map<String, dynamic> json) {
    return ReceptionClinicStats(
      totalToday: json['totalToday'] ?? 0,
      waitingCount: json['waitingCount'] ?? 0,
      currentlyServing: json['currentlyServing'],
    );
  }
}

class ReceptionLiveQueueResponse {
  final String clinicId;
  final String clinicName;
  final bool isLiveQueueActive;
  final ReceptionClinicStats stats;
  final List<ReceptionQueueToken> tokens;

  ReceptionLiveQueueResponse({
    required this.clinicId,
    required this.clinicName,
    required this.isLiveQueueActive,
    required this.stats,
    required this.tokens,
  });

  factory ReceptionLiveQueueResponse.fromJson(Map<String, dynamic> json) {
    final clinic = json['clinic'] as Map<String, dynamic>? ?? {};
    final stats = json['stats'] as Map<String, dynamic>? ?? {};
    final tokensRaw = json['tokens'] as List<dynamic>? ?? [];

    return ReceptionLiveQueueResponse(
      clinicId: clinic['id'] ?? '',
      clinicName: clinic['name'] ?? 'Clinic',
      isLiveQueueActive: clinic['isLiveQueueActive'] ?? true,
      stats: ReceptionClinicStats.fromJson(stats),
      tokens: tokensRaw.map((t) => ReceptionQueueToken.fromJson(t as Map<String, dynamic>)).toList(),
    );
  }
}

class ConsentVerificationResult {
  final bool success;
  final String message;
  final String sessionId;
  final String patientId;
  final String patientName;
  final String? abhaId;
  final bool isAbhaLinked;
  final String? gender;
  final String? bloodGroup;
  final String usedMethod;
  final DateTime usedAt;

  ConsentVerificationResult({
    required this.success,
    required this.message,
    required this.sessionId,
    required this.patientId,
    required this.patientName,
    this.abhaId,
    this.isAbhaLinked = false,
    this.gender,
    this.bloodGroup,
    required this.usedMethod,
    required this.usedAt,
  });

  factory ConsentVerificationResult.fromJson(Map<String, dynamic> json) {
    final patient = json['patient'] as Map<String, dynamic>? ?? {};
    return ConsentVerificationResult(
      success: json['success'] ?? true,
      message: json['message'] ?? 'Consent verified successfully',
      sessionId: json['sessionId'] ?? '',
      patientId: json['patientId'] ?? patient['id'] ?? '',
      patientName: patient['name'] ?? json['patientName'] ?? 'Patient',
      abhaId: patient['abhaId'],
      isAbhaLinked: patient['isAbhaLinked'] ?? false,
      gender: patient['gender'],
      bloodGroup: patient['bloodGroup'],
      usedMethod: json['usedMethod'] ?? 'code',
      usedAt: json['usedAt'] != null ? DateTime.parse(json['usedAt']) : DateTime.now(),
    );
  }
}

class AiCallbackItem {
  final String id;
  final String patientId;
  final String patientName;
  final String phone;
  final String status;
  final DateTime requestedSlot;
  final DateTime createdAt;

  AiCallbackItem({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.phone,
    required this.status,
    required this.requestedSlot,
    required this.createdAt,
  });

  factory AiCallbackItem.fromJson(Map<String, dynamic> json) {
    return AiCallbackItem(
      id: json['id'] ?? '',
      patientId: json['patientId'] ?? '',
      patientName: json['patientName'] ?? 'Patient',
      phone: json['phone'] ?? '',
      status: json['status'] ?? 'pending',
      requestedSlot: json['requestedSlot'] != null ? DateTime.parse(json['requestedSlot']) : DateTime.now(),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }
}

class HourlyFlowItem {
  final String hour;
  final int count;

  HourlyFlowItem({required this.hour, required this.count});

  factory HourlyFlowItem.fromJson(Map<String, dynamic> json) {
    return HourlyFlowItem(
      hour: json['hour'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

class ClinicAnalytics {
  final String clinicId;
  final String clinicName;
  final int totalPatientsToday;
  final int patientsServedToday;
  final int currentlyWaiting;
  final int? currentlyServing;
  final int averageWaitTimeMinutes;
  final int totalAppointmentsToday;
  final List<HourlyFlowItem> hourlyFlow;

  ClinicAnalytics({
    required this.clinicId,
    required this.clinicName,
    required this.totalPatientsToday,
    required this.patientsServedToday,
    required this.currentlyWaiting,
    this.currentlyServing,
    required this.averageWaitTimeMinutes,
    required this.totalAppointmentsToday,
    required this.hourlyFlow,
  });

  factory ClinicAnalytics.fromJson(Map<String, dynamic> json) {
    final clinic = json['clinic'] as Map<String, dynamic>? ?? {};
    final stats = json['stats'] as Map<String, dynamic>? ?? {};
    final flowRaw = json['hourlyFlow'] as List<dynamic>? ?? [];

    return ClinicAnalytics(
      clinicId: clinic['id'] ?? '',
      clinicName: clinic['name'] ?? 'Sunrise Medical Center',
      totalPatientsToday: stats['totalPatientsToday'] ?? 0,
      patientsServedToday: stats['patientsServedToday'] ?? 0,
      currentlyWaiting: stats['currentlyWaiting'] ?? 0,
      currentlyServing: stats['currentlyServing'],
      averageWaitTimeMinutes: stats['averageWaitTimeMinutes'] ?? 0,
      totalAppointmentsToday: stats['totalAppointmentsToday'] ?? 0,
      hourlyFlow: flowRaw.map((f) => HourlyFlowItem.fromJson(f as Map<String, dynamic>)).toList(),
    );
  }
}

class ReceptionClinicModel {
  final String id;
  final String name;
  final String address;
  final String? phone;
  final String? specialty;
  final String? operatingHours;
  final String? description;
  final double latitude;
  final double longitude;
  final bool isLiveQueueActive;
  final double rating;
  final int reviewCount;

  ReceptionClinicModel({
    required this.id,
    required this.name,
    required this.address,
    this.phone,
    this.specialty,
    this.operatingHours,
    this.description,
    required this.latitude,
    required this.longitude,
    required this.isLiveQueueActive,
    required this.rating,
    required this.reviewCount,
  });

  factory ReceptionClinicModel.fromJson(Map<String, dynamic> json) {
    return ReceptionClinicModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'],
      specialty: json['specialty'],
      operatingHours: json['operatingHours'],
      description: json['description'],
      latitude: (json['latitude'] as num?)?.toDouble() ?? 28.5921,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 77.0460,
      isLiveQueueActive: json['isLiveQueueActive'] ?? true,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
    );
  }
}
