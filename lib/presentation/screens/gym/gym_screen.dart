// lib/presentation/screens/gym/gym_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tapem/presentation/blocs/gym/gym_bloc.dart';
import 'package:tapem/presentation/blocs/gym/gym_event.dart';
import 'package:tapem/presentation/blocs/gym/gym_state.dart';
import 'package:tapem/presentation/widgets/common/loading_indicator.dart';
import 'package:tapem/domain/usecases/gym/fetch_devices.dart';
import 'package:tapem/domain/repositories/gym_repository.dart';

class GymScreen extends StatelessWidget {
  const GymScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider<GymBloc>(
      create: (ctx) => GymBloc(
        fetchUseCase: ctx.read<FetchGymDevicesUseCase>(),
      )..add(GymFetchDevices()),
      child: const _GymView(),
    );
  }
}

class _GymView extends StatefulWidget {
  const _GymView();

  @override
  State<_GymView> createState() => _GymViewState();
}

class _GymViewState extends State<_GymView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    context
        .read<GymBloc>()
        .add(GymFetchDevices(nameQuery: _searchController.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gym-Geräte'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Gerätename suchen…',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onSubmitted: (_) => _onSearch(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _onSearch,
                ),
              ],
            ),
          ),
        ),
      ),
      body: BlocBuilder<GymBloc, GymState>(
        builder: (ctx, state) {
          if (state is GymLoading) {
            return const Center(child: LoadingIndicator());
          }
          if (state is GymLoadSuccess) {
            final devices = state.devices;
            if (devices.isEmpty) {
              return const Center(child: Text('Keine Geräte gefunden.'));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: devices.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (_, i) {
                final d = devices[i];
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
          }
          if (state is GymFailure) {
            return Center(child: Text('Fehler: ${state.message}'));
          }
          // initial state – keine Action ausgeführt, aber wir feuern beim BlocProvider bereits GymFetchDevices
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
