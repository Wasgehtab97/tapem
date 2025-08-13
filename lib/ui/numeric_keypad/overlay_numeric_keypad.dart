// overlay_numeric_keypad.dart
// Geometry-driven, compact in-app numeric keyboard (3x4 + action rail without CTA)
// Author: you + GPT-5 Thinking

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ============================
/// THEME TOKENS (zentral)
/// ============================
class NumericKeypadTheme {
  final double gap; // Abstand zwischen Keys/Rail
  final double corner; // Rundung am Sheet-Top
  final double minKeySide; // minimale Key-Kantenlänge (Safety-Net)
  final double minFrac; // weiches Mindestmaß relativ zur Höhe
  final double maxFrac; // weiches Höchstmaß relativ zur Höhe
  final double
  heightScale; // < 1.0 macht die Tastatur flacher (z.B. 0.5 = halb so hoch)

  final Color sheetBg; // Hintergrund zwischen den Keys (auch für Rail-Gaps)
  final Color keyBg;
  final Color keyFg;
  final Color
  railBg; // unbenutzt als Fläche (wir blenden in sheetBg), bleibt für Theme-Flex
  final Color railIcon;
  final Color press;

  const NumericKeypadTheme({
    this.gap = 12.0,
    this.corner = 18.0,
    this.minKeySide = 44.0,
    this.minFrac = 0.28, // min 28% der Screenhöhe (vor Skalierung)
    this.maxFrac = 0.45, // max 45% (vor Skalierung)
    this.heightScale = 0.5, // kompakt
    this.sheetBg = const Color(0xFF0F1012),
    this.keyBg = const Color(0xFF1A1D21),
    this.keyFg = Colors.white,
    this.railBg = const Color(0xFF14171A),
    this.railIcon = Colors.white70,
    this.press = const Color(0xFF2A2E33),
  });
}

/// ===================================
/// CONTROLLER: öffnet/schließt & Ziel
/// ===================================
class OverlayNumericKeypadController extends ChangeNotifier {
  TextEditingController? _target;
  bool _isOpen = false;
  bool allowDecimal = true;
  double decimalStep = 2.5; // z.B. Gewichte
  double integerStep = 1.0; // z.B. Wiederholungen

  bool get isOpen => _isOpen;
  TextEditingController? get target => _target;

  void openFor(
    TextEditingController controller, {
    bool allowDecimal = true,
    double? decimalStep,
    double? integerStep,
  }) {
    _target = controller;
    this.allowDecimal = allowDecimal;
    if (decimalStep != null) this.decimalStep = decimalStep;
    if (integerStep != null) this.integerStep = integerStep;
    FocusManager.instance.primaryFocus?.unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    _isOpen = true;
    notifyListeners();
  }

  void close() {
    _isOpen = false;
    notifyListeners();
  }
}

/// =======================================================
/// HOST: Overlay-Layer über dem Screen (kein Modal)
/// =======================================================
class OverlayNumericKeypadHost extends StatefulWidget {
  final OverlayNumericKeypadController controller;
  final Widget child;
  final NumericKeypadTheme theme;
  final bool interceptAndroidBack; // Back schließt Tastatur statt Route

  const OverlayNumericKeypadHost({
    super.key,
    required this.controller,
    required this.child,
    this.theme = const NumericKeypadTheme(),
    this.interceptAndroidBack = true,
  });

  @override
  State<OverlayNumericKeypadHost> createState() =>
      _OverlayNumericKeypadHostState();
}

class _OverlayNumericKeypadHostState extends State<OverlayNumericKeypadHost>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_rebuild);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(covariant OverlayNumericKeypadHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_rebuild);
      widget.controller.addListener(_rebuild);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && widget.controller.isOpen) {
      widget.controller.close();
    }
  }

  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final keypad = widget.controller.isOpen
        ? OverlayNumericKeypad(
            controller: widget.controller,
            theme: widget.theme,
          )
        : const SizedBox.shrink();

    // Insert a translucent layer that closes the keypad when tapping outside it.
    Widget result = Stack(
      children: [
        widget.child,
        if (widget.controller.isOpen)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                widget.controller.close();
                FocusManager.instance.primaryFocus?.unfocus();
              },
            ),
          ),
        Align(
          alignment: Alignment.bottomCenter,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: keypad,
          ),
        ),
      ],
    );

    if (widget.controller.isOpen) {
      final mq = MediaQuery.of(context);
      result = MediaQuery(
        data: mq.copyWith(viewInsets: mq.viewInsets.copyWith(bottom: 0)),
        child: result,
      );
    }

    if (widget.interceptAndroidBack) {
      result = WillPopScope(
        onWillPop: () async {
          if (widget.controller.isOpen) {
            widget.controller.close();
            return false;
          }
          return true;
        },
        child: result,
      );
    }

    return result;
  }
}

/// ======================================
/// KEYPAD: 3×4 Grid + kompakte Action-Rail
/// ======================================
class OverlayNumericKeypad extends StatelessWidget {
  final OverlayNumericKeypadController controller;
  final NumericKeypadTheme theme;

  const OverlayNumericKeypad({
    super.key,
    required this.controller,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    // --- Geometrie: alles aus Constraints ableiten ---
    final media = MediaQuery.of(context);

    // robust: max(viewPadding, padding) → vermeidet abgeschnittene Keys
    final safeBottom = math.max(media.viewPadding.bottom, media.padding.bottom);

    final size = media.size;
    final gap = theme.gap;

    // 4 Spalten: 3 Grid + 1 Rail → Zellbreite
    final cellW = (size.width - 3 * gap) / 4.0;

    // Basis-Höhe bei quadratischen Keys
    final idealGridH = 4 * cellW + 3 * gap;

    // clampen → skalieren → Mindest-Fit sicherstellen
    final minH = size.height * theme.minFrac;
    final maxH = size.height * theme.maxFrac;
    final baseH = idealGridH.clamp(minH, maxH);
    final scaledH = baseH * theme.heightScale;
    final minFitH = theme.minKeySide * 4 + 3 * gap;
    final contentH = math.max(minFitH, scaledH);

    // Innenhöhe = contentH abzüglich Sheet-Paddings (oben+unten)
    final innerH = contentH - (gap + gap);

    // Zellhöhe & Aspect aus der echten Innenhöhe
    final cellH = (innerH - 3 * gap) / 4.0;
    final aspect = cellW / cellH;

    // Safety: minKeySide für Rail
    final enforcedCellW = math.max(theme.minKeySide, cellW);
    final enforcedCellH = math.max(theme.minKeySide, cellH);
    final railW = enforcedCellW;

    // Gesamthöhe des Sheets inkl. SafeArea
    final barHeight = contentH + safeBottom;
    final decLabel = _decimalChar(context); // "," oder "."

    return Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        width: double.infinity,
        height: barHeight,
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: theme.sheetBg,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(theme.corner),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 20,
                  offset: Offset(0, -8),
                ),
              ],
            ),
            // Bottom-Padding enthält safeBottom → Tasten enden oberhalb Gestenleiste
            padding: EdgeInsets.fromLTRB(gap, gap, gap, gap + safeBottom),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Grid 3×4 (snapped auf innerH) ---
                Expanded(
                  child: SizedBox(
                    height: innerH,
                    child: _KeyGrid(
                      aspect: aspect,
                      gap: gap,
                      theme: theme,
                      allowDecimal: controller.allowDecimal,
                      decimalLabel: decLabel,
                      onKey: (t) => _applyToken(context, controller, t),
                    ),
                  ),
                ),
                SizedBox(width: gap),

                // --- Action-Rail (ohne Backspace & ohne CTA) ---
                ConstrainedBox(
                  constraints: BoxConstraints.tightFor(width: railW),
                  child: _ActionRailCompact(
                    gridCellWidth: enforcedCellW,
                    gridCellHeight: enforcedCellH,
                    totalGridRows: 4,
                    gap: gap,
                    theme: theme,
                    onHide: controller.close,
                    onPaste: () async {
                      final data = await Clipboard.getData('text/plain');
                      if (data?.text != null) {
                        _pasteInto(controller, data!.text!);
                        _haptic(context);
                      }
                    },
                    onCopy: () {
                      Clipboard.setData(
                        ClipboardData(text: controller.target?.text ?? ''),
                      );
                      _haptic(context);
                    },
                    onPlus: () => _increment(context, controller, 1),
                    onMinus: () => _increment(context, controller, -1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------- Helpers -------
  static void _haptic(BuildContext ctx) {
    switch (Theme.of(ctx).platform) {
      case TargetPlatform.iOS:
        HapticFeedback.lightImpact();
        break;
      default:
        HapticFeedback.selectionClick();
    }
  }

  static String _decimalChar(BuildContext ctx) {
    final lc = Localizations.localeOf(ctx);
    final lang = lc.languageCode.toLowerCase();
    const commaLangs = {
      'de',
      'fr',
      'es',
      'it',
      'pt',
      'nl',
      'tr',
      'ru',
      'pl',
      'cs',
      'da',
      'sv',
      'fi',
      'no',
      'hu',
    };
    return commaLangs.contains(lang) ? ',' : '.';
  }

  static void _pasteInto(OverlayNumericKeypadController ctl, String text) {
    final t = ctl.target;
    if (t == null) return;
    final cleaned =
        ctl.allowDecimal
            ? text
                .trim()
                .replaceAll(',', '.')
                .replaceAll(RegExp(r'[^0-9\.]'), '')
            : text.replaceAll(RegExp(r'[^0-9]'), '');
    final parts = cleaned.split('.');
    final normalized =
        ctl.allowDecimal && parts.length > 1
            ? '${parts[0]}.${parts.sublist(1).join()}'
            : cleaned;
    t.value = TextEditingValue(
      text: normalized,
      selection: TextSelection.collapsed(offset: normalized.length),
    );
  }

  static void _applyToken(
    BuildContext ctx,
    OverlayNumericKeypadController ctl,
    String token,
  ) {
    final t = ctl.target;
    if (t == null) return;

    String v = t.text;
    if (token == 'del') {
      if (v.isNotEmpty) v = v.substring(0, v.length - 1);
    } else if (token == 'dec') {
      if (!ctl.allowDecimal) return;
      // nur ein Dezimaltrennzeichen zulassen – Punkt ODER Komma
      if (!(v.contains('.') || v.contains(','))) {
        final char = _decimalChar(ctx);
        v += char;
      }
    } else if (RegExp(r'^[0-9]$').hasMatch(token)) {
      v += token;
    } else {
      return;
    }
    t.value = TextEditingValue(
      text: v,
      selection: TextSelection.collapsed(offset: v.length),
    );
    _haptic(ctx);
  }

  static void _increment(
    BuildContext ctx,
    OverlayNumericKeypadController ctl,
    int direction,
  ) {
    final t = ctl.target;
    if (t == null) return;

    final raw = t.text.replaceAll(',', '.');
    final step = ctl.allowDecimal ? ctl.decimalStep : ctl.integerStep;

    double current = 0;
    if (raw.isNotEmpty) current = double.tryParse(raw) ?? 0;
    final next = current + (step * direction);
    final value =
        ctl.allowDecimal ? next.toStringAsFixed(2) : next.round().toString();

    t.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    _haptic(ctx);
  }
}

/// ===============================
/// GRID (3×4) – deterministisch
/// ===============================
class _KeyGrid extends StatelessWidget {
  final double aspect; // width/height einer Zelle
  final double gap;
  final bool allowDecimal;
  final String decimalLabel; // UI-Label für das Dezimalzeichen
  final NumericKeypadTheme theme;
  final ValueChanged<String> onKey;

  const _KeyGrid({
    required this.aspect,
    required this.gap,
    required this.theme,
    required this.allowDecimal,
    required this.decimalLabel,
    required this.onKey,
  });

  @override
  Widget build(BuildContext context) {
    final items = <_KeySpec>[
      for (final n in ['1', '2', '3', '4', '5', '6', '7', '8', '9'])
        _KeySpec(token: n, label: n, semantics: 'Taste $n'),
      _KeySpec(
        token: allowDecimal ? 'dec' : '_',
        label: allowDecimal ? decimalLabel : '',
        disabled: !allowDecimal,
        semantics: 'Dezimaltrennzeichen',
      ),
      _KeySpec(token: '0', label: '0', semantics: 'Taste 0'),
      _KeySpec(
        token: 'del',
        icon: Icons.backspace_outlined,
        semantics: 'Löschen',
      ),
    ];

    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      crossAxisCount: 3,
      mainAxisSpacing: gap,
      crossAxisSpacing: gap,
      childAspectRatio: aspect,
      children: [
        for (final k in items)
          _KeyButton(
            theme: theme,
            label: k.label,
            icon: k.icon,
            disabled: k.disabled,
            repeat: k.token == 'del',
            semanticsLabel: k.semantics,
            onTap: k.disabled ? null : () => onKey(k.token),
          ),
      ],
    );
  }
}

class _KeySpec {
  final String token;
  final String label;
  final bool disabled;
  final IconData? icon;
  final String semantics;

  _KeySpec({
    required this.token,
    this.label = '',
    this.disabled = false,
    this.icon,
    this.semantics = '',
  });
}

/// =============================================
/// ACTION-RAIL (kompakt) – ohne CTA & ohne Backspace
/// Reihenfolge:
/// 1) Kopieren | 2) Einfügen
/// 3) Minus    | 4) Plus
/// 5) Tastatur ausblenden (volle Breite unten)
/// Hintergründe & Gaps identisch zum Grid (sheetBg), damit es „aus einem Guss“ wirkt.
/// =============================================
class _ActionRailCompact extends StatelessWidget {
  final double gridCellWidth; // Breite einer Grid-Zelle
  final double gridCellHeight; // Höhe einer Grid-Zelle
  final int totalGridRows; // i.d.R. 4
  final double gap;
  final NumericKeypadTheme theme;
  final VoidCallback onHide, onPaste, onCopy, onPlus, onMinus;

  const _ActionRailCompact({
    required this.gridCellWidth,
    required this.gridCellHeight,
    required this.totalGridRows,
    required this.gap,
    required this.theme,
    required this.onHide,
    required this.onPaste,
    required this.onCopy,
    required this.onPlus,
    required this.onMinus,
  });

  @override
  Widget build(BuildContext context) {
    // Gesamthöhe, die das Grid nebenan belegt:
    final availableH =
        totalGridRows * gridCellHeight + (totalGridRows - 1) * gap;

    // copy (oben links) | paste (oben rechts)
    // minus (mitte links) | plus (mitte rechts)
    // hide (unten vollbreit)
    final actions = <_RailAction>[
      _RailAction(Icons.copy_rounded, 'Kopieren', onCopy),
      _RailAction(Icons.paste_rounded, 'Einfügen', onPaste),
      _RailAction(Icons.remove_rounded, 'Verringern', onMinus, repeat: true),
      _RailAction(Icons.add_rounded, 'Erhöhen', onPlus, repeat: true),
      _RailAction(Icons.keyboard_hide_rounded, 'Tastatur ausblenden', onHide),
    ];

    final rowsNeeded = (actions.length / 2).ceil(); // für die Höhe
    final totalRowGaps = math.max(0, rowsNeeded - 1);

    // Kachel-Seite (pixel-snapped, damit keine Haarlinien entstehen)
    final sideV = (availableH - totalRowGaps * gap) / rowsNeeded;
    final sideH = (gridCellWidth - gap) / 2;
    final side = math.max(28.0, math.min(sideV, sideH)).floorToDouble(); // snap

    Widget squareBtn(_RailAction a) => _RailBtnSquare(
      side: side,
      icon: a.icon,
      semanticsLabel: a.label,
      onTap: a.onTap,
      repeat: a.repeat,
      theme: theme,
    );

    int i = 0;
    final rows = <Widget>[];
    while (i < actions.length) {
      final left = actions[i];
      final hasRight = (i + 1) < actions.length;
      final right = hasRight ? actions[i + 1] : null;

      if (hasRight) {
        rows.add(
          SizedBox(
            height: side,
            child: Row(
              children: [
                Expanded(child: squareBtn(left)),
                SizedBox(width: gap),
                Expanded(child: squareBtn(right!)),
              ],
            ),
          ),
        );
        i += 2;
      } else {
        // letzte einzelne Kachel → volle Breite
        rows.add(
          SizedBox(
            height: side,
            child: Row(children: [Expanded(child: squareBtn(left))]),
          ),
        );
        i += 1;
      }
      if (i < actions.length) rows.add(SizedBox(height: gap));
    }

    return Container(
      // WICHTIG: identischer Hintergrund wie die Gaps im Grid
      color: theme.sheetBg,
      // leichte Abrundung nur außen, damit das ganze Sheet eine Einheit bleibt
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(theme.corner),
          bottomRight: const Radius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [...rows, const Spacer()],
        ),
      ),
    );
  }
}

class _RailAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool repeat;
  _RailAction(this.icon, this.label, this.onTap, {this.repeat = false});
}

/// kleines (auch vollbreit verwendbares) Rail-Icon
class _RailBtnSquare extends StatefulWidget {
  final double side; // Höhe des Rasters; Breite kann variieren (Expanded)
  final IconData icon;
  final String semanticsLabel;
  final VoidCallback onTap;
  final bool repeat;
  final NumericKeypadTheme theme;

  const _RailBtnSquare({
    required this.side,
    required this.icon,
    required this.semanticsLabel,
    required this.onTap,
    required this.theme,
    this.repeat = false,
  });

  @override
  State<_RailBtnSquare> createState() => _RailBtnSquareState();
}

class _RailBtnSquareState extends State<_RailBtnSquare> {
  Timer? _timer;

  void _start() {
    widget.onTap();
    if (!widget.repeat) return;
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 260), () {
      _timer = Timer.periodic(
        const Duration(milliseconds: 70),
        (_) => widget.onTap(),
      );
    });
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final th = widget.theme;
    return Semantics(
      label: widget.semanticsLabel,
      button: true,
      child: GestureDetector(
        onTapDown: (_) => _start(),
        onTapUp: (_) => _stop(),
        onTapCancel: _stop,
        child: Container(
          // volle Breite, Höhe vom umschließenden SizedBox (side)
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: th.keyBg, // identisch zu den Ziffern-Keys
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: FittedBox(child: Icon(widget.icon, color: th.railIcon)),
        ),
      ),
    );
  }
}

/// ===============================
/// KEY BUTTON (responsiv, Semantics)
/// ===============================
class _KeyButton extends StatefulWidget {
  final String? label;
  final IconData? icon;
  final bool disabled;
  final bool repeat;
  final VoidCallback? onTap;
  final String semanticsLabel;
  final NumericKeypadTheme theme;

  const _KeyButton({
    required this.theme,
    this.label,
    this.icon,
    this.disabled = false,
    this.repeat = false,
    this.onTap,
    this.semanticsLabel = '',
  });

  @override
  State<_KeyButton> createState() => _KeyButtonState();
}

class _KeyButtonState extends State<_KeyButton> {
  Timer? _timer;

  void _start() {
    if (widget.onTap == null) return;
    widget.onTap!.call();
    if (!widget.repeat) return;
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 260), () {
      _timer = Timer.periodic(
        const Duration(milliseconds: 70),
        (_) => widget.onTap!.call(),
      );
    });
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final th = widget.theme;

    final child = FittedBox(
      fit: BoxFit.scaleDown,
      child:
          widget.icon != null
              ? Icon(widget.icon, color: th.keyFg)
              : Text(
                widget.label ?? '',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),
              ),
    );

    return Semantics(
      label:
          widget.semanticsLabel.isEmpty
              ? (widget.label?.isNotEmpty == true
                  ? 'Taste ${widget.label}'
                  : 'Taste')
              : widget.semanticsLabel,
      button: true,
      child: GestureDetector(
        onTapDown: (_) => _start(),
        onTapUp: (_) => _stop(),
        onTapCancel: _stop,
        child: Container(
          decoration: BoxDecoration(
            color: widget.disabled ? th.keyBg.withOpacity(0.5) : th.keyBg,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}
