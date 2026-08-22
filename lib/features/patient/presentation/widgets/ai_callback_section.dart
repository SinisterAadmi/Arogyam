import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:arogyam_flutter/app/theme/app_colors.dart';
import 'package:arogyam_flutter/app/theme/app_typography.dart';

class AICallbackSection extends StatefulWidget {
  const AICallbackSection({super.key});

  @override
  State<AICallbackSection> createState() => _AICallbackSectionState();
}

class _AICallbackSectionState extends State<AICallbackSection> {
  bool isEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.iconBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.secondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SvgPicture.network(
                    'https://www.figma.com/api/mcp/asset/da96a64f-1e5e-41ad-8b5c-cc2343b9ff88.svg',
                    width: 18,
                    height: 18,
                    colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Request AI Voice Callback',
                    style: AppTypography.bodyLarge.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
              Switch.adaptive(
                value: isEnabled,
                activeTrackColor: AppColors.primary,
                onChanged: (value) {
                  setState(() => isEnabled = value);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Can't find your ideal time? Our automated AI medical coordinator will call you to secure slot changes instantly.",
            style: AppTypography.bodySmall,
          ),
        ],
      ),
    );
  }
}
