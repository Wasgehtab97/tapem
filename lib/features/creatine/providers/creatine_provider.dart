import 'package:flutter/foundation.dart';
import 'package:tapem/core/logging/elog.dart';
import '../data/creatine_repository.dart';

class CreatineProvider extends ChangeNotifier {
  final CreatineRepository _repo;
  CreatineProvider({required CreatineRepository repository}) : _repo = repository;

  final Set<String> _intakeDates = {};
  DateTime _selectedDate = atStartOfLocalDay(nowLocal());
  bool _isLoading = false;
  bool _isToggling = false;
  Object? _error;

  Set<String> get intakeDates => _intakeDates;
  DateTime get selectedDate => _selectedDate;
  String get selectedDateKey => toDateKeyLocal(_selectedDate);
  bool get isLoading => _isLoading;
  bool get busy => _isToggling;
  bool get canToggle => isTodayOrYesterday(_selectedDate);
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
    final day = atStartOfLocalDay(d);
    if (!isTodayOrYesterday(day)) {
      return;
    }
    _selectedDate = day;
    notifyListeners();
  }

  Future<bool> toggleIntake(String uid) async {
    if (!canToggle) {
      throw StateError('Nur heute oder gestern möglich.');
    }
    final dateKey = selectedDateKey;
    final exists = _intakeDates.contains(dateKey);
    _isToggling = true;
    notifyListeners();
    try {
      if (exists) {
        await _repo.deleteIntake(uid, dateKey);
        _intakeDates.remove(dateKey);
      } else {
        await _repo.setIntake(uid, dateKey);
        _intakeDates.add(dateKey);
      }
      elogUi('creatine_mark', {'dateKey': dateKey, 'mode': exists ? 'delete' : 'create'});
      return !exists;
    } catch (e) {
      _error = e;
      rethrow;
    } finally {
      _isToggling = false;
      notifyListeners();
    }
  }
}
