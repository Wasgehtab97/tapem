import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/features/coaching/application/coaching_providers.dart';

class SelectCoachScreen extends ConsumerWidget {
  const SelectCoachScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;
    final authState = ref.watch(authViewStateProvider);

    final coachesAsync = ref.watch(availableCoachIdsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Coach auswählen',
          style: TextStyle(color: brandColor),
        ),
        foregroundColor: brandColor,
      ),
      body: coachesAsync.when(
        data: (ids) {
          if (authState.gymCode == null || authState.gymCode!.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'Bitte wähle zuerst ein Gym aus, '
                  'um Coaches aus deinem Studio zu sehen.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
            );
          }

          if (ids.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.school_outlined,
                      size: 56,
                      color: brandColor.withOpacity(0.7),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Noch keine Coaches in diesem Gym',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: brandColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Sobald Trainer:innen die Coach-Option aktivieren, '
                      'kannst du sie hier als persönlichen Coach auswählen.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: ids.length,
            itemBuilder: (context, index) {
              final coachId = ids[index];
              return _CoachListTile(coachId: coachId);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'Coaches konnten nicht geladen werden.\n$err',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class _CoachListTile extends ConsumerWidget {
  const _CoachListTile({required this.coachId});

  final String coachId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;

    final nameAsync = ref.watch(coachDisplayNameProvider(coachId));
    final authState = ref.watch(authViewStateProvider);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: brandColor.withOpacity(0.08),
          child: Icon(
            Icons.person,
            color: brandColor,
          ),
        ),
        title: nameAsync.when(
          data: (name) => Text(name),
          loading: () => const Text('Lade …'),
          error: (_, __) => Text(coachId),
        ),
        subtitle: Text(
          'Coach in deinem Gym',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        trailing: FilledButton(
          onPressed: () async {
            final gymId = authState.gymCode;
            final clientId = authState.userId;
            if (gymId == null || gymId.isEmpty || clientId == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Gym oder Nutzer nicht verfügbar. Bitte erneut versuchen.',
                  ),
                ),
              );
              return;
            }
            final repo = ref.read(coachingRepositoryProvider);
            try {
              await repo.requestCoaching(
                gymId: gymId,
                coachId: coachId,
                clientId: clientId,
              );
              // Client- und Coach-Relationen neu laden
              ref.invalidate(clientRelationsProvider);
              ref.invalidate(coachRelationsProvider);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Coaching-Anfrage gesendet.'),
                ),
              );
              Navigator.pop(context);
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Fehler beim Senden der Anfrage: $e'),
                ),
              );
            }
          },
          child: const Text('Anfrage senden'),
        ),
      ),
    );
  }
}

