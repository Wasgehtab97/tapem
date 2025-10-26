# Auth Feature – Testdokumentation

Diese Dokumentation beschreibt alle aktuellen Tests des Auth-Features und erläutert deren Zielsetzung, Struktur sowie die verwendeten Test-Doubles. Die Informationen basieren auf den Unit-Tests für den `AuthProvider` und den Widget-Tests für die Auth-UI-Komponenten.

## Überblick

| Testebene | Abgedeckte Komponenten | Datei |
|-----------|------------------------|-------|
| Unit-Tests | `AuthProvider` inkl. Statusverwaltung, Persistenz und Fehlerbehandlung | `test/features/auth/auth_provider_test.dart` |
| Widget-Tests | `LoginForm`, `SplashScreen`, `showUsernameDialog` | `test/features/auth/auth_provider_widget_test.dart` |

## Testumgebung und Mocking

* **SharedPreferences**: Jeder Test setzt `SharedPreferences.setMockInitialValues({})`, um persistente Zustände deterministisch zu halten und Gym-Codes zu verifizieren.
* **Repositories & Manager**: Der `AuthProvider` wird mit Fake-Repositories und einem Fake `FirebaseAuthManager` betrieben, um Authentifizierungs- und Profildaten zu simulieren, ohne echte Firebase-Aufrufe auszuführen.
* **SessionDraftRepository**: Ein Fake-Repository protokolliert Löschoperationen, sodass der Logout-Test die Bereinigung von Session-Entwürfen validieren kann.
* **Widget-Tests**: Verwenden `mocktail`-basierte `AuthProvider`-Mocks, um Ladezustände, Navigationsentscheidungen und Fehlermeldungen kontrolliert auszulösen.

## Unit-Tests für den AuthProvider

### 1. Initialer Ladevorgang synchronisiert Nutzerprofil
* **Ziel**: Sicherstellen, dass beim Start der Provider den aktuellen Nutzer lädt, Custom Claims ausliest, Sichtbarkeitsflags synchronisiert und den bevorzugten Gym-Code persistiert.
* **Kernaktionen**: Fake-Repository liefert einen gespeicherten Nutzer; Custom-Claim „role“ wird als Provider-Rolle gesetzt; Public-Profile-Flag wird über Repository aktualisiert; erster Gym-Code landet in `SharedPreferences`.
* **Assertions**: Nutzer gilt als eingeloggt, Rolle ist `coach`, öffentliches Profil aktiviert, Gym-Code `gym1` gespeichert.

### 2. Erfolgreiches Login aktualisiert Zustand
* **Ziel**: Validieren, dass `login` den Nutzerzustand und die Mailadresse aktualisiert und Fehler zurücksetzt.
* **Kernaktionen**: Fake-Repository aktualisiert Mailadresse beim Login.
* **Assertions**: Provider enthält neue Mailadresse, `error` ist `null`.

### 3. Fehlgeschlagenes Login speichert Fehler
* **Ziel**: Prüfen, dass Exceptions aus dem Repository als Fehlermeldung gespeichert und Ladezustände beendet werden.
* **Assertions**: `error` enthält Exception-Text, `isLoading` ist `false`.

### 4. Registrierung: Erfolg und Fehlerfall
* **Ziel**: Verifizieren, dass `register` den Nutzerzustand aktualisiert und Fehler korrekt abbildet.
* **Kernaktionen**: Zwei Repositories – eines liefert aktualisierten Nutzer, das andere wirft eine Exception.
* **Assertions**: Erfolgsfall setzt neue Mailadresse, Fehlerfall befüllt `error`.

### 5. Logout räumt Zustand auf
* **Ziel**: Sicherstellen, dass `logout` Auth-Status, Session-Entwürfe und persistierte Gym-Codes entfernt.
* **Assertions**: `isLoggedIn` ist `false`, Fake-Session-Repo verzeichnet `deleteAll`, `SharedPreferences` verliert Gym-Code.

### 6. Benutzername setzen: Erfolg, Name vergeben, Firebase-Fehler
* **Ziel**: Abdecken, dass `setUsername` sowohl erfolgreiche Aktualisierung als auch belegte Benutzernamen und Firestore-Fehler behandelt.
* **Kernaktionen**: Drei Repositories simulieren erfolgreiche Speicherung, belegte Namen und `FirebaseException`.
* **Assertions**: Erfolgsfall liefert `true` und aktualisierten Namen, belegter Name führt zu `false` und `error = 'username_taken'`, Firestore-Fehler resultiert in `false` und Fehlercode im Provider.

### 7. Sichtbarkeitsflags aktualisieren und Fehler behandeln
* **Ziel**: Prüfen, dass `setShowInLeaderboard` und `setPublicProfile` Werte sofort aktualisieren und Exceptions melden.
* **Assertions**: Erfolgsfall setzt Flags auf `false`, Fehlerfall schreibt Fehlermeldung in `error`.

### 8. Avatar-Key: Optimistisches Update mit Rollback
* **Ziel**: Sicherstellen, dass `setAvatarKey` den Avatar lokal aktualisiert, bei Repository-Fehlern aber zum alten Wert zurückkehrt.
* **Assertions**: Erfolgsfall setzt `avatarKey` auf `new`, Fehlerfall wirft Exception, stellt `avatarKey` auf `old` zurück und speichert Fehlermeldung.

### 9. Passwort-Reset leitet Fehler weiter
* **Ziel**: Validieren, dass `resetPassword` das Repository aufruft und `FirebaseAuthException`-Meldungen speichert.
* **Assertions**: Erfolgsfall hinterlässt `error = null`, Fehlerfall setzt Fehlermeldung `bad`.

### 10. Gym-Auswahl validiert Gym-Codes
* **Ziel**: Sicherstellen, dass nur bekannte Gym-Codes persistiert werden und ungültige Eingaben ignoriert werden.
* **Assertions**: Auswahl `gym2` wird übernommen und gespeichert, unbekannter Code verändert Zustand nicht.

## Widget-Tests für Auth-Komponenten

### LoginForm
1. **Credential-Submit navigiert nach Erfolg**: Testet Eingabe von Mail/Passwort, überprüft den erwarteten `login`-Aufruf des Providers und stellt sicher, dass nach dem Abschließen des Futures zur Home-Route navigiert wird.
2. **Fehleranzeige**: Simuliert Fehlerantwort des Providers und erwartet gerenderte Fehlermeldung.
3. **Ladeindikator**: Erzwingt `isLoading = true`, überprüft deaktivierten Button und sichtbaren `CircularProgressIndicator`.

### SplashScreen
4. **Navigation zur Auth-Route**: Bei nicht eingeloggtem Nutzer Navigationsziel `AppRouter.auth` nach Ablauf des Timers.
5. **Navigation zur Gym-Auswahl**: Bei mehreren Gym-Codes wird `AppRouter.selectGym` gepusht.
6. **Direkt zur Home-Route**: Bei einem einzigen Gym-Code führt Splash direkt nach `AppRouter.home`.

### Username-Dialog (`showUsernameDialog`)
7. **Dialog schließt nach erfolgreichem Speichern**: `setUsername` liefert `true`; Dialog verschwindet nach `pumpAndSettle`.
8. **Fehler bleibt sichtbar**: `setUsername` gibt `false` zurück, Provider setzt Fehlertext; AlertDialog bleibt geöffnet und zeigt Meldung.

## Aktuelle Lücken und mögliche Ergänzungen

* **Registrierungs-Flow ohne Widget-Tests**: `RegistrationForm` (inkl. Gym-Code-Validierung, Sperrlogik nach Fehlversuchen und Snackbar-Feedback) wird aktuell nicht durch Widget-Tests abgesichert.
* **AuthScreen ohne UI-Tests**: Der Tab-basierte Wechsel zwischen Login und Registrierung sowie der globale Lade-Overlay des `AuthScreen` sind ungetestet.
* **ResetPasswordScreen ohne Abdeckung**: Für `ResetPasswordScreen` existieren weder Widget- noch Integrationstests, obwohl dort Interaktionen mit `FirebaseAuth.confirmPasswordReset` stattfinden.
* **Validierungs- und Fehler-Edge-Cases**: Formularvalidierungen (z. B. ungültige E-Mails oder zu kurze Passwörter) sowie Snackbar-Ausgaben werden momentan nicht explizit geprüft.

## Ausführung der Tests

Führe sämtliche Auth-bezogenen Tests mit folgendem Kommando aus:

```bash
flutter test test/features/auth
```

Die Tests lassen sich parallel in CI integrieren und liefern über die Fake-Abhängigkeiten deterministische Ergebnisse.
