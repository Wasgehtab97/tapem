## State‑Management Guidelines (Provider → Riverpod)

Ziel: Klare Leitplanken, damit neuer Code konsistent mit der geplanten Migration ist und keine zusätzlichen Provider‑Schulden entstehen.

### 1. Grundprinzipien

- Fachlicher State lebt ausschließlich in **Riverpod‑Providern**.
- `provider` wird nur noch als **Legacy‑Adapter** verwendet (`LegacyProviderScope`), um bestehende Widgets zu versorgen.
- Neue Features und Screens werden grundsätzlich **Riverpod‑first** umgesetzt.

### 2. Do & Don’t

**Do**

- Neue State‑Logik über Riverpod aufsetzen (`StateNotifierProvider`, `Provider`, `FutureProvider`, `StreamProvider`, …).
- Widgets als `ConsumerWidget` oder `ConsumerStatefulWidget` schreiben und mit `ref.watch` / `ref.read` arbeiten.
- Bestehende Provider‑basierte Widgets nur dann anfassen, wenn ohnehin ein Refactoring ansteht – dann bevorzugt direkt auf Riverpod migrieren.

**Don’t**

- Keine neuen `ChangeNotifierProvider`, `provider.Consumer` oder `Provider.of(context)` im produktiven Code hinzufügen.
- Keine neuen direkten Firestore‑Zugriffe aus Provider‑Klassen heraus; stattdessen Repositories/Data Sources verwenden (siehe `docs/Architecture/firestore_repositories.md`).
- Keine neuen Brücken zwischen Provider und Riverpod bauen – `LegacyProviderScope` bleibt die einzige Adapter‑Schicht.

### 3. Code‑Review‑Hinweise

- Neue Pull Requests prüfen auf:
  - Verwendung von `package:provider` nur in bereits bekannten Legacy‑Widgets.
  - Neue State‑Klassen sind Riverpod‑Notifier/Provider, keine neuen `ChangeNotifier`‑basierenden Stores.
- Wenn in einem PR ohnehin umfangreiche Änderungen an einem Legacy‑Screen erfolgen, prüfen, ob eine Migration auf Riverpod in Reichweite ist (siehe `docs/ToDos/provider_riverpod_migration_roadmap.md`).

