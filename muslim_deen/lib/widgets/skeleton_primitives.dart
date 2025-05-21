import 'package:flutter/material.dart';

/// A reusable skeleton box widget.
class SkeletonBox extends StatelessWidget {
  final double height;
  final double width;
  final Color? color;
  final BorderRadiusGeometry? borderRadius;

  const SkeletonBox({
    super.key,
    required this.height,
    required this.width,
    this.color,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(102),
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
    );
  }
}

/// A reusable skeleton circle widget.
class SkeletonCircle extends StatelessWidget {
  final double size;
  final Color? color;

  const SkeletonCircle({
    super.key,
    required this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(102),
        shape: BoxShape.circle,
      ),
    );
  }
}