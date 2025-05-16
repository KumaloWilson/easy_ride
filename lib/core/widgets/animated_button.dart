import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AnimatedButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? width;
  final double height;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry padding;
  final bool isLoading;
  final bool isOutlined;
  final bool isDisabled;

  const AnimatedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
    this.height = 56,
    this.borderRadius,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
    this.isLoading = false,
    this.isOutlined = false,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ??
        (isOutlined ? Colors.transparent : theme.colorScheme.primary);
    final fgColor = foregroundColor ??
        (isOutlined ? theme.colorScheme.primary : Colors.white);
    final radius = borderRadius ?? BorderRadius.circular(12);

    return GestureDetector(
      onTap: (isLoading || isDisabled) ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDisabled
              ? (isOutlined ? Colors.transparent : Colors.grey.shade300)
              : bgColor,
          borderRadius: radius,
          border: isOutlined
              ? Border.all(
            color: isDisabled ? Colors.grey.shade400 : fgColor,
            width: 2,
          )
              : null,
        ),
        child: Center(
          child: Padding(
            padding: padding,
            child: isLoading
                ? SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(fgColor),
              ),
            )
                : DefaultTextStyle(
              style: TextStyle(
                color: isDisabled
                    ? (isOutlined ? Colors.grey.shade400 : Colors.grey.shade600)
                    : fgColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              child: child,
            ),
          ),
        ),
      ).animate(
        onPlay: (controller) => controller.forward(),
      ).scaleXY(
        begin: 1.0,
        end: isDisabled ? 1.0 : 0.98,
        duration: 100.ms,
        curve: Curves.easeInOut,
      ).then(delay: 50.ms).scaleXY(
        begin: isDisabled ? 1.0 : 0.98,
        end: 1.0,
        duration: 100.ms,
        curve: Curves.easeInOut,
      ),
    );
  }
}