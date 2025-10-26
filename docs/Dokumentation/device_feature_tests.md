# Geräte-Feature – Testdokumentation

Diese Dokumentation fasst die relevanten Unit- und Widget-Tests für die Geräteverwaltung zusammen. Grundlage sind die in `docs/Dokumentation/` abgelegten Feature-Beschreibungen.

## Überblick

| Testebene | Abgedeckte Komponenten | Datei |
|-----------|------------------------|-------|
| Unit-Tests | `Device.fromJson` (Fallback für Muskelgruppen) | `test/features/device/domain/models/device_test.dart` |
| Widget-Tests | `DeviceScreen` (Set-Erstellung/-Entfernung) | `test/features/device/presentation/screens/device_screen_test.dart` |
| Widget-Tests | `SetCard` (Keypad-Fokussteuerung) | `test/features/device/presentation/widgets/set_card_test.dart` |

## Testumgebung und Mocking

* **Device-abhängige Provider**: Die Tests verwenden `mocktail`, um `DeviceProvider` und zugehörige Provider wie `AuthProvider`, `TrainingPlanProvider` und `ExerciseProvider` zu simulieren. Fallbacks für `Device`, `Exercise`, `TextEditingController`, das Enum `DeviceSetFieldFocus` sowie `Duration.zero` stellen sicher, dass `any()`-Matcher mit Dart's Sound Null Safety kompatibel bleiben.
* **Snapshot-Pagination**: Die Widget-Tests stubben `hasMoreSnapshots`, `prefetchSnapshots` und `loadMoreSnapshots`, damit `DevicePager` in der `DeviceScreen` keine Nullwerte erhält und keine unnötigen Timer startet.
* **OverlayNumericKeypadController**: Der Keypad-Controller wird vollständig gemockt. Die Tests stubben ausschließlich die tatsächlich genutzten Parameter (`allowDecimal`), wodurch unerwartete Matcher-Fehler bei optionalen Argumenten vermieden werden.

## Gerätebezogene Tests

### Device.fromJson (`test/features/device/domain/models/device_test.dart`)
1. **Fallback für kombinierte Muskelgruppen**: Verifiziert, dass beim Fehlen des `muscleGroups`-Keys die Factory die Listen `primaryMuscleGroups` und `secondaryMuscleGroups` kombiniert und damit das Verhalten des Konstruktors spiegelt.

### DeviceScreen (`test/features/device/presentation/screens/device_screen_test.dart`)
1. **Set hinzufügen**: Prüft, dass ein Tap auf die Schaltfläche „Set hinzufügen“ den Provider-Aufruf `addSet()` auslöst.
2. **Set entfernen**: Bestätigt, dass das Wegwischen eines `Dismissible`-Elements `removeSet(0)` auf dem Provider ausführt.

### SetCard (`test/features/device/presentation/widgets/set_card_test.dart`)
1. **Keypad-Interaktion**: Sicherstellt, dass das Tippen auf das Gewichts-Eingabefeld den Fokus korrekt beim Provider registriert und den Keypad-Controller mit `allowDecimal: true` öffnet.

## Ausführung der Tests

Die beschriebenen Tests lassen sich gezielt oder gesammelt mit folgenden Kommandos ausführen:

```bash
flutter test test/features/device/domain/models/device_test.dart
flutter test test/features/device/presentation/screens/device_screen_test.dart
flutter test test/features/device/presentation/widgets/set_card_test.dart
```

Alle Tests arbeiten mit gemockten Abhängigkeiten, sodass keine externe Hardware oder Backend-Verbindung erforderlich ist.
