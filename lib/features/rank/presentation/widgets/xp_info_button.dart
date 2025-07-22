import 'package:flutter/material.dart';
import 'package:tapem/features/rank/domain/services/level_service.dart';

class XpInfoButton extends StatelessWidget {
  final int xp;
  final int level;

  const XpInfoButton({
    Key? key,
    required this.xp,
    required this.level,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.auto_awesome),
      tooltip: 'XP',
      onPressed: () => _showInfo(context),
    );
  }

  void _showInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('XP Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('XP: $xp'),
            Text('Level: ${_toRoman(level)}'),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: xp / LevelService.xpPerLevel),
            Text('${LevelService.xpPerLevel - xp} XP bis Level ${level + 1}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _toRoman(int number) {
    const Map<int, String> romans = {
      1000: 'M',
      900: 'CM',
      500: 'D',
      400: 'CD',
      100: 'C',
      90: 'XC',
      50: 'L',
      40: 'XL',
      10: 'X',
      9: 'IX',
      5: 'V',
      4: 'IV',
      1: 'I',
    };
    var result = '';
    var remaining = number;
    romans.forEach((value, numeral) {
      while (remaining >= value) {
        result += numeral;
        remaining -= value;
      }
    });
    return result;
  }
}
