import 'package:equatable/equatable.dart';

enum UserRole { customer, salonOwner, barber, admin }

UserRole userRoleFromString(String? value) {
  switch (value) {
    case 'salon_owner':
      return UserRole.salonOwner;
    case 'barber':
      return UserRole.barber;
    case 'admin':
      return UserRole.admin;
    case 'customer':
    default:
      return UserRole.customer;
  }
}

String userRoleToString(UserRole role) {
  switch (role) {
    case UserRole.salonOwner:
      return 'salon_owner';
    case UserRole.barber:
      return 'barber';
    case UserRole.admin:
      return 'admin';
    case UserRole.customer:
      return 'customer';
  }
}

class Profile extends Equatable {
  const Profile({
    required this.id,
    required this.role,
    required this.fullName,
    required this.email,
    this.phone,
    this.avatarUrl,
    this.city,
    this.isActive = true,
    this.createdAt,
  });

  final String id;
  final UserRole role;
  final String fullName;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final String? city;
  final bool isActive;
  final DateTime? createdAt;

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      role: userRoleFromString(json['role'] as String?),
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      city: json['city'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': userRoleToString(role),
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'avatar_url': avatarUrl,
        'city': city,
        'is_active': isActive,
      };

  Profile copyWith({
    String? fullName,
    String? phone,
    String? avatarUrl,
    String? city,
  }) {
    return Profile(
      id: id,
      role: role,
      fullName: fullName ?? this.fullName,
      email: email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      city: city ?? this.city,
      isActive: isActive,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, role, fullName, email, phone, avatarUrl, city];
}
