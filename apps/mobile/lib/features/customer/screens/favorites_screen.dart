import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../repositories/favorites_repository.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/salon_card.dart';
import '../../../theme/snip_spacing.dart';
import '../../auth/providers/auth_providers.dart';

final favoritesProvider = FutureProvider.autoDispose((ref) async {
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile == null) return [];
  return ref.watch(favoritesRepositoryProvider).getFavorites(profile.id);
});

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: favoritesAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(SnipSpacing.md),
          child: ListSkeleton(count: 3),
        ),
        error: (e, _) => Center(child: Text('$e')),
        data: (salons) {
          if (salons.isEmpty) {
            return EmptyState(
              title: 'No favorites',
              message: 'Save salons you love for quick access.',
              icon: Icons.favorite_border,
              actionLabel: 'Explore',
              onAction: () => context.go('/customer/explore'),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(favoritesProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(SnipSpacing.md),
              itemCount: salons.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: SnipSpacing.md),
              itemBuilder: (context, index) {
                final salon = salons[index];
                return SalonCard(
                  salon: salon,
                  onTap: () => context.push('/salon/${salon.id}'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
