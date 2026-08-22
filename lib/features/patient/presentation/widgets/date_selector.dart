import 'package:flutter/material.dart';
import 'package:arogyam_flutter/app/theme/app_colors.dart';
import 'package:arogyam_flutter/app/theme/app_typography.dart';

class DateSelector extends StatefulWidget {
  const DateSelector({super.key});

  @override
  State<DateSelector> createState() => _DateSelectorState();
}

class _DateSelectorState extends State<DateSelector> {
  int selectedIndex = 1; // "Tomorrow" selected in Figma

  final List<Map<String, String>> dates = [
    {'day': 'Today', 'date': '24 Jan'},
    {'day': 'Tomorrow', 'date': '25 Jan'},
    {'day': 'Mon', 'date': '26 Jan'},
    {'day': 'Tue', 'date': '27 Jan'},
  ];

  @override
  Widget build(BuildContext context) {
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
              final isSelected = selectedIndex == index;
              return GestureDetector(
                onTap: () => setState(() => selectedIndex = index),
                child: Container(
                  width: 80,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.transparent : AppColors.border,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dates[index]['day']!,
                        style: AppTypography.labelMedium.copyWith(
                          color: isSelected ? AppColors.white : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dates[index]['date']!,
                        style: AppTypography.bodyLarge.copyWith(
                          color: isSelected ? Colors.white : AppColors.textPrimary,
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
