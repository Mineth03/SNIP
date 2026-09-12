import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../models/booking.dart';
import '../../../models/service.dart';
import '../../../repositories/booking_repository.dart';
import '../../../repositories/salon_repository.dart';
import '../../../shared/widgets/barber_card.dart';
import '../../../shared/widgets/booking_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/service_card.dart';
import '../../../shared/widgets/snip_button.dart';
import '../../../shared/widgets/snip_card.dart';
import '../../../theme/snip_colors.dart';
import '../../../theme/snip_spacing.dart';
import '../../auth/providers/auth_providers.dart';

class OwnerShell extends StatelessWidget {
  const OwnerShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/qr/scan'),
        backgroundColor: SnipColors.primary,
        foregroundColor: SnipColors.white,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scan QR'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: Icon(Icons.content_cut_outlined),
            selectedIcon: Icon(Icons.content_cut),
            label: 'Services',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Staff',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz),
            selectedIcon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
      ),
    );
  }
}

final ownerSalonProvider = FutureProvider.autoDispose((ref) async {
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile == null) return null;
  final salons =
      await ref.watch(salonRepositoryProvider).getOwnerSalons(profile.id);
  return salons.isEmpty ? null : salons.first;
});

final ownerTodayBookingsProvider = FutureProvider.autoDispose((ref) async {
  final salon = await ref.watch(ownerSalonProvider.future);
  if (salon == null) return <Booking>[];
  return ref.watch(bookingRepositoryProvider).getSalonBookings(
        salon.id,
        day: DateTime.now(),
      );
});

final ownerAllBookingsProvider = FutureProvider.autoDispose((ref) async {
  final salon = await ref.watch(ownerSalonProvider.future);
  if (salon == null) return <Booking>[];
  return ref.watch(bookingRepositoryProvider).getSalonBookings(salon.id);
});

final ownerServicesProvider = FutureProvider.autoDispose((ref) async {
  final salon = await ref.watch(ownerSalonProvider.future);
  if (salon == null) return <Service>[];
  return ref.watch(salonRepositoryProvider).getServices(salon.id);
});

final ownerStaffProvider = FutureProvider.autoDispose((ref) async {
  final salon = await ref.watch(ownerSalonProvider.future);
  if (salon == null) return [];
  return ref.watch(salonRepositoryProvider).getBarbers(salon.id);
});

class OwnerDashboardScreen extends ConsumerWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salonAsync = ref.watch(ownerSalonProvider);
    final bookingsAsync = ref.watch(ownerTodayBookingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(ownerSalonProvider);
          ref.invalidate(ownerTodayBookingsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(SnipSpacing.md),
          children: [
            salonAsync.when(
              loading: () => const LoadingSkeleton(height: 80),
              error: (e, _) => Text('$e'),
              data: (salon) => Text(
                salon?.name ?? 'Your salon',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: SnipSpacing.md),
            bookingsAsync.when(
              loading: () => const LoadingSkeleton(height: 100),
              error: (e, _) => Text('$e'),
              data: (bookings) {
                final completed = bookings
                    .where((b) => b.status == BookingStatus.completed)
                    .length;
                final upcoming = bookings
                    .where((b) =>
                        b.status == BookingStatus.confirmed ||
                        b.status == BookingStatus.checkedIn ||
                        b.status == BookingStatus.inProgress)
                    .length;

                return Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Today',
                        value: '${bookings.length}',
                        icon: Icons.event,
                      ),
                    ),
                    const SizedBox(width: SnipSpacing.sm),
                    Expanded(
                      child: _StatCard(
                        label: 'Active',
                        value: '$upcoming',
                        icon: Icons.timelapse,
                      ),
                    ),
                    const SizedBox(width: SnipSpacing.sm),
                    Expanded(
                      child: _StatCard(
                        label: 'Done',
                        value: '$completed',
                        icon: Icons.check_circle_outline,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: SnipSpacing.md),
            bookingsAsync.maybeWhen(
              data: (bookings) {
                final revenue = bookings
                    .where((b) => b.status != BookingStatus.cancelled)
                    .fold<double>(0, (sum, b) => sum + b.price);
                return SnipCard(
                  child: Row(
                    children: [
                      const Icon(Icons.payments_outlined, color: SnipColors.primary),
                      const SizedBox(width: SnipSpacing.md),
                      Expanded(
                        child: Text(
                          'Today revenue',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Text(
                        NumberFormat.simpleCurrency().format(revenue),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: SnipColors.primary,
                            ),
                      ),
                    ],
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
            const SizedBox(height: SnipSpacing.lg),
            Text('Quick actions', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: SnipSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    icon: Icons.qr_code_scanner,
                    label: 'Scan QR',
                    onTap: () => context.push('/qr/scan'),
                  ),
                ),
                const SizedBox(width: SnipSpacing.sm),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.add_business_outlined,
                    label: 'Services',
                    onTap: () => context.go('/owner/services'),
                  ),
                ),
                const SizedBox(width: SnipSpacing.sm),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.group_add_outlined,
                    label: 'Staff',
                    onTap: () => context.go('/owner/staff'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: SnipSpacing.lg),
            Text("Today's bookings", style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: SnipSpacing.sm),
            bookingsAsync.when(
              loading: () => const ListSkeleton(count: 3),
              error: (e, _) => Text('$e'),
              data: (bookings) {
                if (bookings.isEmpty) {
                  return const EmptyState(
                    title: 'No bookings today',
                    icon: Icons.event_available,
                  );
                }
                return Column(
                  children: bookings
                      .map(
                        (b) => Padding(
                          padding: const EdgeInsets.only(bottom: SnipSpacing.sm),
                          child: BookingCard(booking: b),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SnipCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: SnipColors.primary, size: 20),
          const SizedBox(height: SnipSpacing.sm),
          Text(value, style: Theme.of(context).textTheme.headlineMedium),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SnipCard(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: SnipColors.primary),
          const SizedBox(height: SnipSpacing.sm),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class OwnerBookingsScreen extends ConsumerWidget {
  const OwnerBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(ownerAllBookingsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Bookings')),
      body: async.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(SnipSpacing.md),
          child: ListSkeleton(),
        ),
        error: (e, _) => Center(child: Text('$e')),
        data: (bookings) {
          if (bookings.isEmpty) {
            return const EmptyState(title: 'No bookings yet');
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(ownerAllBookingsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(SnipSpacing.md),
              itemCount: bookings.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: SnipSpacing.sm),
              itemBuilder: (context, index) {
                final booking = bookings[index];
                return BookingCard(
                  booking: booking,
                  trailing: booking.status == BookingStatus.confirmed
                      ? SnipButton(
                          label: 'Check in',
                          expand: false,
                          onPressed: () async {
                            try {
                              await ref
                                  .read(bookingRepositoryProvider)
                                  .checkInWithQr(booking.qrToken);
                              ref.invalidate(ownerAllBookingsProvider);
                              ref.invalidate(ownerTodayBookingsProvider);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('$e')),
                                );
                              }
                            }
                          },
                        )
                      : null,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class OwnerServicesScreen extends ConsumerWidget {
  const OwnerServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(ownerServicesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Services')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateService(context, ref),
        backgroundColor: SnipColors.primary,
        child: const Icon(Icons.add, color: SnipColors.white),
      ),
      body: async.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(SnipSpacing.md),
          child: ListSkeleton(),
        ),
        error: (e, _) => Center(child: Text('$e')),
        data: (services) {
          if (services.isEmpty) {
            return EmptyState(
              title: 'No services',
              actionLabel: 'Add service',
              onAction: () => _showCreateService(context, ref),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(SnipSpacing.md),
            itemCount: services.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: SnipSpacing.sm),
            itemBuilder: (context, index) => ServiceCard(service: services[index]),
          );
        },
      ),
    );
  }

  Future<void> _showCreateService(BuildContext context, WidgetRef ref) async {
    final salon = await ref.read(ownerSalonProvider.future);
    if (salon == null || !context.mounted) return;

    final name = TextEditingController();
    final price = TextEditingController();
    final duration = TextEditingController(text: '30');
    var category = ServiceCategory.hair;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: SnipSpacing.md,
            right: SnipSpacing.md,
            top: SnipSpacing.md,
            bottom: MediaQuery.of(context).viewInsets.bottom + SnipSpacing.md,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('New service', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: SnipSpacing.md),
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: SnipSpacing.sm),
                  TextField(
                    controller: price,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Price'),
                  ),
                  const SizedBox(height: SnipSpacing.sm),
                  TextField(
                    controller: duration,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Duration (minutes)'),
                  ),
                  const SizedBox(height: SnipSpacing.sm),
                  DropdownButtonFormField<ServiceCategory>(
                    initialValue: category,
                    items: ServiceCategory.values
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(serviceCategoryLabel(c)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setModalState(() => category = v!),
                    decoration: const InputDecoration(labelText: 'Category'),
                  ),
                  const SizedBox(height: SnipSpacing.md),
                  PrimaryCTA(
                    label: 'Save',
                    onPressed: () => Navigator.pop(context, true),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    if (saved == true) {
      await ref.read(salonRepositoryProvider).createService(
            Service(
              id: '',
              salonId: salon.id,
              name: name.text.trim(),
              price: double.tryParse(price.text) ?? 0,
              durationMinutes: int.tryParse(duration.text) ?? 30,
              category: category,
            ),
          );
      ref.invalidate(ownerServicesProvider);
    }
  }
}

class OwnerStaffScreen extends ConsumerWidget {
  const OwnerStaffScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(ownerStaffProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Staff')),
      body: async.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(SnipSpacing.md),
          child: ListSkeleton(),
        ),
        error: (e, _) => Center(child: Text('$e')),
        data: (staff) {
          if (staff.isEmpty) {
            return const EmptyState(
              title: 'No staff yet',
              message: 'Add barbers from your salon dashboard.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(SnipSpacing.md),
            itemCount: staff.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: SnipSpacing.sm),
            itemBuilder: (context, index) => BarberCard(barber: staff[index]),
          );
        },
      ),
    );
  }
}

class OwnerMoreScreen extends ConsumerWidget {
  const OwnerMoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(profile?.fullName ?? 'Owner'),
            subtitle: Text(profile?.email ?? ''),
          ),
          ListTile(
            leading: const Icon(Icons.qr_code_scanner),
            title: const Text('Scan check-in QR'),
            onTap: () => context.push('/qr/scan'),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications'),
            onTap: () => context.push('/notifications'),
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Edit profile'),
            onTap: () => context.push('/profile/edit'),
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
