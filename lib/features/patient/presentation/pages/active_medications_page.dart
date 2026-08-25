import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../providers/prescriptions_provider.dart';
import '../widgets/prescription_card.dart';

class ActiveMedicationsPage extends StatelessWidget {
  const ActiveMedicationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PrescriptionsProvider(),
      child: const _ActiveMedicationsView(),
    );
  }
}

class _ActiveMedicationsView extends StatelessWidget {
  const _ActiveMedicationsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            _buildInfoBanner(),
            Expanded(
              child: Consumer<PrescriptionsProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.teal),
                    );
                  }

                  if (provider.errorMessage != null) {
                    return Center(
                      child: Text(
                        'Error: ${provider.errorMessage}',
                        style: GoogleFonts.inter(color: AppColors.warning),
                      ),
                    );
                  }

                  if (provider.prescriptions.isEmpty) {
                    return const Center(
                      child: Text('No active medications found.'),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: provider.prescriptions.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      return PrescriptionCard(prescription: provider.prescriptions[index]);
                    },
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
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildCircleButton(
                icon: LucideIcons.chevronLeft,
                onTap: () => Navigator.pushReplacementNamed(context, RouteNames.patientHome),
              ),
              const SizedBox(width: 12),
              Text(
                'Active Medications',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          _buildCircleButton(
            icon: LucideIcons.bell,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({required IconData icon, required VoidCallback onTap}) {
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
        child: Icon(icon, size: 18, color: AppColors.teal),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Text(
        'Your digital verified prescriptions under ABHA. Show QR or code to any pharmacy.',
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(LucideIcons.home, 'Home', false, () {
            Navigator.pushReplacementNamed(context, RouteNames.patientHome);
          }),
          _buildNavItem(LucideIcons.mapPin, 'Clinics', false, () {
            Navigator.pushReplacementNamed(context, RouteNames.nearbyClinics);
          }),
          _buildNavItem(LucideIcons.archive, 'History', true, () {
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
