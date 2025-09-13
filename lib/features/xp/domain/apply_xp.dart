class XpLevel {
  final int xp;
  final int level;
  final bool leveledUp;

  const XpLevel({required this.xp, required this.level, required this.leveledUp});
}

XpLevel applyXp({
  required int xp,
  required int level,
  required int add,
  int maxLevel = 30,
  int threshold = 1000,
}) {
  if (level >= maxLevel) {
    return XpLevel(xp: 0, level: maxLevel, leveledUp: false);
  }
  var newXp = xp + add;
  var newLevel = level;
  var leveled = false;
  while (newXp >= threshold && newLevel < maxLevel) {
    newXp -= threshold;
    newLevel++;
    leveled = true;
  }
  if (newLevel >= maxLevel) {
    newLevel = maxLevel;
    newXp = 0;
  }
  return XpLevel(xp: newXp, level: newLevel, leveledUp: leveled);
}
