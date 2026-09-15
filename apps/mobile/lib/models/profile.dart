import 'package:equatable/equatable.dart';

enum UserRole { customer, salonOwner, barber, admin }

typedef AppCapability = UserRole;

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

String userRoleLabel(UserRole role) {
  switch (role) {
    case UserRole.salonOwner:
      return 'Salon Owner';
    case UserRole.barber:
      return 'Barber';
    case UserRole.admin:
      return 'Admin';
    case UserRole.customer:
      return 'Customer';
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
    this.activeRole,
    this.activeBarberSalonId,
    this.capabilities = const [UserRole.customer],
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
  final UserRole? activeRole;
  final String? activeBarberSalonId;
  final List<UserRole> capabilities;

  /// Preferred UI shell: active_role when still a valid capability, else customer.
  UserRole get effectiveActiveRole {
    final preferred = activeRole ?? role;
    if (capabilities.contains(preferred) || preferred == UserRole.admin) {
      return preferred;
    }
    if (capabilities.contains(UserRole.customer)) return UserRole.customer;
    return capabilities.isNotEmpty ? capabilities.first : UserRole.customer;
  }

  bool get isOwner => capabilities.contains(UserRole.salonOwner);
  bool get isBarber => capabilities.contains(UserRole.barber);

  factory Profile.fromJson(
    Map<String, dynamic> json, {
    List<UserRole>? capabilities,
  }) {
    final role = userRoleFromString(json['role'] as String?);
    final active = json['active_role'] != null
        ? userRoleFromString(json['active_role'] as String?)
        : role;
    return Profile(
      id: json['id'] as String,
      role: role,
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      city: json['city'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      activeRole: active,
      activeBarberSalonId: json['active_barber_salon_id'] as String?,
      capabilities: capabilities ?? [UserRole.customer, if (role != UserRole.customer) role],
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
        'active_role': userRoleToString(activeRole ?? role),
        'active_barber_salon_id': activeBarberSalonId,
      };

  Profile copyWith({
    String? fullName,
    String? phone,
    String? avatarUrl,
    String? city,
    UserRole? activeRole,
    String? activeBarberSalonId,
    List<UserRole>? capabilities,
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
      activeRole: activeRole ?? this.activeRole,
      activeBarberSalonId: activeBarberSalonId ?? this.activeBarberSalonId,
      capabilities: capabilities ?? this.capabilities,
    );
  }

  @override
  List<Object?> get props => [
        id,
        role,
        fullName,
        email,
        phone,
        avatarUrl,
        city,
        activeRole,
        activeBarberSalonId,
        capabilities,
      ];
}
