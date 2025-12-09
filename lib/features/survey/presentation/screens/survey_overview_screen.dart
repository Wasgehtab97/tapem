import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/brand_outline.dart';
import 'package:tapem/l10n/app_localizations.dart';

import '../../survey.dart';
import '../../survey_provider.dart';
import 'survey_detail_screen.dart';

class SurveyOverviewScreen extends ConsumerStatefulWidget {
  final String gymId;
  const SurveyOverviewScreen({Key? key, required this.gymId}) : super(key: key);

  @override
  ConsumerState<SurveyOverviewScreen> createState() =>
      _SurveyOverviewScreenState();
}

class _SurveyOverviewScreenState extends ConsumerState<SurveyOverviewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(surveyProvider).listen(widget.gymId);
    });
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    ref.read(surveyProvider).cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surveyProv = ref.watch(surveyProvider);
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(loc.surveyListTitle),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: brandColor,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: brandColor,
          labelColor: brandColor,
          unselectedLabelColor:
              theme.colorScheme.onSurface.withOpacity(0.7),
          tabs: [
            Tab(text: loc.surveyTabOpen),
            Tab(text: loc.surveyTabClosed),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                ),
                child: Text(
                  'Aktive und abgeschlossene Umfragen deines Gyms.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(
                      context,
                      surveyProv.openSurveys,
                      loc: loc,
                      open: true,
                    ),
                    _buildList(
                      context,
                      surveyProv.closedSurveys,
                      loc: loc,
                      open: false,
                    ),
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
    BuildContext context,
    List<Survey> surveys, {
    required AppLocalizations loc,
    required bool open,
  }) {
    if (surveys.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              open ? Icons.inbox_outlined : Icons.check_circle_outline,
              size: 40,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(open ? loc.surveyEmpty : loc.surveyEmptyClosed),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      itemCount: surveys.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, index) {
        final survey = surveys[index];
        final subtitle = DateFormat.yMd().add_Hm().format(survey.createdAt);
        return BrandOutline(
          onTap: open
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SurveyDetailScreen(
                        gymId: widget.gymId,
                        survey: survey,
                      ),
                    ),
                  );
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient:
                        Theme.of(context).extension<AppBrandTheme>()?.gradient,
                  ),
                  child: Icon(
                    open ? Icons.campaign_outlined : Icons.poll,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        survey.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                            ),
                      ),
                    ],
                  ),
                ),
                if (open)
                  const Icon(
                    Icons.chevron_right,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
