import 'package:equatable/equatable.dart';

enum ServiceCategory {
  hair,
  beard,
  nails,
  facial,
  massage,
  color,
  other,
}

ServiceCategory serviceCategoryFromString(String? value) {
  switch (value) {
    case 'hair':
      return ServiceCategory.hair;
    case 'beard':
      return ServiceCategory.beard;
    case 'nails':
      return ServiceCategory.nails;
    case 'facial':
      return ServiceCategory.facial;
    case 'massage':
      return ServiceCategory.massage;
    case 'color':
      return ServiceCategory.color;
    default:
      return ServiceCategory.other;
  }
}

String serviceCategoryToString(ServiceCategory category) {
  return category.name;
}

String serviceCategoryLabel(ServiceCategory category) {
  switch (category) {
    case ServiceCategory.hair:
      return 'Hair';
    case ServiceCategory.beard:
      return 'Beard';
    case ServiceCategory.nails:
      return 'Nails';
    case ServiceCategory.facial:
      return 'Facial';
    case ServiceCategory.massage:
      return 'Massage';
    case ServiceCategory.color:
      return 'Color';
    case ServiceCategory.other:
      return 'Other';
  }
}

class Service extends Equatable {
  const Service({
    required this.id,
    required this.salonId,
    required this.name,
    required this.price,
    required this.durationMinutes,
    this.description,
    this.category = ServiceCategory.other,
    this.imageUrl,
    this.isActive = true,
  });

  final String id;
  final String salonId;
  final String name;
  final String? description;
  final ServiceCategory category;
  final double price;
  final int durationMinutes;
  final String? imageUrl;
  final bool isActive;

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'] as String,
      salonId: json['salon_id'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      category: serviceCategoryFromString(json['category'] as String?),
      price: (json['price'] as num?)?.toDouble() ?? 0,
      durationMinutes: json['duration_minutes'] as int? ?? 30,
      imageUrl: json['image_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'salon_id': salonId,
        'name': name,
        'description': description,
        'category': serviceCategoryToString(category),
        'price': price,
        'duration_minutes': durationMinutes,
        'image_url': imageUrl,
        'is_active': isActive,
      };

  @override
  List<Object?> get props => [id, name, price, durationMinutes, category];
}
