import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/salon.dart';
import '../../theme/snip_colors.dart';
import '../../theme/snip_spacing.dart';
import 'favorite_button.dart';
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
    final effectiveRating = salon.avgRating > 0 ? salon.avgRating : rating;
    final effectiveReviews = salon.reviewCount > 0 ? salon.reviewCount : reviewCount;
    final formattedDistance = salon.distanceKm != null
        ? (salon.distanceKm! < 1
            ? '${(salon.distanceKm! * 1000).round()} m away'
            : '${salon.distanceKm!.toStringAsFixed(1)} km away')
        : distance;

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
                              Container(color: context.snipFill),
                          errorWidget: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: SnipFavoriteButton(salonId: salon.id, size: 16),
              ),
              if (salon.distanceKm != null)
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: SnipColors.dark.withValues(alpha: 0.8),
                      borderRadius:
                          BorderRadius.circular(SnipSpacing.radiusPill),
                      border: Border.all(
                        color: SnipColors.primary.withValues(alpha: 0.6),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.near_me,
                          size: 11,
                          color: SnipColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formattedDistance,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
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
                if (salon.recommendationReason != null &&
                    salon.recommendationReason!.isNotEmpty) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: SnipColors.primary.withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(SnipSpacing.radiusPill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          size: 12,
                          color: SnipColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            salon.recommendationReason!,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: SnipColors.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        salon.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: context.snipText,
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
                      effectiveRating.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: context.snipText,
                      ),
                    ),
                    Text(
                      ' ($effectiveReviews)',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.snipMuted,
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
                        '${salon.city ?? salon.address ?? 'Colombo 05'} • $formattedDistance',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.snipMuted,
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
                          color: context.snipFill,
                          borderRadius:
                              BorderRadius.circular(SnipSpacing.radiusPill),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: context.snipMuted,
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
