import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../shared/entities/clinic.dart';

class ClinicCard extends StatelessWidget {
  final Clinic clinic;
  final VoidCallback? onBookVisit;
  final VoidCallback? onJoinQueue;
  final VoidCallback? onAbout;
  final VoidCallback? onTap;
  final bool isSelected;

  const ClinicCard({
    super.key,
    required this.clinic,
    this.onBookVisit,
    this.onJoinQueue,
    this.onAbout,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.teal : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.teal.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Left info (Name + Address + Distance) & Right Wait Time + Status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clinic.name,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        clinic.address,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(LucideIcons.navigation, size: 11, color: AppColors.teal),
                          const SizedBox(width: 4),
                          Text(
                            '${clinic.distanceKm.toStringAsFixed(1)} km away',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.teal,
                            ),
                          ),
                          if (clinic.specialty != null) ...[
                            Text(' • ', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                            Flexible(
                              child: Text(
                                clinic.specialty!,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Right Column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Wait: ~${clinic.waitTimeMinutes} mins',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      clinic.isLiveQueueActive
                          ? 'Live Queue Active'
                          : 'Queue Inactive',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.normal,
                        color: clinic.isLiveQueueActive
                            ? AppColors.textSecondary
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Row 2: Rating on Left, Actions on Right
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Rating & About
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: Color(0xFFFBBF24),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        clinic.rating.toStringAsFixed(1),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '(${clinic.reviewCount})',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.normal,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 6),
                      // About button
                      InkWell(
                        onTap: onAbout,
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.info, size: 12, color: AppColors.teal),
                              const SizedBox(width: 2),
                              Text(
                                'About',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.teal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Action Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (clinic.isLiveQueueActive) ...[
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onJoinQueue,
                          borderRadius: BorderRadius.circular(8),
                          child: Ink(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.teal,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Join Queue',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onBookVisit,
                        borderRadius: BorderRadius.circular(8),
                        child: Ink(
                          padding: EdgeInsets.symmetric(
                            horizontal: clinic.isLiveQueueActive ? 9 : 12,
                            vertical: clinic.isLiveQueueActive ? 6 : 8,
                          ),
                          decoration: BoxDecoration(
                            color: clinic.isLiveQueueActive
                                ? const Color(0xFFF0FDFA)
                                : AppColors.teal,
                            borderRadius: BorderRadius.circular(8),
                            border: clinic.isLiveQueueActive
                                ? Border.all(color: AppColors.teal)
                                : null,
                          ),
                          child: Text(
                            'Book Visit',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: clinic.isLiveQueueActive
                                  ? AppColors.teal
                                  : AppColors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
