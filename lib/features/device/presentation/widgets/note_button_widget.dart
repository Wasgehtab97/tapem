// lib/features/device/presentation/widgets/note_button_widget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/core/providers/device_provider.dart';

class NoteButtonWidget extends StatelessWidget {
  final String deviceId;
  final Object? sessionIdentifier;

  const NoteButtonWidget({
    Key? key,
    required this.deviceId,
    this.sessionIdentifier,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final prov = context.watch<DeviceProvider>();
    final hasNote = prov.note.isNotEmpty;

    final scheme = Theme.of(context).colorScheme;

    return FloatingActionButton.small(
      heroTag: _resolveHeroTag(),
      tooltip: hasNote ? loc.noteEditTooltip : loc.noteAddTooltip,
      backgroundColor: scheme.surfaceVariant.withOpacity(0.92),
      foregroundColor: scheme.onSurfaceVariant,
      shape: const CircleBorder(),
      child: Icon(
        hasNote ? Icons.info : Icons.info_outline,
        size: 18,
      ),
      onPressed: () => _openNoteModal(context, prov),
    );
  }

  String _resolveHeroTag() {
    final identifier = sessionIdentifier;

    if (identifier is String && identifier.isNotEmpty) {
      return 'noteBtn_${deviceId}_$identifier';
    }

    if (identifier case (String sessionDeviceId, String? exerciseId)) {
      final exercisePart = (exerciseId?.isNotEmpty ?? false) ? exerciseId! : 'default';
      return 'noteBtn_${sessionDeviceId}_$exercisePart';
    }

    if (identifier != null) {
      return 'noteBtn_${deviceId}_${identifier.hashCode}';
    }

    return 'noteBtn_$deviceId';
  }

  void _openNoteModal(BuildContext context, DeviceProvider prov) {
    final loc = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final textController = TextEditingController(text: prov.note);
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete),
                    tooltip: loc.noteDeleteTooltip,
                    onPressed: () {
                      prov.setNote('');
                      Navigator.of(ctx).pop();
                    },
                  ),
                  ElevatedButton(
                    onPressed: () {
                      prov.setNote(textController.text.trim());
                      Navigator.of(ctx).pop();
                    },
                    child: Text(loc.noteSaveButton),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
