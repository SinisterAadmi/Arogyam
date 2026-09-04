import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Default fallback location (Dwarka, Delhi) if GPS is unavailable
  static const LatLng defaultFallback = LatLng(28.5921, 77.0460);

  /// Check if location services (GPS hardware/toggle) are enabled
  Future<bool> isServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      debugPrint('[LocationService] Error checking service status: $e');
      return false;
    }
  }

  /// Request runtime location permission
  Future<LocationPermission> requestPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return permission;
    } catch (e) {
      debugPrint('[LocationService] Error requesting permission: $e');
      return LocationPermission.denied;
    }
  }

  /// Get device's actual current location
  /// Returns null or defaultFallback if permissions are denied or GPS is disabled
  Future<LatLng?> getCurrentLocation({
    bool fallbackToDefault = false,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[LocationService] Location services are disabled by user');
        return fallbackToDefault ? defaultFallback : null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('[LocationService] Location permission denied by user');
          return fallbackToDefault ? defaultFallback : null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('[LocationService] Location permission permanently denied');
        return fallbackToDefault ? defaultFallback : null;
      }

      // Try fast last known position first as cache
      Position? position = await Geolocator.getLastKnownPosition();

      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: timeout,
          ),
        );
      } catch (e) {
        debugPrint('[LocationService] High accuracy timeout or error: $e, using cached/fallback');
      }

      if (position != null) {
        debugPrint('[LocationService] Acquired real coordinates: Lat=${position.latitude}, Lng=${position.longitude}');
        return LatLng(position.latitude, position.longitude);
      }

      return fallbackToDefault ? defaultFallback : null;
    } catch (e, stackTrace) {
      debugPrint('[LocationService] Exception in getCurrentLocation: $e\n$stackTrace');
      return fallbackToDefault ? defaultFallback : null;
    }
  }
}
