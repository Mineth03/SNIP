import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/snip_colors.dart';
import '../../theme/theme_provider.dart';

/// An icon button that toggles between light and dark modes.
class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return IconButton(
      tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, anim) => RotationTransition(
          turns: anim,
          child: FadeTransition(opacity: anim, child: child),
        ),
        child: Icon(
          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          key: ValueKey(isDark),
          size: size,
          color: isDark ? Colors.amber : SnipColors.dark,
        ),
      ),
      onPressed: () {
        ref.read(themeModeProvider.notifier).toggleTheme();
      },
    );
  }
}

/// A ListTile with an interactive switch to toggle Dark Mode in Profile/Settings.
class ThemeModeListTile extends ConsumerWidget {
  const ThemeModeListTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return ListTile(
      leading: Icon(
        isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
        color: isDark ? Colors.amber : SnipColors.primary,
      ),
      title: const Text('Dark mode'),
      subtitle: Text(
        themeMode == ThemeMode.system
            ? 'System default (${isDark ? 'Dark' : 'Light'})'
            : (isDark ? 'On' : 'Off'),
      ),
      trailing: Switch.adaptive(
        value: isDark,
        activeThumbColor: SnipColors.primary,
        onChanged: (value) {
          ref
              .read(themeModeProvider.notifier)
              .setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
        },
      ),
      onTap: () {
        ref.read(themeModeProvider.notifier).toggleTheme();
      },
    );
  }
}
