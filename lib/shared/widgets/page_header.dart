import 'package:flutter/material.dart';

class PageHeader extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final Border? border;
  final EdgeInsets padding;

  const PageHeader({
    super.key,
    required this.child,
    this.backgroundColor = Colors.white,
    this.border,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: border,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
