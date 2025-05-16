import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_ride/core/animations/animations.dart';

class AnimatedCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final double? elevation;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double? width;
  final double? height;
  final int index;
  final bool useStaggeredAnimation;

  const AnimatedCard({
    Key? key,
    required this.child,
    this.onTap,
    this.color,
    this.elevation,
    this.borderRadius,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.only(bottom: 16),
    this.width,
    this.height,
    this.index = 0,
    this.useStaggeredAnimation = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        margin: margin,
        decoration: BoxDecoration(
          color: color ?? theme.cardTheme.color,
          borderRadius: borderRadius ?? BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: elevation ?? 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ).animate(
        onPlay: (controller) => controller.forward(),
      ).then(
        delay: useStaggeredAnimation ? (50 * index).ms : 0.ms,
      ).fadeIn(
        duration: 400.ms,
        curve: Curves.easeOut,
      ).slideY(
        begin: 0.1,
        end: 0,
        duration: 500.ms,
        curve: Curves.easeOutQuart,
      ),
    );
  }
}
