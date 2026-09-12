import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase.dart';
import '../models/salon.dart';

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepository(supabase);
});

class FavoritesRepository {
  FavoritesRepository(this._client);

  final SupabaseClient _client;

  Future<List<Salon>> getFavorites(String userId) async {
    final data = await _client
        .from('favorites')
        .select('salon_id, salons(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (data as List<dynamic>).map((e) {
      final map = e as Map<String, dynamic>;
      return Salon.fromJson(map['salons'] as Map<String, dynamic>);
    }).toList();
  }

  Future<bool> isFavorite({
    required String userId,
    required String salonId,
  }) async {
    final data = await _client
        .from('favorites')
        .select('id')
        .eq('user_id', userId)
        .eq('salon_id', salonId)
        .maybeSingle();
    return data != null;
  }

  Future<void> addFavorite({
    required String userId,
    required String salonId,
  }) async {
    await _client.from('favorites').insert({
      'user_id': userId,
      'salon_id': salonId,
    });
  }

  Future<void> removeFavorite({
    required String userId,
    required String salonId,
  }) async {
    await _client
        .from('favorites')
        .delete()
        .eq('user_id', userId)
        .eq('salon_id', salonId);
  }

  Future<void> toggleFavorite({
    required String userId,
    required String salonId,
  }) async {
    final exists = await isFavorite(userId: userId, salonId: salonId);
    if (exists) {
      await removeFavorite(userId: userId, salonId: salonId);
    } else {
      await addFavorite(userId: userId, salonId: salonId);
    }
  }
}
