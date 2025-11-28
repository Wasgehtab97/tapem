import 'package:flutter/material.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';

class PlanOverviewScreen extends StatelessWidget {
  const PlanOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Trainingspläne',
          style: TextStyle(color: brandColor),
        ),
        foregroundColor: brandColor,
      ),
      body: Center(
        child: Text(
          'Coming Soon',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: brandColor,
          ),
        ),
      ),
    );
  }
}
