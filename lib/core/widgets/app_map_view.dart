import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/theme/app_colors.dart';
import '../../shared/entities/clinic.dart';
import '../constants/api_constants.dart';

class AppMapView extends StatelessWidget {
  final List<Clinic> clinics;
  final LatLng? initialCenter;
  final double initialZoom;
  final void Function(Clinic)? onMarkerTap;
  final MapController? controller;

  const AppMapView({
    super.key,
    required this.clinics,
    this.initialCenter,
    this.initialZoom = 14.0,
    this.onMarkerTap,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    // Fallback center if no clinics and no initialCenter provided
    final LatLng center = initialCenter ??
        (clinics.isNotEmpty
            ? LatLng(clinics.first.latitude, clinics.first.longitude)
            : const LatLng(28.5921, 77.0460)); // Dwarka, Delhi fallback

    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: center,
        initialZoom: initialZoom,
        minZoom: 2.0,
        maxZoom: 18.0,
        cameraConstraint: CameraConstraint.contain(
          bounds: LatLngBounds(
            const LatLng(-56.0, -180.0),
            const LatLng(78.0, 180.0),
          ),
        ),
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=${ApiConstants.mapTilerApiKey}',
          userAgentPackageName: 'com.example.arogyam',
          tileProvider: NetworkTileProvider(),
        ),
        MarkerLayer(
          markers: clinics.map((clinic) {
            return Marker(
              point: LatLng(clinic.latitude, clinic.longitude),
              width: 150, // Enough width for the pill
              height: 40,
              child: GestureDetector(
                onTap: () => onMarkerTap?.call(clinic),
                child: _ClinicPillMarker(name: clinic.name),
              ),
            );
          }).toList(),
        ),
        const RichAttributionWidget(
          attributions: [
            TextSourceAttribution('MapTiler'),
            TextSourceAttribution('OpenStreetMap contributors'),
          ],
        ),
      ],
    );
  }
}

class _ClinicPillMarker extends StatelessWidget {
  final String name;

  const _ClinicPillMarker({required this.name});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.teal,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.plusSquare,
              size: 12,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                name,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
