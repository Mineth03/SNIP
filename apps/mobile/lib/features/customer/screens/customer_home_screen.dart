import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/salon.dart';
import '../../../models/service.dart';
import '../../../models/user_activity.dart';
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
import '../../../theme/theme_provider.dart';
import '../../auth/providers/auth_providers.dart';

class UserLocationState {
  const UserLocationState({
    required this.name,
    required this.district,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final String district;
  final double latitude;
  final double longitude;
}

const defaultLocations = [
  UserLocationState(
    name: 'Colombo 05',
    district: 'Havelock / Thimbirigasyaya',
    latitude: 6.8918,
    longitude: 79.8732,
  ),
  UserLocationState(
    name: 'Colombo 03',
    district: 'Kollupitiya',
    latitude: 6.9034,
    longitude: 79.8542,
  ),
  UserLocationState(
    name: 'Kandy Central',
    district: 'Central Province',
    latitude: 7.2906,
    longitude: 80.6337,
  ),
  UserLocationState(
    name: 'Galle Fort',
    district: 'Southern Province',
    latitude: 6.0535,
    longitude: 80.2210,
  ),
  UserLocationState(
    name: 'Negombo Beach',
    district: 'Western Province',
    latitude: 7.2088,
    longitude: 79.8358,
  ),
  UserLocationState(
    name: 'Kurunegala City',
    district: 'North Western Province',
    latitude: 7.4863,
    longitude: 80.3623,
  ),
];

final userLocationProvider = StateProvider<UserLocationState>((ref) {
  return defaultLocations.first;
});

final nearbySalonsProvider = FutureProvider.autoDispose((ref) {
  final loc = ref.watch(userLocationProvider);
  return ref.watch(salonRepositoryProvider).getNearbySalons(
        latitude: loc.latitude,
        longitude: loc.longitude,
        radiusKm: 50,
        limit: 10,
      );
});

final recommendedSalonsProvider = FutureProvider.autoDispose((ref) {
  final loc = ref.watch(userLocationProvider);
  final profile = ref.watch(currentProfileProvider).valueOrNull;
  return ref.watch(salonRepositoryProvider).getPersonalizedRecommendations(
        userId: profile?.id,
        latitude: loc.latitude,
        longitude: loc.longitude,
        limit: 6,
      );
});

final userRecentActivityProvider = FutureProvider.autoDispose((ref) {
  final profile = ref.watch(currentProfileProvider).valueOrNull;
  if (profile == null) return Future.value(<UserRecentActivity>[]);
  return ref.watch(salonRepositoryProvider).getUserRecentActivity(
        userId: profile.id,
        limit: 5,
      );
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

  void _showLocationPicker(BuildContext context, WidgetRef ref) {
    final currentLocation = ref.read(userLocationProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: context.snipCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(SnipSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: SnipColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.my_location,
                        color: SnipColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Choose Location',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: context.snipText,
                            ),
                          ),
                          Text(
                            'Find top-rated salons closest to you',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.snipMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: SnipSpacing.md),
                const Divider(),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: defaultLocations.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final loc = defaultLocations[i];
                      final isSelected = loc.name == currentLocation.name;
                      return ListTile(
                        leading: Icon(
                          isSelected ? Icons.check_circle : Icons.location_city_outlined,
                          color: isSelected ? SnipColors.primary : SnipColors.secondaryText,
                        ),
                        title: Text(
                          loc.name,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected ? SnipColors.primary : context.snipText,
                          ),
                        ),
                        subtitle: Text(
                          loc.district,
                          style: const TextStyle(
                            fontSize: 12,
                            color: SnipColors.secondaryText,
                          ),
                        ),
                        trailing: isSelected
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: SnipColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(
                                    SnipSpacing.radiusPill,
                                  ),
                                ),
                                child: const Text(
                                  'Current',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: SnipColors.primary,
                                  ),
                                ),
                              )
                            : null,
                        onTap: () {
                          ref.read(userLocationProvider.notifier).state = loc;
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final selectedLocation = ref.watch(userLocationProvider);
    final salonsAsync = ref.watch(nearbySalonsProvider);
    final recommendedAsync = ref.watch(recommendedSalonsProvider);
    final recentActivitiesAsync = ref.watch(userRecentActivityProvider);
    final servicesAsync = ref.watch(featuredServicesProvider);

    return Scaffold(
      backgroundColor: context.snipScaffold,
      body: SafeArea(
        child: RefreshIndicator(
          color: SnipColors.primary,
          onRefresh: () async {
            ref.invalidate(nearbySalonsProvider);
            ref.invalidate(recommendedSalonsProvider);
            ref.invalidate(userRecentActivityProvider);
            ref.invalidate(featuredServicesProvider);
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _CustomerHomeHeader(
                  location: selectedLocation,
                  avatarUrl: profile?.avatarUrl,
                  avatarName: profile?.fullName ?? 'User',
                  onLocationTap: () => _showLocationPicker(context, ref),
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
                            text: TextSpan(
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: context.snipText,
                                height: 1.15,
                              ),
                              children: const [
                                TextSpan(text: 'Look Good\n'),
                                TextSpan(
                                  text: 'Feel Great',
                                  style: TextStyle(color: SnipColors.primary),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Find and book the best salons near you',
                            style: TextStyle(
                              fontSize: 13,
                              color: context.snipMuted,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: context.snipPrimarySoft,
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

              // Recent Activity Ribbon
              recentActivitiesAsync.when(
                data: (activities) {
                  if (activities.isEmpty) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: SnipSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: SnipSpacing.md,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.history_rounded,
                                  size: 14,
                                  color: SnipColors.primary,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'RECENT ACTIVITY',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                    color: SnipColors.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 32,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: SnipSpacing.md,
                              ),
                              itemCount: activities.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, i) {
                                final act = activities[i];
                                return InkWell(
                                  onTap: () {
                                    if (act.salonSlug != null) {
                                      context.push('/salon/${act.salonSlug}');
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(
                                    SnipSpacing.radiusPill,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: context.snipCard,
                                      borderRadius: BorderRadius.circular(
                                        SnipSpacing.radiusPill,
                                      ),
                                      border:
                                          Border.all(color: context.snipBorder),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: SnipColors.primary,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          act.displayTitle,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: context.snipText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (_, __) =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: SnipSpacing.lg)),

              // Recommended For You Header
              SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Recommended For You',
                  onSeeAll: () => context.go('/customer/explore'),
                ),
              ),

              // Recommended Salons List
              recommendedAsync.when(
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
                error: (_, __) =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
                data: (recs) {
                  if (recs.isEmpty) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }
                  return SliverPadding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: SnipSpacing.md),
                    sliver: SliverList.separated(
                      itemCount: recs.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: SnipSpacing.md),
                      itemBuilder: (context, index) {
                        final s = recs[index];
                        return SalonCard(
                          salon: s,
                          onTap: () => context.push('/salon/${s.slug}'),
                        );
                      },
                    ),
                  );
                },
              ),

              const SliverToBoxAdapter(child: SizedBox(height: SnipSpacing.lg)),

              // Salons Near You Header with See All
              SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Salons Near ${selectedLocation.name}',
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

class _CustomerHomeHeader extends ConsumerWidget {
  const _CustomerHomeHeader({
    required this.location,
    required this.avatarUrl,
    required this.avatarName,
    required this.onLocationTap,
  });

  final UserLocationState location;
  final String? avatarUrl;
  final String avatarName;
  final VoidCallback onLocationTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SnipSpacing.md,
        SnipSpacing.md,
        SnipSpacing.md,
        SnipSpacing.sm,
      ),
      child: Column(
        children: [
          SizedBox(
            height: 40,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SnipLogo(
                  variant: SnipLogoVariant.stacked,
                  size: 40,
                ),
                const Spacer(),
                _HomeHeaderIcon(
                  icon: isDark
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                  color: isDark ? Colors.amber : onSurface,
                  tooltip: isDark
                      ? 'Switch to light mode'
                      : 'Switch to dark mode',
                  onTap: () =>
                      ref.read(themeModeProvider.notifier).toggleTheme(),
                ),
                const SizedBox(width: 2),
                _HomeHeaderIcon(
                  icon: Icons.notifications_none_rounded,
                  color: onSurface,
                  tooltip: 'Notifications',
                  showBadge: true,
                  onTap: () => context.push('/notifications'),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => context.go('/customer/profile'),
                  child: SnipAvatar(
                    url: avatarUrl,
                    name: avatarName,
                    size: 40,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Material(
            color: Theme.of(context).cardTheme.color ?? context.snipCard,
            borderRadius: BorderRadius.circular(SnipSpacing.radiusLg),
            child: InkWell(
              onTap: onLocationTap,
              borderRadius: BorderRadius.circular(SnipSpacing.radiusLg),
              child: Container(
                width: double.infinity,
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(SnipSpacing.radiusLg),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: context.snipPrimarySoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        size: 16,
                        color: SnipColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Delivering beauty near you',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.2,
                              color: SnipColors.secondaryText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${location.name}, Sri Lanka',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.2,
                              fontWeight: FontWeight.w700,
                              color: onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 22,
                      color: onSurface,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeHeaderIcon extends StatelessWidget {
  const _HomeHeaderIcon({
    required this.icon,
    required this.onTap,
    this.color,
    this.tooltip,
    this.showBadge = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final String? tooltip;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, size: 22, color: color),
              if (showBadge)
                const Positioned(
                  top: 8,
                  right: 8,
                  child: SizedBox(
                    width: 8,
                    height: 8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: SnipColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
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
              color: isSelected ? SnipColors.primary : context.snipCard,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? SnipColors.primary : context.snipBorder,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: SnipColors.dark.withValues(
                    alpha: context.isDark ? 0.28 : 0.04,
                  ),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 24,
              color: isSelected ? SnipColors.white : context.snipText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? SnipColors.primary : context.snipText,
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
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: context.snipText,
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
