abstract class AvatarsV2Telemetry {
  void avatarInventoryLoaded(int count);
  void avatarEquipAttempt(
      {required String avatarId, required String source, required String result});
  void avatarEquipSuccess();
  void publicProfileMirrorWrite(String result);
}
