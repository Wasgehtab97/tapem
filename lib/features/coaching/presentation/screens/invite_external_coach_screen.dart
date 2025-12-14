import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/features/coaching/application/coach_invite_providers.dart';

class InviteExternalCoachScreen extends ConsumerStatefulWidget {
  const InviteExternalCoachScreen({super.key});

  @override
  ConsumerState<InviteExternalCoachScreen> createState() =>
      _InviteExternalCoachScreenState();
}

class _InviteExternalCoachScreenState
    extends ConsumerState<InviteExternalCoachScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;

    final authState = ref.watch(authViewStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Externen Coach einladen',
          style: TextStyle(color: brandColor),
        ),
        foregroundColor: brandColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lade eine:n externe:n Coach per E-Mail ein, '
                'dich in tapem zu coachen.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E-Mail-Adresse des Coaches',
                  hintText: 'coach@example.com',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) {
                    return 'Bitte E-Mail-Adresse eingeben.';
                  }
                  if (!v.contains('@') || !v.contains('.')) {
                    return 'Bitte eine gültige E-Mail-Adresse eingeben.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) {
                    return;
                  }
                  final email = _emailController.text.trim();
                  final gymId = authState.gymCode;
                  final clientId = authState.userId;

                  if (gymId == null ||
                      gymId.isEmpty ||
                      clientId == null ||
                      clientId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Gym oder Nutzer nicht verfügbar. '
                          'Bitte erneut versuchen.',
                        ),
                      ),
                    );
                    return;
                  }

                  final source = ref.read(coachInviteSourceProvider);
                  try {
                    await source.createInvite(
                      gymId: gymId,
                      clientId: clientId,
                      email: email,
                    );
                    ref.invalidate(clientCoachInvitesProvider);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Einladung wurde gesendet.'),
                      ),
                    );
                    Navigator.pop(context);
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Fehler beim Senden der Einladung: $e',
                        ),
                      ),
                    );
                  }
                },
                child: const Text('Einladung senden'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

