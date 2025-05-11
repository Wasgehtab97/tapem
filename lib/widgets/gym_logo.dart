import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/tenant/tenant_service.dart';
import '../core/models/domain/gym_config.dart';

/// Lädt das gym-spezifische Logo in folgender Reihenfolge:
/// 1) Remote via URL (mit Caching und Lade-Spinner)
/// 2) Lokal aus assets/logos/<gymId>.png
/// 3) Fallback auf Default-Asset assets/images/logo.png
class GymLogo extends StatelessWidget {
  /// Höhe des Logos in Pixeln.
  final double height;

  const GymLogo({Key? key, this.height = 40}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tenant = TenantService();
    final GymConfig? cfg = tenant.config;
    final String? gymId = tenant.gymId;
    const String defaultAsset = 'assets/images/logo.png';

    // 1) Versuche Remote-Logo (logoUrl aus GymConfig)
    if (cfg != null && cfg.logoUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: cfg.logoUrl,
        height: height,
        fit: BoxFit.contain,
        // Während des Ladens Spinner anzeigen
        placeholder: (ctx, url) => SizedBox(
          height: height,
          child: const Center(child: CircularProgressIndicator()),
        ),
        // Bei Fehlern auf lokales Default-Asset zurückfallen
        errorWidget: (ctx, url, error) =>
            Image.asset(defaultAsset, height: height, fit: BoxFit.contain),
      );
    }

    // 2) Versuche lokales Gym-spezifisches Asset
    if (gymId != null && gymId.isNotEmpty) {
      return Image.asset(
        'assets/logos/$gymId.png',
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (ctx, error, stack) =>
            Image.asset(defaultAsset, height: height, fit: BoxFit.contain),
      );
    }

    // 3) Fallback auf generisches Default-Logo
    return Image.asset(
      defaultAsset,
      height: height,
      fit: BoxFit.contain,
    );
  }
}
