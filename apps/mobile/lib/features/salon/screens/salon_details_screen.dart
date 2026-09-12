import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/service.dart';
import '../../../repositories/review_repository.dart';
import '../../../repositories/salon_repository.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/favorite_button.dart';
import '../../../shared/widgets/snip_avatar.dart';
import '../../../shared/widgets/snip_button.dart';
import '../../../theme/snip_colors.dart';
import '../../../theme/snip_spacing.dart';

final salonDetailProvider =
    FutureProvider.autoDispose.family((ref, String salonId) {
  return ref.watch(salonRepositoryProvider).getSalon(salonId);
});

final salonServicesProvider =
    FutureProvider.autoDispose.family((ref, String salonId) {
  return ref.watch(salonRepositoryProvider).getServices(salonId);
});

final salonBarbersProvider =
    FutureProvider.autoDispose.family((ref, String salonId) {
  return ref.watch(salonRepositoryProvider).getBarbers(salonId);
});

class SalonDetailsScreen extends ConsumerStatefulWidget {
  const SalonDetailsScreen({super.key, required this.salonId});

  final String salonId;

  @override
  ConsumerState<SalonDetailsScreen> createState() => _SalonDetailsScreenState();
}

class _SalonDetailsScreenState extends ConsumerState<SalonDetailsScreen> {
  int _activeTab = 0;
  String? _selectedServiceId;

  static const _tabs = ['Services', 'Barbers', 'Reviews', 'About'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(salonRepositoryProvider).logUserActivity(
            activityType: 'view_salon',
            salonId: widget.salonId,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final salonAsync = ref.watch(salonDetailProvider(widget.salonId));
    final servicesAsync = ref.watch(salonServicesProvider(widget.salonId));
    final barbersAsync = ref.watch(salonBarbersProvider(widget.salonId));

    return salonAsync.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: SnipColors.primary),
        ),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('$e')),
      ),
      data: (salon) {
        if (salon == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyState(title: 'Salon not found'),
          );
        }

        return Scaffold(
          backgroundColor: context.snipScaffold,
          appBar: AppBar(
            backgroundColor: context.snipCard,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => context.pop(),
            ),
            title: Text(
              salon.name,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.snipText,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined, size: 22),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Link copied to clipboard')),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: SnipFavoriteButton(salonId: widget.salonId, size: 20),
              ),
            ],
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.all(SnipSpacing.md),
            decoration: BoxDecoration(
              color: context.snipCard,
              border: Border(top: BorderSide(color: context.snipBorder)),
              boxShadow: [
                BoxShadow(
                  color: context.snipText.withValues(alpha: context.isDark ? 0.3 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: SnipButton(
                label: 'Book Appointment',
                icon: Icons.calendar_month_rounded,
                onPressed: () {
                  final serviceQuery = _selectedServiceId != null
                      ? '?serviceId=$_selectedServiceId'
                      : '';
                  context.push('/booking/${salon.id}$serviceQuery');
                },
              ),
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Salon subtitle info
                Container(
                  color: context.snipCard,
                  padding: const EdgeInsets.symmetric(
                    horizontal: SnipSpacing.md,
                    vertical: SnipSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 18,
                        color: Color(0xFFFBBF24),
                      ),
                      const SizedBox(width: 4),
                        Text(
                        '4.8',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: context.snipText,
                        ),
                      ),
                        Text(
                        ' (320 reviews)',
                        style: TextStyle(
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
                          '${salon.city ?? salon.address ?? 'Colombo 05'} • Open till 9:00 PM',
                          style: TextStyle(
                            fontSize: 12,
                            color: SnipColors.secondaryText,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // 3 Photo Thumbnails Gallery
                Container(
                  color: context.snipCard,
                  padding: const EdgeInsets.fromLTRB(
                    SnipSpacing.md,
                    0,
                    SnipSpacing.md,
                    SnipSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(SnipSpacing.radiusMd),
                          child: Container(
                            height: 110,
                            color: context.snipFill,
                            child: salon.coverUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: salon.coverUrl!,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) =>
                                        _galleryFallback(1),
                                  )
                                : _galleryFallback(1),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(SnipSpacing.radiusMd),
                          child: Container(
                            height: 110,
                            color: context.snipFill,
                            child: _galleryFallback(2),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(SnipSpacing.radiusMd),
                          child: Container(
                            height: 110,
                            color: context.snipFill,
                            child: _galleryFallback(3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 2),

                // Horizontal Tab selection pills
                Container(
                  color: context.snipCard,
                  padding: const EdgeInsets.symmetric(
                    horizontal: SnipSpacing.md,
                    vertical: SnipSpacing.sm,
                  ),
                  child: Row(
                    children: List.generate(_tabs.length, (index) {
                      final title = _tabs[index];
                      final isSelected = _activeTab == index;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _activeTab = index),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? SnipColors.primary
                                  : context.snipFill,
                              borderRadius:
                                  BorderRadius.circular(SnipSpacing.radiusPill),
                            ),
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? SnipColors.white
                                    : context.snipText,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                const SizedBox(height: SnipSpacing.md),

                // Tab Content: Services (0)
                if (_activeTab == 0) ...[
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: SnipSpacing.md),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                          Text(
                          'Popular Services',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: context.snipText,
                          ),
                        ),
                        Text(
                          'See All',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: SnipColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: SnipSpacing.sm),
                  servicesAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(SnipSpacing.md),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: SnipColors.primary,
                        ),
                      ),
                    ),
                    error: (e, _) => Center(child: Text('$e')),
                    data: (services) {
                      final displayServices = services.isNotEmpty
                          ? services
                          : [
                              Service(
                                id: 'demo-s1',
                                salonId: salon.id,
                                name: "Men's Haircut",
                                description: 'Wash & style included',
                                category: ServiceCategory.hair,
                                price: 1500,
                                durationMinutes: 30,
                                isActive: true,
                              ),
                              Service(
                                id: 'demo-s2',
                                salonId: salon.id,
                                name: 'Beard Trim',
                                description: 'Precision styling',
                                category: ServiceCategory.beard,
                                price: 1000,
                                durationMinutes: 20,
                                isActive: true,
                              ),
                              Service(
                                id: 'demo-s3',
                                salonId: salon.id,
                                name: 'Hair Wash',
                                description: 'Shampoo & conditioner',
                                category: ServiceCategory.hair,
                                price: 800,
                                durationMinutes: 15,
                                isActive: true,
                              ),
                            ];

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: SnipSpacing.md,
                          vertical: SnipSpacing.xs,
                        ),
                        itemCount: displayServices.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final s = displayServices[index];
                          final isSelected = _selectedServiceId == s.id;
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: context.snipCard,
                              borderRadius:
                                  BorderRadius.circular(SnipSpacing.radiusMd),
                              border: Border.all(
                                color: isSelected
                                    ? SnipColors.primary
                                    : SnipColors.border,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: context.snipPrimarySoft,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.content_cut_rounded,
                                    color: SnipColors.primary,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.name,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: context.snipText,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${s.durationMinutes} mins',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: SnipColors.secondaryText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  'LKR ${s.price.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: context.snipText,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedServiceId =
                                          isSelected ? null : s.id;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(
                                    SnipSpacing.radiusPill,
                                  ),
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? SnipColors.primary
                                          : context.snipPrimarySoft,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isSelected
                                          ? Icons.check
                                          : Icons.add_rounded,
                                      color: isSelected
                                          ? SnipColors.white
                                          : SnipColors.primary,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),

                  // Barbers Row
                  const SizedBox(height: SnipSpacing.lg),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: SnipSpacing.md),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                          Text(
                          'Choose Your Barber',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: context.snipText,
                          ),
                        ),
                        InkWell(
                          onTap: () => setState(() => _activeTab = 1),
                          child: const Text(
                            'See All',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: SnipColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: SnipSpacing.sm),
                  barbersAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (barbers) {
                      return SizedBox(
                        height: 100,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: SnipSpacing.md,
                          ),
                          scrollDirection: Axis.horizontal,
                          itemCount: barbers.isNotEmpty ? barbers.length : 1,
                          separatorBuilder: (_, __) => const SizedBox(width: 16),
                          itemBuilder: (context, index) {
                            final barberName = barbers.isNotEmpty
                                ? barbers[index].displayName
                                : 'Kamal Perera';
                            return Column(
                              children: [
                                SnipAvatar(
                                  name: barberName,
                                  size: 52,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  barberName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: context.snipText,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],

                // Tab Content: Barbers (1)
                if (_activeTab == 1) ...[
                  barbersAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(color: SnipColors.primary),
                      ),
                    ),
                    error: (e, _) => Center(child: Text('$e')),
                    data: (barbers) {
                      if (barbers.isEmpty) {
                        return const EmptyState(
                          title: 'No stylists listed yet',
                          description: 'Stylists will be available soon.',
                        );
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: SnipSpacing.md),
                        itemCount: barbers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: SnipSpacing.sm),
                        itemBuilder: (ctx, i) {
                          final b = barbers[i];
                          return Container(
                            padding: const EdgeInsets.all(SnipSpacing.md),
                            decoration: BoxDecoration(
                              color: context.snipCard,
                              borderRadius: BorderRadius.circular(SnipSpacing.radiusMd),
                              border: Border.all(color: context.snipBorder),
                            ),
                            child: Row(
                              children: [
                                SnipAvatar(
                                  imageUrl: b.avatarUrl,
                                  name: b.displayName,
                                  size: 48,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        b.displayName,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: context.snipText,
                                        ),
                                      ),
                                      if (b.specializations.isNotEmpty)
                                        Text(
                                          b.specializations.join(', '),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: SnipColors.secondaryText,
                                          ),
                                        ),
                                      if (b.bio != null && b.bio!.isNotEmpty)
                                        Text(
                                          b.bio!,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: SnipColors.textMuted,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],

                // Tab Content: Reviews (2)
                if (_activeTab == 2) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: SnipSpacing.md),
                    child: Container(
                      padding: const EdgeInsets.all(SnipSpacing.md),
                      decoration: BoxDecoration(
                        color: context.snipCard,
                        borderRadius: BorderRadius.circular(SnipSpacing.radiusLg),
                        border: Border.all(color: context.snipBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 36, color: Color(0xFFFBBF24)),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                salon.avgRating > 0 ? salon.avgRating.toStringAsFixed(1) : 'New',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: context.snipText,
                                ),
                              ),
                              Text(
                                '${salon.reviewCount} ${salon.reviewCount == 1 ? "review" : "reviews"}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: SnipColors.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: SnipSpacing.md),
                  ref.watch(salonReviewsProvider(salon.id)).when(
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: CircularProgressIndicator(color: SnipColors.primary),
                          ),
                        ),
                        error: (e, _) => Center(child: Text('$e')),
                        data: (reviews) {
                          if (reviews.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(24.0),
                              child: Center(
                                child: Text(
                                  'No reviews yet. Be the first to review after your visit!',
                                  style: TextStyle(color: SnipColors.secondaryText, fontSize: 13),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          }
                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: SnipSpacing.md),
                            itemCount: reviews.length,
                            separatorBuilder: (_, __) => const SizedBox(height: SnipSpacing.sm),
                            itemBuilder: (ctx, i) {
                              final r = reviews[i];
                              return Container(
                                padding: const EdgeInsets.all(SnipSpacing.md),
                                decoration: BoxDecoration(
                                  color: context.snipCard,
                                  borderRadius: BorderRadius.circular(SnipSpacing.radiusMd),
                                  border: Border.all(color: context.snipBorder),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        SnipAvatar(
                                          imageUrl: r.customerAvatarUrl,
                                          name: r.customerName ?? 'Guest',
                                          size: 32,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            r.customerName ?? 'Verified Client',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: context.snipText,
                                            ),
                                          ),
                                        ),
                                        Row(
                                          children: List.generate(
                                            5,
                                            (sIdx) => Icon(
                                              Icons.star_rounded,
                                              size: 14,
                                              color: sIdx < r.rating
                                                  ? const Color(0xFFFBBF24)
                                                  : SnipColors.border,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (r.comment != null && r.comment!.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        r.comment!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: context.snipText,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                ],

                // Tab Content: About (3)
                if (_activeTab == 3) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: SnipSpacing.md),
                    child: Container(
                      padding: const EdgeInsets.all(SnipSpacing.md),
                      decoration: BoxDecoration(
                        color: context.snipCard,
                        borderRadius: BorderRadius.circular(SnipSpacing.radiusLg),
                        border: Border.all(color: context.snipBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Text(
                            'About the Salon',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: context.snipText,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            salon.description ??
                                'Experience the highest standard in barbering and styling with SNIP.',
                            style: TextStyle(
                              fontSize: 13,
                              color: SnipColors.secondaryText,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),
                          if (salon.address != null || salon.city != null) ...[
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 18, color: SnipColors.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    [salon.address, salon.city].where((s) => s != null && s.isNotEmpty).join(', '),
                                    style: TextStyle(fontSize: 13, color: context.snipText),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (salon.phone != null) ...[
                            Row(
                              children: [
                                const Icon(Icons.phone_outlined, size: 18, color: SnipColors.primary),
                                const SizedBox(width: 8),
                                Text(
                                  salon.phone!,
                                  style: TextStyle(fontSize: 13, color: context.snipText),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: SnipSpacing.xl),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _galleryFallback(int index) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            SnipColors.dark.withValues(alpha: 0.05 + index * 0.03),
            SnipColors.primary.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.chair_rounded,
          color: SnipColors.secondaryText.withValues(alpha: 0.5),
          size: 28,
        ),
      ),
    );
  }
}
