import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  static bool disableForTests = false;

  @override
  Widget build(BuildContext context) {
    if (disableForTests) {
      return const SizedBox.shrink();
    }
    final stream = _safeConnectivityStream();
    if (stream == null) {
      return const SizedBox.shrink();
    }
    return StreamBuilder<List<ConnectivityResult>>(
      stream: stream.handleError((_) {}),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }
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

  Stream<List<ConnectivityResult>>? _safeConnectivityStream() {
    try {
      return Connectivity().onConnectivityChanged;
    } on MissingPluginException {
      return null;
    } catch (_) {
      return null;
    }
  }
}
