import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../../app/theme/app_colors.dart';
import '../../data/models/reception_queue_models.dart';
import 'queue_status_badge.dart';

class QueuePatientCard extends StatelessWidget {
  final ReceptionQueueToken token;
  final Function(String newStatus) onUpdateStatus;

  const QueuePatientCard({
    super.key,
    required this.token,
    required this.onUpdateStatus,
  });

  String _formatTime(DateTime dt) {
    final localDt = dt.toLocal();
    final hour = localDt.hour > 12 ? localDt.hour - 12 : (localDt.hour == 0 ? 12 : localDt.hour);
    final minute = localDt.minute.toString().padLeft(2, '0');
    final period = localDt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final isServing = token.status == 'serving';
    final isWaiting = token.status == 'waiting';
    final isCancelled = token.appointmentStatus?.toLowerCase() == 'cancelled';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCancelled
            ? const Color(0xFFFEF2F2)
            : isServing
                ? const Color(0xFFF0FDF4)
                : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCancelled
              ? const Color(0xFFFCA5A5)
              : isServing
                  ? AppColors.teal
                  : AppColors.border,
          width: isServing ? 1.5 : 1,
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
          children: [
            Row(
              children: [
                // Token number badge
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isCancelled
                        ? const Color(0xFFFEE2E2)
                        : isServing
                            ? AppColors.teal
                            : AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isCancelled
                          ? const Color(0xFFFCA5A5)
                          : isServing
                              ? AppColors.teal
                              : AppColors.border,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '#${token.tokenNumber}',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            decoration: isCancelled ? TextDecoration.lineThrough : null,
                            color: isCancelled
                                ? const Color(0xFF991B1B)
                                : isServing
                                    ? Colors.white
                                    : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Patient details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        token.patientName,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          decoration: isCancelled ? TextDecoration.lineThrough : null,
                          color: isCancelled ? const Color(0xFF991B1B) : AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(LucideIcons.clock, size: 13, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Joined: ${_formatTime(token.joinedAt)}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (isCancelled)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Text(
                      'CANCELLED',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF991B1B),
                      ),
                    ),
                  )
                else
                  QueueStatusBadge(status: token.status),
              ],
            ),
            if (isWaiting || isServing) ...[
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (isWaiting) ...[
                    Expanded(
                      flex: 3,
                      child: ElevatedButton.icon(
                        onPressed: () => onUpdateStatus('serving'),
                        icon: const Icon(LucideIcons.phoneCall, size: 16),
                        label: const Text('Call / Serve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: OutlinedButton(
                        onPressed: () => onUpdateStatus('absent'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          side: BorderSide(color: Colors.red.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Absent'),
                      ),
                    ),
                  ] else if (isServing) ...[
                    Expanded(
                      flex: 3,
                      child: ElevatedButton.icon(
                        onPressed: () => onUpdateStatus('done'),
                        icon: const Icon(LucideIcons.checkCircle, size: 16),
                        label: const Text('Mark Done'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: OutlinedButton(
                        onPressed: () => onUpdateStatus('absent'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          side: BorderSide(color: Colors.red.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Absent'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
