import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/salon.dart';
import '../../../models/service.dart';
import '../../../repositories/salon_repository.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/salon_card.dart';
import '../../../shared/widgets/service_card.dart';
import '../../../shared/widgets/snip_avatar.dart';
import '../../../shared/widgets/snip_logo.dart';
import '../../../shared/widgets/snip_search_bar.dart';
import '../../../theme/snip_colors.dart';
import '../../../theme/snip_spacing.dart';
import '../../auth/providers/auth_providers.dart';

final nearbySalonsProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(salonRepositoryProvider).searchSalons(limit: 10);
});

final featuredServicesProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(salonRepositoryProvider).getFeaturedServices();
});

class CustomerHomeScreen extends ConsumerWidget {
  const CustomerHomeScreen({super.key});

  static const _categories = [
    (ServiceCategory.hair, Icons.content_cut_rounded, 'Hair'),
    (ServiceCategory.beard, Icons.face_retouching_natural_rounded, 'Beard'),
    (ServiceCategory.facial, Icons.spa_rounded, 'Facial'),
    (ServiceCategory.nails, Icons.back_hand_rounded, 'Nails'),
    (ServiceCategory.other, Icons.more_horiz_rounded, 'More'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final salonsAsync = ref.watch(nearbySalonsProvider);
    final servicesAsync = ref.watch(featuredServicesProvider);

    return Scaffold(
      backgroundColor: SnipColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: SnipColors.primary,
          onRefresh: () async {
            ref.invalidate(nearbySalonsProvider);
            ref.invalidate(featuredServicesProvider);
          },
          child: CustomScrollView(
            slivers: [
              // Top Bar with Logo, Location selector, notification bell and avatar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    SnipSpacing.md,
                    SnipSpacing.md,
                    SnipSpacing.md,
                    SnipSpacing.sm,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SnipLogo(size: 28, showTagline: false),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: SnipColors.white,
                              borderRadius:
                                  BorderRadius.circular(SnipSpacing.radiusPill),
                              border: Border.all(color: SnipColors.border),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 14,
                                  color: SnipColors.primary,
                                ),
                                SizedBox(width: 4),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Delivering beauty near you',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: SnipColors.secondaryText,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          'Colombo, Sri Lanka',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: SnipColors.dark,
                                          ),
                                        ),
                                        Icon(
                                          Icons.keyboard_arrow_down,
                                          size: 14,
                                          color: SnipColors.dark,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Stack(
                            children: [
                              IconButton(
                                onPressed: () =>
                                    context.push('/notifications'),
                                icon: const Icon(
                                  Icons.notifications_none_rounded,
                                  color: SnipColors.dark,
                                  size: 24,
                                ),
                              ),
                              Positioned(
                                top: 10,
                                right: 12,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: SnipColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => context.go('/customer/profile'),
                            child: SnipAvatar(
                              url: profile?.avatarUrl,
                              name: profile?.fullName ?? 'User',
                              size: 36,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Headline: Look Good Feel Great
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SnipSpacing.md,
                    vertical: SnipSpacing.sm,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: SnipColors.dark,
                                height: 1.15,
                              ),
                              children: [
                                TextSpan(text: 'Look Good\n'),
                                TextSpan(
                                  text: 'Feel Great',
                                  style: TextStyle(color: SnipColors.primary),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Find and book the best salons near you',
                            style: TextStyle(
                              fontSize: 13,
                              color: SnipColors.secondaryText,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: SnipColors.primaryMuted,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.spa_outlined,
                            size: 30,
                            color: SnipColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Pill Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SnipSpacing.md,
                    vertical: SnipSpacing.sm,
                  ),
                  child: SnipSearchBar(
                    readOnly: true,
                    onTap: () => context.go('/customer/explore'),
                    hint: 'Search for salons, services...',
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: SnipSpacing.md)),

              // Horizontal Category circles
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 84,
                  child: ListView.separated(
                    padding:
                        const EdgeInsets.symmetric(horizontal: SnipSpacing.md),
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: SnipSpacing.md),
                    itemBuilder: (context, index) {
                      final item = _categories[index];
                      final isFirst = index == 0;
                      return _CategoryCircleTile(
                        icon: item.$2,
                        label: item.$3,
                        isSelected: isFirst,
                        onTap: () => context.go(
                          '/customer/explore?category=${item.$1.name}',
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: SnipSpacing.lg)),

              // Featured Salons Header with See All
              SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Featured Salons',
                  onSeeAll: () => context.go('/customer/explore'),
                ),
              ),

              // Featured Salons list (Vertical cards matching inspiration)
              salonsAsync.when(
                loading: () => SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: SnipSpacing.md),
                    child: Column(
                      children: List.generate(
                        2,
                        (_) => const Padding(
                          padding: EdgeInsets.only(bottom: SnipSpacing.md),
                          child: LoadingSkeleton(height: 180),
                        ),
                      ),
                    ),
                  ),
                ),
                error: (e, _) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(SnipSpacing.md),
                    child: EmptyState(
                      title: 'Could not load salons',
                      description: '$e',
                      actionLabel: 'Try again',
                      onAction: () => ref.invalidate(nearbySalonsProvider),
                    ),
                  ),
                ),
                data: (salons) {
                  // Fallback demo items if backend has none yet
                  final displaySalons = salons.isNotEmpty
                      ? salons
                      : [
                          const Salon(
                            id: 'demo-1',
                            ownerId: 'demo',
                            name: 'The Modern Cut',
                            slug: 'the-modern-cut',
                            description: 'Modern cuts & styling',
                            city: 'Colombo 05',
                            address: 'Colombo 05',
                            verificationStatus:
                                SalonVerificationStatus.verified,
                            isActive: true,
                          ),
                          const Salon(
                            id: 'demo-2',
                            ownerId: 'demo',
                            name: 'Glow Beauty Studio',
                            slug: 'glow-beauty-studio',
                            description: 'Hair, facial and spa care',
                            city: 'Colombo 03',
                            address: 'Colombo 03',
                            verificationStatus:
                                SalonVerificationStatus.verified,
                            isActive: true,
                          ),
                        ];

                  return SliverPadding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: SnipSpacing.md),
                    sliver: SliverList.separated(
                      itemCount: displaySalons.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: SnipSpacing.md),
                      itemBuilder: (context, index) {
                        final s = displaySalons[index];
                        final isFirst = index == 0;
                        return SalonCard(
                          salon: s,
                          rating: isFirst ? 4.8 : 4.6,
                          reviewCount: isFirst ? 320 : 188,
                          distance: isFirst ? '1.2 km' : '2.1 km',
                          tags: isFirst
                              ? const ['Haircut', 'Beard', 'Styling']
                              : const ['Hair', 'Facial', 'Nails'],
                          onTap: () => context.push('/salon/${s.slug}'),
                        );
                      },
                    ),
                  );
                },
              ),

              const SliverToBoxAdapter(child: SizedBox(height: SnipSpacing.xl)),

              // Popular Services
              SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Popular Services',
                  onSeeAll: () => context.go('/customer/explore'),
                ),
              ),

              servicesAsync.when(
                loading: () => SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: SnipSpacing.md),
                    child: Column(
                      children: List.generate(
                        2,
                        (_) => const Padding(
                          padding: EdgeInsets.only(bottom: SnipSpacing.sm),
                          child: LoadingSkeleton(height: 72),
                        ),
                      ),
                    ),
                  ),
                ),
                error: (e, _) => const SliverToBoxAdapter(
                  child: SizedBox.shrink(),
                ),
                data: (services) {
                  if (services.isEmpty) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }
                  return SliverPadding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: SnipSpacing.md),
                    sliver: SliverList.separated(
                      itemCount: services.take(4).length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: SnipSpacing.sm),
                      itemBuilder: (context, index) {
                        final s = services[index];
                        return ServiceCard(
                          service: s,
                          onBook: () => context.push(
                            '/booking/${s.salonId}?serviceId=${s.id}',
                          ),
                        );
                      },
                    ),
                  );
                },
              ),

              const SliverToBoxAdapter(child: SizedBox(height: SnipSpacing.xxl)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCircleTile extends StatelessWidget {
  const _CategoryCircleTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isSelected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: isSelected ? SnipColors.primary : SnipColors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? SnipColors.primary : SnipColors.border,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: SnipColors.dark.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 24,
              color: isSelected ? SnipColors.white : SnipColors.dark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? SnipColors.primary : SnipColors.dark,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.onSeeAll,
  });

  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SnipSpacing.md,
        vertical: SnipSpacing.xs,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: SnipColors.dark,
            ),
          ),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
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
    );
  }
}
