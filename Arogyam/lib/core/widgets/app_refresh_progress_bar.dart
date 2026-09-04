import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// A subtle 2px progress bar that appears during background refresh/polling
/// and disappears as soon as the refresh finishes or errors out.
class AppRefreshProgressBar extends StatelessWidget {
  final bool isRefreshing;

  const AppRefreshProgressBar({
    super.key,
    required this.isRefreshing,
  });

  @override
  Widget build(BuildContext context) {
    if (!isRefreshing) {
      return const SizedBox(height: 2);
    }
    return const LinearProgressIndicator(
      minHeight: 2,
      backgroundColor: Colors.transparent,
      valueColor: AlwaysStoppedAnimation<Color>(AppColors.teal),
    );
  }
}
