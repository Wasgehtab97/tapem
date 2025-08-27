import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/month_calendar.dart';

class PublicCalendarSource {
  PublicCalendarSource(this._firestore);
  final FirebaseFirestore _firestore;

  Stream<MonthCalendar> watchMonth(String uid, String yyyyMM) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('publicCalendar')
        .doc(yyyyMM)
        .snapshots()
        .map((doc) {
      final data = doc.data();
      final Map<int, DayInfo> days = {};
      if (data != null) {
        data.forEach((key, value) {
          final day = int.tryParse(key);
          if (day != null && value is Map<String, dynamic>) {
            days[day] = DayInfo(
              trained: value['trained'] == true,
              sessions: (value['sessions'] as int?) ?? 0,
            );
          }
        });
      }
      return MonthCalendar(yyyyMM: yyyyMM, days: days);
    });
  }
}
