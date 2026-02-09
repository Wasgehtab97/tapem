# Backend/Profile Fix Plan (Spark-kompatibel)

## Rahmen
- Firebase Plan: **Spark** (keine Cloud Functions nutzbar).
- Ziel: ProfilePage-Backend und zugehörige Settings-/Avatar-Flows konsistent, sicherer und wartbar machen.
- Fokus: nur umsetzbare Maßnahmen ohne Functions-Abhängigkeit.

## Status
- [x] Cloud-Functions-Migrationsansatz zurückgesetzt
- [x] Privacy-Write atomar über einen gemeinsamen App-Pfad
- [x] Username-Pfad clientseitig härten (Validierung/Normalisierung/Fehlercodes)
- [x] Avatar-Ownership konsistent auf `avatarInventory`
- [x] Firestore Rules Spark-kompatibel härten (ohne Kernflows zu brechen)
- [ ] Relevante Tests aktualisieren und ausführen (teilweise erledigt)

## Milestone 1 - Privacy atomar
### Ziel
- Keine Teilzustände mehr zwischen `showInLeaderboard` und `publicProfile`.

### Umsetzung
- [x] Neuer Source/Repository/UseCase-Pfad: `setProfileVisibility(userId, value)`
- [x] `AuthProvider`: ein kombinierter awaitbarer Call mit Rollback bei Fehler
- [x] `SettingsScreen`: nur noch ein Write-Call statt zwei parallelen Calls
- [x] Startup-Sync im `AuthProvider` ebenfalls über den kombinierten Call

## Milestone 2 - Username-Pfad härten (Spark)
### Ziel
- Konsistente Username-Validierung im Backend-nahen App-Layer ohne Cloud Function.

### Umsetzung
- [x] `changeUsernameTransaction`: Validierung (Länge/Regex/Whitespace) zentral erzwingen
- [x] Einheitliche Fehlercodes (`username_invalid`, `username_taken`, ...)
- [x] Tests für Validierungs-/Fehlerfälle ergänzen

## Milestone 3 - Avatar-Pipeline konsolidieren
### Ziel
- Keine Inkonsistenz mehr zwischen `avatarsOwned` (Legacy) und `avatarInventory` (aktuell).

### Umsetzung
- [x] Equip-Prüfung auf `avatarInventory` umstellen
- [x] Legacy-Helfer `getOwnedAvatarIds()` auf echte Avatar-IDs korrigieren
- [x] Admin-Grant-Aufruf im UI auf korrektes Payload (`avatarPath`) vorbereiten (best effort)

## Milestone 4 - Firestore Rules härten (Spark-sicher)
### Ziel
- Privilege-Escalation reduzieren, ohne aktuelle Spark-Flows zu blockieren.

### Umsetzung
- [x] Owner-Update für `coachEnabled` entfernen
- [x] `publicProfiles` Rule ergänzen, `public_profiles` als Legacy belassen
- [x] Gleiches Rule-Update in `firestore-dev.rules`

## Milestone 5 - Verifikation
### Umsetzung
- [x] Unit-/Widget-Tests für geänderte Auth/Settings-Pfade aktualisieren
- [ ] Mindestens gezielte Analyse/Testläufe dokumentieren (Analyze ok, Testlauf teilweise blockiert/abgebrochen)

## Zusatz (UI-Navigation Profil)
- [x] Profil-Buttons auf 2x2-Grid umgestellt (`Progress`, `Entdecken`, `Essen`, `Plan`)
- [x] `Essen` und `Plan` von der Profilseite aus direkt aufrufbar gemacht
- [x] BottomTabBar für normale Member auf 4 Kern-Tabs reduziert (Gym, Profil, Rank, Deals; Workout/Coaching kontextabhängig)
- [x] BottomTabBar bleibt beim Öffnen von `Essen`/`Plan` über Profil-Buttons erhalten (Nested Navigator im Home-Kontext)
- [x] BottomTabBar bleibt über den kompletten `Progress`-Flow erhalten (Home-Overlay-Navigator)
- [x] BottomTabBar bleibt über den kompletten `Entdecken`-Flow erhalten (Stats, Community, Surveys inkl. RestStats/Powerlifting)
- [x] Button-Titel gekürzt für 2x2-Layout (`Prog`, `Hub`, `Food`, `Plan`)
- [x] Overlay-Navigator-Initialisierung auf Single-Initial-Route umgestellt (kein „Back bleibt auf gleicher Seite“-Effekt mehr)
- [x] Einheitliches Top-Left-Back-Verhalten umgesetzt: pop im Feature-Stack, sonst zurück zur Profilseite (Progress/Hub/Food/Plan/Rank)

## Umsetzungslog
- 2026-02-07: Plan auf Spark umgestellt; Cloud-Functions-Migrationsänderungen zurückgerollt.
- 2026-02-07: Spark-Fixes in Privacy/Username/Avatar/Rules umgesetzt; Profil-Quick-Buttons (2x2) ergänzt und Member-BottomTabs reduziert.
- 2026-02-07: Ernährungs- und Trainingsplan-Navigation aus Profil in Home-Nested-Navigator verschoben, damit die BottomTabBar auf den Feature-Seiten bestehen bleibt.
- 2026-02-07: Progress- und Entdecken-Navigation ebenfalls in Home-Nested-Navigator verschoben, damit die BottomTabBar auf allen zugehörigen Seiten erhalten bleibt.
- 2026-02-07: Back-Navigation für Hub-/Overlay-Root-Seiten korrigiert (inkl. Food/Rank), Overlay-Initial-Routing bereinigt und Home-Back-Handling für aktive Overlays ergänzt.
