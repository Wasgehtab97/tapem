import 'package:flutter/foundation.dart';
import '../data/public_calendar_source.dart';
import '../domain/models/month_calendar.dart';

class FriendCalendarProvider extends ChangeNotifier {
  FriendCalendarProvider(this._source);
  final PublicCalendarSource _source;
  String? _activeFriend;

  void setActiveFriend(String uid) {
    _activeFriend = uid;
    notifyListeners();
  }

  Stream<MonthCalendar> monthStream(String yyyyMM) {
    final uid = _activeFriend;
    if (uid == null) {
      return const Stream.empty();
    }
    return _source.watchMonth(uid, yyyyMM);
  }
}
