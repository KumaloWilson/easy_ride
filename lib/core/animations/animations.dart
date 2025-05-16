import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Animation presets for consistent animations across the app
class AppAnimations {
  // Page transitions
  static List<Effect> get pageTransition => [
        FadeEffect(
          duration: 300.ms,
          curve: Curves.easeOut,
        ),
        SlideEffect(
          duration: 400.ms,
          begin: const Offset(0.1, 0),
          end: Offset.zero,
          curve: Curves.easeOutQuart,
        ),
      ];

  // Button tap animation
  static List<Effect> get buttonTap => [
        ScaleEffect(
          duration: 150.ms,
          begin: const Offset(1, 1),
          end: const Offset(0.95, 0.95),
          curve: Curves.easeInOut,
        ),
      ];

  // Card entry animation
  static List<Effect> get cardEntry => [
        FadeEffect(
          duration: 400.ms,
          curve: Curves.easeOut,
        ),
        SlideEffect(
          duration: 500.ms,
          begin: const Offset(0, 0.1),
          end: Offset.zero,
          curve: Curves.easeOutQuart,
        ),
      ];

  // Map marker animation
  static List<Effect> get mapMarker => [
        ScaleEffect(
          duration: 300.ms,
          begin: const Offset(0.5, 0.5),
          end: const Offset(1, 1),
          curve: Curves.elasticOut,
        ),
        FadeEffect(
          duration: 200.ms,
          curve: Curves.easeOut,
        ),
      ];

  // Staggered list item animation
  static List<Effect> staggeredListItem(int index) => [
        FadeEffect(
          duration: 400.ms,
          delay: (50 * index).ms,
          curve: Curves.easeOut,
        ),
        SlideEffect(
          duration: 500.ms,
          delay: (50 * index).ms,
          begin: const Offset(0, 0.1),
          end: Offset.zero,
          curve: Curves.easeOutQuart,
        ),
      ];

  // Pulse animation for attention
  static List<Effect> get pulse => [
        ScaleEffect(
          duration: 600.ms,
          begin: const Offset(1, 1),
          end: const Offset(1.05, 1.05),
          curve: Curves.easeInOut,
        )
      ];

  // Shimmer loading effect
  static List<Effect> get shimmer => [
        ShimmerEffect(
          duration: 1200.ms,
          color: Colors.white.withOpacity(0.5),
          curve: Curves.easeInOut,
        )
      ];

  // Success animation
  static List<Effect> get success => [
        ScaleEffect(
          duration: 200.ms,
          begin: const Offset(0.5, 0.5),
          end: const Offset(1, 1),
          curve: Curves.elasticOut,
        ),
        RotateEffect(
          duration: 400.ms,
          begin: -0.1,
          end: 0,
          curve: Curves.elasticOut,
        ),
      ];
}
