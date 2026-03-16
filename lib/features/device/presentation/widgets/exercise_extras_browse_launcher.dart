import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/providers/database_provider.dart';
import 'package:tapem/core/providers/device_provider.dart';
import 'package:tapem/core/providers/firebase_provider.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/features/device/presentation/widgets/machine_leaderboard_sheet.dart';
import 'package:tapem/features/device/presentation/widgets/workout_exercise_extras_sheet.dart';
import 'package:tapem/features/feedback/presentation/widgets/feedback_button.dart'
    show showFeedbackDialog;
import 'package:tapem/features/training_details/providers/session_repository_provider.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/services/membership_service.dart';

Future<void> showExerciseExtrasBrowseSheet({
  required BuildContext context,
  required String gymId,
  required String deviceId,
  required String exerciseId,
  String? exerciseName,
}) async {
  if (!context.mounted) return;
  final hostContext = context;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.7),
    builder: (_) => _ExerciseExtrasBrowseSheetContent(
      hostContext: hostContext,
      gymId: gymId,
      deviceId: deviceId,
      exerciseId: exerciseId,
      exerciseName: exerciseName,
    ),
  );
}

class _ExerciseExtrasBrowseSheetContent extends ConsumerStatefulWidget {
  const _ExerciseExtrasBrowseSheetContent({
    required this.hostContext,
    required this.gymId,
    required this.deviceId,
    required this.exerciseId,
    this.exerciseName,
  });

  final BuildContext hostContext;
  final String gymId;
  final String deviceId;
  final String exerciseId;
  final String? exerciseName;

  @override
  ConsumerState<_ExerciseExtrasBrowseSheetContent> createState() =>
      _ExerciseExtrasBrowseSheetContentState();
}

class _ExerciseExtrasBrowseSheetContentState
    extends ConsumerState<_ExerciseExtrasBrowseSheetContent> {
  DeviceProvider? _previewProvider;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  @override
  void dispose() {
    _previewProvider?.dispose();
    super.dispose();
  }

  Future<void> _loadPreview() async {
    final auth = ref.read(authControllerProvider);
    final userId = auth.userId;
    if (userId == null || userId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Nutzerkontext fehlt.';
      });
      return;
    }

    final provider = DeviceProvider(
      firestore: ref.read(firebaseFirestoreProvider),
      sessionRepository: ref.read(sessionRepositoryProvider),
      membership: ref.read(membershipServiceProvider),
      syncService: ref.read(syncServiceProvider),
      autoFinalizeEnabled: false,
      persistEmptyDrafts: false,
    );

    try {
      await provider.loadDevice(
        gymId: widget.gymId,
        deviceId: widget.deviceId,
        exerciseId: widget.exerciseId,
        userId: userId,
      );
      if (!mounted) {
        provider.dispose();
        return;
      }
      setState(() {
        _previewProvider = provider;
        _isLoading = false;
        _error = null;
      });
    } catch (error) {
      provider.dispose();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = error.toString();
      });
    }
  }

  void _closeAndRun(VoidCallback action) {
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final hostContext = widget.hostContext;
      if (!hostContext.mounted) return;
      action();
    });
  }

  void _openLeaderboard({
    required String machineId,
    required bool isMulti,
    required String title,
  }) {
    showModalBottomSheet<void>(
      context: widget.hostContext,
      isScrollControlled: true,
      builder: (_) => MachineLeaderboardSheet(
        gymId: widget.gymId,
        machineId: machineId,
        isMulti: isMulti,
        title: title,
      ),
    );
  }

  void _openHistory({
    required String deviceName,
    required String? deviceDescription,
    required bool isMulti,
  }) {
    Navigator.of(widget.hostContext).pushNamed(
      AppRouter.history,
      arguments: {
        'deviceId': widget.deviceId,
        'deviceName': deviceName,
        'deviceDescription': deviceDescription,
        'isMulti': isMulti,
        if (isMulti) 'exerciseId': widget.exerciseId,
        if (isMulti && (widget.exerciseName?.isNotEmpty ?? false))
          'exerciseName': widget.exerciseName,
      },
    );
  }

  void _openFeedback() {
    unawaited(
      showFeedbackDialog(
        widget.hostContext,
        ref,
        gymId: widget.gymId,
        deviceId: widget.deviceId,
      ),
    );
  }

  void _openNote(DeviceProvider provider) {
    final loc = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final textController = TextEditingController(text: provider.note);
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                loc.noteModalTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: textController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: loc.noteModalHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete),
                    tooltip: loc.noteDeleteTooltip,
                    onPressed: () {
                      provider.setNote('');
                      Navigator.of(ctx).pop();
                    },
                  ),
                  ElevatedButton(
                    onPressed: () {
                      provider.setNote(textController.text.trim());
                      Navigator.of(ctx).pop();
                    },
                    child: Text(loc.noteSaveButton),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingOrErrorShell({required Widget child}) {
    final isNarrow = MediaQuery.sizeOf(context).width <= 390;
    return SafeArea(
      top: false,
      child: Container(
        margin: EdgeInsets.fromLTRB(10, 0, 10, isNarrow ? 10 : 12),
        padding: EdgeInsets.fromLTRB(
          isNarrow ? 13 : 16,
          12,
          isNarrow ? 13 : 16,
          18,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0D15),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingOrErrorShell(
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_error != null) {
      return _buildLoadingOrErrorShell(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Schließen'),
              ),
            ],
          ),
        ),
      );
    }

    final provider = _previewProvider;
    if (provider == null || provider.device == null) {
      return _buildLoadingOrErrorShell(
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Text(
            'Übungsdaten konnten nicht geladen werden.',
            style: TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final brandColor =
        theme.extension<AppBrandTheme>()?.outline ??
        theme.colorScheme.secondary;
    final device = provider.device!;
    final title = (widget.exerciseName?.isNotEmpty ?? false)
        ? widget.exerciseName!
        : device.name;

    return WorkoutExerciseExtrasSheet(
      brandColor: brandColor,
      isBodyweightMode: provider.isBodyweightMode,
      level: provider.level,
      xp: provider.xp,
      hasNote: provider.note.trim().isNotEmpty,
      isBodyweightToggleEnabled: false,
      onOpenLeaderboard: () => _closeAndRun(
        () => _openLeaderboard(
          machineId: device.uid,
          isMulti: device.isMulti,
          title: title,
        ),
      ),
      onOpenHistory: () => _closeAndRun(
        () => _openHistory(
          deviceName: device.name,
          deviceDescription: device.description,
          isMulti: device.isMulti,
        ),
      ),
      onToggleBodyweight: null,
      onFeedback: () => _closeAndRun(_openFeedback),
      onOpenNote: () => _openNote(provider),
    );
  }
}
