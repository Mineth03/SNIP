import 'package:equatable/equatable.dart';

class Review extends Equatable {
  const Review({
    required this.id,
    required this.bookingId,
    required this.salonId,
    this.barberId,
    required this.customerId,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.customerName,
    this.customerAvatarUrl,
  });

  final String id;
  final String bookingId;
  final String salonId;
  final String? barberId;
  final String customerId;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final String? customerName;
  final String? customerAvatarUrl;

  factory Review.fromJson(Map<String, dynamic> json) {
    String? name;
    String? avatar;
    if (json['profiles'] != null && json['profiles'] is Map) {
      final prof = json['profiles'] as Map<String, dynamic>;
      name = prof['full_name'] as String?;
      avatar = prof['avatar_url'] as String?;
    }

    return Review(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String,
      salonId: json['salon_id'] as String,
      barberId: json['barber_id'] as String?,
      customerId: json['customer_id'] as String,
      rating: (json['rating'] as num).toInt(),
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      customerName: name,
      customerAvatarUrl: avatar,
    );
  }

  @override
  List<Object?> get props => [id, bookingId, salonId, rating, comment, createdAt];
}
