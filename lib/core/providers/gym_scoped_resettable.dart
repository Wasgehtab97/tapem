import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class GymScopedResettable {
  void resetGymScopedState();
}

class GymScopedStateController extends ChangeNotifier {
  final Set<GymScopedResettable> _registrations = <GymScopedResettable>{};

  void register(GymScopedResettable resettable) {
    _registrations.add(resettable);
  }

  void unregister(GymScopedResettable resettable) {
    _registrations.remove(resettable);
  }

  void resetGymScopedState() {
    final listeners = List<GymScopedResettable>.from(_registrations);
    for (final listener in listeners) {
      listener.resetGymScopedState();
    }
  }
}

final gymScopedStateControllerProvider =
    ChangeNotifierProvider<GymScopedStateController>((ref) {
  final controller = GymScopedStateController();
  return controller;
});

mixin GymScopedResettableChangeNotifier on ChangeNotifier
    implements GymScopedResettable {
  GymScopedStateController? _gymScopedStateController;

  void registerGymScopedResettable(GymScopedStateController controller) {
    if (!identical(_gymScopedStateController, controller)) {
      _gymScopedStateController?.unregister(this);
      _gymScopedStateController = controller;
      controller.register(this);
    }
  }

  @mustCallSuper
  void disposeGymScopedRegistration() {
    _gymScopedStateController?.unregister(this);
    _gymScopedStateController = null;
  }
}
