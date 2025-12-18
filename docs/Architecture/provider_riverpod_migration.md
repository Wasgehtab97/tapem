## Provider → Riverpod Migration – Roadmap

Ziel: Mittelfristig die gesamte App auf Riverpod als einziges State‑Management heben, ohne den laufenden Betrieb oder die Launch‑Readiness zu gefährden.

### 1. Status Quo (Stand: nach Migration 2025)

- **Riverpod** ist die einzige Quelle der Wahrheit für:
  - Auth‑State (`authViewStateProvider`),
  - Workout‑State (`WorkoutDayController` und zugehörige Provider),
  - Coaching, Training‑Pläne, XP, Community, NFC usw.
- **Provider** wird im Produktions‑Code nicht mehr verwendet:
  - Alle früheren `ChangeNotifier`‑Adapter werden ausschließlich über Riverpod‑Provider erzeugt.
  - `LegacyProviderScope` ist nur noch ein dünner Wrapper um das Kind‑Widget und baut keine eigene Provider‑Hierarchie mehr auf.
- Neue Features werden ausschließlich **direkt über Riverpod** gebaut (Widget = `ConsumerWidget` / `ConsumerStatefulWidget`), ohne neue Provider‑basierte Klassen zu erzeugen.

### 2. Migrationsprinzipien

1. **Single Source of Truth**
   - Fachlicher State lebt ausschließlich in Riverpod‑Providern.
   - Provider‑Klassen dürfen keine eigene Business‑Logik oder eigenen Zustand mehr halten, sondern nur lesen/weiterreichen.
2. **Schrittweise Migration nach Feature‑Modulen**
   - Pro Modul (z.B. „Friends“, „Coaching“, „Community“) wird zunächst der Daten‑/Domain‑Layer stabilisiert.
   - Anschließend werden einzelne Screens von Provider auf Riverpod umgestellt.
3. **Keine „Cross‑Wires“**
   - Keine neuen Stellen, an denen Provider direkt Firestore/Services ansprechen.
   - Neue State‑Logik immer erst in Riverpod, dann optional Adapter.

### 3. Konkreter Migrationsplan

1. **Lesende Provider zuerst**
   - Kandidaten: Settings, Theme, einfache Read‑Only‑Daten (z.B. Brands).
   - Vorgehen:
     - Widget von `Consumer`/`Provider.of` auf `ConsumerWidget` umstellen.
     - Alte Provider‑Zugriffe entfernen, Adapter in `LegacyProviderScope` nur noch für Alt‑Screens behalten.
2. **Komplexe Controller danach**
   - WorkoutDay, Coaching, Chat/Friends:
     - Klassen intern bereits Riverpod‑first halten (ist heute großteils erfüllt).
     - Schrittweise UI‑Screens direkt an Riverpod hängen (ohne `AuthProvider`/`GymProvider`), beginnend mit neuen/überarbeiteten Screens.
3. **LegacyProviderScope abbauen**
   - (Abgeschlossen) Adapter wurden entfernt; `LegacyProviderScope` ist ein reiner Kompatibilitäts‑Wrapper ohne eigene Provider.
4. **Abschlusskriterium**
   - Es existieren keine produktiven Widgets mehr, die `package:provider` als State‑Mechanismus nutzen.
   - Weitere Refactorings (z.B. vollständiges Entfernen alter `ChangeNotifier`‑Klassen) sind optionale Post‑Launch‑Aufräumarbeiten und nicht Teil der Launch‑Kriterien.

### 4. Regeln für neue Features

- Neue Screens / Module:
  - **Nur Riverpod verwenden**, keine neuen Provider‑basieren Notifier/States.
  - Falls bestehende Provider‑Consumer Widgets eingebunden werden müssen, nur über vorhandene Adapter – keine neuen Brücken einziehen.
- Refactorings:
  - Wenn ein Screen ohnehin angefasst wird (z.B. wegen UX‑Verbesserung), bevorzugt gleich auf Riverpod umstellen.

Diese Roadmap erfüllt die Punkte aus Phase 8.17 der `technisch_launchready.md`:  
- Die Migrationsschritte sind klar beschrieben.  
- Der Brücken‑Layer (`LegacyProviderScope`) ist dokumentiert und bleibt bewusst als Übergangslösung bestehen, ohne die Launch‑Readiness zu gefährden.
