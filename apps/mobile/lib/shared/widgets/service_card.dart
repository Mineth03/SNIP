import 'package:flutter/material.dart';

import '../../models/service.dart';
import '../../theme/snip_colors.dart';
import '../../theme/snip_spacing.dart';
import 'snip_card.dart';

class ServiceCard extends StatelessWidget {
  const ServiceCard({
    super.key,
    required this.service,
    this.onTap,
    this.onBook,
    this.selected = false,
    this.trailing,
  });

  final Service service;
  final VoidCallback? onTap;
  final VoidCallback? onBook;
  final bool selected;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final effectiveOnTap = onTap ?? onBook;

    return SnipCard(
      onTap: effectiveOnTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: selected
                  ? SnipColors.primaryMuted
                  : SnipColors.lightGray,
              borderRadius: BorderRadius.circular(SnipSpacing.radiusMd),
            ),
            child: Icon(
              _iconFor(service.category),
              color: SnipColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: SnipSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: SnipColors.dark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${service.durationMinutes} mins · ${serviceCategoryLabel(service.category)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: SnipColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          trailing ??
              Text(
                'LKR ${service.price.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: SnipColors.dark,
                ),
              ),
        ],
      ),
    );
  }

  IconData _iconFor(ServiceCategory category) {
    switch (category) {
      case ServiceCategory.hair:
        return Icons.content_cut_rounded;
      case ServiceCategory.nails:
        return Icons.back_hand_rounded;
      case ServiceCategory.facial:
        return Icons.spa_rounded;
      case ServiceCategory.massage:
        return Icons.self_improvement_rounded;
      case ServiceCategory.beard:
        return Icons.face_retouching_natural_rounded;
      case ServiceCategory.color:
        return Icons.palette_rounded;
      case ServiceCategory.other:
        return Icons.miscellaneous_services_rounded;
    }
  }
}
