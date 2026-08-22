import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../shared/entities/clinic.dart';
import '../providers/nearby_clinics_provider.dart';
import 'clinic_card.dart';

class ClinicBottomSheet extends StatelessWidget {
  final List<Clinic> clinics;

  const ClinicBottomSheet({
    super.key,
    required this.clinics,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.15,
      maxChildSize: 0.9,
      snap: true,
      snapSizes: const [0.15, 0.55, 0.9],
      builder: (context, scrollController) {
        final provider = context.watch<NearbyClinicsProvider>();

        return Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // 1. Drag handle — MUST be a direct Column child, outside the ListView
              // This ensures the handle resize the sheet when dragged.
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // 2. "Clinics Near You" + sort header row — MUST also be outside the ListView
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Clinics Near You',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    _SortDropdown(provider: provider),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // 3. ONLY the clinic cards go inside the scrollable list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: clinics.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ClinicCard(clinic: clinics[index]),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SortDropdown extends StatelessWidget {
  final NearbyClinicsProvider provider;

  const _SortDropdown({required this.provider});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SortOption>(
      onSelected: (option) => provider.sortBy(option),
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      position: PopupMenuPosition.under,
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: SortOption.distance,
          child: Text('Distance'),
        ),
        const PopupMenuItem(
          value: SortOption.waitTime,
          child: Text('Wait time'),
        ),
        const PopupMenuItem(
          value: SortOption.rating,
          child: Text('Rating'),
        ),
        const PopupMenuItem(
          value: SortOption.availability,
          child: Text('Availability'),
        ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Sort by ${provider.currentSortLabel}',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.teal,
            ),
          ),
          const SizedBox(width: 2),
          const Icon(
            LucideIcons.chevronDown,
            size: 14,
            color: AppColors.teal,
          ),
        ],
      ),
    );
  }
}
