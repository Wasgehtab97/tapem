import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tapem/core/providers/device_provider.dart';
import 'package:tapem/features/device/domain/models/device_session_snapshot.dart';
import 'set_card.dart';

class DevicePager extends StatefulWidget {
  final Widget editablePage;
  final DeviceProvider provider;
  final String gymId;
  final String deviceId;
  const DevicePager({
    super.key,
    required this.editablePage,
    required this.provider,
    required this.gymId,
    required this.deviceId,
  });

  @override
  State<DevicePager> createState() => _DevicePagerState();
}

class _DevicePagerState extends State<DevicePager> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = widget.provider;
    final itemCount = 1 + prov.sessionSnapshots.length;
    return Stack(
      children: [
        PageView.builder(
          controller: _controller,
          itemCount: itemCount,
          onPageChanged: (index) {
            if (index >= itemCount - 2 && prov.hasMoreSnapshots) {
              prov.loadMoreSnapshots(
                gymId: widget.gymId,
                deviceId: widget.deviceId,
              );
            }
          },
          itemBuilder: (context, index) {
            if (index == 0) return widget.editablePage;
            final snap = prov.sessionSnapshots[index - 1];
            return ReadOnlySnapshotPage(
              snapshot: snap,
              onJumpToCurrent: () => _controller.animateToPage(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
            );
          },
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => _controller.previousPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            ),
            child: const SizedBox(width: 28),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => _controller.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            ),
            child: const SizedBox(width: 28),
          ),
        ),
      ],
    );
  }
}

class ReadOnlySnapshotPage extends StatelessWidget {
  final DeviceSessionSnapshot snapshot;
  final VoidCallback onJumpToCurrent;
  const ReadOnlySnapshotPage({
    super.key,
    required this.snapshot,
    required this.onJumpToCurrent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                DateFormat('dd.MM.yyyy HH:mm').format(snapshot.createdAt),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < snapshot.sets.length; i++)
                SetCard(
                  index: i,
                  set: {
                    'number': '${i + 1}',
                    'weight': snapshot.sets[i].kg.toString(),
                    'reps': snapshot.sets[i].reps.toString(),
                    'rir': snapshot.sets[i].rir?.toString() ?? '',
                    'note': snapshot.sets[i].note,
                    'dropWeight': snapshot.sets[i].drops.isNotEmpty
                        ? snapshot.sets[i].drops.first.kg.toString()
                        : '',
                    'dropReps': snapshot.sets[i].drops.isNotEmpty
                        ? snapshot.sets[i].drops.first.reps.toString()
                        : '',
                    'done': snapshot.sets[i].done,
                  },
                  readOnly: true,
                  size: SetCardSize.dense,
                ),
              if (snapshot.note != null && snapshot.note!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(snapshot.note!),
                ),
            ],
          ),
        ),
        TextButton(
          onPressed: onJumpToCurrent,
          child: const Text('Zur aktuellen Session'),
        ),
      ],
    );
  }
}
