import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../survey_provider.dart';
import '../../survey.dart';
import 'survey_detail_screen.dart';

class SurveyOverviewScreen extends StatefulWidget {
  final String gymId;
  const SurveyOverviewScreen({Key? key, required this.gymId}) : super(key: key);

  @override
  State<SurveyOverviewScreen> createState() => _SurveyOverviewScreenState();
}

class _SurveyOverviewScreenState extends State<SurveyOverviewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SurveyProvider>().listen(widget.gymId);
    });
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    context.read<SurveyProvider>().cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surveyProv = context.watch<SurveyProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Umfragen'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Offen'),
            Tab(text: 'Abgeschlossen'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(context, surveyProv.openSurveys, open: true),
          _buildList(context, surveyProv.closedSurveys, open: false),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, List<Survey> surveys, {required bool open}) {
    if (surveys.isEmpty) {
      return const Center(child: Text('Keine Umfragen'));
    }
    return ListView.builder(
      itemCount: surveys.length,
      itemBuilder: (_, index) {
        final survey = surveys[index];
        return ListTile(
          title: Text(survey.title),
          subtitle: Text(DateFormat.yMd().add_Hm().format(survey.createdAt)),
          trailing: open ? const Icon(Icons.arrow_forward_ios) : null,
          onTap: open
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SurveyDetailScreen(
                          gymId: widget.gymId, survey: survey),
                    ),
                  );
                }
              : null,
        );
      },
    );
  }
}
