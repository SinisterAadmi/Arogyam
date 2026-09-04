import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../shared/entities/clinic.dart';

class ClinicAboutBottomSheet extends StatelessWidget {
  final Clinic clinic;
  final VoidCallback? onJoinQueue;
  final VoidCallback? onBookVisit;

  const ClinicAboutBottomSheet({
    super.key,
    required this.clinic,
    this.onJoinQueue,
    this.onBookVisit,
  });

  static void show(
    BuildContext context, {
    required Clinic clinic,
    VoidCallback? onJoinQueue,
    VoidCallback? onBookVisit,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ClinicAboutBottomSheet(
        clinic: clinic,
        onJoinQueue: onJoinQueue,
        onBookVisit: onBookVisit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header: Name, Specialty & Rating
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDFA),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFCCFBF1)),
                ),
                child: const Icon(LucideIcons.building2, size: 24, color: AppColors.teal),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clinic.name,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      clinic.specialty ?? 'General Healthcare',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.teal,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
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
                                clinic.isOpen ? 'Open Now' : 'Closed',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: clinic.isOpen ? const Color(0xFF166534) : const Color(0xFF991B1B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${clinic.distanceKm.toStringAsFixed(1)} km away',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Details List
          _buildInfoRow(
            icon: LucideIcons.mapPin,
            title: 'Address',
            value: clinic.address,
          ),
          const SizedBox(height: 14),

          _buildInfoRow(
            icon: LucideIcons.clock,
            title: 'Operating Hours',
            value: clinic.operatingHours ?? 'Mon-Sat 9:00 AM - 8:00 PM',
          ),
          const SizedBox(height: 14),

          _buildInfoRow(
            icon: LucideIcons.phone,
            title: 'Contact Phone',
            value: clinic.phone ?? '+91 22 2700 3300',
          ),
          const SizedBox(height: 14),

          _buildInfoRow(
            icon: LucideIcons.fileText,
            title: 'About Clinic',
            value: clinic.description ?? 'Quality medical care with digital queuing and diagnostics.',
          ),

          if (clinic.doctors.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Attending Physicians',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: clinic.doctors.map((doc) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.stethoscope, size: 14, color: AppColors.teal),
                      const SizedBox(width: 6),
                      Text(
                        '${doc.name} (${doc.specialty})',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 24),

          // Actions
          if (!clinic.isOpen) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.alertCircle, size: 18, color: Color(0xFFDC2626)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Clinic is currently closed. Queuing and booking are unavailable.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF991B1B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              if (clinic.isLiveQueueActive) ...[
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: clinic.isOpen
                          ? () {
                              Navigator.pop(context);
                              onJoinQueue?.call();
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: clinic.isOpen ? AppColors.teal : const Color(0xFFE2E8F0),
                        foregroundColor: clinic.isOpen ? Colors.white : const Color(0xFF94A3B8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Join Live Queue',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: OutlinedButton(
                    onPressed: clinic.isOpen
                        ? () {
                            Navigator.pop(context);
                            onBookVisit?.call();
                          }
                        : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: clinic.isOpen ? AppColors.teal : const Color(0xFF94A3B8),
                      side: BorderSide(
                        color: clinic.isOpen ? AppColors.teal : const Color(0xFFE2E8F0),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Book Visit',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.teal),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
