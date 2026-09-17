import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../constants/app_animations.dart';

class AppLoader extends StatelessWidget {
  final double? width;
  final double? height;

  const AppLoader({
    super.key,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      AppAnimations.astrologyLoading,
      width: width,
      height: height,
      fit: BoxFit.contain,
    );
  }
}
