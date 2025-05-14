// lib/presentation/screens/coach/coach_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tapem/presentation/blocs/coach/coach_bloc.dart';
import 'package:tapem/presentation/blocs/coach/coach_event.dart';
import 'package:tapem/presentation/blocs/coach/coach_state.dart';

import 'package:tapem/domain/repositories/coach_repository.dart';
import 'package:tapem/domain/usecases/coach/load_clients.dart';
import 'package:tapem/domain/usecases/coach/fetch_training_dates.dart';
import 'package:tapem/domain/usecases/coach/send_request.dart';
import 'package:tapem/domain/repositories/auth_repository.dart';

import 'package:tapem/presentation/widgets/common/loading_indicator.dart';
import 'package:tapem/presentation/widgets/training_plan/full_screen_calendar.dart';

/// Coach-Dashboard: Übersicht über Klienten mit Optionen.
class CoachDashboardScreen extends StatelessWidget {
  const CoachDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Hole die aktuelle User/Coach-ID aus dem AuthRepository
    final coachId = context.read<AuthRepository>().currentUserId;
    if (coachId == null) {
      // Falls nicht eingeloggt, zurück zur Auth
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/auth');
      });
      return const Scaffold(body: Center(child: LoadingIndicator()));
    }

    return BlocProvider<CoachBloc>(
      create: (ctx) => CoachBloc(
        loadClients:  LoadClientsUseCase(ctx.read<CoachRepository>()),
        fetchDates:   FetchTrainingDatesUseCase(ctx.read<CoachRepository>()),
        sendRequest:  SendCoachingRequestUseCase(ctx.read<CoachRepository>()),
      )..add(CoachLoadClients(coachId)),
      child: const _CoachView(),
    );
  }
}

class _CoachView extends StatelessWidget {
  const _CoachView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Coach Dashboard')),
      body: BlocBuilder<CoachBloc, CoachState>(
        builder: (ctx, state) {
          if (state is CoachLoading) {
            return const Center(child: LoadingIndicator());
          }

          if (state is CoachClientsLoadSuccess) {
            final clients = state.clients;
            if (clients.isEmpty) {
              return const Center(child: Text('Keine Klienten gefunden.'));
            }
            return GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: clients.length,
              itemBuilder: (_, i) {
                final client = clients[i];
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _showOptions(context, client.id),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        client.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                );
              },
            );
          }

          if (state is CoachFailure) {
            return Center(child: Text('Fehler: ${state.message}'));
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Beispiel: neue Coaching-Anfrage (membershipNumber müsst ihr noch erfragen)
          final coachId = context.read<AuthRepository>().currentUserId!;
          context
              .read<CoachBloc>()
              .add(CoachSendRequest(coachId: coachId, membershipNumber: ''));
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Klient anfragen'),
      ),
    );
  }

  void _showOptions(BuildContext ctx, String clientId) {
    showModalBottomSheet(
      context: ctx,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Wrap(children: [
        ListTile(
          leading: const Icon(Icons.history),
          title: const Text('Historie'),
          onTap: () {
            // lade und zeige Trainingsdaten
            ctx.read<CoachBloc>().add(CoachFetchTrainingDates(clientId));
            Navigator.pop(ctx);
            Navigator.push(
              ctx,
              MaterialPageRoute(
                builder: (_) => FullScreenCalendar(
                  trainingDates:
                      (ctx.read<CoachBloc>().state as CoachDatesLoadSuccess)
                          .dates,
                ),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.edit),
          title: const Text('Plan bearbeiten'),
          onTap: () {
            Navigator.pop(ctx);
            Navigator.pushNamed(
              ctx,
              '/trainingsplan',
              arguments: {'clientId': clientId},
            );
          },
        ),
      ]),
    );
  }
}
