import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/core/widgets/admin_access_guard.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:tapem/features/home/presentation/screens/owner_screen.dart';
import 'package:tapem/features/report/presentation/screens/report_screen_new.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/ui/numeric_keypad/overlay_numeric_keypad.dart';

class _OwnerOverlayCloseObserver extends NavigatorObserver {
  _OwnerOverlayCloseObserver(this.controller);

  final OverlayNumericKeypadController controller;

  void _close() {
    controller.close();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _close();
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _close();
    super.didPop(route, previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _close();
    super.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _close();
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}

class OwnerTabNavigator extends ConsumerWidget {
  const OwnerTabNavigator({super.key, this.navigatorKey});

  static const String ownerHome = '/owner';
  static const String ownerReport = '/owner/report';
  static const String ownerAdmin = '/owner/admin';

  final GlobalKey<NavigatorState>? navigatorKey;

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case ownerReport:
        return MaterialPageRoute(builder: (_) => const _OwnerReportPage());
      case ownerAdmin:
        return MaterialPageRoute(
          builder: (_) => const AdminAccessGuard(child: AdminDashboardScreen()),
        );
      case ownerHome:
      default:
        return MaterialPageRoute(
          builder: (context) => OwnerScreen(
            onOpenReport: () => Navigator.of(context).pushNamed(ownerReport),
            onOpenAdmin: () => Navigator.of(context).pushNamed(ownerAdmin),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keypad = ref.watch(overlayNumericKeypadControllerProvider);
    return Navigator(
      key: navigatorKey,
      onGenerateInitialRoutes: (_, __) => <Route<dynamic>>[
        _onGenerateRoute(const RouteSettings(name: ownerHome)),
      ],
      onGenerateRoute: _onGenerateRoute,
      observers: [_OwnerOverlayCloseObserver(keypad)],
    );
  }
}

class _OwnerReportPage extends ConsumerWidget {
  const _OwnerReportPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final auth = ref.watch(authControllerProvider);
    return ReportScreenNew(
      gymId: auth.gymCode ?? '',
      appBar: AppBar(
        title: Text(loc.reportTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
    );
  }
}
