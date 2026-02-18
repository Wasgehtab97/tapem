import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/analytics/analytics_service.dart';
import 'package:tapem/core/constants.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/providers/shared_preferences_provider.dart';
import 'package:tapem/core/widgets/network_circle_avatar.dart';
import 'package:tapem/features/auth/presentation/theme/auth_theme.dart';
import 'package:tapem/features/auth/presentation/widgets/auth_background.dart';
import 'package:tapem/features/auth/presentation/widgets/auth_keyboard_scroll_view.dart';
import 'package:tapem/features/auth/presentation/widgets/glass_card.dart';
import 'package:tapem/features/gym/application/gym_directory_provider.dart';
import 'package:tapem/l10n/app_localizations.dart';

class SelectGymScreen extends ConsumerStatefulWidget {
  const SelectGymScreen({super.key});

  @override
  ConsumerState<SelectGymScreen> createState() => _SelectGymScreenState();
}

class _SelectGymScreenState extends ConsumerState<SelectGymScreen> {
  String? _claimingGymCode;
  String? _localErrorMessage;
  bool _redirectingHome = false;

  String? _mapError(AppLocalizations loc, String? code) {
    switch (code) {
      case 'invalid_gym_code':
        return loc.invalidGymSelectionError;
      case 'membership_sync_failed':
        return loc.membershipSyncError;
      case 'missing_membership':
        return loc.missingMembershipError;
      default:
        return code;
    }
  }

  Future<void> _selectGym(String code) async {
    if (_claimingGymCode != null) return;
    setState(() {
      _claimingGymCode = code;
      _localErrorMessage = null;
    });
    final AuthProvider auth = ref.read(authControllerProvider);
    AnalyticsService.logGymSelected(gymId: code, source: 'switch');
    final result = await auth.switchGym(code);
    if (!mounted) return;
    if (result.success) {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString(StorageKeys.lastUsedGymId, code);
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRouter.home, (route) => false, arguments: 1);
    } else {
      final loc = AppLocalizations.of(context)!;
      final latestError =
          _mapError(loc, result.errorCode) ?? loc.membershipSyncError;
      setState(() => _localErrorMessage = latestError);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(latestError)));
    }
    if (mounted) {
      setState(() {
        _claimingGymCode = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final gyms = auth.gymCodes ?? [];
    final loc = AppLocalizations.of(context)!;

    if (!_redirectingHome &&
        _claimingGymCode == null &&
        auth.gymContextStatus == GymContextStatus.ready &&
        (auth.gymCode?.isNotEmpty ?? false)) {
      _redirectingHome = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRouter.home,
          (route) => false,
          arguments: 1,
        );
      });
    }

    final errorMessage = _localErrorMessage;
    final isInitialLoading =
        auth.isLoading && _claimingGymCode == null && gyms.isEmpty;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuthBackground(
        child: AuthKeyboardScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AuthTheme.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 18),
              Text(
                loc.selectGymTitle,
                textAlign: TextAlign.center,
                style: AuthTheme.headingStyle.copyWith(fontSize: 28),
              ),
              const SizedBox(height: 6),
              Text(
                loc.gymSwitchSubtitle,
                textAlign: TextAlign.center,
                style: AuthTheme.bodyStyle,
              ),
              const SizedBox(height: AuthTheme.spacingL),
              GlassCard(
                padding: EdgeInsets.zero,
                child: isInitialLoading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      )
                    : _GymSelectionList(
                        gyms: gyms,
                        claimingGymCode: _claimingGymCode,
                        onSelectGym: _selectGym,
                      ),
              ),
              if (gyms.isEmpty && !isInitialLoading) ...[
                const SizedBox(height: AuthTheme.spacingM),
                Text(
                  loc.missingMembershipError,
                  textAlign: TextAlign.center,
                  style: AuthTheme.bodyStyle,
                ),
              ],
              if (errorMessage != null) ...[
                const SizedBox(height: AuthTheme.spacingM),
                Text(
                  errorMessage,
                  style: AuthTheme.bodyStyle.copyWith(color: AuthTheme.danger),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _GymSelectionList extends ConsumerWidget {
  const _GymSelectionList({
    required this.gyms,
    required this.claimingGymCode,
    required this.onSelectGym,
  });

  final List<String> gyms;
  final String? claimingGymCode;
  final ValueChanged<String> onSelectGym;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    if (gyms.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: gyms.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: Colors.white.withOpacity(0.08)),
      itemBuilder: (context, i) {
        final code = gyms[i];
        final isProcessing = claimingGymCode == code;
        final gymAsync = ref.watch(gymByIdProvider(code));
        return gymAsync.when(
          data: (gym) => ListTile(
            leading: NetworkCircleAvatar(url: gym.logoUrl),
            title: Text(gym.name, style: AuthTheme.bodyStyle),
            subtitle: Text(code, style: AuthTheme.labelStyle),
            trailing: isProcessing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.1,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AuthTheme.textMuted,
                  ),
            onTap: isProcessing ? null : () => onSelectGym(code),
          ),
          loading: () => ListTile(
            title: Text(code, style: AuthTheme.bodyStyle),
            trailing: const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            onTap: isProcessing ? null : () => onSelectGym(code),
          ),
          error: (_, __) => ListTile(
            title: Text(code, style: AuthTheme.bodyStyle),
            subtitle: Text(loc.loadingErrorLabel, style: AuthTheme.labelStyle),
            onTap: isProcessing ? null : () => onSelectGym(code),
          ),
        );
      },
    );
  }
}
