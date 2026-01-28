import 'package:flutter/material.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/brand_gradient_icon.dart';
import 'package:tapem/core/widgets/brand_gradient_card.dart';
import 'package:tapem/features/nutrition/presentation/widgets/nutrition_ui.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'dart:ui';

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

class _NutritionScanScreenState extends State<NutritionScanScreen>
    with SingleTickerProviderStateMixin {
  bool _hasScanned = false;
  String _meal = 'breakfast';
  late AnimationController _scanLineController;

  @override
  void initState() {
    super.initState();
    _meal = widget.initialMeal;
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    super.dispose();
  }


  void _handleDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    final barcode = capture.barcodes
        .map((b) => b.rawValue)
        .whereType<String>()
        .firstWhere((v) => v.isNotEmpty, orElse: () => '');
    
    if (barcode.isEmpty) return;
    
    setState(() => _hasScanned = true);
    
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
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>();
    final brandColor = brand?.outline ?? theme.colorScheme.secondary;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.nutritionScanTitle),
      ),
      body: Stack(
        children: [
          // Camera scanner
          MobileScanner(
            onDetect: _handleDetect,
          ),
          
          // Animated scanning overlay
          Positioned.fill(
            child: CustomPaint(
              painter: _ScanOverlayPainter(
                animation: _scanLineController,
                brandColor: brandColor,
              ),
            ),
          ),
          
          // Bottom controls with glassmorphism
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.0),
                    Colors.black.withOpacity(0.7),
                    Colors.black.withOpacity(0.85),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.xl,
                      AppSpacing.md,
                      AppSpacing.lg,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          loc.nutritionScanHint,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SecondaryCTA(
                          label: loc.nutritionScanManualCta,
                          icon: Icons.edit_rounded,
                          onPressed: () => Navigator.of(context).pushNamed(
                            AppRouter.nutritionEntry,
                            arguments: {'meal': _meal},
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for scanning overlay with brand gradient
class _ScanOverlayPainter extends CustomPainter {
  final Animation<double> animation;
  final Color brandColor;

  _ScanOverlayPainter({
    required this.animation,
    required this.brandColor,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final scanSize = size.width * 0.7;
    final scanRect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: scanSize,
      height: scanSize,
    );

    // Semi-transparent overlay
    final overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.5);
    
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      overlayPaint,
    );

    // Clear center
    canvas.drawRect(
      scanRect,
      Paint()..blendMode = BlendMode.clear,
    );

    // Corner brackets with brand gradient
    final cornerLength = 30.0;
    final cornerThickness = 4.0;
    
    final gradient = LinearGradient(
      colors: [
        brandColor,
        brandColor.withOpacity(0.5),
      ],
    );
    
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final bracketPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..strokeWidth = cornerThickness
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Top-left corner
    canvas.drawLine(
      Offset(scanRect.left, scanRect.top + cornerLength),
      Offset(scanRect.left, scanRect.top),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(scanRect.left, scanRect.top),
      Offset(scanRect.left + cornerLength, scanRect.top),
      bracketPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(scanRect.right - cornerLength, scanRect.top),
      Offset(scanRect.right, scanRect.top),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(scanRect.right, scanRect.top),
      Offset(scanRect.right, scanRect.top + cornerLength),
      bracketPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(scanRect.left, scanRect.bottom - cornerLength),
      Offset(scanRect.left, scanRect.bottom),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(scanRect.left, scanRect.bottom),
      Offset(scanRect.left + cornerLength, scanRect.bottom),
      bracketPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(scanRect.right - cornerLength, scanRect.bottom),
      Offset(scanRect.right, scanRect.bottom),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(scanRect.right, scanRect.bottom - cornerLength),
      Offset(scanRect.right, scanRect.bottom),
      bracketPaint,
    );

    // Animated scan line
    final scanY = scanRect.top + (scanRect.height * animation.value);
    final scanLinePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          brandColor.withOpacity(0.0),
          brandColor.withOpacity(0.8),
          brandColor.withOpacity(0.0),
        ],
      ).createShader(
        Rect.fromLTRB(scanRect.left, scanY - 2, scanRect.right, scanY + 2),
      )
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTRB(scanRect.left, scanY - 2, scanRect.right, scanY + 2),
      scanLinePaint,
    );
  }

  @override
  bool shouldRepaint(_ScanOverlayPainter oldDelegate) => true;
}
