import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tapem/domain/models/gym_config.dart';
import 'package:tapem/domain/repositories/tenant_repository.dart';
import 'package:tapem/presentation/widgets/common/loading_indicator.dart';

/// Lädt das gym-spezifische Logo in folgender Reihenfolge:
/// 1. Remote via URL (mit Caching und Lade-Spinner)
/// 2. Lokal aus assets/logos/`gymId`.png
/// 3. Fallback auf Default-Asset assets/images/logo.png
class GymLogo extends StatelessWidget {
  final double height;

  const GymLogo({Key? key, this.height = 40}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const defaultAsset = 'assets/images/logo.png';
    final repo = context.read<TenantRepository>();
    final config = repo.config;
    final gymId = repo.gymId;

    // 1) Remote-Logo, wenn konfiguriert
    if (config != null && config.logoUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: config.logoUrl,
        height: height,
        fit: BoxFit.contain,
        placeholder: (_, __) => SizedBox(
          height: height,
          child: const LoadingIndicator(),
        ),
        errorWidget: (_, __, ___) =>
            Image.asset(defaultAsset, height: height, fit: BoxFit.contain),
      );
    }

    // 2) Lokales Asset pro gymId
    if (gymId != null && gymId.isNotEmpty) {
      return Image.asset(
        'assets/logos/$gymId.png',
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            Image.asset(defaultAsset, height: height, fit: BoxFit.contain),
      );
    }

    // 3) Fallback
    return Image.asset(
      defaultAsset,
      height: height,
      fit: BoxFit.contain,
    );
  }
}
