import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ============================
/// Public API
/// ============================

Future<void> showNumericKeypadSheet({
  required BuildContext context,
  required TextEditingController controller,
  bool allowDecimal = true,
  ValueChanged<String>? onChanged,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _NumericKeypadSheet(
      controller: controller,
      allowDecimal: allowDecimal,
      onChanged: onChanged,
      theme: const NumericKeypadTheme(),
    ),
  );
}

/// Theme tokens – passe Farben bei Bedarf an.
class NumericKeypadTheme {
  final double cornerRadius;
  final double gap;
  final double maxHeightPx;
  final double maxHeightFraction;
  final Color sheetBg;
  final Color keyBg;
  final Color keyFg;
  final Color railBg;
  final Color railIcon;
  final Color keyBgPressed;

  const NumericKeypadTheme({
    this.cornerRadius = 16,
    this.gap = 6,
    this.maxHeightPx = 210,
    this.maxHeightFraction = 0.19,
    this.sheetBg = const Color(0xFF121212),
    this.keyBg = const Color(0xFF1E1E1E),
    this.keyFg = Colors.white,
    this.railBg = const Color(0xFF0F0F0F),
    this.railIcon = Colors.white70,
    this.keyBgPressed = const Color(0xFF2A2A2A),
  });
}

/// ============================
/// Sheet with Grid + ActionRail
/// ============================
class _NumericKeypadSheet extends StatefulWidget {
  final TextEditingController controller;
  final bool allowDecimal;
  final ValueChanged<String>? onChanged;
  final NumericKeypadTheme theme;

  const _NumericKeypadSheet({
    required this.controller,
    required this.allowDecimal,
    required this.onChanged,
    required this.theme,
  });

  @override
  State<_NumericKeypadSheet> createState() => _NumericKeypadSheetState();
}

class _NumericKeypadSheetState extends State<_NumericKeypadSheet> {
  late String _value;

  @override
  void initState() {
    super.initState();
    _value = widget.controller.text;
  }

  void _emitChanged() {
    widget.controller.value = TextEditingValue(
      text: _value,
      selection: TextSelection.collapsed(offset: _value.length),
    );
    widget.onChanged?.call(_value);
    HapticFeedback.selectionClick();
  }

  void _tap(String token) {
    if (token == 'del') {
      if (_value.isNotEmpty) {
        _value = _value.substring(0, _value.length - 1);
        _emitChanged();
      }
      return;
    }
    if (token == '.' && !widget.allowDecimal) return;
    if (token == '.' && _value.contains('.')) return;
    if (token == '+' || token == '-') {
      // Optional: einfache arithmische Hilfe – hier nur Anhängen eines Zeichens vermeiden
      return;
    }
    _value += token;
    _emitChanged();
  }

  void _paste() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text == null) return;
    final text = data!.text!.trim().replaceAll(',', '.');
    if (!widget.allowDecimal) {
      final onlyDigits = text.replaceAll(RegExp(r'[^0-9]'), '');
      _value = onlyDigits;
    } else {
      final filtered = text.replaceAll(RegExp(r'[^0-9\.]'), '');
      final parts = filtered.split('.');
      _value = parts.length > 1 ? '${parts[0]}.${parts.sublist(1).join()}' : filtered;
    }
    _emitChanged();
  }

  void _copy() {
    Clipboard.setData(ClipboardData(text: _value));
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    final media = MediaQuery.of(context);
    final safeBottom = media.viewPadding.bottom;

    final maxSheetHeight = math.min(
      media.size.height * t.maxHeightFraction,
      t.maxHeightPx,
    );

    return SafeArea(
      top: false,
      bottom: true,
      child: Padding(
        padding: EdgeInsets.only(bottom: safeBottom),
        child: Container(
          decoration: BoxDecoration(
            color: t.sheetBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(t.cornerRadius)),
            boxShadow: const [BoxShadow(blurRadius: 12, color: Colors.black54)],
          ),
          constraints: BoxConstraints(maxHeight: maxSheetHeight),
          child: LayoutBuilder(
            builder: (context, c) {
              // Höhe für Grid/Row berechnen
              final gap = t.gap;
              final availableH = c.maxHeight - gap * 2;
              // Mindest-Key-Kante 40px, rail so breit wie Key-Kante
              final cols = 3;
              final rows = 4;

              // Breite fürs Grid (abzgl. Rail)
              final railWidthTarget = 64.0; // Startwert, wird unten an keySide gekoppelt
              final gridAreaW = c.maxWidth - railWidthTarget - gap * 3;

              final fromWidth = (gridAreaW / cols) - gap;
              final fromHeight = (availableH / rows) - gap;
              final keySide = math.max(40.0, math.min(fromWidth, fromHeight));
              final railW = math.max(48.0, keySide); // Rail ≈ Key‑Breite

              return Padding(
                padding: EdgeInsets.all(gap),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 3x4 Grid
                    Expanded(
                      child: _KeyGrid(
                        keySide: keySide,
                        gap: gap,
                        allowDecimal: widget.allowDecimal,
                        onPressed: _tap,
                      ),
                    ),
                    SizedBox(width: gap),
                    // Action Rail
                    ConstrainedBox(
                      constraints: BoxConstraints(minWidth: railW, maxWidth: railW),
                      child: _ActionRail(
                        keySide: keySide,
                        theme: t,
                        onHide: () => Navigator.of(context).maybePop(),
                        onPaste: _paste,
                        onCopy: _copy,
                        onPlus: () => _tap('+'),
                        onMinus: () => _tap('-'),
                        onBackspace: () => _tap('del'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// ============================
/// Grid (3x4)
/// ============================
class _KeyGrid extends StatelessWidget {
  final double keySide;
  final double gap;
  final bool allowDecimal;
  final ValueChanged<String> onPressed;

  const _KeyGrid({
    required this.keySide,
    required this.gap,
    required this.allowDecimal,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final keys = <_KeySpec>[
      for (final n in ['1','2','3','4','5','6','7','8','9']) _KeySpec(label: n, token: n),
      _KeySpec(label: allowDecimal ? '.' : '', token: allowDecimal ? '.' : '', disabled: !allowDecimal),
      _KeySpec(label: '0', token: '0'),
      _KeySpec(icon: Icons.backspace_outlined, token: 'del', isIcon: true),
    ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemCount: keys.length,
      itemBuilder: (_, i) {
        final spec = keys[i];
        return _KeyButton(
          keySide: keySide,
          label: spec.label,
          icon: spec.isIcon ? spec.icon : null,
          disabled: spec.disabled,
          onTap: spec.disabled ? null : () => onPressed(spec.token),
          repeat: spec.token == 'del' ? true : false,
        );
      },
      padding: EdgeInsets.zero,
    );
  }
}

class _KeySpec {
  final String label;
  final String token;
  final bool disabled;
  final bool isIcon;
  final IconData icon;

  _KeySpec({
    this.label = '',
    required this.token,
    this.disabled = false,
    this.isIcon = false,
    this.icon = Icons.circle,
  });
}

/// ============================
/// Action Rail (vertikal)
/// ============================
class _ActionRail extends StatelessWidget {
  final double keySide;
  final NumericKeypadTheme theme;
  final VoidCallback onHide;
  final VoidCallback onPaste;
  final VoidCallback onCopy;
  final VoidCallback onPlus;
  final VoidCallback onMinus;
  final VoidCallback onBackspace;

  const _ActionRail({
    required this.keySide,
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
      _RailIconButton(icon: Icons.keyboard_hide_rounded, onTap: onHide, size: keySide, color: theme.railIcon),
      _RailIconButton(icon: Icons.keyboard_return_rounded, onTap: onBackspace, size: keySide, color: theme.railIcon),
      _RailIconButton(icon: Icons.paste_rounded, onTap: onPaste, size: keySide, color: theme.railIcon),
      _RailIconButton(icon: Icons.copy_rounded, onTap: onCopy, size: keySide, color: theme.railIcon),
      _RailIconButton(icon: Icons.add_rounded, onTap: onPlus, size: keySide, color: theme.railIcon, repeat: true),
      _RailIconButton(icon: Icons.remove_rounded, onTap: onMinus, size: keySide, color: theme.railIcon, repeat: true),
    ];

    return Container(
      decoration: BoxDecoration(
        color: theme.railBg,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(theme.cornerRadius),
          bottomRight: Radius.circular(theme.cornerRadius),
        ),
      ),
      child: Column(
        children: [
          for (final w in items) Expanded(child: w),
        ],
      ),
    );
  }
}

class _RailIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool repeat;
  final double size;
  final Color color;

  const _RailIconButton({
    required this.icon,
    required this.onTap,
    required this.size,
    required this.color,
    this.repeat = false,
  });

  @override
  Widget build(BuildContext context) {
    return _KeyButton(
      keySide: size,
      icon: icon,
      onTap: onTap,
      repeat: repeat,
    );
  }
}

/// ============================
/// Key Button (responsive)
/// ============================
class _KeyButton extends StatefulWidget {
  final double keySide;
  final String? label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool repeat;
  final bool disabled;

  const _KeyButton({
    required this.keySide,
    this.label,
    this.icon,
    this.onTap,
    this.repeat = false,
    this.disabled = false,
  });

  @override
  State<_KeyButton> createState() => _KeyButtonState();
}

class _KeyButtonState extends State<_KeyButton> {
  Timer? _timer;

  void _startRepeat() {
    if (!widget.repeat || widget.onTap == null) return;
    // kleiner Delay, dann schnell wiederholen
    _timer?.cancel();
    widget.onTap!.call();
    _timer = Timer(const Duration(milliseconds: 280), () {
      _timer = Timer.periodic(const Duration(milliseconds: 70), (_) {
        widget.onTap!.call();
      });
    });
  }

  void _stopRepeat() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopRepeat();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = const NumericKeypadTheme();
    final minSide = math.max(40.0, widget.keySide);

    final child = Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: widget.icon != null
            ? Icon(widget.icon, color: theme.keyFg)
            : Text(
                widget.label ?? '',
                style: TextStyle(
                  color: theme.keyFg,
                  fontWeight: FontWeight.w600,
                  fontSize: minSide * 0.38, // skaliert mit Feldgröße
                ),
              ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(0),
      child: GestureDetector(
        onTapDown: (_) {
          if (widget.disabled) return;
          _startRepeat();
        },
        onTapUp: (_) => _stopRepeat(),
        onTapCancel: _stopRepeat,
        onTap: widget.disabled ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          margin: const EdgeInsets.all(0),
          decoration: BoxDecoration(
            color: widget.disabled ? theme.keyBg.withOpacity(0.5) : theme.keyBg,
            borderRadius: BorderRadius.circular(12),
          ),
          width: minSide,
          height: minSide,
          child: child,
        ),
      ),
    );
  }
}
