# Tap'em – Profile & Leaderboard Stabilization

## Prompt
```
Ziel & Kontext
In der Flutter-App Tap’em (Firebase/Firestore, Riverpod), behebe zwei Bugs und verhärte die Implementierung:

Bug A – Profile: Beim Speichern von Geschlecht + Körpergewicht crasht die App mit
A TextEditingController was used after being disposed → gefolgt von _dependents.isEmpty und großem RenderFlex-Overflow.

Bug B – Leaderboard relativ: „Leaderboard konnte nicht geladen werden“ wenn „Relativ“ aktiv ist (aktuell wahrscheinlich wegen eines bodyWeightKg-Filters + OrderBy-Kombination ohne passenden Index).

Anforderungen: best practice, robust, saubere Architektur, bestehende UI/Strings behalten. Tests anpassen/ergänzen.
Wichtig: Am Ende zusätzlich eine Markdown-Datei unter thesis/gamification/ anlegen, die Prompt, Ziel/Kontext und Ergebnis/Changelog dokumentiert.

1) Profile-Screen: Controller-Lifecycle & Layout härten

Datei: lib/features/profile/presentation/screens/profile_screen.dart

Refaktoriere den Screen zu einem StatefulWidget (falls noch nicht), mit stabilen Instanzfeldern:

late final TextEditingController _bodyWeightCtrl;

late final FocusNode _bodyWeightFocus;

Optional: ValueNotifier<Gender?> _gender; falls Gender als eigener State gehalten wird; ansonsten über Provider.

Init: In initState() Controller/FocusNodes einmal erstellen, Startwert aus SettingsProvider setzen (z. B. state.bodyWeightKg?.toString() ?? '').
Kein Controller-Neuaufbau im build/Consumer!

Dispose: In dispose() sauber dispose() aufrufen (Controller + FocusNodes).
Wichtig: Es darf keine Animation (z. B. AnimatedSwitcher/AnimatedCrossFade/AnimatedSize) direkt um den TextFormField mit Controller liegen, die beim Statewechsel den Child-Baum tauscht, während der alte Controller bereits disposed ist.
→ Falls Animation gewünscht: Animation um Container-Ebene, nicht um das TextFormField. Alternativ feste Keys: KeyedSubtree(key: const ValueKey('bodyWeightField'), child: ...) und Controller nicht austauschen.

Kein Controller-Swap: Falls der Provider neue Werte liefert, nur den Text setzen, nicht den Controller ersetzen:

ref.listen<SettingsState>(settingsProvider, (_, s) {
  final target = s.bodyWeightKg?.toString() ?? '';
  if (_bodyWeightCtrl.text != target) _bodyWeightCtrl.text = target;
});


Overflow verhindern: Form in SafeArea + SingleChildScrollView/ListView mit padding legen; resizeToAvoidBottomInset: true.

Parsing & Validation:

InputFormatter für Dezimalzahlen (FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))) und beim Speichern zu double? parsen (, → .).

Form + GlobalKey<FormState> mit validator (z. B. >= 30 && <= 400 als realistischer Bereich, optional).

Speichern:

await settingsProvider.updateProfile(gender: selectedGender, bodyWeightKg: parsedWeight).

try/catch → FirebaseException/Exception abfangen, mit SnackBar/showDialog melden.

if (!mounted) return; vor UI-Feedback.

Keine Red-Screens mehr: Stelle sicher, dass keine setState() während des Builds ausgelöst wird (kein setState in build/didChangeDependencies).
_dependents.isEmpty verschwindet, sobald Controller nicht mehr disposed sind, während ein Animated-Widget noch referenziert.

Falls Controller heute über einen Provider erzeugt/entsorgt werden: entferne das; Controller gehören in den Widget-State dieses Screens.

2) Leaderboard „Relativ“ stabilisieren (Indexfrei)

Dateien:

lib/features/device/domain/services/leaderboard_service.dart

lib/features/device/data/sources/firestore_machine_attempt_source.dart

lib/features/device/presentation/widgets/machine_leaderboard_sheet.dart

Ziel: Kein Firestore-Filter auf bodyWeightKg mehr. Berechne den relativen Score clientseitig → vermeidet zusätzliche Composite-Indizes, bleibt performant mit kleinem limit.

Query-Basis (absolut & relativ gleich):

// basisQuery: attempts for gym+machine, isMulti == false, Zeitraum (start..end)
// Beachte: orderBy(createdAt) MUSS vor weiterem orderBy stehen.
query
  .where('isMulti', isEqualTo: false)
  .where('createdAt', isGreaterThanOrEqualTo: start)
  .where('createdAt', isLessThan: end)
  .orderBy('createdAt', descending: true)
  .orderBy('e1rm', descending: true)
  .limit(50); // small page to sort client-side
// Optional gender:
// if (gender != null) query = query.where('gender', isEqualTo: gender);


Keine where('bodyWeightKg' ...)-Klausel!

Clientseitige Sortierung im Service:

final docs = await query.get();
final entries = docs.docs.map(toModel).toList();

List<_ScoredEntry> scored = entries
  .map((e) {
    final bw = e.bodyWeightKg;
    final score = relative
      ? (bw != null && bw > 0 ? e.e1rm / bw : double.nan)
      : e.e1rm;
    return _ScoredEntry(e, score);
  })
  .where((s) => !relative || s.score.isFinite)
  .toList();

scored.sort((a, b) => b.score.compareTo(a.score));
final top = scored.take(topN).map((s) => s.entry.withScore(s.score)).toList();


UI-Fehlertexte trennen:

„Keine Daten“ (leere Liste) ≠ „Ladefehler“ (Exception).

Bei FirebaseException(code == 'failed-precondition') (Index fehlt) gib klaren Hinweis im Log (nicht UI) aus.

Tests:

Unit-Test: relative Sort mit null/0 Körpergewicht wird korrekt gefiltert.

Widget-Test: Empty-State vs. Error-State.

Optional: Wenn du später serverseitige Ordnung willst, führe ein persistiertes Feld relativeScore ein (Write-Pfad aktualisiert es), und indiziere createdAt desc, relativeScore desc (+ Varianten mit gender).

3) (Optional) Attempt-Write robust machen

Stelle sicher, dass beim Speichern eines Satzes immer ein Attempt geschrieben wird (nur isMulti == false).

Logge Schreibfehler (FirebaseException) separat; blockiere den UX-Flow nicht.

Rules: erlaube createdAt via serverTimestamp() (prüfe nicht auf == request.time, das ist mit dem ServerTimestamp-Sentinel fragil). Prüfen: Felder-Whitelist, userId == request.auth.uid, !machine.isMulti.

4) Akzeptanzkriterien

Profil lässt sich ohne Red-Screen speichern; kein TextEditingController disposed mehr; kein _dependents.isEmpty.

Layout scrollt statt zu überlaufen.

Leaderboard:

„Absolut“ funktioniert wie zuvor.

„Relativ“ lädt zuverlässig ohne neue Indizes; Top-Einträge korrekt sortiert (e1RM/BW); Einträge ohne/≤0 BW werden ignoriert.

Empty-State wird separat von echten Fehlern angezeigt.

Tests für Parsing/Relative-Sort/Empty-State grün.

Dokumentation: Markdown unter thesis/gamification/ erstellt (siehe unten).

5) Dateien, die du voraussichtlich änderst

lib/features/profile/presentation/screens/profile_screen.dart (Lifecycle, Scroll, Save)

lib/core/providers/settings_provider.dart (robustes updateProfile, Fehlerhandling)

lib/features/device/domain/services/leaderboard_service.dart (clientseitige relative Sortierung)

lib/features/device/data/sources/firestore_machine_attempt_source.dart (Query ohne bodyWeightKg-Filter)

lib/features/device/presentation/widgets/machine_leaderboard_sheet.dart (Empty- vs Error-State)

test/... (neue/angepasste Tests)

ggf. firestore.rules (ServerTimestamp-freundlich)

6) PR-Beschreibung

Problem, Ursache, Lösung kurz erläutern (Controller-Lifecycle & clientseitige Relative-Sort).

Risiken (Performance bei limit=50 minimal), wie mitigiert.

Manuelle Testschritte (Profil speichern; Leaderboard Absolut/Relativ in Tag/Woche/Monat).

Checkliste Akzeptanzkriterien.

7) Datei für die Masterarbeit

Lege zusätzlich eine Markdown-Datei an:
thesis/gamification/20251031_profile_leaderboard_fixes.md mit:

Prompt (dieser Text),

Ziel & Kontext,

Umsetzung/Änderungen (Kurz-Changelog),

Screenshots (Pfade),

offene Punkte/Nacharbeiten.

Bitte umsetzen und einen PR erstellen.
```

## Ziel & Kontext
Stabilisierung der Profilbearbeitung und des relativen Leaderboards in Tap’em, um Abstürze beim Speichern der Körperschwerpunkte zu vermeiden und eine zuverlässige Anzeige relativer Bestenlisten ohne zusätzliche Firestore-Indizes sicherzustellen.

## Umsetzung / Änderungen (Kurz-Changelog)
- Profil-Dialog auf stabilen Widget-State mit persistenten Controllern, validierter Eingabe und sicherem Speicherrückfall umgestellt.
- SettingsProvider um eine kombinierte `updateProfile`-Methode erweitert, die Änderungen konsistent in Firestore schreibt und Rollbacks durchführt.
- Relative Leaderboard-Scores werden nun clientseitig berechnet, fehlerhafte Versuche gefiltert und Fehlerfälle protokolliert.
- Firestore-Abfragen vereinheitlicht und zusätzliche Tests für Service- und UI-Verhalten ergänzt.

## Screenshots (Pfade)
- Keine neuen Screenshots erstellt.

## Offene Punkte / Nacharbeiten
- Optional: Persistente relative Scores in Firestore pflegen, falls serverseitiges Sortieren benötigt wird.
- Beobachten, ob Limit-Erhöhung auf 50 bei größeren Datenmengen weitere Optimierungen erfordert.

