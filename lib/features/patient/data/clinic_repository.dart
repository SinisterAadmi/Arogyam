import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/location/location_service.dart';
import '../../../shared/entities/clinic.dart';
import '../domain/repositories/clinic_repository.dart';
import 'datasources/clinic_remote_datasource.dart';

class ClinicRepositoryImpl implements ClinicRepository {
  final ClinicRemoteDatasource _datasource;

  ClinicRepositoryImpl(this._datasource);

  @override
  Future<List<Clinic>> getNearbyClinics({double? lat, double? lng}) async {
    try {
      double targetLat;
      double targetLng;

      if (lat != null && lng != null) {
        targetLat = lat;
        targetLng = lng;
      } else {
        final pos = await LocationService().getCurrentLocation(fallbackToDefault: true);
        targetLat = pos?.latitude ?? LocationService.defaultFallback.latitude;
        targetLng = pos?.longitude ?? LocationService.defaultFallback.longitude;
      }

      debugPrint('[ClinicRepository] Fetching nearby clinics for coordinates: ($targetLat, $targetLng)');
      return await _datasource.getNearbyClinics(targetLat, targetLng);
    } on DioException catch (e, stackTrace) {
      debugPrint('[Patient] error: $e\n$stackTrace');
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        rethrow;
      }
      return const [
        Clinic(
          id: '1',
          name: 'City Family Health Clinic (Mock)',
          address: 'Sector 5, Dwarka',
          latitude: 28.5921,
          longitude: 77.0460,
          distanceKm: 0.8,
          waitTimeMinutes: 15,
          isLiveQueueActive: true,
          rating: 4.8,
          reviewCount: 120,
        ),
      ];
    } catch (e, stackTrace) {
      debugPrint('[Patient] error: $e\n$stackTrace');
      rethrow;
    }
  }
}
