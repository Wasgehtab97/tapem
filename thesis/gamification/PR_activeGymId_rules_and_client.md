# PR: Admin-Read für Trainingstage via activeGymId (ohne Custom Claims)

## Prompt (Ziel & Kontext)
Admins sollen im Spark Tier Trainingstage anderer Mitglieder sehen. Statt Custom Claims verwenden wir `users/{uid}.activeGymId` und passen Security Rules + Client an.

## Umsetzung (Änderungen)
- firestore.rules: `activeGymId()` helper, Read-Regeln für `users/{uid}/trainingDayXP` auf Admin des `activeGymId` + `isMember`.
- User-Update-Whitelist um `activeGymId` erweitert.
- Flutter: `UserProfileService.setActiveGym(gymId)` + Aufruf nach Ensure-Membership.
- Repository: robustes Error-Handling für `permission-denied`.
- UI: dezenter Admin-only Hinweis.

## Ergebnis (Screens/Logs/Tests)
- Screenshot Mitgliederseite mit geladenen Trainingstagen (Admin).
- Log-Auszug ohne permission-denied.
- (Optional) Rules-Unit-Tests grün.

## Learnings / Trade-offs
- Kein Token-Refresh nötig beim Gym-Wechsel.
- Abhängigkeit: `activeGymId` muss konsistent gepflegt werden.

## Nächste Schritte
- (Optional) Gym-Switch UI verknüpfen mit `setActiveGym`.
