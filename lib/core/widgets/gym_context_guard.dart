import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/gym_context_state_adapter.dart';

class GymContextGuard extends ConsumerStatefulWidget {
  const GymContextGuard({super.key, required this.child, this.loadingFallback});

  final Widget child;
  final Widget? loadingFallback;

  @override
  ConsumerState<GymContextGuard> createState() => _GymContextGuardState();
}

class _GymContextGuardState extends ConsumerState<GymContextGuard> {
  bool _redirectScheduled = false;

  @override
  Widget build(BuildContext context) {
    final gymContext = ref.watch(gymContextStateAdapterProvider);
    final status = gymContext.gymContextStatus;
    _maybeRedirect(status);

    if (status == GymContextStatus.ready && gymContext.gymCode != null) {
      _redirectScheduled = false;
      return widget.child;
    }

    return widget.loadingFallback ?? const _GymGuardLoading();
  }

  void _maybeRedirect(GymContextStatus status) {
    if (status != GymContextStatus.missingSelection) {
      return;
    }
    if (_redirectScheduled) {
      return;
    }
    _redirectScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRouter.selectGym,
        (route) => false,
      );
    });
  }
}

class _GymGuardLoading extends StatelessWidget {
  const _GymGuardLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
