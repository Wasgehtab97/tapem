// lib/presentation/screens/profile/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tapem/presentation/blocs/profile/profile_bloc.dart';
import 'package:tapem/presentation/blocs/profile/profile_event.dart';
import 'package:tapem/presentation/blocs/profile/profile_state.dart';
import 'package:tapem/presentation/widgets/common/loading_indicator.dart';
import 'package:tapem/presentation/widgets/profile/feedback_overview.dart';
import 'package:tapem/presentation/widgets/profile/feedback_form.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _didLoad = false;
  bool _showFeedbackForm = false;
  String? _selectedDeviceId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoad) {
      context.read<ProfileBloc>().add(ProfileLoadAll());
      _didLoad = true;
    }
  }

  void _onRespond(String requestId, bool accept) {
    context.read<ProfileBloc>().add(ProfileRespondRequest(requestId, accept));
  }

  void _onSignOut() {
    context.read<ProfileBloc>().add(ProfileSignOut());
  }

  void _openFeedbackForm(String deviceId) {
    setState(() {
      _selectedDeviceId = deviceId;
      _showFeedbackForm = true;
    });
  }

  void _closeFeedbackForm() {
    setState(() {
      _showFeedbackForm = false;
      _selectedDeviceId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _onSignOut),
        ],
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (ctx, state) {
          if (state is ProfileSignedOut) {
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/auth', (route) => false);
          }
        },
        builder: (ctx, state) {
          if (state is ProfileLoading) {
            return const Center(child: LoadingIndicator());
          }

          if (state is ProfileLoadSuccess) {
            final user = state.user;
            final dates = state.trainingDates;
            final pending = state.pendingRequest;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // User-Info
                  Text('Name: ${user.displayName}', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text('Email: ${user.email}'),
                  const SizedBox(height: 8),
                  Text('Beigetreten am: ${user.joinedAt.toLocal().toIso8601String().split("T").first}'),
                  const Divider(height: 32),

                  // Trainingstermine
                  Text('Trainingstermine:', style: Theme.of(context).textTheme.titleMedium),
                  if (dates.isEmpty)
                    const Text('Keine Termine vorhanden.')
                  else
                    ...dates.map((d) => Text('• $d')).toList(),
                  const Divider(height: 32),

                  // Ausstehende Coaching-Anfrage
                  if (pending != null) ...[
                    Text('Offene Anfrage:', style: Theme.of(context).textTheme.titleMedium),
                    Text('• ${pending['type'] ?? 'Coaching'} angefragt am ${pending['createdAt']?.toString() ?? ''}'),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () => _onRespond(pending['id'] as String, true),
                          child: const Text('Akzeptieren'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _onRespond(pending['id'] as String, false),
                          child: const Text('Ablehnen'),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                  ],

                  // Feedback-Übersicht & Formular
                  const Text('Feedback zum Gerät:', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  // Hier Device-IDs dynamisch auswählen – als Beispiel ein Button:
                  ElevatedButton(
                    onPressed: () => _openFeedbackForm('DEVICE_ID_HIER'),
                    child: const Text('Feedback abgeben'),
                  ),
                  const SizedBox(height: 16),
                  if (_showFeedbackForm && _selectedDeviceId != null)
                    FeedbackForm(
                      deviceId: _selectedDeviceId!,
                      onClose: _closeFeedbackForm,
                    ),
                  const SizedBox(height: 16),
                  if (!_showFeedbackForm && _selectedDeviceId != null)
                    FeedbackOverview(deviceId: _selectedDeviceId!),
                ],
              ),
            );
          }

          if (state is ProfileFailure) {
            return Center(child: Text('Fehler: ${state.message}'));
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
