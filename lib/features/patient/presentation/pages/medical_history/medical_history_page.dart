import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../../app/router/route_names.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../providers/prescriptions_provider.dart';
import 'tabs/records_tab.dart';
import 'tabs/prescriptions_tab.dart';

class MedicalHistoryPage extends StatefulWidget {
  const MedicalHistoryPage({super.key});

  @override
  State<MedicalHistoryPage> createState() => _MedicalHistoryPageState();
}

class _MedicalHistoryPageState extends State<MedicalHistoryPage> {
  bool _showPrescriptions = false;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PrescriptionsProvider()),
      ],
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          leadingWidth: 76,
          leading: Center(
            child: _buildCircleButton(
              context: context,
              icon: LucideIcons.chevronLeft,
              onTap: () {
                if (_showPrescriptions) {
                  setState(() => _showPrescriptions = false);
                } else {
                  Navigator.pushReplacementNamed(context, RouteNames.patientHome);
                }
              },
            ),
          ),
          title: Text(
            _showPrescriptions ? 'Active Medications' : 'Medical History',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: _buildCircleButton(
                context: context,
                icon: LucideIcons.bell,
                onTap: () {},
              ),
            ),
          ],
        ),
        body: _showPrescriptions
            ? const PrescriptionsTab()
            : RecordsTab(
                onPrescriptionsTap: () {
                  setState(() => _showPrescriptions = true);
                },
              ),
        bottomNavigationBar: _buildBottomNav(context),
      ),
    );
  }

  Widget _buildCircleButton({
    required BuildContext context,
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
        child: Icon(icon, size: 18, color: AppColors.teal),
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
          _buildNavItem(context, LucideIcons.home, 'Home', false, () {
            Navigator.pushReplacementNamed(context, RouteNames.patientHome);
          }),
          _buildNavItem(context, LucideIcons.mapPin, 'Clinics', false, () {
            Navigator.pushReplacementNamed(context, RouteNames.nearbyClinics);
          }),
          _buildNavItem(context, LucideIcons.archive, 'History', true, () {
            if (_showPrescriptions) {
              setState(() => _showPrescriptions = false);
            }
          }),
          _buildNavItem(context, LucideIcons.radio, 'Share', false, () {
            Navigator.pushReplacementNamed(context, RouteNames.nfcShare);
          }),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String label,
    bool isActive,
    VoidCallback onTap,
  ) {
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
