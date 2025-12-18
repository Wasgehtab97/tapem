import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/core/providers/database_provider.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/services/workout_session_duration_service.dart';
import 'package:tapem/features/story_session/presentation/widgets/story_session_dialog.dart';
import 'package:tapem/features/story_session/story_session_service.dart';
import 'package:tapem/features/training_details/data/repositories/session_repository_impl.dart';
import 'package:tapem/features/training_details/data/session_meta_source.dart';
import 'package:tapem/features/training_details/data/sources/firestore_session_source.dart';
import 'package:tapem/features/training_details/domain/models/session.dart';
import 'package:tapem/features/training_details/domain/usecases/get_sessions_for_date.dart';
import 'package:tapem/features/story_session/domain/models/story_session_summary.dart';

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
  late final GetSessionsForDate _getSessionsForDate;
  StreamSubscription<WorkoutSessionCompletionEvent>? _subscription;
  WorkoutSessionDurationService? _durationService;
  final Queue<StorySessionSummary> _pendingSummaries = Queue();
  bool _isShowingDialog = false;

  @override
  void initState() {
    super.initState();
    final databaseService = ref.read(databaseServiceProvider);
    final syncService = ref.read(syncServiceProvider);
    final repository = SessionRepositoryImpl(
      databaseService,
      syncService,
      SessionMetaSource(),
    );
    _getSessionsForDate = GetSessionsForDate(repository);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final service = ref.read(workoutSessionDurationServiceProvider);
    if (!identical(service, _durationService)) {
      _subscription?.cancel();
      _durationService = service;
      _subscription = service.completionStream.listen((event) {
        unawaited(_handleCompletion(event));
      });
    }
  }

  Future<void> _handleCompletion(WorkoutSessionCompletionEvent event) async {
    if (!mounted) return;
    final auth = ref.read(authViewStateProvider);
    if (event.userId.isEmpty || auth.userId != event.userId) {
      return;
    }

    final storyService = ref.read(storySessionServiceProvider);

    List<Session> sessions = const [];
    try {
      sessions = await _getSessionsForDate.execute(
        userId: event.userId,
        date: event.start,
      );
    } catch (error, stackTrace) {
      debugPrint(
          'StorySessionHighlightsListener: failed to load sessions: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    if (!mounted) return;

    StorySessionSummary? summary;
    try {
      summary = await storyService.getSummary(
        gymId: event.gymId,
        userId: event.userId,
        date: event.start,
        sessions: sessions,
      );
    } catch (error, stackTrace) {
      debugPrint(
          'StorySessionHighlightsListener: failed to build summary: $error');
      debugPrintStack(stackTrace: stackTrace);
      return;
    }

    if (!mounted || summary == null) {
      return;
    }

    // Wenn der globale Workout-Timer eine Dauer gemessen hat, verwenden wir
    // diese als Obergrenze für die angezeigte Dauer in den Session Highlights.
    // So spiegelt die „Dauer“ möglichst genau das erlebte Training wider,
    // selbst wenn einzelne Sessions noch keine start/end-Timestamps besitzen.
    if (event.durationMs > 0) {
      final currentStats = summary.stats;
      final resolvedDurationMs =
          currentStats.durationMs > 0 && currentStats.durationMs > event.durationMs
              ? currentStats.durationMs
              : event.durationMs;
      if (resolvedDurationMs != currentStats.durationMs) {
        summary = summary.copyWith(
          stats: currentStats.copyWith(durationMs: resolvedDurationMs),
        );
      }
    }

    _enqueueSummary(summary);
  }

  void _enqueueSummary(StorySessionSummary summary) {
    if (_isShowingDialog) {
      _pendingSummaries.add(summary);
      return;
    }
    _isShowingDialog = true;
    unawaited(_showSummary(summary));
  }

  Future<void> _showSummary(StorySessionSummary summary) async {
    final navigator = widget.navigatorKey.currentState;
    if (navigator == null || !navigator.mounted) {
      _isShowingDialog = false;
      _pendingSummaries.clear();
      return;
    }

    try {
      // Kurze Verzögerung, damit Navigation nach dem Speichern
      // (z.B. zur Profilseite) zuerst sauber abgeschlossen wird.
      // Dadurch erscheinen die Session Highlights stabil auf der
      // Zielseite und nicht kurz auf der vorherigen Workout-Page.
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (!navigator.mounted) {
        _isShowingDialog = false;
        _pendingSummaries.clear();
        return;
      }

      await showDialog<void>(
        context: navigator.context,
        builder: (_) => StorySessionDialog(summary: summary),
      );
    } catch (error, stackTrace) {
      debugPrint(
          'StorySessionHighlightsListener: failed to show dialog: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      if (!mounted) {
        _isShowingDialog = false;
        _pendingSummaries.clear();
      } else if (_pendingSummaries.isNotEmpty) {
        final next = _pendingSummaries.removeFirst();
        unawaited(_showSummary(next));
      } else {
        _isShowingDialog = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _pendingSummaries.clear();
    super.dispose();
  }
}
