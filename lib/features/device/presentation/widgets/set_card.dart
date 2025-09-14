// lib/features/device/presentation/widgets/set_card.dart
// SetCard with silent controller updates to prevent re-entrant rebuilds.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/device_provider.dart';
import 'package:tapem/core/ui_mutation_guard.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/brand_on_colors.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/ui/numeric_keypad/overlay_numeric_keypad.dart';
import 'package:tapem/core/logging/elog.dart';
import 'package:tapem/core/util/duration_utils.dart';
import 'package:tapem/core/config/remote_config.dart';
import 'package:tapem/core/util/number_utils.dart';

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
    final scheme = Theme.of(context).colorScheme;
    return SetCardTheme(
      padding: const EdgeInsets.all(16),
      chipBg: scheme.surfaceVariant.withOpacity(0.7),
      chipFg: scheme.onSurface,
      chipBorder: scheme.primary,
      doneOn: Colors.green,
      doneOff: scheme.onSurface.withOpacity(0.5),
      menuBg: scheme.surfaceVariant.withOpacity(0.5),
      menuFg: scheme.onSurface.withOpacity(0.8),
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

class SetCard extends StatefulWidget {
  final int index;
  final Map<String, dynamic> set;
  final Map<String, dynamic>? previous;
  final SetCardSize size;
  final bool readOnly;
  const SetCard({
    super.key,
    required this.index,
    required this.set,
    this.previous,
    this.size = SetCardSize.regular,
    this.readOnly = false,
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
  late final TextEditingController _speedCtrl;
  late final FocusNode _speedFocus;

  Stopwatch? _sw;
  Timer? _ticker;
  int _elapsed = 0;
  bool _running = false;

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
    _speedCtrl = TextEditingController(text: widget.set['speed'] as String?);
    _weightFocus = FocusNode();
    _repsFocus = FocusNode();
    _dropWeightFocus = FocusNode();
    _dropRepsFocus = FocusNode();
    _speedFocus = FocusNode();
    _elapsed = parseHms(widget.set['duration'] as String? ?? '');

    if (!widget.readOnly) {
      final prov = context.read<DeviceProvider>();
      final cardio = prov.device?.isCardio == true;
      if (cardio) {
        _speedCtrl.addListener(() {
          if (_muteCtrls) return;
          prov.updateSet(
            widget.index,
            speed: _speedCtrl.text,
          );
        });
      } else {
        _weightCtrl.addListener(() {
          if (_muteCtrls) return;
          _slog(widget.index, 'weight → "${_weightCtrl.text}"');
          prov.updateSet(
            widget.index,
            weight: _weightCtrl.text,
            isBodyweight: prov.isBodyweightMode,
          );
        });
        _repsCtrl.addListener(() {
          if (_muteCtrls) return;
          _slog(widget.index, 'reps → "${_repsCtrl.text}"');
          prov.updateSet(
            widget.index,
            reps: _repsCtrl.text,
          );
        });
        _dropWeightCtrl.addListener(() {
          if (_muteCtrls) return;
          _slog(widget.index, 'dropWeight → "${_dropWeightCtrl.text}"');
          prov.updateSet(
            widget.index,
            dropWeight: _dropWeightCtrl.text,
            dropReps: _dropRepsCtrl.text,
          );
        });
        _dropRepsCtrl.addListener(() {
          if (_muteCtrls) return;
          _slog(widget.index, 'dropReps → "${_dropRepsCtrl.text}"');
          prov.updateSet(
            widget.index,
            dropWeight: _dropWeightCtrl.text,
            dropReps: _dropRepsCtrl.text,
          );
        });
      }
    }
  }

  @override
  void didUpdateWidget(covariant SetCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final prov = context.read<DeviceProvider>();
    final cardio = prov.device?.isCardio == true;
    if (cardio) {
      final sp = widget.set['speed'] as String? ?? '';
      final du = widget.set['duration'] as String? ?? '';
      if (oldWidget.set['speed'] != sp) {
        _setTextSilently(_speedCtrl, sp, 'speed');
      }
      if (!_running) {
        final sec = parseHms(du);
        if (sec != _elapsed) {
          _elapsed = sec;
        }
      }
      return;
    }
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
    _speedCtrl.dispose();
    _ticker?.cancel();
    _sw?.stop();
    _weightFocus.dispose();
    _repsFocus.dispose();
    _dropWeightFocus.dispose();
    _dropRepsFocus.dispose();
    _speedFocus.dispose();
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

  void _startTimer() {
    if (_running) return;
    HapticFeedback.mediumImpact();
    _sw = Stopwatch()..start();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsed = _sw!.elapsed.inSeconds;
      });
    });
    setState(() {
      _running = true;
    });
    elogUi('cardio_timer_started', {'set': widget.index + 1});
  }

  void _stopTimer() {
    if (!_running) return;
    _sw?.stop();
    _ticker?.cancel();
    final sec = _sw?.elapsed.inSeconds ?? _elapsed;
    setState(() {
      _elapsed = sec;
      _running = false;
    });
    final formatted = formatHms(_elapsed);
    context.read<DeviceProvider>().updateSet(
          widget.index,
          duration: formatted,
        );
    elogUi('cardio_timer_stopped', {
      'set': widget.index + 1,
      'durationSec': _elapsed,
    });
  }

  void _clearTimer() {
    if (_running) {
      _stopTimer();
    }
    setState(() {
      _elapsed = 0;
    });
    context.read<DeviceProvider>().updateSet(widget.index, duration: '');
  }

  void stopTimerIfRunning() {
    if (_running) {
      _stopTimer();
    }
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
    final surface = Theme.of(context).extension<AppBrandTheme>();

    var gradient = surface?.gradient ?? AppGradients.brandGradient;
    if (surface != null) {
      final lums = gradient.colors.map((c) => c.computeLuminance());
      final lum = lums.reduce((a, b) => a + b) / gradient.colors.length;
      final delta = surface.luminanceRef - lum;
      gradient = Tone.gradient(gradient, delta);
    }
    final doneVal = widget.set['done'];
    final done = doneVal == true || doneVal == 'true';
    final isCardio = prov.device?.isCardio == true;
    if (isCardio) {
      final speed = (widget.set['speed'] ?? '').toString().trim();
      final speedVal = parseLenientDouble(speed);
      final durSec = _elapsed;
      final speedValid = speedVal != null &&
          speedVal > 0 &&
          speedVal <= RC.cardioMaxSpeedKmH;
      final durValid = durSec == 0 || (durSec > 0 && durSec <= RC.cardioMaxDurationSec);
      final filled = speedValid && durValid;
      return Semantics(
        label: 'Set ${widget.index + 1}',
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius:
                surface?.radius as BorderRadius? ??
                BorderRadius.circular(AppRadius.button),
            boxShadow: surface?.shadow,
          ),
          padding: tokens.padding,
          child: Row(
            children: [
              _IndexBadge(
                tokens: tokens,
                index: widget.index + 1,
                dense: dense,
              ),
              SizedBox(width: dense ? 8 : 12),
              Expanded(
                child: Semantics(
                  label: loc.speedInKmH,
                  child: _InputPill(
                    controller: _speedCtrl,
                    focusNode: _speedFocus,
                    label: 'km/h',
                    readOnly: done || widget.readOnly,
                    tokens: tokens,
                    dense: dense,
                    onTap: widget.readOnly
                        ? null
                        : () => _openKeypad(_speedCtrl, allowDecimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return null;
                      final numVal = parseLenientDouble(v);
                      if (numVal == null) return loc.numberInvalid;
                      if (numVal <= 0 || numVal > RC.cardioMaxSpeedKmH) {
                        return loc.speedOutOfRange(RC.cardioMaxSpeedKmH);
                      }
                      return null;
                    },
                  ),
                ),
              ),
              SizedBox(width: dense ? 8 : 12),
              Expanded(
                child: _TimerControl(
                  elapsed: _elapsed,
                  running: _running,
                  readOnly: done || widget.readOnly,
                  tokens: tokens,
                  dense: dense,
                  loc: loc,
                  onStart: _startTimer,
                  onStop: _stopTimer,
                  onClear: _clearTimer,
                ),
              ),
              SizedBox(width: dense ? 8 : 12),
              _RoundButton(
                tokens: tokens,
                icon: Icons.check,
                filled: done,
                semantics:
                    done ? loc.setReopenTooltip : loc.setCompleteTooltip,
                dense: dense,
                onTap: widget.readOnly || !filled
                    ? null
                    : () {
                        final prov = context.read<DeviceProvider>();
                        final ok = prov.toggleSetDone(widget.index);
                        if (ok) {
                          context
                              .read<OverlayNumericKeypadController>()
                              .close();
                        }
                      },
              ),
            ],
          ),
        ),
      );
    }
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

    return Semantics(
      label: 'Set ${widget.index + 1}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius:
              surface?.radius as BorderRadius? ??
              BorderRadius.circular(AppRadius.button),
          boxShadow: surface?.shadow,
        ),
        padding: tokens.padding,
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _IndexBadge(
                  tokens: tokens,
                  index: widget.index + 1,
                  dense: dense,
                ),
                if (dropActive) ...[
                  SizedBox(width: dense ? 4 : 6),
                  _DropBadge(tokens: tokens, dense: dense),
                ],
                SizedBox(width: dense ? 8 : 12),
                Expanded(
                  child: _InputPill(
                    controller: _weightCtrl,
                    focusNode: _weightFocus,
                    label: prov.isBodyweightMode ? loc.bodyweight : 'kg',
                    readOnly: done || widget.readOnly,
                    tokens: tokens,
                    dense: dense,
                    onTap: widget.readOnly
                        ? null
                        : () => _openKeypad(_weightCtrl, allowDecimal: true),
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
                  child: _InputPill(
                    controller: _repsCtrl,
                    focusNode: _repsFocus,
                    label: 'x',
                    readOnly: done || widget.readOnly,
                    tokens: tokens,
                    dense: dense,
                    onTap: widget.readOnly
                        ? null
                        : () => _openKeypad(_repsCtrl, allowDecimal: false),
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
                  icon: Icons.check,
                  filled: done,
                  semantics:
                      done ? loc.setReopenTooltip : loc.setCompleteTooltip,
                  dense: dense,
                  onTap: widget.readOnly || !filled
                      ? null
                      : () {
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
                            context
                                .read<OverlayNumericKeypadController>()
                                .close();
                          }
                        },
                ),
                SizedBox(width: dense ? 6 : 8),
                _RoundButton(
                  tokens: tokens,
                  icon: _showExtras ? Icons.expand_less : Icons.more_horiz,
                  filled: false,
                  semantics: 'Mehr Optionen',
                  dense: dense,
                  onTap: widget.readOnly
                      ? null
                      : () {
                          _slog(
                            widget.index,
                            'tap: more options → ${!_showExtras}',
                          );
                          HapticFeedback.lightImpact();
                          setState(() => _showExtras = !_showExtras);
                        },
                ),
              ],
            ),
            if (_showExtras) ...[
              SizedBox(height: dense ? 8 : 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _dropWeightCtrl,
                      focusNode: _dropWeightFocus,
                      decoration: InputDecoration(
                        labelText: loc.dropKgFieldLabel,
                        isDense: true,
                      ),
                      enabled: !widget.readOnly,
                      readOnly: true,
                      keyboardType: TextInputType.none,
                      validator: _validateDrop,
                      onTap: done || widget.readOnly
                          ? null
                          : () =>
                              _openKeypad(_dropWeightCtrl, allowDecimal: true),
                    ),
                  ),
                  SizedBox(width: dense ? 8 : 12),
                  Expanded(
                    child: TextFormField(
                      controller: _dropRepsCtrl,
                      focusNode: _dropRepsFocus,
                      decoration: InputDecoration(
                        labelText: loc.dropRepsFieldLabel,
                        isDense: true,
                      ),
                      enabled: !widget.readOnly,
                      readOnly: true,
                      keyboardType: TextInputType.none,
                      validator: _validateDrop,
                      onTap: done || widget.readOnly
                          ? null
                          : () => _openKeypad(
                                _dropRepsCtrl,
                                allowDecimal: false,
                              ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
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
          border: Border.all(color: tokens.chipFg.withOpacity(0.2)),
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
        border: Border.all(color: tokens.chipFg.withOpacity(0.2)),
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

class _InputPill extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: readOnly ? null : () => onTap?.call(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x1FFFFFFF), Color(0x14FFFFFF)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                focusNode.hasFocus
                    ? tokens.chipBorder
                    : tokens.chipFg.withOpacity(0.3),
            width: 1.3,
          ),
          boxShadow:
              focusNode.hasFocus
                  ? [
                    BoxShadow(
                      color: tokens.chipBorder.withOpacity(0.4),
                      blurRadius: 8,
                    ),
                  ]
                  : null,
        ),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: dense ? 2 : 4),
        alignment: Alignment.center,
        child: TextFormField(
          controller: controller,
          focusNode: focusNode,
          enabled: !readOnly,
          readOnly: true,
          onTap: readOnly ? null : onTap,
          keyboardType: TextInputType.none,
          decoration: InputDecoration(
            border: InputBorder.none,
            labelText: label,
            labelStyle: dense ? const TextStyle(fontSize: 14) : null,
          ),
          style: dense ? const TextStyle(fontSize: 14) : null,
          validator: validator,
        ),
      ),
    );
  }
}

class _TimerControl extends StatelessWidget {
  final int elapsed;
  final bool running;
  final bool readOnly;
  final SetCardTheme tokens;
  final bool dense;
  final AppLocalizations loc;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onClear;

  const _TimerControl({
    required this.elapsed,
    required this.running,
    required this.readOnly,
    required this.tokens,
    required this.dense,
    required this.loc,
    required this.onStart,
    required this.onStop,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final text = formatHms(elapsed);
    final display = readOnly && elapsed == 0 ? '—' : text;
    final canClear = !running && elapsed > 0 && !readOnly;
    return Semantics(
      button: !readOnly,
      label: readOnly
          ? display
          : running
              ? loc.timerStop
              : loc.timerStart,
      child: GestureDetector(
        onTap: readOnly
            ? null
            : running
                ? onStop
                : onStart,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x1FFFFFFF), Color(0x14FFFFFF)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: tokens.chipFg.withOpacity(0.3),
              width: 1.3,
            ),
          ),
          padding:
              EdgeInsets.symmetric(horizontal: 12, vertical: dense ? 2 : 4),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!readOnly)
                Icon(
                  running ? Icons.stop_circle : Icons.play_circle,
                  size: dense ? 20 : 24,
                  color: tokens.chipFg,
                ),
              if (!readOnly) const SizedBox(width: 4),
              Text(
                display,
                style: TextStyle(
                  color: tokens.chipFg,
                  fontSize: dense ? 14 : 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (canClear) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onClear,
                  child: Icon(
                    Icons.close,
                    size: dense ? 16 : 18,
                    color: tokens.chipFg.withOpacity(0.7),
                  ),
                ),
              ],
            ],
          ),
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
  const _RoundButton({
    required this.tokens,
    required this.icon,
    required this.filled,
    required this.semantics,
    this.onTap,
    this.dense = false,
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
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x1FFFFFFF), Color(0x14FFFFFF)],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color:
                    widget.filled
                        ? widget.tokens.doneOn
                        : widget.tokens.chipFg.withOpacity(0.3),
                width: 1.3,
              ),
              color:
                  widget.filled ? widget.tokens.doneOn : widget.tokens.menuBg,
            ),
            child: Icon(
              widget.icon,
              color:
                  widget.filled
                      ? Theme.of(context).extension<BrandOnColors>()?.onCta ?? Theme.of(context).colorScheme.onPrimary
                      : widget.tokens.menuFg,
            ),
          ),
        ),
      ),
    );
  }
}
