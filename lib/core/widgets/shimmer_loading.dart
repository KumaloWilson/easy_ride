import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final bool isLoading;
  final Widget? child;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 4.0,
    this.isLoading = true,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading) {
      return child ?? Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          color: Colors.grey[300],
        ),
      );
    }

    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          color: Colors.white,
        ),
      ),
    );
  }
}
