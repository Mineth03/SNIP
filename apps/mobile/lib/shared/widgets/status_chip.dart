import 'package:flutter/material.dart';

import '../../models/booking.dart';
import '../../theme/snip_colors.dart';
import '../../theme/snip_spacing.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, bg) = _colors(status);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SnipSpacing.sm,
        vertical: SnipSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(SnipSpacing.radiusSm),
      ),
      child: Text(
        bookingStatusLabel(status),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  (Color, Color) _colors(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return (SnipColors.primary, SnipColors.primary.withValues(alpha: 0.12));
      case BookingStatus.checkedIn:
      case BookingStatus.inProgress:
        return (SnipColors.warning, SnipColors.warning.withValues(alpha: 0.15));
      case BookingStatus.completed:
        return (SnipColors.success, SnipColors.success.withValues(alpha: 0.12));
      case BookingStatus.cancelled:
      case BookingStatus.noShow:
        return (SnipColors.error, SnipColors.error.withValues(alpha: 0.12));
      case BookingStatus.pending:
        return (SnipColors.secondaryText, SnipColors.lightGray);
    }
  }
}
