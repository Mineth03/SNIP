import 'package:flutter/material.dart';

import '../../theme/snip_colors.dart';
import '../../theme/snip_spacing.dart';

class LoadingSkeleton extends StatefulWidget {
  const LoadingSkeleton({
    super.key,
    this.height = 16,
    this.width,
    this.borderRadius,
  });

  final double height;
  final double? width;
  final double? borderRadius;

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            color: Color.lerp(
              context.isDark
                  ? SnipColors.darkSurfaceElevated
                  : SnipColors.lightGray,
              context.isDark ? SnipColors.darkBorder : SnipColors.border,
              _controller.value,
            ),
            borderRadius: BorderRadius.circular(
              widget.borderRadius ?? SnipSpacing.radiusSm,
            ),
          ),
        );
      },
    );
  }
}

class SalonCardSkeleton extends StatelessWidget {
  const SalonCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.snipCard,
        borderRadius: BorderRadius.circular(SnipSpacing.radiusMd),
        border: Border.all(color: context.snipBorder),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LoadingSkeleton(height: 120, borderRadius: SnipSpacing.radiusMd),
          Padding(
            padding: EdgeInsets.all(SnipSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LoadingSkeleton(height: 16, width: 140),
                SizedBox(height: SnipSpacing.sm),
                LoadingSkeleton(height: 12, width: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ListSkeleton extends StatelessWidget {
  const ListSkeleton({super.key, this.count = 4});

  final int count;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: SnipSpacing.md),
      itemBuilder: (_, __) => const LoadingSkeleton(height: 72),
    );
  }
}
