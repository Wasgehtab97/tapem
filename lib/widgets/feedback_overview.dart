// lib/widgets/feedback_overview.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/tenant/tenant_service.dart';

class FeedbackOverview extends StatelessWidget {
  final int deviceId;
  const FeedbackOverview({Key? key, required this.deviceId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gymId = TenantService().gymId;
    if (gymId == null) {
      return Center(child: Text('Studio nicht ausgewählt.'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('gyms')
          .doc(gymId)
          .collection('feedback')
          .where('deviceId', isEqualTo: deviceId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Text(
              'Kein Feedback vorhanden.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.secondary),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final id = docs[index].id;
            final status = data['status'] as String? ?? 'neu';
            final ts =
                (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
            final formattedDate =
                '${ts.day.toString().padLeft(2, '0')}.${ts.month.toString().padLeft(2, '0')}.${ts.year}';

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                title: Text(
                  data['text'] ?? '',
                  style:
                      theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary),
                ),
                subtitle: Text(
                  'Status: $status • $formattedDate',
                  style:
                      theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
                ),
                trailing: status != 'erledigt'
                    ? IconButton(
                        icon: Icon(Icons.check, color: theme.colorScheme.primary),
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('gyms')
                              .doc(gymId)
                              .collection('feedback')
                              .doc(id)
                              .update({'status': 'erledigt'});
                        },
                      )
                    : null,
              ),
            );
          },
        );
      },
    );
  }
}
