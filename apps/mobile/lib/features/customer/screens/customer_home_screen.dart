import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/service.dart';
import '../../../repositories/salon_repository.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/salon_card.dart';
import '../../../shared/widgets/service_card.dart';
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
    (ServiceCategory.hair, Icons.content_cut, 'Hair'),
    (ServiceCategory.nails, Icons.back_hand_outlined, 'Nails'),
    (ServiceCategory.facial, Icons.spa_outlined, 'Facial'),
    (ServiceCategory.massage, Icons.self_improvement_outlined, 'Massage'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final salonsAsync = ref.watch(nearbySalonsProvider);
    final servicesAsync = ref.watch(featuredServicesProvider);
    final firstName = (profile?.fullName ?? 'there').split(' ').first;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(nearbySalonsProvider);
            ref.invalidate(featuredServicesProvider);
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: AppHeader(
                  subtitle: _greeting(),
                  title: firstName,
                  avatarUrl: profile?.avatarUrl,
                  actions: [
                    IconButton(
                      onPressed: () => context.push('/notifications'),
                      icon: const Icon(Icons.notifications_none_outlined),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: SnipSpacing.md),
                  child: SnipSearchBar(
                    readOnly: true,
                    onTap: () => context.go('/customer/explore'),
                    hint: 'Find salons near you',
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: SnipSpacing.lg)),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 92,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: SnipSpacing.md),
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: SnipSpacing.sm),
                    itemBuilder: (context, index) {
                      final item = _categories[index];
                      return _CategoryTile(
                        icon: item.$2,
                        label: item.$3,
                        onTap: () => context.go(
                          '/customer/explore?category=${item.$1.name}',
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: SnipSpacing.lg)),
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Nearby salons',
                  actionLabel: 'See all',
                  onAction: () => context.go('/customer/explore'),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: SnipSpacing.sm)),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 220,
                  child: salonsAsync.when(
                    loading: () => ListView.separated(
                      padding:
                          const EdgeInsets.symmetric(horizontal: SnipSpacing.md),
                      scrollDirection: Axis.horizontal,
                      itemCount: 3,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: SnipSpacing.md),
                      itemBuilder: (_, __) => const SizedBox(
                        width: 240,
                        child: SalonCardSkeleton(),
                      ),
                    ),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.all(SnipSpacing.md),
                      child: Text('Could not load salons: $e'),
                    ),
                    data: (salons) {
                      if (salons.isEmpty) {
                        return const EmptyState(
                          title: 'No salons nearby',
                          message: 'Check back soon for verified salons.',
                          icon: Icons.storefront_outlined,
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: SnipSpacing.md,
                        ),
                        scrollDirection: Axis.horizontal,
                        itemCount: salons.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: SnipSpacing.md),
                        itemBuilder: (context, index) {
                          final salon = salons[index];
                          return SizedBox(
                            width: 240,
                            child: SalonCard(
                              salon: salon,
                              compact: true,
                              onTap: () =>
                                  context.push('/salon/${salon.id}'),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: SnipSpacing.lg)),
              const SliverToBoxAdapter(
                child: SectionHeader(title: 'Featured services'),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: SnipSpacing.sm)),
              servicesAsync.when(
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(SnipSpacing.md),
                    child: ListSkeleton(count: 3),
                  ),
                ),
                error: (e, _) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(SnipSpacing.md),
                    child: Text('$e'),
                  ),
                ),
                data: (services) {
                  if (services.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: EmptyState(
                        title: 'No featured services',
                        icon: Icons.content_cut,
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      SnipSpacing.md,
                      0,
                      SnipSpacing.md,
                      SnipSpacing.xl,
                    ),
                    sliver: SliverList.separated(
                      itemCount: services.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: SnipSpacing.sm),
                      itemBuilder: (context, index) {
                        final service = services[index];
                        return ServiceCard(
                          service: service,
                          onTap: () => context.push(
                            '/salon/${service.salonId}/book?serviceId=${service.id}',
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(SnipSpacing.radiusMd),
      child: Container(
        width: 84,
        padding: const EdgeInsets.all(SnipSpacing.sm),
        decoration: BoxDecoration(
          color: SnipColors.white,
          borderRadius: BorderRadius.circular(SnipSpacing.radiusMd),
          boxShadow: [
            BoxShadow(
              color: SnipColors.dark.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: SnipColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(SnipSpacing.radiusSm),
              ),
              child: Icon(icon, color: SnipColors.primary, size: 20),
            ),
            const SizedBox(height: SnipSpacing.sm),
            Text(label, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}
