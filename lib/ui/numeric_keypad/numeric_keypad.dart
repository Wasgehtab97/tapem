// ignore_for_file: unused_field
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:tapem/core/theme/brand_surface_theme.dart';
import 'package:tapem/core/widgets/gradient_button.dart';

/// =======================
/// Public API & Theme
/// =======================

typedef NextCallback = void Function();

class NumericKeypadController {
  final TextEditingController textController;
  final FocusNode focusNode;
  NumericKeypadController(this.textController, this.focusNode);
}

class NumericKeypadTheme {
  // Colors
  final Color bg;
  final Color keyBg;
  final Color keyFg;
  final Color cta;
  final Color overlayPressed;
  final Color disabled;

  // Layout
  final double keySize;
  final double gap;
  final double radius;
  final double railWidth;
  final double ctaHeight;

  // Typography
  final TextStyle textStyle;

  const NumericKeypadTheme({
    this.bg = const Color(0xFF0B0F12),
    this.keyBg = const Color(0xFF151A1F),
    this.keyFg = const Color(0xFFF5F7FA),
    this.cta = const Color(0xFFF2994A),
    this.overlayPressed = const Color(0x29FFFFFF), // 16–20% white
    this.disabled = const Color(0x66FFFFFF),       // 40% white
    this.keySize = 58.0,
    this.gap = 8.0,
    this.radius = 16.0,
    this.railWidth = 64.0,
    this.ctaHeight = 48.0,
    this.textStyle = const TextStyle(
      fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: 0.2,
    ),
  });

  NumericKeypadTheme copyWith({
    Color? bg, Color? keyBg, Color? keyFg, Color? cta,
    Color? overlayPressed, Color? disabled,
    double? keySize, double? gap, double? radius,
    double? railWidth, double? ctaHeight,
    TextStyle? textStyle,
  }) => NumericKeypadTheme(
    bg: bg ?? this.bg,
    keyBg: keyBg ?? this.keyBg,
    keyFg: keyFg ?? this.keyFg,
    cta: cta ?? this.cta,
    overlayPressed: overlayPressed ?? this.overlayPressed,
    disabled: disabled ?? this.disabled,
    keySize: keySize ?? this.keySize,
    gap: gap ?? this.gap,
    radius: radius ?? this.radius,
    railWidth: railWidth ?? this.railWidth,
    ctaHeight: ctaHeight ?? this.ctaHeight,
    textStyle: textStyle ?? this.textStyle,
  );

  factory NumericKeypadTheme.fromTheme(ThemeData theme) => NumericKeypadTheme(
        bg: theme.colorScheme.surface,
        keyBg: theme.canvasColor,
        keyFg: theme.colorScheme.onPrimary,
        cta: theme.colorScheme.primary,
        overlayPressed: theme.colorScheme.primary.withOpacity(0.15),
        disabled: theme.colorScheme.onPrimary.withOpacity(0.4),
      );
}

/// Convenience TextField (readOnly) – öffnet das Sheet bei Tap.
class NumericTextField extends StatelessWidget {
  final NumericKeypadController controller;
  final String? label;
  final bool allowsDecimal;
  final double step;
  final double? minValue;
  final double? maxValue;
  final NumericKeypadTheme? theme;
  final NextCallback? onNext;

  const NumericTextField({
    super.key,
    required this.controller,
    this.label,
    this.allowsDecimal = true,
    this.step = 1.0,
    this.minValue,
    this.maxValue,
    this.theme,
    this.onNext,
  });

  Future<void> _openSheet(BuildContext context) async {
    await showNumericKeypadSheet(
      context,
      controller: controller,
      allowsDecimal: allowsDecimal,
      step: step,
      minValue: minValue,
      maxValue: maxValue,
      onNext: onNext,
      theme: theme,
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller.textController,
      focusNode: controller.focusNode,
      readOnly: true,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onTap: () => _openSheet(context),
      decoration: InputDecoration(labelText: label),
    );
  }
}

/// API-Funktion zum Anzeigen des Keypads.
Future<void> showNumericKeypadSheet(
  BuildContext context, {
  required NumericKeypadController controller,
  bool allowsDecimal = true,
  double step = 1.0,
  double? minValue,
  double? maxValue,
  NextCallback? onNext,
  VoidCallback? onClosed,
  NumericKeypadTheme? theme,
  bool usePlatformAdaptiveStyle = true,
}) async {
  final th = theme ?? NumericKeypadTheme.fromTheme(Theme.of(context));
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: th.bg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    constraints: BoxConstraints(
      maxHeight: math.min(MediaQuery.of(context).size.height * 0.45, 420),
    ),
    builder: (ctx) => _NumericKeypadSheet(
      controller: controller,
      allowsDecimal: allowsDecimal,
      step: step,
      minValue: minValue,
      maxValue: maxValue,
      onNext: onNext,
      onClosed: onClosed,
      theme: th,
      platformAdaptive: usePlatformAdaptiveStyle,
    ),
  );
}

/// =======================
/// Implementation
/// =======================

class _NumericKeypadSheet extends StatefulWidget {
  final NumericKeypadController controller;
  final bool allowsDecimal;
  final double step;
  final double? minValue;
  final double? maxValue;
  final NextCallback? onNext;
  final VoidCallback? onClosed;
  final NumericKeypadTheme theme;
  final bool platformAdaptive;

  const _NumericKeypadSheet({
    required this.controller,
    required this.allowsDecimal,
    required this.step,
    required this.minValue,
    required this.maxValue,
    required this.onNext,
    required this.onClosed,
    required this.theme,
    required this.platformAdaptive,
  });

  @override
  State<_NumericKeypadSheet> createState() => _NumericKeypadSheetState();
}

class _NumericKeypadSheetState extends State<_NumericKeypadSheet> {
  late final String _decimalSep;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context).toString();
    _decimalSep =
        NumberFormat.decimalPattern(locale).symbols.DECIMAL_SEP;
  }

  /// ===== Helpers: text editing
  void _insert(String s) {
    final tc = widget.controller.textController;
    final sel = tc.selection;
    final text = tc.text;
    final start = sel.start >= 0 ? sel.start : text.length;
    final end = sel.end >= 0 ? sel.end : text.length;
    final newText = text.replaceRange(start, end, s);
    tc.text = newText;
    tc.selection = TextSelection.collapsed(offset: start + s.length);
  }

  void _backspace() {
    final tc = widget.controller.textController;
    final sel = tc.selection;
    final text = tc.text;
    int start = sel.start, end = sel.end;
    if (start == -1 || end == -1) {
      if (text.isEmpty) return;
      tc.text = text.substring(0, text.length - 1);
      tc.selection = TextSelection.collapsed(offset: tc.text.length);
      return;
    }
    if (start == end && start > 0) start -= 1;
    final newText = text.replaceRange(start, end, '');
    tc.text = newText;
    tc.selection = TextSelection.collapsed(offset: start);
  }

  bool _hasDecimal() =>
      widget.controller.textController.text.contains(_decimalSep);


  @override
  Widget build(BuildContext context) {
    final th = widget.theme;
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final padding = MediaQuery.viewPaddingOf(context);
    final sheetHeight =
        math.min(MediaQuery.of(context).size.height * 0.45, 420.0);

    return SizedBox(
      width: double.infinity,
      height: sheetHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final widthBased =
              (constraints.maxWidth - 24 - th.gap * 2) / 3;
          final handleHeight = isIOS ? 0.0 : 16.0;
          final bottomPad = padding.bottom > 0 ? 8.0 : 12.0;
          final availableHeight = constraints.maxHeight -
              12 -
              handleHeight -
              12 -
              (Theme.of(context)
                      .extension<BrandSurfaceTheme>()
                      ?.height ??
                  th.ctaHeight) -
              bottomPad;
          final heightBased =
              (availableHeight - th.gap * 3) / 4;
          final keySide = math.max(48.0, math.min(widthBased, heightBased));

          return SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(
                left: 12,
                right: 12,
                bottom: bottomPad,
                top: 12,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  if (!isIOS)
                    Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  _buildGrid(th, keySide),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GradientButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).maybePop();
                        widget.onNext?.call();
                      },
                      child: const Text('Weiter'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGrid(NumericKeypadTheme th, double keySide) {
    final keys = <_KeySpec>[
      for (final k in ['1', '2', '3', '4', '5', '6', '7', '8', '9'])
        _KeySpec.text(k),
      _KeySpec.text(_decimalSep),
      _KeySpec.text('0'),
      _KeySpec.icon(CupertinoIcons.delete_left),
    ];

    return SizedBox(
      height: keySide * 4 + th.gap * 3,
      child: GridView.count(
        crossAxisCount: 3,
        childAspectRatio: 1,
        mainAxisSpacing: th.gap,
        crossAxisSpacing: th.gap,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(keys.length, (i) {
          final spec = keys[i];
          return _KeyButton(
            theme: th,
            width: keySide,
            height: keySide,
            icon: spec.icon,
            label: spec.label,
            onTap: () {
              HapticFeedback.selectionClick();
              if (spec.isIcon) {
                _backspace();
              } else if (spec.label == _decimalSep) {
                if (widget.allowsDecimal && !_hasDecimal()) {
                  _insert(_decimalSep);
                }
              } else {
                _insert(spec.label!);
              }
            },
            onHold: spec.isIcon ? () => _backspace() : null,
          );
        }),
      ),
    );
  }

  // Rail with additional actions has been removed to keep the layout compact.
}

/// Taste mit Press-Animation, Glow & optionalem Long-Press-Repeat.
class _KeyButton extends StatefulWidget {
  final NumericKeypadTheme theme;
  final double width;
  final double height;
  final IconData? icon;
  final String? label;
  final VoidCallback? onTap;
  final VoidCallback? onHold;

  const _KeyButton({
    required this.theme,
    required this.width,
    required this.height,
    this.icon,
    this.label,
    this.onTap,
    this.onHold,
  });

  @override
  State<_KeyButton> createState() => _KeyButtonState();
}

class _KeyButtonState extends State<_KeyButton> {
  bool _pressed = false;
  final _hold = _HoldRepeater();

  @override
  void dispose() {
    _hold.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final th = widget.theme;
    final surface = Theme.of(context).extension<BrandSurfaceTheme>();
    final radius = surface?.radius ?? BorderRadius.circular(th.radius);
    final textStyle = surface?.textStyle ?? th.textStyle;
    final fg = textStyle.color ?? th.keyFg;
    final overlay = surface?.pressedOverlay ?? th.overlayPressed;
    final content = DecoratedBox(
      decoration: BoxDecoration(
        gradient: surface?.gradient ??
            LinearGradient(colors: [th.cta, th.cta]),
        borderRadius: radius,
        boxShadow: surface?.shadow,
      ),
      child: Stack(
        children: [
          Center(
            child: widget.icon != null
                ? Icon(widget.icon, color: fg)
                : Text(widget.label ?? '',
                    style: textStyle.copyWith(color: fg)),
          ),
          if (_pressed)
            DecoratedBox(
              decoration: BoxDecoration(
                color: overlay,
                borderRadius: radius,
              ),
            ),
        ],
      ),
    );

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) {
            setState(() => _pressed = true);
            if (widget.onHold != null) {
              _hold.start(onFire: widget.onHold!);
            }
          },
          onTapUp: (_) {
            setState(() => _pressed = false);
            _hold.stop();
            widget.onTap?.call();
          },
          onTapCancel: () {
            setState(() => _pressed = false);
            _hold.stop();
          },
          onLongPressStart: (_) {
            if (widget.onHold != null) {
              HapticFeedback.mediumImpact();
              _hold.enableBurst();
            }
          },
          child: content,
        ),
      ),
    );
  }
}

class _HoldRepeater {
  Timer? _timer;
  Duration _initial = const Duration(milliseconds: 350);
  Duration _repeat = const Duration(milliseconds: 60);
  VoidCallback? _onFire;

  void start({required VoidCallback onFire}) {
    _onFire = onFire;
    _timer?.cancel();
    _timer = Timer(_initial, () {
      _timer = Timer.periodic(_repeat, (_) => _onFire?.call());
    });
  }

  void enableBurst() {
    if (_timer?.isActive ?? false) return;
    // nothing – kept for clarity
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() => _timer?.cancel();
}

class _KeySpec {
  final String? label;
  final IconData? icon;
  bool get isIcon => icon != null;

  _KeySpec.text(this.label) : icon = null;
  _KeySpec.icon(this.icon) : label = null;
}

/*
Example usage:

// In deinem Screen/State:
final kgCtrl = NumericKeypadController(TextEditingController(), FocusNode());
final repsCtrl = NumericKeypadController(TextEditingController(), FocusNode());

// Beispiel-Theme in deinen App-Farben:
final keypadTheme = NumericKeypadTheme(
  bg: const Color(0xFF0B0F12),
  keyBg: const Color(0xFF151A1F),
  keyFg: const Color(0xFFF5F7FA),
  cta: const Color(0xFFF2994A), // <- ersetze mit deiner Primärfarbe
);

// Im Build:
Column(
  children: [
    NumericTextField(
      controller: kgCtrl,
      label: 'kg',
      allowsDecimal: true,
      step: 0.5,
      minValue: 0,
      theme: keypadTheme,
      onNext: () {
        // Fokus auf Wdh.
        repsCtrl.focusNode.requestFocus();
        showNumericKeypadSheet(
          context,
          controller: repsCtrl,
          allowsDecimal: false,
          step: 1,
          minValue: 0,
          theme: keypadTheme,
        );
      },
    ),
    const SizedBox(height: 16),
    NumericTextField(
      controller: repsCtrl,
      label: 'Wdh.',
      allowsDecimal: false,
      step: 1,
      minValue: 0,
      theme: keypadTheme,
    ),
  ],
);
*/

/*
FAQ

Brauche ich extra Assets/PNGs?
Nein. Alles oben nutzt nur Code (Material/Cupertino‑Icons, Gradients, BoxShadow).

"Keyboard wechseln"-Button → Systemtastatur
Der Button schließt das Sheet. Wenn dein Feld nicht readOnly ist, erscheint die Systemtastatur automatisch.

Farben im Stil deiner App
Passe einfach NumericKeypadTheme an (bg, keyBg, keyFg, cta etc.).
*/
