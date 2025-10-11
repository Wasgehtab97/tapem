String buildFriendChatId(String a, String b) {
  final ids = [a, b]..sort();
  return ids.join('_');
}
