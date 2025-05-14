// lib/presentation/screens/device/device_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tapem/presentation/blocs/device/device_bloc.dart';
import 'package:tapem/presentation/widgets/common/loading_indicator.dart';

// UseCase-Imports
import 'package:tapem/domain/usecases/device/load_devices.dart';
import 'package:tapem/domain/usecases/device/register_device.dart';
import 'package:tapem/domain/usecases/device/update_device.dart';

/// Device-Übersicht per BLoC.
class DeviceScreen extends StatelessWidget {
  const DeviceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DeviceBloc>(
      create: (ctx) => DeviceBloc(
        loadAll:        ctx.read<LoadDevicesUseCase>(),
        registerUseCase: ctx.read<RegisterDeviceUseCase>(),
        updateUseCase:   ctx.read<UpdateDeviceUseCase>(),
      )..add(DeviceLoadAll()),
      child: const _DeviceView(),
    );
  }
}

class _DeviceView extends StatelessWidget {
  const _DeviceView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Geräte')),
      body: BlocBuilder<DeviceBloc, DeviceState>(
        builder: (ctx, state) {
          if (state is DeviceLoading) {
            return const Center(child: LoadingIndicator());
          } else if (state is DeviceLoaded) {
            return ListView.builder(
              itemCount: state.devices.length,
              itemBuilder: (_, i) {
                final d = state.devices[i];
                return ListTile(
                  title: Text(d.name),
                  subtitle: Text('Mode: ${d.exerciseMode}'),
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/dashboard',
                    arguments: {'deviceId': d.documentId},
                  ),
                );
              },
            );
          } else if (state is DeviceFailure) {
            return Center(child: Text('Fehler: ${state.message}'));
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
