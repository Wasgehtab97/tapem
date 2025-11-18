import 'package:flutter/foundation.dart';

import 'auth_provider.dart';

class GymContextStateAdapter extends ChangeNotifier implements GymContextState {
  GymContextStatus _status = GymContextStatus.unknown;
  String? _gymCode;

  @override
  GymContextStatus get gymContextStatus => _status;

  @override
  String? get gymCode => _gymCode;

  void updateFrom(GymContextState state) {
    final nextStatus = state.gymContextStatus;
    final nextCode = state.gymCode;

    if (_status == nextStatus && _gymCode == nextCode) {
      return;
    }

    _status = nextStatus;
    _gymCode = nextCode;
    notifyListeners();
  }
}
