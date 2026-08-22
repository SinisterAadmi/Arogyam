import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/widgets/app_map_view.dart';
import '../../providers/nearby_clinics_provider.dart';
import '../../widgets/clinic_bottom_sheet.dart';

class NearbyClinicsPage extends StatelessWidget {
  const NearbyClinicsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NearbyClinicsProvider(),
      child: const _NearbyClinicsView(),
    );
  }
}

class _NearbyClinicsView extends StatelessWidget {
  const _NearbyClinicsView();

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
                          clinics: provider.clinics,
                          onMarkerTap: (clinic) {
                            provider.selectClinic(clinic.id);
                          },
                        ),
                      ),

                      // Draggable Bottom Sheet (Overlay)
                      // Interactive like Uber/Rapido
                      ClinicBottomSheet(clinics: provider.clinics),
                    ],
                  );
                },
              ),
            ),

            // 3. Bottom Navigation Bar
            _buildBottomNav(),

            // 4. Home Indicator
            _buildHomeIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
                onTap: () {},
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

  Widget _buildBottomNav() {
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
          _buildNavItem(LucideIcons.home, 'Home', false),
          _buildNavItem(LucideIcons.mapPin, 'Clinics', true),
          _buildNavItem(LucideIcons.archive, 'Records', false),
          _buildNavItem(LucideIcons.radio, 'Live Queue', false),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return Column(
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
    );
  }

  Widget _buildHomeIndicator() {
    return Container(
      color: AppColors.card,
      padding: const EdgeInsets.only(bottom: 8),
      alignment: Alignment.center,
      child: Container(
        width: 134,
        height: 5,
        decoration: BoxDecoration(
          color: AppColors.textPrimary,
          borderRadius: BorderRadius.circular(100),
        ),
      ),
    );
  }
}
