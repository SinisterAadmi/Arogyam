import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class QueueStatusBadge extends StatelessWidget {
  final String status;

  const QueueStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;
    String label;

    switch (status.toLowerCase()) {
      case 'serving':
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF2563EB);
        icon = LucideIcons.stethoscope;
        label = 'Now Serving';
        break;
      case 'done':
        bg = const Color(0xFFF0FDF4);
        fg = const Color(0xFF16A34A);
        icon = LucideIcons.checkCircle2;
        label = 'Completed';
        break;
      case 'absent':
        bg = const Color(0xFFFEF2F2);
        fg = const Color(0xFFDC2626);
        icon = LucideIcons.userX;
        label = 'Absent / Skipped';
        break;
      case 'waiting':
      default:
        bg = const Color(0xFFFFFBEB);
        fg = const Color(0xFFD97706);
        icon = LucideIcons.clock;
        label = 'Waiting';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: fg.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
