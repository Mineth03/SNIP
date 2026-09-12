import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/service.dart';
import '../../../repositories/salon_repository.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/salon_card.dart';
import '../../../shared/widgets/snip_search_bar.dart';
import '../../../theme/snip_spacing.dart';

final exploreQueryProvider = StateProvider.autoDispose<String>((ref) => '');
final exploreCategoryProvider =
    StateProvider.autoDispose<ServiceCategory?>((ref) => null);

final exploreSalonsProvider = FutureProvider.autoDispose((ref) {
  final query = ref.watch(exploreQueryProvider);
  final category = ref.watch(exploreCategoryProvider);
  return ref.watch(salonRepositoryProvider).searchSalons(
        query: query.isEmpty ? null : query,
        category: category,
      );
});

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key, this.initialCategory});

  final String? initialCategory;

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    if (widget.initialCategory != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(exploreCategoryProvider.notifier).state =
            serviceCategoryFromString(widget.initialCategory);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final salonsAsync = ref.watch(exploreSalonsProvider);
    final selectedCategory = ref.watch(exploreCategoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Explore')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(SnipSpacing.md),
            child: SnipSearchBar(
              controller: _controller,
              hint: 'Search salons or services',
              onChanged: (value) =>
                  ref.read(exploreQueryProvider.notifier).state = value,
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: SnipSpacing.md),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: SnipSpacing.sm),
                  child: FilterChip(
                    label: const Text('All'),
                    selected: selectedCategory == null,
                    onSelected: (_) =>
                        ref.read(exploreCategoryProvider.notifier).state = null,
                  ),
                ),
                ...[ServiceCategory.hair, ServiceCategory.nails, ServiceCategory.facial, ServiceCategory.massage]
                    .map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(right: SnipSpacing.sm),
                    child: FilterChip(
                      label: Text(serviceCategoryLabel(c)),
                      selected: selectedCategory == c,
                      onSelected: (_) =>
                          ref.read(exploreCategoryProvider.notifier).state = c,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: SnipSpacing.md),
          Expanded(
            child: salonsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(SnipSpacing.md),
                child: ListSkeleton(count: 5),
              ),
              error: (e, _) => Center(child: Text('$e')),
              data: (salons) {
                if (salons.isEmpty) {
                  return const EmptyState(
                    title: 'No results',
                    message: 'Try a different search or category.',
                    icon: Icons.search_off,
                  );
                }
                return ListView.separated(
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
