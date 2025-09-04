import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:tapem/core/logging/elog.dart';
import '../data/creatine_repository.dart';

class CreatineProvider extends ChangeNotifier {
  final CreatineRepository _repo;
  CreatineProvider({required CreatineRepository repository}) : _repo = repository;

  final Set<String> _intakeDates = {};
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  Object? _error;

  Set<String> get intakeDates => _intakeDates;
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;
  Object? get error => _error;

  Future<void> loadIntakeDates(String uid, int year) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _repo.fetchDatesForYear(uid, year);
      _intakeDates
        ..clear()
        ..addAll(data);
    } catch (e) {
      _error = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSelectedDate(DateTime d) {
    _selectedDate = DateTime(d.year, d.month, d.day);
    notifyListeners();
  }

  Future<bool> toggleIntake(String uid, String dateKey) async {
    final exists = _intakeDates.contains(dateKey);
    try {
      if (exists) {
        await _repo.deleteIntake(uid, dateKey);
        _intakeDates.remove(dateKey);
      } else {
        await _repo.setIntake(uid, dateKey);
        _intakeDates.add(dateKey);
      }
      elogUi('creatine_mark', {'dateKey': dateKey, 'mode': exists ? 'delete' : 'create'});
      notifyListeners();
      return !exists;
    } catch (e) {
      _error = e;
      notifyListeners();
      rethrow;
    }
  }

  static String dateKeyFrom(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
}
