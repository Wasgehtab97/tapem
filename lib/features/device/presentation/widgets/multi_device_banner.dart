import 'package:flutter/material.dart';
import 'package:tapem/l10n/app_localizations.dart';

class MultiDeviceBanner extends StatefulWidget {
  const MultiDeviceBanner({super.key});

  @override
  State<MultiDeviceBanner> createState() => _MultiDeviceBannerState();
}

class _MultiDeviceBannerState extends State<MultiDeviceBanner> {
  bool _visible = true;

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    final loc = AppLocalizations.of(context)!;
    return MaterialBanner(
      content: Text(loc.multiDeviceBannerText),
      leading: const Icon(Icons.info_outline),
      actions: [
        TextButton(
          onPressed: () => setState(() => _visible = false),
          child: Text(loc.multiDeviceBannerOk),
        ),
      ],
    );
  }
}
