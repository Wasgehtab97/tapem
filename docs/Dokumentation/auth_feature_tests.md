# Auth Feature – Testdokumentation

Diese Dokumentation beschreibt alle aktuellen Tests des Auth-Features und erläutert deren Zielsetzung, Struktur sowie die verwendeten Test-Doubles. Die Informationen basieren auf den Unit-Tests für den `AuthProvider` und den Widget-Tests für die Auth-UI-Komponenten.

## Überblick

| Testebene | Abgedeckte Komponenten | Datei |
|-----------|------------------------|-------|
| Unit-Tests | `AuthProvider` inkl. Statusverwaltung, Persistenz und Fehlerbehandlung | `test/features/auth/auth_provider_test.dart` |
| Widget-Tests | `LoginForm`, `RegistrationForm`, `PasswordResetDialog`, `UsernameDialog`, `DynamicLinkListener` | `test/features/auth/presentation/widgets/*.dart` |
| Screen-Tests | `AuthScreen`, `ResetPasswordScreen` | `test/features/auth/presentation/screens/*.dart` |

## Testumgebung und Mocking

* **SharedPreferences**: Jeder Test setzt `SharedPreferences.setMockInitialValues({})`, um persistente Zustände deterministisch zu halten und Gym-Codes zu verifizieren.
* **Repositories & Manager**: Der `AuthProvider` wird mit Fake-Repositories und einem Fake `FirebaseAuthManager` betrieben, um Authentifizierungs- und Profildaten zu simulieren, ohne echte Firebase-Aufrufe auszuführen.
* **SessionDraftRepository**: Ein Fake-Repository protokolliert Löschoperationen, sodass der Logout-Test die Bereinigung von Session-Entwürfen validieren kann.
* **Widget- und Screen-Tests**: Verwenden echte `AuthProvider`-Instanzen mit Fake-Repositories sowie Fake-Dienste (z. B. `FakeFirebaseAuthManager`, `FakeFirebaseAuth`), um Navigation, Ladezustände und Fehlermeldungen kontrolliert auszulösen – ganz ohne externe Mocking-Frameworks.

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

### LoginForm (`test/features/auth/presentation/widgets/login_form_test.dart`)
1. **Erfolgreiche Anmeldung**: Füllt Formular, löst echten Provider-Login aus und verifiziert Navigation zu `AppRouter.home`.
2. **Fehlgeschlagene Anmeldung**: Simuliert Repository-Exception und erwartet SnackBar mit Fehlertext.
3. **Ladezustand**: Erzwingt einen langen Login-Vorgang und prüft deaktivierten Button sowie Spinner.

### RegistrationForm (`.../registration_form_test.dart`)
4. **Erfolgreiche Registrierung**: Validiert Gym-Code über injizierten Validator, führt Registrierung aus und navigiert nach `AppRouter.home`.
5. **Ungültiger Gym-Code**: Wirft `GymNotFoundException`, zeigt Validierungsfehler und verhindert Login.
6. **Rate-Limit**: Drei Fehlversuche sperren das Formular, deaktivieren den Button und zeigen `gymCodeLockedMessage`.

### PasswordResetDialog (`.../password_reset_dialog_test.dart`)
7. **Validierung**: Prüft, dass leere oder ungültige E-Mail unmittelbar Fehler anzeigt.
8. **Erfolgreicher Versand**: Simuliert erfolgreiches Repository, schließt Dialog und zeigt Bestätigungs-SnackBar.
9. **Fehlerfall**: Erzwingt `FirebaseAuthException` und zeigt Backend-Fehlermeldung im Dialog.

### UsernameDialog (`.../username_dialog_test.dart`)
10. **Speichern**: Reale Provider-Instanz setzt Nutzernamen und schließt den Dialog.
11. **Name belegt**: Fake-Repository meldet belegten Namen; Dialog bleibt offen und zeigt `username_taken`.

### DynamicLinkListener (`.../dynamic_link_listener_test.dart`)
12. **Initialer Link**: Kontrollierter Pending-Link navigiert direkt zu `AppRouter.resetPassword`.
13. **Ignorierte Links**: Nicht passende Modi lösen keine Navigation aus.
14. **Live-Stream**: Eine simulierte Stream-Nachricht führt zur Navigation und wird nachgewiesen.

### AuthScreen (`test/features/auth/presentation/screens/auth_screen_test.dart`)
15. **Tab-Navigation**: Wechselt zwischen Login- und Registrierungs-Tab und prüft Sichtbarkeit der Formularfelder.
16. **Lade-Overlay**: Ein laufender Provider-Login blendet den Overlay-Spinner über beide Tabs ein.

### ResetPasswordScreen (`.../reset_password_screen_test.dart`)
17. **Erfolgreicher Reset**: Fake-FirebaseAuth bestätigt Passwort-Reset, zeigt Erfolgsnachricht und navigiert zu `AppRouter.auth`.
18. **Fehlerfall**: Simulierter `FirebaseAuthException` hinterlegt Fehlertext im Formular, ohne die Navigation auszulösen.

## Ausführung der Tests

Führe sämtliche Auth-bezogenen Tests mit folgendem Kommando aus:

```bash
flutter test test/features/auth
```

Die Tests lassen sich parallel in CI integrieren und liefern über die Fake-Abhängigkeiten deterministische Ergebnisse.
