import 'package:flutter/material.dart';

import '../../theme/snip_colors.dart';
import '../../theme/snip_spacing.dart';

class SnipSearchBar extends StatelessWidget {
  const SnipSearchBar({
    super.key,
    this.controller,
    this.hint = 'Search salons, services…',
    this.onChanged,
    this.onSubmitted,
    this.readOnly = false,
    this.onTap,
  });

  final TextEditingController? controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search, color: SnipColors.secondaryText),
        filled: true,
        fillColor: SnipColors.lightGray,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: SnipSpacing.md,
          vertical: SnipSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SnipSpacing.radiusMd),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
