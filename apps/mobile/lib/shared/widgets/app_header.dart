import 'package:flutter/material.dart';

import '../../theme/snip_colors.dart';
import '../../theme/snip_spacing.dart';
import 'snip_avatar.dart';
import 'theme_toggle_button.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.avatarUrl,
    this.actions,
    this.onAvatarTap,
    this.showThemeToggle = false,
  });

  final String title;
  final String? subtitle;
  final String? avatarUrl;
  final List<Widget>? actions;
  final VoidCallback? onAvatarTap;
  final bool showThemeToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SnipSpacing.md,
        SnipSpacing.sm,
        SnipSpacing.md,
        SnipSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),
          ),
          if (showThemeToggle) const ThemeToggleButton(size: 22),
          if (actions != null) ...actions!,
          if (avatarUrl != null || onAvatarTap != null)
            GestureDetector(
              onTap: onAvatarTap,
              child: SnipAvatar(imageUrl: avatarUrl, name: title, size: 40),
            ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SnipSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: const TextStyle(color: SnipColors.primary),
              ),
            ),
        ],
      ),
    );
  }
}
