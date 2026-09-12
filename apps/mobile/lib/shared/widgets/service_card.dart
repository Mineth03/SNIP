import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/service.dart';
import '../../theme/snip_colors.dart';
import '../../theme/snip_spacing.dart';
import 'snip_card.dart';

class ServiceCard extends StatelessWidget {
  const ServiceCard({
    super.key,
    required this.service,
    this.onTap,
    this.selected = false,
    this.trailing,
  });

  final Service service;
  final VoidCallback? onTap;
  final bool selected;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency();
    return SnipCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: selected
                  ? SnipColors.primary.withValues(alpha: 0.15)
                  : SnipColors.lightGray,
              borderRadius: BorderRadius.circular(SnipSpacing.radiusSm),
            ),
            child: Icon(
              _iconFor(service.category),
              color: SnipColors.primary,
            ),
          ),
          const SizedBox(width: SnipSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service.name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 2),
                Text(
                  '${service.durationMinutes} min · ${serviceCategoryLabel(service.category)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          trailing ??
              Text(
                currency.format(service.price),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: SnipColors.primary,
                    ),
              ),
        ],
      ),
    );
  }

  IconData _iconFor(ServiceCategory category) {
    switch (category) {
      case ServiceCategory.hair:
        return Icons.content_cut;
      case ServiceCategory.nails:
        return Icons.back_hand_outlined;
      case ServiceCategory.facial:
        return Icons.spa_outlined;
      case ServiceCategory.massage:
        return Icons.self_improvement_outlined;
      case ServiceCategory.beard:
        return Icons.face_retouching_natural;
      case ServiceCategory.color:
        return Icons.palette_outlined;
      case ServiceCategory.other:
        return Icons.miscellaneous_services_outlined;
    }
  }
}
