# Community Stats & Feed – Implementierung

## Prompt
Neue Community-Seite mit Gym-weiten KPIs (Heute/Woche/Monat) und Live-Ticker. Button auf der Profilseite verlinkt auf die neue Ansicht. Aggregation clientseitig über Firestore, inkl. Idempotenz und Feed-Events.

## Ziel & Kontext
* Gemeinschaftliche Leistungsdaten sichtbar machen.
* Mitglieder motivieren über Live-Ticker und Meilensteine.
* Vorbereitung für Masterarbeit zu Gamification im Gym-Setting.

## Architektur & Datenmodell
* **Collections**:
  * `/gyms/{gymId}/stats_daily/{dayKey}` mit Feldern `date`, `repsTotal`, `volumeTotal`, `trainingSessions`.
  * `/gyms/{gymId}/stats_applied/{sessionId}` als Idempotenz-Marker (userId, createdAt).
  * `/gyms/{gymId}/feed_events/{eventId}` für Session-Summaries (optional deviceName/funnyText/avatarUrl).
* **Domain-Layer**: `CommunityStatsService` aggregiert Tages-Stream sowie Wochen-/Monats-Ladungen via `FirestoreCommunityStatsSource` und `TimeWindow`-Utils.
* **Write-Pfad**: `CommunityStatsWriter` wird aus `DeviceProvider.saveWorkoutSession` getriggert. Berechnet Reps/Volumen, schreibt Batch (Applied-Marker, Daily-Doc, Feed-Event). Fehler werden geloggt, Session-Save bleibt robust.
* **Read-Pfad**: Riverpod-Provider liefern Streams/Futures für KPIs und Feed. Zeiträume über `todayUtcRange`, `weekUtcRange`, `monthUtcRange` (TZ-sicher durch lokale Mitternacht + UTC-Konvertierung).
* **UI**: `CommunityScreen` (Tabs Heute/Woche/Monat, KPI-Karten, Live-Ticker mit Skeletons/Empty/Error). Aufruf via neuen Profil-CTA.

## Changelog (Dateien & Diffs)
* `pubspec.yaml` – Riverpod-Abhängigkeit.
* `lib/core/time/time_windows.dart` – neue TimeWindow-Utilities.
* `lib/features/community/...` – Models, Service, Provider, Writer, Screen.
* `lib/core/providers/device_provider.dart` – CommunityStatsWriter Hook + Constructor Injection.
* `lib/main.dart` – `ProviderScope` für Riverpod.
* `lib/app_router.dart` – Route `community`.
* `lib/features/profile/presentation/screens/profile_screen.dart` – Community-CTA & Icon.
* `lib/l10n/app_en.arb`, `lib/l10n/app_de.arb` – neue Strings.
* `firestore.rules`, `firestore.indexes.json` – Zugriffsregeln & Indizes.
* `thesis/gamification/20251101_community_stats_and_feed.md` – diese Dokumentation.

## Rules & Indizes
* Firestore-Regeln: Lese-/Schreibschutz für `stats_daily`, `stats_applied`, `feed_events` (Mitgliedschaft & Feldvalidierung, serverTimestamp).
* Indizes: `stats_daily` (date ASC), `feed_events` (createdAt DESC).

## Screenshots
* Keine Screenshots erstellt (keine UI-Session verfügbar).

## Tests & Ergebnis
* `flutter pub get`, `flutter gen-l10n`, `flutter test` **nicht ausführbar** (Flutter SDK fehlt in Container). Bitte lokal nachholen.

## Offene Punkte
* Feed-Events enthalten aktuell keine Geräteinfos/Avatar – bei Bedarf erweitern.
* Volumenaggregation rundet auf zwei Nachkommastellen; ggf. exakt speichern.
* Manuelle Firestore-Deploy (`firebase deploy --only firestore:rules,firestore:indexes`) noch ausstehend.
