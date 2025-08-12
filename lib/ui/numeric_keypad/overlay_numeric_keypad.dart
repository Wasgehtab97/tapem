import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ============================
/// THEME TOKENS (zentral steuerbar)
/// ============================
class NumericKeypadTheme {
  final double heightFraction;   // Anteil an der Bildschirmhöhe
  final double maxHeight;        // Obergrenze in dp
  final double gap;              // Abstand zwischen Keys
  final double corner;           // Rundung am Sheet-Top
  final double minKeySide;       // Mindest-Kantenlänge eines Keys

  final Color sheetBg;
  final Color keyBg;
  final Color keyFg;
  final Color railBg;
  final Color railIcon;
  final Color press;

  const NumericKeypadTheme({
    this.heightFraction = 0.30,         // ~30% der Screen-Höhe
    this.maxHeight = 300.0,
    this.gap = 6.0,
    this.corner = 16.0,
    this.minKeySide = 34.0,
    this.sheetBg = const Color(0xFF121212),
    this.keyBg = const Color(0xFF1E1E1E),
    this.keyFg = Colors.white,
    this.railBg = const Color(0xFF0F0F0F),
    this.railIcon = Colors.white70,
    this.press = const Color(0xFF2A2A2A),
  });
}

/// ===================================
/// CONTROLLER: öffnen/schließen + Ziel
/// ===================================
class OverlayNumericKeypadController extends ChangeNotifier {
  TextEditingController? _target;
  bool _isOpen = false;
  bool allowDecimal = true;
  double decimalStep = 2.5;  // für Gewichte
  double integerStep = 1.0;  // für Wiederholungen

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
    _isOpen = true;
    notifyListeners();
  }

  void close() {
    _isOpen = false;
    notifyListeners();
  }
}

/// =======================================================
/// HOST: legt das Keypad als OVERLAY-Layer über den Screen
/// =======================================================
class OverlayNumericKeypadHost extends StatefulWidget {
  final OverlayNumericKeypadController controller;
  final Widget child;
  final NumericKeypadTheme theme;

  const OverlayNumericKeypadHost({
    super.key,
    required this.controller,
    required this.child,
    this.theme = const NumericKeypadTheme(),
  });

  @override
  State<OverlayNumericKeypadHost> createState() => _OverlayNumericKeypadHostState();
}

class _OverlayNumericKeypadHostState extends State<OverlayNumericKeypadHost> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_rebuild);
  }

  @override
  void didUpdateWidget(covariant OverlayNumericKeypadHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_rebuild);
      widget.controller.addListener(_rebuild);
    }
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keypad = widget.controller.isOpen
        ? OverlayNumericKeypad(controller: widget.controller, theme: widget.theme)
        : const SizedBox.shrink();

    // WICHTIG: Stack → Overlay; keine Abdunklung, kein Content-Shift
    return Stack(
      children: [
        widget.child,
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
  }
}

/// ======================================
/// KEYPAD: Grid + Action-Rail (Overlay)
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
    final media = MediaQuery.of(context);
    final safeBottom = media.viewPadding.bottom;
    final maxH = math.min(media.size.height * theme.heightFraction, theme.maxHeight);

    return SafeArea(
      top: false,
      bottom: true,
      child: Container(
        decoration: BoxDecoration(
          color: theme.sheetBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(theme.corner)),
          boxShadow: const [BoxShadow(blurRadius: 12, color: Colors.black54)],
        ),
        constraints: BoxConstraints(maxHeight: maxH + safeBottom),
        child: LayoutBuilder(
          builder: (context, c) {
            final gap = theme.gap;
            const cols = 3, rows = 4;

            // Rail-Breite ≈ Key-Seite; Startwert
            final railGuess = 56.0;

            final availableW = c.maxWidth - railGuess - (cols + 1) * gap;
            final availableH = c.maxHeight - safeBottom - (rows + 1) * gap;

            final keySideFromW = availableW / cols;
            final keySideFromH = availableH / rows;
            final keySide = math.max(theme.minKeySide, math.min(keySideFromW, keySideFromH));
            final railW = math.max(theme.minKeySide, keySide); // Rail an Key-Breite koppeln

            return Padding(
              padding: EdgeInsets.fromLTRB(gap, gap, gap, gap),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // 3×4 Grid
                  Expanded(
                    child: _KeyGrid(
                      keySide: keySide,
                      gap: gap,
                      allowDecimal: controller.allowDecimal,
                      onKey: (t) => _applyToken(controller, t),
                    ),
                  ),
                  SizedBox(width: gap),
                  // Action‑Rail
                  ConstrainedBox(
                    constraints: BoxConstraints.tightFor(width: railW),
                    child: _ActionRail(
                      size: keySide,
                      theme: theme,
                      onHide: controller.close,
                      onPaste: () async {
                        final data = await Clipboard.getData('text/plain');
                        if (data?.text != null) _pasteInto(controller, data!.text!);
                      },
                      onCopy: () {
                        Clipboard.setData(ClipboardData(text: controller.target?.text ?? ''));
                        HapticFeedback.lightImpact();
                      },
                      onPlus: () => _increment(controller, +1),
                      onMinus: () => _increment(controller, -1),
                      onBackspace: () => _applyToken(controller, 'del'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  static void _pasteInto(OverlayNumericKeypadController ctl, String text) {
    final t = ctl.target;
    if (t == null) return;
    final cleaned = ctl.allowDecimal
        ? text.trim().replaceAll(',', '.').replaceAll(RegExp(r'[^0-9.]'), '')
        : text.replaceAll(RegExp(r'[^0-9]'), '');
    final parts = cleaned.split('.');
    final normalized = ctl.allowDecimal && parts.length > 1
        ? '${parts[0]}.${parts.sublist(1).join()}'
        : cleaned;
    t.value = TextEditingValue(text: normalized, selection: TextSelection.collapsed(offset: normalized.length));
  }

  static void _applyToken(OverlayNumericKeypadController ctl, String token) {
    final t = ctl.target;
    if (t == null) return;

    String v = t.text;
    if (token == 'del') {
      if (v.isNotEmpty) v = v.substring(0, v.length - 1);
    } else if (token == '.') {
      if (!ctl.allowDecimal) return;
      if (!v.contains('.')) v += '.';
    } else if (RegExp(r'^[0-9]$').hasMatch(token)) {
      v += token;
    } else {
      // Unbekanntes Token: ignorieren
      return;
    }
    t.value = TextEditingValue(text: v, selection: TextSelection.collapsed(offset: v.length));
    HapticFeedback.selectionClick();
  }

  static void _increment(OverlayNumericKeypadController ctl, int direction) {
    final t = ctl.target;
    if (t == null) return;

    final raw = t.text.replaceAll(',', '.');
    final step = ctl.allowDecimal ? ctl.decimalStep : ctl.integerStep;

    double current = 0;
    if (raw.isNotEmpty) {
      current = double.tryParse(raw) ?? 0;
    }
    final next = current + (step * direction);
    final value = ctl.allowDecimal ? next.toStringAsFixed(2) : next.round().toString();

    t.value = TextEditingValue(text: value, selection: TextSelection.collapsed(offset: value.length));
    HapticFeedback.selectionClick();
  }
}

/// ===============================
/// GRID (3×4) – responsiv
/// ===============================
class _KeyGrid extends StatelessWidget {
  final double keySide;
  final double gap;
  final bool allowDecimal;
  final ValueChanged<String> onKey;

  const _KeyGrid({
    required this.keySide,
    required this.gap,
    required this.allowDecimal,
    required this.onKey,
  });

  @override
  Widget build(BuildContext context) {
    final items = <_KeySpec>[
      for (final n in ['1','2','3','4','5','6','7','8','9']) _KeySpec(token: n, label: n),
      _KeySpec(token: allowDecimal ? '.' : '_', label: allowDecimal ? '.' : '', disabled: !allowDecimal),
      _KeySpec(token: '0', label: '0'),
      _KeySpec(token: 'del', icon: Icons.backspace_outlined),
    ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final k = items[i];
        return _KeyButton(
          side: keySide,
          label: k.label,
          icon: k.icon,
          disabled: k.disabled,
          repeat: k.token == 'del',
          onTap: k.disabled ? null : () => onKey(k.token),
        );
      },
    );
  }
}

class _KeySpec {
  final String token;
  final String label;
  final bool disabled;
  final IconData? icon;

  _KeySpec({required this.token, this.label = '', this.disabled = false, this.icon});
}

/// ===============================
/// ACTION‑RAIL (vertikal)
/// ===============================
class _ActionRail extends StatelessWidget {
  final double size;
  final NumericKeypadTheme theme;
  final VoidCallback onHide, onPaste, onCopy, onPlus, onMinus, onBackspace;

  const _ActionRail({
    required this.size,
    required this.theme,
    required this.onHide,
    required this.onPaste,
    required this.onCopy,
    required this.onPlus,
    required this.onMinus,
    required this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      _RailBtn(icon: Icons.keyboard_hide_rounded, onTap: onHide, side: size),
      _RailBtn(icon: Icons.backspace_outlined, onTap: onBackspace, side: size, repeat: true),
      _RailBtn(icon: Icons.paste_rounded, onTap: onPaste, side: size),
      _RailBtn(icon: Icons.copy_rounded, onTap: onCopy, side: size),
      _RailBtn(icon: Icons.add_rounded, onTap: onPlus, side: size, repeat: true),
      _RailBtn(icon: Icons.remove_rounded, onTap: onMinus, side: size, repeat: true),
    ];

    return Container(
      decoration: BoxDecoration(
        color: theme.railBg,
        borderRadius: BorderRadius.only(topRight: Radius.circular(theme.corner)),
      ),
      child: Column(children: items.map((w) => Expanded(child: w)).toList()),
    );
  }
}

class _RailBtn extends StatefulWidget {
  final IconData icon;
  final double side;
  final VoidCallback onTap;
  final bool repeat;

  const _RailBtn({required this.icon, required this.side, required this.onTap, this.repeat = false});

  @override
  State<_RailBtn> createState() => _RailBtnState();
}

class _RailBtnState extends State<_RailBtn> {
  Timer? _timer;

  void _start() {
    widget.onTap();
    if (!widget.repeat) return;
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 260), () {
      _timer = Timer.periodic(const Duration(milliseconds: 70), (_) => widget.onTap());
    });
  }

  void _stop() { _timer?.cancel(); _timer = null; }

  @override
  void dispose() { _stop(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final th = const NumericKeypadTheme();
    return GestureDetector(
      onTapDown: (_) => _start(),
      onTapUp: (_) => _stop(),
      onTapCancel: _stop,
      child: SizedBox(
        width: widget.side,
        height: widget.side,
        child: Center(child: Icon(widget.icon, color: th.railIcon)),
      ),
    );
  }
}

/// ===============================
/// KEY BUTTON (responsiv)
/// ===============================
class _KeyButton extends StatefulWidget {
  final double side;
  final String? label;
  final IconData? icon;
  final bool disabled;
  final bool repeat;
  final VoidCallback? onTap;

  const _KeyButton({
    required this.side,
    this.label,
    this.icon,
    this.disabled = false,
    this.repeat = false,
    this.onTap,
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
      _timer = Timer.periodic(const Duration(milliseconds: 70), (_) => widget.onTap!.call());
    });
  }

  void _stop() { _timer?.cancel(); _timer = null; }

  @override
  void dispose() { _stop(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final th = const NumericKeypadTheme();
    final side = math.max(th.minKeySide, widget.side);

    final child = FittedBox(
      fit: BoxFit.scaleDown,
      child: widget.icon != null
          ? Icon(widget.icon, color: th.keyFg)
          : Text(
              widget.label ?? '',
              style: TextStyle(color: th.keyFg, fontWeight: FontWeight.w600, fontSize: side * 0.36),
            ),
    );

    return GestureDetector(
      onTapDown: (_) => _start(),
      onTapUp: (_) => _stop(),
      onTapCancel: _stop,
      child: Container(
        width: side,
        height: side,
        decoration: BoxDecoration(color: widget.disabled ? th.keyBg.withOpacity(0.5) : th.keyBg, borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}
