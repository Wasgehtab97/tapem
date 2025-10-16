import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/features/friends/providers/friend_calendar_provider.dart';
import 'package:tapem/features/profile/presentation/widgets/calendar.dart';
import 'package:tapem/features/profile/presentation/widgets/calendar_popup.dart';
import 'package:tapem/l10n/app_localizations.dart';

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

class _FriendTrainingCalendarScreenState
    extends State<FriendTrainingCalendarScreen> {
  bool _requestedInitial = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requestedInitial) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _requestedInitial) {
        return;
      }
      final route = ModalRoute.of(context);
      if (route != null && !route.isCurrent) {
        return;
      }
      final provider = context.read<FriendCalendarProvider>();
      provider.setActiveFriend(widget.friendUid);
      unawaited(provider.loadInitialRange());
      _requestedInitial = true;
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
    final loc = AppLocalizations.of(context)!;

    Widget body;
    if (prov.isLoading && !prov.hasLoaded) {
      body = const Center(child: CircularProgressIndicator());
    } else if (prov.error != null) {
      body = Center(child: Text(loc.friends_privacy_no_access));
    } else {
      final content = <Widget>[
        Text(
          loc.friends_action_training_days,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 360,
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
        if (prov.hasMore)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: OutlinedButton.icon(
              onPressed: prov.isLoading ? null : prov.loadMore,
              icon: const Icon(Icons.unfold_more),
              label: Text(loc.friends_calendar_load_more_days),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: TextButton.icon(
            onPressed: prov.isLoading ? null : prov.refresh,
            icon: const Icon(Icons.refresh),
            label: Text(loc.friends_calendar_refresh),
          ),
        ),
        if (prov.isLoading)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
      ];

      if (!prov.hasLoaded) {
        content.insert(
          0,
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              loc.friends_calendar_initial_hint,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        );
      }

      body = RefreshIndicator(
        onRefresh: () => prov.refresh(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: content,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.friendName)),
      body: body,
    );
  }
}
