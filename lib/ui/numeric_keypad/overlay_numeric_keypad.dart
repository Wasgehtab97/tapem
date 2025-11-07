// lib/ui/numeric_keypad/overlay_numeric_keypad.dart
// Geometry-driven numeric keypad with de-duped height notifications + logging.

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/logging/elog.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/core/providers/device_provider.dart';
import 'package:tapem/features/device/presentation/controllers/workout_day_controller.dart';

void _klog(String m) => debugPrint('🔢 [Keypad] $m');

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

  factory NumericKeypadTheme.fromContext(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final brand = theme.extension<AppBrandTheme>();

    Color tintTowards(Color source, Color target, double amount) {
      return Color.lerp(source, target, amount) ?? source;
    }

    Color adjustForeground(Color foreground, Color background) {
      final brightness = ThemeData.estimateBrightnessForColor(background);
      final lum = foreground.computeLuminance();
      if (brightness == Brightness.dark && lum < 0.35) {
        return tintTowards(foreground, Colors.white, 0.35);
      }
      if (brightness == Brightness.light && lum > 0.65) {
        return tintTowards(foreground, Colors.black, 0.4);
      }
      return foreground;
    }

    final gradientColors = brand?.gradient.colors ?? const <Color>[];
    final accentBase =
        gradientColors.isNotEmpty ? gradientColors.last : scheme.secondary;
    final accent = accentBase.computeLuminance() < 0.08
        ? scheme.primary
        : accentBase;

    const sheetBase = Colors.black;
    const keyBase = Colors.black;
    const railBase = Colors.black;

    const sheetBg = sheetBase;
    const keyBg = keyBase;
    const railBg = railBase;

    final keyFg = adjustForeground(accent, keyBg);
    final railIcon = adjustForeground(accent, railBg);
    final press = brand?.pressedOverlay ??
        accent.withOpacity(0.2);

    return NumericKeypadTheme(
      sheetBg: sheetBg,
      keyBg: keyBg,
      keyFg: keyFg,
      railBg: railBg,
      railIcon: railIcon,
      press: press,
    );
  }
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

enum OutsideTapMode { none, closeAfterTap }

class OverlayNumericKeypadHost extends StatefulWidget {
  final OverlayNumericKeypadController controller;
  final Widget child;
  final NumericKeypadTheme? theme;
  final bool interceptAndroidBack;
  final OutsideTapMode outsideTapMode;

  const OverlayNumericKeypadHost({
    super.key,
    required this.controller,
    required this.child,
    this.theme,
    this.interceptAndroidBack = true,
    this.outsideTapMode = OutsideTapMode.none,
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

  void _rebuild() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final keypad = widget.controller.isOpen
        ? OverlayNumericKeypad(
            key: _keypadKey,
            controller: widget.controller,
            theme: widget.theme ?? NumericKeypadTheme.fromContext(context),
          )
        : const SizedBox.shrink();

    Widget result = Stack(
      children: [
        KeyedSubtree(key: _childKey, child: widget.child),
        if (widget.controller.isOpen &&
            widget.outsideTapMode != OutsideTapMode.none)
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerUp: (event) {
                final keypadBox =
                    _keypadKey.currentContext?.findRenderObject() as RenderBox?;
                final keypadRect = keypadBox == null
                    ? Rect.zero
                    : keypadBox.localToGlobal(Offset.zero) & keypadBox.size;
                final inside = keypadRect.contains(event.position);
                _klog(
                  'outsideTap up at ${event.position} insideKeypad=$inside',
                );
                if (widget.outsideTapMode == OutsideTapMode.closeAfterTap &&
                    !inside) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) widget.controller.close();
                  });
                }
              },
              child: const IgnorePointer(
                ignoring: true,
                child: SizedBox.expand(),
              ),
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
                    onHide: () {
                      context
                          .read<WorkoutDayController>()
                          .focusedProvider
                          ?.clearFocus();
                      controller.close();
                    },
                    onNavigate: () => _navigateNext(context, controller),
                    onNavigateBack: () => _navigatePrevious(context, controller),
                    onAddSet: () => _addSet(context),
                    onDuplicate: () => _duplicateFromPrevious(context, controller),
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

  static DeviceProvider? _activeProvider(BuildContext context) {
    return context.read<WorkoutDayController>().focusedProvider;
  }

  static void _navigateNext(
    BuildContext context,
    OverlayNumericKeypadController controller,
  ) {
    final prov = _activeProvider(context);
    if (prov == null) {
      _haptic(context);
      return;
    }
    final focusedIndex = prov.focusedIndex;
    final focusedField = prov.focusedField;

    elogUi('OVERLAY_NAVIGATE_NEXT', {
      'deviceId': prov.device?.uid,
      'focusedIndex': focusedIndex,
      'focusedField': focusedField?.name,
    });

    if (focusedIndex == null || focusedField == null) {
      _haptic(context);
      return;
    }

    final dropIndex = prov.focusedDropIndex ?? 0;
    final targetController = controller.target;
    if (targetController != null) {
      final text = targetController.text;
      switch (focusedField) {
        case DeviceSetFieldFocus.weight:
          prov.updateSet(focusedIndex, weight: text);
          break;
        case DeviceSetFieldFocus.reps:
          prov.updateSet(focusedIndex, reps: text);
          break;
        case DeviceSetFieldFocus.dropWeight:
          prov.updateDrop(focusedIndex, dropIndex, weight: text);
          break;
        case DeviceSetFieldFocus.dropReps:
          prov.updateDrop(focusedIndex, dropIndex, reps: text);
          break;
      }
    }

    int targetIndex = focusedIndex;
    late final DeviceSetFieldFocus targetField;
    int? targetDropIndex;

    switch (focusedField) {
      case DeviceSetFieldFocus.weight:
        targetField = DeviceSetFieldFocus.reps;
        break;
      case DeviceSetFieldFocus.reps:
        final done = prov.markSetDone(focusedIndex);
        if (!done) {
          elogUi('OVERLAY_NAVIGATE_BLOCKED', {
            'reason': 'invalid_set',
            'index': focusedIndex,
          });
          _haptic(context);
          return;
        }
        final nextIndex = prov.nextPendingSetIndex(focusedIndex);
        if (nextIndex != null) {
          targetIndex = nextIndex;
          targetField = DeviceSetFieldFocus.weight;
        } else {
          prov.clearFocus();
          controller.close();
          elogUi('OVERLAY_NAVIGATE_CLOSE', {'reason': 'all_sets_completed'});
          _haptic(context);
          return;
        }
        break;
      case DeviceSetFieldFocus.dropWeight:
        targetField = DeviceSetFieldFocus.dropReps;
        targetDropIndex = dropIndex;
        break;
      case DeviceSetFieldFocus.dropReps:
        final done = prov.markSetDone(focusedIndex);
        if (!done) {
          elogUi('OVERLAY_NAVIGATE_BLOCKED', {
            'reason': 'invalid_set',
            'index': focusedIndex,
          });
          _haptic(context);
          return;
        }
        final nextIndex = prov.nextPendingSetIndex(focusedIndex);
        if (nextIndex != null) {
          targetIndex = nextIndex;
          targetField = DeviceSetFieldFocus.weight;
        } else {
          prov.clearFocus();
          controller.close();
          elogUi('OVERLAY_NAVIGATE_CLOSE', {'reason': 'all_sets_completed'});
          _haptic(context);
          return;
        }
        break;
    }

    prov.requestFocus(
      index: targetIndex,
      field: targetField,
      dropIndex: targetDropIndex,
    );

    _haptic(context);
  }

  static void _navigatePrevious(
    BuildContext context,
    OverlayNumericKeypadController controller,
  ) {
    final prov = _activeProvider(context);
    if (prov == null) {
      _haptic(context);
      return;
    }
    final focusedIndex = prov.focusedIndex;
    final focusedField = prov.focusedField;

    elogUi('OVERLAY_NAVIGATE_PREVIOUS', {
      'deviceId': prov.device?.uid,
      'focusedIndex': focusedIndex,
      'focusedField': focusedField?.name,
    });

    if (focusedIndex == null || focusedField == null) {
      _haptic(context);
      return;
    }

    final dropIndex = prov.focusedDropIndex ?? 0;
    final targetController = controller.target;
    if (targetController != null) {
      final text = targetController.text;
      switch (focusedField) {
        case DeviceSetFieldFocus.weight:
          prov.updateSet(focusedIndex, weight: text);
          break;
        case DeviceSetFieldFocus.reps:
          prov.updateSet(focusedIndex, reps: text);
          break;
        case DeviceSetFieldFocus.dropWeight:
          prov.updateDrop(focusedIndex, dropIndex, weight: text);
          break;
        case DeviceSetFieldFocus.dropReps:
          prov.updateDrop(focusedIndex, dropIndex, reps: text);
          break;
      }
    }

    var targetIndex = focusedIndex;
    DeviceSetFieldFocus? targetField;
    int? targetDropIndex;

    switch (focusedField) {
      case DeviceSetFieldFocus.reps:
        targetField = DeviceSetFieldFocus.weight;
        break;
      case DeviceSetFieldFocus.weight:
        final prevIndex = focusedIndex - 1;
        if (prevIndex >= 0 && prevIndex < prov.sets.length) {
          targetIndex = prevIndex;
          final drops = _dropMapsFromSet(prov.sets[prevIndex]);
          if (drops.isNotEmpty) {
            targetField = DeviceSetFieldFocus.dropReps;
            targetDropIndex = drops.length - 1;
          } else {
            targetField = DeviceSetFieldFocus.reps;
          }
        }
        break;
      case DeviceSetFieldFocus.dropReps:
        targetField = DeviceSetFieldFocus.dropWeight;
        targetDropIndex = dropIndex;
        break;
      case DeviceSetFieldFocus.dropWeight:
        if (dropIndex > 0) {
          targetField = DeviceSetFieldFocus.dropReps;
          targetDropIndex = dropIndex - 1;
        } else {
          targetField = DeviceSetFieldFocus.reps;
        }
        break;
    }

    if (targetField != null) {
      if (targetIndex != focusedIndex) {
        prov.markSetNotDone(targetIndex);
      }
      prov.requestFocus(
        index: targetIndex,
        field: targetField,
        dropIndex: targetDropIndex,
      );
    }

    _haptic(context);
  }

  static void _addSet(BuildContext context) {
    final prov = _activeProvider(context);
    if (prov == null) {
      _haptic(context);
      return;
    }

    elogUi('OVERLAY_ADD_SET', {
      'deviceId': prov.device?.uid,
      'focusedIndex': prov.focusedIndex,
      'focusedField': prov.focusedField?.name,
    });

    prov.addSet();

    _haptic(context);
  }

  static void _duplicateFromPrevious(
    BuildContext context,
    OverlayNumericKeypadController controller,
  ) {
    final prov = _activeProvider(context);
    if (prov == null) {
      _haptic(context);
      return;
    }
    final focusedIndex = prov.focusedIndex;
    final focusedField = prov.focusedField;
    final dropIndex = prov.focusedDropIndex ?? 0;
    final targetController = controller.target;

    elogUi('OVERLAY_DUPLICATE_PREVIOUS', {
      'deviceId': prov.device?.uid,
      'focusedIndex': focusedIndex,
      'focusedField': focusedField?.name,
    });

    if (focusedIndex == null ||
        focusedField == null ||
        targetController == null ||
        focusedIndex <= 0 ||
        focusedIndex >= prov.sets.length) {
      _haptic(context);
      return;
    }

    final previousSet = prov.sets[focusedIndex - 1];

    String? value;
    switch (focusedField) {
      case DeviceSetFieldFocus.weight:
        value = (previousSet['weight'] ?? '').toString();
        break;
      case DeviceSetFieldFocus.reps:
        value = (previousSet['reps'] ?? '').toString();
        break;
      case DeviceSetFieldFocus.dropWeight:
        value = _valueFromDrops(previousSet, dropIndex, 'weight');
        break;
      case DeviceSetFieldFocus.dropReps:
        value = _valueFromDrops(previousSet, dropIndex, 'reps');
        break;
    }

    if (value == null) {
      _haptic(context);
      return;
    }

    targetController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );

    _navigateNext(context, controller);
  }

  static List<Map<String, String>> _dropMapsFromSet(Map<String, dynamic> set) {
    final raw = set['drops'];
    final drops = <Map<String, String>>[];
    if (raw is List) {
      for (final entry in raw) {
        if (entry is Map) {
          final map = Map<String, dynamic>.from(entry);
          drops.add({
            'weight': (map['weight'] ?? map['kg'] ?? '').toString(),
            'reps': (map['reps'] ?? map['wdh'] ?? '').toString(),
          });
        }
      }
    }
    if (drops.isEmpty) {
      final legacyWeight = (set['dropWeight'] ?? '').toString();
      final legacyReps = (set['dropReps'] ?? '').toString();
      if (legacyWeight.isNotEmpty || legacyReps.isNotEmpty) {
        drops.add({'weight': legacyWeight, 'reps': legacyReps});
      }
    }
    return drops;
  }

  static String? _valueFromDrops(
    Map<String, dynamic> set,
    int dropIndex,
    String key,
  ) {
    final drops = _dropMapsFromSet(set);
    if (drops.isEmpty) return null;
    final index = dropIndex.clamp(0, drops.length - 1);
    final value = drops[index.toInt()][key];
    return value?.toString();
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
    final loc = AppLocalizations.of(context)!;
    final items = <_KeySpec>[
      for (final n in ['1', '2', '3', '4', '5', '6', '7', '8', '9'])
        _KeySpec(token: n, label: n, semantics: loc.numericKeypadSemanticsDigit(n)),
      _KeySpec(
        token: allowDecimal ? 'dec' : '_',
        label: allowDecimal ? decimalLabel : '',
        disabled: !allowDecimal,
        semantics: loc.numericKeypadSemanticsDecimal,
      ),
      _KeySpec(token: '0', label: '0', semantics: loc.numericKeypadSemanticsDigit('0')),
      _KeySpec(
        token: 'del',
        icon: Icons.backspace_outlined,
        semantics: loc.numericKeypadSemanticsDelete,
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

/// Action rail (right side). No "done" checkmark anymore.
/// The "hide keyboard" button is rendered WIDE and occupies the full row.
class _ActionRailCompact extends StatelessWidget {
  final double gridCellWidth;
  final double gridCellHeight;
  final int totalGridRows;
  final double gap;
  final NumericKeypadTheme theme;
  final VoidCallback onHide;
  final VoidCallback onNavigate;
  final VoidCallback onNavigateBack;
  final VoidCallback onAddSet;
  final VoidCallback onDuplicate;

  const _ActionRailCompact({
    required this.gridCellWidth,
    required this.gridCellHeight,
    required this.totalGridRows,
    required this.gap,
    required this.theme,
    required this.onHide,
    required this.onNavigate,
    required this.onNavigateBack,
    required this.onAddSet,
    required this.onDuplicate,
  });

  @override
  Widget build(BuildContext context) {
    final availableH =
        totalGridRows * gridCellHeight + (totalGridRows - 1) * gap;
    final loc = AppLocalizations.of(context)!;

    // Actions without "done". Last action is WIDE hide-keyboard.
    final actions = <_RailAction>[
      _RailAction(
        Icons.arrow_back_rounded,
        loc.numericKeypadSemanticsPrevious,
        onNavigateBack,
      ),
      _RailAction(
        Icons.arrow_forward_rounded,
        loc.numericKeypadSemanticsNext,
        onNavigate,
      ),
      _RailAction(
        Icons.add_rounded,
        loc.addSetButton,
        onAddSet,
      ),
      _RailAction(
        Icons.copy_all_rounded,
        loc.numericKeypadSemanticsDuplicate,
        onDuplicate,
      ),
      _RailAction(
        Icons.keyboard_hide_rounded,
        loc.numericKeypadSemanticsHideKeyboard,
        onHide,
        wide: true,
      ),
    ];

    // Compute how many 1x slots we need (wide counts as 2).
    final slotCount = actions.fold<int>(0, (sum, a) => sum + (a.wide ? 2 : 1));
    final rowsNeeded = (slotCount / 2).ceil();
    final totalRowGaps = math.max(0, rowsNeeded - 1);

    final sideV = (availableH - totalRowGaps * gap) / rowsNeeded;
    final sideH = (gridCellWidth - gap) / 2;
    final side = math.max(28.0, math.min(sideV, sideH)).floorToDouble();

    Widget squareBtn(_RailAction a) => _RailBtnSquare(
      side: side,
      icon: a.icon,
      semanticsLabel: a.label,
      onTap: a.onTap,
      theme: theme,
    );

    Widget wideBtn(_RailAction a) => _RailBtnWide(
      height: side,
      icon: a.icon,
      semanticsLabel: a.label,
      onTap: a.onTap,
      theme: theme,
    );

    int slotsUsed = 0;
    final rows = <Widget>[];
    while (slotsUsed < slotCount) {
      // pick next action(s)
      // We'll consume from a moving pointer instead of recomputing; simpler:
      // Build sequentially
      int i = 0;
      while (i < actions.length && actions[i]._consumed) {
        i++;
      }
      if (i >= actions.length) break;
      final a = actions[i].._consumed = true;
      if (a.wide) {
        rows.add(
          SizedBox(
            height: side,
            child: Row(children: [Expanded(child: wideBtn(a))]),
          ),
        );
        slotsUsed += 2;
      } else {
        // Try to pair with a second 1x action
        int j = i + 1;
        while (j < actions.length && actions[j]._consumed) {
          j++;
        }
        _RailAction? b;
        if (j < actions.length && !actions[j].wide) {
          b = actions[j].._consumed = true;
        }
        if (b != null) {
          rows.add(
            SizedBox(
              height: side,
              child: Row(
                children: [
                  Expanded(child: squareBtn(a)),
                  SizedBox(width: gap),
                  Expanded(child: squareBtn(b)),
                ],
              ),
            ),
          );
          slotsUsed += 2;
        } else {
          rows.add(
            SizedBox(
              height: side,
              child: Row(children: [Expanded(child: squareBtn(a))]),
            ),
          );
          slotsUsed += 1;
        }
      }
      if (slotsUsed < slotCount) rows.add(SizedBox(height: gap));
    }

    return Container(
      color: theme.railBg,
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
  final bool wide;

  // internal bookkeeping for layout
  bool _consumed = false;

  _RailAction(
    this.icon,
    this.label,
    this.onTap, {
    this.wide = false,
  });
}

class _RailBtnSquare extends StatefulWidget {
  final double side;
  final IconData icon;
  final String semanticsLabel;
  final VoidCallback onTap;
  final NumericKeypadTheme theme;

  const _RailBtnSquare({
    required this.side,
    required this.icon,
    required this.semanticsLabel,
    required this.onTap,
    required this.theme,
  });

  @override
  State<_RailBtnSquare> createState() => _RailBtnSquareState();
}

class _RailBtnSquareState extends State<_RailBtnSquare> {
  @override
  Widget build(BuildContext context) {
    final th = widget.theme;
    return Semantics(
      label: widget.semanticsLabel,
      button: true,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: th.railBg,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: FittedBox(
            child: Icon(
              widget.icon,
              color: th.railIcon,
            ),
          ),
        ),
      ),
    );
  }
}

class _RailBtnWide extends StatelessWidget {
  final double height;
  final IconData icon;
  final String semanticsLabel;
  final VoidCallback onTap;
  final NumericKeypadTheme theme;

  const _RailBtnWide({
    required this.height,
    required this.icon,
    required this.semanticsLabel,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final th = theme;
    return Semantics(
      label: semanticsLabel,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: th.railBg,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          // Icon only (consistent with compact rail); gets more visual weight
          child: FittedBox(
            child: Icon(
              icon,
              color: th.railIcon,
            ),
          ),
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
      _timer = Timer.periodic(const Duration(milliseconds: 70), (_) {
        widget.onTap!.call();
      });
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
    final disabled = widget.disabled || widget.onTap == null;
    final fg = disabled ? th.keyFg.withOpacity(0.35) : th.keyFg;

    final child = FittedBox(
      fit: BoxFit.scaleDown,
      child: widget.icon != null
          ? Icon(widget.icon, color: fg)
          : Text(
              widget.label ?? '',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
    );

    return Semantics(
      label: widget.semanticsLabel.isEmpty
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
            color: disabled ? th.keyBg.withOpacity(0.5) : th.keyBg,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}
