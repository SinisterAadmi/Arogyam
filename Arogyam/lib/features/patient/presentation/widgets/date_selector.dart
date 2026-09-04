import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../providers/appointment_provider.dart';

class DateSelector extends StatelessWidget {
  const DateSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppointmentProvider>();
    final List<DateTime> dates = List.generate(7, (index) => DateTime.now().add(Duration(days: index)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Date', style: AppTypography.h2),
        const SizedBox(height: 8),
        SizedBox(
          height: 64,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: dates.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final date = dates[index];
              final isSelected = provider.selectedDate != null &&
                  date.year == provider.selectedDate!.year &&
                  date.month == provider.selectedDate!.month &&
                  date.day == provider.selectedDate!.day;

              String dayStr;
              if (index == 0) {
                dayStr = 'Today';
              } else if (index == 1) {
                dayStr = 'Tomorrow';
              } else {
                dayStr = DateFormat('E').format(date);
              }

              return GestureDetector(
                onTap: () => provider.setDate(date),
                child: Container(
                  width: 80,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.teal : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.transparent : AppColors.border,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dayStr,
                        style: AppTypography.labelMedium.copyWith(
                          color: isSelected ? Colors.white70 : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('d MMM').format(date),
                        style: AppTypography.bodyLarge.copyWith(
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
