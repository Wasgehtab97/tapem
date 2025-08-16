// lib/features/device/presentation/widgets/set_card.dart
// SetCard with silent controller updates to prevent re-entrant rebuilds.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/device_provider.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/ui/numeric_keypad/overlay_numeric_keypad.dart';

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
  const SetCard({
    super.key,
    required this.index,
    required this.set,
    this.previous,
    this.size = SetCardSize.regular,
  });

  @override
  State<SetCard> createState() => SetCardState();
}

class SetCardState extends State<SetCard> {
  late final TextEditingController _weightCtrl;
  late final TextEditingController _repsCtrl;
  late final TextEditingController _rirCtrl;
  final List<TextEditingController> _dropWeightCtrls = [];
  final List<TextEditingController> _dropRepsCtrls = [];
  late final FocusNode _weightFocus;
  late final FocusNode _repsFocus;
  late final FocusNode _rirFocus;
  final FocusNode _noteFocus = FocusNode();
  final List<FocusNode> _dropWeightFocuses = [];
  final List<FocusNode> _dropRepsFocuses = [];

  final GlobalKey _plusKey = GlobalKey();
  final List<String> _registeredIds = [];

  bool _showExtras = false;

  // 🔒 Silent-update Mechanik
  bool _muteCtrls = false;
  void _setTextSilently(TextEditingController c, String text) {
    if (c.text == text) return;
    _muteCtrls = true;
    c.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _muteCtrls = false;
  }

  void _onDropChanged() {
    if (_muteCtrls) return;
    _syncDropSets();
  }

  void _syncDropSets() {
    final drops = <Map<String, String>>[];
    for (var i = 0; i < _dropWeightCtrls.length; i++) {
      drops.add({
        'weight': _dropWeightCtrls[i].text,
        'reps': _dropRepsCtrls[i].text,
      });
    }
    context
        .read<DeviceProvider>()
        .updateSet(widget.index, dropSets: drops);
  }

  void _rebuildDropCtrls(List drops) {
    for (final c in _dropWeightCtrls) {
      c.dispose();
    }
    for (final c in _dropRepsCtrls) {
      c.dispose();
    }
    for (final f in _dropWeightFocuses) {
      f.dispose();
    }
    for (final f in _dropRepsFocuses) {
      f.dispose();
    }
    _dropWeightCtrls.clear();
    _dropRepsCtrls.clear();
    _dropWeightFocuses.clear();
    _dropRepsFocuses.clear();

    for (final d in drops) {
      final w = TextEditingController(text: d['weight'] as String?);
      final r = TextEditingController(text: d['reps'] as String?);
      final wf = FocusNode();
      final rf = FocusNode();
      w.addListener(_onDropChanged);
      r.addListener(_onDropChanged);
      _dropWeightCtrls.add(w);
      _dropRepsCtrls.add(r);
      _dropWeightFocuses.add(wf);
      _dropRepsFocuses.add(rf);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _registerTargets());
  }

  void _addDropSet() {
    setState(() {
      final w = TextEditingController();
      final r = TextEditingController();
      final wf = FocusNode();
      final rf = FocusNode();
      w.addListener(_onDropChanged);
      r.addListener(_onDropChanged);
      _dropWeightCtrls.add(w);
      _dropRepsCtrls.add(r);
      _dropWeightFocuses.add(wf);
      _dropRepsFocuses.add(rf);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _registerTargets();
      final i = _dropWeightCtrls.length - 1;
      if (i < 0) return;
      FocusScope.of(context).requestFocus(_dropWeightFocuses[i]);
      _openKeypad(_dropWeightCtrls[i], allowDecimal: true);
      final ctx = _dropWeightFocuses[i].context;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.5,
          duration: const Duration(milliseconds: 200),
        );
      }
    });
  }

  void _unregisterTargets() {
    for (final id in _registeredIds) {
      KeypadTargetRegistry.unregister(id);
    }
    _registeredIds.clear();
  }

  void _registerTargets() {
    _unregisterTargets();
    String base(String suffix) => 'set${widget.index}_$suffix';
    void add(KeypadTarget t) {
      KeypadTargetRegistry.register(t);
      _registeredIds.add(t.id);
    }

    add(KeypadTarget(
      id: base('weight'),
      focusNode: _weightFocus,
      controller: _weightCtrl,
      allowDecimal: true,
      type: KeypadTargetType.numeric,
    ));
    add(KeypadTarget(
      id: base('reps'),
      focusNode: _repsFocus,
      controller: _repsCtrl,
      allowDecimal: false,
      type: KeypadTargetType.numeric,
    ));
    for (var i = 0; i < _dropWeightCtrls.length; i++) {
      add(KeypadTarget(
        id: base('drop${i}_w'),
        focusNode: _dropWeightFocuses[i],
        controller: _dropWeightCtrls[i],
        allowDecimal: true,
        type: KeypadTargetType.numeric,
      ));
      add(KeypadTarget(
        id: base('drop${i}_r'),
        focusNode: _dropRepsFocuses[i],
        controller: _dropRepsCtrls[i],
        allowDecimal: false,
        type: KeypadTargetType.numeric,
      ));
    }
    add(KeypadTarget(
      id: base('rir'),
      focusNode: _rirFocus,
      type: KeypadTargetType.text,
    ));
    add(KeypadTarget(
      id: base('note'),
      focusNode: _noteFocus,
      type: KeypadTargetType.text,
    ));
    add(KeypadTarget(
      id: base('plus'),
      key: _plusKey,
      onPressed: _addDropSet,
      type: KeypadTargetType.plus,
    ));
  }

  String? _validateDrop(int i, String? _) {
    final loc = AppLocalizations.of(context)!;
    final dw = _dropWeightCtrls[i].text.trim();
    final dr = _dropRepsCtrls[i].text.trim();
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
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController(text: widget.set['weight'] as String?);
    _repsCtrl = TextEditingController(text: widget.set['reps'] as String?);
    _rirCtrl = TextEditingController(text: widget.set['rir'] as String?);
    _weightFocus = FocusNode();
    _repsFocus = FocusNode();
    _rirFocus = FocusNode();

    _rebuildDropCtrls(widget.set['dropSets'] as List? ?? []);

    _weightCtrl.addListener(() {
      if (_muteCtrls) return;
      _slog(widget.index, 'weight → "${_weightCtrl.text}"');
      context.read<DeviceProvider>().updateSet(
        widget.index,
        weight: _weightCtrl.text,
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
    _rirCtrl.addListener(() {
      if (_muteCtrls) return;
      _slog(widget.index, 'rir → "${_rirCtrl.text}"');
      context.read<DeviceProvider>().updateSet(
        widget.index,
        rir: _rirCtrl.text,
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _registerTargets());
  }

  @override
  void didUpdateWidget(covariant SetCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final w = widget.set['weight'] as String? ?? '';
    final r = widget.set['reps'] as String? ?? '';
    final rir = widget.set['rir'] as String? ?? '';
    if (oldWidget.set['weight'] != w) {
      _slog(widget.index, 'didUpdateWidget sync weight "$w"');
      _setTextSilently(_weightCtrl, w);
    }
    if (oldWidget.set['reps'] != r) {
      _slog(widget.index, 'didUpdateWidget sync reps "$r"');
      _setTextSilently(_repsCtrl, r);
    }
    if (oldWidget.set['rir'] != rir) {
      _slog(widget.index, 'didUpdateWidget sync rir "$rir"');
      _setTextSilently(_rirCtrl, rir);
    }
    final drops = (widget.set['dropSets'] as List? ?? []);
    if (_dropWeightCtrls.length != drops.length) {
      _rebuildDropCtrls(drops);
    } else {
      for (var i = 0; i < drops.length; i++) {
        final dw = drops[i]['weight'] as String? ?? '';
        final dr = drops[i]['reps'] as String? ?? '';
        _setTextSilently(_dropWeightCtrls[i], dw);
        _setTextSilently(_dropRepsCtrls[i], dr);
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _registerTargets());
  }

  @override
  void dispose() {
    _slog(widget.index, 'dispose()');
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    _rirCtrl.dispose();
    _weightFocus.dispose();
    _repsFocus.dispose();
    _rirFocus.dispose();
    for (final c in _dropWeightCtrls) {
      c.dispose();
    }
    for (final c in _dropRepsCtrls) {
      c.dispose();
    }
    for (final f in _dropWeightFocuses) {
      f.dispose();
    }
    for (final f in _dropRepsFocuses) {
      f.dispose();
    }
    _noteFocus.dispose();
    _unregisterTargets();
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
    context.read<OverlayNumericKeypadController>().openFor(
      controller,
      allowDecimal: allowDecimal,
    );
    // Hinweis: ensureVisible nach dem Öffnen separat aufrufen (DeviceScreen macht das).
  }

  void focusWeight() {
    _openKeypad(_weightCtrl, allowDecimal: true);
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
    final dropActive =
        ((widget.set['dropSets'] as List?)?.isNotEmpty ?? false);

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
                    label: 'kg',
                    readOnly: done,
                    tokens: tokens,
                    dense: dense,
                    onTap: () => _openKeypad(_weightCtrl, allowDecimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return loc.kgRequired;
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
                    readOnly: done,
                    tokens: tokens,
                    dense: dense,
                    onTap: () => _openKeypad(_repsCtrl, allowDecimal: false),
                    validator: (v) {
                      if (v == null || v.isEmpty) return loc.repsRequired;
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
                  onTap: () {
                    _slog(
                      widget.index,
                      'tap: toggle done (form validate then provider)',
                    );
                    final form = Form.of(context);
                    if (!form.validate()) {
                      _slog(widget.index, 'toggle blocked: invalid form');
                      HapticFeedback.lightImpact();
                      return;
                    }
                    HapticFeedback.lightImpact();
                    context.read<DeviceProvider>().toggleSetDone(widget.index);
                  },
                ),
                SizedBox(width: dense ? 6 : 8),
                _RoundButton(
                  tokens: tokens,
                  icon: _showExtras ? Icons.expand_less : Icons.more_horiz,
                  filled: false,
                  semantics: 'Mehr Optionen',
                  dense: dense,
                  onTap: () {
                    _slog(widget.index, 'tap: more options → ${!_showExtras}');
                    HapticFeedback.lightImpact();
                    setState(() {
                      _showExtras = !_showExtras;
                      if (_showExtras && _dropWeightCtrls.isEmpty) {
                        _addDropSet();
                      }
                    });
                  },
                ),
              ],
            ),
            if (_showExtras) ...[
              SizedBox(height: dense ? 8 : 12),
              Column(
                children: [
                  for (var i = 0; i < _dropWeightCtrls.length; i++) ...[
                    Row(
                      children: [
                        Text('Drop', style: Theme.of(context).textTheme.bodySmall),
                        SizedBox(width: dense ? 8 : 12),
                        Expanded(
                          child: _InputPill(
                            controller: _dropWeightCtrls[i],
                            focusNode: _dropWeightFocuses[i],
                            label: 'kg',
                            readOnly: done,
                            tokens: tokens,
                            dense: dense,
                            onTap: () =>
                                _openKeypad(_dropWeightCtrls[i], allowDecimal: true),
                            validator: (v) => _validateDrop(i, v),
                          ),
                        ),
                        SizedBox(width: dense ? 8 : 12),
                        Expanded(
                          child: _InputPill(
                            controller: _dropRepsCtrls[i],
                            focusNode: _dropRepsFocuses[i],
                            label: 'x',
                            readOnly: done,
                            tokens: tokens,
                            dense: dense,
                            onTap: () =>
                                _openKeypad(_dropRepsCtrls[i], allowDecimal: false),
                            validator: (v) => _validateDrop(i, v),
                          ),
                        ),
                        if (i == _dropWeightCtrls.length - 1)
                          IconButton(
                            key: _plusKey,
                            icon: const Icon(Icons.add),
                            onPressed: done ? null : _addDropSet,
                          ),
                      ],
                    ),
                    SizedBox(height: dense ? 8 : 12),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _rirCtrl,
                          focusNode: _rirFocus,
                          decoration: const InputDecoration(
                            labelText: 'RIR',
                            isDense: true,
                          ),
                          readOnly: done,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      SizedBox(width: dense ? 8 : 12),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          readOnly: done,
                          initialValue: widget.set['note'] as String?,
                          decoration: InputDecoration(
                            labelText: loc.noteFieldLabel,
                            isDense: true,
                          ),
                          focusNode: _noteFocus,
                          onChanged: (v) {
                            _slog(widget.index, 'note → "$v"');
                            prov.updateSet(widget.index, note: v);
                          },
                        ),
                      ),
                    ],
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
  final VoidCallback onTap;
  final String? Function(String?)? validator;
  final bool dense;

  const _InputPill({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.readOnly,
    required this.tokens,
    required this.onTap,
    this.validator,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: readOnly ? null : () => onTap(),
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

class _RoundButton extends StatefulWidget {
  final SetCardTheme tokens;
  final IconData icon;
  final bool filled;
  final String semantics;
  final VoidCallback onTap;
  final bool dense;
  const _RoundButton({
    required this.tokens,
    required this.icon,
    required this.filled,
    required this.semantics,
    required this.onTap,
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
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
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
                      ? Theme.of(context).extension<AppBrandTheme>()?.onBrand ?? Theme.of(context).colorScheme.onPrimary
                      : widget.tokens.menuFg,
            ),
          ),
        ),
      ),
    );
  }
}
