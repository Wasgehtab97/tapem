import 'package:flutter/material.dart';
import 'package:tapem/features/rank/domain/services/level_service.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/l10n/app_localizations.dart';

class XpInfoButton extends StatelessWidget {
  final int xp;
  final int level;
  final Color? color;

  const XpInfoButton({
    Key? key,
    required this.xp,
    required this.level,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final iconColor = color ?? Theme.of(context).iconTheme.color;
    return IconButton(
      icon: Icon(Icons.auto_awesome, color: iconColor),
      tooltip: loc.xpInfoTooltip,
      onPressed: () => _showInfo(context),
    );
  }

  void _showInfo(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final xpRemaining = LevelService.xpPerLevel - xp;
    final nextLevel = level + 1;
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(loc.xpInfoTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.xpInfoCurrentXp(xp)),
                Text(loc.xpInfoLevel(_toRoman(level))),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: xp / LevelService.xpPerLevel),
                Text(loc.xpInfoProgress(xpRemaining, nextLevel)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(loc.commonOk),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamed(AppRouter.xpOverview);
                },
                child: Text(loc.xpInfoDetails),
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
