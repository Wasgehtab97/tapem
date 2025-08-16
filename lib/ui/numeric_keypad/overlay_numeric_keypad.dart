// lib/ui/numeric_keypad/overlay_numeric_keypad.dart
// Geometry-driven numeric keypad with de-duped height notifications + logging.

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void _klog(String m) => debugPrint('🔢 [Keypad] $m');

// Simple routing registry for numeric keypad targets.
enum KeypadTargetType { numeric, plus, text }

class KeypadTarget {
  final String id;
  final FocusNode? focusNode;
  final TextEditingController? controller;
  final bool allowDecimal;
  final double? decimalStep;
  final double? integerStep;
  final GlobalKey? key;
  final VoidCallback? onPressed;
  final KeypadTargetType type;

  KeypadTarget({
    required this.id,
    this.focusNode,
    this.controller,
    this.allowDecimal = true,
    this.decimalStep,
    this.integerStep,
    this.key,
    this.onPressed,
    required this.type,
  });
}

class KeypadTargetRegistry {
  static final _targets = <String, KeypadTarget>{};

  static void register(KeypadTarget t) {
    _targets.remove(t.id);
    _targets[t.id] = t;
  }

  static void unregister(String id) {
    _targets.remove(id);
  }

  static Iterable<KeypadTarget> get targets => _targets.values;
}

class NumericKeypadTheme {
  final double gap;
  final double corner;
  final double minKeySide;
  final double minFrac;
  final double maxFrac;
  final double heightScale;

  final Color sheetBg;
  final Color keyBg;
  final Color keyFg;
  final Color railBg;
  final Color railIcon;
  final Color press;

  const NumericKeypadTheme({
    this.gap = 12.0,
    this.corner = 18.0,
    this.minKeySide = 44.0,
    this.minFrac = 0.28,
    this.maxFrac = 0.45,
    this.heightScale = 0.5,
    this.sheetBg = const Color(0xFF0F1012),
    this.keyBg = const Color(0xFF1A1D21),
    this.keyFg = Colors.white,
    this.railBg = const Color(0xFF14171A),
    this.railIcon = Colors.white70,
    this.press = const Color(0xFF2A2E33),
  });
}

class OverlayNumericKeypadController extends ChangeNotifier {
  TextEditingController? _target;
  bool _isOpen = false;
  bool allowDecimal = true;
  double decimalStep = 2.5;
  double integerStep = 1.0;
  double _contentHeight = 0.0;
  bool _pendingHeightNotify = false;

  bool get isOpen => _isOpen;
  TextEditingController? get target => _target;
  double get keypadContentHeight => _isOpen ? _contentHeight : 0.0;

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

    if (!_isOpen) {
      _isOpen = true;
      _klog(
        'openFor(tc#${controller.hashCode.toRadixString(16)} allowDecimal=$allowDecimal stepDec=$decimalStep stepInt=$integerStep text="${controller.text}")',
      );
      notifyListeners();
    } else {
      _klog(
        'retarget(tc#${controller.hashCode.toRadixString(16)} allowDecimal=$allowDecimal text="${controller.text}")',
      );
    }
  }

  void close() {
    if (!_isOpen) return;
    _isOpen = false;
    _contentHeight = 0.0;
    _klog('close()');
    notifyListeners();
  }

  void _updateContentHeight(double height) {
    if ((_contentHeight - height).abs() <= 0.5) return;
    _contentHeight = height;

    if (_pendingHeightNotify) return;
    _pendingHeightNotify = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pendingHeightNotify = false;
      if (_isOpen) {
        _klog('contentHeight=$_contentHeight');
        notifyListeners();
      }
    });
  }
}

class OverlayNumericKeypadHost extends StatefulWidget {
  final OverlayNumericKeypadController controller;
  final Widget child;
  final NumericKeypadTheme theme;
  final bool interceptAndroidBack;

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
  final _keypadKey = GlobalKey();
  final _childKey = GlobalKey();

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
    final keypad =
        widget.controller.isOpen
            ? OverlayNumericKeypad(
              key: _keypadKey,
              controller: widget.controller,
              theme: widget.theme,
            )
            : const SizedBox.shrink();

    Widget result = Stack(
      children: [
        KeyedSubtree(key: _childKey, child: widget.child),
        if (widget.controller.isOpen)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: _handleTap,
              child: const SizedBox.expand(),
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

  Rect? _rectForTarget(KeypadTarget t) {
    RenderBox? box;
    if (t.key != null) {
      box = t.key!.currentContext?.findRenderObject() as RenderBox?;
    } else if (t.focusNode?.context != null) {
      box = t.focusNode!.context!.findRenderObject() as RenderBox?;
    }
    if (box == null) return null;
    final offset = box.localToGlobal(Offset.zero);
    return offset & box.size;
  }

  void _handleTap(TapUpDetails event) {
    final pos = event.globalPosition;
    final keypadBox = _keypadKey.currentContext?.findRenderObject() as RenderBox?;
    final keypadRect =
        keypadBox == null ? Rect.zero : keypadBox.localToGlobal(Offset.zero) & keypadBox.size;
    if (keypadRect.contains(pos)) {
      _klog('KEYPAD_ROUTER tap at=${pos.dx},${pos.dy} hit=keypad action=ignore');
      return;
    }

    for (final t in KeypadTargetRegistry.targets.toList().reversed) {
      final rect = _rectForTarget(t);
      if (rect != null && rect.contains(pos)) {
        switch (t.type) {
          case KeypadTargetType.numeric:
            widget.controller.openFor(
              t.controller!,
              allowDecimal: t.allowDecimal,
              decimalStep: t.decimalStep,
              integerStep: t.integerStep,
            );
            t.focusNode?.requestFocus();
            final ctx = t.focusNode?.context;
            if (ctx != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Scrollable.ensureVisible(ctx,
                    alignment: 0.5,
                    duration: const Duration(milliseconds: 200));
              });
            }
            _klog('KEYPAD_ROUTER tap at=${pos.dx},${pos.dy} hit=numeric:${t.id} action=retarget');
            return;
          case KeypadTargetType.plus:
            t.onPressed?.call();
            _klog('KEYPAD_ROUTER tap at=${pos.dx},${pos.dy} hit=plus:${t.id} action=addDrop');
            return;
          case KeypadTargetType.text:
            widget.controller.close();
            t.focusNode?.requestFocus();
            _klog('KEYPAD_ROUTER tap at=${pos.dx},${pos.dy} hit=text:${t.id} action=dismiss');
            return;
        }
      }
    }
    widget.controller.close();
    _klog('KEYPAD_ROUTER tap at=${pos.dx},${pos.dy} hit=none action=dismiss');
  }
}

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

    final safeBottom = math.max(media.viewPadding.bottom, media.padding.bottom);

    final size = media.size;
    final gap = theme.gap;

    final cellW = (size.width - 3 * gap) / 4.0;
    final idealGridH = 4 * cellW + 3 * gap;

    final minH = size.height * theme.minFrac;
    final maxH = size.height * theme.maxFrac;
    final baseH = idealGridH.clamp(minH, maxH);
    final scaledH = baseH * theme.heightScale;
    final minFitH = theme.minKeySide * 4 + 3 * gap;
    final contentH = math.max(minFitH, scaledH);

    final innerH = contentH - (gap + gap);
    controller._updateContentHeight(contentH);

    final cellH = (innerH - 3 * gap) / 4.0;
    final aspect = cellW / cellH;

    final enforcedCellW = math.max(theme.minKeySide, cellW);
    final enforcedCellH = math.max(theme.minKeySide, cellH);
    final railW = enforcedCellW;

    final barHeight = contentH + safeBottom;
    final decLabel = _decimalChar(context);

    _klog(
      'build() size=${size.width}x${size.height} safeBottom=$safeBottom contentH=$contentH innerH=$innerH allowDecimal=${controller.allowDecimal}',
    );

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
            padding: EdgeInsets.fromLTRB(gap, gap, gap, gap + safeBottom),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                        _klog('paste "${data!.text}"');
                        _pasteInto(context, controller, data.text!);
                        _haptic(context);
                      }
                    },
                    onCopy: () {
                      final text = controller.target?.text ?? '';
                      _klog('copy "$text"');
                      Clipboard.setData(ClipboardData(text: text));
                      _haptic(context);
                    },
                    onPlus: () => _increment(context, controller, 1),
                    onMinus: () => _increment(context, controller, -1),
                    onDone: controller.close,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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

  static void _pasteInto(
    BuildContext ctx,
    OverlayNumericKeypadController ctl,
    String text,
  ) {
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
    final display =
        ctl.allowDecimal
            ? normalized.replaceAll('.', _decimalChar(ctx))
            : normalized;
    t.value = TextEditingValue(
      text: display,
      selection: TextSelection.collapsed(offset: display.length),
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
      if (!(v.contains('.') || v.contains(','))) {
        v += _decimalChar(ctx);
      }
    } else if (RegExp(r'^[0-9]$').hasMatch(token)) {
      v += token;
    } else {
      return;
    }
    _klog(
      'key token="$token" tc#${t.hashCode.toRadixString(16)}: "${t.text}" → "$v"',
    );
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
    final rawValue =
        ctl.allowDecimal ? next.toStringAsFixed(2) : next.round().toString();
    final value =
        ctl.allowDecimal
            ? rawValue.replaceAll('.', _decimalChar(ctx))
            : rawValue;

    _klog(
      '${direction > 0 ? 'plus' : 'minus'} step=$step from="$raw" → "$value"',
    );
    t.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    _haptic(ctx);
  }
}

class _KeyGrid extends StatelessWidget {
  final double aspect;
  final double gap;
  final bool allowDecimal;
  final String decimalLabel;
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

class _ActionRailCompact extends StatelessWidget {
  final double gridCellWidth;
  final double gridCellHeight;
  final int totalGridRows;
  final double gap;
  final NumericKeypadTheme theme;
  final VoidCallback onHide, onPaste, onCopy, onPlus, onMinus, onDone;

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
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final availableH =
        totalGridRows * gridCellHeight + (totalGridRows - 1) * gap;

    final actions = <_RailAction>[
      _RailAction(Icons.copy_rounded, 'Kopieren', onCopy),
      _RailAction(Icons.paste_rounded, 'Einfügen', onPaste),
      _RailAction(Icons.remove_rounded, 'Verringern', onMinus, repeat: true),
      _RailAction(Icons.add_rounded, 'Erhöhen', onPlus, repeat: true),
      _RailAction(Icons.done_rounded, 'Fertig', onDone),
      _RailAction(Icons.keyboard_hide_rounded, 'Tastatur ausblenden', onHide),
    ];

    final rowsNeeded = (actions.length / 2).ceil();
    final totalRowGaps = math.max(0, rowsNeeded - 1);

    final sideV = (availableH - totalRowGaps * gap) / rowsNeeded;
    final sideH = (gridCellWidth - gap) / 2;
    final side = math.max(28.0, math.min(sideV, sideH)).floorToDouble();

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
      color: theme.sheetBg,
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

class _RailBtnSquare extends StatefulWidget {
  final double side;
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
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: th.keyBg,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: FittedBox(child: Icon(widget.icon, color: th.railIcon)),
        ),
      ),
    );
  }
}

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
