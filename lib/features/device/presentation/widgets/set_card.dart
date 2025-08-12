import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/device_provider.dart';
import 'package:tapem/core/theme/brand_surface_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/ui/numeric_keypad/numeric_keypad.dart';

/// Tokens used to style a [SetCard]. They derive their default values from the
/// ambient [ThemeData] but can be overridden via [copyWith].
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

/// Card representing a single workout set. Only visual styling has changed –
/// callbacks and state handling remain untouched.
class SetCard extends StatefulWidget {
  final int index;
  final Map<String, dynamic> set;
  final Map<String, String>? previous; // kept for API compatibility

  const SetCard({
    super.key,
    required this.index,
    required this.set,
    this.previous,
  });

  @override
  State<SetCard> createState() => _SetCardState();
}

class _SetCardState extends State<SetCard> {
  late final TextEditingController _weightCtrl;
  late final TextEditingController _repsCtrl;
  late final FocusNode _weightFocus;
  late final FocusNode _repsFocus;

  bool _showExtras = false;

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController(text: widget.set['weight'] as String?);
    _repsCtrl = TextEditingController(text: widget.set['reps'] as String?);
    _weightFocus = FocusNode();
    _repsFocus = FocusNode();
  }

  @override
  void didUpdateWidget(covariant SetCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.set['weight'] != widget.set['weight']) {
      _weightCtrl.text = widget.set['weight'] as String? ?? '';
    }
    if (oldWidget.set['reps'] != widget.set['reps']) {
      _repsCtrl.text = widget.set['reps'] as String? ?? '';
    }
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    _weightFocus.dispose();
    _repsFocus.dispose();
    super.dispose();
  }

  Future<void> _openKeypad(
    TextEditingController controller, {
    required bool allowDecimal,
  }) async {
    await showNumericKeypadSheet(
      context: context,
      controller: controller,
      allowDecimal: allowDecimal,
    );
    final prov = context.read<DeviceProvider>();
    if (controller == _weightCtrl) {
      prov.updateSet(widget.index, weight: _weightCtrl.text);
    } else {
      prov.updateSet(widget.index, reps: _repsCtrl.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<DeviceProvider>();
    final loc = AppLocalizations.of(context)!;
    final tokens = SetCardTheme.of(context);
    final surface = Theme.of(context).extension<BrandSurfaceTheme>();

    var gradient = surface?.gradient ?? AppGradients.brandGradient;
    if (surface != null) {
      final lums = gradient.colors.map((c) => c.computeLuminance());
      final lum = lums.reduce((a, b) => a + b) / gradient.colors.length;
      final delta = surface.luminanceRef - lum;
      gradient = Tone.gradient(gradient, delta);
    }

    final doneVal = widget.set['done'];
    final done = doneVal == 'true' || doneVal == true;

    return Semantics(
      label: 'Set ${widget.index + 1}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: surface?.radius as BorderRadius? ??
              BorderRadius.circular(AppRadius.button),
          boxShadow: surface?.shadow,
        ),
        padding: tokens.padding,
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _IndexBadge(tokens: tokens, index: widget.index + 1),
                const SizedBox(width: 12),
                Expanded(
                  child: _InputPill(
                    controller: _weightCtrl,
                    focusNode: _weightFocus,
                    label: 'kg',
                    readOnly: done,
                    tokens: tokens,
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
                const SizedBox(width: 12),
                Expanded(
                  child: _InputPill(
                    controller: _repsCtrl,
                    focusNode: _repsFocus,
                    label: 'x',
                    readOnly: done,
                    tokens: tokens,
                    onTap: () => _openKeypad(_repsCtrl, allowDecimal: false),
                    validator: (v) {
                      if (v == null || v.isEmpty) return loc.repsRequired;
                      if (int.tryParse(v) == null) return loc.intRequired;
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                _RoundButton(
                  tokens: tokens,
                  icon: done ? Icons.check : Icons.check,
                  filled: done,
                  semantics: done ? loc.setReopenTooltip : loc.setCompleteTooltip,
                  onTap: () {
                    final form = Form.of(context);
                    if (!form.validate()) {
                      HapticFeedback.lightImpact();
                      return;
                    }
                    HapticFeedback.lightImpact();
                    prov.toggleSetDone(widget.index);
                  },
                ),
                const SizedBox(width: 8),
                _RoundButton(
                  tokens: tokens,
                  icon: _showExtras ? Icons.expand_less : Icons.more_horiz,
                  filled: false,
                  semantics: 'Mehr Optionen',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _showExtras = !_showExtras;
                    });
                  },
                ),
              ],
            ),
            if (_showExtras) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      readOnly: done,
                      initialValue: widget.set['rir'] as String?,
                      decoration: InputDecoration(
                        labelText: 'RIR',
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (v) =>
                          prov.updateSet(widget.index, rir: v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      readOnly: done,
                      initialValue: widget.set['note'] as String?,
                      decoration: InputDecoration(
                        labelText: loc.noteFieldLabel,
                        isDense: true,
                      ),
                      onChanged: (v) =>
                          prov.updateSet(widget.index, note: v),
                    ),
                  ),
                ],
              )
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
  const _IndexBadge({required this.tokens, required this.index});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Set $index',
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: tokens.chipBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tokens.chipFg.withOpacity(0.2)),
        ),
        child: Text(
          '$index',
          style: TextStyle(color: tokens.chipFg, fontWeight: FontWeight.w600),
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

  const _InputPill({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.readOnly,
    required this.tokens,
    required this.onTap,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: readOnly ? null : () => onTap(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withOpacity(0.12),
              Colors.white.withOpacity(0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: focusNode.hasFocus
                ? tokens.chipBorder
                : tokens.chipFg.withOpacity(0.3),
            width: 1.3,
          ),
          boxShadow: focusNode.hasFocus
              ? [
                  BoxShadow(
                    color: tokens.chipBorder.withOpacity(0.4),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        alignment: Alignment.center,
        child: TextFormField(
          controller: controller,
          focusNode: focusNode,
          readOnly: readOnly,
          onTap: onTap,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            border: InputBorder.none,
            labelText: label,
          ),
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
  const _RoundButton({
    required this.tokens,
    required this.icon,
    required this.filled,
    required this.semantics,
    required this.onTap,
  });

  @override
  State<_RoundButton> createState() => _RoundButtonState();
}

class _RoundButtonState extends State<_RoundButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final size = 44.0;
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
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context)
                      .colorScheme
                      .onPrimary
                      .withOpacity(0.12),
                  Theme.of(context)
                      .colorScheme
                      .onPrimary
                      .withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: widget.filled
                    ? widget.tokens.doneOn
                    : widget.tokens.chipFg.withOpacity(0.3),
                width: 1.3,
              ),
              color: widget.filled ? widget.tokens.doneOn : widget.tokens.menuBg,
            ),
            child: Icon(
              widget.icon,
              color: widget.filled
                  ? Theme.of(context).colorScheme.onPrimary
                  : widget.tokens.menuFg,
            ),
          ),
        ),
      ),
    );
  }
}

