import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/providers/settings_provider.dart';
import 'package:tapem/app_router.dart';

import 'package:tapem/features/device/presentation/controllers/workout_day_controller.dart';
import 'package:tapem/features/device/presentation/models/workout_device_selection.dart';
import 'package:tapem/features/device/presentation/widgets/device_session_section.dart';
import 'package:tapem/features/device/presentation/widgets/session_rest_timer.dart';
import 'package:tapem/features/gym/presentation/screens/gym_screen.dart';
import 'package:tapem/features/training_plan/data/sources/firestore_training_plan_source.dart';
import 'package:tapem/features/training_plan/application/training_plan_provider.dart';
import 'package:tapem/features/training_details/data/session_meta_source.dart';
import 'package:tapem/core/time/logic_day.dart';

import 'package:tapem/features/nfc/widgets/nfc_scan_button.dart';
import 'package:tapem/ui/numeric_keypad/overlay_numeric_keypad.dart';
import 'package:tapem/ui/timer/active_workout_timer.dart';
import 'package:tapem/l10n/app_localizations.dart';

class WorkoutDayScreen extends StatefulWidget {
  const WorkoutDayScreen({
    super.key,
    required this.gymId,
    required this.deviceId,
    required this.exerciseId,
    this.planId,
    this.planName,
    this.sessionBuilder,
    this.closeSessionOnDispose = false,
  });

  final String gymId;
  final String deviceId;
  final String exerciseId;
  final String? planId;
  final String? planName;
  final Widget Function(
    BuildContext context,
    WorkoutDaySession session,
  )?
      sessionBuilder;
  final bool closeSessionOnDispose;

  @override
  State<WorkoutDayScreen> createState() => _WorkoutDayScreenState();
}

class _WorkoutDayScreenState extends State<WorkoutDayScreen> {
  final ScrollController _scrollController = ScrollController();
  String? _sessionKey;
  bool _isInitializing = true;
  bool _ownsSession = false;
  String? _planId;
  String? _planName;
  final GlobalKey<SessionRestTimerState> _restTimerKey =
      GlobalKey<SessionRestTimerState>();



  void _handleSelection(WorkoutDeviceSelection selection) {
    final auth = context.read<AuthProvider>();
    final controller = context.read<WorkoutDayController>();
    final session = controller.addOrFocusSession(
      gymId: selection.gymId,
      deviceId: selection.deviceId,
      exerciseId: selection.exerciseId,
      exerciseName: selection.exerciseName,
      userId: auth.userId!,
    );
    if (!mounted) return;
    
    // Close keyboard before scrolling
    FocusManager.instance.primaryFocus?.unfocus();
    final keypad = context.read<OverlayNumericKeypadController>();
    keypad.close();
    
    setState(() {});
    _scrollToLatest();
    _sessionKey ??= session.key;
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

  @override
  void initState() {
    super.initState();
    _planId = widget.planId;
    _planName = widget.planName;
    debugPrint(
        '🏋️ WorkoutDayScreen init gymId=${widget.gymId} deviceId=${widget.deviceId} exerciseId=${widget.exerciseId} planId=$_planId planName=$_planName');
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureSession());
  }

  Future<void> _ensureSession() async {
    final auth = context.read<AuthProvider>();
    final controller = context.read<WorkoutDayController>();
    // Plan-Kontext ggf. im Controller hinterlegen oder von dort übernehmen
    final existingPlan = controller.getPlanContext(
      gymId: widget.gymId,
    );
    if (_planId != null) {
      controller.setPlanContext(
        gymId: widget.gymId,
        planId: _planId!,
        planName: _planName,
      );
    } else if (existingPlan != null) {
      _planId ??= existingPlan.$1;
      _planName ??= existingPlan.$2;
      debugPrint(
          '📎 WorkoutDayScreen adopted existing plan context planId=$_planId planName=$_planName');
    }
    final contextKey = WorkoutDayController.contextKey(
      gymId: widget.gymId,
      deviceId: widget.deviceId,
      exerciseId: widget.exerciseId,
      userId: auth.userId!,
    );
    final alreadyExists = controller.sessionForKey(contextKey) != null;
    final session = controller.addOrFocusSession(
      gymId: widget.gymId,
      deviceId: widget.deviceId,
      exerciseId: widget.exerciseId,
      userId: auth.userId!,
    );
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

  @override
  void dispose() {
    _scrollController.dispose();
    final key = _sessionKey;
    if (widget.closeSessionOnDispose && key != null && _ownsSession) {
      final controller = context.read<WorkoutDayController>();
      if (controller.sessionForKey(key) != null) {
        controller.closeSession(key);
      }
    }
    super.dispose();
  }

  void _handleCloseSession(WorkoutDaySession session) {
    final controller = context.read<WorkoutDayController>();
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
    final auth = context.read<AuthProvider>();
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

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<WorkoutDayController>();
    final auth = context.watch<AuthProvider>();
    final activeGymId = auth.gymCode ?? widget.gymId;
    final userId = auth.userId;
    final sessions = (userId == null)
        ? const <WorkoutDaySession>[]
        : controller.sessionsFor(userId: userId, gymId: activeGymId);


    final loc = AppLocalizations.of(context)!;

    if (_isInitializing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final restSeconds = _resolveRestSeconds(sessions);
    final theme = Theme.of(context);
    final brandColor = theme.colorScheme.primary;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 110, // etwas kompakter für "< Übungen"
        leading: InkWell(
          onTap: () {
            // Robustly close keyboard and clear focus
            final dayController = context.read<WorkoutDayController>();
            dayController.focusedProvider?.clearFocus();
            
            final keypadController = context.read<OverlayNumericKeypadController>();
            if (keypadController.isOpen) {
              keypadController.close();
            }
            
            FocusManager.instance.primaryFocus?.unfocus();

            // Immer zurück zur Gym-Page der Home-Tabs (Index 0).
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRouter.home,
              (route) => false,
              arguments: 0,
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            margin: const EdgeInsets.only(left: 8),
            padding: const EdgeInsets.symmetric(horizontal: 4), // Reduced padding
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
                      style: theme.textTheme.labelMedium?.copyWith( // Smaller text style
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
          child: Row(
            mainAxisSize: MainAxisSize.min, // Keep min to allow centering if space permits
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: ActiveWorkoutTimer(
                  key: ValueKey('workoutDayTimer-${_sessionKey ?? 'global'}'),
                  compact: true,
                  padding: EdgeInsets.zero,
                  sessionKey: _sessionKey,
                ),
              ),
              const SizedBox(width: 8), // Reduced gap
              Flexible(
                child: SessionRestTimer(
                  key: _restTimerKey,
                  initialSeconds: restSeconds,
                  onInteraction: _handleTimerInteraction,
                ),
              ),
            ],
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
                _handleSelection(selection);
              },
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.scaffoldBackgroundColor,
              Color.alphaBlend(
                brandColor.withOpacity(0.05),
                theme.scaffoldBackgroundColor,
              ),
            ],
          ),
        ),
        child: SafeArea(
          child: Consumer<OverlayNumericKeypadController>(
            builder: (context, keypadController, _) {
              final bottomSpacerHeight = keypadController.keypadContentHeight +
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
                  padding: const EdgeInsets.only(
                    top: 16,
                    bottom: 24,
                  ),
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
                            .animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOut,
                        )),
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
                        child: _SaveAllButton(
                          isSaving: controller.isSaving,
                          canSave: controller.canSave,
                          onPressed: () =>
                              _handleSaveAllSessions(sessions),
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
                        padding: const EdgeInsets.only(bottom: 24),
                        child: builder(
                          context,
                          session,
                        ),
                      );
                    } else {
                      child = Padding(
                        padding: const EdgeInsets.only(bottom: 24),
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
      ),
    );
  }

  int? _resolveRestSeconds(
    List<WorkoutDaySession> sessions,
  ) {
    if (sessions.isEmpty) {
      return null;
    }
    final key = _sessionKey;
    if (key != null) {
      final index = sessions.indexWhere((session) => session.key == key);
      if (index != -1) {
      }
    }
    return null;
  }

  void _handleTimerInteraction() {
    FocusManager.instance.primaryFocus?.unfocus();
    final keypad = context.read<OverlayNumericKeypadController>();
    keypad.close();
  }

  Future<void> _handleSaveAllSessions(
    List<WorkoutDaySession> sessions,
  ) async {
    final loc = AppLocalizations.of(context)!;
    final controller = context.read<WorkoutDayController>();
    final auth = context.read<AuthProvider>();
    final settings = context.read<SettingsProvider>();

    // Tastaturen sofort schließen, bevor Dialoge/Speichern starten.
    FocusManager.instance.primaryFocus?.unfocus();
    context.read<OverlayNumericKeypadController>().close();

    final confirmFinish = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Trainingstag abschließen?'),
        content: const Text(
            'Möchtest du alle offenen Sessions speichern und den Trainingstag beenden?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(loc.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(loc.saveButton),
          ),
        ],
      ),
    );

    if (!mounted || confirmFinish != true) {
      return;
    }

    final sessionsByKey = {
      for (final session in sessions) session.key: session,
    };
    final sessionsWithPendingSets = <WorkoutDaySession>[
      for (final session in sessions)
        if (session.provider.getSetCounts().filledNotDone > 0) session,
    ];

    if (sessionsWithPendingSets.isNotEmpty) {
      final confirmCompleteAll = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(loc.notAllSetsConfirmed),
          content: const Text(
            'Es wurden noch nicht alle Sätze abgehakt. Möchtest du alle offenen Sätze abhaken und fortfahren?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(loc.cancelButton),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(loc.confirmAllSets),
            ),
          ],
        ),
      );

      if (!mounted || confirmCompleteAll != true) {
        return;
      }

      for (final session in sessionsWithPendingSets) {
        session.provider.completeAllFilledNotDone();
      }
    }

    await settings.load(auth.userId!);

    // Use the gymId from the current sessions if possible to ensure that
    // session meta and XP are always written under the same gym that the
    // TrainingDetails screen will later query.
    final sessionGymId =
        sessions.isNotEmpty ? sessions.first.gymId : null;
    final activeGymId = sessionGymId ?? auth.gymCode ?? widget.gymId;

    debugPrint(
      '[WorkoutDay] navigate home index=1 role=${auth.role} gym=$activeGymId',
    );

    final result = await controller.saveAllSessions(
      userId: auth.userId!,
      gymId: activeGymId,
      showInLeaderboard: auth.showInLeaderboard ?? true,
      userName: auth.userName,
      gender: settings.gender,
      bodyWeightKg: settings.bodyWeightKg,

    );

    if (!mounted) return;

    if (result.saved > 0) {
      if (_planId != null) {
        debugPrint(
            '📊 Updating training plan stats for planId=$_planId gym=$activeGymId (saved=${result.saved}/${result.attempted})');
        try {
          await FirestoreTrainingPlanSource().incrementCompletion(
            userId: auth.userId!,
            planId: _planId!,
          );
          if (!mounted) return;
          riverpod.ProviderScope.containerOf(context, listen: false)
              .refresh(trainingPlanStatsProvider(_planId!));
          final dayKey = logicDayKey(DateTime.now());
          await SessionMetaSource().upsertMeta(
            gymId: activeGymId,
            uid: auth.userId!,
            sessionId: dayKey,
            meta: {
              'dayKey': dayKey,
              'planId': _planId,
              if (_planName != null) 'planName': _planName,
            },
          );
        } catch (e, st) {
          debugPrint('❌ Failed to update training plan meta for planId=$_planId gym=$activeGymId: $e');
          debugPrint('$st');
        }
      }

      for (final key in result.savedSessionKeys) {
        final session = sessionsByKey[key];
        if (session == null) continue;
        final closed = controller.closeSession(key);
        if (closed && key == _sessionKey) {
          _sessionKey = null;
          _ownsSession = false;
        }
      }
      final remaining = controller.sessionsFor(
        userId: auth.userId!,
        gymId: activeGymId,
      );

      // Wenn alle Sessions gespeichert wurden, gilt der Plan für diesen Tag als abgeschlossen.
      if (_planId != null) {
        controller.clearPlanContextForDay(gymId: activeGymId);
      }

      debugPrint(
        '[WorkoutDay] saveAllSessions result.saved=${result.saved} remainingSessions=${remaining.length} → navigate to Home(Profile)',
      );

      if (!mounted) return;

      // Nach dem Speichern immer zur Profil-Page (Home-Tab Index 1) navigieren,
      // unabhängig davon, ob noch andere Sessions im Hintergrund existieren.
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRouter.home,
        (route) => false,
        arguments: 1,
      );
    }

      final message = () {
        if (result.attempted == 0) {
          return loc.noCompletedSets;
        }
        if (result.saved == 0) {
          final firstError = result.failedSessions.values.firstWhere(
            (error) => error != null && error.isNotEmpty,
            orElse: () => null,
          );
          return firstError ?? '${loc.errorPrefix}: ${result.failedSessions.length}';
        }
        final savedText = result.saved == result.attempted
            ? loc.sessionSaved
            : '${loc.sessionSaved} (${result.saved}/${result.attempted})';
        if (!result.hasFailures) {
          return savedText;
        }
        final firstError = result.failedSessions.values.firstWhere(
          (error) => error != null && error.isNotEmpty,
          orElse: () => null,
        );
        final failureText =
            firstError ?? '${loc.errorPrefix}: ${result.failedSessions.length}';
        return '$savedText\n$failureText';
      }();

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
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
    final brandColor = brandTheme?.outline ?? theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      child: Container(
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: canSave && !isSaving
              ? LinearGradient(
                  colors: [
                    brandColor,
                    brandColor.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: canSave ? null : Colors.white.withOpacity(0.05),
          boxShadow: canSave && !isSaving
              ? [
                  BoxShadow(
                    color: brandColor.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: !canSave || isSaving ? null : onPressed,
            borderRadius: BorderRadius.circular(28),
             child: Center(
              child: isSaving
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Training speichern', // More engaging text
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: canSave 
                          ? Colors.white 
                          : Colors.white.withOpacity(0.3),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
