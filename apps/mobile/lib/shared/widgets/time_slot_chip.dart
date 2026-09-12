import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../theme/snip_colors.dart';
import '../../theme/snip_spacing.dart';

class TimeSlotChip extends StatelessWidget {
  const TimeSlotChip({
    super.key,
    required this.time,
    this.selected = false,
    this.onTap,
    this.enabled = true,
  });

  final DateTime time;
  final bool selected;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final label = DateFormat('h:mm a').format(time.toLocal());
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: SnipSpacing.md,
          vertical: SnipSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: selected
              ? SnipColors.primary
              : enabled
                  ? SnipColors.white
                  : SnipColors.lightGray,
          borderRadius: BorderRadius.circular(SnipSpacing.radiusSm),
          border: Border.all(
            color: selected
                ? SnipColors.primary
                : enabled
                    ? SnipColors.border
                    : SnipColors.lightGray,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected
                    ? SnipColors.white
                    : enabled
                        ? SnipColors.dark
                        : SnipColors.secondaryText,
              ),
        ),
      ),
    );
  }
}
