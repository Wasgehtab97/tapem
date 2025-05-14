// lib/presentation/widgets/profile/feedback_overview.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tapem/domain/repositories/tenant_repository.dart';

/// Zeigt alle Feedback-Einträge zu einem Gerät an.
class FeedbackOverview extends StatelessWidget {
  final String deviceId;
  const FeedbackOverview({Key? key, required this.deviceId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TenantRepository muss in main.dart als Provider/RegisterBlocProvider verfügbar sein
    final tenantRepo = context.read<TenantRepository>();
    final gymId = tenantRepo.gymId;
    if (gymId == null || gymId.isEmpty) {
      return const Center(child: Text('Kein Gym ausgewählt'));
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('gyms')
          .doc(gymId)
          .collection('devices')
          .doc(deviceId)
          .collection('feedback')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Fehler: ${snap.error}'));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('Kein Feedback vorhanden.'));
        }
        return ListView.builder(
          shrinkWrap: true,
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data();
            final text = data['text'] as String? ?? '';
            final ts = data['createdAt'] as Timestamp?;
            final date = ts != null
                ? ts.toDate().toLocal().toString().split('.')[0]
                : 'Unbekannt';
            return ListTile(
              title: Text(text),
              subtitle: Text(date, style: const TextStyle(fontSize: 12)),
            );
          },
        );
      },
    );
  }
}
