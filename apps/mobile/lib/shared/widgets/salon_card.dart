import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/salon.dart';
import '../../theme/snip_colors.dart';
import '../../theme/snip_spacing.dart';
import 'snip_card.dart';

class SalonCard extends StatelessWidget {
  const SalonCard({
    super.key,
    required this.salon,
    this.onTap,
    this.compact = false,
    this.rating = 4.8,
    this.reviewCount = 320,
    this.distance = '1.2 km',
    this.tags = const ['Haircut', 'Beard', 'Styling'],
  });

  final Salon salon;
  final VoidCallback? onTap;
  final bool compact;
  final double rating;
  final int reviewCount;
  final String distance;
  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    final image = salon.coverUrl ?? salon.logoUrl;

    return SnipCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(SnipSpacing.radiusLg),
                ),
                child: SizedBox(
                  height: compact ? 110 : 150,
                  width: double.infinity,
                  child: image != null && image.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: image,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: SnipColors.lightGray),
                          errorWidget: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: SnipColors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: SnipColors.dark.withValues(alpha: 0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.favorite_border,
                    size: 18,
                    color: SnipColors.dark,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(SnipSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        salon.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: SnipColors.dark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (salon.verificationStatus ==
                        SalonVerificationStatus.verified)
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(
                          Icons.verified,
                          size: 16,
                          color: SnipColors.primary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: Color(0xFFFBBF24),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: SnipColors.dark,
                      ),
                    ),
                    Text(
                      ' ($reviewCount)',
                      style: const TextStyle(
                        fontSize: 12,
                        color: SnipColors.secondaryText,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: const BoxDecoration(
                        color: SnipColors.secondaryText,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${salon.city ?? salon.address ?? 'Colombo 05'} • $distance',
                        style: const TextStyle(
                          fontSize: 12,
                          color: SnipColors.secondaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (!compact && tags.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: tags.take(3).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: SnipColors.lightGray,
                          borderRadius:
                              BorderRadius.circular(SnipSpacing.radiusPill),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: SnipColors.secondaryText,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            SnipColors.primary.withValues(alpha: 0.15),
            SnipColors.primary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.storefront_outlined,
          color: SnipColors.primary,
          size: 38,
        ),
      ),
    );
  }
}
