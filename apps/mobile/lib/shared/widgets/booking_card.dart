import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/booking.dart';
import '../../theme/snip_colors.dart';
import '../../theme/snip_spacing.dart';
import 'snip_card.dart';
import 'status_chip.dart';

class BookingCard extends StatelessWidget {
  const BookingCard({
    super.key,
    required this.booking,
    this.onTap,
    this.trailing,
  });

  final Booking booking;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('EEE, MMM d').format(booking.appointmentStart.toLocal());
    final time = DateFormat('h:mm a').format(booking.appointmentStart.toLocal());
    final currency = NumberFormat.currency(symbol: 'LKR ', decimalDigits: 0);

    return SnipCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  booking.serviceName ?? 'Service',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              StatusChip(status: booking.status),
            ],
          ),
          const SizedBox(height: SnipSpacing.sm),
          Text(
            booking.salonName ?? 'Salon',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.snipMuted,
                ),
          ),
          const SizedBox(height: SnipSpacing.sm),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 14, color: context.snipMuted),
              const SizedBox(width: 4),
              Text('$date · $time', style: Theme.of(context).textTheme.bodySmall),
              const Spacer(),
              Text(
                currency.format(booking.price),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: SnipColors.primary,
                    ),
              ),
            ],
          ),
          if (booking.barberName != null) ...[
            const SizedBox(height: SnipSpacing.xs),
            Text(
              'with ${booking.barberName}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (trailing != null) ...[
            const SizedBox(height: SnipSpacing.md),
            trailing!,
          ],
        ],
      ),
    );
  }
}
