import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/brand_gradient_card.dart';
import 'package:tapem/features/device/domain/models/device_session_snapshot.dart';
import '../models/session_set_vm.dart';

class LastSessionCard extends StatelessWidget {
  final DateTime date;
  final List<SessionSetVM> sets;
  final String? note;
  const LastSessionCard({super.key, required this.date, required this.sets, this.note});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return BrandGradientCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Letzte Session: ${DateFormat.yMd(locale).add_Hm().format(date)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          for (final s in sets) ...[
            _MainSetRow(s: s),
            if (s.drops.isNotEmpty) _DropRows(drops: s.drops),
            const SizedBox(height: 4),
          ],
          if (note != null && note!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Notiz: $note'),
          ],
        ],
      ),
    );
  }
}

class _MainSetRow extends StatelessWidget {
  final SessionSetVM s;
  const _MainSetRow({required this.s});
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${s.ordinal}. '),
        const SizedBox(width: 12),
        BrandGradientCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Text('${s.kg} kg'),
        ),
        const SizedBox(width: 16),
        Text('${s.reps} x'),
        if (s.rir != null) ...[
          const SizedBox(width: 16),
          Text('RIR ${s.rir}'),
        ],
        if (s.note != null && s.note!.isNotEmpty) ...[
          const SizedBox(width: 16),
          Expanded(child: Text(s.note!)),
        ],
      ],
    );
  }
}

class _DropRows extends StatelessWidget {
  final List<DropEntry> drops;
  const _DropRows({required this.drops});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 32.0, top: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          for (final d in drops) _DropChip(d: d),
        ],
      ),
    );
  }
}

class _DropChip extends StatelessWidget {
  final DropEntry d;
  const _DropChip({required this.d});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.south_east, size: 12),
          const SizedBox(width: 6),
          Text('${d.kg} kg × ${d.reps}', style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
