// lib/features/gym/presentation/widgets/device_card.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:tapem/features/device/domain/models/device.dart';
import 'package:tapem/core/utils/context_extensions.dart';
import 'package:tapem/core/theme/design_tokens.dart';

class DeviceCard extends StatefulWidget {
  final Device device;
  final VoidCallback? onTap;
  const DeviceCard({
    Key? key,
    required this.device,
    this.onTap,
  }) : super(key: key);

  @override
  State<DeviceCard> createState() => _DeviceCardState();
}

class _DeviceCardState extends State<DeviceCard> {
  double _scale = 1;

  void _onTapDown(TapDownDetails d) => setState(() => _scale = 0.97);
  void _onTapEnd([_]) => setState(() => _scale = 1);

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final device = widget.device;
    final initial = device.name.isNotEmpty ? device.name[0].toUpperCase() : '?';
    final subtitle = device.description;
    return Hero(
      tag: 'device-${device.uid}',
      child: AnimatedScale(
        duration: AppDurations.short,
        scale: _scale,
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.card),
            onTap: widget.onTap,
            onTapDown: _onTapDown,
            onTapCancel: _onTapEnd,
            onTapUp: _onTapEnd,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.transparent,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppGradients.primary,
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    device.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

