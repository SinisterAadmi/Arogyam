import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../app/router/route_names.dart';
import '../../../../../app/theme/app_colors.dart';

class NfcSharePage extends StatefulWidget {
  const NfcSharePage({super.key});

  @override
  State<NfcSharePage> createState() => _NfcSharePageState();
}

class _NfcSharePageState extends State<NfcSharePage> with SingleTickerProviderStateMixin {
  bool _shareFullHistory = false;
  bool _selectedRecordsOnly = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            onTap: () => Navigator.pushReplacementNamed(context, RouteNames.patientHome),
          ),
        ),
        title: Text(
          'NFC Instant Share',
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
        shape: const Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Broadcasting Visual with Animated Ripples
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDFA),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _buildAnimatedRipple(100),
                  _buildAnimatedRipple(140),
                  _buildAnimatedRipple(180),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.smartphone,
                        size: 44,
                        color: AppColors.teal,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'NFC Signal Broadcasting...',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.teal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Tap your phone on the doctor's device",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            // Timer Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEDD5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFEA580C)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    LucideIcons.clock,
                    size: 14,
                    color: Color(0xFFEA580C),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Secured link active for 04:59 mins',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFEA580C),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Consent Settings Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Consent Settings',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildConsentToggle(
                    'Share full medical history',
                    _shareFullHistory,
                    (v) => setState(() {
                      _shareFullHistory = v;
                      if (v) _selectedRecordsOnly = false;
                    }),
                  ),
                  const Divider(height: 24, color: AppColors.border),
                  _buildConsentToggle(
                    'Selected records only',
                    _selectedRecordsOnly,
                    (v) => setState(() {
                      _selectedRecordsOnly = v;
                      if (v) _shareFullHistory = false;
                    }),
                    isSemiBold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Security Disclaimer
            Text(
              'Doctors can only view records. Transmitted links self-destruct. Protected strictly under ABDM Digital Security framework.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildAnimatedRipple(double size) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          width: size * _animationController.value,
          height: size * _animationController.value,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.teal.withValues(alpha: (1 - _animationController.value) * 0.3),
              width: 2,
            ),
          ),
        );
      },
    );
  }

  Widget _buildConsentToggle(String title, bool value, ValueChanged<bool> onChanged, {bool isSemiBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: isSemiBold ? FontWeight.w600 : FontWeight.normal,
            color: AppColors.textSecondary,
          ),
        ),
        Switch.adaptive(
          value: value,
          activeTrackColor: AppColors.teal,
          onChanged: onChanged,
        ),
      ],
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
          _buildNavItem(context, LucideIcons.archive, 'History', false, () {
            Navigator.pushReplacementNamed(context, RouteNames.medicalHistory);
          }),
          _buildNavItem(context, LucideIcons.radio, 'Share', true, () {}),
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
