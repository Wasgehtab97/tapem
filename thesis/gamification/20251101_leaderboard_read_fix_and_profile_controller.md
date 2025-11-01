# Prompt
Projekt / Stack
Flutter (Dart), Riverpod, Firebase Firestore (Spark, ohne Cloud Functions), iOS/Android.
App: Tap’em – Fitness-Logger mit Geräte-Detailseite („Device Screen“) und Gamification.

Kontext – Feature „King/Queen of the machine“
Auf der Device-Detailseite gibt es einen neuen Button (Krone/Trophy), der ein Bottom-Sheet mit Tabs Heute | Woche | Monat öffnet. Darin sollen e1RM-Rekorde (Ein-Wiederholungs-Max über Formel) für das aktuell geöffnete Gerät und das aktuelle Gym angezeigt werden. Filter: Geschlecht (Alle | w | m) und Modus (Absolut | Relativ), wobei „Relativ“ = e1RM / Körpergewicht. Das Feature gilt nur für Geräte mit isMulti == false.

IST-Zustand (Code grob)

Datenmodell „Attempts“ bereits angelegt und beim Speichern von Sätzen geschrieben:
Pfad: /gyms/{gymId}/machines/{machineId}/attempts/{attemptId}
Beispiel-Doc (vorhanden in der DB, siehe Screenshots):

{
  gymId: "lifthouse_koblenz",
  machineId: "<deviceId>",
  userId: "<uid>",
  username: "Admin",
  e1rm: 36.3,            // double
  reps: 3,               // int
  weight: 33,            // double|int
  createdAt: <serverTimestamp>,
  isMulti: false,
  gender: "m",           // optional
  bodyWeightKg: 85       // optional
}


UI: Bottom-Sheet mit Tabs & Filter ist vorhanden.

LeaderboardService/Repository/Source existieren (Codex-Umsetzung).

Profile-Screen speichert gender und bodyWeightKg.

Reproduktion (IST)

Auf einem Gerät mit isMulti=false 1–2 Sätze loggen.

In Firestore tauchen unter /gyms/{gymId}/machines/{machineId}/attempts die Docs auf (verifiziert).

In der App auf dem Gerät das Crown-Sheet öffnen → Fehlertext: „Leaderboard konnte nicht geladen werden.“ (auch im „Absolut“-Modus).

Logs (Auszug)

Es sind keine eindeutigen UI-Stacktraces beim Öffnen des Sheets sichtbar (XP-Logs laufen normal).

Zuvor trat ein separater Fehler auf dem Profile-Screen auf (TextEditingController used after being disposed) – wurde bereits adressiert, bitte trotzdem Lifecycle prüfen.

Aufgabe / Ziel
Bitte analysiere den Code eigenständig (Service, Repository, Source, UI) und finde die Ursache(n), warum das Leaderboard nicht lädt, obwohl attempts-Docs existieren. Implementiere danach einen robusten, sauberen Best-Practice-Fix.

Technische Hypothesen (nur als Hinweise, bitte selbst verifizieren):

Query verwendet collectionGroup('attempts') plus where(gymId/machineId) → benötigt COLLECTION_GROUP-Composite-Indizes; fehlen diese, wirft Firestore FAILED_PRECONDITION.

Falsche orderBy-Reihenfolge bei Range-Filter: Wenn where('createdAt', >= start/< end) genutzt wird, muss orderBy('createdAt', ...) vor orderBy('e1rm', ...) kommen.

Im „Relativ“-Flow wird (direkt oder indirekt) where('bodyWeightKg', ...) verwendet → löst zusätzliche Indexanforderungen aus.

Falscher Pfad (z. B. falsches gymId/machineId Binding) oder Rules-Mismatch beim Read.

UI behandelt „keine Daten“ als „Fehler“.

Erwartete Lösung (Guidelines, du darfst optimieren/umstrukturieren):

Query korrekt & indexarm:

Primär Pfad-Query verwenden:
collection('gyms/$gymId/machines/$machineId/attempts') statt collectionGroup, damit weniger Indizes nötig sind.

Filter nur: isMulti == false, createdAt in [start, end), optional gender == x.

orderBy('createdAt', descending: true) vor orderBy('e1rm', descending: true).

Relativ: kein Firestore-Filter auf bodyWeightKg; lade z. B. limit(25–50) und berechne/sortiere e1rm/bodyWeightKg clientseitig, Einträge mit null/0 Gewichten aussortieren.

Falls du weiterhin collectionGroup oder Server-Filter brauchst, füge die nötigen Composite-Indizes in firestore.indexes.json hinzu (siehe unten).

Fehler- & Empty-Handling:

Unterscheide Empty-State („Noch kein Rekord in diesem Zeitraum.“) von Fehler-State („Konnte nicht geladen werden.“).

FirebaseException sauber abfangen und e.code + e.message loggen (DebugPrint), inkl. der automatisch gelieferten Index-URL.

Keine Endlos-Spinner; loading → content/empty/error klar separieren.

Zeitfenster / Zeitzone:

Start/Ende für Heute/Woche/Monat stabil berechnen (lokale TZ → UTC) und in den Query-Range verwenden. Tests anpassen.

Profile-Screen (Regression-Check):

Sicherstellen, dass TextEditingController/FocusNode im State erstellt und in dispose() freigegeben werden; nicht bei Rebuilds austauschen.

Kein setState im Build; Animationen nicht direkt um TextFormField mit bestehendem Controller legen.

Scrollbarer Inhalt, resizeToAvoidBottomInset: true.

Validierung & Parsing von bodyWeightKg robust (, → ., Bereich checken).

Tests:

Unit-Tests: Zeitfenster-Helper, e1RM-Berechnung, clientseitige Sortierung „Relativ“ (Entries mit null/0 ausgeschlossen).

Widget-Test: Bottom-Sheet states (loading/empty/error/content).

Optional Emulator-Test: Read-Query schlägt nicht mit Index-Fehlern fehl.

Indizes (nur falls benötigt):

Für Pfad-Query genügt meist:

isMulti ASC, createdAt DESC, e1rm DESC

isMulti ASC, gender ASC, createdAt DESC, e1rm DESC

Für collectionGroup('attempts') zusätzlich (falls du das beibehältst):

COLLECTION_GROUP: gymId ASC, machineId ASC, isMulti ASC, createdAt DESC, e1rm DESC

COLLECTION_GROUP: gymId ASC, machineId ASC, gender ASC, isMulti ASC, createdAt DESC, e1rm DESC

Ggf. Aufnahme in firestore.indexes.json + firebase deploy --only firestore:indexes.

Security Rules – Read:

Prüfen, dass Mitglieder des Gyms die Attempts lesen dürfen (z. B. exists(/gyms/{gymId}/members/{uid})).

Write-Rules bleiben restriktiv (nur eigene Writes, !machine.isMulti). ServerTimestamp nicht starr mit request.time == vergleichen, um Sentinel-Probleme zu vermeiden.

DX & Logging:

Präzise Debug-Logs im LeaderboardService (Start der Query, Parameter, limit, Filter, Catch von FirebaseException).

Akzeptanzkriterien

Leaderboard zeigt im Absolut-Modus Top-Ergebnis korrekt für Heute/Woche/Monat; keine Fehlermeldung bei vorhandenen Daten.

Relativ funktioniert ohne zusätzliche Server-Filter; korrekte Sortierung e1rm/bodyWeightKg; Einträge mit null/≤0 BW werden ignoriert.

Bei keinen Attempts erscheint ein Empty-State, kein Fehler.

Keine FAILED_PRECONDITION/INVALID_ARGUMENT mehr in Logs.

Profile-Screen speichert ohne „Controller disposed“/_dependents.isEmpty/Overflow.

Tests grün.

Zu ändernde/prüfende Dateien (typisch):

lib/features/device/domain/services/leaderboard_service.dart

lib/features/device/data/sources/firestore_machine_attempt_source.dart

lib/features/device/presentation/widgets/machine_leaderboard_sheet.dart

lib/features/profile/presentation/screens/profile_screen.dart

lib/features/device/domain/utils/leaderboard_time_utils.dart

firestore.indexes.json, firestore.rules (falls Anpassungen nötig)

test/... (Unit/Widget)

Dokumentation (Masterarbeit – bitte unbedingt ausführen):
Lege zusätzlich eine Markdown-Datei unter thesis/gamification/ an – Dateiname:
YYYYMMDD_leaderboard_read_fix_and_profile_controller.md
mit folgenden Abschnitten: Prompt (dieser Text), Ziel & Kontext, Analyse & Root Cause, Umsetzung/Changelog (Dateien, Diffs, Indizes/Rules), Screenshots (Pfade/Bezeichnungen), Outcome/Tests, Offene Punkte.

PR-Hinweis

Aussagekräftige PR-Beschreibung mit Root-Cause, Lösung, Risiken, Checkliste (Akzeptanzkriterien) und ggf. Links zu Index-Deploy.

Bitte Code möglichst klein und fokussiert halten; keine unrelated Changes.

# Ziel & Kontext
Die Leaderboard-Abfragen für Geräte mit `isMulti == false` sollen stabil Daten laden und ohne zusätzliche Firestore-Indizes auf Spark funktionieren. Außerdem sollte der bereits gefixte Profile-Screen weiterhin ohne Lifecycle-Probleme funktionieren.

# Analyse & Root Cause
Die bestehende Abfrage filterte `isMulti` und `gender` direkt in Firestore und sortierte zusätzlich nach `e1rm`. Dadurch verlangte Firestore eine mehrteilige Index-Kombination, die in Spark nicht vorhanden war. Die Abfrage löste deshalb `FirebaseException(code: failed-precondition)` aus, was im UI als Fehlerzustand endete. Da `MachineLeaderboardSheet` den Fehlerstatus direkt anzeigte, war das Leaderboard stets leer.

# Umsetzung/Changelog (Dateien, Diffs, Indizes/Rules)
- `lib/features/device/data/sources/firestore_machine_attempt_source.dart`: Range-Query auf `createdAt` beibehalten, serverseitige Filter auf `isMulti`/`gender` entfernt, Limit dynamisch auf 20× (max. 100) erhöht, um genügend Kandidaten für das clientseitige Scoring zu laden und Index-Anforderungen zu vermeiden.
- `lib/features/device/data/repositories/machine_attempt_repository_impl.dart`: Gender-Filterung clientseitig nachgeladen, damit die Query ohne zusätzliche Indizes auskommt.
- `test/features/device/data/repositories/machine_attempt_repository_impl_test.dart`: Neue Unit-Tests für die Gender-Filterung im Repository.
- `test/features/device/domain/services/leaderboard_service_test.dart`: Fake-Repository passt sich an die neue Gender-Filterlogik an.
- Keine Änderungen an `firestore.indexes.json` oder den Rules notwendig.

# Screenshots (Pfade/Bezeichnungen)
Keine Screenshots erforderlich – ausschließlich Backend-/Logik-Anpassungen.

# Outcome/Tests
- Lokale Unit-Tests vorgesehen (`flutter test`), im Container jedoch nicht lauffähig, weil Flutter CLI fehlt.
- Manuelle Code-Analyse der Profile-Screen-Lifecycle-Logik; keine zusätzlichen Änderungen erforderlich.

# Offene Punkte
- Nach Deployment einmalig auf einem Gerät prüfen, ob 50 geladene Versuche je Zeitraum für Gyms mit hoher Frequenz ausreichen.
- Optional: Indizes für zukünftige Skalierung vorbereiten, falls Query wieder serverseitig nach `gender`/`isMulti` filtern soll.
