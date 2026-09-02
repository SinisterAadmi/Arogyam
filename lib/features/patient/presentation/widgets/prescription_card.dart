import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../shared/entities/prescription.dart';
import '../../../../shared/enums/prescription_status.dart';

class PrescriptionCard extends StatelessWidget {
  final Prescription prescription;

  const PrescriptionCard({
    super.key,
    required this.prescription,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Icon + Name & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.pill,
                      size: 18,
                      color: AppColors.teal,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        prescription.medicineName,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusBadge(prescription.status),
            ],
          ),
          const SizedBox(height: 12),

          // Row 2: Dosage + Prescriber
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                prescription.dosageInstructions,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Prescribed by ${prescription.prescribedBy} (${prescription.clinicName})',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.normal,
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),

          // Row 3: Expiry + Pharmacy QR
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Expiry: ${DateFormat('d MMM yyyy').format(prescription.expiryDate)}',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.normal,
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              GestureDetector(
                onTap: () {
                  // QR display
                },
                child: const Row(
                  children: [
                    Icon(
                      LucideIcons.qrCode,
                      size: 14,
                      color: AppColors.teal,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Pharmacy QR',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.teal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(PrescriptionStatus status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case PrescriptionStatus.active:
        bgColor = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF16A34A);
        label = 'Active';
        break;
      case PrescriptionStatus.expiringSoon:
        bgColor = const Color(0xFFFFEDD5);
        textColor = const Color(0xFFEA580C);
        label = 'Expiring Soon';
        break;
      case PrescriptionStatus.expired:
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFFDC2626);
        label = 'Expired';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.bold,
          fontSize: 11,
          color: textColor,
        ),
      ),
    );
  }
}
