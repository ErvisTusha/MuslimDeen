import 'package:flutter/material.dart';

/// A widget that adds a shimmer effect to any skeleton loader
class ShimmerEffect extends StatefulWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration duration;

  const ShimmerEffect({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    )..addListener(() {
        setState(() {});
      });

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color baseColor = widget.baseColor ?? 
        Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(102);
    final Color highlightColor = widget.highlightColor ?? 
        Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(51);

    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: ClipRect(
            child: FractionallySizedBox(
              widthFactor: 3,
              alignment: Alignment(_animation.value, 0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      baseColor,
                      highlightColor,
                      baseColor,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
