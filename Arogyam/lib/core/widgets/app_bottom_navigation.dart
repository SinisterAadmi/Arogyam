import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/theme/app_colors.dart';

class AppBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(LucideIcons.home, 'Home', currentIndex == 0, () => onTap(0)),
          _buildNavItem(LucideIcons.mapPin, 'Clinics', currentIndex == 1, () => onTap(1)),
          _buildNavItem(LucideIcons.archive, 'History', currentIndex == 2, () => onTap(2)),
          _buildNavItem(LucideIcons.radio, 'Share', currentIndex == 3, () => onTap(3)),
          _buildNavItem(LucideIcons.user, 'Profile', currentIndex == 4, () => onTap(4)),
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
