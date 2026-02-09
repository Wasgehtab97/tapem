import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/widgets/brand_modal.dart';
import 'package:tapem/core/widgets/brand_primary_button.dart';
import 'package:tapem/l10n/app_localizations.dart';

enum UsernameAvailability { idle, loading, available, taken, error }

String normalizeUsername(String v) {
  final collapsed = v.replaceAll(RegExp(' +'), ' ');
  return collapsed.trim();
}

bool isValidUsername(String v) {
  final n = normalizeUsername(v);
  if (n.length < 3 || n.length > 20) return false;
  return RegExp(r'^[A-Za-z0-9 ]+$').hasMatch(n);
}

bool canSubmitUsername({
  required String input,
  required String current,
  required UsernameAvailability availability,
  required bool submitting,
}) {
  final normalized = normalizeUsername(input);
  final currentNorm = normalizeUsername(current);
  return !submitting &&
      isValidUsername(normalized) &&
      normalized.toLowerCase() != currentNorm.toLowerCase() &&
      availability != UsernameAvailability.taken;
}

Future<void> showChangeUsernameSheet(BuildContext context) async {
  final loc = AppLocalizations.of(context)!;
  final container = ProviderScope.containerOf(context, listen: false);
  final AuthProvider auth = container.read(authControllerProvider);
  final ctr = TextEditingController();
  String? error;
  UsernameAvailability availability = UsernameAvailability.idle;
  Timer? debouncer;
  bool loading = false;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => StatefulBuilder(
      builder: (ctx, setState) {
        final theme = Theme.of(ctx);
        final brandTheme = theme.extension<AppBrandTheme>();
        final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;

        Future<void> check(String value) async {
          final name = normalizeUsername(value);
          if (!isValidUsername(name)) {
            setState(() {
              error = name.isEmpty ? null : loc.usernameInvalid;
              availability = UsernameAvailability.idle;
            });
            return;
          }
          final current = auth.userName ?? '';
          if (name.toLowerCase() == normalizeUsername(current).toLowerCase()) {
            setState(() {
              error = null;
              availability = UsernameAvailability.idle;
            });
            return;
          }
          setState(() {
            error = null;
            availability = UsernameAvailability.loading;
          });
          try {
            final free = await auth.checkUsernameAvailable(name.toLowerCase());
            setState(() {
              availability = free
                  ? UsernameAvailability.available
                  : UsernameAvailability.taken;
              if (!free) error = loc.usernameTaken;
            });
          } catch (_) {
            setState(() {
              availability = UsernameAvailability.error;
            });
          }
        }

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: BrandModalSheet(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BrandModalHeader(
                  icon: Icons.person_rounded,
                  accent: brandColor,
                  title: loc.usernameDialogTitle,
                  subtitle: loc.usernameHelper,
                  onClose: loading ? null : () => Navigator.pop(ctx),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: ctr,
                  autofocus: true,
                  enabled: !loading,
                  onChanged: (v) {
                    final normalized = normalizeUsername(v);
                    if (v != normalized) {
                      ctr.value = TextEditingValue(
                        text: normalized,
                        selection: TextSelection.collapsed(
                          offset: normalized.length,
                        ),
                      );
                    }
                    debouncer?.cancel();
                    debouncer = Timer(
                      const Duration(milliseconds: 300),
                      () => check(normalized),
                    );
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    labelText: loc.usernameFieldLabel,
                    helperText: error == null ? loc.usernameHelper : null,
                    errorText: error,
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.04),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: brandColor.withOpacity(0.4),
                        width: 1.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (normalizeUsername(ctr.text).isNotEmpty)
                  Text(
                    loc.usernameLowerPreview(
                      normalizeUsername(ctr.text).toLowerCase(),
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: loading ? null : () => Navigator.pop(ctx),
                        child: Text(loc.cancelButton),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: BrandPrimaryButton(
                        onPressed:
                            canSubmitUsername(
                              input: ctr.text,
                              current: auth.userName ?? '',
                              availability: availability,
                              submitting: loading,
                            )
                            ? () async {
                                final username = normalizeUsername(ctr.text);
                                setState(() => loading = true);
                                final success = await auth.setUsername(
                                  username,
                                );
                                if (!ctx.mounted) return;
                                if (success) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(loc.saveSuccess)),
                                  );
                                } else {
                                  setState(() {
                                    loading = false;
                                    if (auth.error == 'username_taken') {
                                      error = loc.usernameTaken;
                                      availability = UsernameAvailability.taken;
                                    } else {
                                      error = auth.error;
                                      availability = UsernameAvailability.error;
                                    }
                                  });
                                }
                              }
                            : null,
                        child: loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(loc.saveButton),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
  debouncer?.cancel();
  ctr.dispose();
}
