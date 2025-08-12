import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:tapem/core/widgets/gradient_button.dart';
import 'action_rail.dart';
import 'key_button.dart';

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
  });

  static Future<void> show(BuildContext context, NumericKeypadSheet sheet) {
    final h = MediaQuery.of(context).size.height;
    final maxH = math.min(h * 0.45, 380.0);
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => sheet,
      constraints: BoxConstraints(maxHeight: maxH),
    );
  }

  @override
  State<NumericKeypadSheet> createState() => _NumericKeypadSheetState();
}

class _NumericKeypadSheetState extends State<NumericKeypadSheet>
    with SingleTickerProviderStateMixin {
  late final String _decimal;
  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;

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
    if (elapsed - _lastTick >= const Duration(milliseconds: 100)) {
      _lastTick += const Duration(milliseconds: 100);
      widget.onBackspace(continuous: true);
    }
  }

  Future<void> _handlePaste() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text ?? '';
    for (final ch in text.split('')) {
      if (ch == _decimal) {
        widget.onDecimal();
      } else if (RegExp(r'\d').hasMatch(ch)) {
        widget.onDigit(ch);
      }
    }
    widget.onPaste();
  }

  void _startBackspace() {
    _lastTick = Duration.zero;
    _ticker.start();
  }

  void _stopBackspace() {
    _ticker.stop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    const gap = 8.0;
    const railWidth = 64.0;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: DecoratedBox(
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
          child: FocusTraversalGroup(
            child: Shortcuts(
              shortcuts: {
                LogicalKeySet(LogicalKeyboardKey.enter): const ActivateIntent(),
                LogicalKeySet(LogicalKeyboardKey.numpadEnter): const ActivateIntent(),
                LogicalKeySet(LogicalKeyboardKey.backspace): const _BackspaceIntent(),
              },
              child: Actions(
                actions: {
                  ActivateIntent: CallbackAction<ActivateIntent>(
                    onInvoke: (_) {
                      if (widget.isSubmitEnabled) widget.onSubmit();
                      return null;
                    },
                  ),
                  _BackspaceIntent: CallbackAction<_BackspaceIntent>(
                    onInvoke: (_) {
                      widget.onBackspace(continuous: false);
                      return null;
                    },
                  ),
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final gridWidth = constraints.maxWidth - railWidth - gap;
                          final gridHeight = constraints.maxHeight;
                          final cell = math.min(
                            (gridWidth - gap * 2) / 3,
                            (gridHeight - gap * 3) / 4,
                          );
                          final cellSize = math.max(cell, 44.0);
                          final gridBoxWidth = cellSize * 3 + gap * 2;
                          final gridBoxHeight = cellSize * 4 + gap * 3;
                          final actionSize = math.min(cellSize, 48.0);

                          return Row(
                            children: [
                              Expanded(
                                child: Center(
                                  child: SizedBox(
                                    width: gridBoxWidth,
                                    height: gridBoxHeight,
                                    child: GridView.builder(
                                      physics: const NeverScrollableScrollPhysics(),
                                      shrinkWrap: true,
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        mainAxisSpacing: gap,
                                        crossAxisSpacing: gap,
                                        childAspectRatio: 1,
                                      ),
                                      itemCount: 12,
                                      itemBuilder: (context, index) {
                                        if (index < 9) {
                                          final d = '${index + 1}';
                                          return KeyButton(
                                            size: cellSize,
                                            semanticsLabel: 'Taste $d',
                                            onPressed: () => widget.onDigit(d),
                                            child: Text(d),
                                          );
                                        }
                                        if (index == 9) {
                                          return KeyButton(
                                            size: cellSize,
                                            semanticsLabel:
                                                _decimal == ',' ? 'Komma' : 'Punkt',
                                            onPressed: widget.onDecimal,
                                            child: Text(_decimal),
                                          );
                                        }
                                        if (index == 10) {
                                          return KeyButton(
                                            size: cellSize,
                                            semanticsLabel: 'Taste 0',
                                            onPressed: () => widget.onDigit('0'),
                                            child: const Text('0'),
                                          );
                                        }
                                        return KeyButton(
                                          size: cellSize,
                                          semanticsLabel: 'Rücktaste',
                                          onPressed: () =>
                                              widget.onBackspace(continuous: false),
                                          onLongPressStart: (_) {
                                            widget.onBackspace(continuous: true);
                                            _startBackspace();
                                          },
                                        onLongPressEnd: (_) => _stopBackspace(),
                                          child: const Icon(Icons.backspace),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: gap),
                              SizedBox(
                                width: railWidth,
                                child: ActionRail(
                                  buttonSize: actionSize,
                                  onHide: () {
                                    widget.onHideKeyboard();
                                    Navigator.of(context).maybePop();
                                  },
                                  onPaste: _handlePaste,
                                  onCopy: widget.onCopy,
                                  onPlus: widget.onPlus,
                                  onMinus: widget.onMinus,
                                  onClose: () => Navigator.of(context).maybePop(),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    GradientButton(
                      onPressed:
                          widget.isSubmitEnabled ? widget.onSubmit : null,
                      child: const Text('Weiter'),
                    ),
                    SizedBox(height: bottomPadding),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BackspaceIntent extends Intent {
  const _BackspaceIntent();
}
