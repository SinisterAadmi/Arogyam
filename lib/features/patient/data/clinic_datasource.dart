import '../../../shared/entities/clinic.dart';

abstract class ClinicDatasource {
  Future<List<Clinic>> getNearbyClinics();
}

class MockClinicDatasource implements ClinicDatasource {
  @override
  Future<List<Clinic>> getNearbyClinics() async {
    await Future.delayed(const Duration(milliseconds: 300));

    return const [
      Clinic(
        id: '1',
        name: 'City Family Health Clinic',
        address: 'Sector 5, Dwarka',
        latitude: 28.5921,
        longitude: 77.0460,
        distanceKm: 0.8,
        waitTimeMinutes: 15,
        isLiveQueueActive: true,
        rating: 4.8,
        reviewCount: 120,
      ),
      Clinic(
        id: '2',
        name: 'City Health',
        address: 'Sector 6, Dwarka',
        latitude: 28.5935,
        longitude: 77.0475,
        distanceKm: 1.2,
        waitTimeMinutes: 25,
        isLiveQueueActive: true,
        rating: 4.6,
        reviewCount: 95,
      ),
      Clinic(
        id: '3',
        name: 'Apollo',
        address: 'Sector 10, Dwarka',
        latitude: 28.5960,
        longitude: 77.0510,
        distanceKm: 2.4,
        waitTimeMinutes: 10,
        isLiveQueueActive: false,
        rating: 4.9,
        reviewCount: 230,
      ),
    ];
  }
}
