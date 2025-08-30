// lib/features/gym/presentation/widgets/device_card.dart
import 'package:flutter/material.dart';
import 'package:tapem/features/device/domain/models/device.dart';
import 'package:tapem/core/utils/context_extensions.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/brand_outline.dart';
import 'package:tapem/core/theme/brand_on_colors.dart';

class DeviceCard extends StatefulWidget {
  final Device device;
  final VoidCallback? onTap;
  const DeviceCard({Key? key, required this.device, this.onTap})
    : super(key: key);

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
    final idText = device.id > 0 ? device.id.toString() : '–';
    final onBrand = Theme.of(context).extension<BrandOnColors>()?.onGradient ?? Colors.black;
    return Hero(
      tag: 'device-${device.uid}',
      child: AnimatedScale(
        duration: AppDurations.short,
        scale: _scale,
        child: GestureDetector(
          onTapDown: _onTapDown,
          onTapCancel: _onTapEnd,
          onTapUp: _onTapEnd,
          child: BrandOutline(
            onTap: widget.onTap,
            child: SizedBox(
              height: 140,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.transparent,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppGradients.brandGradient,
                        ),
                        child: Center(
                          child: Text(
                            initial,
                            style: theme.textTheme.titleLarge?.copyWith(color: onBrand),
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
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'ID: $idText',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
