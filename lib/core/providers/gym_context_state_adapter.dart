import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';
import 'auth_providers.dart';

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

final gymContextStateAdapterProvider =
    ChangeNotifierProvider<GymContextStateAdapter>((ref) {
  final adapter = GymContextStateAdapter();
  void update(AuthViewState state) {
    adapter.updateFrom(state);
  }

  ref.onDispose(adapter.dispose);
  update(ref.read(authViewStateProvider));
  ref.listen<AuthViewState>(
    authViewStateProvider,
    (_, next) => update(next),
  );
  return adapter;
});
