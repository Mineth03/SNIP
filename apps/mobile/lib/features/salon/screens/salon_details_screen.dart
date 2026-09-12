import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../repositories/favorites_repository.dart';
import '../../../repositories/salon_repository.dart';
import '../../../shared/widgets/barber_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/service_card.dart';
import '../../../shared/widgets/snip_button.dart';
import '../../../theme/snip_colors.dart';
import '../../../theme/snip_spacing.dart';
import '../../auth/providers/auth_providers.dart';

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

class SalonDetailsScreen extends ConsumerWidget {
  const SalonDetailsScreen({super.key, required this.salonId});

  final String salonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salonAsync = ref.watch(salonDetailProvider(salonId));
    final servicesAsync = ref.watch(salonServicesProvider(salonId));
    final barbersAsync = ref.watch(salonBarbersProvider(salonId));
    final profile = ref.watch(currentProfileProvider).valueOrNull;

    return salonAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
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

        final cover = salon.coverUrl ?? salon.logoUrl;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                actions: [
                  if (profile != null)
                    IconButton(
                      icon: const Icon(Icons.favorite_border),
                      onPressed: () async {
                        await ref.read(favoritesRepositoryProvider).toggleFavorite(
                              userId: profile.id,
                              salonId: salonId,
                            );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Favorites updated')),
                          );
                        }
                      },
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    salon.name,
                    style: const TextStyle(fontSize: 16),
                  ),
                  background: cover != null
                      ? CachedNetworkImage(
                          imageUrl: cover,
                          fit: BoxFit.cover,
                          color: Colors.black26,
                          colorBlendMode: BlendMode.darken,
                        )
                      : Container(color: SnipColors.primary),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(SnipSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (salon.city != null || salon.address != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: SnipColors.secondaryText,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                [salon.address, salon.city]
                                    .whereType<String>()
                                    .join(', '),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      if (salon.description != null) ...[
                        const SizedBox(height: SnipSpacing.md),
                        Text(
                          salon.description!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                      const SizedBox(height: SnipSpacing.lg),
                      Text('Services', style: Theme.of(context).textTheme.headlineSmall),
                    ],
                  ),
                ),
              ),
              servicesAsync.when(
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(SnipSpacing.md),
                    child: ListSkeleton(count: 3),
                  ),
                ),
                error: (e, _) => SliverToBoxAdapter(child: Text('$e')),
                data: (services) {
                  if (services.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: EmptyState(title: 'No services listed'),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: SnipSpacing.md),
                    sliver: SliverList.separated(
                      itemCount: services.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: SnipSpacing.sm),
                      itemBuilder: (context, index) {
                        final service = services[index];
                        return ServiceCard(
                          service: service,
                          onTap: () => context.push(
                            '/salon/$salonId/book?serviceId=${service.id}',
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(SnipSpacing.md),
                  child: Text('Team', style: Theme.of(context).textTheme.headlineSmall),
                ),
              ),
              barbersAsync.when(
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(SnipSpacing.md),
                    child: ListSkeleton(count: 2),
                  ),
                ),
                error: (e, _) => SliverToBoxAdapter(child: Text('$e')),
                data: (barbers) {
                  if (barbers.isEmpty) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      SnipSpacing.md,
                      0,
                      SnipSpacing.md,
                      100,
                    ),
                    sliver: SliverList.separated(
                      itemCount: barbers.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: SnipSpacing.sm),
                      itemBuilder: (context, index) =>
                          BarberCard(barber: barbers[index]),
                    ),
                  );
                },
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(SnipSpacing.md),
              child: PrimaryCTA(
                label: 'Book appointment',
                icon: Icons.calendar_today,
                onPressed: () => context.push('/salon/$salonId/book'),
              ),
            ),
          ),
        );
      },
    );
  }
}
