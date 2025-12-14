import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/features/coaching/application/coach_invite_providers.dart';
import 'package:tapem/features/coaching/application/coaching_providers.dart';

class ExternalCoachInvitesScreen extends ConsumerWidget {
  const ExternalCoachInvitesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;

    final invitesAsync = ref.watch(pendingInvitesForCoachEmailProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Einladungen',
          style: TextStyle(color: brandColor),
        ),
        foregroundColor: brandColor,
      ),
      body: invitesAsync.when(
        data: (invites) {
          if (invites.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'Derzeit liegen keine offenen Einladungen vor.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: invites.length,
            itemBuilder: (context, index) {
              final invite = invites[index];
              return _InviteTile(inviteId: invite.id);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'Einladungen konnten nicht geladen werden.\n$err',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class _InviteTile extends ConsumerWidget {
  const _InviteTile({required this.inviteId});

  final String inviteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;

    final invitesAsync = ref.watch(pendingInvitesForCoachEmailProvider);
    final authState = ref.watch(authViewStateProvider);

    return invitesAsync.when(
      data: (invites) {
        final invite =
            invites.firstWhere((i) => i.id == inviteId, orElse: () => invites[0]);
        final clientNameAsync =
            ref.watch(clientDisplayNameProvider(invite.clientId));

        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: brandColor.withOpacity(0.08),
              child: Icon(
                Icons.person_add_alt,
                color: brandColor,
              ),
            ),
            title: clientNameAsync.when(
              data: (name) => Text(name),
              loading: () => const Text('Lade …'),
              error: (_, __) => Text(invite.clientId),
            ),
            subtitle: Text(
              'Einladung aus Gym ${invite.gymId}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            trailing: FilledButton(
              onPressed: () async {
                final coachId = authState.userId;
                if (coachId == null || coachId.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Coach-ID nicht verfügbar.'),
                    ),
                  );
                  return;
                }

                final coachingRepo = ref.read(coachingRepositoryProvider);
                final inviteSource = ref.read(coachInviteSourceProvider);

                try {
                  // Coaching-Relation anlegen/aktivieren
                  await coachingRepo.requestCoaching(
                    gymId: invite.gymId,
                    coachId: coachId,
                    clientId: invite.clientId,
                  );
                  final relationId =
                      '${invite.gymId}_${coachId}_${invite.clientId}';
                  await coachingRepo.updateRelationStatus(
                    relationId: relationId,
                    status: 'active',
                  );
                  // Einladung als angenommen markieren
                  await inviteSource.markInviteAccepted(
                    inviteId: invite.id,
                    coachId: coachId,
                  );

                  // Daten neu laden
                  ref.invalidate(pendingInvitesForCoachEmailProvider);
                  ref.invalidate(coachRelationsProvider);
                  ref.invalidate(clientRelationsProvider);

                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Einladung angenommen.'),
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Fehler beim Annehmen der Einladung: $e'),
                    ),
                  );
                }
              },
              child: const Text('Annehmen'),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

