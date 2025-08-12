// ignore_for_file: unused_field
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  final th = theme ?? const NumericKeypadTheme();
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: th.bg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
    _decimalSep = MaterialLocalizations.of(context).decimalSeparator;
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

  double _parse() {
    final t = widget.controller.textController.text.trim();
    if (t.isEmpty) return 0.0;
    final normalized = t.replaceAll(_decimalSep, '.');
    return double.tryParse(normalized) ?? 0.0;
  }

  void _writeFormatted(double v) {
    // Clamp
    if (widget.minValue != null && v < widget.minValue!) v = widget.minValue!;
    if (widget.maxValue != null && v > widget.maxValue!) v = widget.maxValue!;
    // Strip trailing zeros
    String s = v.toStringAsFixed(6);
    s = s.replaceFirst(RegExp(r'\.?0+\$'), '');
    s = s.replaceFirst(RegExp(r'\.?0+$'), '');
    s = s.replaceAll('.', _decimalSep);
    widget.controller.textController
      ..text = s
      ..selection = TextSelection.collapsed(offset: s.length);
  }

  Future<void> _copy() async {
    final t = widget.controller.textController.text;
    await Clipboard.setData(ClipboardData(text: t));
    HapticFeedback.lightImpact();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData('text/plain');
    final raw = data?.text ?? '';
    final allowed = RegExp('[0-9${RegExp.escape(_decimalSep)}]');
    final filtered = raw.split('').where((c) => allowed.hasMatch(c)).join();

    if (filtered.isEmpty) return;
    // Normalize to our single decimal sep
    String s = filtered;
    // Wenn mehrere Dezimalzeichen → nur das erste behalten
    final first = s.indexOf(_decimalSep);
    if (first != -1) {
      s = s.replaceAll(_decimalSep, '');
      s = s.substring(0, first) + _decimalSep + s.substring(first);
    }
    widget.controller.textController.text = s;
    widget.controller.textController.selection =
        TextSelection.collapsed(offset: s.length);
    HapticFeedback.selectionClick();
  }

  void _toggleSystemKeyboard() {
    // Einfach: Sheet schließen – das Host-Feld kann dann ggf. readOnly=false setzen.
    Navigator.of(context).pop();
    widget.onClosed?.call();
    // Fokus bleibt auf dem Feld; System-Keyboard zeigt sich,
    // wenn das Feld nicht readOnly ist (Host entscheidet).
  }

  final _hold = _HoldRepeater();

  @override
  void dispose() {
    _hold.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final th = widget.theme;
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final padding = MediaQuery.viewPaddingOf(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          bottom: padding.bottom > 0 ? 8 : 12,
          top: 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Optional: Drag handle (vor allem Android)
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Grid
                Expanded(child: _buildGrid(th)),
                const SizedBox(width: 8),
                // Rail
                _buildRail(th),
              ],
            ),
            const SizedBox(height: 12),
            // CTA Weiter
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                height: th.ctaHeight,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).maybePop();
                    widget.onNext?.call();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: th.cta,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    elevation: 3,
                    shadowColor: Colors.black54,
                  ),
                  child: const Text('Weiter',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(NumericKeypadTheme th) {
    final keys = <_KeySpec>[
      for (final k in ['1','2','3','4','5','6','7','8','9']) _KeySpec.text(k),
      _KeySpec.text(_decimalSep),
      _KeySpec.text('0'),
      _KeySpec.icon(CupertinoIcons.delete_left),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        return Wrap(
          spacing: th.gap,
          runSpacing: th.gap,
          children: List.generate(keys.length, (i) {
            final spec = keys[i];
            return _KeyButton(
              theme: th,
              width: (c.maxWidth - 2 * th.gap) / 3,
              height: th.keySize,
              icon: spec.icon,
              label: spec.label,
              onTap: () {
                HapticFeedback.selectionClick();
                if (spec.isIcon) {
                  _backspace();
                } else if (spec.label == _decimalSep) {
                  if (widget.allowsDecimal && !_hasDecimal()) _insert(_decimalSep);
                } else {
                  _insert(spec.label!);
                }
              },
              onHold: spec.isIcon
                  ? () => _backspace()
                  : null,
            );
          }),
        );
      },
    );
  }

  Widget _buildRail(NumericKeypadTheme th) {
    final btn = (_KeySpec spec, {VoidCallback? onHold}) => Padding(
      padding: EdgeInsets.only(bottom: th.gap),
      child: _KeyButton(
        theme: th,
        width: th.railWidth,
        height: th.keySize,
        icon: spec.icon,
        label: spec.label,
        onTap: () {
          HapticFeedback.selectionClick();
          spec.onTap?.call();
        },
        onHold: onHold,
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        btn(_KeySpec.icon(Icons.keyboard, onTap: _toggleSystemKeyboard)),
        btn(_KeySpec.icon(Icons.copy_all_rounded, onTap: _copy)),
        btn(_KeySpec.icon(Icons.content_paste_rounded, onTap: _paste)),
        // Stepper + / -
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _KeyButton(
              theme: th, width: (th.railWidth - th.gap) / 2, height: th.keySize,
              icon: Icons.add,
              onTap: () {
                final v = _parse() + widget.step;
                _writeFormatted(v);
              },
              onHold: () {
                final v = _parse() + widget.step;
                _writeFormatted(v);
              },
            ),
            SizedBox(width: th.gap),
            _KeyButton(
              theme: th, width: (th.railWidth - th.gap) / 2, height: th.keySize,
              icon: Icons.remove,
              onTap: () {
                final v = _parse() - widget.step;
                _writeFormatted(v);
              },
              onHold: () {
                final v = _parse() - widget.step;
                _writeFormatted(v);
              },
            ),
          ],
        ),
        SizedBox(height: th.gap),
        btn(_KeySpec.icon(CupertinoIcons.xmark_circle_fill, onTap: () {
          Navigator.of(context).maybePop();
          widget.onClosed?.call();
        })),
      ],
    );
  }
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

    final child = Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: th.keyBg,
        borderRadius: BorderRadius.circular(th.radius),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
        ],
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x1FFFFFFF), Color(0x19FFFFFF)], // subtiler Glaslook
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: widget.icon != null
                ? Icon(widget.icon, color: th.keyFg)
                : Text(widget.label ?? '',
                    style: th.textStyle.copyWith(color: th.keyFg)),
          ),
          if (_pressed)
            Container(
              decoration: BoxDecoration(
                color: th.overlayPressed,
                borderRadius: BorderRadius.circular(th.radius),
              ),
            ),
        ],
      ),
    );

    return AnimatedScale(
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
  final VoidCallback? onTap;
  bool get isIcon => icon != null;

  _KeySpec.text(this.label)
      : icon = null,
        onTap = null;
  _KeySpec.icon(this.icon, {this.onTap}) : label = null;
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
