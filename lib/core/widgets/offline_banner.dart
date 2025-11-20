import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ConnectivityResult>>(
      stream: Connectivity().onConnectivityChanged,
      builder: (context, snapshot) {
        final results = snapshot.data;
        final isOffline = results != null && results.every((r) => r == ConnectivityResult.none);

        if (!isOffline) return const SizedBox.shrink();

        return Container(
          color: Colors.red,
          padding: const EdgeInsets.all(4),
          width: double.infinity,
          child: const Text(
            'Offline Mode',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        );
      },
    );
  }
}
