import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/destructive_action.dart';
import 'package:tapem/core/widgets/brand_outline.dart';
import 'package:tapem/features/feedback/feedback_provider.dart'
    as feedback_riverpod;
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

class _FeedbackOverviewScreenState extends ConsumerState<FeedbackOverviewScreen>
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
    final devices = {
      for (var d in gym.devices) d.uid: d,
    }.cast<String, Device>();
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Feedback'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: brandColor,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: brandColor,
          labelColor: brandColor,
          unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.7),
          tabs: const [
            Tab(text: 'Offen'),
            Tab(text: 'Erledigt'),
          ],
        ),
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
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  'Alle Rückmeldungen deiner Mitglieder im Überblick.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildList(provider.openEntries, devices, false),
                          _buildList(provider.doneEntries, devices, true),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(
    List<FeedbackEntry> entries,
    Map<String, Device> devices,
    bool done,
  ) {
    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.inbox_outlined, size: 40),
            SizedBox(height: AppSpacing.sm),
            Text('Keine Einträge'),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, idx) {
        final entry = entries[idx];
        final deviceName = devices[entry.deviceId]?.name ?? entry.deviceId;
        final createdAt = entry.createdAt.toLocal().toString().split('T').first;
        return BrandOutline(
          onTap: done
              ? null
              : () {
                  // Kein eigener Detail-Screen, aber der Tap gibt ein
                  // hochwertiges Interaktionsgefühl.
                },
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: Theme.of(
                      context,
                    ).extension<AppBrandTheme>()?.gradient,
                  ),
                  child: const Icon(
                    Icons.feedback_outlined,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deviceName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        entry.text,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        createdAt,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!done)
                  IconButton(
                    icon: const Icon(Icons.check_circle_outline),
                    onPressed: () async {
                      await ref
                          .read(feedback_riverpod.feedbackProvider)
                          .markDone(gymId: widget.gymId, entryId: entry.id);
                      if (!context.mounted) return;
                      showUndoSnackBar(
                        context: context,
                        message: 'Feedback als erledigt markiert.',
                        onUndo: () => ref
                            .read(feedback_riverpod.feedbackProvider)
                            .markOpen(gymId: widget.gymId, entryId: entry.id),
                        undoSuccessMessage:
                            'Feedback zurück auf offen gesetzt.',
                        undoErrorPrefix: 'Rückgängig fehlgeschlagen',
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
