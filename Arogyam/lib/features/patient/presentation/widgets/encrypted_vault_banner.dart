import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_colors.dart';

class EncryptedVaultBanner extends StatelessWidget {
  const EncryptedVaultBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.teal,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.lock,
            size: 20,
            color: Colors.white,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AES-256 Encrypted Vault',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Your health records are digitally sealed and private.',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.normal,
                    color: const Color(0xFF99F6E4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
