import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase.dart';
import '../models/booking.dart';

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository(supabase);
});

const _bookingSelect = '''
  *,
  salons(name),
  services(name),
  barbers(display_name),
  profiles!bookings_customer_id_fkey(full_name)
''';

class BookingRepository {
  BookingRepository(this._client);

  final SupabaseClient _client;

  Future<List<TimeSlot>> getAvailableSlots({
    required String salonId,
    required String serviceId,
    String? barberId,
    required DateTime date,
  }) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final response = await _client.rpc(
      'get_available_slots',
      params: {
        'p_salon_id': salonId,
        'p_service_id': serviceId,
        'p_barber_id': barberId,
        'p_date': dateStr,
        'p_slot_interval_minutes': 15,
        'p_buffer_minutes': 0,
      },
    );

    return (response as List<dynamic>)
        .map((e) => TimeSlot.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Booking> createBooking({
    required String salonId,
    required String serviceId,
    required DateTime appointmentStart,
    String? barberId,
    String? customerNotes,
  }) async {
    final response = await _client.rpc(
      'create_booking',
      params: {
        'p_salon_id': salonId,
        'p_service_id': serviceId,
        'p_appointment_start': appointmentStart.toUtc().toIso8601String(),
        'p_barber_id': barberId,
        'p_customer_notes': customerNotes,
        'p_is_walk_in': false,
      },
    );

    return Booking.fromJson(Map<String, dynamic>.from(response as Map));
  }

  Future<Booking> checkInWithQr(String qrToken) async {
    String token = qrToken.trim();
    if (token.toUpperCase().startsWith('SNIP')) {
      final code = token.substring(4).toLowerCase();
      final res = await _client
          .from('bookings')
          .select('qr_token')
          .ilike('qr_token', '$code%')
          .limit(1)
          .maybeSingle();
      if (res != null && res['qr_token'] != null) {
        token = res['qr_token'] as String;
      }
    }

    final response = await _client.rpc(
      'check_in_with_qr',
      params: {'p_qr_token': token},
    );
    return Booking.fromJson(Map<String, dynamic>.from(response as Map));
  }

  Future<Booking> transitionStatus({
    required String bookingId,
    required BookingStatus toStatus,
    String? note,
  }) async {
    final response = await _client.rpc(
      'transition_booking_status',
      params: {
        'p_booking_id': bookingId,
        'p_to_status': bookingStatusToString(toStatus),
        'p_note': note,
      },
    );
    return Booking.fromJson(Map<String, dynamic>.from(response as Map));
  }

  Future<Booking?> getBooking(String id) async {
    final data = await _client
        .from('bookings')
        .select(_bookingSelect)
        .eq('id', id)
        .maybeSingle();
    if (data == null) return null;
    return Booking.fromJson(data);
  }

  Future<List<Booking>> getCustomerBookings(String customerId) async {
    final data = await _client
        .from('bookings')
        .select(_bookingSelect)
        .eq('customer_id', customerId)
        .order('appointment_start', ascending: false);
    return (data as List<dynamic>)
        .map((e) => Booking.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Booking>> getSalonBookings(
    String salonId, {
    DateTime? day,
  }) async {
    var query = _client.from('bookings').select(_bookingSelect).eq('salon_id', salonId);

    if (day != null) {
      final start = DateTime(day.year, day.month, day.day).toUtc();
      final end = start.add(const Duration(days: 1));
      query = query
          .gte('appointment_start', start.toIso8601String())
          .lt('appointment_start', end.toIso8601String());
    }

    final data = await query.order('appointment_start');
    return (data as List<dynamic>)
        .map((e) => Booking.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Booking>> getBarberBookings(
    String barberId, {
    DateTime? day,
  }) async {
    var query =
        _client.from('bookings').select(_bookingSelect).eq('barber_id', barberId);

    if (day != null) {
      final start = DateTime(day.year, day.month, day.day).toUtc();
      final end = start.add(const Duration(days: 1));
      query = query
          .gte('appointment_start', start.toIso8601String())
          .lt('appointment_start', end.toIso8601String());
    }

    final data = await query.order('appointment_start');
    return (data as List<dynamic>)
        .map((e) => Booking.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Live real-time stream of a single booking (for Ticket screen)
  Stream<Booking?> streamBooking(String id) {
    return _client
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .asyncMap((list) async {
          if (list.isEmpty) return null;
          return getBooking(id);
        });
  }

  /// Live real-time stream of a barber's appointments
  Stream<List<Booking>> streamBarberBookings(String barberId, {DateTime? day}) {
    return _client
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('barber_id', barberId)
        .asyncMap((_) => getBarberBookings(barberId, day: day));
  }

  /// Live real-time stream of salon appointments for Owner
  Stream<List<Booking>> streamSalonBookings(String salonId, {DateTime? day}) {
    return _client
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('salon_id', salonId)
        .asyncMap((_) => getSalonBookings(salonId, day: day));
  }

  /// Live real-time stream of customer appointments
  Stream<List<Booking>> streamCustomerBookings(String customerId) {
    return _client
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('customer_id', customerId)
        .asyncMap((_) => getCustomerBookings(customerId));
  }
}
