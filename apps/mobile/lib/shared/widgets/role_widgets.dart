import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/profile.dart';
import '../../repositories/profile_repository.dart';
import '../../theme/snip_colors.dart';
import '../../theme/snip_spacing.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../routing/route_guards.dart';

class RoleSwitcherCard extends ConsumerWidget {
  const RoleSwitcherCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    if (profile == null) return const SizedBox.shrink();

    final hats = <({UserRole role, IconData icon, String description})>[
      (
        role: UserRole.customer,
        icon: Icons.person_outline,
        description: 'Book salons and manage appointments',
      ),
      (
        role: UserRole.salonOwner,
        icon: Icons.storefront_outlined,
        description: 'Manage your salon, staff, and bookings',
      ),
      (
        role: UserRole.barber,
        icon: Icons.content_cut,
        description: 'Chair schedule, check-ins, and clients',
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(SnipSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Switch profile view',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'One account can hold multiple roles.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: SnipColors.secondaryText,
                  ),
            ),
            const SizedBox(height: SnipSpacing.sm),
            ...hats.map((hat) {
              final available = profile.capabilities.contains(hat.role);
              final active = profile.effectiveActiveRole == hat.role;
              return Padding(
                padding: const EdgeInsets.only(bottom: SnipSpacing.xs),
                child: ListTile(
                  enabled: available,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(SnipSpacing.radiusSm),
                    side: BorderSide(
                      color: active
                          ? SnipColors.primary
                          : SnipColors.border,
                    ),
                  ),
                  leading: Icon(
                    hat.icon,
                    color: active ? SnipColors.primary : null,
                  ),
                  title: Text(userRoleLabel(hat.role)),
                  subtitle: Text(
                    available
                        ? hat.description
                        : hat.role == UserRole.salonOwner
                            ? 'Use “Become a salon owner” below to unlock.'
                            : 'Ask a salon owner to invite you.',
                  ),
                  trailing: active
                      ? const Text(
                          'Active',
                          style: TextStyle(
                            color: SnipColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        )
                      : null,
                  onTap: !available || active
                      ? null
                      : () async {
                          try {
                            await ref
                                .read(profileRepositoryProvider)
                                .setActiveRole(hat.role);
                            ref.invalidate(currentProfileProvider);
                            if (context.mounted) {
                              context.go(homePathForRole(hat.role));
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('$e')),
                              );
                            }
                          }
                        },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class BecomeOwnerCard extends ConsumerStatefulWidget {
  const BecomeOwnerCard({super.key});

  @override
  ConsumerState<BecomeOwnerCard> createState() => _BecomeOwnerCardState();
}

class _BecomeOwnerCardState extends ConsumerState<BecomeOwnerCard> {
  final _name = TextEditingController();
  final _city = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    if (profile == null || profile.isOwner) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(SnipSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Become a salon owner',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'List your salon without creating a new account.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: SnipColors.secondaryText,
                  ),
            ),
            const SizedBox(height: SnipSpacing.sm),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Salon name'),
            ),
            TextField(
              controller: _city,
              decoration: const InputDecoration(labelText: 'City (optional)'),
            ),
            TextField(
              controller: _phone,
              decoration: const InputDecoration(labelText: 'Phone (optional)'),
            ),
            TextField(
              controller: _address,
              decoration:
                  const InputDecoration(labelText: 'Address (optional)'),
            ),
            const SizedBox(height: SnipSpacing.sm),
            FilledButton(
              onPressed: _loading
                  ? null
                  : () async {
                      if (_name.text.trim().length < 2) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Salon name is required'),
                          ),
                        );
                        return;
                      }
                      setState(() => _loading = true);
                      try {
                        await ref
                            .read(profileRepositoryProvider)
                            .becomeSalonOwner(
                              name: _name.text.trim(),
                              city: _city.text.trim().isEmpty
                                  ? null
                                  : _city.text.trim(),
                              phone: _phone.text.trim().isEmpty
                                  ? null
                                  : _phone.text.trim(),
                              address: _address.text.trim().isEmpty
                                  ? null
                                  : _address.text.trim(),
                            );
                        ref.invalidate(currentProfileProvider);
                        if (context.mounted) {
                          context.go('/owner/dashboard');
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$e')),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _loading = false);
                      }
                    },
              child: Text(_loading ? 'Creating...' : 'Create salon & switch'),
            ),
          ],
        ),
      ),
    );
  }
}

class BarberSalonSwitcher extends ConsumerWidget {
  const BarberSalonSwitcher({
    super.key,
    required this.memberships,
    required this.activeSalonId,
  });

  final List<({String salonId, String salonName, String barberId})> memberships;
  final String activeSalonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (memberships.isEmpty) return const SizedBox.shrink();
    if (memberships.length == 1) {
      return Padding(
        padding: const EdgeInsets.only(bottom: SnipSpacing.sm),
        child: Text(
          'Salon: ${memberships.first.salonName}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: SnipColors.secondaryText,
              ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: SnipSpacing.sm),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Working at:',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: SnipColors.secondaryText,
                  fontWeight: FontWeight.bold,
                ),
          ),
          ...memberships.map((m) {
            final selected = m.salonId == activeSalonId;
            return ChoiceChip(
              label: Text(m.salonName),
              selected: selected,
              onSelected: selected
                  ? null
                  : (_) async {
                      try {
                        await ref
                            .read(profileRepositoryProvider)
                            .setActiveBarberSalon(m.salonId);
                        ref.invalidate(currentProfileProvider);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$e')),
                          );
                        }
                      }
                    },
            );
          }),
        ],
      ),
    );
  }
}
