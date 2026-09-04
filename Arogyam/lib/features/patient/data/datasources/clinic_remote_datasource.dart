import '../../../../core/network/api_client.dart';
import '../../../../shared/entities/clinic.dart';

abstract class ClinicRemoteDatasource {
  Future<List<Clinic>> getNearbyClinics(double lat, double lng);
}

class ClinicRemoteDatasourceImpl implements ClinicRemoteDatasource {
  final ApiClient _client;

  ClinicRemoteDatasourceImpl(this._client);

  @override
  Future<List<Clinic>> getNearbyClinics(double lat, double lng) async {
    final response = await _client.get('/patients/clinics/nearby', queryParameters: {
      'lat': lat,
      'lng': lng,
    });
    
    return (response.data as List).map((json) => Clinic(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      phone: json['phone'],
      specialty: json['specialty'],
      operatingHours: json['operatingHours'],
      description: json['description'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      distanceKm: json['distanceKm'].toDouble(),
      waitTimeMinutes: json['waitTimeMinutes'],
      isLiveQueueActive: json['isLiveQueueActive'],
      isOpen: json['isOpen'] ?? true,
      rating: json['rating'].toDouble(),
      reviewCount: json['reviewCount'],
      doctors: (json['doctors'] as List?)
              ?.map((d) => DoctorInfo.fromJson(d as Map<String, dynamic>))
              .toList() ??
          const [],
    )).toList();
  }
}
