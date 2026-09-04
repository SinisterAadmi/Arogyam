import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:arogyam_flutter/app/theme/app_colors.dart';
import 'package:arogyam_flutter/app/theme/app_typography.dart';

import '../../../../shared/entities/clinic.dart';

class ClinicInfoCard extends StatelessWidget {
  final Clinic clinic;

  const ClinicInfoCard({
    super.key,
    required this.clinic,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.iconBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Icon(
              LucideIcons.building2,
              size: 24,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                clinic.name,
                style: AppTypography.h2,
              ),
              const SizedBox(height: 2),
              Text(
                'General Physician • ${clinic.address}',
                style: AppTypography.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
