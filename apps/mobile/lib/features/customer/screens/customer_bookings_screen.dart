import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../repositories/booking_repository.dart';
import '../../../shared/widgets/booking_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../theme/snip_spacing.dart';
import '../../auth/providers/auth_providers.dart';

final customerBookingsProvider = FutureProvider.autoDispose((ref) async {
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile == null) return [];
  return ref.watch(bookingRepositoryProvider).getCustomerBookings(profile.id);
});

class CustomerBookingsScreen extends ConsumerWidget {
  const CustomerBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(customerBookingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My bookings')),
      body: bookingsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(SnipSpacing.md),
          child: ListSkeleton(count: 4),
        ),
        error: (e, _) => Center(child: Text('$e')),
        data: (bookings) {
          if (bookings.isEmpty) {
            return EmptyState(
              title: 'No bookings yet',
              message: 'Explore salons and book your next appointment.',
              icon: Icons.calendar_month_outlined,
              actionLabel: 'Explore',
              onAction: () => context.go('/customer/explore'),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(customerBookingsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(SnipSpacing.md),
              itemCount: bookings.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: SnipSpacing.md),
              itemBuilder: (context, index) {
                final booking = bookings[index];
                return BookingCard(
                  booking: booking,
                  onTap: () => context.push('/booking/${booking.id}/ticket'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
