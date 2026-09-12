import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../theme/snip_colors.dart';

class SnipAvatar extends StatelessWidget {
  const SnipAvatar({
    super.key,
    this.imageUrl,
    this.url,
    this.name,
    this.size = 40,
  });

  final String? imageUrl;
  final String? url;
  final String? name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final effectiveUrl = imageUrl ?? url;
    final initials = _initials(name);

    if (effectiveUrl != null && effectiveUrl.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: effectiveUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) => _fallback(initials),
          errorWidget: (_, __, ___) => _fallback(initials),
        ),
      );
    }
    return _fallback(initials);
  }

  Widget _fallback(String initials) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: SnipColors.primary,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: SnipColors.white,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.38,
        ),
      ),
    );
  }

  String _initials(String? value) {
    if (value == null || value.trim().isEmpty) return 'S';
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}
