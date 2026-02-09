import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

const trainingDoneAssetPath = 'assets/images/training_done.png';
const _overlayExitDuration = Duration(milliseconds: 220);

class TrainingDoneOverlay {
  TrainingDoneOverlay._();

  static OverlayEntry? _entry;
  static DateTime? _shownAt;
  static ValueNotifier<bool>? _visibilityNotifier;

  static bool get isVisible => _entry != null;

  static Future<void> precache(BuildContext context) {
    return precacheImage(const AssetImage(trainingDoneAssetPath), context);
  }

  static void show(GlobalKey<NavigatorState> navigatorKey) {
    if (_entry != null) {
      _visibilityNotifier?.value = true;
      return;
    }
    final overlayState = navigatorKey.currentState?.overlay;
    if (overlayState == null) return;
    _shownAt = DateTime.now();
    final visibilityNotifier = ValueNotifier<bool>(true);
    _visibilityNotifier = visibilityNotifier;
    final entry = OverlayEntry(
      builder: (_) =>
          _TrainingDoneOverlayWidget(visibilityListenable: visibilityNotifier),
    );
    _entry = entry;
    overlayState.insert(entry);
  }

  static Future<void> hide({
    Duration minVisible = Duration.zero,
  }) async {
    final shownAt = _shownAt;
    if (shownAt != null && minVisible > Duration.zero) {
      final elapsed = DateTime.now().difference(shownAt);
      final remaining = minVisible - elapsed;
      if (remaining > Duration.zero) {
        await Future<void>.delayed(remaining);
      }
    }
    final visibilityNotifier = _visibilityNotifier;
    if (visibilityNotifier != null) {
      visibilityNotifier.value = false;
      await Future<void>.delayed(_overlayExitDuration);
    }
    clear();
  }

  static void clear() {
    final entry = _entry;
    final visibilityNotifier = _visibilityNotifier;
    _entry = null;
    _shownAt = null;
    _visibilityNotifier = null;
    entry?.remove();
    visibilityNotifier?.dispose();
  }
}

class _TrainingDoneOverlayWidget extends StatefulWidget {
  const _TrainingDoneOverlayWidget({
    required this.visibilityListenable,
  });

  final ValueListenable<bool> visibilityListenable;

  @override
  State<_TrainingDoneOverlayWidget> createState() =>
      _TrainingDoneOverlayWidgetState();
}

class _TrainingDoneOverlayWidgetState extends State<_TrainingDoneOverlayWidget>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final AnimationController _pulseController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _entryScaleAnimation;
  late final Animation<double> _pulseScaleAnimation;
  Timer? _statusTimer;
  bool _showPreparingState = false;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..forward();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _fadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );
    _entryScaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Curves.elasticOut,
      ),
    );
    _pulseScaleAnimation = Tween<double>(begin: 1.0, end: 1.035).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
    _statusTimer = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() {
        _showPreparingState = true;
      });
    });
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _entryController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.maybeOf(context);
    final disableAnimations = mediaQuery?.disableAnimations ?? false;
    final shortestSide = mediaQuery?.size.shortestSide ?? 360;
    final logoSize = (shortestSide * 0.52).clamp(200.0, 360.0);
    final theme = Theme.of(context);

    return IgnorePointer(
      ignoring: true,
      child: Material(
        color: Colors.transparent,
        child: ValueListenableBuilder<bool>(
          valueListenable: widget.visibilityListenable,
          builder: (context, visible, child) {
            return AnimatedOpacity(
              opacity: visible ? 1.0 : 0.0,
              duration: _overlayExitDuration,
              curve: Curves.easeOut,
              child: AnimatedScale(
                scale: visible ? 1.0 : 0.97,
                duration: _overlayExitDuration,
                curve: Curves.easeOut,
                child: child,
              ),
            );
          },
          child: AnimatedBuilder(
            animation: Listenable.merge([_entryController, _pulseController]),
            builder: (context, _) {
              final opacity = disableAnimations ? 1.0 : _fadeAnimation.value;
              final baseScale =
                  disableAnimations ? 1.0 : _entryScaleAnimation.value;
              final pulseScale =
                  disableAnimations ? 1.0 : _pulseScaleAnimation.value;
              return Opacity(
                opacity: opacity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const _TrainingDoneBackdrop(),
                    SafeArea(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Transform.scale(
                                  scale: baseScale * pulseScale,
                                  child: SizedBox(
                                    width: logoSize,
                                    height: logoSize,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        DecoratedBox(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.white
                                                    .withOpacity(0.22),
                                                blurRadius: logoSize * 0.24,
                                                spreadRadius: logoSize * 0.04,
                                              ),
                                            ],
                                          ),
                                          child: SizedBox(
                                            width: logoSize * 0.78,
                                            height: logoSize * 0.78,
                                          ),
                                        ),
                                        Image.asset(
                                          trainingDoneAssetPath,
                                          fit: BoxFit.contain,
                                          filterQuality: FilterQuality.high,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 250),
                                  switchInCurve: Curves.easeOut,
                                  switchOutCurve: Curves.easeOut,
                                  child: Text(
                                    _showPreparingState
                                        ? 'Highlights werden vorbereitet...'
                                        : 'Training wird gespeichert...',
                                    key: ValueKey<bool>(_showPreparingState),
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: Colors.white.withOpacity(0.95),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TrainingDoneBackdrop extends StatelessWidget {
  const _TrainingDoneBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xF2080A10),
                Color(0xF7020305),
              ],
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.28),
              radius: 0.9,
              colors: [
                Colors.white.withOpacity(0.12),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }
}
