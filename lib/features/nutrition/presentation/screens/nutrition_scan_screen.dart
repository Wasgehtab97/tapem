import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/l10n/app_localizations.dart';

class NutritionScanScreen extends StatefulWidget {
  const NutritionScanScreen({super.key});

  @override
  State<NutritionScanScreen> createState() => _NutritionScanScreenState();
}

class _NutritionScanScreenState extends State<NutritionScanScreen> {
  bool _hasScanned = false;

  void _handleDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    final barcode = capture.barcodes
        .map((b) => b.rawValue)
        .firstWhere((v) => v != null && v!.isNotEmpty, orElse: () => null);
    if (barcode == null) return;
    _hasScanned = true;
    Navigator.of(context).pushReplacementNamed(
      AppRouter.nutritionProduct,
      arguments: {'barcode': barcode},
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.nutritionScanTitle),
      ),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              onDetect: _handleDetect,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              children: [
                Text(
                  loc.nutritionScanHint,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pushNamed(
                    AppRouter.nutritionEntry,
                  ),
                  child: Text(loc.nutritionScanManualCta),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
