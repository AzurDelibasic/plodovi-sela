import 'package:flutter/material.dart';

import '../theme/app_surface_colors.dart';

/// The one card style used everywhere (listings, farms, orders): white,
/// rounded, a soft shadow instead of a border. Centralized so every card
/// in the app stays visually identical without copy-pasting the same
/// BoxDecoration in five places.
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final content = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: context.surfaceColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: onTap == null
          ? Padding(padding: padding, child: child)
          : Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onTap,
                child: Padding(padding: padding, child: child),
              ),
            ),
    );
    return content;
  }
}
