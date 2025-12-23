import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/features/auth/presentation/theme/auth_theme.dart';
import 'package:tapem/features/auth/presentation/widgets/auth_background.dart';
import 'package:tapem/features/auth/presentation/widgets/glass_card.dart';
import 'package:tapem/features/auth/presentation/widgets/premium_text_field.dart';
import 'package:tapem/features/gym/application/gym_directory_provider.dart';
import 'package:tapem/l10n/app_localizations.dart';

class GymAddMembershipScreen extends ConsumerStatefulWidget {
  const GymAddMembershipScreen({super.key});

  @override
  ConsumerState<GymAddMembershipScreen> createState() =>
      _GymAddMembershipScreenState();
}

class _GymAddMembershipScreenState
    extends ConsumerState<GymAddMembershipScreen> {
  final _searchController = TextEditingController();
  late final StateController<String> _gymSearchQuery;

  @override
  void initState() {
    super.initState();
    _gymSearchQuery = ref.read(gymSearchQueryProvider.notifier);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _gymSearchQuery.state = '';
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final gymsAsync = ref.watch(listGymsProvider);
    final gyms = ref.watch(filteredGymsProvider);
    final auth = ref.watch(authControllerProvider);
    final memberships = auth.gymCodes ?? [];

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: AuthBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white70),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              loc.gymAddMembershipTitle,
              textAlign: TextAlign.center,
              style: AuthTheme.headingStyle,
            ),
            const SizedBox(height: AuthTheme.spacingS),
            Text(
              loc.gymAddMembershipSubtitle,
              textAlign: TextAlign.center,
              style: AuthTheme.bodyStyle.copyWith(
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: AuthTheme.spacingL),
            PremiumTextField(
              label: loc.gymSearchHint,
              controller: _searchController,
              prefixIcon: Icons.search,
              onChanged: (value) {
                _gymSearchQuery.state = value;
              },
            ),
            const SizedBox(height: AuthTheme.spacingL),
            Expanded(
              child: GlassCard(
                padding: EdgeInsets.zero,
                child: gymsAsync.when(
                  data: (_) {
                    if (gyms.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            loc.gymSearchEmpty,
                            textAlign: TextAlign.center,
                            style: AuthTheme.bodyStyle.copyWith(
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: gyms.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: Colors.white.withOpacity(0.08),
                      ),
                      itemBuilder: (context, index) {
                        final gym = gyms[index];
                        final alreadyMember = memberships.contains(gym.id);
                        return ListTile(
                          leading: gym.logoUrl != null
                              ? CircleAvatar(
                                  backgroundImage: NetworkImage(gym.logoUrl!),
                                  backgroundColor: Colors.white.withOpacity(0.1),
                                )
                              : const CircleAvatar(
                                  child: Icon(Icons.fitness_center_outlined),
                                ),
                          title: Text(
                            gym.name,
                            style: AuthTheme.bodyStyle,
                          ),
                          subtitle: alreadyMember
                              ? Text(
                                  loc.gymMembershipAlreadyAdded,
                                  style: AuthTheme.labelStyle,
                                )
                              : (gym.code.isEmpty
                                  ? null
                                  : Text(
                                      gym.code,
                                      style: AuthTheme.labelStyle,
                                    )),
                          trailing: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: Colors.white70,
                          ),
                          onTap: alreadyMember
                              ? null
                              : () {
                                  Navigator.of(context).pushReplacementNamed(
                                    AppRouter.gymJoin,
                                    arguments: gym.id,
                                  );
                                },
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Colors.white70),
                  ),
                  error: (error, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        loc.authErrorGeneric(error),
                        textAlign: TextAlign.center,
                        style: AuthTheme.bodyStyle.copyWith(
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
