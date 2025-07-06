import 'package:flutter/material.dart';

class SmoothPageTransition extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;
  final Animation<double> secondaryAnimation;

  const SmoothPageTransition({
    super.key,
    required this.child,
    required this.animation,
    required this.secondaryAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        // Curva personalizada para una transición más suave
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutCubic,
          reverseCurve: Curves.easeInOutCubic,
        );

        // Transición combinada: fade + slide
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.1, 0.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: FadeTransition(
            opacity: Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class SmoothPageTransitionBuilder {
  static Widget buildTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SmoothPageTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      child: child,
    );
  }
} 