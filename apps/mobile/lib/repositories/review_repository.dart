import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase.dart';
import '../models/review.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository(supabase);
});

final salonReviewsProvider =
    FutureProvider.family<List<Review>, String>((ref, salonId) async {
  return ref.watch(reviewRepositoryProvider).getSalonReviews(salonId);
});

final bookingReviewProvider =
    FutureProvider.family<Review?, String>((ref, bookingId) async {
  return ref.watch(reviewRepositoryProvider).getBookingReview(bookingId);
});

class ReviewRepository {
  ReviewRepository(this._client);

  final SupabaseClient _client;

  /// Fetch all reviews for a salon with customer profiles
  Future<List<Review>> getSalonReviews(String salonId) async {
    final data = await _client
        .from('reviews')
        .select('*, profiles:customer_id(full_name, avatar_url)')
        .eq('salon_id', salonId)
        .order('created_at', ascending: false);

    return (data as List<dynamic>)
        .map((e) => Review.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch a review for a specific booking (if already reviewed)
  Future<Review?> getBookingReview(String bookingId) async {
    final data = await _client
        .from('reviews')
        .select('*, profiles:customer_id(full_name, avatar_url)')
        .eq('booking_id', bookingId)
        .maybeSingle();

    if (data == null) return null;
    return Review.fromJson(data);
  }

  /// Submit or update a review using the secure RPC function
  Future<Map<String, dynamic>> submitReview({
    required String bookingId,
    required int rating,
    String? comment,
  }) async {
    final response = await _client.rpc('submit_booking_review', params: {
      'p_booking_id': bookingId,
      'p_rating': rating,
      'p_comment': comment?.trim().isNotEmpty == true ? comment!.trim() : null,
    });

    return response as Map<String, dynamic>;
  }
}
