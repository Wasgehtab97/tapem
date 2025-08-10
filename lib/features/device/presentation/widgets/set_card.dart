import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/device_provider.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/features/rank/presentation/device_level_style.dart';
import 'package:tapem/l10n/app_localizations.dart';

class SetCard extends StatefulWidget {
  final int index;
  final Map<String, dynamic> set;
  final Map<String, String>? previous;

  const SetCard({super.key, required this.index, required this.set, this.previous});

  @override
  State<SetCard> createState() => _SetCardState();
}

class _SetCardState extends State<SetCard> {
  bool _showExtras = false;

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<DeviceProvider>();
    final loc = AppLocalizations.of(context)!;
    final doneVal = widget.set['done'];
    final done = doneVal == 'true' || doneVal == true;

    final decoration = DeviceLevelStyle.widgetDecorationFor(
      prov.level,
      opacity: 0.6,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: decoration.copyWith(
        color: done ? Colors.green.withOpacity(0.1) : null,
        boxShadow: const [
          BoxShadow(blurRadius: 6, color: Colors.black12, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                child: Text('${widget.index + 1}'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.previous != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          'Previous: ${widget.previous!['weight']} × ${widget.previous!['reps']}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey),
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            readOnly: done,
                            initialValue: widget.set['weight'] as String?,
                            decoration: const InputDecoration(
                              labelText: 'kg',
                              isDense: true,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.,]')),
                            ],
                            validator: (v) {
                              if (v == null || v.isEmpty) return loc.kgRequired;
                              if (double.tryParse(v.replaceAll(',', '.')) ==
                                  null) {
                                return loc.numberInvalid;
                              }
                              return null;
                            },
                            onChanged: (v) =>
                                prov.updateSet(widget.index, weight: v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            readOnly: done,
                            initialValue: widget.set['reps'] as String?,
                            decoration: const InputDecoration(
                              labelText: 'x',
                              isDense: true,
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (v) {
                              if (v == null || v.isEmpty) return loc.repsRequired;
                              if (int.tryParse(v) == null) {
                                return loc.intRequired;
                              }
                              return null;
                            },
                            onChanged: (v) => prov.updateSet(widget.index, reps: v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            final form = Form.of(context);
                            if (!form.validate()) {
                              HapticFeedback.lightImpact();
                              return;
                            }
                            prov.toggleSetDone(widget.index);
                          },
                          icon: Icon(
                            done
                                ? Icons.check_circle
                                : Icons.check_circle_outline,
                            color: done ? Colors.green : null,
                          ),
                          tooltip: done
                              ? loc.setReopenTooltip
                              : loc.setCompleteTooltip,
                        ),
                        IconButton(
                          onPressed: () => setState(() {
                            _showExtras = !_showExtras;
                          }),
                          icon: Icon(_showExtras
                              ? Icons.expand_less
                              : Icons.more_horiz),
                          tooltip: 'More',
                        ),
                      ],
                    ),
                    if (_showExtras)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                readOnly: done,
                                initialValue: widget.set['rir'] as String?,
                                decoration: const InputDecoration(
                                  labelText: 'RIR',
                                  isDense: true,
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                onChanged: (v) =>
                                    prov.updateSet(widget.index, rir: v),
                              ),
                            ),
                            const SizedBox(width: 8),
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
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
