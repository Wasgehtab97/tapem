int parseHms(String input) {
  final t = input.trim();
  if (t.isEmpty) return 0;
  if (t.contains(':')) {
    final parts = t.split(':');
    if (parts.length > 3 || parts.any((p) => p.isEmpty)) return 0;
    try {
      final nums = parts.map(int.parse).toList();
      while (nums.length < 3) {
        nums.insert(0, 0);
      }
      return nums[0] * 3600 + nums[1] * 60 + nums[2];
    } catch (_) {
      return 0;
    }
  }
  return int.tryParse(t) ?? 0;
}

String formatHms(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  final hh = h.toString().padLeft(2, '0');
  final mm = m.toString().padLeft(2, '0');
  final ss = s.toString().padLeft(2, '0');
  return '$hh:$mm:$ss';
}
