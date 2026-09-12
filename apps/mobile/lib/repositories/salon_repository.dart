import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase.dart';
import '../models/barber.dart';
import '../models/salon.dart';
import '../models/service.dart';
import '../models/user_activity.dart';

final salonRepositoryProvider = Provider<SalonRepository>((ref) {
  return SalonRepository(supabase);
});

class SalonRepository {
  SalonRepository(this._client);

  final SupabaseClient _client;

  Future<List<Salon>> searchSalons({
    String? query,
    String? city,
    ServiceCategory? category,
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _client.rpc(
      'search_salons',
      params: {
        'p_query': query,
        'p_city': city,
        'p_category': category != null ? serviceCategoryToString(category) : null,
        'p_verified_only': true,
        'p_limit': limit,
        'p_offset': offset,
      },
    );

    return (response as List<dynamic>)
        .map((e) => Salon.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Salon>> getNearbySalons({
    required double latitude,
    required double longitude,
    double radiusKm = 50,
    ServiceCategory? category,
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _client.rpc(
      'get_nearby_salons',
      params: {
        'p_latitude': latitude,
        'p_longitude': longitude,
        'p_radius_km': radiusKm,
        'p_category': category != null ? serviceCategoryToString(category) : null,
        'p_limit': limit,
        'p_offset': offset,
      },
    );

    return (response as List<dynamic>)
        .map((e) => Salon.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Salon>> getPersonalizedRecommendations({
    String? userId,
    double? latitude,
    double? longitude,
    int limit = 10,
  }) async {
    final response = await _client.rpc(
      'get_personalized_recommendations',
      params: {
        'p_user_id': userId,
        'p_latitude': latitude,
        'p_longitude': longitude,
        'p_limit': limit,
      },
    );

    return (response as List<dynamic>)
        .map((e) => Salon.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<String?> logUserActivity({
    required String activityType,
    String? salonId,
    String? serviceId,
    ServiceCategory? category,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await _client.rpc(
        'log_user_activity',
        params: {
          'p_activity_type': activityType,
          'p_salon_id': salonId,
          'p_service_id': serviceId,
          'p_category':
              category != null ? serviceCategoryToString(category) : null,
          'p_metadata': metadata ?? {},
        },
      );
      return response as String?;
    } catch (_) {
      // Non-blocking telemetry
      return null;
    }
  }

  Future<List<UserRecentActivity>> getUserRecentActivity({
    String? userId,
    int limit = 5,
  }) async {
    try {
      final response = await _client.rpc(
        'get_user_recent_activity',
        params: {
          'p_user_id': userId,
          'p_limit': limit,
        },
      );
      return (response as List<dynamic>)
          .map((e) => UserRecentActivity.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<Salon?> getSalon(String id) async {
    final data =
        await _client.from('salons').select().eq('id', id).maybeSingle();
    if (data == null) return null;
    return Salon.fromJson(data);
  }

  Future<List<Salon>> getOwnerSalons(String ownerId) async {
    final data = await _client
        .from('salons')
        .select()
        .eq('owner_id', ownerId)
        .order('created_at');
    return (data as List<dynamic>)
        .map((e) => Salon.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Service>> getServices(String salonId) async {
    final data = await _client
        .from('services')
        .select()
        .eq('salon_id', salonId)
        .eq('is_active', true)
        .order('name');
    return (data as List<dynamic>)
        .map((e) => Service.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Service>> getFeaturedServices({int limit = 8}) async {
    final data = await _client
        .from('services')
        .select()
        .eq('is_active', true)
        .order('created_at', ascending: false)
        .limit(limit);
    return (data as List<dynamic>)
        .map((e) => Service.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Service> createService(Service service) async {
    final payload = service.toJson()..removeWhere((key, value) => value == null);
    final data = await _client
        .from('services')
        .insert(payload)
        .select()
        .single();
    return Service.fromJson(data);
  }

  Future<Service> updateService(String id, Map<String, dynamic> payload) async {
    final data = await _client
        .from('services')
        .update(payload)
        .eq('id', id)
        .select()
        .single();
    return Service.fromJson(data);
  }

  Future<void> deleteService(String id) async {
    await _client.from('services').update({'is_active': false}).eq('id', id);
  }

  Future<List<Barber>> getBarbers(String salonId) async {
    final data = await _client
        .from('barbers')
        .select()
        .eq('salon_id', salonId)
        .eq('is_active', true)
        .order('display_name');
    return (data as List<dynamic>)
        .map((e) => Barber.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Barber?> getBarberByProfile(String profileId) async {
    final data = await _client
        .from('barbers')
        .select()
        .eq('profile_id', profileId)
        .eq('is_active', true)
        .maybeSingle();
    if (data == null) return null;
    return Barber.fromJson(data);
  }

  Future<Barber> createBarber(Barber barber) async {
    final data = await _client
        .from('barbers')
        .insert(barber.toJson())
        .select()
        .single();
    return Barber.fromJson(data);
  }

  Future<void> updateBarber(String id, Map<String, dynamic> payload) async {
    await _client.from('barbers').update(payload).eq('id', id);
  }

  Future<List<BarberSchedule>> getBarberSchedules(String barberId) async {
    final data = await _client
        .from('barber_schedules')
        .select()
        .eq('barber_id', barberId)
        .order('day_of_week');
    return (data as List<dynamic>)
        .map((e) => BarberSchedule.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<String>> getGallery(String salonId) async {
    final data = await _client
        .from('salon_gallery')
        .select('image_url')
        .eq('salon_id', salonId)
        .order('sort_order');
    return (data as List<dynamic>)
        .map((e) => (e as Map<String, dynamic>)['image_url'] as String)
        .toList();
  }
}
