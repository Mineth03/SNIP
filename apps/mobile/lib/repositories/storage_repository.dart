import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../config/supabase.dart';

final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  return StorageRepository(supabase);
});

class StorageRepository {
  StorageRepository(this._client);

  final SupabaseClient _client;
  static const _uuid = Uuid();

  /// Upload avatar image bytes to the 'avatars' bucket
  Future<String> uploadAvatar({
    required Uint8List bytes,
    required String userId,
    String fileExtension = 'jpg',
  }) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${_uuid.v4().substring(0, 8)}.$fileExtension';
    final path = '$userId/$fileName';

    await _client.storage.from('avatars').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: 'image/$fileExtension',
            upsert: true,
          ),
        );

    return _client.storage.from('avatars').getPublicUrl(path);
  }

  /// Upload salon photo bytes to the 'salon-images' bucket
  Future<String> uploadSalonImage({
    required Uint8List bytes,
    required String salonId,
    String fileExtension = 'jpg',
  }) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${_uuid.v4().substring(0, 8)}.$fileExtension';
    final path = 'salons/$salonId/$fileName';

    await _client.storage.from('salon-images').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: 'image/$fileExtension',
            upsert: true,
          ),
        );

    return _client.storage.from('salon-images').getPublicUrl(path);
  }

  /// Delete an image from a storage bucket
  Future<void> deleteImage({
    required String bucket,
    required String publicUrlOrPath,
  }) async {
    String path = publicUrlOrPath;
    if (publicUrlOrPath.startsWith('http')) {
      final parts = publicUrlOrPath.split('/$bucket/');
      if (parts.length > 1) {
        path = parts[1];
      }
    }
    await _client.storage.from(bucket).remove([path]);
  }
}
