import 'package:flutter/material.dart';
import 'package:tapem/features/auth/presentation/theme/auth_theme.dart';

class AuthBackground extends StatelessWidget {
  final Widget child;

  const AuthBackground({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const ColoredBox(color: AuthTheme.background),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AuthTheme.backgroundRaised, AuthTheme.background],
              ),
            ),
          ),
        ),
        Positioned(
          top: -120,
          right: -80,
          child: _GlowOrb(color: Colors.white.withOpacity(0.045), size: 320),
        ),
        Positioned(
          bottom: -160,
          left: -90,
          child: _GlowOrb(color: Colors.white.withOpacity(0.035), size: 360),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.25),
                  Colors.black.withOpacity(0.55),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
        ),
        SafeArea(child: child),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color,
              blurRadius: size * 0.6,
              spreadRadius: size * 0.18,
            ),
          ],
        ),
      ),
    );
  }
}
