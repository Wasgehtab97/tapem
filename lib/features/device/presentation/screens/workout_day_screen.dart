import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/settings_provider.dart';
import 'package:tapem/app_router.dart';

import 'package:tapem/features/device/presentation/controllers/workout_day_controller.dart';
import 'package:tapem/features/device/presentation/models/workout_device_selection.dart';
import 'package:tapem/features/device/presentation/widgets/device_session_section.dart';
import 'package:tapem/features/device/presentation/widgets/session_rest_timer.dart';
import 'package:tapem/features/gym/presentation/screens/gym_screen.dart';

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
    this.sessionBuilder,
    this.closeSessionOnDispose = false,
  });

  final String gymId;
  final String deviceId;
  final String exerciseId;
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
  final GlobalKey<SessionRestTimerState> _restTimerKey =
      GlobalKey<SessionRestTimerState>();



  void _handleSelection(WorkoutDeviceSelection selection) {
    final auth = context.read<AuthProvider>();
    final controller = context.read<WorkoutDayController>();
    final session = controller.addOrFocusSession(
      gymId: selection.gymId,
      deviceId: selection.deviceId,
      exerciseId: selection.exerciseId,
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureSession());
  }

  Future<void> _ensureSession() async {
    final auth = context.read<AuthProvider>();
    final controller = context.read<WorkoutDayController>();
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
        leadingWidth: 160,
        leading: InkWell(
          onTap: () => Navigator.of(context).popUntil((route) => route.settings.name == '/home' || route.isFirst),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            margin: const EdgeInsets.only(left: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Icon(Icons.add, color: brandColor),
                const SizedBox(width: 4),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Nächste Übung',
                      style: theme.textTheme.labelLarge?.copyWith(
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
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(width: 12),
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
          child: Scrollbar(
            controller: _scrollController,
            child: Consumer<OverlayNumericKeypadController>(
              builder: (context, keypadController, _) {
                final bottomSpacerHeight = keypadController.keypadContentHeight +
                    MediaQuery.of(context).padding.bottom +
                    12;
                return CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    if (sessions.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text(
                            loc.multiDeviceNewExercise,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      )
                    else ...[
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 16),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.only(bottom: 24),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final session = sessions[index];
                              final builder = widget.sessionBuilder;
                              final displayIndex = sessions.length - index;
                              if (builder != null) {
                                return builder(
                                  context,
                                  session,
                                );
                              }
                              return DeviceSessionSection(
                                key: ValueKey(session.key),
                                provider: session.provider,
                                gymId: session.gymId,
                                deviceId: session.deviceId,
                                exerciseId: session.exerciseId,
                                userId: session.userId,
                                displayIndex: displayIndex,
                                sessionKey: session.key,

                                onCloseRequested: () => _handleCloseSession(session),
                              );
                            },
                            childCount: sessions.length,
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: _SaveAllButton(
                          isSaving: controller.isSaving,
                          canSave: controller.canSave,
                          onPressed: () => _handleSaveAllSessions(
                            sessions,
                          ),
                        ),
                      ),
                    ],
                    SliverToBoxAdapter(
                      child: SizedBox(height: bottomSpacerHeight),
                    ),
                  ],
                );
              },
            ),
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



    final activeGymId = auth.gymCode ?? widget.gymId;

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
      if (remaining.isEmpty) {
        if (mounted) {
          // Navigate to home/profile page after saving
          Navigator.of(context).popUntil((route) {
            final name = route.settings.name;
            return name == AppRouter.home || route.isFirst;
          });
        }
      } else {
        setState(() {});
      }
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

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
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
    final brandColor = theme.colorScheme.primary;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: canSave && !isSaving
              ? [
                  BoxShadow(
                    color: brandColor.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton(
            onPressed: !canSave || isSaving ? null : onPressed,
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Speichern',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
