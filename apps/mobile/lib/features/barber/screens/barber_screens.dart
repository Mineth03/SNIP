import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/booking.dart';
import '../../../repositories/booking_repository.dart';
import '../../../repositories/salon_repository.dart';
import '../../../shared/widgets/booking_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/snip_button.dart';
import '../../../theme/snip_colors.dart';
import '../../../theme/snip_spacing.dart';
import '../../auth/providers/auth_providers.dart';

class BarberShell extends StatelessWidget {
  const BarberShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: navigationShell.goBranch,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            selectedIcon: Icon(Icons.event_note),
            label: 'Appointments',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner),
            selectedIcon: Icon(Icons.qr_code_scanner),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.schedule_outlined),
            selectedIcon: Icon(Icons.schedule),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

final barberProfileProvider = FutureProvider.autoDispose((ref) async {
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile == null) return null;
  return ref.watch(salonRepositoryProvider).getBarberByProfile(profile.id);
});

final barberTodayProvider = FutureProvider.autoDispose((ref) async {
  final barber = await ref.watch(barberProfileProvider.future);
  if (barber == null) return <Booking>[];
  return ref.watch(bookingRepositoryProvider).getBarberBookings(
        barber.id,
        day: DateTime.now(),
      );
});

final barberAppointmentsProvider = FutureProvider.autoDispose((ref) async {
  final barber = await ref.watch(barberProfileProvider.future);
  if (barber == null) return <Booking>[];
  return ref.watch(bookingRepositoryProvider).getBarberBookings(barber.id);
});

final barberScheduleProvider = FutureProvider.autoDispose((ref) async {
  final barber = await ref.watch(barberProfileProvider.future);
  if (barber == null) return [];
  return ref.watch(salonRepositoryProvider).getBarberSchedules(barber.id);
});

class BarberDashboardScreen extends ConsumerWidget {
  const BarberDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(barberTodayProvider);
    final profile = ref.watch(currentProfileProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(barberTodayProvider),
        child: ListView(
          padding: const EdgeInsets.all(SnipSpacing.md),
          children: [
            Text(
              'Hi ${profile?.fullName.split(' ').first ?? 'there'}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: SnipSpacing.sm),
            Text(
              "Today's appointments",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: SnipColors.secondaryText,
                  ),
            ),
            const SizedBox(height: SnipSpacing.lg),
            bookingsAsync.when(
              loading: () => const ListSkeleton(count: 3),
              error: (e, _) => Text('$e'),
              data: (bookings) {
                if (bookings.isEmpty) {
                  return const EmptyState(
                    title: 'No appointments today',
                    icon: Icons.event_available,
                  );
                }
                return Column(
                  children: bookings
                      .map(
                        (b) => Padding(
                          padding: const EdgeInsets.only(bottom: SnipSpacing.sm),
                          child: BookingCard(
                            booking: b,
                            trailing: _StatusActions(booking: b),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusActions extends ConsumerWidget {
  const _StatusActions({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final next = _nextStatus(booking.status);
    if (next == null) return const SizedBox.shrink();

    return SnipButton(
      label: bookingStatusLabel(next),
      expand: true,
      onPressed: () async {
        try {
          await ref.read(bookingRepositoryProvider).transitionStatus(
                bookingId: booking.id,
                toStatus: next,
              );
          ref.invalidate(barberTodayProvider);
          ref.invalidate(barberAppointmentsProvider);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$e')),
            );
          }
        }
      },
    );
  }

  BookingStatus? _nextStatus(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return BookingStatus.checkedIn;
      case BookingStatus.checkedIn:
        return BookingStatus.inProgress;
      case BookingStatus.inProgress:
        return BookingStatus.completed;
      default:
        return null;
    }
  }
}

class BarberAppointmentsScreen extends ConsumerWidget {
  const BarberAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(barberAppointmentsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Appointments')),
      body: async.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(SnipSpacing.md),
          child: ListSkeleton(),
        ),
        error: (e, _) => Center(child: Text('$e')),
        data: (bookings) {
          if (bookings.isEmpty) {
            return const EmptyState(title: 'No appointments');
          }
          return ListView.separated(
            padding: const EdgeInsets.all(SnipSpacing.md),
            itemCount: bookings.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: SnipSpacing.sm),
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return BookingCard(
                booking: booking,
                trailing: _StatusActions(booking: booking),
              );
            },
          );
        },
      ),
    );
  }
}

class BarberScanTab extends StatelessWidget {
  const BarberScanTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(SnipSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.qr_code_scanner, size: 72, color: SnipColors.primary),
              const SizedBox(height: SnipSpacing.md),
              Text(
                'Scan a customer QR ticket to check them in.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: SnipSpacing.lg),
              PrimaryCTA(
                label: 'Open scanner',
                icon: Icons.qr_code_scanner,
                onPressed: () => context.push('/qr/scan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BarberScheduleScreen extends ConsumerWidget {
  const BarberScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(barberScheduleProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Schedule')),
      body: async.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(SnipSpacing.md),
          child: ListSkeleton(),
        ),
        error: (e, _) => Center(child: Text('$e')),
        data: (schedules) {
          if (schedules.isEmpty) {
            return const EmptyState(
              title: 'No schedule set',
              message: 'Ask your salon owner to configure your hours.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(SnipSpacing.md),
            itemCount: schedules.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: SnipSpacing.sm),
            itemBuilder: (context, index) {
              final s = schedules[index];
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(SnipSpacing.radiusMd),
                  side: const BorderSide(color: SnipColors.border),
                ),
                title: Text(_capitalize(s.dayOfWeek)),
                subtitle: Text(
                  s.isWorking
                      ? '${s.startTime} – ${s.endTime}'
                      : 'Off',
                ),
                trailing: Icon(
                  s.isWorking ? Icons.check_circle : Icons.cancel_outlined,
                  color: s.isWorking ? SnipColors.success : SnipColors.secondaryText,
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _capitalize(String value) =>
      value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';
}

class BarberProfileScreen extends ConsumerWidget {
  const BarberProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        children: [
          ListTile(
            title: Text(profile?.fullName ?? 'Barber'),
            subtitle: Text(profile?.email ?? ''),
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Edit profile'),
            onTap: () => context.push('/profile/edit'),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications'),
            onTap: () => context.push('/notifications'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: SnipColors.error),
            title: const Text('Sign out', style: TextStyle(color: SnipColors.error)),
            onTap: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
    );
  }
}
