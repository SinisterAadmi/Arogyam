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
  final LatLng? userLocation;
  final double initialZoom;
  final void Function(Clinic)? onMarkerTap;
  final VoidCallback? onLocationTap;
  final bool isLocating;
  final MapController? controller;
  final String? selectedClinicId;
  final bool showControls;

  const AppMapView({
    super.key,
    required this.clinics,
    this.initialCenter,
    this.userLocation,
    this.initialZoom = 14.0,
    this.onMarkerTap,
    this.onLocationTap,
    this.isLocating = false,
    this.controller,
    this.selectedClinicId,
    this.showControls = true,
  });

  @override
  State<AppMapView> createState() => _AppMapViewState();
}

class _AppMapViewState extends State<AppMapView> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = widget.controller ?? MapController();
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, (currentZoom + 1.0).clamp(2.0, 18.0));
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, (currentZoom - 1.0).clamp(2.0, 18.0));
  }

  @override
  Widget build(BuildContext context) {
    // Fallback center priority: initialCenter -> userLocation -> first clinic -> Dwarka default
    final LatLng center = widget.initialCenter ??
        widget.userLocation ??
        (widget.clinics.isNotEmpty
            ? LatLng(widget.clinics.first.latitude, widget.clinics.first.longitude)
            : const LatLng(28.5921, 77.0460));

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: widget.initialZoom,
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
            // User Location Marker Layer (if location acquired)
            if (widget.userLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: widget.userLocation!,
                    width: 48,
                    height: 48,
                    child: const _UserLocationPin(),
                  ),
                ],
              ),
            // Clinic Markers Layer
            MarkerLayer(
              markers: widget.clinics.map((clinic) {
                final isSelected = widget.selectedClinicId == clinic.id;
                return Marker(
                  point: LatLng(clinic.latitude, clinic.longitude),
                  width: isSelected ? 170 : 150,
                  height: isSelected ? 48 : 40,
                  child: GestureDetector(
                    onTap: () => widget.onMarkerTap?.call(clinic),
                    child: _ClinicPillMarker(
                      name: clinic.name,
                      isSelected: isSelected,
                    ),
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
        if (widget.showControls)
          Positioned(
            right: 14,
            top: 14,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Zoom In / Zoom Out Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          onTap: _zoomIn,
                          child: const Padding(
                            padding: EdgeInsets.all(10),
                            child: Icon(LucideIcons.plus, size: 18, color: AppColors.textPrimary),
                          ),
                        ),
                      ),
                      Container(
                        width: 28,
                        height: 1,
                        color: AppColors.border,
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                          onTap: _zoomOut,
                          child: const Padding(
                            padding: EdgeInsets.all(10),
                            child: Icon(LucideIcons.minus, size: 18, color: AppColors.textPrimary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Current Location Button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: widget.isLocating ? null : widget.onLocationTap,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: widget.isLocating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.teal,
                                ),
                              )
                            : const Icon(
                                LucideIcons.locateFixed,
                                size: 18,
                                color: AppColors.teal,
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _UserLocationPin extends StatelessWidget {
  const _UserLocationPin();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer GPS Accuracy Ring
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
        ),
        // Middle Pulse Ring
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withValues(alpha: 0.25),
            shape: BoxShape.circle,
          ),
        ),
        // Center Solid Blue Dot with Crisp White Border & Shadow
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFF1D4ED8),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ClinicPillMarker extends StatelessWidget {
  final String name;
  final bool isSelected;

  const _ClinicPillMarker({
    required this.name,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isSelected ? const Color(0xFF0F766E) : AppColors.teal;
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 12 : 10,
          vertical: isSelected ? 8 : 6,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFFACC15) : Colors.white,
            width: isSelected ? 2.5 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF0F766E).withValues(alpha: 0.4)
                  : Colors.black.withValues(alpha: 0.15),
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? LucideIcons.mapPin : LucideIcons.plusSquare,
              size: isSelected ? 14 : 12,
              color: isSelected ? const Color(0xFFFACC15) : Colors.white,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                name,
                style: GoogleFonts.inter(
                  fontSize: isSelected ? 12 : 11,
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
