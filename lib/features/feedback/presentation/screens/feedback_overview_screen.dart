import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tapem/features/feedback/feedback_provider.dart' as feedback_riverpod;
import 'package:tapem/features/feedback/models/feedback_entry.dart';
import 'package:tapem/features/device/domain/models/device.dart';
import 'package:tapem/core/providers/gym_provider.dart';

class FeedbackOverviewScreen extends ConsumerStatefulWidget {
  final String gymId;
  const FeedbackOverviewScreen({Key? key, required this.gymId})
    : super(key: key);

  @override
  ConsumerState<FeedbackOverviewScreen> createState() =>
      _FeedbackOverviewScreenState();
}

class _FeedbackOverviewScreenState
    extends ConsumerState<FeedbackOverviewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(feedback_riverpod.feedbackProvider).loadFeedback(widget.gymId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(feedback_riverpod.feedbackProvider);
    final gym = ref.watch(gymProvider);
    final devices = {for (var d in gym.devices) d.uid: d}.cast<String, Device>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Offen'), Tab(text: 'Erledigt')],
        ),
      ),
      body:
          provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildList(provider.openEntries, devices, false),
                  _buildList(provider.doneEntries, devices, true),
                ],
              ),
    );
  }

  Widget _buildList(
    List<FeedbackEntry> entries,
    Map<String, Device> devices,
    bool done,
  ) {
    if (entries.isEmpty) {
      return const Center(child: Text('Keine Einträge'));
    }
    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (_, idx) {
        final entry = entries[idx];
        final deviceName = devices[entry.deviceId]?.name ?? entry.deviceId;
        return ListTile(
          title: Text(deviceName),
          subtitle: Text(
            '${entry.createdAt.toLocal().toString().split('T').first}\n${entry.text}',
          ),
          isThreeLine: true,
          trailing:
              !done
                  ? IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: () {
                      ref.read(feedback_riverpod.feedbackProvider).markDone(
                        gymId: widget.gymId,
                        entryId: entry.id,
                      );
                    },
                  )
                  : null,
        );
      },
    );
  }
}
