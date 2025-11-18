import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/gym_context_state_adapter.dart';
import 'package:tapem/core/widgets/gym_context_guard.dart';

class _FakeGymContext extends ChangeNotifier implements GymContextState {
  _FakeGymContext({required GymContextStatus status, String? code})
      : _status = status,
        _code = code;

  GymContextStatus _status;
  String? _code;

  @override
  GymContextStatus get gymContextStatus => _status;

  @override
  String? get gymCode => _code;

  void update({GymContextStatus? status, String? code}) {
    _status = status ?? _status;
    _code = code ?? _code;
    notifyListeners();
  }
}

void main() {
  group('GymContextGuard', () {
    testWidgets('renders child when gym selection is ready', (tester) async {
      final fake = _FakeGymContext(
        status: GymContextStatus.ready,
        code: 'gym-1',
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<_FakeGymContext>.value(
          value: fake,
          child: ChangeNotifierProxyProvider<_FakeGymContext, GymContextStateAdapter>(
            create: (_) => GymContextStateAdapter(),
            update: (_, source, adapter) {
              final resolved = adapter ?? GymContextStateAdapter();
              resolved.updateFrom(source);
              return resolved;
            },
            child: const MaterialApp(
              home: GymContextGuard(
                child: Text('protected'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('protected'), findsOneWidget);
    });

    testWidgets('redirects to selection when no gym is set', (tester) async {
      final fake = _FakeGymContext(status: GymContextStatus.missingSelection);

      await tester.pumpWidget(
        ChangeNotifierProvider<_FakeGymContext>.value(
          value: fake,
          child: ChangeNotifierProxyProvider<_FakeGymContext, GymContextStateAdapter>(
            create: (_) => GymContextStateAdapter(),
            update: (_, source, adapter) {
              final resolved = adapter ?? GymContextStateAdapter();
              resolved.updateFrom(source);
              return resolved;
            },
            child: MaterialApp(
              initialRoute: '/guarded',
              routes: {
                '/guarded': (_) => const GymContextGuard(
                      child: Text('protected'),
                    ),
                AppRouter.selectGym: (_) => const Text('SelectGym'),
              },
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('SelectGym'), findsOneWidget);
    });
  });
}
