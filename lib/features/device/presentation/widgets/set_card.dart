// lib/features/device/presentation/widgets/set_card.dart
// SetCard with silent controller updates to prevent re-entrant rebuilds.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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
  final Color cardFill;

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
    );
  }
}

enum SetCardSize { regular, dense }

enum SetCardDisplayMode { standalone, grouped }

class SetCard extends StatefulWidget {
  final int index;
  final Map<String, dynamic> set;
  final Map<String, dynamic>? previous;
  final SetCardSize size;
  final bool readOnly;
  final SetCardDisplayMode displayMode;
  final BorderRadiusGeometry? groupedRadius;
  final bool showPreviousSummary;
  const SetCard({
    super.key,
    required this.index,
    required this.set,
    this.previous,
    this.size = SetCardSize.regular,
    this.readOnly = false,
    this.displayMode = SetCardDisplayMode.standalone,
    this.groupedRadius,
    this.showPreviousSummary = true,
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

  String? _buildPreviousSummary(AppLocalizations loc) {
    if (!widget.showPreviousSummary) return null;
    final prev = widget.previous;
    if (prev == null) return null;
    final rawWeight = (prev['weight'] ?? '').toString().trim();
    final rawReps = (prev['reps'] ?? '').toString().trim();
    final prevWeightRaw = rawWeight.toLowerCase() == 'null' ? '' : rawWeight;
    final prevRepsRaw = rawReps.toLowerCase() == 'null' ? '' : rawReps;
    final prevIsBodyweight = prev['isBodyweight'] == true ||
        prev['isBodyweight'] == 'true';

    String? weightPart;
    if (prevIsBodyweight) {
      final sanitized = prevWeightRaw.replaceAll(',', '.');
      final parsed = double.tryParse(sanitized);
      if (parsed == null || parsed == 0) {
        weightPart = loc.bodyweight;
      } else {
        weightPart = loc.bodyweightPlus(prevWeightRaw);
      }
    } else if (prevWeightRaw.isNotEmpty) {
      weightPart = '$prevWeightRaw kg';
    }

    final repsPart = prevRepsRaw.isEmpty ? null : prevRepsRaw;

    if (weightPart != null && repsPart != null) {
      return '$weightPart × $repsPart';
    }

    if (weightPart != null) {
      return weightPart;
    }

    if (repsPart != null) {
      return '× $repsPart';
    }

    return null;
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
    final previousSummary = _buildPreviousSummary(loc);
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

    Widget content = SetRowContent(
      tokens: tokens,
      dense: dense,
      index: widget.index + 1,
      dropActive: dropActive,
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
      previousSummary: previousSummary,
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
  final bool dropActive;
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
  final String? previousSummary;

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
    required this.loc,
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
    this.previousSummary,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

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
              Expanded(
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
                  supportingText: previousSummary == null
                      ? null
                      : '${loc.setCardPreviousLabel}: $previousSummary',
                  showLabel: false,
                  placeholder:
                      isBodyweightMode ? loc.bodyweight : 'kg',
                ),
              ),
              SizedBox(width: dense ? 8 : 12),
              Expanded(
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
                  showLabel: false,
                  placeholder: 'wdh',
                ),
              ),
              SizedBox(width: dense ? 8 : 12),
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
              SizedBox(width: dense ? 6 : 8),
              _RoundButton(
                tokens: tokens,
                icon: Icons.check,
                filled: done,
                semantics:
                    done ? loc.setReopenTooltip : loc.setCompleteTooltip,
                dense: dense,
                onTap: onToggleDone,
                iconColor: primaryColor,
                filledIconColor: primaryColor,
                disabledIconColor: primaryColor.withOpacity(0.4),
              ),
            ],
          ),
          if (showExtras) ...[
            SizedBox(height: dense ? 8 : 12),
            Row(
              children: [
                Expanded(
                  child: _InputPill(
                    controller: dropWeightController,
                    focusNode: dropWeightFocus,
                    label: loc.dropKgFieldLabel,
                    readOnly: readOnly || done,
                    tokens: tokens,
                    dense: true,
                    onTap: onTapDropWeight,
                    validator: dropValidator,
                    placeholder: 'kg',
                  ),
                ),
                SizedBox(width: dense ? 8 : 12),
                Expanded(
                  child: _InputPill(
                    controller: dropRepsController,
                    focusNode: dropRepsFocus,
                    label: loc.dropRepsFieldLabel,
                    readOnly: readOnly || done,
                    tokens: tokens,
                    dense: true,
                    onTap: onTapDropReps,
                    validator: dropValidator,
                    placeholder: 'wdh',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );

      return SizedBox(width: double.infinity, child: body);
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
  final String? supportingText;
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
    this.supportingText,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final radius = BorderRadius.circular(widget.dense ? 18 : 22);
    final baseOverlay = showLabel
        ? Color.alphaBlend(
            widget.tokens.menuFg.withOpacity(hasFocus ? 0.22 : 0.1),
            widget.tokens.chipBg,
          )
        : widget.tokens.cardFill;
    final haloColor = widget.tokens.menuFg.withOpacity(showLabel
        ? (hasFocus ? 0.28 : 0.08)
        : (hasFocus ? 0.32 : 0.14));
    final borderColor = widget.tokens.chipFg.withOpacity(showLabel
        ? (hasFocus ? 0.32 : 0.18)
        : (hasFocus ? 0.45 : 0.28));

    final labelStyle = GoogleFonts.inter(
      fontSize: widget.dense ? 11 : 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
      color: widget.tokens.chipFg.withOpacity(hasFocus ? 0.8 : 0.6),
    );

    final valueColor = widget.tokens.chipFg
        .withOpacity(disabled ? 0.4 : (hasValue ? 0.95 : 0.55));
    final valueStyle = GoogleFonts.spaceGrotesk(
      fontSize: showLabel ? (widget.dense ? 18 : 20) : (widget.dense ? 22 : 26),
      fontWeight: FontWeight.w700,
      color: valueColor,
      height: 1.15,
    );

    final placeholderStyle = valueStyle.copyWith(
      color: widget.tokens.chipFg.withOpacity(0.35),
    );

    final supportingStyle = TextStyle(
      fontSize: widget.dense ? 11 : 12,
      color: widget.tokens.chipFg.withOpacity(isDark ? 0.55 : 0.5),
    );

    final double horizontalPadding =
        showLabel ? (widget.dense ? 16 : 18) : (widget.dense ? 18 : 22);
    final double verticalPadding =
        showLabel ? (widget.dense ? 9 : 12) : (widget.dense ? 12 : 16);

    final Widget textField = SizedBox(
      width: double.infinity,
      child: TextFormField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        enabled: !widget.readOnly,
        readOnly: true,
        showCursor: false,
        onTap: widget.readOnly ? null : widget.onTap,
        keyboardType: TextInputType.none,
        validator: widget.validator,
        style: valueStyle,
        cursorColor: Colors.transparent,
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
        constraints:
            showLabel ? null : BoxConstraints(minHeight: widget.dense ? 58 : 68),
        decoration: BoxDecoration(
          color: baseOverlay,
          borderRadius: radius,
          border: Border.all(
            color: borderColor,
            width: showLabel ? 1 : 1.2,
          ),
          boxShadow: disabled
              ? null
              : [
                  BoxShadow(
                    color: haloColor,
                    blurRadius:
                        hasFocus ? (showLabel ? 24 : 28) : (showLabel ? 12 : 16),
                    spreadRadius:
                        hasFocus ? (showLabel ? 0.8 : 0.9) : (showLabel ? 0.2 : 0.3),
                    offset:
                        Offset(0, hasFocus ? (showLabel ? 10 : 12) : (showLabel ? 6 : 8)),
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
                ),
              ),
            textField,
          ],
        ),
      ),
    );

    final Widget supporting = AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: widget.supportingText == null
          ? const SizedBox.shrink()
          : Padding(
              key: ValueKey(widget.supportingText),
              padding: EdgeInsets.only(
                top: showLabel ? (widget.dense ? 4 : 6) : (widget.dense ? 6 : 8),
              ),
              child: Text(
                widget.supportingText!,
                style: supportingStyle,
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
          supporting,
        ],
      );
    }

    if (widget.supportingText != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          inputSurface,
          supporting,
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
