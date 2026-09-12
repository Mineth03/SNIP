import 'package:flutter/material.dart';

import '../../theme/snip_colors.dart';
import '../../theme/snip_spacing.dart';

class SnipSearchBar extends StatelessWidget {
  const SnipSearchBar({
    super.key,
    this.controller,
    this.hint = 'Search for salons, services...',
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
    return Container(
      decoration: BoxDecoration(
        color: SnipColors.white,
        borderRadius: BorderRadius.circular(SnipSpacing.radiusPill),
        border: Border.all(color: SnipColors.border),
        boxShadow: [
          BoxShadow(
            color: SnipColors.dark.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: SnipSpacing.md),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              readOnly: readOnly,
              onTap: onTap,
              style: const TextStyle(
                fontSize: 15,
                color: SnipColors.dark,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  color: SnipColors.secondaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                filled: false,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 0,
                  vertical: 14,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: InkWell(
              onTap: readOnly
                  ? onTap
                  : () {
                      if (onSubmitted != null && controller != null) {
                        onSubmitted!(controller!.text);
                      }
                    },
              borderRadius: BorderRadius.circular(SnipSpacing.radiusPill),
              child: Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: SnipColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search,
                  size: 20,
                  color: SnipColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
