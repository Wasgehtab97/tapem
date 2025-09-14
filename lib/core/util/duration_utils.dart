int parseHms(String input) {
  if (input.contains(':')) {
    final parts = input.split(':').map(int.parse).toList();
    while (parts.length < 3) {
      parts.insert(0, 0);
    }
    return parts[0] * 3600 + parts[1] * 60 + parts[2];
  }
  return int.tryParse(input) ?? 0;
}
