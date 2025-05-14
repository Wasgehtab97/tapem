// lib/presentation/screens/dashboard/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tapem/presentation/blocs/dashboard/dashboard_bloc.dart';
import 'package:tapem/presentation/widgets/common/loading_indicator.dart';
import 'package:tapem/presentation/widgets/dashboard/input_table.dart';
import 'package:tapem/presentation/widgets/dashboard/finish_and_next_buttons.dart';
import 'package:tapem/presentation/widgets/dashboard/last_session_card.dart';

import 'package:tapem/domain/usecases/dashboard/load_device.dart';
import 'package:tapem/domain/usecases/dashboard/add_set.dart';
import 'package:tapem/domain/usecases/dashboard/finish_session.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

    final deviceId = args?['deviceId'] as String? ?? '';
    final secretCode = args?['secretCode'] as String?;

    return BlocProvider(
      create: (ctx) => DashboardBloc(
        loadDevice: ctx.read<LoadDeviceUseCase>(),
        addSet: ctx.read<AddSetUseCase>(),
        finishSession: ctx.read<FinishSessionUseCase>(),
      )..add(DashboardLoad(deviceId: deviceId, secretCode: secretCode)),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (ctx, state) {
          if (state is DashboardLoading) {
            return const Center(child: LoadingIndicator());
          }

          if (state is DashboardLoadSuccess) {
            final data = state.data;
            final code = state.secretCode;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    data.device.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),

                  InputTable(
                    entries: data.entries,
                    onAddSet: (exercise, sets, weight, reps) {
                      context.read<DashboardBloc>().add(
                            DashboardAddSet(
                              deviceId: data.device.id,
                              secretCode: code,
                              exercise: exercise,
                              sets: sets,
                              weight: weight,
                              reps: reps,
                            ),
                          );
                    },
                  ),
                  const SizedBox(height: 16),

                  FinishAndNextButtons(
                    onFinish: () {
                      final last = data.entries.isNotEmpty
                          ? data.entries.last.exercise
                          : '';
                      context.read<DashboardBloc>().add(
                            DashboardFinish(
                              deviceId: data.device.id,
                              secretCode: code,
                              exercise: last,
                            ),
                          );
                    },
                    onNext: () {},
                    isFinishDisabled: data.entries.isEmpty,
                  ),
                  const SizedBox(height: 24),
                  const LastSessionCard(),
                ],
              ),
            );
          }

          if (state is DashboardFailure) {
            return Center(child: Text('Fehler: ${state.message}'));
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
