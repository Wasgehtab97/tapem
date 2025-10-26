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

### WriteNfcTagUseCase (`test/features/nfc/write_nfc_tag_usecase_test.dart`)
1. **Session-Abschluss trotz Fehlern**: Erwartet, dass `finishSession()` selbst bei fehlgeschlagenem Schreibvorgang aufgerufen wird.
2. **Aktueller Status**: Der Test bricht derzeit mit einer `PlatformException(write_failed, failed, null, null)` ab. Die Mock-Implementierung reicht den Fehler ungefiltert durch, sodass weder Session-Cleanup noch Fehlerbehandlung validiert werden können.

## Aktueller Teststatus (Stand laut letztem Lauf `flutter test`)

| Test | Ergebnis | Beobachtung |
|------|----------|-------------|
| `read_nfc_code_test.dart` | ❌ Timeout | Der Stream wird nie abgeschlossen; der Test läuft 30 Sekunden und endet mit einer `TimeoutException`. |
| `write_nfc_tag_usecase_test.dart` | ❌ PlatformException | `WriteNfcTagUseCase.execute` wirft eine `PlatformException(write_failed, failed, null, null)`; dadurch wird der erwartete Session-Finish-Call nicht erreicht. |
| `global_nfc_listener_test.dart` | ✅ Bestanden | Die bisherigen Assertions zum Session-Handling greifen weiterhin. |

## Blocker & nächste Schritte

* Momentan kommen wir mit „Vibecoding“ nicht weiter: spontane Anpassungen am Test-Setup oder an den UseCases führen entweder zu neuen Exceptions oder lösen den Timeout nicht auf.
* Für den Timeout des `ReadNfcCode`-Tests müssen wir den Mock-Stream neu gestalten (z. B. kontrollierter Abschluss über `close()` in `setUp`/`tearDown`) oder die Produktionslogik so anpassen, dass `cancel`/`dispose` Pfade deterministisch sind.
* Für die `PlatformException` im `WriteNfcTagUseCase` sollten wir untersuchen, ob die Test-Mocks den erwarteten Fehlerpfad korrekt simulieren oder ob der UseCase eine Guard-Branch zur Fehlerbehandlung benötigt. Ohne Hardware-Zugriff ist eine reine Mock-Lösung eventuell nicht belastbar.
* Alternative Lösungswege: 
  * Gerätetests mit einem echten Android-Emulator samt NFC-Hardware-Simulation, um das Verhalten fernab der Mock-Umgebung zu beobachten.
  * Fokus auf Integrationstests in Kombination mit einem Fake-NFC-Plugin, das deterministische Antworten liefert.
  * Analyse der Plattformkanal-Aufrufe (`MethodChannel`) und gezielte Abstraktion der Fehlerbehandlung, damit Tests ohne direkte Plattform-Implementierung laufen können.

## Ausführung der Tests

Die beschriebenen Tests lassen sich gezielt oder gesammelt mit folgenden Kommandos ausführen:

```bash
flutter test test/features/nfc/read_nfc_code_test.dart
flutter test test/features/nfc/write_nfc_tag_usecase_test.dart
flutter test test/features/nfc/global_nfc_listener_test.dart
```

Alle Tests arbeiten mit gemockten Abhängigkeiten und benötigen weder NFC-Hardware noch Backend-Verbindungen. Die aktuellen Fehler zeigen jedoch, dass wir die Mocks oder die UseCase-Logik weiterentwickeln müssen, um die Ausführung zu stabilisieren.
