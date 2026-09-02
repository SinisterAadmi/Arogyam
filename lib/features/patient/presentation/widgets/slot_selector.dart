import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../providers/appointment_provider.dart';

class SlotSelector extends StatelessWidget {
  const SlotSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppointmentProvider>();
    
    final List<Map<String, dynamic>> slots = [
      {'time': '09:30 AM', 'status': 'unavailable'},
      {'time': '10:00 AM', 'status': 'available'},
      {'time': '10:30 AM', 'status': 'available'},
      {'time': '11:00 AM', 'status': 'available'},
      {'time': '11:30 AM', 'status': 'unavailable'},
      {'time': '12:00 PM', 'status': 'available'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Available Slots', style: AppTypography.h2),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.2,
          ),
          itemCount: slots.length,
          itemBuilder: (context, index) {
            final slot = slots[index];
            final time = slot['time'] as String;
            final isAvailable = slot['status'] == 'available';
            final isSelected = provider.selectedSlot == time;
            
            return GestureDetector(
              onTap: isAvailable ? () => provider.setSlot(time) : null,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.teal : (isAvailable ? Colors.white : AppColors.background),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : AppColors.border,
                  ),
                ),
                child: Text(
                  time,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : (isAvailable ? AppColors.textPrimary : AppColors.textMuted),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
