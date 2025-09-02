// lib/core/providers/profile_provider.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/auth_provider.dart';

class ProfileProvider extends ChangeNotifier {
  ProfileProvider();

  bool _isLoading = false;
  String? _error;
  List<String> _trainingDates = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<String> get trainingDates => List.unmodifiable(_trainingDates);

  /// Lädt alle Trainingstage (YYYY-MM-DD) des aktuellen Users.
  Future<void> loadTrainingDates(BuildContext context) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final authProv = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProv.userId;

      if (userId == null) {
        throw Exception('Kein Benutzer gefunden');
      }

      final snapshot = await FirebaseFirestore.instance
          .collectionGroup('logs')
          .where('userId', isEqualTo: userId)
          .select(['timestamp'])
          .get();

      final datesSet = <String>{};
      for (final doc in snapshot.docs) {
        final dt = (doc['timestamp'] as Timestamp).toDate();
        final key =
            '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
        datesSet.add(key);
      }

      _trainingDates = datesSet.toList()..sort();
    } catch (e, st) {
      _error = 'Fehler beim Laden der Trainingstage: ${e.toString()}';
      debugPrintStack(
        label: 'ProfileProvider.loadTrainingDates',
        stackTrace: st,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
