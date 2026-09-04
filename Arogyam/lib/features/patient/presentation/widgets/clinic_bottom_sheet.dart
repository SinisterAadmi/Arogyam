import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../shared/entities/clinic.dart';
import '../../../../app/router/route_names.dart';
import '../providers/nearby_clinics_provider.dart';
import '../providers/queue_provider.dart';
import 'clinic_card.dart';
import 'clinic_about_bottom_sheet.dart';

class ClinicBottomSheet extends StatelessWidget {
  final List<Clinic> clinics;
  final void Function(Clinic)? onClinicSelected;

  const ClinicBottomSheet({
    super.key,
    required this.clinics,
    this.onClinicSelected,
  });

  Future<void> _handleJoinQueue(BuildContext context, Clinic clinic) async {
    final queueProvider = context.read<QueueProvider>();
    final success = await queueProvider.joinQueue(clinic.id);
    if (!context.mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Joined ${clinic.name} queue (#${queueProvider.status?.tokenNumber})'),
          backgroundColor: const Color(0xFF0D9488),
        ),
      );
      Navigator.of(context, rootNavigator: true).pushNamed(RouteNames.queueStatus);
    } else {
      final msg = queueProvider.errorMessage ?? 'Failed to join queue. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _handleAbout(BuildContext context, Clinic clinic) {
    ClinicAboutBottomSheet.show(
      context,
      clinic: clinic,
      onJoinQueue: () => _handleJoinQueue(context, clinic),
      onBookVisit: () {
        Navigator.of(context, rootNavigator: true).pushNamed(
          RouteNames.appointmentBooking,
          arguments: clinic,
        );
      },
    );
  }

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
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
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
                      ),
                    ),
                    _SortDropdown(provider: provider),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  children: clinics.map((clinic) {
                    final isSelected = provider.selectedClinicId == clinic.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ClinicCard(
                        clinic: clinic,
                        isSelected: isSelected,
                        onTap: () => onClinicSelected?.call(clinic),
                        onAbout: () => _handleAbout(context, clinic),
                        onJoinQueue: () => _handleJoinQueue(context, clinic),
                        onBookVisit: () {
                          Navigator.of(context, rootNavigator: true).pushNamed(
                            RouteNames.appointmentBooking,
                            arguments: clinic,
                          );
                        },
                      ),
                    );
                  }).toList(),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        const PopupMenuItem(value: SortOption.distance, child: Text('Distance')),
        const PopupMenuItem(value: SortOption.waitTime, child: Text('Wait time')),
        const PopupMenuItem(value: SortOption.rating, child: Text('Rating')),
        const PopupMenuItem(value: SortOption.availability, child: Text('Availability')),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Sort by ${provider.currentSortLabel}',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.teal),
          ),
          const SizedBox(width: 2),
          const Icon(LucideIcons.chevronDown, size: 14, color: AppColors.teal),
        ],
      ),
    );
  }
}
