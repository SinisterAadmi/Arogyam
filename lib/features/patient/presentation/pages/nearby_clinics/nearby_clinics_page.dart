import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/widgets/app_map_view.dart';
import '../../providers/nearby_clinics_provider.dart';
import '../../widgets/clinic_bottom_sheet.dart';

import '../../../../../app/router/route_names.dart';

class NearbyClinicsPage extends StatefulWidget {
  const NearbyClinicsPage({super.key});

  @override
  State<NearbyClinicsPage> createState() => _NearbyClinicsPageState();
}

class _NearbyClinicsPageState extends State<NearbyClinicsPage> {
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
    return ChangeNotifierProvider(
      create: (_) => NearbyClinicsProvider(),
      child: _NearbyClinicsView(
        mapController: _mapController,
        onZoom: _zoom,
      ),
    );
  }
}

class _NearbyClinicsView extends StatelessWidget {
  final MapController mapController;
  final Function(double) onZoom;

  const _NearbyClinicsView({
    required this.mapController,
    required this.onZoom,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. Pinned Header & Search Bar (Top Layer, Opaque)
            _buildHeader(context),

            // 2. Map and Draggable Sheet Area
            Expanded(
              child: Consumer<NearbyClinicsProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.teal,
                      ),
                    );
                  }

                  if (provider.errorMessage != null) {
                    return Center(
                      child: Text(
                        'Error: ${provider.errorMessage}',
                        style: GoogleFonts.inter(
                          color: AppColors.warning,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }

                  return Stack(
                    children: [
                      // Map Layer (Bottom) - Fills remaining space
                      Positioned.fill(
                        child: AppMapView(
                          controller: mapController,
                          clinics: provider.clinics,
                          onMarkerTap: (clinic) {
                            provider.selectClinic(clinic.id);
                          },
                        ),
                      ),

                      // Zoom Buttons Overlay - Stable in this Stack
                      Positioned(
                        right: 16,
                        top: 16,
                        child: Column(
                          children: [
                            _ZoomButton(
                              icon: LucideIcons.plus,
                              onPressed: () => onZoom(1),
                            ),
                            const SizedBox(height: 8),
                            _ZoomButton(
                              icon: LucideIcons.minus,
                              onPressed: () => onZoom(-1),
                            ),
                          ],
                        ),
                      ),

                      // Draggable Bottom Sheet (Overlay)
                      ClinicBottomSheet(clinics: provider.clinics),
                    ],
                  );
                },
              ),
            ),

          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final provider = context.read<NearbyClinicsProvider>();
    
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(
          bottom: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Title Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCircleButton(
                icon: LucideIcons.chevronLeft,
                onTap: () {
                  Navigator.pushReplacementNamed(context, RouteNames.patientHome);
                },
              ),
              Text(
                'Clinics & Centers',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              _buildCircleButton(
                icon: LucideIcons.bell,
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Search Bar
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppColors.border,
                width: 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.search,
                  size: 18,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    onChanged: (value) => provider.searchClinics(value),
                    decoration: InputDecoration(
                      hintText: 'Search by clinic name, doctor, or area',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textMuted,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: AppColors.iconButtonBg,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 18,
          color: AppColors.teal,
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(
          top: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(LucideIcons.home, 'Home', false, () {
            Navigator.pushReplacementNamed(context, RouteNames.patientHome);
          }),
          _buildNavItem(LucideIcons.mapPin, 'Clinics', true, () {}),
          _buildNavItem(LucideIcons.archive, 'History', false, () {
            Navigator.pushReplacementNamed(context, RouteNames.medicalHistory);
          }),
          _buildNavItem(LucideIcons.radio, 'Share', false, () {
            Navigator.pushReplacementNamed(context, RouteNames.nfcShare);
          }),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 28,
            decoration: BoxDecoration(
              color: isActive ? AppColors.iconButtonBg : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              size: 18,
              color: isActive ? AppColors.teal : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? AppColors.teal : AppColors.textSecondary,
            ),
          ),
        ],
      ),
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
