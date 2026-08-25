import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../app/router/route_names.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../widgets/user_hero_section.dart';
import '../../widgets/upcoming_appointment_card.dart';
import '../../widgets/prescriptions_banner.dart';
import '../../widgets/quick_action_card.dart';

class PatientHomePage extends StatelessWidget {
  const PatientHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const UserHeroSection(
                      userName: 'Rajesh Kumar',
                      abhaId: '91-8273-1284',
                      imageUrl: 'https://www.figma.com/api/mcp/asset/4bfd7ea4-6c80-4455-83a6-0509e9bb2b94.png',
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () {
                              Navigator.pushNamed(context, RouteNames.queueStatus);
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: const UpcomingAppointmentCard(
                              doctorName: 'Dr. Ananya Sharma',
                              specialty: 'Cardiologist',
                              clinicName: 'Apollo Health City',
                              appointmentTime: 'Tomorrow, 10:30 AM',
                              tokenNumber: '15',
                            ),
                          ),
                          const SizedBox(height: 20),
                          PrescriptionsBanner(
                            count: 3,
                            subtext: '1 medication needs refill soon',
                            onTap: () {
                              Navigator.pushNamed(context, RouteNames.medicalHistory);
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildQuickActions(context),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            QuickActionCard(
              title: 'Live Queue',
              icon: LucideIcons.radio,
              iconBgColor: const Color(0xFFE0F2FE),
              onTap: () {
                Navigator.pushReplacementNamed(context, RouteNames.queueStatus);
              },
            ),
            QuickActionCard(
              title: 'Health Vault',
              icon: LucideIcons.fileText,
              iconBgColor: const Color(0xFFDCFCE7),
              onTap: () {},
            ),
            QuickActionCard(
              title: 'Nearby Clinics',
              icon: LucideIcons.navigation,
              iconBgColor: const Color(0xFFFFEDD5),
              onTap: () {
                Navigator.pushReplacementNamed(context, RouteNames.nearbyClinics);
              },
            ),
            QuickActionCard(
              title: 'NFC Share',
              icon: LucideIcons.wifi,
              iconBgColor: const Color(0xFFF3E8FF),
              onTap: () {
                Navigator.pushReplacementNamed(context, RouteNames.nfcShare);
              },
            ),
          ],
        ),
      ],
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
          _buildNavItem(LucideIcons.home, 'Home', true, () {}),
          _buildNavItem(LucideIcons.mapPin, 'Clinics', false, () {
            Navigator.pushReplacementNamed(context, RouteNames.nearbyClinics);
          }),
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
