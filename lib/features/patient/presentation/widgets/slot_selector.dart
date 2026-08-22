import 'package:flutter/material.dart';
import 'package:arogyam_flutter/app/theme/app_colors.dart';
import 'package:arogyam_flutter/app/theme/app_typography.dart';

class SlotSelector extends StatefulWidget {
  const SlotSelector({super.key});

  @override
  State<SlotSelector> createState() => _SlotSelectorState();
}

class _SlotSelectorState extends State<SlotSelector> {
  String selectedSlot = '12:00 PM';

  final List<Map<String, dynamic>> slots = [
    {'time': '09:30 AM', 'status': 'unavailable'},
    {'time': '10:00 AM', 'status': 'available'},
    {'time': '10:30 AM', 'status': 'selected'},
    {'time': '11:00 AM', 'status': 'available'},
    {'time': '11:30 AM', 'status': 'unavailable'},
    {'time': '12:00 PM', 'status': 'available'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Available Slots', style: AppTypography.h2),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.5,
          ),
          itemCount: slots.length,
          itemBuilder: (context, index) {
            final slot = slots[index];
            final status = slot['status'];
            
            Color bgColor = AppColors.surface;
            Color textColor = AppColors.textPrimary;
            double opacity = 1.0;
            Border border = Border.all(color: AppColors.border);

            if (status == 'selected' || selectedSlot == slot['time']) {
              bgColor = AppColors.primary;
              textColor = Colors.white;
              border = Border.all(color: Colors.transparent);
            } else if (status == 'unavailable') {
              bgColor = AppColors.disabledBg;
              textColor = AppColors.textDisabled;
              opacity = 0.5;
            }

            return GestureDetector(
              onTap: status == 'unavailable' ? null : () {
                setState(() => selectedSlot = slot['time'] as String);
              },
              child: Opacity(
                opacity: opacity,
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                    border: border,
                  ),
                  child: Text(
                    slot['time'] as String,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
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
