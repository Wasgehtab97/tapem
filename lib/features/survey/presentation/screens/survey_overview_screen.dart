import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../survey_provider.dart';
import '../../survey.dart';
import 'survey_detail_screen.dart';
import 'package:tapem/l10n/app_localizations.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.surveyListTitle),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: loc.surveyTabOpen),
            Tab(text: loc.surveyTabClosed),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(context, surveyProv.openSurveys, loc: loc, open: true),
          _buildList(context, surveyProv.closedSurveys, loc: loc, open: false),
        ],
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
      return Center(child: Text(open ? loc.surveyEmpty : loc.surveyEmptyClosed));
    }
    return ListView.builder(
      itemCount: surveys.length,
      itemBuilder: (_, index) {
        final survey = surveys[index];
        return ListTile(
          title: Text(survey.title),
          subtitle: Text(DateFormat.yMd().add_Hm().format(survey.createdAt)),
          trailing: open ? const Icon(Icons.arrow_forward_ios) : null,
          onTap:
              open
                  ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => SurveyDetailScreen(
                              gymId: widget.gymId,
                              survey: survey,
                            ),
                      ),
                    );
                  }
                  : null,
        );
      },
    );
  }
}
