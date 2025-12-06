import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/auth_theme.dart';

class AuthBackground extends StatelessWidget {
  final Widget child;

  const AuthBackground({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base Gradient Background
        Container(
          decoration: const BoxDecoration(
            gradient: AuthTheme.backgroundGradient,
          ),
        ),

        // Floating Orbs (Parallax/Animated)
        Positioned(
          top: -100,
          left: -100,
          child: _buildBlurOrb(
            const Color(0xFF8B5CF6).withOpacity(0.3), // Purple
            300,
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
           .move(duration: 10.seconds, begin: const Offset(0, 0), end: const Offset(50, 50))
           .scale(duration: 15.seconds, begin: const Offset(1, 1), end: const Offset(1.2, 1.2)),
        ),

        Positioned(
          bottom: 100,
          right: -50,
          child: _buildBlurOrb(
            const Color(0xFF3B82F6).withOpacity(0.2), // Blue
            250,
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
           .move(duration: 12.seconds, begin: const Offset(0, 0), end: const Offset(-30, -30))
           .scale(duration: 8.seconds, begin: const Offset(1, 1), end: const Offset(1.3, 1.3)),
        ),
        
        Positioned(
          top: 300,
          right: -100,
          child: _buildBlurOrb(
            const Color(0xFFF472B6).withOpacity(0.15), // Pink
            200,
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
           .move(duration: 14.seconds, begin: const Offset(0, 0), end: const Offset(-20, 40)),
        ),

        // Content
        SafeArea(child: child),
      ],
    );
  }

  Widget _buildBlurOrb(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: size / 2,
            spreadRadius: size / 4,
          ),
        ],
      ),
    );
  }
}
