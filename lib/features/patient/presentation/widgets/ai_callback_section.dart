import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:arogyam_flutter/app/theme/app_colors.dart';
import 'package:arogyam_flutter/app/theme/app_typography.dart';
import 'package:arogyam_flutter/core/mixins/polling_mixin.dart';
import '../../../ai_callback/presentation/providers/ai_callback_provider.dart';

class AICallbackSection extends StatefulWidget {
  const AICallbackSection({super.key});

  @override
  State<AICallbackSection> createState() => _AICallbackSectionState();
}

class _AICallbackSectionState extends State<AICallbackSection>
    with WidgetsBindingObserver, PollingMixin<AICallbackSection> {
  @override
  Duration get pollingInterval => const Duration(seconds: 25);

  @override
  Future<void> onPoll() async {
    if (!mounted) return;
    final callbackProvider = context.read<AiCallbackProvider>();
    if (callbackProvider.isRequested) {
      await callbackProvider.fetchStatus();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AiCallbackProvider>().fetchStatus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final callbackProvider = context.watch<AiCallbackProvider>();
    final isRequested = callbackProvider.isRequested;
    final isLoading = callbackProvider.isLoading;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRequested ? const Color(0xFFF0FDF4) : AppColors.iconBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRequested ? Colors.green.shade300 : AppColors.secondary,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isRequested ? LucideIcons.phoneIncoming : LucideIcons.phoneCall,
                    size: 20,
                    color: isRequested ? Colors.green.shade700 : AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Request AI Voice Callback',
                    style: AppTypography.bodyLarge.copyWith(
                      color: isRequested ? Colors.green.shade800 : AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (isLoading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                )
              else
                Switch.adaptive(
                  value: isRequested,
                  activeTrackColor: AppColors.primary,
                  onChanged: (value) async {
                    try {
                      if (value) {
                        final reqId = await callbackProvider.requestCallback(
                          clinicId: '1',
                          phone: '9876543210',
                          scheduledAt: DateTime.now().toIso8601String(),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('AI Voice Callback requested! (ID: ${reqId ?? "Pending"})'),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        }
                      } else {
                        await callbackProvider.cancelCallback();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('AI Callback cancelled'),
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Callback operation failed: $e'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Can't find your ideal time? Our automated AI medical coordinator will call you to secure slot changes instantly.",
            style: AppTypography.bodySmall,
          ),
          if (isRequested) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.clock, size: 15, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Status: Call Pending • Coordinator will call within 15 mins',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                            await callbackProvider.cancelCallback();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('AI Callback cancelled')),
                              );
                            }
                          },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Cancel',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
