import 'package:flutter/material.dart';

import '../../theme/snip_colors.dart';

enum SnipLogoVariant {
  horizontal,
  stacked,
  icon,
}

/// The official SNIP logo widget using the original brand assets.
/// Automatically switches between light mode and dark mode original assets.
class SnipLogo extends StatelessWidget {
  const SnipLogo({
    super.key,
    this.variant = SnipLogoVariant.stacked,
    this.size,
    this.showText = true,
    this.showTagline = false,
    this.textColor,
    this.primaryColor = SnipColors.primary,
    this.isDarkMode,
    this.fit = BoxFit.contain,
  });

  /// Layout variant: stacked/icon (square emblem) or horizontal (wide banner)
  final SnipLogoVariant? variant;

  /// The height of the logo in logical pixels
  final double? size;

  /// Maintained for backwards-compatibility
  final bool showText;

  /// Maintained for backwards-compatibility
  final bool showTagline;

  /// Optional text color override
  final Color? textColor;

  /// Kept for backwards compatibility
  final Color primaryColor;

  /// Explicit dark mode flag. If null, inferred from Theme brightness or textColor.
  final bool? isDarkMode;

  /// Image fit mode
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final isWhiteText = textColor != null &&
        (textColor == Colors.white ||
            textColor!.computeLuminance() > 0.7);

    final effectiveDark = isDarkMode ??
        (isWhiteText || Theme.of(context).brightness == Brightness.dark);

    final isSquare = variant != SnipLogoVariant.horizontal;
    final logoAsset = isSquare
        ? (effectiveDark
            ? 'assets/SNIP-dark-mode-logo.png'
            : 'assets/SNIP-main-logo.png')
        : (effectiveDark
            ? 'assets/long-logo-dark-mode.png'
            : 'assets/long-logo-original.png');

    final h = size ?? (isSquare ? 60.0 : 40.0);

    return SizedBox(
      height: h,
      width: isSquare ? h : null,
      child: Image.asset(
        logoAsset,
        height: h,
        width: isSquare ? h : null,
        fit: fit,
      ),
    );
  }
}
