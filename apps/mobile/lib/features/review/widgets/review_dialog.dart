import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../repositories/review_repository.dart';
import '../../../shared/widgets/snip_button.dart';
import '../../../theme/snip_colors.dart';
import '../../../theme/snip_spacing.dart';

class ReviewDialog extends ConsumerStatefulWidget {
  const ReviewDialog({
    super.key,
    required this.bookingId,
    required this.salonName,
    this.barberName,
    this.initialRating = 5,
    this.initialComment = '',
  });

  final String bookingId;
  final String salonName;
  final String? barberName;
  final int initialRating;
  final String initialComment;

  static Future<bool?> show(
    BuildContext context, {
    required String bookingId,
    required String salonName,
    String? barberName,
    int initialRating = 5,
    String initialComment = '',
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => ReviewDialog(
        bookingId: bookingId,
        salonName: salonName,
        barberName: barberName,
        initialRating: initialRating,
        initialComment: initialComment,
      ),
    );
  }

  @override
  ConsumerState<ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends ConsumerState<ReviewDialog> {
  late int _rating;
  late final TextEditingController _commentController;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
    _commentController = TextEditingController(text: widget.initialComment);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await ref.read(reviewRepositoryProvider).submitReview(
            bookingId: widget.bookingId,
            rating: _rating,
            comment: _commentController.text.trim(),
          );

      ref.invalidate(bookingReviewProvider(widget.bookingId));

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you! Your review has been submitted.'),
            backgroundColor: SnipColors.primaryDark,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit review: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SnipSpacing.radiusLg),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rate ${widget.salonName}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: SnipColors.dark,
            ),
          ),
          if (widget.barberName != null)
            Text(
              'Stylist: ${widget.barberName}',
              style: const TextStyle(
                fontSize: 13,
                color: SnipColors.secondaryText,
              ),
            ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            // Star selection
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starVal = index + 1;
                return IconButton(
                  icon: Icon(
                    starVal <= _rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 36,
                    color: starVal <= _rating
                        ? const Color(0xFFFBBF24)
                        : SnipColors.border,
                  ),
                  onPressed: () => setState(() => _rating = starVal),
                );
              }),
            ),
            const SizedBox(height: 6),
            Text(
              '$_rating of 5 stars',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: SnipColors.dark,
              ),
            ),
            const SizedBox(height: SnipSpacing.md),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Share your experience (optional)...',
                hintStyle: const TextStyle(fontSize: 13, color: SnipColors.textMuted),
                filled: true,
                fillColor: SnipColors.lightGray,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(SnipSpacing.radiusMd),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: SnipColors.secondaryText)),
        ),
        SnipButton(
          label: 'Submit Review',
          isLoading: _submitting,
          onPressed: _submit,
        ),
      ],
    );
  }
}
