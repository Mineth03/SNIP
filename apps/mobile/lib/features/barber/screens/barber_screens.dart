import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../models/booking.dart';
import '../../../repositories/booking_repository.dart';
import '../../../repositories/salon_repository.dart';
import '../../../shared/widgets/booking_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/snip_avatar.dart';
import '../../../shared/widgets/snip_button.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../../shared/widgets/theme_toggle_button.dart';
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

final barberTodayProvider = StreamProvider.autoDispose<List<Booking>>((ref) {
  final barber = ref.watch(barberProfileProvider).valueOrNull;
  if (barber == null) return Stream.value(<Booking>[]);
  return ref.watch(bookingRepositoryProvider).streamBarberBookings(
        barber.id,
        day: DateTime.now(),
      );
});

final barberAppointmentsProvider = StreamProvider.autoDispose<List<Booking>>((ref) {
  final barber = ref.watch(barberProfileProvider).valueOrNull;
  if (barber == null) return Stream.value(<Booking>[]);
  return ref.watch(bookingRepositoryProvider).streamBarberBookings(barber.id);
});

final barberScheduleProvider = FutureProvider.autoDispose((ref) async {
  final barber = await ref.watch(barberProfileProvider.future);
  if (barber == null) return [];
  return ref.watch(salonRepositoryProvider).getBarberSchedules(barber.id);
});

class BarberDashboardScreen extends ConsumerStatefulWidget {
  const BarberDashboardScreen({super.key});

  @override
  ConsumerState<BarberDashboardScreen> createState() =>
      _BarberDashboardScreenState();
}

class _BarberDashboardScreenState extends ConsumerState<BarberDashboardScreen> {
  int _activeFilter = 0; // 0 = Today, 1 = Upcoming

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(barberTodayProvider);
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final name = profile?.fullName.split(' ').first ?? 'Kamal';

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: SnipColors.primary,
          onRefresh: () async => ref.invalidate(barberTodayProvider),
          child: ListView(
            padding: const EdgeInsets.all(SnipSpacing.md),
            children: [
              // Header row with notification bell and avatar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, $name!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        "Let's make someone look amazing today!",
                        style: TextStyle(
                          fontSize: 13,
                          color: SnipColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const ThemeToggleButton(size: 22),
                      Stack(
                        children: [
                          IconButton(
                            onPressed: () => context.push('/notifications'),
                            icon: Icon(
                              Icons.notifications_none_rounded,
                              color: Theme.of(context).colorScheme.onSurface,
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
                      SnipAvatar(
                        url: profile?.avatarUrl,
                        name: profile?.fullName ?? 'Kamal',
                        size: 38,
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: SnipSpacing.md),

              // Filter pills: [ Today (5) ] [ Upcoming ]
              Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _activeFilter = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _activeFilter == 0
                            ? SnipColors.primary
                            : SnipColors.lightGray,
                        borderRadius:
                            BorderRadius.circular(SnipSpacing.radiusPill),
                      ),
                      child: Text(
                        'Today (5)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _activeFilter == 0
                              ? SnipColors.white
                              : SnipColors.dark,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _activeFilter = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _activeFilter == 1
                            ? SnipColors.primary
                            : SnipColors.lightGray,
                        borderRadius:
                            BorderRadius.circular(SnipSpacing.radiusPill),
                      ),
                      child: Text(
                        'Upcoming',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _activeFilter == 1
                              ? SnipColors.white
                              : SnipColors.dark,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: SnipSpacing.lg),

              // Timeline list
              bookingsAsync.when(
                loading: () => const ListSkeleton(count: 3),
                error: (e, _) => Text('$e'),
                data: (bookings) {
                  // Fallback sample appointments if none returned from DB yet
                  final list = bookings.isNotEmpty
                      ? bookings
                      : [
                          Booking(
                            id: 'b-1',
                            customerId: 'c1',
                            salonId: 's1',
                            serviceId: 'sv1',
                            barberId: 'b1',
                            appointmentStart: DateTime.now().copyWith(
                              hour: 10,
                              minute: 0,
                            ),
                            appointmentEnd: DateTime.now().copyWith(
                              hour: 10,
                              minute: 30,
                            ),
                            price: 1500,
                            status: BookingStatus.confirmed,
                            serviceName: "Men's Haircut",
                            customerName: 'James Perera',
                            qrToken: 'demo-token-1',
                          ),
                          Booking(
                            id: 'b-2',
                            customerId: 'c2',
                            salonId: 's1',
                            serviceId: 'sv2',
                            barberId: 'b1',
                            appointmentStart: DateTime.now().copyWith(
                              hour: 11,
                              minute: 30,
                            ),
                            appointmentEnd: DateTime.now().copyWith(
                              hour: 12,
                              minute: 0,
                            ),
                            price: 1000,
                            status: BookingStatus.confirmed,
                            serviceName: 'Beard Trim',
                            customerName: 'Sahan Wickrama',
                            qrToken: 'demo-token-2',
                          ),
                          Booking(
                            id: 'b-3',
                            customerId: 'c3',
                            salonId: 's1',
                            serviceId: 'sv3',
                            barberId: 'b1',
                            appointmentStart: DateTime.now().copyWith(
                              hour: 13,
                              minute: 0,
                            ),
                            appointmentEnd: DateTime.now().copyWith(
                              hour: 14,
                              minute: 0,
                            ),
                            price: 2500,
                            status: BookingStatus.checkedIn,
                            serviceName: 'Haircut + Beard',
                            customerName: 'Dinesh Silva',
                            qrToken: 'demo-token-3',
                          ),
                          Booking(
                            id: 'b-4',
                            customerId: 'c4',
                            salonId: 's1',
                            serviceId: 'sv4',
                            barberId: 'b1',
                            appointmentStart: DateTime.now().copyWith(
                              hour: 15,
                              minute: 0,
                            ),
                            appointmentEnd: DateTime.now().copyWith(
                              hour: 16,
                              minute: 0,
                            ),
                            price: 3000,
                            status: BookingStatus.confirmed,
                            serviceName: 'Hair Spa',
                            customerName: 'Tharindu Jay',
                            qrToken: 'demo-token-4',
                          ),
                          Booking(
                            id: 'b-5',
                            customerId: 'c5',
                            salonId: 's1',
                            serviceId: 'sv5',
                            barberId: 'b1',
                            appointmentStart: DateTime.now().copyWith(
                              hour: 16,
                              minute: 30,
                            ),
                            appointmentEnd: DateTime.now().copyWith(
                              hour: 17,
                              minute: 15,
                            ),
                            price: 1500,
                            status: BookingStatus.confirmed,
                            serviceName: 'Haircut',
                            customerName: 'Kasun Fernando',
                            qrToken: 'demo-token-5',
                          ),
                        ];

                  return Column(
                    children: list.map((b) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: SnipSpacing.sm),
                        child: _BarberTimelineCard(booking: b),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarberTimelineCard extends ConsumerWidget {
  const _BarberTimelineCard({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeStr =
        DateFormat('hh:mm a').format(booking.appointmentStart.toLocal());

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SnipColors.white,
        borderRadius: BorderRadius.circular(SnipSpacing.radiusMd),
        border: Border.all(color: SnipColors.border),
        boxShadow: [
          BoxShadow(
            color: SnipColors.dark.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            timeStr,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: SnipColors.dark,
            ),
          ),
          const SizedBox(width: 10),
          SnipAvatar(
            name: booking.customerName ?? 'Customer',
            size: 38,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.customerName ?? 'Customer',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: SnipColors.dark,
                  ),
                ),
                Text(
                  booking.serviceName ?? 'Service',
                  style: const TextStyle(
                    fontSize: 12,
                    color: SnipColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 4),
                StatusChip(status: booking.status),
              ],
            ),
          ),
          if (booking.status == BookingStatus.confirmed)
            OutlinedButton.icon(
              onPressed: () => context.push('/qr/scan'),
              icon: const Icon(Icons.qr_code_scanner, size: 16),
              label: const Text('Scan QR', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: SnipColors.primary,
                side: const BorderSide(color: SnipColors.primary),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                minimumSize: const Size(0, 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(SnipSpacing.radiusPill),
                ),
              ),
            )
          else if (booking.status == BookingStatus.checkedIn)
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  await ref.read(bookingRepositoryProvider).transitionStatus(
                        bookingId: booking.id,
                        toStatus: BookingStatus.inProgress,
                      );
                  ref.invalidate(barberTodayProvider);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$e')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.play_arrow_rounded, size: 16),
              label: const Text(
                'Start Service',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: SnipColors.primary,
                foregroundColor: SnipColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: const Size(0, 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(SnipSpacing.radiusPill),
                ),
              ),
            )
          else if (booking.status == BookingStatus.inProgress)
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  await ref.read(bookingRepositoryProvider).transitionStatus(
                        bookingId: booking.id,
                        toStatus: BookingStatus.completed,
                      );
                  ref.invalidate(barberTodayProvider);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$e')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.check_rounded, size: 16),
              label: const Text(
                'Complete',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: SnipColors.success,
                foregroundColor: SnipColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: const Size(0, 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(SnipSpacing.radiusPill),
                ),
              ),
            )
          else if (booking.status == BookingStatus.completed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: SnipColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(SnipSpacing.radiusPill),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded, size: 14, color: SnipColors.success),
                  SizedBox(width: 4),
                  Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: SnipColors.success,
                    ),
                  ),
                ],
              ),
            ),
        ],
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
          const ThemeModeListTile(),
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
