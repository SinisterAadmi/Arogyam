import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../../app/theme/app_colors.dart';
import '../../data/models/reception_queue_models.dart';

class UpcomingAppointmentCard extends StatelessWidget {
  final ReceptionUpcomingAppointment appointment;

  const UpcomingAppointmentCard({
    super.key,
    required this.appointment,
  });

  String _formatDateTime(DateTime dt) {
    final localDt = dt.toLocal();
    final hour = localDt.hour > 12 ? localDt.hour - 12 : (localDt.hour == 0 ? 12 : localDt.hour);
    final minute = localDt.minute.toString().padLeft(2, '0');
    final period = localDt.hour >= 12 ? 'PM' : 'AM';
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final dateStr = '${months[localDt.month - 1]} ${localDt.day}, ${localDt.year}';
    return '$dateStr • $hour:$minute $period';
  }

  Color _getStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'scheduled':
        return const Color(0xFFDCFCE7);
      case 'cancelled':
        return const Color(0xFFFEE2E2);
      case 'reschedule_requested':
        return const Color(0xFFFEF3C7);
      case 'pending':
      default:
        return const Color(0xFFEFF6FF);
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'scheduled':
        return const Color(0xFF166534);
      case 'cancelled':
        return const Color(0xFF991B1B);
      case 'reschedule_requested':
        return const Color(0xFF92400E);
      case 'pending':
      default:
        return const Color(0xFF1D4ED8);
    }
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
      case 'confirmed':
        return 'Confirmed';
      case 'cancelled':
        return 'Cancelled';
      case 'reschedule_requested':
        return 'Reschedule Req.';
      case 'pending':
        return 'Pending';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCancelled = appointment.status.toLowerCase() == 'cancelled';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCancelled ? const Color(0xFFFEF2F2) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCancelled ? const Color(0xFFFCA5A5) : AppColors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isCancelled ? const Color(0xFFFEE2E2) : const Color(0xFFF0FDFA),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.calendarClock,
                    color: isCancelled ? const Color(0xFF991B1B) : AppColors.teal,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.patientName,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          decoration: isCancelled ? TextDecoration.lineThrough : null,
                          color: isCancelled ? const Color(0xFF991B1B) : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Dr. ${appointment.doctorName} • ${appointment.specialty}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _getStatusBgColor(appointment.status),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getStatusTextColor(appointment.status).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    _formatStatus(appointment.status),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getStatusTextColor(appointment.status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.clock, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      _formatDateTime(appointment.scheduledAt),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (appointment.tokenNumber != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDFA),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'TOKEN #${appointment.tokenNumber}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.teal,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
