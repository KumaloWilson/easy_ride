import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LottieAnimation extends StatelessWidget {
  final String animationPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool repeat;
  final bool animate;
  final Duration? duration;
  final VoidCallback? onLoaded;

  const LottieAnimation({
    Key? key,
    required this.animationPath,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.repeat = true,
    this.animate = true,
    this.duration,
    this.onLoaded,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      animationPath,
      width: width,
      height: height,
      fit: fit,
      repeat: repeat,
      animate: animate,
      frameRate: FrameRate.max,
      delegates: LottieDelegates(
        values: [
          ValueDelegate.color(
            const ['**'],
            value: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
      onLoaded: (composition) {
        if (onLoaded != null) {
          onLoaded!();
        }
      },
    );
  }
}
