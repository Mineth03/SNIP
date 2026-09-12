import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../models/barber.dart';
import '../../../shared/widgets/barber_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/service_card.dart';
import '../../../shared/widgets/snip_button.dart';
import '../../../shared/widgets/time_slot_chip.dart';
import '../../../theme/snip_colors.dart';
import '../../../theme/snip_spacing.dart';
import '../providers/booking_providers.dart';

class BookingFlowScreen extends ConsumerStatefulWidget {
  const BookingFlowScreen({
    super.key,
    required this.salonId,
    this.initialServiceId,
  });

  final String salonId;
  final String? initialServiceId;

  @override
  ConsumerState<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends ConsumerState<BookingFlowScreen> {
  int _step = 0;
  bool _confirming = false;
  final _notes = TextEditingController();
  bool _seeded = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  void _seedServiceIfNeeded() {
    if (_seeded || widget.initialServiceId == null) return;
    final services = ref.read(bookingServicesProvider(widget.salonId)).valueOrNull;
    if (services == null) return;
    final match = services.where((s) => s.id == widget.initialServiceId);
    if (match.isNotEmpty) {
      ref
          .read(bookingDraftProvider(widget.salonId).notifier)
          .selectService(match.first);
      _step = 1;
    }
    _seeded = true;
  }

  Future<void> _confirm() async {
    setState(() => _confirming = true);
    try {
      ref.read(bookingDraftProvider(widget.salonId).notifier).setNotes(_notes.text);
      final booking =
          await ref.read(bookingDraftProvider(widget.salonId).notifier).confirm();
      if (mounted) {
        context.go('/booking/${booking.id}/ticket');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(bookingServicesProvider(widget.salonId));
    _seedServiceIfNeeded();

    final draft = ref.watch(bookingDraftProvider(widget.salonId));
    final titles = [
      'Select service',
      'Select barber',
      'Select date',
      'Select time',
      'Review',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_step.clamp(0, titles.length - 1)]),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_step == 0) {
              context.pop();
            } else {
              setState(() => _step -= 1);
            }
          },
        ),
      ),
      body: Column(
        children: [
          _StepIndicator(current: _step, total: 5),
          Expanded(child: _buildStep(draft)),
        ],
      ),
    );
  }

  Widget _buildStep(BookingDraft draft) {
    switch (_step) {
      case 0:
        return _ServiceStep(
          salonId: widget.salonId,
          selectedId: draft.service?.id,
          onSelected: (service) {
            ref
                .read(bookingDraftProvider(widget.salonId).notifier)
                .selectService(service);
            setState(() => _step = 1);
          },
        );
      case 1:
        return _BarberStep(
          salonId: widget.salonId,
          selectedId: draft.barber?.id,
          onSelected: (barber) {
            ref
                .read(bookingDraftProvider(widget.salonId).notifier)
                .selectBarber(barber);
            setState(() => _step = 2);
          },
          onAny: () {
            ref
                .read(bookingDraftProvider(widget.salonId).notifier)
                .selectBarber(
                  const Barber(id: '', salonId: '', displayName: 'Any available'),
                );
            setState(() => _step = 2);
          },
        );
      case 2:
        return _DateStep(
          selected: draft.date,
          onSelected: (date) {
            ref
                .read(bookingDraftProvider(widget.salonId).notifier)
                .selectDate(date);
            setState(() => _step = 3);
          },
        );
      case 3:
        if (draft.service == null || draft.date == null) {
          return const EmptyState(title: 'Select a service and date first');
        }
        final barberId =
            draft.barber?.id == null || draft.barber!.id.isEmpty
                ? null
                : draft.barber!.id;
        return _SlotStep(
          salonId: widget.salonId,
          serviceId: draft.service!.id,
          barberId: barberId,
          date: draft.date!,
          selectedStart: draft.slot?.slotStart,
          onSelected: (slot) {
            ref
                .read(bookingDraftProvider(widget.salonId).notifier)
                .selectSlot(slot);
            setState(() => _step = 4);
          },
        );
      default:
        return _ReviewStep(
          draft: draft,
          notesController: _notes,
          isLoading: _confirming,
          onConfirm: _confirm,
        );
    }
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SnipSpacing.md,
        SnipSpacing.sm,
        SnipSpacing.md,
        SnipSpacing.md,
      ),
      child: Row(
        children: List.generate(total, (index) {
          final active = index <= current;
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index == total - 1 ? 0 : 6),
              decoration: BoxDecoration(
                color: active ? SnipColors.primary : SnipColors.lightGray,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ServiceStep extends ConsumerWidget {
  const _ServiceStep({
    required this.salonId,
    required this.onSelected,
    this.selectedId,
  });

  final String salonId;
  final String? selectedId;
  final void Function(dynamic service) onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(bookingServicesProvider(salonId));
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(SnipSpacing.md),
        child: ListSkeleton(),
      ),
      error: (e, _) => Center(child: Text('$e')),
      data: (services) {
        if (services.isEmpty) {
          return const EmptyState(title: 'No services available');
        }
        return ListView.separated(
          padding: const EdgeInsets.all(SnipSpacing.md),
          itemCount: services.length,
          separatorBuilder: (_, __) => const SizedBox(height: SnipSpacing.sm),
          itemBuilder: (context, index) {
            final service = services[index];
            return ServiceCard(
              service: service,
              selected: service.id == selectedId,
              onTap: () => onSelected(service),
            );
          },
        );
      },
    );
  }
}

class _BarberStep extends ConsumerWidget {
  const _BarberStep({
    required this.salonId,
    required this.onSelected,
    required this.onAny,
    this.selectedId,
  });

  final String salonId;
  final String? selectedId;
  final void Function(Barber barber) onSelected;
  final VoidCallback onAny;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(bookingBarbersProvider(salonId));
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(SnipSpacing.md),
        child: ListSkeleton(),
      ),
      error: (e, _) => Center(child: Text('$e')),
      data: (barbers) {
        return ListView(
          padding: const EdgeInsets.all(SnipSpacing.md),
          children: [
            SnipCardAnyBarber(onTap: onAny),
            const SizedBox(height: SnipSpacing.sm),
            ...barbers.map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: SnipSpacing.sm),
                child: BarberCard(
                  barber: b,
                  selected: b.id == selectedId,
                  onTap: () => onSelected(b),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class SnipCardAnyBarber extends StatelessWidget {
  const SnipCardAnyBarber({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SnipColors.white,
      borderRadius: BorderRadius.circular(SnipSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SnipSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(SnipSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(SnipSpacing.radiusMd),
            border: Border.all(color: SnipColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: SnipColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.groups_outlined, color: SnipColors.primary),
              ),
              const SizedBox(width: SnipSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Any available', style: Theme.of(context).textTheme.titleLarge),
                    Text(
                      'We will assign the best match',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateStep extends StatelessWidget {
  const _DateStep({required this.onSelected, this.selected});

  final DateTime? selected;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = List.generate(14, (i) {
      final d = today.add(Duration(days: i));
      return DateTime(d.year, d.month, d.day);
    });

    return ListView.separated(
      padding: const EdgeInsets.all(SnipSpacing.md),
      itemCount: days.length,
      separatorBuilder: (_, __) => const SizedBox(height: SnipSpacing.sm),
      itemBuilder: (context, index) {
        final day = days[index];
        final isSelected = selected != null &&
            selected!.year == day.year &&
            selected!.month == day.month &&
            selected!.day == day.day;
        return ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SnipSpacing.radiusMd),
            side: BorderSide(
              color: isSelected ? SnipColors.primary : SnipColors.border,
            ),
          ),
          tileColor: isSelected
              ? SnipColors.primary.withValues(alpha: 0.08)
              : SnipColors.white,
          title: Text(DateFormat('EEEE').format(day)),
          subtitle: Text(DateFormat('MMM d, y').format(day)),
          trailing: isSelected
              ? const Icon(Icons.check_circle, color: SnipColors.primary)
              : null,
          onTap: () => onSelected(day),
        );
      },
    );
  }
}

class _SlotStep extends ConsumerWidget {
  const _SlotStep({
    required this.salonId,
    required this.serviceId,
    required this.date,
    required this.onSelected,
    this.barberId,
    this.selectedStart,
  });

  final String salonId;
  final String serviceId;
  final String? barberId;
  final DateTime date;
  final DateTime? selectedStart;
  final void Function(dynamic slot) onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(
      availableSlotsProvider((
        salonId: salonId,
        serviceId: serviceId,
        barberId: barberId,
        date: date,
      )),
    );

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (slots) {
        if (slots.isEmpty) {
          return const EmptyState(
            title: 'No slots available',
            message: 'Try another date or barber.',
            icon: Icons.schedule,
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(SnipSpacing.md),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.4,
          ),
          itemCount: slots.length,
          itemBuilder: (context, index) {
            final slot = slots[index];
            return TimeSlotChip(
              time: slot.slotStart,
              selected: selectedStart == slot.slotStart,
              onTap: () => onSelected(slot),
            );
          },
        );
      },
    );
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({
    required this.draft,
    required this.notesController,
    required this.isLoading,
    required this.onConfirm,
  });

  final BookingDraft draft;
  final TextEditingController notesController;
  final bool isLoading;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'LKR ', decimalDigits: 0);
    return ListView(
      padding: const EdgeInsets.all(SnipSpacing.md),
      children: [
        _ReviewRow(label: 'Service', value: draft.service?.name ?? '—'),
        _ReviewRow(
          label: 'Barber',
          value: draft.barber?.displayName ?? 'Any available',
        ),
        _ReviewRow(
          label: 'Date',
          value: draft.date != null
              ? DateFormat('EEE, MMM d').format(draft.date!)
              : '—',
        ),
        _ReviewRow(
          label: 'Time',
          value: draft.slot != null
              ? DateFormat('h:mm a').format(draft.slot!.slotStart.toLocal())
              : '—',
        ),
        _ReviewRow(
          label: 'Price',
          value: draft.service != null
              ? currency.format(draft.service!.price)
              : '—',
        ),
        const SizedBox(height: SnipSpacing.lg),
        TextField(
          controller: notesController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Notes (optional)',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: SnipSpacing.xl),
        PrimaryCTA(
          label: 'Confirm booking',
          isLoading: isLoading,
          onPressed: onConfirm,
        ),
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SnipSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
