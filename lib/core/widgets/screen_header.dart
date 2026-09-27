import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_surface_colors.dart';

/// The flat, minimal header used at the top of every in-app screen —
/// replaces the earlier full-gradient hero block. Title is large and bold,
/// an optional subtitle sits under it in muted text, and [actions] sit at
/// the trailing edge.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (leading != null) leading!,
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: leading == null ? 8 : 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: Theme.of(
                      context,
                    ).textTheme.headlineMedium?.copyWith(fontSize: 26),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!,
                        style: TextStyle(
                          color: context.surfaceColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}

/// A neutral, circular icon-button used in headers (cart, logout, back) —
/// a soft grey chip instead of a raw IconButton, so trailing actions read
/// as tappable without needing color to say so.
class HeaderIconButton extends StatelessWidget {
  const HeaderIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.badgeCount = 0,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final surfaceColors = context.surfaceColors;
    final button = Material(
      color: surfaceColors.background,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20, color: surfaceColors.textPrimary),
        ),
      ),
    );

    if (badgeCount <= 0) {
      return Tooltip(message: tooltip ?? '', child: button);
    }

    return Tooltip(
      message: tooltip ?? '',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          button,
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.all(3),
              constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$badgeCount',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
