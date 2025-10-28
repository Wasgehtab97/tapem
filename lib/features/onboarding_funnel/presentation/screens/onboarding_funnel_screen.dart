import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/brand_gradient_card.dart';
import '../../../../core/widgets/brand_primary_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/onboarding_funnel_provider.dart';
import '../widgets/onboarding_member_card.dart';
import '../../domain/models/onboarding_member_summary.dart';

class OnboardingFunnelScreen extends StatefulWidget {
  final String gymId;

  const OnboardingFunnelScreen({super.key, required this.gymId});

  @override
  State<OnboardingFunnelScreen> createState() => _OnboardingFunnelScreenState();
}

class _OnboardingFunnelScreenState extends State<OnboardingFunnelScreen> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<OnboardingFunnelProvider>().ensureInitialized(widget.gymId);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: ListView(
            children: [
              _buildMemberCountCard(context, provider, loc),
              const SizedBox(height: AppSpacing.lg),
              _buildSearchField(context, provider, loc),
              const SizedBox(height: AppSpacing.md),
              _buildSearchResult(context, provider, loc),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberCountCard(
    BuildContext context,
    OnboardingFunnelProvider provider,
    AppLocalizations loc,
  ) {
    final theme = Theme.of(context);

    Widget content;
    if (provider.isLoadingCount && provider.memberCount == null) {
      content = const Center(child: CircularProgressIndicator());
    } else if (provider.countErrorMessage != null) {
      content = Text(
        loc.onboardingMembersCountError,
        style: theme.textTheme.bodyMedium,
      );
    } else {
      final count = provider.memberCount ?? 0;
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.onboardingMembersCountLabel,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            NumberFormat.decimalPattern(loc.localeName).format(count),
            style: theme.textTheme.displaySmall,
          ),
        ],
      );
    }

    return BrandGradientCard(child: content);
  }

  Widget _buildSearchField(
    BuildContext context,
    OnboardingFunnelProvider provider,
    AppLocalizations loc,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.onboardingSearchLabel,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.search,
          maxLength: 4,
          inputFormatters: const [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
          ],
          decoration: InputDecoration(
            hintText: loc.onboardingSearchHint,
            counterText: '',
            suffixIcon: _controller.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      provider.clearSearch();
                      setState(() {});
                    },
                  ),
          ),
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _submitSearch(context, provider, loc),
        ),
        const SizedBox(height: AppSpacing.sm),
        BrandPrimaryButton(
          onPressed: provider.isSearching ? null : () => _submitSearch(context, provider, loc),
          child: provider.isSearching
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(loc.onboardingSearchButton),
        ),
      ],
    );
  }

  Widget _buildSearchResult(
    BuildContext context,
    OnboardingFunnelProvider provider,
    AppLocalizations loc,
  ) {
    if (provider.isSearching) {
      return const SizedBox.shrink();
    }

    if (!provider.hasSearched) {
      return const SizedBox.shrink();
    }

    if (provider.searchResult != null) {
      final summary = provider.searchResult!;
      return OnboardingMemberCard(
        summary: summary,
        onTap: () => _showMemberDetails(context, summary),
      );
    }

    if (provider.searchErrorType == OnboardingSearchErrorType.notFound) {
      return Text(
        loc.onboardingSearchNotFound(provider.lastSearchNumber ?? ''),
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    if (provider.searchErrorType == OnboardingSearchErrorType.failure) {
      return Text(
        loc.onboardingSearchError,
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: Theme.of(context).colorScheme.error),
      );
    }

    return const SizedBox.shrink();
  }

  void _submitSearch(
    BuildContext context,
    OnboardingFunnelProvider provider,
    AppLocalizations loc,
  ) {
    final raw = _controller.text.trim();
    if (raw.isEmpty) {
      _showError(loc.onboardingSearchInvalidNumber);
      return;
    }

    final normalized = raw.padLeft(4, '0');
    _focusNode.unfocus();
    provider.searchMember(widget.gymId, normalized);
    if (_controller.text != normalized) {
      _controller.text = normalized;
      _controller.selection = TextSelection.collapsed(offset: normalized.length);
    }
  }

  void _showMemberDetails(BuildContext context, OnboardingMemberSummary summary) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final dateFormatter = DateFormat.yMMMMd(loc.localeName);

    String formatDate(DateTime? value) {
      if (value == null) return loc.onboardingDateUnknown;
      return dateFormatter.format(value);
    }

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.onboardingMemberDetailsTitle(summary.memberNumber),
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                summary.displayName?.isNotEmpty == true
                    ? summary.displayName!
                    : loc.genericUser,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (summary.email != null && summary.email!.isNotEmpty) ...[
                Text(
                  '${loc.onboardingMemberEmailLabel}: ${summary.email!}',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
              Text(
                '${loc.onboardingMemberRegisteredLabel}: ${formatDate(summary.registeredAt)}',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${loc.onboardingMemberAssignedLabel}: ${formatDate(summary.onboardingAssignedAt)}',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${loc.onboardingMemberTrainingDaysLabel}: ${loc.onboardingTrainingDays(summary.trainingDays)}',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerRight,
                child: BrandPrimaryButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(loc.commonOk),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
