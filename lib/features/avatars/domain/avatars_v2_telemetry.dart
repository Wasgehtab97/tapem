abstract class AvatarsV2Telemetry {
  void avatarInventoryLoaded(int count);
  void avatarEquipAttempt(
      {required String avatarId, required String source, required String result});
  void avatarEquipSuccess();
  void publicProfileMirrorWrite(String result);

  void avatarGrantAttempt(
      {required String avatarId, required String reason});
  void avatarGrantSuccess();
  void avatarGrantNoop();
  void avatarGrantDenied(String policy);
  void avatarGrantFailed(String error);

  void avatarRevokeAttempt({required String avatarId});
  void avatarRevokeSuccess();
  void avatarRevokeFailed(String error);
}
