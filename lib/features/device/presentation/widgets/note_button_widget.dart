// lib/features/device/presentation/widgets/note_button_widget.dart

import 'package:flutter/material.dart';
import 'package:tapem/core/providers/device_provider.dart';
import 'package:tapem/features/device/presentation/widgets/session_action_button_style.dart';
import 'package:tapem/l10n/app_localizations.dart';

class NoteButtonWidget extends StatelessWidget {
  final String deviceId;
  final DeviceProvider provider;
  const NoteButtonWidget({
    Key? key,
    required this.deviceId,
    required this.provider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final prov = provider;
    final hasNote = prov.note.isNotEmpty;

    return IconButton(
      tooltip: hasNote ? loc.noteEditTooltip : loc.noteAddTooltip,
      icon: Icon(hasNote ? Icons.info : Icons.info_outline),
      onPressed: () => _openNoteModal(context, prov),
      style: sessionActionButtonStyle(
        context,
        isActive: hasNote,
      ),
    );
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
