import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/supabase.dart';
import '../../repositories/favorites_repository.dart';
import '../../theme/snip_colors.dart';

class SnipFavoriteButton extends ConsumerStatefulWidget {
  const SnipFavoriteButton({
    super.key,
    required this.salonId,
    this.size = 20,
    this.backgroundColor,
  });

  final String salonId;
  final double size;
  final Color? backgroundColor;

  @override
  ConsumerState<SnipFavoriteButton> createState() => _SnipFavoriteButtonState();
}

class _SnipFavoriteButtonState extends ConsumerState<SnipFavoriteButton> {
  bool _isFavorite = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    try {
      final isFav = await ref
          .read(favoritesRepositoryProvider)
          .isFavorite(userId: user.id, salonId: widget.salonId);
      if (mounted) setState(() => _isFavorite = isFav);
    } catch (_) {}
  }

  Future<void> _toggleFavorite() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to save your favorite salons')),
      );
      return;
    }

    setState(() {
      _loading = true;
      _isFavorite = !_isFavorite;
    });

    try {
      await ref.read(favoritesRepositoryProvider).toggleFavorite(
            userId: user.id,
            salonId: widget.salonId,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isFavorite ? 'Added to favorites' : 'Removed from favorites',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isFavorite = !_isFavorite);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating favorite: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: widget.backgroundColor ??
          (context.isDark
              ? SnipColors.darkSurface.withValues(alpha: 0.92)
              : SnipColors.white.withValues(alpha: 0.9)),
      shape: const CircleBorder(),
      elevation: 1,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: _loading ? null : _toggleFavorite,
        child: Padding(
          padding: const EdgeInsets.all(7.0),
          child: Icon(
            _isFavorite ? Icons.favorite : Icons.favorite_border,
            size: widget.size,
            color: _isFavorite ? const Color(0xFFEF4444) : context.snipText,
          ),
        ),
      ),
    );
  }
}
