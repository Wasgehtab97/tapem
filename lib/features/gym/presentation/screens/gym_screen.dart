// lib/features/gym/presentation/screens/gym_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/gym_provider.dart';
import 'package:tapem/features/gym/presentation/widgets/device_card.dart';
import 'package:tapem/features/device/domain/models/device.dart';

class GymScreen extends StatefulWidget {
  const GymScreen({Key? key}) : super(key: key);

  @override
  State<GymScreen> createState() => _GymScreenState();
}

class _GymScreenState extends State<GymScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProv = context.read<AuthProvider>();
      final gymProv  = context.read<GymProvider>();
      final gymCode  = authProv.gymCode;
      if (gymCode != null && gymCode.isNotEmpty) {
        gymProv.loadGymData(gymCode);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc    = AppLocalizations.of(context)!;
    final gymProv = context.watch<GymProvider>();

    final appBar = AppBar(title: Text(loc.gymTitle));

    if (gymProv.isLoading) {
      return Scaffold(
        appBar: appBar,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (gymProv.error != null) {
      return Scaffold(
        appBar: appBar,
        body: Center(child: Text('${loc.errorPrefix}: ${gymProv.error}')),
      );
    }

    final devices = gymProv.devices;
    if (devices.isEmpty) {
      return Scaffold(
        appBar: appBar,
        body: Center(child: Text(loc.gymNoDevices)),
      );
    }

    return Scaffold(
      appBar: appBar,
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        itemCount: devices.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final Device device = devices[index];
          return DeviceCard(
            device: device,
            onTap: () => Navigator.of(context).pushNamed(
              AppRouter.device,
              arguments: device.id,
            ),
          );
        },
      ),
    );
  }
}
