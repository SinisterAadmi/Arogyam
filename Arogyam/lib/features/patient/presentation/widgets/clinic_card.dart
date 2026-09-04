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
            // Row 1: Left info (Name + Address + Distance) & Right (Wait Time + Open/Closed Badge)
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
                    // Open / Closed Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: clinic.isOpen ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: clinic.isOpen ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: clinic.isOpen ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            clinic.isOpen ? 'Open' : 'Closed',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: clinic.isOpen ? const Color(0xFF166534) : const Color(0xFF991B1B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    if (clinic.isOpen)
                      Text(
                        'Wait: ~${clinic.waitTimeMinutes}m',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.warning,
                        ),
                      )
                    else
                      Text(
                        'Closed today',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.normal,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // If clinic is closed: display warning banner
            if (!clinic.isOpen) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.alertCircle, size: 13, color: Color(0xFFDC2626)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Clinic is currently closed',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF991B1B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Row 2: About on Left, Actions on Right (or greyed out if closed)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // About button (always functional)
                InkWell(
                  onTap: onAbout,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.info, size: 13, color: AppColors.teal),
                        const SizedBox(width: 3),
                        Text(
                          'About',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.teal,
                          ),
                        ),
                      ],
                    ),
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
                          onTap: clinic.isOpen ? onJoinQueue : null,
                          borderRadius: BorderRadius.circular(8),
                          child: Ink(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: clinic.isOpen ? AppColors.teal : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Join Queue',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: clinic.isOpen ? AppColors.white : const Color(0xFF94A3B8),
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
                        onTap: clinic.isOpen ? onBookVisit : null,
                        borderRadius: BorderRadius.circular(8),
                        child: Ink(
                          padding: EdgeInsets.symmetric(
                            horizontal: clinic.isLiveQueueActive ? 10 : 12,
                            vertical: clinic.isLiveQueueActive ? 6 : 8,
                          ),
                          decoration: BoxDecoration(
                            color: !clinic.isOpen
                                ? const Color(0xFFF1F5F9)
                                : (clinic.isLiveQueueActive ? const Color(0xFFF0FDFA) : AppColors.teal),
                            borderRadius: BorderRadius.circular(8),
                            border: clinic.isOpen && clinic.isLiveQueueActive
                                ? Border.all(color: AppColors.teal)
                                : null,
                          ),
                          child: Text(
                            'Book Visit',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: !clinic.isOpen
                                  ? const Color(0xFF94A3B8)
                                  : (clinic.isLiveQueueActive ? AppColors.teal : AppColors.white),
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
