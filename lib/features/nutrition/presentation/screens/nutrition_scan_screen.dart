import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/l10n/app_localizations.dart';

class NutritionScanScreen extends StatefulWidget {
  final String initialMeal;
  final bool returnBarcode;
  const NutritionScanScreen({
    super.key,
    this.initialMeal = 'breakfast',
    this.returnBarcode = false,
  });

  @override
  State<NutritionScanScreen> createState() => _NutritionScanScreenState();
}

class _NutritionScanScreenState extends State<NutritionScanScreen> {
  bool _hasScanned = false;
  String _meal = 'breakfast';

  @override
  void initState() {
    super.initState();
    _meal = widget.initialMeal;
  }

  Future<void> _pickMeal() async {
    final meals = [
      ('breakfast', 'Frühstück'),
      ('lunch', 'Mittagessen'),
      ('dinner', 'Abendessen'),
      ('snack', 'Snack'),
    ];
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              for (final meal in meals)
                ListTile(
                  title: Text(meal.$2),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(ctx).pop(meal.$1),
                ),
            ],
          ),
        );
      },
    );
    if (choice != null && mounted) {
      setState(() => _meal = choice);
    }
  }

  void _handleDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    final barcode = capture.barcodes
        .map((b) => b.rawValue)
        .firstWhere((v) => v != null && v!.isNotEmpty, orElse: () => null);
    if (barcode == null) return;
    _hasScanned = true;
    if (widget.returnBarcode) {
      Navigator.of(context).pop(barcode);
      return;
    }
    Navigator.of(context).pushReplacementNamed(
      AppRouter.nutritionEntry,
      arguments: {
        'barcode': barcode,
        'meal': _meal,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.nutritionScanTitle),
        actions: [
          IconButton(
            tooltip: loc.nutritionAddEntryCta,
            icon: const Icon(Icons.restaurant_menu),
            onPressed: _pickMeal,
          ),
        ],
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
                    arguments: {'meal': _meal},
                  ),
                  child: Text(loc.nutritionScanManualCta),
                ),
                const SizedBox(height: 8),
                Text(
                  'Mahlzeit: $_meal',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
