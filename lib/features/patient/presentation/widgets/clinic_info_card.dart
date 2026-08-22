import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:arogyam_flutter/app/theme/app_colors.dart';
import 'package:arogyam_flutter/app/theme/app_typography.dart';

class ClinicInfoCard extends StatelessWidget {
  const ClinicInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.iconBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SvgPicture.network(
            'https://www.figma.com/api/mcp/asset/8cc8344b-638e-48d3-929a-20d46dcd7b80.svg',
            colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'City Family Health Clinic',
                style: AppTypography.h2,
              ),
              SizedBox(height: 2),
              Text(
                'General Physician • Sector 5, Dwarka',
                style: AppTypography.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
