import 'package:flutter/material.dart';

import '../theme/app_brand_theme.dart';

/// Vollflächiger Lade-Indikator im Tapem-Stil.
class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>();
    final color = brand?.outline ?? theme.colorScheme.secondary;

    return Center(
      child: CircularProgressIndicator(
        color: color,
        strokeWidth: 3,
      ),
    );
  }
}

