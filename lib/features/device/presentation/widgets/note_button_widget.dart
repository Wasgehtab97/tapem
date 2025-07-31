// lib/features/device/presentation/widgets/note_button_widget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/core/providers/device_provider.dart';

class NoteButtonWidget extends StatelessWidget {
  final String deviceId;

  const NoteButtonWidget({
    Key? key,
    required this.deviceId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc  = AppLocalizations.of(context)!;
    final prov = context.watch<DeviceProvider>();
    final hasNote = prov.note.isNotEmpty;

    return FloatingActionButton(
      heroTag: 'noteBtn_$deviceId',
      mini: true,  // verkleinert den Button
      tooltip: hasNote ? loc.noteEditTooltip : loc.noteAddTooltip,
      child: Icon(
        hasNote ? Icons.info : Icons.info_outline,
        size: 20,  // Icon etwas kleiner
      ),
      onPressed: () => _openNoteModal(context, prov),
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
