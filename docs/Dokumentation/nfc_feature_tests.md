# NFC-Feature – Testdokumentation

Diese Dokumentation beschreibt die relevanten Tests für die NFC-Funktionalitäten. Grundlage sind die in `docs/Dokumentation/` abgelegten Feature-Beschreibungen.

## Überblick

| Testebene | Abgedeckte Komponenten | Datei |
|-----------|------------------------|-------|
| Unit-Tests | `ReadNfcCode` UseCase (Weiterleitung des Datenstroms) | `test/features/nfc/read_nfc_code_test.dart` |
| Widget-Tests | `GlobalNfcListener` (Session-Steuerung und Provider-Interaktionen) | `test/features/nfc/global_nfc_listener_test.dart` |

## Testumgebung und Mocking

* **NFC-Streams**: Der `ReadNfcCode`-Test nutzt einen `StreamController<String>` und reicht exakt dieselbe Stream-Instanz aus dem Mock zurück, um die Identitätserwartung (`same()`) zu erfüllen.
* **Provider-Abhängigkeiten**: Für Widget-Tests wie `GlobalNfcListener` werden `AuthProvider`, `GetDeviceByNfcCode` und `MembershipService` gemockt. Dadurch lassen sich Navigationspfade und Berechtigungsprüfungen ohne echte Firestore-Zugriffe simulieren.

## NFC-bezogene Tests

### ReadNfcCode (`test/features/nfc/read_nfc_code_test.dart`)
1. **Stream-Durchleitung**: Bestätigt, dass `execute()` exakt dieselbe Stream-Instanz wie der `NfcService` liefert, wodurch `same()` erfolgreich ist.
2. **Event-Weitergabe**: Überprüft die vollständige Weiterleitung einer Beispielsequenz (`a`, `b`, `c`) inklusive `emitsDone`.

### GlobalNfcListener (`test/features/nfc/global_nfc_listener_test.dart`)
1. **Session-Handling**: Stellt sicher, dass beim Starten und Stoppen von Sessions die entsprechenden Methoden des `NfcService` verwendet werden.
2. **Provider-Interaktion**: Prüft, dass bei gefundenen Geräten `GetDeviceByNfcCode` und `MembershipService` korrekt aufgerufen und Navigationsaktionen ausgelöst werden.

## Ausführung der Tests

Die beschriebenen Tests lassen sich gezielt oder gesammelt mit folgenden Kommandos ausführen:

```bash
flutter test test/features/nfc/read_nfc_code_test.dart
flutter test test/features/nfc/global_nfc_listener_test.dart
```

Alle Tests arbeiten mit gemockten Abhängigkeiten und benötigen weder NFC-Hardware noch Backend-Verbindungen.
