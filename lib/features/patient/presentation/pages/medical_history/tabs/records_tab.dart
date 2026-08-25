import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../../app/theme/app_colors.dart';
import '../../../widgets/encrypted_vault_banner.dart';
import '../../../widgets/medical_category_card.dart';

class RecordsTab extends StatelessWidget {
  final VoidCallback onPrescriptionsTap;

  const RecordsTab({
    super.key,
    required this.onPrescriptionsTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EncryptedVaultBanner(),
          const SizedBox(height: 20),
          Text(
            'Categorized Records',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          MedicalCategoryCard(
            title: 'Lab Reports',
            lastUpdated: '10 Jan 2026',
            count: 12,
            icon: LucideIcons.clipboardList,
            iconBgColor: const Color(0xFFE0F2FE),
            onTap: () {},
          ),
          const SizedBox(height: 12),
          MedicalCategoryCard(
            title: 'Prescriptions',
            lastUpdated: '12 Jan 2026',
            count: 8,
            icon: LucideIcons.pill,
            iconBgColor: const Color(0xFFF0FDFA),
            onTap: onPrescriptionsTap,
          ),
          const SizedBox(height: 12),
          MedicalCategoryCard(
            title: 'Discharge Summaries',
            lastUpdated: '20 Aug 2025',
            count: 2,
            icon: LucideIcons.fileText,
            iconBgColor: const Color(0xFFFEE2E2),
            onTap: () {},
          ),
          const SizedBox(height: 12),
          MedicalCategoryCard(
            title: 'Diagnostic Imaging',
            lastUpdated: '15 Dec 2025',
            count: 4,
            icon: LucideIcons.activity,
            iconBgColor: const Color(0xFFF3E8FF),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
