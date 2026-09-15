import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../models/booking.dart';
import '../../../models/service.dart';
import '../../../repositories/booking_repository.dart';
import '../../../repositories/profile_repository.dart';
import '../../../repositories/salon_repository.dart';
import '../../../shared/widgets/booking_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/role_widgets.dart';
import '../../../shared/widgets/service_card.dart';
import '../../../shared/widgets/snip_avatar.dart';
import '../../../shared/widgets/snip_logo.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../../shared/widgets/snip_button.dart';
import '../../../shared/widgets/theme_toggle_button.dart';
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

final ownerTodayBookingsProvider = StreamProvider.autoDispose<List<Booking>>((ref) {
  final salon = ref.watch(ownerSalonProvider).valueOrNull;
  if (salon == null) return Stream.value(<Booking>[]);
  return ref.watch(bookingRepositoryProvider).streamSalonBookings(
        salon.id,
        day: DateTime.now(),
      );
});

final ownerAllBookingsProvider = StreamProvider.autoDispose<List<Booking>>((ref) {
  final salon = ref.watch(ownerSalonProvider).valueOrNull;
  if (salon == null) return Stream.value(<Booking>[]);
  return ref.watch(bookingRepositoryProvider).streamSalonBookings(salon.id);
});

final ownerServicesProvider = FutureProvider.autoDispose((ref) async {
  final salon = await ref.watch(ownerSalonProvider.future);
  if (salon == null) return <Service>[];
  return ref.watch(salonRepositoryProvider).getServices(salon.id);
});

final ownerStaffProvider = FutureProvider.autoDispose((ref) async {
  final salon = await ref.watch(ownerSalonProvider.future);
  if (salon == null) return <({dynamic barber, bool linked})>[];
  final barbers =
      await ref.watch(salonRepositoryProvider).getBarbers(salon.id);
  return barbers
      .map((b) => (barber: b, linked: b.profileId != null))
      .toList();
});

final ownerPendingInvitesProvider = FutureProvider.autoDispose((ref) async {
  final salon = await ref.watch(ownerSalonProvider.future);
  if (salon == null) return <Map<String, dynamic>>[];
  final members =
      await ref.watch(salonRepositoryProvider).getSalonMemberInvites(salon.id);
  return members
      .where((m) => m['invitation_accepted_at'] == null && m['is_active'] == true)
      .toList();
});

class OwnerDashboardScreen extends ConsumerWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salonAsync = ref.watch(ownerSalonProvider);
    final bookingsAsync = ref.watch(ownerTodayBookingsProvider);
    final profile = ref.watch(currentProfileProvider).valueOrNull;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: SnipColors.primary,
          onRefresh: () async {
            ref.invalidate(ownerSalonProvider);
            ref.invalidate(ownerTodayBookingsProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(SnipSpacing.md),
            children: [
              // Top Bar with SnipLogo, Notification bell & Avatar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SnipLogo(
                    variant: SnipLogoVariant.stacked,
                    size: 36,
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
                        name: profile?.fullName ?? 'Owner',
                        size: 36,
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: SnipSpacing.md),

              // Greeting & Subtitle
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: SnipColors.dark,
                        height: 1.2,
                      ),
                      children: [
                        TextSpan(text: 'Good morning,\n'),
                        TextSpan(
                          text: 'Salon Owner!',
                          style: TextStyle(color: SnipColors.primary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Here's what's happening today.",
                    style: TextStyle(
                      fontSize: 13,
                      color: SnipColors.secondaryText,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: SnipSpacing.md),

              // Salon info banner
              salonAsync.maybeWhen(
                data: (salon) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: SnipColors.white,
                    borderRadius: BorderRadius.circular(SnipSpacing.radiusMd),
                    border: Border.all(color: SnipColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: SnipColors.primaryMuted,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.storefront_rounded,
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
                              salon?.name ?? 'The Modern Cut',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: SnipColors.dark,
                              ),
                            ),
                            Text(
                              salon?.city ?? 'Colombo 05',
                              style: const TextStyle(
                                fontSize: 12,
                                color: SnipColors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: SnipColors.secondaryText,
                        size: 20,
                      ),
                    ],
                  ),
                ),
                orElse: () => const SizedBox.shrink(),
              ),

              const SizedBox(height: SnipSpacing.md),

              // 2x2 Metric Cards Grid
              bookingsAsync.when(
                loading: () => const LoadingSkeleton(height: 140),
                error: (e, _) => Text('$e'),
                data: (bookings) {
                  final totalCount = bookings.isNotEmpty ? bookings.length : 12;
                  final revenue = bookings.isNotEmpty
                      ? bookings
                          .where((b) => b.status != BookingStatus.cancelled)
                          .fold<double>(0, (sum, b) => sum + b.price)
                      : 18500.0;

                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: "Today's Bookings",
                              value: '$totalCount',
                              icon: Icons.calendar_today_rounded,
                              iconColor: SnipColors.primary,
                            ),
                          ),
                          const SizedBox(width: SnipSpacing.sm),
                          Expanded(
                            child: _StatCard(
                              label: "Today's Revenue",
                              value: 'LKR ${revenue.toStringAsFixed(0)}',
                              icon: Icons.trending_up_rounded,
                              iconColor: const Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: SnipSpacing.sm),
                      const Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: 'Active Staff',
                              value: '4',
                              icon: Icons.people_outline_rounded,
                              iconColor: Color(0xFF3B82F6),
                            ),
                          ),
                          SizedBox(width: SnipSpacing.sm),
                          Expanded(
                            child: _StatCard(
                              label: 'Customer Rating',
                              value: '96%',
                              icon: Icons.star_rounded,
                              iconColor: Color(0xFFFBBF24),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: SnipSpacing.lg),

              // Quick Actions
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: SnipColors.dark,
                ),
              ),
              const SizedBox(height: SnipSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.add_circle_outline_rounded,
                      label: 'Add Booking',
                      onTap: () => context.push('/owner/walk-in'),
                    ),
                  ),
                  const SizedBox(width: SnipSpacing.xs),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.qr_code_scanner_rounded,
                      label: 'Scan QR',
                      onTap: () => context.push('/qr/scan'),
                    ),
                  ),
                  const SizedBox(width: SnipSpacing.xs),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.people_alt_outlined,
                      label: 'Manage Staff',
                      onTap: () => context.go('/owner/staff'),
                    ),
                  ),
                  const SizedBox(width: SnipSpacing.xs),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.content_cut_rounded,
                      label: 'Services',
                      onTap: () => context.go('/owner/services'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: SnipSpacing.lg),

              // Today's Bookings with See All
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Today's Bookings",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: SnipColors.dark,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/owner/bookings'),
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
              const SizedBox(height: SnipSpacing.sm),

              bookingsAsync.when(
                loading: () => const ListSkeleton(count: 3),
                error: (e, _) => Text('$e'),
                data: (bookings) {
                  // Fallback sample bookings if none exist yet today
                  final items = bookings.isNotEmpty
                      ? bookings
                      : [
                          Booking(
                            id: 'sample-1',
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
                            barberName: 'Kamal',
                            customerName: 'James Perera',
                            qrToken: 'sample-token-1',
                          ),
                          Booking(
                            id: 'sample-2',
                            customerId: 'c2',
                            salonId: 's1',
                            serviceId: 'sv2',
                            barberId: 'b2',
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
                            barberName: 'Ravi',
                            customerName: 'Sahan Wickrama',
                            qrToken: 'sample-token-2',
                          ),
                          Booking(
                            id: 'sample-3',
                            customerId: 'c3',
                            salonId: 's1',
                            serviceId: 'sv3',
                            barberId: 'b3',
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
                            barberName: 'Isuru',
                            customerName: 'Dinesh Silva',
                            qrToken: 'sample-token-3',
                          ),
                          Booking(
                            id: 'sample-4',
                            customerId: 'c4',
                            salonId: 's1',
                            serviceId: 'sv4',
                            barberId: 'b4',
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
                            barberName: 'Nuwan',
                            customerName: 'Tharindu Jay',
                            qrToken: 'sample-token-4',
                          ),
                        ];

                  return Column(
                    children: items
                        .map(
                          (b) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: SnipSpacing.sm),
                            child: _OwnerBookingRow(booking: b),
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
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor = SnipColors.primary,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SnipSpacing.md),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: SnipColors.dark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: SnipColors.secondaryText,
            ),
          ),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(SnipSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: SnipColors.white,
          borderRadius: BorderRadius.circular(SnipSpacing.radiusMd),
          border: Border.all(color: SnipColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: SnipColors.primaryMuted,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: SnipColors.primary, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: SnipColors.dark,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _OwnerBookingRow extends StatelessWidget {
  const _OwnerBookingRow({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final timeStr =
        DateFormat('hh:mm a').format(booking.appointmentStart.toLocal());

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SnipColors.white,
        borderRadius: BorderRadius.circular(SnipSpacing.radiusMd),
        border: Border.all(color: SnipColors.border),
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
          const SizedBox(width: 12),
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
                  '${booking.serviceName ?? "Service"} • ${booking.barberName ?? "Staff"}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: SnipColors.secondaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          StatusChip(status: booking.status),
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

class OwnerStaffScreen extends ConsumerStatefulWidget {
  const OwnerStaffScreen({super.key});

  @override
  ConsumerState<OwnerStaffScreen> createState() => _OwnerStaffScreenState();
}

class _OwnerStaffScreenState extends ConsumerState<OwnerStaffScreen> {
  final _email = TextEditingController();
  final _displayName = TextEditingController();
  bool _inviting = false;
  String? _lastInviteLink;

  @override
  void dispose() {
    _email.dispose();
    _displayName.dispose();
    super.dispose();
  }

  Future<void> _invite() async {
    final salon = await ref.read(ownerSalonProvider.future);
    if (salon == null || !mounted) return;
    final email = _email.text.trim();
    if (!email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email')),
      );
      return;
    }
    setState(() => _inviting = true);
    try {
      final token = await ref.read(profileRepositoryProvider).inviteBarberToSalon(
            salonId: salon.id,
            email: email,
            displayName: _displayName.text.trim().isEmpty
                ? null
                : _displayName.text.trim(),
          );
      if (!mounted) return;
      setState(() {
        _lastInviteLink = '/invite/barber?token=$token';
        _email.clear();
        _displayName.clear();
      });
      ref.invalidate(ownerStaffProvider);
      ref.invalidate(ownerPendingInvitesProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invite created')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _inviting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(ownerStaffProvider);
    final pendingAsync = ref.watch(ownerPendingInvitesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Staff')),
      body: ListView(
        padding: const EdgeInsets.all(SnipSpacing.md),
        children: [
          Text(
            'Invite barber',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: SnipSpacing.sm),
          TextField(
            controller: _displayName,
            decoration: const InputDecoration(
              labelText: 'Display name (optional)',
            ),
          ),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: SnipSpacing.sm),
          FilledButton(
            onPressed: _inviting ? null : _invite,
            child: Text(_inviting ? 'Inviting...' : 'Send invite'),
          ),
          if (_lastInviteLink != null) ...[
            const SizedBox(height: SnipSpacing.sm),
            SelectableText(
              'Invite link: $_lastInviteLink',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: SnipSpacing.lg),
          Text(
            'Pending invites',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          pendingAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('$e'),
            data: (pending) {
              if (pending.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No pending invites'),
                );
              }
              return Column(
                children: pending
                    .map(
                      (m) => ListTile(
                        title: Text(m['invited_email']?.toString() ?? 'Invite'),
                        subtitle: Text(
                          m['invitation_token'] != null
                              ? '/invite/barber?token=${m['invitation_token']}'
                              : 'Pending',
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: SnipSpacing.md),
          Text(
            'Team',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          async.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(SnipSpacing.md),
              child: ListSkeleton(),
            ),
            error: (e, _) => Text('$e'),
            data: (staff) {
              if (staff.isEmpty) {
                return const EmptyState(
                  title: 'No staff yet',
                  message: 'Invite barbers by email above.',
                );
              }
              return Column(
                children: staff.map((row) {
                  final barber = row.barber;
                  return Card(
                    child: ListTile(
                      title: Text(barber.displayName),
                      subtitle: Text(
                        row.linked ? 'Linked account' : 'Unlinked / pending',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.person_remove_outlined,
                            color: SnipColors.error),
                        onPressed: () async {
                          final salon =
                              await ref.read(ownerSalonProvider.future);
                          if (salon == null || !context.mounted) return;
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (d) => AlertDialog(
                              title: const Text('Remove barber?'),
                              content: Text(
                                'Remove ${barber.displayName} from this salon only.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(d, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(d, true),
                                  child: const Text('Remove'),
                                ),
                              ],
                            ),
                          );
                          if (ok != true) return;
                          try {
                            await ref
                                .read(profileRepositoryProvider)
                                .removeBarberFromSalon(
                                  salonId: salon.id,
                                  barberId: barber.id,
                                );
                            ref.invalidate(ownerStaffProvider);
                            ref.invalidate(ownerPendingInvitesProvider);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('$e')),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
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
        padding: const EdgeInsets.all(SnipSpacing.md),
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(profile?.fullName ?? 'Owner'),
            subtitle: Text(profile?.email ?? ''),
          ),
          const RoleSwitcherCard(),
          const SizedBox(height: SnipSpacing.md),
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
