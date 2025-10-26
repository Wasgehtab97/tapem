# NFC Feature – Testdokumentation

Diese Dokumentation fasst die neu hinzugefügten Unit- und Widget-Tests für die NFC-Funktionalitäten zusammen. Grundlage sind die in `docs/Dokumentation/` beschriebenen Flows für das Lesen und Schreiben von NFC-Tags.

## Überblick

| Testebene | Abgedeckte Komponenten | Datei |
|-----------|------------------------|-------|
| Unit-Tests | `ReadNfcCode` UseCase (Weiterleitung des Datenstroms) | `test/features/nfc/read_nfc_code_test.dart` |
| Unit-Tests | `WriteNfcTagUseCase` (Verfügbarkeit, Polling, Schreiben, Session-Cleanup) | `test/features/nfc/write_nfc_tag_usecase_test.dart` |
| Widget-Tests | `GlobalNfcListener` (Routensteuerung nach NFC-Scan) | `test/features/nfc/global_nfc_listener_test.dart` |

## Testumgebung und Mocking

* **MethodChannel-Stubs**: Der `flutter_nfc_kit`-Channel wird vollständig simuliert, um NFC-Verfügbarkeit, Polling, Schreibversuche und `finish()`-Aufrufe deterministisch zu kontrollieren.
* **NFC-Manager**: Der Channel `plugins.flutter.io/nfc_manager` wird global mit einem Dummy-Handler versehen, damit `stopSession()` im Widget-Test keine `MissingPluginException` auslöst.
* **Provider/UseCases**: `mocktail` stellt Mocks für `ReadNfcCode`, `GetDeviceByNfcCode` und `NavigatorObserver` bereit. Für die Authentifizierung kommt ein leichter Fake-Provider zum Einsatz, der ausschließlich den ausgewählten Gym-Code bereitstellt.

## Unit-Tests für die UseCases

### ReadNfcCode (`test/features/nfc/read_nfc_code_test.dart`)
1. **Stream-Durchleitung**: Verifiziert, dass `execute()` genau den Stream des `NfcService` zurückliefert – ohne eigene Transformationen.
2. **Event-Weitergabe**: Prüft, dass alle vom Service gesendeten Codes in identischer Reihenfolge beim Konsumenten ankommen.

### WriteNfcTagUseCase (`test/features/nfc/write_nfc_tag_usecase_test.dart`)
1. **Verfügbarkeitsprüfung**: Liefert eine Exception mit der dokumentierten Fehlermeldung, wenn der Channel `notSupported` meldet.
2. **Erfolgreiches Schreiben**: Stellt sicher, dass Polling-Parameter (Timeout, iOS-Alerts) korrekt sind, der Text-Payload exakt in Hex (`02656e…`) generiert wird und die Session mit dem erwarteten Alert beendet wird.
3. **Cleanup bei Fehlern**: Erzwingt einen Schreibfehler und bestätigt, dass `finish()` trotzdem aufgerufen wird – wichtig, um blockierte Sessions zu vermeiden.

## Widget-Tests für GlobalNfcListener (`test/features/nfc/global_nfc_listener_test.dart`)
1. **Leere Payloads ignorieren**: Ein leerer Scan löst weder Repository-Aufrufe noch Navigation aus.
2. **Multi-Geräte-Routing**: Bei `isMulti = true` navigiert der Listener zur Exercise-Liste und übergibt `gymId`/`deviceId` wie dokumentiert.
3. **Single-Gerät-Routing**: Für Einzelgeräte erfolgt ein direkter Push zur Gerätesicht mit den passenden Argumenten.
4. **Kein Gym ausgewählt**: Ist kein Gym-Code gesetzt, wird kein Repository-Call gestartet – auch wenn ein NFC-Code eintrifft.

## Ausführung der Tests

Alle NFC-bezogenen Tests lassen sich gemeinsam mit folgendem Kommando starten:

```bash
flutter test test/features/nfc
```

Die MethodChannel-Stubs sorgen dafür, dass die Tests ohne echte NFC-Hardware deterministisch ausführbar sind.
