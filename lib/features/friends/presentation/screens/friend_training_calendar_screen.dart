import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/features/profile/presentation/widgets/calendar.dart';
import 'package:tapem/features/profile/presentation/widgets/calendar_popup.dart';
import 'package:tapem/l10n/app_localizations.dart';

import '../../providers/friends_riverpod.dart';

class FriendTrainingCalendarScreen extends ConsumerStatefulWidget {
  final String friendUid;
  final String friendName;
  const FriendTrainingCalendarScreen({
    Key? key,
    required this.friendUid,
    required this.friendName,
  }) : super(key: key);

  @override
  ConsumerState<FriendTrainingCalendarScreen> createState() =>
      _FriendTrainingCalendarScreenState();
}

class _FriendTrainingCalendarScreenState
    extends ConsumerState<FriendTrainingCalendarScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(friendCalendarProvider.notifier).setActiveFriend(widget.friendUid);
    });
  }

  void _openCalendarPopup(
    List<String> trainingDates,
    Map<String, String> gymIdsByDate,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CalendarPopup(
        trainingDates: trainingDates,
        initialYear: DateTime.now().year,
        userId: widget.friendUid,
        gymIdsByDate: gymIdsByDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(friendCalendarProvider);
    final dates = state.trainingDates;
    final gymIdsByDate = state.gymIdsByDate;
    final loc = AppLocalizations.of(context)!;

    Widget body;
    if (state.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (state.error != null) {
      body = Center(child: Text(loc.friends_privacy_no_access));
    } else {
      body = Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.friends_action_training_days,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _openCalendarPopup(dates, gymIdsByDate),
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
