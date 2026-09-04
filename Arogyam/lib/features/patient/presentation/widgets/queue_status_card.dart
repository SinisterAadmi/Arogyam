import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_colors.dart';

class QueueStatusCard extends StatelessWidget {
  final String clinicName;
  final String tokenNumber;
  final int peopleAhead;
  final String currentlyServing;
  final String waitTime;
  final String status;

  const QueueStatusCard({
    super.key,
    required this.clinicName,
    required this.tokenNumber,
    required this.peopleAhead,
    required this.currentlyServing,
    required this.waitTime,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.radio, size: 18, color: AppColors.teal),
                  const SizedBox(width: 8),
                  Text(
                    'Live Queue Status',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: status == 'completed'
                      ? const Color(0xFFDCFCE7)
                      : status == 'serving'
                          ? const Color(0xFFE0F2FE)
                          : status == 'absent'
                              ? const Color(0xFFFEF2F2)
                              : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status == 'completed'
                      ? 'Done'
                      : status == 'serving'
                          ? 'Serving'
                          : status == 'absent'
                              ? 'Absent'
                              : 'Waiting',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: status == 'completed'
                        ? const Color(0xFF166534)
                        : status == 'serving'
                            ? const Color(0xFF0369A1)
                            : status == 'absent'
                                ? const Color(0xFFDC2626)
                                : const Color(0xFFD97706),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem('Your Token', tokenNumber, isHighlight: true),
              ),
              Container(width: 1, height: 40, color: AppColors.border),
              Expanded(
                child: _buildInfoItem('People Ahead', peopleAhead.toString()),
              ),
              Container(width: 1, height: 40, color: AppColors.border),
              Expanded(
                child: _buildInfoItem('Wait Time', waitTime),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.info, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Currently serving Token #$currentlyServing at $clinicName',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
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

  Widget _buildInfoItem(String label, String value, {bool isHighlight = false}) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isHighlight ? AppColors.teal : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
