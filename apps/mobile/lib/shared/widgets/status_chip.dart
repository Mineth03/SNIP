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
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(SnipSpacing.radiusPill),
      ),
      child: Text(
        _label(status),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  String _label(BookingStatus status) {
    switch (status) {
      case BookingStatus.checkedIn:
        return 'Arriving';
      default:
        return bookingStatusLabel(status);
    }
  }

  (Color, Color) _colors(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return (const Color(0xFF059669), const Color(0xFFD1FAE5));
      case BookingStatus.checkedIn:
      case BookingStatus.inProgress:
        return (const Color(0xFFEA580C), const Color(0xFFFFEDD5));
      case BookingStatus.completed:
        return (const Color(0xFF0D9488), const Color(0xFFCCFBF1));
      case BookingStatus.cancelled:
      case BookingStatus.noShow:
        return (const Color(0xFFDC2626), const Color(0xFFFEE2E2));
      case BookingStatus.pending:
        return (SnipColors.secondaryText, SnipColors.lightGray);
    }
  }
}
