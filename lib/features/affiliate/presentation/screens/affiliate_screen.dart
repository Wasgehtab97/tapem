import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';

class AffiliateScreen extends StatefulWidget {
  const AffiliateScreen({super.key});

  @override
  State<AffiliateScreen> createState() => _AffiliateScreenState();
}

class _AffiliateScreenState extends State<AffiliateScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final accent = brandTheme?.outline ?? theme.colorScheme.secondary;
    final onSurface = theme.colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Affiliate',
          style: TextStyle(color: accent, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        foregroundColor: accent,
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final bgTop = Color.lerp(
            AppColors.background,
            const Color(0xFF10121A),
            t,
          )!;
          final bgBottom = Color.lerp(
            const Color(0xFF050608),
            const Color(0xFF050712),
            1 - t,
          )!;

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [bgTop, bgBottom],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroBanner(
                      accent: accent,
                      onSurface: onSurface,
                      animation: _controller,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Entdecke bald',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: onSurface.withOpacity(0.9),
                        letterSpacing: 0.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const _CategoryPills(),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Preview',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: onSurface.withOpacity(0.7),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _ProductList(animation: _controller),
                    const SizedBox(height: AppSpacing.lg),
                    _InfoBox(accent: accent, onSurface: onSurface),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({
    required this.accent,
    required this.onSurface,
    required this.animation,
  });

  final Color accent;
  final Color onSurface;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wave = math.sin(animation.value * 2 * math.pi);
    final scale = 1.0 + 0.015 * wave;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Transform.scale(
        scale: scale,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.cardLg),
            gradient: LinearGradient(
              begin: Alignment(-0.4 + 0.2 * wave, -0.6),
              end: const Alignment(1.0, 1.0),
              colors: AppGradients.brandGradient.colors,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.45),
                blurRadius: 28,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.18),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.25),
                          width: 1.4,
                        ),
                      ),
                      child: const Icon(
                        Icons.shopping_bag_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Studio‑Shop',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Bald findest du hier exklusive Deals deines Gyms – von Merch bis Supplements.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Coming soon',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.white.withOpacity(0.85),
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryPills extends StatelessWidget {
  const _CategoryPills();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    const categories = [
      'Merch & Apparel',
      'Supplements',
      'Equipment',
      'Lifestyle',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final label in categories)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.chip),
              color: AppColors.surface,
              border: Border.all(
                color: onSurface.withOpacity(0.08),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.circle,
                  size: 6,
                  color: theme.colorScheme.secondary.withOpacity(0.9),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: onSurface.withOpacity(0.8),
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ProductList extends StatelessWidget {
  const _ProductList({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ProductCard(
          title: 'Gym Hoodie',
          subtitle: 'Limited Studio Drop',
          animation: animation,
          index: 0,
        ),
        const SizedBox(height: AppSpacing.sm),
        _ProductCard(
          title: 'Performance Stack',
          subtitle: 'Protein, Booster & mehr',
          animation: animation,
          index: 1,
        ),
        const SizedBox(height: AppSpacing.sm),
        _ProductCard(
          title: 'Lifting Essentials',
          subtitle: 'Gürtel, Grips & Straps',
          animation: animation,
          index: 2,
        ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.title,
    required this.subtitle,
    required this.animation,
    required this.index,
  });

  final String title;
  final String subtitle;
  final Animation<double> animation;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    final shimmer = 0.15 + 0.10 * math.sin(animation.value * 2 * math.pi);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 450 + index * 140),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: onSurface.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.card),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.accentMint.withOpacity(0.6 + shimmer),
                    AppColors.accentTurquoise.withOpacity(0.5),
                    AppColors.accentAmber.withOpacity(0.3),
                  ],
                ),
              ),
              child: const Icon(
                Icons.image_outlined,
                color: Colors.white70,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: onSurface.withOpacity(0.92),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.chip),
                          color: AppColors.background,
                        ),
                        child: Text(
                          'Bald verfügbar',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: onSurface.withOpacity(0.7),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({
    required this.accent,
    required this.onSurface,
  });

  final Color accent;
  final Color onSurface;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: onSurface.withOpacity(0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: accent.withOpacity(0.9),
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Dieser Bereich ist ein Preview. In Zukunft kannst du hier Studio‑Merch, Equipment und Supplements direkt über tap‑em entdecken – kuratiert von deinem Gym.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: onSurface.withOpacity(0.7),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
