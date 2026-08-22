import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/theme/app_colors.dart';
import '../../shared/entities/clinic.dart';
import '../constants/api_constants.dart';

class AppMapView extends StatefulWidget {
  final List<Clinic> clinics;
  final LatLng? initialCenter;
  final double initialZoom;
  final void Function(Clinic)? onMarkerTap;

  const AppMapView({
    super.key,
    required this.clinics,
    this.initialCenter,
    this.initialZoom = 14.0,
    this.onMarkerTap,
  });

  @override
  State<AppMapView> createState() => _AppMapViewState();
}

class _AppMapViewState extends State<AppMapView> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _zoom(double delta) {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom + delta);
  }

  @override
  Widget build(BuildContext context) {
    // Fallback center if no clinics and no initialCenter provided
    final LatLng center = widget.initialCenter ??
        (widget.clinics.isNotEmpty
            ? LatLng(widget.clinics.first.latitude, widget.clinics.first.longitude)
            : const LatLng(28.5921, 77.0460)); // Dwarka, Delhi fallback

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: widget.initialZoom,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            TileLayer(
              // TODO: verify tile URL pattern against your current MapTiler dashboard
              urlTemplate:
                  'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=${ApiConstants.mapTilerApiKey}',
              userAgentPackageName: 'com.example.arogyam',
              subdomains: const ['a', 'b', 'c', 'd'],
            ),
            MarkerLayer(
              markers: widget.clinics.map((clinic) {
                return Marker(
                  point: LatLng(clinic.latitude, clinic.longitude),
                  width: 150, // Enough width for the pill
                  height: 40,
                  child: GestureDetector(
                    onTap: () => widget.onMarkerTap?.call(clinic),
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
        ),

        // Zoom Buttons Overlay
        Positioned(
          right: 16,
          top: MediaQuery.of(context).size.height * 0.2, // Positioned in the upper half
          child: Column(
            children: [
              _ZoomButton(
                icon: LucideIcons.plus,
                onPressed: () => _zoom(1),
              ),
              const SizedBox(height: 8),
              _ZoomButton(
                icon: LucideIcons.minus,
                onPressed: () => _zoom(-1),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _ZoomButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppColors.teal,
          ),
        ),
      ),
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
