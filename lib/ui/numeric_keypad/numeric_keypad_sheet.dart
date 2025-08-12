import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:tapem/core/widgets/gradient_button.dart';
import 'package:tapem/core/theme/brand_surface_theme.dart';

import 'action_rail.dart';
import 'key_button.dart';

/// Bottom sheet numeric keypad used on the device/session page.
class NumericKeypadSheet extends StatefulWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onDecimal;
  final void Function({bool continuous}) onBackspace;
  final VoidCallback onPlus;
  final VoidCallback onMinus;
  final VoidCallback onPaste;
  final VoidCallback onCopy;
  final VoidCallback onHideKeyboard;
  final VoidCallback onSubmit;
  final bool isSubmitEnabled;
  final bool canPaste;
  final bool canCopy;
  final bool canPlus;
  final bool canMinus;

  const NumericKeypadSheet({
    super.key,
    required this.onDigit,
    required this.onDecimal,
    required this.onBackspace,
    required this.onPlus,
    required this.onMinus,
    required this.onPaste,
    required this.onCopy,
    required this.onHideKeyboard,
    required this.onSubmit,
    this.isSubmitEnabled = false,
    this.canPaste = true,
    this.canCopy = true,
    this.canPlus = true,
    this.canMinus = true,
  });

  /// Convenience helper to show the sheet.
  static Future<void> show(BuildContext context, NumericKeypadSheet sheet) {
    final maxH = MediaQuery.of(context).size.height * 0.45;
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => sheet,
      constraints: BoxConstraints(maxHeight: maxH),
    );
  }

  @override
  State<NumericKeypadSheet> createState() => _NumericKeypadSheetState();
}

enum _RepeatAction { backspace, plus, minus }

class _NumericKeypadSheetState extends State<NumericKeypadSheet>
    with SingleTickerProviderStateMixin {
  late final String _decimal;
  late final Ticker _ticker;
  _RepeatAction? _repeatAction;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context).toString();
    _decimal = NumberFormat.decimalPattern(locale).symbols.DECIMAL_SEP;
  }

  void _onTick(Duration elapsed) {
    switch (_repeatAction) {
      case _RepeatAction.backspace:
        widget.onBackspace(continuous: true);
        break;
      case _RepeatAction.plus:
        widget.onPlus();
        break;
      case _RepeatAction.minus:
        widget.onMinus();
        break;
      default:
        break;
    }
  }

  void _startRepeat(_RepeatAction action) {
    _repeatAction = action;
    _ticker.start();
  }

  void _stopRepeat() {
    _ticker.stop();
    _repeatAction = null;
  }

  Future<void> _handlePaste() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text ?? '';
    var hasDecimal = false;
    for (final ch in text.split('')) {
      if (ch == _decimal) {
        if (!hasDecimal) {
          widget.onDecimal();
          hasDecimal = true;
        }
      } else if (RegExp(r'\d').hasMatch(ch)) {
        widget.onDigit(ch);
      }
    }
    widget.onPaste();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const gap = 8.0;
    const padding = 12.0;
    const ctaSpacing = 12.0;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45),
        child: SafeArea(
          top: false,
          bottom: true,
          child: Padding(
            padding: const EdgeInsets.all(padding),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availableWidth = constraints.maxWidth;
                final availableHeight = constraints.maxHeight;

                // Key size computed primarily from width.
                final sizeFromWidth = (availableWidth - 3 * gap) / 4;

                final surface = Theme.of(context).extension<BrandSurfaceTheme>();
                final ctaHeight = surface?.height ?? 48;

                final heightForGrid =
                    availableHeight - ctaHeight - ctaSpacing;
                final sizeFromHeight =
                    (heightForGrid - gap * 3) / 4;

                var keySize = math.min(sizeFromWidth, sizeFromHeight);
                keySize = math.max(44.0, keySize);

                final gridWidth = keySize * 3 + gap * 2;
                final gridHeight = keySize * 4 + gap * 3;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: gridHeight,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: gridWidth,
                            child: GridView.count(
                              crossAxisCount: 3,
                              mainAxisSpacing: gap,
                              crossAxisSpacing: gap,
                              physics:
                                  const NeverScrollableScrollPhysics(),
                              children: [
                                for (var i = 1; i <= 9; i++)
                                  KeyButton(
                                    label: '$i',
                                    semanticsLabel: 'Taste $i',
                                    onTap: () => widget.onDigit('$i'),
                                    size: keySize,
                                  ),
                                KeyButton(
                                  label: _decimal,
                                  semanticsLabel:
                                      _decimal == ',' ? 'Komma' : 'Punkt',
                                  onTap: widget.onDecimal,
                                  size: keySize,
                                ),
                                KeyButton(
                                  label: '0',
                                  semanticsLabel: 'Taste 0',
                                  onTap: () => widget.onDigit('0'),
                                  size: keySize,
                                ),
                                KeyButton(
                                  icon: const Icon(Icons.backspace),
                                  semanticsLabel: 'Rücktaste',
                                  onTap: () =>
                                      widget.onBackspace(continuous: false),
                                  onLongPressStart: (_) {
                                    widget.onBackspace(continuous: true);
                                    _startRepeat(_RepeatAction.backspace);
                                  },
                                  onLongPressEnd: (_) => _stopRepeat(),
                                  size: keySize,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: gap),
                          SizedBox(
                            width: keySize,
                            child: ActionRail(
                              keySize: keySize,
                              onHide: () {
                                widget.onHideKeyboard();
                                Navigator.of(context).maybePop();
                              },
                              onPaste: _handlePaste,
                              onCopy: widget.onCopy,
                              onPlus: widget.onPlus,
                              onMinus: widget.onMinus,
                              onClose: () => Navigator.of(context).maybePop(),
                              onPlusLongPressStart: (_) {
                                widget.onPlus();
                                _startRepeat(_RepeatAction.plus);
                              },
                              onPlusLongPressEnd: (_) => _stopRepeat(),
                              onMinusLongPressStart: (_) {
                                widget.onMinus();
                                _startRepeat(_RepeatAction.minus);
                              },
                              onMinusLongPressEnd: (_) => _stopRepeat(),
                              canPaste: widget.canPaste,
                              canCopy: widget.canCopy,
                              canPlus: widget.canPlus,
                              canMinus: widget.canMinus,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: ctaSpacing),
                    GradientButton(
                      onPressed:
                          widget.isSubmitEnabled ? widget.onSubmit : null,
                      child: const Text('Weiter'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
