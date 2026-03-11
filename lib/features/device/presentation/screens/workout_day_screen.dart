import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapem/core/navigation/workout_flow_navigation.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/services/workout_session_coordinator.dart';
import 'package:tapem/core/services/workout_session_duration_service.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/providers/settings_provider.dart';
import 'package:tapem/core/widgets/offline_banner.dart';
import 'package:tapem/core/widgets/premium_action_tile.dart';
import 'package:tapem/app_router.dart';

import 'package:tapem/features/device/presentation/controllers/workout_day_controller.dart';
import 'package:tapem/features/device/presentation/models/workout_device_selection.dart';
import 'package:tapem/features/device/presentation/workout_manual_stop_flow.dart';
import 'package:tapem/features/device/presentation/widgets/device_session_section.dart';
import 'package:tapem/features/gym/presentation/screens/gym_screen.dart';
import 'package:tapem/bootstrap/navigation.dart';

import 'package:tapem/features/nfc/widgets/nfc_scan_button.dart';
import 'package:tapem/ui/numeric_keypad/overlay_numeric_keypad.dart';
import 'package:tapem/ui/timer/active_workout_timer.dart';
import 'package:tapem/features/device/presentation/widgets/session_rest_timer.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/features/device/providers/workout_day_controller_provider.dart';
import 'package:tapem/features/device/providers/workout_entry_orchestrator_provider.dart';

class WorkoutDayScreen extends riverpod.ConsumerStatefulWidget {
  static const staleEntryMaxAge = Duration(seconds: 15);

  const WorkoutDayScreen({
    super.key,
    required this.gymId,
    required this.deviceId,
    required this.exerciseId,
    this.planId,
    this.planName,
    this.entryRequestedAtMs,
    this.sessionBuilder,
    this.closeSessionOnDispose = false,
    this.showInlineOfflineBanner = true,
  });

  final String gymId;
  final String deviceId;
  final String exerciseId;
  final String? planId;
  final String? planName;
  final int? entryRequestedAtMs;
  final Widget Function(
    BuildContext context,
    WorkoutDaySession session,
    int displayIndex,
  )?
  sessionBuilder;
  final bool closeSessionOnDispose;
  final bool showInlineOfflineBanner;

  @override
  riverpod.ConsumerState<WorkoutDayScreen> createState() =>
      _WorkoutDayScreenState();
}

class _WorkoutDayScreenState extends riverpod.ConsumerState<WorkoutDayScreen> {
  static const double _headerRestTimerWidth = 80;
  static const double _headerTimerGap = 6;
  final ScrollController _scrollController = ScrollController();
  String? _sessionKey;
  bool _isInitializing = true;
  bool _ownsSession = false;
  String? _planId;
  String? _planName;
  int? _globalRestSeconds;
  String? _loadedRestTimerUserId;
  final GlobalKey<SessionRestTimerState> _globalRestTimerKey =
      GlobalKey<SessionRestTimerState>();

  Future<void> _handleSelection(WorkoutDeviceSelection selection) async {
    final auth = ref.read(authControllerProvider);
    final userId = auth.userId;
    if (userId == null) return;
    final controller = ref.read(workoutDayControllerProvider);
    final coordinator = ref.read(workoutSessionCoordinatorProvider);
    final orchestrator = ref.read(workoutEntryOrchestratorProvider);
    final result = await orchestrator.addOrFocusFromExternalSource(
      controller: controller,
      coordinator: coordinator,
      gymId: selection.gymId,
      deviceId: selection.deviceId,
      exerciseId: selection.exerciseId,
      exerciseName: selection.exerciseName,
      userId: userId,
    );

    if (!mounted) return;

    // Close keyboard before scrolling
    FocusManager.instance.primaryFocus?.unfocus();
    final keypad = ref.read(overlayNumericKeypadControllerProvider);
    keypad.close();

    setState(() {});
    _scrollToLatest();
    _sessionKey ??= result.session?.key;
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  String _globalRestPrefKey(String userId) => 'restTimer/$userId/global';

  Future<void> _ensureGlobalRestTimerLoaded(String userId) async {
    if (_loadedRestTimerUserId == userId) return;
    _loadedRestTimerUserId = userId;
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getInt(_globalRestPrefKey(userId));
      if (!mounted) return;
      setState(() => _globalRestSeconds = stored);
      if (stored != null) {
        _globalRestTimerKey.currentState?.applyInitialSeconds(stored);
      }
    } catch (_) {
      // fail silently; timer just falls back to default
    }
  }

  Future<void> _persistGlobalRestSeconds(int seconds) async {
    setState(() => _globalRestSeconds = seconds);
    final userId = ref.read(authControllerProvider).userId;
    if (userId == null || userId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_globalRestPrefKey(userId), seconds);
    } catch (_) {
      // ignore persistence failure
    }
  }

  void _handleGlobalRestTimerInteraction() {
    FocusManager.instance.primaryFocus?.unfocus();
    final keypad = ref.read(overlayNumericKeypadControllerProvider);
    if (keypad.isOpen) {
      keypad.close();
    }
  }

  Widget _buildHeaderRestTimer() {
    return SizedBox(
      width: _headerRestTimerWidth,
      child: Align(
        alignment: Alignment.centerLeft,
        child: SessionRestTimer(
          key: _globalRestTimerKey,
          initialSeconds: _globalRestSeconds,
          onInteraction: _handleGlobalRestTimerInteraction,
          onDurationChanged: (seconds) => _persistGlobalRestSeconds(seconds),
          compact: true,
          inline: true,
          showLabel: true,
        ),
      ),
    );
  }

  void _syncSessionKey(List<WorkoutDaySession> sessions) {
    final currentKey = _sessionKey;
    if (currentKey == null) return;
    final exists = sessions.any((session) => session.key == currentKey);
    if (exists) return;
    final nextKey = sessions.isNotEmpty ? sessions.last.key : null;
    if (nextKey == currentKey) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _sessionKey = nextKey;
        _ownsSession = false;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _planId = widget.planId;
    _planName = widget.planName;
    debugPrint(
      '🏋️ WorkoutDayScreen init gymId=${widget.gymId} deviceId=${widget.deviceId} exerciseId=${widget.exerciseId} planId=$_planId planName=$_planName',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureSession());
  }

  Future<void> _ensureSession() async {
    final auth = ref.read(authControllerProvider);
    final controller = ref.read(workoutDayControllerProvider);
    final coordinator = ref.read(workoutSessionCoordinatorProvider);
    final durationService = ref.read(workoutSessionDurationServiceProvider);
    final userId = auth.userId;
    if (userId == null || userId.isEmpty) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
      return;
    }
    await _ensureGlobalRestTimerLoaded(userId);
    final contextKey = WorkoutDayController.contextKey(
      gymId: widget.gymId,
      deviceId: widget.deviceId,
      exerciseId: widget.exerciseId,
      userId: userId,
    );
    final existingSession = controller.sessionForKey(contextKey);
    final hasRunningTraining =
        coordinator.isRunning && durationService.isRunning;
    final hasFinalizeMarker =
        coordinator.finalizedAt != null || coordinator.finalizeReason != null;
    final isFreshEntry = _isFreshEntryRequest();
    if (!hasRunningTraining &&
        existingSession == null &&
        hasFinalizeMarker &&
        !isFreshEntry) {
      debugPrint(
        '🏁 [WorkoutFlow] stale_workout_route_blocked gym=${widget.gymId} device=${widget.deviceId} exercise=${widget.exerciseId}',
      );
      await navigateToHomeProfile(
        navigatorKey: navigatorKey,
        source: 'stale_workout_route',
      );
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _sessionKey = null;
          _ownsSession = false;
        });
      }
      return;
    }
    final anchorStartAt = coordinator.anchorStartAt;
    final anchorDayKey = coordinator.anchorDayKey;
    // Drafts (ungeplante offene Sessions) automatisch wiederherstellen
    await controller.restoreDraftSessions(userId: userId, gymId: widget.gymId);
    // Plan-Kontext ggf. im Controller hinterlegen oder von dort übernehmen
    final existingPlan = controller.getPlanContext(
      gymId: widget.gymId,
      date: anchorStartAt,
      dayKey: anchorDayKey,
    );
    if (_planId != null) {
      controller.setPlanContext(
        gymId: widget.gymId,
        planId: _planId!,
        planName: _planName,
        date: anchorStartAt,
        dayKey: anchorDayKey,
      );
    } else if (existingPlan != null) {
      _planId ??= existingPlan.$1;
      _planName ??= existingPlan.$2;
      debugPrint(
        '📎 WorkoutDayScreen adopted existing plan context planId=$_planId planName=$_planName',
      );
    }
    final alreadyExists = controller.sessionForKey(contextKey) != null;
    final session = controller.addOrFocusSession(
      gymId: widget.gymId,
      deviceId: widget.deviceId,
      exerciseId: widget.exerciseId,
      userId: userId,
    );
    if (!alreadyExists) {
      await ref
          .read(workoutSessionCoordinatorProvider)
          .onExerciseAddedFromGymOrNfc(uid: userId, gymId: widget.gymId);
    }
    if (mounted) {
      setState(() {
        _sessionKey = session.key;
        _isInitializing = false;
        if (!alreadyExists) {
          _ownsSession = true;
        }
      });
      _scrollToLatest();
    }
  }

  bool _isFreshEntryRequest() {
    final requestedAtMs = widget.entryRequestedAtMs;
    if (requestedAtMs == null || requestedAtMs <= 0) {
      return false;
    }
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final ageMs = nowMs - requestedAtMs;
    return ageMs >= 0 &&
        ageMs <= WorkoutDayScreen.staleEntryMaxAge.inMilliseconds;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    final key = _sessionKey;
    if (widget.closeSessionOnDispose && key != null && _ownsSession) {
      final controller = ref.read(workoutDayControllerProvider);
      if (controller.sessionForKey(key) != null) {
        controller.closeSession(key);
      }
    }
    super.dispose();
  }

  void _handleCloseSession(WorkoutDaySession session) {
    final controller = ref.read(workoutDayControllerProvider);
    final closed = controller.closeSession(session.key);
    if (closed && session.key == _sessionKey) {
      _sessionKey = null;
      _ownsSession = false;
    }
    if (!mounted) return;
    if (!closed) {
      setState(() {});
      return;
    }
    final auth = ref.read(authControllerProvider);
    final userId = auth.userId;
    final activeGymId = auth.gymCode ?? session.gymId;
    final remaining = (userId == null)
        ? const <WorkoutDaySession>[]
        : controller.sessionsFor(userId: userId, gymId: activeGymId);
    if (remaining.isEmpty) {
      Navigator.of(context).maybePop();
    } else {
      setState(() {});
    }
  }

  void _navigateToAddExercise() {
    // Robustly close keyboard and clear focus
    final dayController = ref.read(workoutDayControllerProvider);
    dayController.focusedProvider?.clearFocus();

    final keypadController = ref.read(overlayNumericKeypadControllerProvider);
    if (keypadController.isOpen) {
      keypadController.close();
    }

    FocusManager.instance.primaryFocus?.unfocus();

    // Immer zurück zur Gym-Page der Home-Tabs (Index 0).
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRouter.home, (route) => false, arguments: 0);
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(workoutDayControllerProvider);
    final auth = ref.watch(authControllerProvider);
    final activeGymId = auth.gymCode ?? widget.gymId;
    final userId = auth.userId;
    final sessions = (userId == null)
        ? const <WorkoutDaySession>[]
        : controller.sessionsFor(userId: userId, gymId: activeGymId);
    _syncSessionKey(sessions);

    final loc = AppLocalizations.of(context)!;
    final showInlineOfflineBanner =
        widget.showInlineOfflineBanner &&
        (ModalRoute.of(context)?.canPop ?? false);

    // LUX: Auto-scroll to top when a new session is added (e.g. via NFC)
    ref.listen(
      workoutDayControllerProvider.select((c) {
        final uid = auth.userId;
        final gid = auth.gymCode ?? widget.gymId;
        return c.sessionsFor(userId: uid ?? '', gymId: gid).length;
      }),
      (prev, next) {
        if (next > (prev ?? 0)) {
          _scrollToLatest();
        }
      },
    );

    if (_isInitializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    final brandColor = theme.colorScheme.primary;

    const screenTop = Color(0xFF05060A);
    const screenBottom = Color(0xFF020305);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: screenTop,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 110, // etwas kompakter für "< Übungen"
        leading: InkWell(
          onTap: _navigateToAddExercise,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            margin: const EdgeInsets.only(left: 8),
            padding: const EdgeInsets.symmetric(
              horizontal: 4,
            ), // Reduced padding
            child: Row(
              children: [
                Icon(Icons.chevron_left, color: brandColor, size: 20),
                const SizedBox(width: 2),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Übungen',
                      style: theme.textTheme.labelMedium?.copyWith(
                        // Smaller text style
                        color: brandColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        centerTitle: true,
        titleSpacing: 0,
        toolbarHeight: kToolbarHeight + 8,
        title: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize
                  .min, // Keep min to allow centering if space permits
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ActiveWorkoutTimer(
                  key: ValueKey('workoutDayTimer-${_sessionKey ?? 'global'}'),
                  compact: true,
                  padding: EdgeInsets.zero,
                  sessionKey: _sessionKey,
                ),
                const SizedBox(width: _headerTimerGap),
                _buildHeaderRestTimer(),
              ],
            ),
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(8),
          child: SizedBox(height: 8),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.check, color: brandColor),
            tooltip: 'Zum Speichern-Button',
            onPressed: _scrollToBottom,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: NfcScanButton(
              onBeforeOpen: () => FocusManager.instance.primaryFocus?.unfocus(),
              onSelection: (selection) async {
                await _handleSelection(selection);
              },
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [screenTop, screenBottom],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              if (showInlineOfflineBanner) const OfflineBanner(),
              Expanded(
                child: riverpod.Consumer(
                  builder: (context, ref, _) {
                    final keypadController = ref.watch(
                      overlayNumericKeypadControllerProvider,
                    );
                    final bottomSpacerHeight =
                        keypadController.keypadContentHeight +
                        MediaQuery.of(context).padding.bottom +
                        24;

                    if (sessions.isEmpty) {
                      return CustomScrollView(
                        controller: _scrollController,
                        slivers: [
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Text(
                                loc.multiDeviceNewExercise,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    return Scrollbar(
                      controller: _scrollController,
                      child: ReorderableListView.builder(
                        scrollController: _scrollController,
                        padding: const EdgeInsets.only(top: 10, bottom: 14),
                        buildDefaultDragHandles: false,
                        proxyDecorator: (child, index, animation) {
                          // Deutlichere visuelle Rückmeldung während des Drag-Vorgangs.
                          return Material(
                            color: Colors.transparent,
                            elevation: 12,
                            shadowColor: brandColor.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(24),
                            child: ScaleTransition(
                              scale: Tween<double>(begin: 1.0, end: 1.03)
                                  .animate(
                                    CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeOut,
                                    ),
                                  ),
                              child: child,
                            ),
                          );
                        },
                        onReorder: (oldIndex, newIndex) {
                          // Letztes Element ist der "Training speichern"-Button
                          // und darf nicht als Ziel für Reordering verwendet werden.
                          final userId = auth.userId;
                          if (userId == null) return;
                          if (oldIndex >= sessions.length ||
                              newIndex > sessions.length) {
                            return;
                          }
                          newIndex = newIndex.clamp(0, sessions.length - 1);
                          controller.reorderSessions(
                            userId: userId,
                            gymId: activeGymId,
                            oldIndex: oldIndex,
                            newIndex: newIndex,
                          );
                          setState(() {});
                        },
                        itemCount: sessions.length + 1,
                        itemBuilder: (context, index) {
                          // Footer-Zeile: "Training speichern"-Button
                          if (index == sessions.length) {
                            return Padding(
                              key: const ValueKey('save-button-footer'),
                              padding: EdgeInsets.only(
                                left: 16,
                                right: 16,
                                bottom: bottomSpacerHeight,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _AddExerciseButton(
                                    onPressed: _navigateToAddExercise,
                                  ),
                                  _SaveAllButton(
                                    isSaving: controller.isSaving,
                                    canSave: controller.canSave,
                                    onPressed: _handleSaveAllSessions,
                                  ),
                                ],
                              ),
                            );
                          }

                          final session = sessions[index];
                          final builder = widget.sessionBuilder;
                          final displayIndex = index + 1;
                          final key = ValueKey(session.key);

                          Widget child;
                          if (builder != null) {
                            child = Container(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: builder(context, session, displayIndex),
                            );
                          } else {
                            child = Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: DeviceSessionSection(
                                provider: session.provider,
                                gymId: session.gymId,
                                deviceId: session.deviceId,
                                exerciseId: session.exerciseId,
                                exerciseName: session.exerciseName,
                                userId: session.userId,
                                displayIndex: displayIndex,
                                sessionKey: session.key,
                                onCloseRequested: () =>
                                    _handleCloseSession(session),
                              ),
                            );
                          }

                          return ReorderableDelayedDragStartListener(
                            key: key,
                            index: index,
                            child: child,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSaveAllSessions() async {
    final controller = ref.read(workoutDayControllerProvider);
    final auth = ref.read(authControllerProvider);
    final settings = ref.read(settingsProvider);
    final sessionCoordinator = ref.read(workoutSessionCoordinatorProvider);

    // Tastaturen sofort schließen, bevor Dialoge/Speichern starten.
    FocusManager.instance.primaryFocus?.unfocus();
    ref.read(overlayNumericKeypadControllerProvider).close();

    await WorkoutManualStopFlow.saveFromWorkoutDay(
      context: context,
      auth: auth,
      controller: controller,
      settings: settings,
      sessionCoordinator: sessionCoordinator,
      container: riverpod.ProviderScope.containerOf(context, listen: false),
      customNavigatorKey: navigatorKey,
    );
  }
}

class _AddExerciseButton extends StatelessWidget {
  const _AddExerciseButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final accent = brandTheme?.outline ?? theme.colorScheme.secondary;

    return PremiumActionTile(
      margin: const EdgeInsets.only(bottom: 12),
      borderRadius: BorderRadius.circular(26),
      accentColor: accent,
      trailingColor: accent,
      onTap: onPressed,
      showArrow: true,
      leading: const Icon(Icons.add_rounded),
      title: 'Übung hinzufügen',
    );
  }
}

class _SaveAllButton extends StatelessWidget {
  const _SaveAllButton({
    required this.isSaving,
    required this.canSave,
    required this.onPressed,
  });

  final bool isSaving;
  final bool canSave;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final accent = brandTheme?.outline ?? theme.colorScheme.secondary;
    final isEnabled = canSave && !isSaving;

    return Opacity(
      opacity: isEnabled || isSaving ? 1.0 : 0.55,
      child: PremiumActionTile(
        margin: const EdgeInsets.only(bottom: 12),
        borderRadius: BorderRadius.circular(26),
        accentColor: accent,
        trailingColor: accent,
        onTap: isEnabled ? onPressed : null,
        showArrow: !isSaving,
        leading: isSaving
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              )
            : const Icon(Icons.check_rounded),
        title: 'Training speichern',
        trailing: isSaving
            ? SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              )
            : null,
      ),
    );
  }
}
