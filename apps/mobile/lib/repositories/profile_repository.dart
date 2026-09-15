import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase.dart';
import '../models/profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(supabase);
});

class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

  Future<List<UserRole>> fetchCapabilities(String userId) async {
    try {
      final data = await _client.rpc(
        'user_capabilities',
        params: {'p_uid': userId},
      );
      if (data is List) {
        return data
            .map((e) => userRoleFromString(e?.toString()))
            .toSet()
            .toList();
      }
    } catch (_) {
      // Pre-migration fallback handled by caller.
    }
    return const [UserRole.customer];
  }

  Future<Profile?> getCurrentProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final data = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (data == null) return null;
    var caps = await fetchCapabilities(user.id);
    if (caps.length == 1 && caps.first == UserRole.customer) {
      // Fallback when RPC missing: derive from legacy role column.
      final role = userRoleFromString(data['role'] as String?);
      caps = [
        UserRole.customer,
        if (role != UserRole.customer) role,
      ];
    }
    return Profile.fromJson(data, capabilities: caps);
  }

  Future<Profile?> getById(String id) async {
    final data =
        await _client.from('profiles').select().eq('id', id).maybeSingle();
    if (data == null) return null;
    return Profile.fromJson(data);
  }

  Future<Profile> updateProfile({
    required String id,
    String? fullName,
    String? phone,
    String? city,
    String? avatarUrl,
  }) async {
    final payload = <String, dynamic>{};
    if (fullName != null) payload['full_name'] = fullName;
    if (phone != null) payload['phone'] = phone;
    if (city != null) payload['city'] = city;
    if (avatarUrl != null) payload['avatar_url'] = avatarUrl;

    final data = await _client
        .from('profiles')
        .update(payload)
        .eq('id', id)
        .select()
        .single();

    return Profile.fromJson(data);
  }

  Future<void> setActiveRole(UserRole role) async {
    await _client.rpc(
      'set_active_role',
      params: {'p_role': userRoleToString(role)},
    );
  }

  Future<void> setActiveBarberSalon(String salonId) async {
    await _client.rpc(
      'set_active_barber_salon',
      params: {'p_salon_id': salonId},
    );
  }

  Future<void> becomeSalonOwner({
    required String name,
    String? city,
    String? phone,
    String? address,
  }) async {
    await _client.rpc(
      'become_salon_owner',
      params: {
        'p_name': name,
        'p_city': city,
        'p_phone': phone,
        'p_address': address,
      },
    );
  }

  Future<void> acceptBarberInvite(String token) async {
    await _client.rpc(
      'accept_barber_invite',
      params: {'p_token': token},
    );
  }

  Future<String> inviteBarberToSalon({
    required String salonId,
    required String email,
    String? displayName,
  }) async {
    final result = await _client.rpc(
      'invite_barber_to_salon',
      params: {
        'p_salon_id': salonId,
        'p_email': email,
        'p_display_name': displayName,
      },
    );
    if (result is Map) {
      return result['invitation_token']?.toString() ?? '';
    }
    return result?.toString() ?? '';
  }

  Future<void> removeBarberFromSalon({
    required String salonId,
    required String barberId,
  }) async {
    await _client.rpc(
      'remove_barber_from_salon',
      params: {
        'p_salon_id': salonId,
        'p_barber_id': barberId,
      },
    );
  }

  Future<void> resignFromSalon(String salonId) async {
    await _client.rpc(
      'resign_from_salon',
      params: {'p_salon_id': salonId},
    );
  }
}
