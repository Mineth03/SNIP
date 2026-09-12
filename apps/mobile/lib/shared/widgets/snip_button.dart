import 'package:flutter/material.dart';

import '../../theme/snip_colors.dart';
import '../../theme/snip_spacing.dart';

enum SnipButtonVariant { primary, secondary, outline, text }

class SnipButton extends StatelessWidget {
  const SnipButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = SnipButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.expand = true,
    this.height = 50,
  });

  final String label;
  final VoidCallback? onPressed;
  final SnipButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final bool expand;
  final double height;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: variant == SnipButtonVariant.primary
                  ? SnipColors.white
                  : SnipColors.primary,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: SnipSpacing.sm),
              ],
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          );

    final button = switch (variant) {
      SnipButtonVariant.primary => ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: SnipColors.primary,
            foregroundColor: SnipColors.white,
            elevation: 0,
            minimumSize: Size(expand ? double.infinity : 0, height),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(SnipSpacing.radiusPill),
            ),
          ),
          child: child,
        ),
      SnipButtonVariant.secondary => ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: context.snipFill,
            foregroundColor: context.snipText,
            elevation: 0,
            minimumSize: Size(expand ? double.infinity : 0, height),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(SnipSpacing.radiusPill),
            ),
          ),
          child: child,
        ),
      SnipButtonVariant.outline => OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: context.snipText,
            side: BorderSide(color: context.snipBorder, width: 1.5),
            minimumSize: Size(expand ? double.infinity : 0, height),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(SnipSpacing.radiusPill),
            ),
          ),
          child: child,
        ),
      SnipButtonVariant.text => TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: SnipColors.primary,
            minimumSize: Size(expand ? double.infinity : 0, height),
          ),
          child: child,
        ),
    };

    if (expand) return button;
    return SizedBox(height: height, child: button);
  }
}

class PrimaryCTA extends StatelessWidget {
  const PrimaryCTA({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SnipButton(
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      icon: icon,
      variant: SnipButtonVariant.primary,
      expand: true,
    );
  }
}
