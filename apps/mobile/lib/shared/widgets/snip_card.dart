import 'package:flutter/material.dart';

import '../../theme/snip_colors.dart';
import '../../theme/snip_spacing.dart';

class SnipCard extends StatelessWidget {
  const SnipCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: SnipColors.white,
        borderRadius: BorderRadius.circular(SnipSpacing.radiusMd),
        boxShadow: [
          BoxShadow(
            color: SnipColors.dark.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(SnipSpacing.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(SnipSpacing.radiusMd),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(SnipSpacing.md),
            child: child,
          ),
        ),
      ),
    );
    return content;
  }
}
