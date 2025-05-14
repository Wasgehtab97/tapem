// lib/presentation/screens/admin/admin_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tapem/presentation/blocs/admin/admin_bloc.dart';
import 'package:tapem/presentation/blocs/admin/admin_event.dart';
import 'package:tapem/presentation/blocs/admin/admin_state.dart';

import 'package:tapem/domain/repositories/admin_repository.dart';
import 'package:tapem/domain/usecases/admin/fetch_devices.dart';
import 'package:tapem/domain/usecases/admin/create_device.dart';
import 'package:tapem/domain/usecases/admin/update_device.dart';

import 'package:tapem/presentation/widgets/common/loading_indicator.dart';

import 'package:tapem/domain/models/device_model.dart';

/// Admin-Dashboard: Liste aller Geräte mit CRUD-Optionen.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AdminBloc>(
      create: (ctx) => AdminBloc(
        fetchDevices: FetchDevicesUseCase(ctx.read<AdminRepository>()),
        createDevice: CreateDeviceUseCase(ctx.read<AdminRepository>()),
        updateDevice: UpdateDeviceUseCase(ctx.read<AdminRepository>()),
      )..add(AdminFetchDevices()),
      child: const _AdminView(),
    );
  }
}

class _AdminView extends StatelessWidget {
  const _AdminView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: BlocBuilder<AdminBloc, AdminState>(
        builder: (ctx, state) {
          if (state is AdminLoading) {
            return const Center(child: LoadingIndicator());
          }

          if (state is AdminLoadSuccess) {
            final devices = state.devices;
            return ListView.builder(
              itemCount: devices.length,
              itemBuilder: (_, i) {
                final d = devices[i];
                return ListTile(
                  title: Text(d.name),
                  subtitle: Text('Mode: ${d.exerciseMode} • #${d.documentId}'),
                  onTap: () {
                    // Beispiel: Update-Dialog oder Navigation
                    context.read<AdminBloc>().add(
                      AdminUpdateDevice(
                        documentId: d.documentId,
                        name: d.name,
                        exerciseMode: d.exerciseMode,
                        secretCode: d.secretCode,
                      ),
                    );
                  },
                );
              },
            );
          }

          if (state is AdminFailure) {
            return Center(child: Text('Fehler: ${state.error}'));
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Beispiel: Create-Dialog oder stub
          context.read<AdminBloc>().add(
            AdminCreateDevice(name: 'Neues Gerät', exerciseMode: 'Standard'),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
