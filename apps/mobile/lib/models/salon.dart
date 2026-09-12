import 'package:equatable/equatable.dart';

enum SalonVerificationStatus {
  draft,
  pendingVerification,
  verified,
  rejected,
  suspended,
}

SalonVerificationStatus salonStatusFromString(String? value) {
  switch (value) {
    case 'pending_verification':
      return SalonVerificationStatus.pendingVerification;
    case 'verified':
      return SalonVerificationStatus.verified;
    case 'rejected':
      return SalonVerificationStatus.rejected;
    case 'suspended':
      return SalonVerificationStatus.suspended;
    case 'draft':
    default:
      return SalonVerificationStatus.draft;
  }
}

class Salon extends Equatable {
  const Salon({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.slug,
    this.description,
    this.email,
    this.phone,
    this.address,
    this.city,
    this.latitude,
    this.longitude,
    this.logoUrl,
    this.coverUrl,
    this.verificationStatus = SalonVerificationStatus.draft,
    this.isActive = true,
    this.openingHours = const {},
  });

  final String id;
  final String ownerId;
  final String name;
  final String slug;
  final String? description;
  final String? email;
  final String? phone;
  final String? address;
  final String? city;
  final double? latitude;
  final double? longitude;
  final String? logoUrl;
  final String? coverUrl;
  final SalonVerificationStatus verificationStatus;
  final bool isActive;
  final Map<String, dynamic> openingHours;

  factory Salon.fromJson(Map<String, dynamic> json) {
    return Salon(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      logoUrl: json['logo_url'] as String?,
      coverUrl: json['cover_url'] as String?,
      verificationStatus:
          salonStatusFromString(json['verification_status'] as String?),
      isActive: json['is_active'] as bool? ?? true,
      openingHours: (json['opening_hours'] as Map<String, dynamic>?) ?? const {},
    );
  }

  @override
  List<Object?> get props => [id, name, city, verificationStatus];
}
