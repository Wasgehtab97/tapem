import 'package:flutter/scheduler.dart';
import 'package:tapem/core/logging/elog.dart';
import 'package:flutter/widgets.dart';

class UiMutationGuard {
  UiMutationGuard._();

  static final Set<String> _logged = <String>{};

  static void run({
    required String screen,
    required String widget,
    required String field,
    required Object? oldValue,
    required Object? newValue,
    required VoidCallback mutate,
    String? reason,
  }) {
    if (oldValue == newValue) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks) {
      final key = '$screen|$widget|$field';
      if (!_logged.contains(key)) {
        _logged.add(key);
        elogUi('VIOLATION_GUARDED', {
          'screen': screen,
          'widget': widget,
          'field': field,
          if (reason != null) 'reason': reason,
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _logged.remove(key);
        });
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        mutate();
      });
    } else {
      mutate();
    }
  }
}
