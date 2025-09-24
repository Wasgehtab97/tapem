// lib/features/device/presentation/widgets/set_card.dart
// SetCard with silent controller updates to prevent re-entrant rebuilds.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/device_provider.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/branding_provider.dart';
import 'package:tapem/core/ui_mutation_guard.dart';
import 'package:tapem/core/theme/brand_on_colors.dart';
import 'package:tapem/core/widgets/brand_outline.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/ui/numeric_keypad/overlay_numeric_keypad.dart';
import 'package:tapem/core/logging/elog.dart';
import 'package:tapem/core/services/workout_session_duration_service.dart';

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

  const SetCardTheme({
    required this.padding,
    required this.chipBg,
    required this.chipFg,
    required this.chipBorder,
    required this.doneOn,
    required this.doneOff,
    required this.menuBg,
    required this.menuFg,
  });

  factory SetCardTheme.of(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    Color tint(Color base, {double lightAlpha = 0.12, double darkAlpha = 0.2}) {
      final alpha = isDark ? darkAlpha : lightAlpha;
      return Color.alphaBlend(scheme.primary.withOpacity(alpha), base);
    }

    return SetCardTheme(
      padding: const EdgeInsets.all(16),
      chipBg: tint(scheme.surface, lightAlpha: 0.14, darkAlpha: 0.28),
      chipFg: scheme.onSurface,
      chipBorder: scheme.primary,
      doneOn: scheme.primary,
      doneOff: scheme.onSurface.withOpacity(0.5),
      menuBg: tint(scheme.surfaceVariant, lightAlpha: 0.12, darkAlpha: 0.24),
      menuFg: scheme.primary,
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
    );
  }
}

enum SetCardSize { regular, dense }

enum SetCardDisplayMode { standalone, grouped }

class SetCard extends StatefulWidget {
  final int index;
  final Map<String, dynamic> set;
  final Map<String, dynamic>? previous;
  final bool showPrevious;
  final SetCardSize size;
  final bool readOnly;
  final SetCardDisplayMode displayMode;
  final BorderRadiusGeometry? groupedRadius;
  const SetCard({
    super.key,
    required this.index,
    required this.set,
    this.previous,
    this.showPrevious = false,
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
  late final TextEditingController _dropWeightCtrl;
  late final TextEditingController _dropRepsCtrl;
  late final FocusNode _weightFocus;
  late final FocusNode _repsFocus;
  late final FocusNode _dropWeightFocus;
  late final FocusNode _dropRepsFocus;

  bool _showExtras = false;

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

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController(text: widget.set['weight'] as String?);
    _repsCtrl = TextEditingController(text: widget.set['reps'] as String?);
    _dropWeightCtrl =
        TextEditingController(text: widget.set['dropWeight'] as String?);
    _dropRepsCtrl =
        TextEditingController(text: widget.set['dropReps'] as String?);
    _weightFocus = FocusNode();
    _repsFocus = FocusNode();
    _dropWeightFocus = FocusNode();
    _dropRepsFocus = FocusNode();

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
      _dropWeightCtrl.addListener(() {
        if (_muteCtrls) return;
        _slog(widget.index, 'dropWeight → "${_dropWeightCtrl.text}"');
        context.read<DeviceProvider>().updateSet(
          widget.index,
          dropWeight: _dropWeightCtrl.text,
          dropReps: _dropRepsCtrl.text,
        );
      });
      _dropRepsCtrl.addListener(() {
        if (_muteCtrls) return;
        _slog(widget.index, 'dropReps → "${_dropRepsCtrl.text}"');
        context.read<DeviceProvider>().updateSet(
          widget.index,
          dropWeight: _dropWeightCtrl.text,
          dropReps: _dropRepsCtrl.text,
        );
      });
    }
  }

  @override
  void didUpdateWidget(covariant SetCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final w = widget.set['weight'] as String? ?? '';
    final r = widget.set['reps'] as String? ?? '';
    final dw = widget.set['dropWeight'] as String? ?? '';
    final dr = widget.set['dropReps'] as String? ?? '';
    if (oldWidget.set['weight'] != w) {
      _slog(widget.index, 'didUpdateWidget sync weight "$w"');
      _setTextSilently(_weightCtrl, w, 'weight');
    }
    if (oldWidget.set['reps'] != r) {
      _slog(widget.index, 'didUpdateWidget sync reps "$r"');
      _setTextSilently(_repsCtrl, r, 'reps');
    }
    if (oldWidget.set['dropWeight'] != dw) {
      _slog(widget.index, 'didUpdateWidget sync dropWeight "$dw"');
      _setTextSilently(_dropWeightCtrl, dw, 'dropWeight');
    }
    if (oldWidget.set['dropReps'] != dr) {
      _slog(widget.index, 'didUpdateWidget sync dropReps "$dr"');
      _setTextSilently(_dropRepsCtrl, dr, 'dropReps');
    }
  }

  @override
  void dispose() {
    _slog(widget.index, 'dispose()');
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    _dropWeightCtrl.dispose();
    _dropRepsCtrl.dispose();
    _weightFocus.dispose();
    _repsFocus.dispose();
    _dropWeightFocus.dispose();
    _dropRepsFocus.dispose();
    super.dispose();
  }

  void _openKeypad(
    TextEditingController controller, {
    required bool allowDecimal,
  }) {
    _slog(
      widget.index,
      'open keypad allowDecimal=$allowDecimal text="${controller.text}"',
    );
    FocusScope.of(context).unfocus();
    context.read<DeviceProvider>().setFocusedIndex(widget.index);
    context.read<OverlayNumericKeypadController>().openFor(
      controller,
      allowDecimal: allowDecimal,
    );
    // Hinweis: ensureVisible nach dem Öffnen separat aufrufen (DeviceScreen macht das).
  }

  void focusWeight() {
    _openKeypad(_weightCtrl, allowDecimal: true);
  }

  String? _validateDrop(String? _) {
    final loc = AppLocalizations.of(context)!;
    final dw = _dropWeightCtrl.text.trim();
    final dr = _dropRepsCtrl.text.trim();
    if (dw.isEmpty && dr.isEmpty) return null;
    if (dw.isEmpty || dr.isEmpty) return null;
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
    final dropActive =
        (widget.set['dropWeight'] ?? '').toString().isNotEmpty &&
            (widget.set['dropReps'] ?? '').toString().isNotEmpty;
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
    VoidCallback? toggleExtras;
    if (!widget.readOnly) {
      toggleExtras = () {
        _slog(
          widget.index,
          'tap: more options → ${!_showExtras}',
        );
        HapticFeedback.lightImpact();
        setState(() => _showExtras = !_showExtras);
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
          final sets = prov.sets;
          final isDone = sets[widget.index]['done'] == true ||
              sets[widget.index]['done'] == 'true';
          if (isDone) {
            final service = context.read<WorkoutSessionDurationService>();
            if (!service.isRunning) {
              final auth = context.read<AuthProvider>();
              final branding = context.read<BrandingProvider>();
              final uid = auth.userId;
              final gymId = branding.gymId;
              if (uid != null && gymId != null) {
                unawaited(service.start(uid: uid, gymId: gymId));
              }
            }
          }
          context.read<OverlayNumericKeypadController>().close();
        }
      };
    }

    final displayMode = widget.displayMode;
    final contentPadding =
        displayMode == SetCardDisplayMode.grouped ? tokens.padding : EdgeInsets.zero;
    final BorderRadius? rowRadius = displayMode == SetCardDisplayMode.grouped
        ? (widget.groupedRadius as BorderRadius?)
        : null;

    final content = SetRowContent(
      tokens: tokens,
      dense: dense,
      index: widget.index + 1,
      dropActive: dropActive,
      showExtras: _showExtras,
      done: done,
      readOnly: widget.readOnly,
      filled: filled,
      isBodyweightMode: prov.isBodyweightMode,
      showPrevious: widget.showPrevious,
      previous: widget.previous,
      loc: loc,
      weightController: _weightCtrl,
      weightFocus: _weightFocus,
      repsController: _repsCtrl,
      repsFocus: _repsFocus,
      dropWeightController: _dropWeightCtrl,
      dropWeightFocus: _dropWeightFocus,
      dropRepsController: _dropRepsCtrl,
      dropRepsFocus: _dropRepsFocus,
      onToggleExtras: toggleExtras,
      onToggleDone: toggleDone,
      onTapWeight:
          widget.readOnly ? null : () => _openKeypad(_weightCtrl, allowDecimal: true),
      onTapReps:
          widget.readOnly ? null : () => _openKeypad(_repsCtrl, allowDecimal: false),
      onTapDropWeight: done || widget.readOnly
          ? null
          : () => _openKeypad(_dropWeightCtrl, allowDecimal: true),
      onTapDropReps: done || widget.readOnly
          ? null
          : () => _openKeypad(_dropRepsCtrl, allowDecimal: false),
      dropValidator: _validateDrop,
      padding: contentPadding,
      radius: rowRadius,
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
  final bool dropActive;
  final bool showExtras;
  final bool done;
  final bool readOnly;
  final bool filled;
  final bool isBodyweightMode;
  final bool showPrevious;
  final AppLocalizations loc;
  final Map<String, dynamic>? previous;
  final TextEditingController weightController;
  final FocusNode weightFocus;
  final TextEditingController repsController;
  final FocusNode repsFocus;
  final TextEditingController dropWeightController;
  final FocusNode dropWeightFocus;
  final TextEditingController dropRepsController;
  final FocusNode dropRepsFocus;
  final VoidCallback? onToggleExtras;
  final VoidCallback? onToggleDone;
  final VoidCallback? onTapWeight;
  final VoidCallback? onTapReps;
  final VoidCallback? onTapDropWeight;
  final VoidCallback? onTapDropReps;
  final FormFieldValidator<String>? dropValidator;
  final EdgeInsetsGeometry padding;
  final BorderRadius? radius;

  const SetRowContent({
    super.key,
    required this.tokens,
    required this.dense,
    required this.index,
    required this.dropActive,
    required this.showExtras,
    required this.done,
    required this.readOnly,
    required this.filled,
    required this.isBodyweightMode,
    required this.showPrevious,
    required this.loc,
    required this.previous,
    required this.weightController,
    required this.weightFocus,
    required this.repsController,
    required this.repsFocus,
    required this.dropWeightController,
    required this.dropWeightFocus,
    required this.dropRepsController,
    required this.dropRepsFocus,
    required this.onToggleExtras,
    required this.onToggleDone,
    required this.onTapWeight,
    required this.onTapReps,
    required this.onTapDropWeight,
    required this.onTapDropReps,
    required this.dropValidator,
    this.padding = EdgeInsets.zero,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final previousValue = _formatPreviousValue(loc);
    Widget body = Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _IndexBadge(
                tokens: tokens,
                index: index,
                dense: dense,
              ),
              if (dropActive) ...[
                SizedBox(width: dense ? 4 : 6),
                _DropBadge(tokens: tokens, dense: dense),
              ],
              SizedBox(width: dense ? 8 : 12),
              if (showPrevious) ...[
                Expanded(
                  flex: 3,
                  child: _DisplayPill(
                    label: loc.devicePreviousFieldLabel,
                    value: previousValue,
                    tokens: tokens,
                    dense: dense,
                  ),
                ),
                SizedBox(width: dense ? 8 : 12),
              ],
              Expanded(
                flex: showPrevious ? 3 : 4,
                child: _InputPill(
                  controller: weightController,
                  focusNode: weightFocus,
                  label: isBodyweightMode ? loc.bodyweight : 'kg',
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
                ),
              ),
              SizedBox(width: dense ? 8 : 12),
              Expanded(
                flex: showPrevious ? 2 : 3,
                child: _InputPill(
                  controller: repsController,
                  focusNode: repsFocus,
                  label: 'x',
                  readOnly: done || readOnly,
                  tokens: tokens,
                  dense: dense,
                  onTap: onTapReps,
                  validator: (v) {
                    if (v == null || v.isEmpty) return null;
                    if (int.tryParse(v) == null) return loc.intRequired;
                    return null;
                  },
                ),
              ),
              SizedBox(width: dense ? 8 : 12),
              _RoundButton(
                tokens: tokens,
                icon: showExtras ? Icons.expand_less : Icons.expand_more,
                filled: false,
                semantics: 'Mehr Optionen',
                dense: dense,
                iconColor: Colors.black,
                disabledIconColor: Colors.black,
                filledIconColor: Colors.black,
                onTap: onToggleExtras,
              ),
              SizedBox(width: dense ? 6 : 8),
              _RoundButton(
                tokens: tokens,
                icon: Icons.check,
                filled: done,
                semantics:
                    done ? loc.setReopenTooltip : loc.setCompleteTooltip,
                dense: dense,
                iconColor: Colors.black,
                disabledIconColor: Colors.black,
                filledIconColor: Colors.black,
                onTap: onToggleDone,
              ),
            ],
          ),
          if (showExtras) ...[
            SizedBox(height: dense ? 8 : 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: dropWeightController,
                    focusNode: dropWeightFocus,
                    decoration: InputDecoration(
                      labelText: loc.dropKgFieldLabel,
                      isDense: true,
                    ),
                    enabled: !readOnly,
                    readOnly: true,
                    keyboardType: TextInputType.none,
                    validator: dropValidator,
                    onTap: onTapDropWeight,
                  ),
                ),
                SizedBox(width: dense ? 8 : 12),
                Expanded(
                  child: TextFormField(
                    controller: dropRepsController,
                    focusNode: dropRepsFocus,
                    decoration: InputDecoration(
                      labelText: loc.dropRepsFieldLabel,
                      isDense: true,
                    ),
                    enabled: !readOnly,
                    readOnly: true,
                    keyboardType: TextInputType.none,
                    validator: dropValidator,
                    onTap: onTapDropReps,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );

    if (radius != null) {
      body = ClipRRect(
        borderRadius: radius!,
        child: body,
      );
    }

    return SizedBox(width: double.infinity, child: body);
  }

  String _formatPreviousValue(AppLocalizations loc) {
    if (!showPrevious) return '';
    final prev = previous;
    if (prev == null) {
      return '-';
    }
    final rawWeight = (prev['weight'] ?? '').toString().trim();
    final rawReps = (prev['reps'] ?? '').toString().trim();

    final hasWeight = rawWeight.isNotEmpty && rawWeight.toLowerCase() != 'null';
    final hasReps = rawReps.isNotEmpty && rawReps.toLowerCase() != 'null';

    if (!hasWeight && !hasReps) {
      return '-';
    }

    final weightPart = hasWeight ? '$rawWeight kg' : '– kg';
    final repsPart = hasReps ? rawReps : '–';

    return '$weightPart × $repsPart';
  }
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
    return Semantics(
      label: 'Set $index',
      child: Container(
        width: dense ? 28 : 32,
        height: dense ? 28 : 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: tokens.chipBg,
          borderRadius: BorderRadius.circular(dense ? 14 : 16),
          border: Border.all(
            color: tokens.chipBorder.withOpacity(0.65),
            width: 1.2,
          ),
        ),
        child: Text(
          '$index',
          style: TextStyle(
            color: tokens.chipFg,
            fontWeight: FontWeight.w600,
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
        color: tokens.chipBg,
        borderRadius: BorderRadius.circular(dense ? 12 : 14),
        border: Border.all(
          color: tokens.chipBorder.withOpacity(0.65),
          width: 1.2,
        ),
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

  const _InputPill({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.readOnly,
    required this.tokens,
    this.onTap,
    this.validator,
    this.dense = false,
  });

  @override
  State<_InputPill> createState() => _InputPillState();
}

class _InputPillState extends State<_InputPill> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_handleFocusChange);
    _focused = widget.focusNode.hasFocus;
  }

  @override
  void didUpdateWidget(covariant _InputPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_handleFocusChange);
      widget.focusNode.addListener(_handleFocusChange);
      _focused = widget.focusNode.hasFocus;
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocusChange);
    super.dispose();
  }

  void _handleFocusChange() {
    if (!mounted) return;
    setState(() {
      _focused = widget.focusNode.hasFocus;
    });
  }

  void _handleTap() {
    if (widget.readOnly) return;
    widget.focusNode.requestFocus();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      fontSize: widget.dense ? 12 : 13,
      fontWeight: FontWeight.w600,
      color: widget.tokens.chipFg.withOpacity(0.65),
      letterSpacing: 0.2,
    );
    final valueStyle = TextStyle(
      fontSize: widget.dense ? 16 : 18,
      fontWeight: FontWeight.w600,
      color: widget.tokens.chipFg,
      height: 1.2,
      letterSpacing: 0.1,
    );

    return Semantics(
      label: '${widget.label} ${widget.controller.text}'.trim(),
      button: !widget.readOnly,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.readOnly ? null : _handleTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            color: widget.tokens.chipBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _focused
                  ? widget.tokens.chipBorder
                  : widget.tokens.chipBorder.withOpacity(0.35),
              width: 1.2,
            ),
            boxShadow: _focused
                ? [
                    BoxShadow(
                      color: widget.tokens.chipBorder.withOpacity(0.26),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: widget.dense ? 12 : 14,
            vertical: widget.dense ? 8 : 10,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.label, style: labelStyle),
              SizedBox(height: widget.dense ? 2 : 4),
              TextFormField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                enabled: !widget.readOnly,
                readOnly: true,
                onTap: widget.readOnly ? null : _handleTap,
                keyboardType: TextInputType.none,
                validator: widget.validator,
                textAlign: TextAlign.left,
                textAlignVertical: TextAlignVertical.center,
                style: valueStyle,
                cursorColor: widget.tokens.chipBorder,
                minLines: 1,
                maxLines: 1,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isCollapsed: true,
                  contentPadding: EdgeInsets.zero,
                ),
                strutStyle: StrutStyle(
                  height: valueStyle.height,
                  fontSize: valueStyle.fontSize,
                  leading: 0.2,
                  forceStrutHeight: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DisplayPill extends StatelessWidget {
  final String label;
  final String value;
  final SetCardTheme tokens;
  final bool dense;

  const _DisplayPill({
    required this.label,
    required this.value,
    required this.tokens,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      fontSize: dense ? 12 : 13,
      color: tokens.chipFg.withOpacity(0.7),
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    );
    final valueStyle = TextStyle(
      fontSize: dense ? 15 : 17,
      fontWeight: FontWeight.w600,
      color: tokens.chipFg,
      height: 1.2,
      letterSpacing: 0.1,
    );

    return Semantics(
      label: '$label $value',
      child: Container(
        decoration: BoxDecoration(
          color: tokens.chipBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: tokens.chipBorder.withOpacity(0.6),
            width: 1.3,
          ),
        ),
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: dense ? 8 : 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: labelStyle),
            SizedBox(height: dense ? 2 : 4),
            Text(
              value,
              style: valueStyle,
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              strutStyle: StrutStyle(
                height: valueStyle.height,
                fontSize: valueStyle.fontSize,
                leading: 0.2,
                forceStrutHeight: true,
              ),
            ),
          ],
        ),
      ),
    );
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
              border: Border.all(
                color: widget.filled
                    ? widget.tokens.doneOn
                    : widget.tokens.chipBorder
                        .withOpacity(widget.onTap == null ? 0.35 : 0.7),
                width: 1.3,
              ),
              color:
                  widget.filled ? widget.tokens.doneOn : widget.tokens.menuBg,
              boxShadow: widget.onTap == null
                  ? null
                  : [
                      BoxShadow(
                        color: (widget.filled
                                ? widget.tokens.doneOn
                                : widget.tokens.chipBorder)
                            .withOpacity(0.24),
                        blurRadius: widget.filled ? 12 : 8,
                        offset: const Offset(0, 3),
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
                      widget.tokens.menuFg.withOpacity(0.6);
                }
                return widget.iconColor ?? widget.tokens.menuFg;
              }(),
            ),
          ),
        ),
      ),
    );
  }
}
