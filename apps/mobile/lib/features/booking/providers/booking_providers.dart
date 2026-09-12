import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/barber.dart';
import '../../../models/booking.dart';
import '../../../models/service.dart';
import '../../../repositories/booking_repository.dart';
import '../../../repositories/salon_repository.dart';

class BookingDraft extends Equatable {
  const BookingDraft({
    required this.salonId,
    this.service,
    this.barber,
    this.date,
    this.slot,
    this.notes,
    this.createdBooking,
  });

  final String salonId;
  final Service? service;
  final Barber? barber;
  final DateTime? date;
  final TimeSlot? slot;
  final String? notes;
  final Booking? createdBooking;

  int get step {
    if (service == null) return 0;
    if (barber == null) return 1;
    if (date == null) return 2;
    if (slot == null) return 3;
    if (createdBooking == null) return 4;
    return 5;
  }

  BookingDraft copyWith({
    Service? service,
    Barber? barber,
    DateTime? date,
    TimeSlot? slot,
    String? notes,
    Booking? createdBooking,
    bool clearBarber = false,
    bool clearSlot = false,
  }) {
    return BookingDraft(
      salonId: salonId,
      service: service ?? this.service,
      barber: clearBarber ? null : (barber ?? this.barber),
      date: date ?? this.date,
      slot: clearSlot ? null : (slot ?? this.slot),
      notes: notes ?? this.notes,
      createdBooking: createdBooking ?? this.createdBooking,
    );
  }

  @override
  List<Object?> get props =>
      [salonId, service, barber, date, slot, notes, createdBooking];
}

final bookingDraftProvider =
    StateNotifierProvider.autoDispose.family<BookingDraftController, BookingDraft, String>(
  (ref, salonId) => BookingDraftController(ref, salonId),
);

class BookingDraftController extends StateNotifier<BookingDraft> {
  BookingDraftController(this._ref, String salonId)
      : super(BookingDraft(salonId: salonId));

  final Ref _ref;

  void selectService(Service service) {
    state = state.copyWith(service: service, clearBarber: true, clearSlot: true);
  }

  void selectBarber(Barber? barber) {
    state = state.copyWith(barber: barber, clearSlot: true);
  }

  void selectDate(DateTime date) {
    state = state.copyWith(date: date, clearSlot: true);
  }

  void selectSlot(TimeSlot slot) {
    state = state.copyWith(
      slot: slot,
      barber: Barber(
        id: slot.barberId,
        salonId: state.salonId,
        displayName: slot.barberName,
      ),
    );
  }

  void setNotes(String notes) {
    state = state.copyWith(notes: notes);
  }

  Future<Booking> confirm() async {
    final service = state.service;
    final slot = state.slot;
    if (service == null || slot == null) {
      throw StateError('Incomplete booking draft');
    }

    final booking = await _ref.read(bookingRepositoryProvider).createBooking(
          salonId: state.salonId,
          serviceId: service.id,
          appointmentStart: slot.slotStart,
          barberId: state.barber?.id ?? slot.barberId,
          customerNotes: state.notes,
        );
    state = state.copyWith(createdBooking: booking);
    return booking;
  }
}

final bookingServicesProvider =
    FutureProvider.autoDispose.family((ref, String salonId) {
  return ref.watch(salonRepositoryProvider).getServices(salonId);
});

final bookingBarbersProvider =
    FutureProvider.autoDispose.family((ref, String salonId) {
  return ref.watch(salonRepositoryProvider).getBarbers(salonId);
});

final availableSlotsProvider = FutureProvider.autoDispose
    .family<List<TimeSlot>, ({String salonId, String serviceId, String? barberId, DateTime date})>(
  (ref, args) {
    return ref.watch(bookingRepositoryProvider).getAvailableSlots(
          salonId: args.salonId,
          serviceId: args.serviceId,
          barberId: args.barberId,
          date: args.date,
        );
  },
);
