import 'package:flutter/foundation.dart';
import 'package:tapem/core/providers/settings_provider.dart';

class FakeSettingsProvider extends ChangeNotifier implements SettingsProvider {
  FakeSettingsProvider({
    bool creatineEnabled = false,
    String? gender,
    double? bodyWeightKg,
  })  : _creatineEnabled = creatineEnabled,
        _gender = gender,
        _bodyWeightKg = bodyWeightKg;

  bool _creatineEnabled;
  String? _gender;
  double? _bodyWeightKg;
  final bool _isLoading = false;
  String? _error;

  @override
  bool get isLoading => _isLoading;

  @override
  String? get error => _error;

  @override
  bool get creatineEnabled => _creatineEnabled;

  @override
  String? get gender => _gender;

  @override
  double? get bodyWeightKg => _bodyWeightKg;

  @override
  Future<void> load(String uid) async {}

  @override
  Future<void> setCreatineEnabled(bool value) async {
    _creatineEnabled = value;
    notifyListeners();
  }

  @override
  Future<void> setGender(String? value) async {
    await updateProfile(gender: value, bodyWeightKg: _bodyWeightKg);
  }

  @override
  Future<void> setBodyWeightKg(double? value) async {
    await updateProfile(gender: _gender, bodyWeightKg: value);
  }

  @override
  Future<void> updateProfile({String? gender, double? bodyWeightKg}) async {
    _gender = gender;
    _bodyWeightKg = bodyWeightKg;
    notifyListeners();
  }
}
