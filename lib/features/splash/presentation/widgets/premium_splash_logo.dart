import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

class PremiumSplashLogo extends StatefulWidget {
  const PremiumSplashLogo({super.key});

  @override
  State<PremiumSplashLogo> createState() => _PremiumSplashLogoState();
}

class _PremiumSplashLogoState extends State<PremiumSplashLogo>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final AnimationController _pulseController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _fadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 1.0, curve: Curves.elasticOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logoWidth =
        (MediaQuery.of(context).size.width * 0.72).clamp(280.0, 420.0).toDouble();

    return AnimatedBuilder(
      animation: Listenable.merge([_entryController, _pulseController]),
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value * _pulseAnimation.value,
            child: child,
          ),
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: logoWidth,
            child: Image.asset(
              'assets/images/splash.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.fitness_center_rounded,
                  size: 80,
                  color: AppColors.accentMint,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
