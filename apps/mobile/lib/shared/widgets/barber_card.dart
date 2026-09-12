import 'package:flutter/material.dart';

import '../../models/barber.dart';
import '../../theme/snip_colors.dart';
import '../../theme/snip_spacing.dart';
import 'snip_avatar.dart';
import 'snip_card.dart';

class BarberCard extends StatelessWidget {
  const BarberCard({
    super.key,
    required this.barber,
    this.onTap,
    this.selected = false,
  });

  final Barber barber;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return SnipCard(
      onTap: onTap,
      child: Row(
        children: [
          SnipAvatar(
            imageUrl: barber.avatarUrl,
            name: barber.displayName,
            size: 48,
          ),
          const SizedBox(width: SnipSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  barber.displayName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (barber.specializations.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    barber.specializations.take(2).join(' · '),
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (selected)
            const Icon(Icons.check_circle, color: SnipColors.primary)
          else
            const Icon(Icons.chevron_right, color: SnipColors.secondaryText),
        ],
      ),
    );
  }
}
