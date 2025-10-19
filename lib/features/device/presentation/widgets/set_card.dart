// lib/features/device/presentation/widgets/set_card.dart
// SetCard with silent controller updates to prevent re-entrant rebuilds.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/device_provider.dart';
import 'package:tapem/core/ui_mutation_guard.dart';
import 'package:tapem/core/theme/brand_on_colors.dart';
import 'package:tapem/core/widgets/brand_outline.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/ui/numeric_keypad/overlay_numeric_keypad.dart';
import 'package:tapem/core/logging/elog.dart';

void _slog(int idx, String m) => debugPrint('🧾 [SetCard#$idx] $m');

class SetCardTheme {
  final EdgeInsets padding;
  final Color chipBg;
  final Color chipFg;
  final Color chipBorder;
  final Color doneOn;
  final Color doneOff;
  final Color menuBg;
  final Color menuFg;
  final Color cardFill;
  final Color inputFill;
  final Color inputFillDisabled;
  final Color inputStroke;
  final Color inputStrokeActive;
  final Color inputShadow;
  final Color inputShadowActive;
  final Color inputPlaceholder;

  const SetCardTheme({
    required this.padding,
    required this.chipBg,
    required this.chipFg,
    required this.chipBorder,
    required this.doneOn,
    required this.doneOff,
    required this.menuBg,
    required this.menuFg,
    required this.cardFill,
    required this.inputFill,
    required this.inputFillDisabled,
    required this.inputStroke,
    required this.inputStrokeActive,
    required this.inputShadow,
    required this.inputShadowActive,
    required this.inputPlaceholder,
  });

  factory SetCardTheme.of(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    Color tint(Color base, Color overlay, double opacity) {
      return Color.alphaBlend(overlay.withOpacity(opacity), base);
    }

    final surface = theme.canvasColor;
    final softenedSurface = tint(surface, scheme.surface, isDark ? 0.75 : 0.95);
    final quietBase = tint(softenedSurface, scheme.primary, isDark ? 0.06 : 0.04);
    final idleOverlay = tint(quietBase, scheme.surfaceTint, isDark ? 0.1 : 0.06);
    final cardFill = Color.alphaBlend(
      Colors.black.withOpacity(isDark ? 0.85 : 0.9),
      softenedSurface,
    );
    final inputBase = cardFill;
    final inputDisabledBase = Color.alphaBlend(
      scheme.onSurface.withOpacity(isDark ? 0.12 : 0.08),
      cardFill,
    );
    final stroke = scheme.onSurface.withOpacity(isDark ? 0.24 : 0.14);
    final strokeActive = Color.alphaBlend(
      scheme.primary.withOpacity(isDark ? 0.5 : 0.4),
      stroke,
    );
    final glowIdle = scheme.primary.withOpacity(isDark ? 0.18 : 0.12);
    final glowActive = scheme.primary.withOpacity(isDark ? 0.28 : 0.2);

    return SetCardTheme(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      chipBg: idleOverlay,
      chipFg: scheme.onSurface.withOpacity(isDark ? 0.92 : 0.78),
      chipBorder: scheme.onSurface.withOpacity(isDark ? 0.22 : 0.12),
      doneOn: tint(quietBase, scheme.primaryContainer, isDark ? 0.4 : 0.25),
      doneOff: scheme.onSurface.withOpacity(0.55),
      menuBg: tint(quietBase, scheme.primary, isDark ? 0.18 : 0.12),
      menuFg: scheme.primary.withOpacity(isDark ? 0.85 : 0.75),
      cardFill: cardFill,
      inputFill: inputBase,
      inputFillDisabled: inputDisabledBase,
      inputStroke: stroke,
      inputStrokeActive: strokeActive,
      inputShadow: glowIdle,
      inputShadowActive: glowActive,
      inputPlaceholder: scheme.primary.withOpacity(isDark ? 0.45 : 0.38),
    );
  }

  SetCardTheme copyWith({
    EdgeInsets? padding,
    Color? chipBg,
    Color? chipFg,
    Color? chipBorder,
    Color? doneOn,
    Color? doneOff,
    Color? menuBg,
    Color? menuFg,
    Color? cardFill,
    Color? inputFill,
    Color? inputFillDisabled,
    Color? inputStroke,
    Color? inputStrokeActive,
    Color? inputShadow,
    Color? inputShadowActive,
    Color? inputPlaceholder,
  }) {
    return SetCardTheme(
      padding: padding ?? this.padding,
      chipBg: chipBg ?? this.chipBg,
      chipFg: chipFg ?? this.chipFg,
      chipBorder: chipBorder ?? this.chipBorder,
      doneOn: doneOn ?? this.doneOn,
      doneOff: doneOff ?? this.doneOff,
      menuBg: menuBg ?? this.menuBg,
      menuFg: menuFg ?? this.menuFg,
      cardFill: cardFill ?? this.cardFill,
      inputFill: inputFill ?? this.inputFill,
      inputFillDisabled: inputFillDisabled ?? this.inputFillDisabled,
      inputStroke: inputStroke ?? this.inputStroke,
      inputStrokeActive: inputStrokeActive ?? this.inputStrokeActive,
      inputShadow: inputShadow ?? this.inputShadow,
      inputShadowActive: inputShadowActive ?? this.inputShadowActive,
      inputPlaceholder: inputPlaceholder ?? this.inputPlaceholder,
    );
  }
}

enum SetCardSize { regular, dense }

enum SetCardDisplayMode { standalone, grouped }

class SetCard extends StatefulWidget {
  final int index;
  final Map<String, dynamic> set;
  final SetCardSize size;
  final bool readOnly;
  final SetCardDisplayMode displayMode;
  final BorderRadiusGeometry? groupedRadius;
  const SetCard({
    super.key,
    required this.index,
    required this.set,
    this.size = SetCardSize.regular,
    this.readOnly = false,
    this.displayMode = SetCardDisplayMode.standalone,
    this.groupedRadius,
  });

  @override
  State<SetCard> createState() => SetCardState();
}

class SetCardState extends State<SetCard> {
  late final TextEditingController _weightCtrl;
  late final TextEditingController _repsCtrl;
  final List<TextEditingController> _dropWeightCtrls = [];
  final List<TextEditingController> _dropRepsCtrls = [];
  late final FocusNode _weightFocus;
  late final FocusNode _repsFocus;
  final List<FocusNode> _dropWeightFocuses = [];
  final List<FocusNode> _dropRepsFocuses = [];
  final List<VoidCallback?> _dropWeightListeners = [];
  final List<VoidCallback?> _dropRepsListeners = [];

  bool _showExtras = false;
  int _lastFocusRequestId = -1;

  // 🔒 Silent-update Mechanik
  bool _muteCtrls = false;
  void _setTextSilently(
    TextEditingController c,
    String text,
    String field,
  ) {
    UiMutationGuard.run(
      screen: 'DeviceScreen',
      widget: 'SetCard',
      field: field,
      oldValue: c.text,
      newValue: text,
      reason: 'didUpdateWidget',
      mutate: () {
        _muteCtrls = true;
        c.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
        _muteCtrls = false;
      },
    );
  }

  List<Map<String, String>> _dropMapsFromSet(Map<String, dynamic> set) {
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
      if (legacyWeight.isNotEmpty && legacyReps.isNotEmpty) {
        drops.add({'weight': legacyWeight, 'reps': legacyReps});
      }
    }
    return drops;
  }

  void _handleDropWeightChanged(TextEditingController controller) {
    if (_muteCtrls) return;
    final index = _dropWeightCtrls.indexOf(controller);
    if (index == -1) return;
    _slog(widget.index, 'dropWeight[$index] → "${controller.text}"');
    context.read<DeviceProvider>().updateDrop(
          widget.index,
          index,
          weight: controller.text,
        );
  }

  void _handleDropRepsChanged(TextEditingController controller) {
    if (_muteCtrls) return;
    final index = _dropRepsCtrls.indexOf(controller);
    if (index == -1) return;
    _slog(widget.index, 'dropReps[$index] → "${controller.text}"');
    context.read<DeviceProvider>().updateDrop(
          widget.index,
          index,
          reps: controller.text,
        );
  }

  void _addDropController() {
    final weightCtrl = TextEditingController();
    final repsCtrl = TextEditingController();
    final weightFocus = FocusNode();
    final repsFocus = FocusNode();
    _dropWeightCtrls.add(weightCtrl);
    _dropRepsCtrls.add(repsCtrl);
    _dropWeightFocuses.add(weightFocus);
    _dropRepsFocuses.add(repsFocus);
    if (!widget.readOnly) {
      void weightListener() => _handleDropWeightChanged(weightCtrl);
      void repsListener() => _handleDropRepsChanged(repsCtrl);
      weightCtrl.addListener(weightListener);
      repsCtrl.addListener(repsListener);
      _dropWeightListeners.add(weightListener);
      _dropRepsListeners.add(repsListener);
    } else {
      _dropWeightListeners.add(null);
      _dropRepsListeners.add(null);
    }
  }

  void _removeDropController(int index) {
    final weightCtrl = _dropWeightCtrls.removeAt(index);
    final repsCtrl = _dropRepsCtrls.removeAt(index);
    final weightFocus = _dropWeightFocuses.removeAt(index);
    final repsFocus = _dropRepsFocuses.removeAt(index);
    final weightListener = _dropWeightListeners.removeAt(index);
    final repsListener = _dropRepsListeners.removeAt(index);
    if (weightListener != null) weightCtrl.removeListener(weightListener);
    if (repsListener != null) repsCtrl.removeListener(repsListener);
    weightCtrl.dispose();
    repsCtrl.dispose();
    weightFocus.dispose();
    repsFocus.dispose();
  }

  void _setDropControllerCount(int count) {
    final current = _dropWeightCtrls.length;
    if (current < count) {
      for (var i = current; i < count; i++) {
        _addDropController();
      }
    } else if (current > count) {
      for (var i = current - 1; i >= count; i--) {
        _removeDropController(i);
      }
    }
  }

  void _syncDropControllersFromWidget() {
    final drops = _dropMapsFromSet(widget.set);
    _setDropControllerCount(drops.length);
    for (var i = 0; i < drops.length; i++) {
      final weight = drops[i]['weight'] ?? '';
      final reps = drops[i]['reps'] ?? '';
      if (_dropWeightCtrls[i].text != weight) {
        _setTextSilently(_dropWeightCtrls[i], weight, 'dropWeight[$i]');
      }
      if (_dropRepsCtrls[i].text != reps) {
        _setTextSilently(_dropRepsCtrls[i], reps, 'dropReps[$i]');
      }
    }
    if (drops.isEmpty) {
      _setDropControllerCount(0);
    }
  }

  void _clearDropControllers() {
    for (var i = _dropWeightCtrls.length - 1; i >= 0; i--) {
      _removeDropController(i);
    }
  }

  void _handleAddDrop() {
    final prov = context.read<DeviceProvider>();
    final newIndex = prov.addDropToSet(widget.index);
    HapticFeedback.lightImpact();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (newIndex < _dropWeightCtrls.length) {
        _openKeypad(
          _dropWeightCtrls[newIndex],
          _dropWeightFocuses[newIndex],
          allowDecimal: true,
          field: DeviceSetFieldFocus.dropWeight,
          dropIndex: newIndex,
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController(text: widget.set['weight'] as String?);
    _repsCtrl = TextEditingController(text: widget.set['reps'] as String?);
    _weightFocus = FocusNode();
    _repsFocus = FocusNode();
    _syncDropControllersFromWidget();

    if (!widget.readOnly) {
      _weightCtrl.addListener(() {
        if (_muteCtrls) return;
        _slog(widget.index, 'weight → "${_weightCtrl.text}"');
        final prov = context.read<DeviceProvider>();
        prov.updateSet(
          widget.index,
          weight: _weightCtrl.text,
          isBodyweight: prov.isBodyweightMode,
        );
      });
      _repsCtrl.addListener(() {
        if (_muteCtrls) return;
        _slog(widget.index, 'reps → "${_repsCtrl.text}"');
        context.read<DeviceProvider>().updateSet(
          widget.index,
          reps: _repsCtrl.text,
        );
      });
    }
  }

  @override
  void didUpdateWidget(covariant SetCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final w = widget.set['weight'] as String? ?? '';
    final r = widget.set['reps'] as String? ?? '';
    if (oldWidget.set['weight'] != w) {
      _slog(widget.index, 'didUpdateWidget sync weight "$w"');
      _setTextSilently(_weightCtrl, w, 'weight');
    }
    if (oldWidget.set['reps'] != r) {
      _slog(widget.index, 'didUpdateWidget sync reps "$r"');
      _setTextSilently(_repsCtrl, r, 'reps');
    }
    _syncDropControllersFromWidget();
  }

  @override
  void dispose() {
    _slog(widget.index, 'dispose()');
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    _weightFocus.dispose();
    _repsFocus.dispose();
    _clearDropControllers();
    super.dispose();
  }

  void _openKeypad(
    TextEditingController controller,
    FocusNode focusNode, {
    required bool allowDecimal,
    required DeviceSetFieldFocus field,
    bool notifyFocus = true,
    int? dropIndex,
  }) {
    _slog(
      widget.index,
      'open keypad field=$field allowDecimal=$allowDecimal text="${controller.text}"',
    );
    final prov = context.read<DeviceProvider>();
    if (notifyFocus) {
      _lastFocusRequestId = prov.requestFocus(
        index: widget.index,
        field: field,
        dropIndex: dropIndex,
      );
    } else {
      _lastFocusRequestId = prov.focusRequestId;
    }
    final keypad = context.read<OverlayNumericKeypadController>();
    keypad.openFor(
      controller,
      allowDecimal: allowDecimal,
    );
    controller.selection = TextSelection.collapsed(offset: controller.text.length);
    if (focusNode.canRequestFocus) {
      focusNode.requestFocus();
    }
    // Hinweis: ensureVisible nach dem Öffnen separat aufrufen (DeviceScreen macht das).
  }

  void focusWeight() {
    _openKeypad(
      _weightCtrl,
      _weightFocus,
      allowDecimal: true,
      field: DeviceSetFieldFocus.weight,
    );
  }

  String? _validateDrop(int index) {
    final loc = AppLocalizations.of(context)!;
    if (index >= _dropWeightCtrls.length || index >= _dropRepsCtrls.length) {
      return null;
    }
    final dw = _dropWeightCtrls[index].text.trim();
    final dr = _dropRepsCtrls[index].text.trim();
    if (dw.isEmpty && dr.isEmpty) return null;
    if (dw.isEmpty || dr.isEmpty) return loc.dropFillBoth;
    final base = double.tryParse(_weightCtrl.text.replaceAll(',', '.'));
    final drop = double.tryParse(dw.replaceAll(',', '.'));
    if (base == null || drop == null) return loc.numberInvalid;
    if (drop >= base) return loc.dropWeightTooHigh;
    final reps = int.tryParse(dr);
    if (reps == null || reps < 1) return loc.dropRepsInvalid;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<DeviceProvider>();
    final loc = AppLocalizations.of(context)!;
    var tokens = SetCardTheme.of(context);
    final dense = widget.size == SetCardSize.dense;
    if (dense) {
      tokens = tokens.copyWith(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      );
    }
    final doneVal = widget.set['done'];
    final done = doneVal == true || doneVal == 'true';
    final weight = (widget.set['weight'] ?? '').toString().trim();
    final reps = (widget.set['reps'] ?? '').toString().trim();
    final isBw = widget.set['isBodyweight'] == true;
    final filled = (isBw
            ? (weight.isEmpty ||
                double.tryParse(weight.replaceAll(',', '.')) != null)
            : (weight.isNotEmpty &&
                double.tryParse(weight.replaceAll(',', '.')) != null)) &&
        reps.isNotEmpty &&
        int.tryParse(reps) != null;

    final focusField = prov.focusedField;
    final focusRequestId = prov.focusRequestId;
    if (!widget.readOnly &&
        focusField != null &&
        prov.focusedIndex == widget.index &&
        focusRequestId != _lastFocusRequestId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _lastFocusRequestId = focusRequestId;
        switch (focusField) {
          case DeviceSetFieldFocus.weight:
            _openKeypad(
              _weightCtrl,
              _weightFocus,
              allowDecimal: true,
              field: focusField,
              notifyFocus: false,
            );
            break;
          case DeviceSetFieldFocus.reps:
            _openKeypad(
              _repsCtrl,
              _repsFocus,
              allowDecimal: false,
              field: focusField,
              notifyFocus: false,
            );
            break;
          case DeviceSetFieldFocus.dropWeight:
            final dropIndex = prov.focusedDropIndex ?? 0;
            if (dropIndex < _dropWeightCtrls.length) {
              _openKeypad(
                _dropWeightCtrls[dropIndex],
                _dropWeightFocuses[dropIndex],
                allowDecimal: true,
                field: focusField,
                notifyFocus: false,
                dropIndex: dropIndex,
              );
            }
            break;
          case DeviceSetFieldFocus.dropReps:
            final dropIndex = prov.focusedDropIndex ?? 0;
            if (dropIndex < _dropRepsCtrls.length) {
              _openKeypad(
                _dropRepsCtrls[dropIndex],
                _dropRepsFocuses[dropIndex],
                allowDecimal: false,
                field: focusField,
                notifyFocus: false,
                dropIndex: dropIndex,
              );
            }
            break;
        }
      });
    }
    VoidCallback? toggleExtras;
    if (!widget.readOnly) {
      toggleExtras = () {
        _slog(
          widget.index,
          'tap: more options → ${!_showExtras}',
        );
        HapticFeedback.lightImpact();
        final next = !_showExtras;
        setState(() => _showExtras = next);
        if (next && _dropWeightCtrls.isEmpty) {
          context.read<DeviceProvider>().ensureDropSlot(widget.index);
        }
      };
    }

    VoidCallback? toggleDone;
    if (!widget.readOnly && filled) {
      toggleDone = () {
        _slog(
          widget.index,
          'tap: toggle done via provider',
        );
        final prov = context.read<DeviceProvider>();
        final ok = prov.toggleSetDone(widget.index);
        elogUi('SET_DONE_TAP', {
          'index': widget.index,
          'wasValid': ok,
          if (!ok) 'reasonIfBlocked': 'invalid',
        });
        HapticFeedback.lightImpact();
        if (ok) {
          prov.clearFocus();
          context.read<OverlayNumericKeypadController>().close();
        }
      };
    }

    final canMutateDrops = !widget.readOnly && !done;
    final dropRows = <_DropRowConfig>[
      for (var i = 0; i < _dropWeightCtrls.length; i++)
        _DropRowConfig(
          weightController: _dropWeightCtrls[i],
          weightFocus: _dropWeightFocuses[i],
          repsController: _dropRepsCtrls[i],
          repsFocus: _dropRepsFocuses[i],
          onTapWeight: widget.readOnly
              ? null
              : () => _openKeypad(
                    _dropWeightCtrls[i],
                    _dropWeightFocuses[i],
                    allowDecimal: true,
                    field: DeviceSetFieldFocus.dropWeight,
                    dropIndex: i,
                  ),
          onTapReps: widget.readOnly
              ? null
              : () => _openKeypad(
                    _dropRepsCtrls[i],
                    _dropRepsFocuses[i],
                    allowDecimal: false,
                    field: DeviceSetFieldFocus.dropReps,
                    dropIndex: i,
                  ),
          validator: (_) => _validateDrop(i),
          showAddButton: canMutateDrops && i == _dropWeightCtrls.length - 1,
          onAdd: canMutateDrops ? _handleAddDrop : null,
        ),
    ];

    final displayMode = widget.displayMode;
    final paddingBase = tokens.padding;
    final isFirstGroupedRow =
        displayMode == SetCardDisplayMode.grouped && widget.index == 0;
    final EdgeInsets contentPadding = displayMode == SetCardDisplayMode.grouped
        ? EdgeInsets.fromLTRB(
            paddingBase.left,
            isFirstGroupedRow ? 0 : paddingBase.top,
            paddingBase.right,
            paddingBase.bottom,
          )
        : EdgeInsets.zero;
    final BorderRadius? rowRadius = displayMode == SetCardDisplayMode.grouped
        ? (widget.groupedRadius as BorderRadius?)
        : null;

    Widget content = SetRowContent(
      tokens: tokens,
      dense: dense,
      index: widget.index + 1,
      showFieldHeaderRow: displayMode != SetCardDisplayMode.grouped,
      showExtras: _showExtras,
      done: done,
      readOnly: widget.readOnly,
      filled: filled,
      isBodyweightMode: prov.isBodyweightMode,
      loc: loc,
      weightController: _weightCtrl,
      weightFocus: _weightFocus,
      repsController: _repsCtrl,
      repsFocus: _repsFocus,
      onToggleExtras: toggleExtras,
      onToggleDone: toggleDone,
      onTapWeight:
          widget.readOnly
              ? null
              : () => _openKeypad(
                    _weightCtrl,
                    _weightFocus,
                    allowDecimal: true,
                    field: DeviceSetFieldFocus.weight,
                  ),
      onTapReps:
          widget.readOnly
              ? null
              : () => _openKeypad(
                    _repsCtrl,
                    _repsFocus,
                    allowDecimal: false,
                    field: DeviceSetFieldFocus.reps,
                  ),
      dropRows: dropRows,
      padding: contentPadding,
    );

    final backgroundRadius = rowRadius ??
        (displayMode == SetCardDisplayMode.standalone
            ? BorderRadius.circular(26)
            : BorderRadius.circular(18));
    content = ClipRRect(
      borderRadius: backgroundRadius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.cardFill,
        ),
        child: content,
      ),
    );

    return Semantics(
      label: 'Set ${widget.index + 1}',
      child: displayMode == SetCardDisplayMode.standalone
          ? BrandOutline(
              padding: tokens.padding,
              child: content,
            )
          : content,
    );
  }
}

class SetRowContent extends StatelessWidget {
  final SetCardTheme tokens;
  final bool dense;
  final int index;
  final bool showFieldHeaderRow;
  final bool showExtras;
  final bool done;
  final bool readOnly;
  final bool filled;
  final bool isBodyweightMode;
  final AppLocalizations loc;
  final TextEditingController weightController;
  final FocusNode weightFocus;
  final TextEditingController repsController;
  final FocusNode repsFocus;
  final VoidCallback? onToggleExtras;
  final VoidCallback? onToggleDone;
  final VoidCallback? onTapWeight;
  final VoidCallback? onTapReps;
  final List<_DropRowConfig> dropRows;
  final EdgeInsetsGeometry padding;

  const SetRowContent({
    super.key,
    required this.tokens,
    required this.dense,
    required this.index,
    required this.showFieldHeaderRow,
    required this.showExtras,
    required this.done,
    required this.readOnly,
    required this.filled,
    required this.isBodyweightMode,
    required this.loc,
    required this.weightController,
    required this.weightFocus,
    required this.repsController,
    required this.repsFocus,
    required this.onToggleExtras,
    required this.onToggleDone,
    required this.onTapWeight,
    required this.onTapReps,
    required this.dropRows,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final weightLabel = isBodyweightMode
        ? loc.bodyweightFieldLabel(loc.tableHeaderKg)
        : loc.weightFieldLabel(loc.tableHeaderKg);
    final repsLabel = loc.tableHeaderReps;
    final showFieldHeaders = index == 0;
    final headerStyle = GoogleFonts.inter(
      fontSize: dense ? 11 : 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
      color: tokens.chipFg.withOpacity(0.78),
    );
    final double indexBadgeWidth = dense ? 26.0 : 30.0;
    final double indexBadgeGap = dense ? 6.0 : 9.0;
    final double dropBadgeToFieldGap = dense ? 6.0 : 9.0;
    final double leadingWidth = indexBadgeWidth + indexBadgeGap;

    final children = <Widget>[];
    if (showFieldHeaderRow && showFieldHeaders) {
      children.add(
        Padding(
          padding: EdgeInsets.only(bottom: dense ? 6 : 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(width: leadingWidth),
              Expanded(
                child: Text(
                  weightLabel,
                  style: headerStyle,
                ),
              ),
              SizedBox(width: dense ? 8 : 12),
              Expanded(
                child: Text(
                  repsLabel,
                  style: headerStyle,
                ),
              ),
            ],
          ),
        ),
      );
    }

    children.add(
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _IndexBadge(
            tokens: tokens,
            index: index,
            dense: dense,
          ),
          SizedBox(width: dense ? 6 : 8),
          Expanded(
            child: _InputPill(
              controller: weightController,
              focusNode: weightFocus,
              label: weightLabel,
              readOnly: done || readOnly,
              tokens: tokens,
              dense: dense,
              onTap: onTapWeight,
              validator: (v) {
                if (v == null || v.isEmpty) return null;
                if (double.tryParse(v.replaceAll(',', '.')) == null) {
                  return loc.numberInvalid;
                }
                return null;
              },
              showLabel: false,
              placeholder: weightLabel,
            ),
          ),
          SizedBox(width: dense ? 6 : 8),
          Expanded(
            child: _InputPill(
              controller: repsController,
              focusNode: repsFocus,
              label: repsLabel,
              readOnly: done || readOnly,
              tokens: tokens,
              dense: dense,
              onTap: onTapReps,
              validator: (v) {
                if (v == null || v.isEmpty) return null;
                if (int.tryParse(v) == null) return loc.intRequired;
                return null;
              },
              showLabel: false,
              placeholder: repsLabel,
            ),
          ),
          SizedBox(width: dense ? 6 : 8),
          _RoundButton(
            tokens: tokens,
            icon: showExtras ? Icons.expand_less : Icons.expand_more,
            filled: false,
            semantics: 'Mehr Optionen',
            dense: dense,
            onTap: onToggleExtras,
            iconColor: primaryColor,
            disabledIconColor: primaryColor.withOpacity(0.4),
          ),
          SizedBox(width: dense ? 5 : 7),
          _RoundButton(
            tokens: tokens,
            icon: Icons.check,
            filled: done,
            semantics: done ? loc.setReopenTooltip : loc.setCompleteTooltip,
            dense: dense,
            onTap: onToggleDone,
            iconColor: primaryColor,
            filledIconColor: primaryColor,
            disabledIconColor: primaryColor.withOpacity(0.4),
          ),
        ],
      ),
    );
    if (showExtras) {
      children.add(SizedBox(height: dense ? 6 : 9));
      for (var i = 0; i < dropRows.length; i++) {
        final drop = dropRows[i];
        children.add(
          SizedBox(
            width: double.infinity,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final hasAddButton = !readOnly && drop.showAddButton;
                final fieldGap = dense ? 6.0 : 10.0;
                final buttonSize = dense ? 38.0 : 42.0;
                final trailingLeadingGap = fieldGap;
                final trailingBetweenGap = dense ? 5.0 : 6.0;
                final trailingReservedWidth =
                    trailingLeadingGap + buttonSize + trailingBetweenGap + buttonSize;
                final available = constraints.maxWidth -
                    leadingWidth -
                    fieldGap -
                    trailingReservedWidth;
                final fieldWidth = math.max(0.0, available / 2);
                final trailingRemainder = trailingBetweenGap + buttonSize;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: leadingWidth,
                      child: Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: Padding(
                          padding: EdgeInsetsDirectional.only(
                            end: dropBadgeToFieldGap,
                          ),
                          child: _DropBadge(tokens: tokens, dense: dense),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: fieldWidth,
                      child: _InputPill(
                        controller: drop.weightController,
                        focusNode: drop.weightFocus,
                        label: loc.dropKgFieldLabel,
                        readOnly: readOnly || done,
                        tokens: tokens,
                        dense: true,
                        onTap: drop.onTapWeight,
                        validator: drop.validator,
                      ),
                    ),
                    SizedBox(width: fieldGap),
                    SizedBox(
                      width: fieldWidth,
                      child: _InputPill(
                        controller: drop.repsController,
                        focusNode: drop.repsFocus,
                        label: loc.dropRepsFieldLabel,
                        readOnly: readOnly || done,
                        tokens: tokens,
                        dense: true,
                        onTap: drop.onTapReps,
                        validator: drop.validator,
                      ),
                    ),
                    if (hasAddButton) ...[
                      SizedBox(width: trailingLeadingGap),
                      _RoundButton(
                        tokens: tokens,
                        icon: Icons.add,
                        filled: false,
                        semantics: loc.addSetButton,
                        dense: true,
                        onTap: drop.onAdd,
                        iconColor: primaryColor,
                        disabledIconColor: primaryColor.withOpacity(0.4),
                      ),
                      SizedBox(width: trailingRemainder),
                    ] else
                      SizedBox(width: trailingReservedWidth),
                  ],
                );
              },
            ),
          ),
        );
        if (i != dropRows.length - 1) {
          children.add(SizedBox(height: dense ? 8 : 12));
        }
      }
    }

    Widget body = Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );

    return SizedBox(
      width: double.infinity,
      child: body,
    );
  }
}

class _DropRowConfig {
  final TextEditingController weightController;
  final FocusNode weightFocus;
  final TextEditingController repsController;
  final FocusNode repsFocus;
  final VoidCallback? onTapWeight;
  final VoidCallback? onTapReps;
  final FormFieldValidator<String>? validator;
  final bool showAddButton;
  final VoidCallback? onAdd;

  const _DropRowConfig({
    required this.weightController,
    required this.weightFocus,
    required this.repsController,
    required this.repsFocus,
    this.onTapWeight,
    this.onTapReps,
    this.validator,
    this.showAddButton = false,
    this.onAdd,
  });
}

class _IndexBadge extends StatelessWidget {
  final SetCardTheme tokens;
  final int index;
  final bool dense;
  const _IndexBadge({
    required this.tokens,
    required this.index,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Semantics(
      label: 'Set $index',
      child: Container(
        width: dense ? 28 : 32,
        height: dense ? 28 : 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: tokens.cardFill,
          borderRadius: BorderRadius.circular(dense ? 14 : 16),
          boxShadow: [
            BoxShadow(
              color: tokens.menuFg.withOpacity(0.12),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Text(
          '$index',
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.w700,
            fontSize: dense ? 14 : null,
          ),
        ),
      ),
    );
  }
}

class _DropBadge extends StatelessWidget {
  final SetCardTheme tokens;
  final bool dense;
  const _DropBadge({
    required this.tokens,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: dense ? 24 : 28,
      height: dense ? 24 : 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tokens.cardFill,
        borderRadius: BorderRadius.circular(dense ? 12 : 14),
        boxShadow: [
          BoxShadow(
            color: tokens.menuFg.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Text(
        '↘︎',
        style: TextStyle(
          color: tokens.chipFg,
          fontWeight: FontWeight.w600,
          fontSize: dense ? 14 : 16,
        ),
      ),
    );
  }
}

class _InputPill extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final bool readOnly;
  final SetCardTheme tokens;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;
  final bool dense;
  final bool showLabel;
  final String? placeholder;

  const _InputPill({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.readOnly,
    required this.tokens,
    this.onTap,
    this.validator,
    this.dense = false,
    this.showLabel = true,
    this.placeholder,
  });

  @override
  State<_InputPill> createState() => _InputPillState();
}

class _InputPillState extends State<_InputPill> {
  late bool _hasFocus;
  late String _text;

  @override
  void initState() {
    super.initState();
    _hasFocus = widget.focusNode.hasFocus;
    _text = widget.controller.text;
    widget.focusNode.addListener(_handleFocus);
    widget.controller.addListener(_handleText);
  }

  @override
  void didUpdateWidget(covariant _InputPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_handleFocus);
      _hasFocus = widget.focusNode.hasFocus;
      widget.focusNode.addListener(_handleFocus);
    }
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleText);
      _text = widget.controller.text;
      widget.controller.addListener(_handleText);
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocus);
    widget.controller.removeListener(_handleText);
    super.dispose();
  }

  void _handleFocus() {
    if (!mounted) return;
    final hasFocus = widget.focusNode.hasFocus;
    if (_hasFocus != hasFocus) {
      setState(() => _hasFocus = hasFocus);
    }
  }

  void _handleText() {
    if (!mounted) return;
    final current = widget.controller.text;
    if (_text != current) {
      setState(() => _text = current);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showLabel = widget.showLabel;
    final hasValue = _text.trim().isNotEmpty;
    final hasFocus = _hasFocus;
    final disabled = widget.readOnly;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final brandColor = colorScheme.primary;
    final tokens = widget.tokens;
    final dense = widget.dense;

    final radius = BorderRadius.circular(dense ? 14 : 18);
    final fillColor = disabled ? tokens.inputFillDisabled : tokens.inputFill;
    final borderColor = hasFocus ? tokens.inputStrokeActive : tokens.inputStroke;
    final haloColor = hasFocus ? tokens.inputShadowActive : tokens.inputShadow;

    final labelStyle = GoogleFonts.inter(
      fontSize: dense ? 10.5 : 11.5,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
      color: tokens.chipFg.withOpacity(hasFocus ? 0.82 : 0.62),
    );

    final valueColor = brandColor.withOpacity(
      disabled
          ? 0.45
          : hasValue
              ? (isDark ? 0.96 : 0.9)
              : (isDark ? 0.7 : 0.68),
    );
    final keypadTypeface = Theme.of(context).textTheme.titleLarge ??
        Theme.of(context).textTheme.bodyMedium ??
        const TextStyle();
    final valueStyle = keypadTypeface.copyWith(
      fontSize: showLabel
          ? (dense ? 16 : 18)
          : (dense ? 18 : 20),
      fontWeight: FontWeight.w600,
      color: valueColor,
      height: 1.1,
    );

    final placeholderStyle = valueStyle.copyWith(
      color: tokens.inputPlaceholder,
    );

    final double horizontalPadding =
        showLabel ? (dense ? 10 : 12) : (dense ? 11 : 14);
    final double verticalPadding =
        showLabel ? (dense ? 4 : 6) : (dense ? 6 : 8);
    final double minHeight = dense ? 40 : 46;

    final Widget textField = SizedBox(
      width: double.infinity,
      child: TextFormField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        enabled: !widget.readOnly,
        readOnly: true,
        showCursor: !widget.readOnly,
        onTap: widget.readOnly ? null : widget.onTap,
        keyboardType: TextInputType.none,
        validator: widget.validator,
        style: valueStyle,
        cursorColor: brandColor,
        cursorOpacityAnimates: true,
        cursorWidth: 2.0,
        cursorRadius: const Radius.circular(20),
        enableInteractiveSelection: false,
        textAlignVertical: TextAlignVertical.center,
        textAlign: TextAlign.center,
        decoration: const InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );

    final Widget inputSurface = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.readOnly ? null : widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        constraints: showLabel ? null : BoxConstraints(minHeight: minHeight),
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: radius,
          border: Border.all(
            color: borderColor,
            width: showLabel ? 0.6 : 0.8,
          ),
          boxShadow: disabled
              ? null
              : [
                  BoxShadow(
                    color: haloColor,
                    blurRadius: hasFocus ? 18 : 10,
                    spreadRadius: hasFocus ? 0.6 : 0.1,
                    offset: Offset(0, hasFocus ? 8 : 4),
                  ),
                ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (!showLabel && !hasValue)
              Align(
                alignment: Alignment.center,
                child: Text(
                  widget.placeholder ?? widget.label,
                  style: placeholderStyle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                ),
              ),
            textField,
          ],
        ),
      ),
    );

    if (showLabel) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.label, style: labelStyle),
          SizedBox(height: widget.dense ? 2 : 4),
          inputSurface,
        ],
      );
    }

    return inputSurface;
  }
}

class _RoundButton extends StatefulWidget {
  final SetCardTheme tokens;
  final IconData icon;
  final bool filled;
  final String semantics;
  final VoidCallback? onTap;
  final bool dense;
  final Color? iconColor;
  final Color? disabledIconColor;
  final Color? filledIconColor;
  const _RoundButton({
    required this.tokens,
    required this.icon,
    required this.filled,
    required this.semantics,
    this.onTap,
    this.dense = false,
    this.iconColor,
    this.disabledIconColor,
    this.filledIconColor,
  });

  @override
  State<_RoundButton> createState() => _RoundButtonState();
}

class _RoundButtonState extends State<_RoundButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final size = widget.dense ? 40.0 : 44.0;
    final scale = _pressed ? 0.98 : 1.0;
    return Semantics(
      label: widget.semantics,
      button: true,
      child: GestureDetector(
        onTapDown: widget.onTap == null
            ? null
            : (_) => setState(() => _pressed = true),
        onTapUp: widget.onTap == null
            ? null
            : (_) => setState(() => _pressed = false),
        onTapCancel: widget.onTap == null
            ? null
            : () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 80),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: widget.tokens.cardFill,
              boxShadow: widget.onTap == null
                  ? null
                  : [
                      BoxShadow(
                        color: widget.tokens.menuFg
                            .withOpacity(widget.filled ? 0.26 : 0.14),
                        blurRadius: widget.filled ? 16 : 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            child: Icon(
              widget.icon,
              color: () {
                final theme = Theme.of(context);
                final brandOn = theme.extension<BrandOnColors>();
                if (widget.filled) {
                  return widget.filledIconColor ??
                      brandOn?.onCta ??
                      theme.colorScheme.onPrimary;
                }
                if (widget.onTap == null) {
                  return widget.disabledIconColor ??
                      widget.tokens.menuFg.withOpacity(0.55);
                }
                return widget.iconColor ??
                    theme.colorScheme.onSurface.withOpacity(0.8);
              }(),
            ),
          ),
        ),
      ),
    );
  }
}
