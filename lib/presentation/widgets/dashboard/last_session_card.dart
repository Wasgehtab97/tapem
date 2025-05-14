// lib/presentation/widgets/dashboard/last_session_card.dart

import 'package:flutter/material.dart';

class LastSessionCard extends StatelessWidget {
  const LastSessionCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext c) {
    // TODO: Aus Bloc-State mit echten Daten füllen
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Letzte Session: …'), // Platzhalter
      ),
    );
  }
}
