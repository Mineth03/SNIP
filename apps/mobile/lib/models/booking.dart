import 'package:equatable/equatable.dart';

enum BookingStatus {
  pending,
  confirmed,
  checkedIn,
  inProgress,
  completed,
  cancelled,
  noShow,
}

BookingStatus bookingStatusFromString(String? value) {
  switch (value) {
    case 'pending':
      return BookingStatus.pending;
    case 'checked_in':
      return BookingStatus.checkedIn;
    case 'in_progress':
      return BookingStatus.inProgress;
    case 'completed':
      return BookingStatus.completed;
    case 'cancelled':
      return BookingStatus.cancelled;
    case 'no_show':
      return BookingStatus.noShow;
    case 'confirmed':
    default:
      return BookingStatus.confirmed;
  }
}

String bookingStatusToString(BookingStatus status) {
  switch (status) {
    case BookingStatus.pending:
      return 'pending';
    case BookingStatus.confirmed:
      return 'confirmed';
    case BookingStatus.checkedIn:
      return 'checked_in';
    case BookingStatus.inProgress:
      return 'in_progress';
    case BookingStatus.completed:
      return 'completed';
    case BookingStatus.cancelled:
      return 'cancelled';
    case BookingStatus.noShow:
      return 'no_show';
  }
}

String bookingStatusLabel(BookingStatus status) {
  switch (status) {
    case BookingStatus.pending:
      return 'Pending';
    case BookingStatus.confirmed:
      return 'Confirmed';
    case BookingStatus.checkedIn:
      return 'Checked in';
    case BookingStatus.inProgress:
      return 'In progress';
    case BookingStatus.completed:
      return 'Completed';
    case BookingStatus.cancelled:
      return 'Cancelled';
    case BookingStatus.noShow:
      return 'No show';
  }
}

class Booking extends Equatable {
  const Booking({
    required this.id,
    required this.customerId,
    required this.salonId,
    required this.serviceId,
    required this.barberId,
    required this.appointmentStart,
    required this.appointmentEnd,
    required this.price,
    required this.status,
    required this.qrToken,
    this.customerNotes,
    this.isWalkIn = false,
    this.salonName,
    this.serviceName,
    this.barberName,
    this.customerName,
  });

  final String id;
  final String customerId;
  final String salonId;
  final String serviceId;
  final String barberId;
  final DateTime appointmentStart;
  final DateTime appointmentEnd;
  final double price;
  final BookingStatus status;
  final String qrToken;
  final String? customerNotes;
  final bool isWalkIn;
  final String? salonName;
  final String? serviceName;
  final String? barberName;
  final String? customerName;

  factory Booking.fromJson(Map<String, dynamic> json) {
    final salon = json['salons'] as Map<String, dynamic>?;
    final service = json['services'] as Map<String, dynamic>?;
    final barber = json['barbers'] as Map<String, dynamic>?;
    final customer = json['profiles'] as Map<String, dynamic>?;

    return Booking(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      salonId: json['salon_id'] as String,
      serviceId: json['service_id'] as String,
      barberId: json['barber_id'] as String,
      appointmentStart: DateTime.parse(json['appointment_start'] as String),
      appointmentEnd: DateTime.parse(json['appointment_end'] as String),
      price: (json['price'] as num?)?.toDouble() ?? 0,
      status: bookingStatusFromString(json['status'] as String?),
      qrToken: json['qr_token'] as String,
      customerNotes: json['customer_notes'] as String?,
      isWalkIn: json['is_walk_in'] as bool? ?? false,
      salonName: salon?['name'] as String? ?? json['salon_name'] as String?,
      serviceName: service?['name'] as String? ?? json['service_name'] as String?,
      barberName:
          barber?['display_name'] as String? ?? json['barber_name'] as String?,
      customerName:
          customer?['full_name'] as String? ?? json['customer_name'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, status, appointmentStart, qrToken];
}

class TimeSlot extends Equatable {
  const TimeSlot({
    required this.barberId,
    required this.barberName,
    required this.slotStart,
    required this.slotEnd,
  });

  final String barberId;
  final String barberName;
  final DateTime slotStart;
  final DateTime slotEnd;

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      barberId: json['barber_id'] as String,
      barberName: json['barber_name'] as String? ?? '',
      slotStart: DateTime.parse(json['slot_start'] as String),
      slotEnd: DateTime.parse(json['slot_end'] as String),
    );
  }

  @override
  List<Object?> get props => [barberId, slotStart, slotEnd];
}
