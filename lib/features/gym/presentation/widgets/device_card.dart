// lib/features/gym/presentation/widgets/device_card.dart
import 'package:flutter/material.dart';
import 'package:tapem/features/device/domain/models/device.dart';

class DeviceCard extends StatelessWidget {
  final Device device;
  final VoidCallback? onTap;
  const DeviceCard({
    Key? key,
    required this.device,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(device.name),
        subtitle: device.description.isNotEmpty ? Text(device.description) : null,
        onTap: onTap,
      ),
    );
  }
}
