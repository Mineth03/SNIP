import 'package:equatable/equatable.dart';

class UserRecentActivity extends Equatable {
  const UserRecentActivity({
    required this.id,
    required this.activityType,
    this.salonId,
    this.salonName,
    this.salonSlug,
    this.salonCoverUrl,
    this.serviceId,
    this.serviceName,
    this.category,
    this.metadata = const {},
    required this.createdAt,
  });

  final String id;
  final String activityType;
  final String? salonId;
  final String? salonName;
  final String? salonSlug;
  final String? salonCoverUrl;
  final String? serviceId;
  final String? serviceName;
  final String? category;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  factory UserRecentActivity.fromJson(Map<String, dynamic> json) {
    return UserRecentActivity(
      id: json['id'] as String,
      activityType: json['activity_type'] as String? ?? 'view_salon',
      salonId: json['salon_id'] as String?,
      salonName: json['salon_name'] as String?,
      salonSlug: json['salon_slug'] as String?,
      salonCoverUrl: json['salon_cover_url'] as String?,
      serviceId: json['service_id'] as String?,
      serviceName: json['service_name'] as String?,
      category: json['category'] as String?,
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? const {},
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  String get displayTitle {
    switch (activityType) {
      case 'book_appointment':
        return 'Booked ${serviceName ?? 'appointment'}';
      case 'view_salon':
        return 'Viewed ${salonName ?? 'salon'}';
      case 'favorite_salon':
        return 'Saved ${salonName ?? 'salon'}';
      case 'review_salon':
        return 'Reviewed ${salonName ?? 'salon'}';
      case 'search':
        return 'Searched in ${category ?? 'services'}';
      default:
        return salonName ?? 'Recent activity';
    }
  }

  @override
  List<Object?> get props => [id, activityType, salonId, createdAt];
}
