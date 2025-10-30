import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/onboarding_funnel_repository.dart';
import '../../data/sources/firestore_onboarding_source.dart';
import '../providers/onboarding_funnel_provider.dart';
import '../widgets/onboarding_member_card.dart';
import '../../../../l10n/app_localizations.dart';

class OnboardingFunnelScreen extends StatelessWidget {
  const OnboardingFunnelScreen({
    super.key,
    required this.gymId,
    this.repository,
    Duration? searchDebounce,
  }) : searchDebounce = searchDebounce ?? const Duration(milliseconds: 350);

  final String gymId;
  final OnboardingFunnelRepository? repository;
  final Duration searchDebounce;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<OnboardingFunnelProvider>(
      create: (_) => OnboardingFunnelProvider(
        repository: repository ?? OnboardingFunnelRepository(
          source: FirestoreOnboardingSource(),
        ),
        searchDebounce: searchDebounce,
      )..loadMemberCount(gymId),
      child: _OnboardingFunnelView(gymId: gymId),
    );
  }
}

class _OnboardingFunnelView extends StatefulWidget {
  const _OnboardingFunnelView({required this.gymId});

  final String gymId;

  @override
  State<_OnboardingFunnelView> createState() => _OnboardingFunnelViewState();
}

class _OnboardingFunnelViewState extends State<_OnboardingFunnelView> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final provider = context.watch<OnboardingFunnelProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.onboardingFunnelTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TotalMembersCard(provider: provider, loc: loc),
            const SizedBox(height: 16),
            Text(loc.onboardingFunnelSubtitle, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLength: 4,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: InputDecoration(
                labelText: loc.onboardingFunnelSearchHint,
                counterText: '',
              ),
              onChanged: (value) => provider.searchMember(widget.gymId, value),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _SearchResultSection(provider: provider, loc: loc),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalMembersCard extends StatelessWidget {
  const _TotalMembersCard({
    required this.provider,
    required this.loc,
  });

  final OnboardingFunnelProvider provider;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    final count = provider.memberCount;
    final isLoading = provider.isLoadingCount;
    final textTheme = Theme.of(context).textTheme;
    final subtitle = count == null
        ? loc.onboardingFunnelCountLoading
        : loc.onboardingFunnelCountLabel(count);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.onboardingFunnelTotalMembersLabel, style: textTheme.labelMedium),
            const SizedBox(height: 8),
            if (isLoading)
              const Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              Text(
                NumberFormat.decimalPattern(loc.localeName).format(count ?? 0),
                style: textTheme.headlineMedium,
              ),
            const SizedBox(height: 8),
            Text(subtitle, style: textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _SearchResultSection extends StatelessWidget {
  const _SearchResultSection({
    required this.provider,
    required this.loc,
  });

  final OnboardingFunnelProvider provider;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    if (provider.isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null) {
      final errorDetail = provider.errorMessage!.trim();
      final detailedMessage = errorDetail.isEmpty
          ? loc.onboardingFunnelSearchError
          : '${loc.onboardingFunnelSearchError}\n$errorDetail';
      return Center(
        child: Text(
          detailedMessage,
          textAlign: TextAlign.center,
        ),
      );
    }

    if (!provider.hasSearched) {
      return Center(
        child: Text(
          loc.onboardingFunnelSearchIdle,
          textAlign: TextAlign.center,
        ),
      );
    }

    final detail = provider.selectedMember;
    if (detail == null) {
      return Center(
        child: Text(
          loc.onboardingFunnelSearchNoResult,
          textAlign: TextAlign.center,
        ),
      );
    }

    return SingleChildScrollView(
      child: OnboardingMemberCard(detail: detail),
    );
  }
}
