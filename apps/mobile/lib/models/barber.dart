import 'package:equatable/equatable.dart';

class Barber extends Equatable {
  const Barber({
    required this.id,
    required this.salonId,
    required this.displayName,
    this.profileId,
    this.bio,
    this.avatarUrl,
    this.specializations = const [],
    this.isActive = true,
  });

  final String id;
  final String salonId;
  final String? profileId;
  final String displayName;
  final String? bio;
  final String? avatarUrl;
  final List<String> specializations;
  final bool isActive;

  factory Barber.fromJson(Map<String, dynamic> json) {
    return Barber(
      id: json['id'] as String,
      salonId: json['salon_id'] as String,
      profileId: json['profile_id'] as String?,
      displayName: json['display_name'] as String? ?? '',
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      specializations: (json['specializations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'salon_id': salonId,
        'profile_id': profileId,
        'display_name': displayName,
        'bio': bio,
        'avatar_url': avatarUrl,
        'specializations': specializations,
        'is_active': isActive,
      };

  @override
  List<Object?> get props => [id, displayName, salonId];
}

class BarberSchedule extends Equatable {
  const BarberSchedule({
    required this.id,
    required this.barberId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.isWorking = true,
  });

  final String id;
  final String barberId;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final bool isWorking;

  factory BarberSchedule.fromJson(Map<String, dynamic> json) {
    return BarberSchedule(
      id: json['id'] as String,
      barberId: json['barber_id'] as String,
      dayOfWeek: json['day_of_week'] as String,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      isWorking: json['is_working'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [id, dayOfWeek, startTime, endTime, isWorking];
}

class BarberSalonMembership extends Equatable {
  const BarberSalonMembership({
    required this.salonId,
    required this.salonName,
    required this.barberId,
  });

  final String salonId;
  final String salonName;
  final String barberId;

  @override
  List<Object?> get props => [salonId, salonName, barberId];
}

class ActiveBarberContext extends Equatable {
  const ActiveBarberContext({
    required this.barber,
    required this.salonName,
    required this.memberships,
  });

  final Barber barber;
  final String salonName;
  final List<BarberSalonMembership> memberships;

  String get salonId => barber.salonId;
  String get barberId => barber.id;

  @override
  List<Object?> get props => [barber, salonName, memberships];
}
