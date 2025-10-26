# Geräte-Feature – Testabdeckung

Die folgenden automatisierten Tests decken die im Geräte-Modul beschriebenen Kernfunktionen ab. Alle Tests befinden sich im Verzeichnis `test/features/device/`. Der jüngste Lauf von `flutter test` (siehe Log vom 00:43 min) hat gezeigt, dass einzelne Prüfungen aktuell scheitern. Die Tabelle im Abschnitt „Aktueller Status“ fasst die Resultate zusammen und verweist auf offene Blocker.

## Domain-Modelle
- `domain/models/device_test.dart`
  - Verifiziert Serialisierung/Deserialisierung sowie die `copyWith`-Logik von `Device`, inklusive des korrekten Zusammensetzens der Muskelgruppen.
- `domain/models/exercise_test.dart`
  - Prüft `Exercise` auf korrekte JSON-Konvertierung, Fallback-Logik für ältere Felder und `copyWith`.

## Repositories
- `data/repositories/device_repository_impl_test.dart`
  - Testet die Delegation an die Firestore-Quelle, das Mapping von DTOs zu Domain-Objekten und die Verwaltung des Snapshot-Cursors bei paginierten Sitzungen.
- `data/repositories/exercise_repository_impl_test.dart`
  - Stellt sicher, dass alle Repository-Methoden direkt an die jeweilige Datenquelle weiterleiten.

## Use Cases
- `domain/usecases/device_usecases_test.dart`
  - Prüft alle Geräte-spezifischen Use Cases (`Create`, `Delete`, `Get`, `Set/Update Muscle Groups`) auf korrekte Zusammenarbeit mit dem Repository.
- `domain/usecases/exercise_usecases_test.dart`
  - Deckt die Use Cases für Übungen (Erstellen, Laden, Aktualisieren, Löschen, Muskelgruppen anpassen) ab.

## Widget-Tests
- `presentation/screens/device_screen_test.dart`
  - Simuliert das Hinzufügen und Entfernen von Sätzen auf der `DeviceScreen`, inklusive Swipe-to-Delete über `Dismissible`. Achtung: Der Fall „tapping remove set calls provider.removeSet“ schlägt derzeit fehl, da der erwartete Aufruf im Mock nicht ankommt.
- `presentation/widgets/set_card_test.dart`
  - Validiert, dass beim Tippen auf das Gewichtsfeld der numerische Keypad-Controller geöffnet und der Fokus korrekt über den `DeviceProvider` angefordert wird.
- `presentation/widgets/note_button_widget_test.dart`
  - Prüft das Erfassen neuer Notizen sowie das Zurücksetzen (Löschen) bestehender Notizen über das Bottom-Sheet.

## Aktueller Status & bekannte Probleme

| Testdatei | Ergebnis | Bemerkung |
|-----------|----------|-----------|
| `presentation/screens/device_screen_test.dart` | ❌ Verifikation fehlgeschlagen | `mocktail` sieht keinen `removeSet`-Aufruf. Unser ad-hoc „Vibecoding“-Ansatz liefert keine stabile Lösung; wir müssen alternative Debug-Strategien anwenden (z. B. Fakes oder Integrationstests). |
| `presentation/widgets/set_card_test.dart` | ✅ Bestanden | Fokussteuerung und Keypad-Interaktion laufen wie erwartet. |
| `domain/models/device_test.dart` | ✅ Bestanden | JSON/`copyWith`-Logik weiterhin stabil. |

### Alternativen zum „Vibecoding“

* **Gezielte Analyse des Gesture-Flows**: Breakpoints in `Dismissible`-Callbacks setzen, `tester.drag`/`pump`-Sequenz überprüfen.
* **Fake-Provider einsetzen**: Anstatt auf `mocktail`-Verifikation zu setzen, ein `FakeDeviceProvider` mit explizitem Flag `removeSetCalled` nutzen.
* **Integrationstest**: `DeviceScreen` mit realem Provider und `ChangeNotifierProvider` in einem Integrationstest ausführen, um Gesten ohne Mocks zu testen.
* **Logs instrumentieren**: Temporär Logging in der Produktionslogik (`removeSet`) aktivieren, um während des Tests die Aufrufkette zu sehen.

## Ausführung
Alle Tests werden mit `flutter test` gestartet. In Umgebungen ohne vorinstalliertes Flutter SDK kann der Befehl nicht ausgeführt werden.
