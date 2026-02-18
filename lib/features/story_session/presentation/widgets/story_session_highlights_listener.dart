import 'dart:async';
import 'dart:collection';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/services/workout_session_coordinator.dart';
import 'package:tapem/core/services/workout_session_duration_service.dart';
import 'package:tapem/features/story_session/presentation/widgets/story_session_dialog.dart';
import 'package:tapem/features/story_session/story_session_service.dart';
import 'package:tapem/features/training_details/domain/models/session.dart';
import 'package:tapem/features/training_details/domain/usecases/get_sessions_for_date.dart';
import 'package:tapem/features/training_details/providers/session_repository_provider.dart';
import 'package:tapem/features/story_session/domain/models/story_session_summary.dart';

const _navigationSettleDelay = Duration(milliseconds: 350);
const _summaryBuildTimeout = Duration(seconds: 3);
const _sessionLoadTimeout = Duration(seconds: 2);
const _replayRetryDelay = Duration(seconds: 2);

void _workoutHighlightsLog(String message) {
  debugPrint('🎬 [WorkoutHighlights] $message');
}

void _workoutHighlightsError(String message, Object error, StackTrace stack) {
  debugPrint('❌ [WorkoutHighlights] $message: $error');
  debugPrintStack(label: 'workout_highlights_error', stackTrace: stack);
}

final storyHighlightsGetSessionsForDateProvider = Provider<GetSessionsForDate>((
  ref,
) {
  return GetSessionsForDate(ref.read(sessionRepositoryProvider));
});

class StorySessionHighlightsListener extends ConsumerStatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  const StorySessionHighlightsListener({
    super.key,
    required this.child,
    required this.navigatorKey,
  });

  @override
  ConsumerState<StorySessionHighlightsListener> createState() =>
      _StorySessionHighlightsListenerState();
}

class _StorySessionHighlightsListenerState
    extends ConsumerState<StorySessionHighlightsListener> {
  StreamSubscription<WorkoutSessionCompletionEvent>? _subscription;
  WorkoutSessionDurationService? _durationService;
  final Queue<_PendingSummaryItem> _pendingSummaries = Queue();
  final Set<String> _activeCompletionKeys = <String>{};
  final Set<String> _shownCompletionKeys = <String>{};
  bool _isShowingDialog = false;
  bool _replayingPending = false;
  Timer? _replayRetryTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ensure coordinator is initialized globally so inactivity auto-finalize
    // runs even without opening workout-specific screens.
    ref.read(workoutSessionCoordinatorProvider);
    final service = ref.read(workoutSessionDurationServiceProvider);
    if (!identical(service, _durationService)) {
      _subscription?.cancel();
      _durationService = service;
      _subscription = service.completionStream.listen((event) {
        unawaited(_handleCompletion(event));
      });
      _workoutHighlightsLog('listener_bound_to_duration_service');
      unawaited(_replayPendingCompletions(service));
    }
  }

  Future<void> _replayPendingCompletions(
    WorkoutSessionDurationService service,
  ) async {
    if (_replayingPending || !mounted) return;
    _replayingPending = true;
    try {
      final auth = ref.read(authViewStateProvider);
      final userId = auth.userId;
      if (userId == null || userId.isEmpty) return;
      final pending = await service.getPendingCompletions(userId: userId);
      _workoutHighlightsLog(
        'replay_pending count=${pending.length} user=$userId',
      );
      for (final event in pending) {
        if (!mounted) break;
        await _handleCompletion(event);
      }
    } catch (error, stackTrace) {
      _workoutHighlightsError('replay_pending_failed', error, stackTrace);
      _scheduleReplayRetry(reason: 'replay_pending_failed');
    } finally {
      _replayingPending = false;
    }
  }

  Future<void> _handleCompletion(WorkoutSessionCompletionEvent event) async {
    if (!mounted) return;
    final auth = ref.read(authViewStateProvider);
    if (event.userId.isEmpty || auth.userId != event.userId) {
      return;
    }
    final completionKey = _completionKey(event);
    _workoutHighlightsLog(
      'completion_received key=$completionKey day=${event.dayKey} durationMs=${event.durationMs}',
    );
    if (_shownCompletionKeys.contains(completionKey) ||
        _activeCompletionKeys.contains(completionKey)) {
      _workoutHighlightsLog('completion_skipped_duplicate key=$completionKey');
      return;
    }
    _activeCompletionKeys.add(completionKey);
    var keepActiveKey = false;
    try {
      final isOffline = await _isOffline();
      if (isOffline) {
        _workoutHighlightsLog(
          'summary_deferred_offline key=$completionKey day=${event.dayKey}',
        );
        _showDeferredOfflineHint();
        _scheduleReplayRetry(reason: 'offline');
        return;
      }

      final storyService = ref.read(storySessionServiceProvider);

      List<Session> sessions = const [];
      try {
        sessions = await ref
            .read(storyHighlightsGetSessionsForDateProvider)
            .execute(userId: event.userId, date: event.start)
            .timeout(_sessionLoadTimeout, onTimeout: () => const <Session>[]);
      } catch (error, stackTrace) {
        _workoutHighlightsError('load_sessions_failed', error, stackTrace);
      }

      if (!mounted) return;

      StorySessionSummary? summary;
      try {
        summary = await storyService
            .getSummary(
              gymId: event.gymId,
              userId: event.userId,
              date: event.start,
              sessions: sessions,
              fallbackDurationMs: event.durationMs,
            )
            .timeout(_summaryBuildTimeout);
      } on TimeoutException catch (error, stackTrace) {
        _workoutHighlightsError('build_summary_timeout', error, stackTrace);
        _showDeferredHighlightsHint(
          'Training lokal gespeichert. Highlights werden später angezeigt.',
        );
        _scheduleReplayRetry(reason: 'summary_timeout');
        return;
      } catch (error, stackTrace) {
        _workoutHighlightsError('build_summary_failed', error, stackTrace);
        _showDeferredHighlightsHint(
          'Training lokal gespeichert. Highlights konnten gerade nicht geladen werden.',
        );
        _scheduleReplayRetry(reason: 'summary_failed');
        return;
      }

      if (!mounted || summary == null) {
        if (mounted && summary == null) {
          _scheduleReplayRetry(reason: 'summary_null');
        }
        return;
      }

      keepActiveKey = true;
      _workoutHighlightsLog('summary_ready key=$completionKey');
      _enqueueSummary(
        _PendingSummaryItem(
          summary: summary,
          completionEvent: event,
          completionKey: completionKey,
        ),
      );
    } finally {
      if (!keepActiveKey) {
        _activeCompletionKeys.remove(completionKey);
      }
    }
  }

  void _enqueueSummary(_PendingSummaryItem item) {
    if (_isShowingDialog) {
      _pendingSummaries.add(item);
      _workoutHighlightsLog(
        'summary_enqueued key=${item.completionKey} queue=${_pendingSummaries.length}',
      );
      return;
    }
    _isShowingDialog = true;
    _workoutHighlightsLog('summary_show_start key=${item.completionKey}');
    unawaited(_showSummary(item));
  }

  Future<void> _showSummary(_PendingSummaryItem item) async {
    final navigator = widget.navigatorKey.currentState;
    if (navigator == null || !navigator.mounted) {
      _activeCompletionKeys.remove(item.completionKey);
      _isShowingDialog = false;
      _releasePendingForRetry();
      _scheduleReplayRetry(reason: 'navigator_unavailable');
      return;
    }

    var shownSuccessfully = false;
    try {
      // Kurze Verzögerung, damit Navigation nach dem Speichern
      // (z.B. zur Profilseite) zuerst sauber abgeschlossen wird.
      // Dadurch erscheinen die Session Highlights stabil auf der
      // Zielseite und nicht kurz auf der vorherigen Workout-Page.
      await Future<void>.delayed(_navigationSettleDelay);
      if (!navigator.mounted) {
        _activeCompletionKeys.remove(item.completionKey);
        _isShowingDialog = false;
        _releasePendingForRetry();
        _scheduleReplayRetry(reason: 'navigator_unmounted');
        return;
      }

      await showDialog<void>(
        context: navigator.context,
        barrierDismissible: true,
        builder: (_) => StorySessionDialog(summary: item.summary),
      );
      shownSuccessfully = true;
      _workoutHighlightsLog('summary_dialog_closed key=${item.completionKey}');
    } catch (error, stackTrace) {
      _workoutHighlightsError('show_dialog_failed', error, stackTrace);
    } finally {
      if (shownSuccessfully) {
        try {
          final existingService = _durationService;
          if (existingService != null) {
            await existingService.acknowledgeCompletion(item.completionEvent);
          } else {
            final fallbackService = ref.read(
              workoutSessionDurationServiceProvider,
            );
            await fallbackService.acknowledgeCompletion(item.completionEvent);
          }
          _shownCompletionKeys.add(item.completionKey);
          _workoutHighlightsLog(
            'completion_acknowledged key=${item.completionKey}',
          );
        } catch (error, stackTrace) {
          _workoutHighlightsError(
            'acknowledge_completion_failed',
            error,
            stackTrace,
          );
        }
      }
      _activeCompletionKeys.remove(item.completionKey);
      if (!mounted) {
        _isShowingDialog = false;
        _releasePendingForRetry();
      } else if (_pendingSummaries.isNotEmpty) {
        final next = _pendingSummaries.removeFirst();
        unawaited(_showSummary(next));
      } else {
        _isShowingDialog = false;
        if (!shownSuccessfully) {
          _scheduleReplayRetry(reason: 'dialog_not_shown');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthViewState>(authViewStateProvider, (previous, next) {
      final previousUserId = previous?.userId;
      final nextUserId = next.userId;
      if (nextUserId == null ||
          nextUserId.isEmpty ||
          nextUserId == previousUserId) {
        return;
      }
      final existingService = _durationService;
      if (existingService != null) {
        unawaited(_replayPendingCompletions(existingService));
        return;
      }
      final service = ref.read(workoutSessionDurationServiceProvider);
      unawaited(_replayPendingCompletions(service));
    });
    return widget.child;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _replayRetryTimer?.cancel();
    _pendingSummaries.clear();
    _activeCompletionKeys.clear();
    _shownCompletionKeys.clear();
    super.dispose();
  }

  void _releasePendingForRetry() {
    for (final item in _pendingSummaries) {
      _activeCompletionKeys.remove(item.completionKey);
    }
    _pendingSummaries.clear();
  }

  String _completionKey(WorkoutSessionCompletionEvent event) {
    final startMs = event.start.millisecondsSinceEpoch;
    final endMs = event.end.millisecondsSinceEpoch;
    final session = event.sessionId ?? '-';
    return '${event.userId}|${event.gymId}|${event.dayKey}|$startMs|$endMs|$session';
  }

  Future<bool> _isOffline() async {
    if (!kReleaseMode) {
      return false;
    }
    try {
      final results = await Connectivity().checkConnectivity();
      return results.isNotEmpty &&
          results.every((result) => result == ConnectivityResult.none);
    } catch (_) {
      return false;
    }
  }

  void _showDeferredOfflineHint() {
    _showDeferredHighlightsHint(
      'Training lokal gespeichert. Highlights werden angezeigt, sobald Internet verfügbar ist.',
    );
  }

  void _showDeferredHighlightsHint(String message) {
    _workoutHighlightsLog('ui_hint_suppressed message="$message"');
  }

  void _scheduleReplayRetry({
    required String reason,
    Duration delay = _replayRetryDelay,
  }) {
    if (!mounted) return;
    if (_replayRetryTimer?.isActive ?? false) {
      return;
    }
    _workoutHighlightsLog(
      'replay_retry_scheduled reason=$reason delayMs=${delay.inMilliseconds}',
    );
    _replayRetryTimer = Timer(delay, () {
      _replayRetryTimer = null;
      if (!mounted) return;
      final service = _durationService;
      if (service != null) {
        unawaited(_replayPendingCompletions(service));
        return;
      }
      final fallbackService = ref.read(workoutSessionDurationServiceProvider);
      unawaited(_replayPendingCompletions(fallbackService));
    });
  }
}

class _PendingSummaryItem {
  const _PendingSummaryItem({
    required this.summary,
    required this.completionEvent,
    required this.completionKey,
  });

  final StorySessionSummary summary;
  final WorkoutSessionCompletionEvent completionEvent;
  final String completionKey;
}
