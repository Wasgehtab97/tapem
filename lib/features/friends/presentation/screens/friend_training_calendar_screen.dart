import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/features/friends/providers/friend_calendar_provider.dart';
import 'package:tapem/features/profile/presentation/widgets/calendar.dart';
import 'package:tapem/features/profile/presentation/widgets/calendar_popup.dart';

class FriendTrainingCalendarScreen extends StatefulWidget {
  final String friendUid;
  final String friendName;
  const FriendTrainingCalendarScreen({
    Key? key,
    required this.friendUid,
    required this.friendName,
  }) : super(key: key);

  @override
  State<FriendTrainingCalendarScreen> createState() => _FriendTrainingCalendarScreenState();
}

class _FriendTrainingCalendarScreenState extends State<FriendTrainingCalendarScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FriendCalendarProvider>().setActiveFriend(widget.friendUid);
    });
  }

  void _openCalendarPopup(List<String> trainingDates) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CalendarPopup(
        trainingDates: trainingDates,
        initialYear: DateTime.now().year,
        userId: widget.friendUid,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<FriendCalendarProvider>();
    final dates = prov.trainingDates;

    Widget body;
    if (prov.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (prov.error != null) {
      body = const Center(child: Text('Nur für Freunde sichtbar'));
    } else {
      body = Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trainingstage',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _openCalendarPopup(dates),
                child: Calendar(
                  trainingDates: dates,
                  showNavigation: false,
                  year: DateTime.now().year,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.friendName)),
      body: body,
    );
  }
}
