# Geräte- und NFC-Feature – Testdokumentation

Diese Dokumentation fasst die relevanten Unit- und Widget-Tests für die Geräteverwaltung sowie die NFC-Funktionalitäten zusammen. Grundlage sind die in `docs/Dokumentation/` abgelegten Feature-Beschreibungen.

## Überblick

| Testebene | Abgedeckte Komponenten | Datei |
|-----------|------------------------|-------|
| Unit-Tests | `Device.fromJson` (Fallback für Muskelgruppen) | `test/features/device/domain/models/device_test.dart` |
| Widget-Tests | `DeviceScreen` (Set-Erstellung/-Entfernung) | `test/features/device/presentation/screens/device_screen_test.dart` |
| Widget-Tests | `SetCard` (Keypad-Fokussteuerung) | `test/features/device/presentation/widgets/set_card_test.dart` |
| Unit-Tests | `ReadNfcCode` UseCase (Weiterleitung des Datenstroms) | `test/features/nfc/read_nfc_code_test.dart` |

## Testumgebung und Mocking

* **Device-spezifische Provider**: Die Tests verwenden `mocktail`, um `DeviceProvider` und abhängige Provider (u. a. `AuthProvider`, `TrainingPlanProvider`, `ExerciseProvider`) zu simulieren. Für `DeviceSetFieldFocus` wird ein Fallback-Enum registriert, damit Matcherausdrücke mit `any()` auch in Dart's Sound Null Safety gültig bleiben.
* **OverlayNumericKeypadController**: Der Keypad-Controller wird vollständig gemockt. Die Tests stubben ausschließlich die tatsächlich genutzten Parameter (`allowDecimal`), wodurch unerwartete Matcher-Fehler bei optionalen Argumenten vermieden werden.
* **NFC-Service**: Der `ReadNfcCode`-Test nutzt einen `StreamController<String>` und reicht exakt dieselbe Stream-Instanz aus dem Mock zurück, um die Identitätserwartung (`same()`) zu erfüllen.

## Gerätebezogene Tests

### Device.fromJson (`test/features/device/domain/models/device_test.dart`)
1. **Fallback für kombinierte Muskelgruppen**: Verifiziert, dass beim Fehlen des `muscleGroups`-Keys die Factory die Listen `primaryMuscleGroups` und `secondaryMuscleGroups` kombiniert und damit das Verhalten des Konstruktors spiegelt.

### DeviceScreen (`test/features/device/presentation/screens/device_screen_test.dart`)
1. **Set hinzufügen**: Prüft, dass ein Tap auf die Schaltfläche „Set hinzufügen“ den Provider-Aufruf `addSet()` auslöst.
2. **Set entfernen**: Bestätigt, dass das Wegwischen eines `Dismissible`-Elements `removeSet(0)` auf dem Provider ausführt.

### SetCard (`test/features/device/presentation/widgets/set_card_test.dart`)
1. **Keypad-Interaktion**: Sicherstellt, dass das Tippen auf das Gewichts-Eingabefeld den Fokus korrekt beim Provider registriert und den Keypad-Controller mit `allowDecimal: true` öffnet.

## NFC-bezogene Tests

### ReadNfcCode (`test/features/nfc/read_nfc_code_test.dart`)
1. **Stream-Durchleitung**: Bestätigt, dass `execute()` exakt dieselbe Stream-Instanz wie der `NfcService` liefert, wodurch `same()` erfolgreich ist.
2. **Event-Weitergabe**: Überprüft die vollständige Weiterleitung einer Beispielsequenz (`a`, `b`, `c`) inklusive `emitsDone`.

## Ausführung der Tests

Die beschriebenen Tests lassen sich gezielt oder gesammelt mit folgenden Kommandos ausführen:

```bash
flutter test test/features/device/domain/models/device_test.dart
flutter test test/features/device/presentation/screens/device_screen_test.dart
flutter test test/features/device/presentation/widgets/set_card_test.dart
flutter test test/features/nfc/read_nfc_code_test.dart
```

Alle Tests arbeiten mit gemockten Abhängigkeiten, sodass keine externe Hardware oder Backend-Verbindung erforderlich ist.
