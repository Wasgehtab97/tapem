import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/features/deals/data/providers/deals_provider.dart';
import 'package:tapem/features/deals/presentation/widgets/deal_card.dart';
import 'package:tapem/features/deals/domain/models/deal.dart';
import 'package:tapem/features/deals/data/repositories/deals_repository.dart';
import 'package:tapem/core/widgets/brand_interactive_card.dart';

class DealsScreen extends ConsumerWidget {
  const DealsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dealsAsync = ref.watch(dealsStreamProvider);

    return dealsAsync.when(
      data: (deals) {
        if (deals.isEmpty) {
          return Center(
            child: Text(
              'Aktuell keine Deals verfügbar.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          );
        }
        return _DealsCarousel(deals: deals);
      },
      error: (err, stack) {
        debugPrint('🔴 Deals Error: $err');
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Fehler beim Laden: $err'),
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  static void showDealsInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
        title: const Text('Support the Hustle 🚀'),
        content: const Text(
          'Jeder Einkauf über diese Deals unterstützt nicht nur dich mit fetten Rabatten, '
          'sondern hilft auch deinem Fitnessstudio und der Weiterentwicklung von Tap\'em. '
          '\n\nWin-Win für die ganze Community! Dank dir für den Support. 🔥',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ehrensache!'),
          ),
        ],
      ),
    );
  }
}

class _DealsCarousel extends ConsumerStatefulWidget {
  final List<Deal> deals;
  const _DealsCarousel({required this.deals});

  @override
  ConsumerState<_DealsCarousel> createState() => _DealsCarouselState();
}

class _DealsCarouselState extends ConsumerState<_DealsCarousel> {
  late PageController _pageController;
  late int _virtualItemCount;
  late int _initialPage;
  double _currentPage = 0.0;

  @override
  void initState() {
    super.initState();
    // Use a large number for infinite scroll simulation
    _virtualItemCount = 10000;
    _initialPage = _virtualItemCount ~/ 2;
    // Ensure initial page points to the first deal
    _initialPage = _initialPage - (_initialPage % widget.deals.length);
    
    _pageController = PageController(
      viewportFraction: 0.82,
      initialPage: _initialPage,
    );
    _currentPage = _initialPage.toDouble();
    
    _pageController.addListener(() {
      if (_pageController.hasClients) {
        setState(() {
          _currentPage = _pageController.page!;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        const SizedBox(height: AppSpacing.sm),
        // Stylish Support Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: BrandInteractiveCard(
            onTap: () => DealsScreen.showDealsInfo(context),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            backgroundColor: theme.colorScheme.surface.withOpacity(0.4),
            borderRadius: BorderRadius.circular(16),
            enableScaleAnimation: true,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.rocket_launch_rounded, size: 18, color: AppColors.accentMint),
                const SizedBox(width: 8),
                Text(
                  'Support the Hustle',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.5)),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: _virtualItemCount,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final realIndex = index % widget.deals.length;
              
              // Calculate relative position to center
              double relativePosition = index - _currentPage;
              
              // Smoother scaling curve
              double absPos = relativePosition.abs();
              double scale = (1 - (absPos * 0.12)).clamp(0.85, 1.0);
              double opacity = (1 - (absPos * 0.5)).clamp(0.4, 1.0);
              double translateY = (absPos * 10.0).clamp(0.0, 10.0);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Center(
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Transform.translate(
                      offset: Offset(0, translateY),
                      child: Transform.scale(
                        scale: scale,
                        child: Opacity(
                          opacity: opacity,
                          child: DealCard(
                            deal: widget.deals[realIndex],
                            onTrackClick: () {
                              ref.read(dealsRepositoryProvider).trackClick(widget.deals[realIndex].id);
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Premium Indicator
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.deals.length, (index) {
              bool active = index == (_currentPage.round() % widget.deals.length);
              return AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 6,
                width: active ? 28 : 8,
                decoration: BoxDecoration(
                  gradient: active 
                    ? LinearGradient(colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ])
                    : null,
                  color: active ? null : Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: active ? [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ] : [],
                ),
              );
            }),
          ),
        ),
        // Disclaimer Bottom Right
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, AppSpacing.lg, AppSpacing.lg),
            child: Opacity(
              opacity: 0.5,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info_outline_rounded, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Aktuell nur Demo-Deals – Real Hustle coming soon! 🚀',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

