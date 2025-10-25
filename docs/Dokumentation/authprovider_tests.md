# AuthProvider – Tests (Unit & Widget)

Diese Test-Suite ergänzt das AuthProvider-Feature um gezielte Unit- und Widget-Tests und dokumentiert die wichtigsten Szenarien.

## Architektur-Anpassungen

* Die `AuthProvider`-Klasse akzeptiert jetzt ein `AuthRepository`-Interface, einen injizierbaren `FirebaseAuthManager` sowie ein `SessionDraftRepository`. Dadurch lassen sich Abhängigkeiten in Tests leichter faken.
* Ein neuer `FirebaseAuthManager` kapselt alle Zugriffe auf `FirebaseAuth`. Standardmäßig nutzt er `FirebaseAuth.instance`, in Tests wird eine Mock-Implementierung verwendet.

## Abgedeckte Unit-Test-Szenarien

* **Login-Erfolg** – Prüft, dass `login` Nutzerinformationen lädt, Custom Claims verarbeitet, den Gym-Code in `SharedPreferences` speichert und Ladezustände korrekt setzt.
* **Login-Fehlerfall** – Simuliert eine Exception beim Login und stellt sicher, dass Fehlernachrichten gesetzt und Nutzerinformationen zurückgesetzt werden.
* **Logout** – Verifiziert, dass Logout den Nutzerzustand, den persistierten Gym-Code und gespeicherte Session-Entwürfe löscht.
* **Claim-Synchronisation** – Stellt sicher, dass die Rolle aus Custom Claims den Nutzerdaten zugewiesen wird.
* **Gym-Code-Persistenz** – Testet sowohl den Fall eines gültigen gespeicherten Gym-Codes als auch das Zurückfallen auf den ersten Gym-Code bei ungültigen oder fehlenden Werten.

## Widget-Tests

* **LoginForm** – Prüft das Rendering von Eingabefeldern, das Sperren des Login-Buttons im Ladezustand, SnackBar-Fehlerausgabe sowie die Navigation zur Home-Route nach erfolgreichem Login.
* **SplashScreen** – Simuliert die Zeitverzögerung und leitet abhängig von `isLoggedIn` und den verfügbaren Gym-Codes auf Auth-, Select-Gym- oder Home-Routen weiter.
* **Username-Dialog** – Überprüft, dass erfolgreiche Speichervorgänge den Dialog schließen und Fehlversuche eine Rückmeldung im Eingabefeld anzeigen.

## Mocking-Strategie

* Für SharedPreferences wird pro Test `SharedPreferences.setMockInitialValues({})` verwendet.
* Repository-Interaktionen werden über `mocktail`-Mocks für `AuthRepository`, `FirebaseAuthManager`, `SessionDraftRepository` und `FirebaseUser` simuliert.
* Widget-Tests verwenden `mocktail`-gestützte `AuthProvider`-Fakes, um Ladezustände, Navigation und Fehlerbehandlung deterministisch auszulösen.
* Externe Aufrufe (z. B. `reload`, `getIdToken`, `deleteAll`) werden über `verify`/`verifyNever` geprüft.

Diese Tests bilden das Fundament für weitere Auth-bezogene Testfälle und erhöhen die Testbarkeit des Providers nachhaltig.
