# Titel
PR: Auth Gym Flow Stabilization

# Kontext
Stabilisierung des Authentifizierungs- und Gym-Claiming-Flows nach dem refactor der `AuthProvider`-Logik, damit Masterarbeit-Analysen zur Gamification-Plattform auf konsistenten Nutzerstatusdaten aufsetzen können.

# Kurzfassung des Prompts
Der Prompt forderte eine strukturierte Dokumentation (Titel, Kontext, Prompt-Zusammenfassung, Ziele, Dateiübersicht, Ergebnis-Bullets, Hinweise) sowie eine klare Beschreibung der Änderungen rund um `AuthResult`, `switchGym`, `GymScopedStateController`, UI und Tests inkl. Dateireferenzen.
Zuerst ist eine kurze IST-Analyse erforderlich, die Auth-Flow-Instabilitäten und fehlende Gym-Persistenz benennt.
Darauf folgt eine SOLL-Definition mit klarer Zielarchitektur für `AuthResult`, Gym-Controller und die UI-Zustände.
Im Implementierungsteil müssen die Anpassungen am Auth- und Gym-Controller beschrieben werden, inklusive Token-Refresh, Membership-Prüfung und Reset-Mechanik.
UI-Anpassungen sind hervorzuheben, insbesondere neue Lade-, Fehler- und Navigationspfade im Select-Gym-Screen.
Tests decken Unit- und Widget-Szenarien ab, die Membership-Sync, Fehlerfälle und Navigation prüfen.
Abschließend fordert der Prompt explizite Dokumentationspflichten, um Dateibezüge, Hinweise für die Masterarbeit und Nachverfolgung festzuhalten.

# Ziele
1. Persistente Gym-Auswahl mit Membership-Validierung und Token-Refresh sicherstellen.
2. Gym-Scoped-State sauber invalidieren, sobald Nutzer*innen zwischen Gyms wechseln.
3. UI- und Testverhalten an den neuen AuthResult- und switchGym-Vertrag anpassen.
4. Relevante Dateien für spätere PR-Nachverfolgung dokumentieren.

# Dateiübersicht
- `lib/core/providers/auth_provider.dart`: Erweiterter `AuthResult`, neue Membership-/Gym-Handling-Logik und `switchGym`-Flow inkl. Token-Refresh und SharedPreferences-Persistenz.
- `lib/core/providers/gym_scoped_resettable.dart`: Controller verwaltet Gym-Scoped-Registrierungen und ermöglicht globales Reset-Signal.
- `lib/features/gym/presentation/screens/select_gym_screen.dart`: UI zeigt Lade-/Fehlerzustände und ruft `switchGym` sicher auf.
- `test/features/auth/auth_provider_test.dart`: Unit-Tests für Membership-Sync, Fehlerpfade und Gym-Scoped-Reset.
- `test/features/auth/auth_provider_widget_test.dart`: Widget-Tests für Login-/Register-Flows, Routing und Fehlerfeedback.
- `test/features/nfc/global_nfc_listener_test.dart`: Stubs passen sich an den neuen Provider-Vertrag an.

# Ergebnis-Bullets
- `AuthResult` trägt jetzt Flags `requiresGymSelection` und `missingMembership`, womit Login- und Registrierungs-Flows sauber zwischen Follow-up-Actions unterscheiden können. (Siehe `lib/core/providers/auth_provider.dart`)
- `AuthProvider.switchGym` validiert, prüft Membership per `MembershipService`, setzt das aktive Gym im Profil, refresht ID-Tokens, persistiert via SharedPreferences und resettet registered Gym-Scoped-State. (Siehe `lib/core/providers/auth_provider.dart`)
- `GymScopedStateController` ermöglicht allen abhängigen Providern, sich neu zu initialisieren, sobald ein anderes Gym gewählt wird. (Siehe `lib/core/providers/gym_scoped_resettable.dart`)
- Select-Gym-UI deckt Invalid-Gym-, Missing-Membership- und Membership-Sync-Errors ab und navigiert nach erfolgreichem Claim weiter. (Siehe `lib/features/gym/presentation/screens/select_gym_screen.dart`)
- Tests decken neue Erfolgs-/Fehlerpfade, UI-Navigation und State-Resets ab; Widget-Tests kontrollieren Navigation zu Home/SelectGym abhängig von `AuthResult`. (Siehe `test/features/auth/auth_provider_test.dart`, `test/features/auth/auth_provider_widget_test.dart`)

# Hinweise für die Masterarbeit
- Für Gamification-Metriken (XP-Verteilung, Leaderboards) sicherstellen, dass `AuthProvider.switchGym` aufgerufen wird, sobald Nutzer*innen Gyms wechseln, weil damit Membership-Claims und Token-Claims synchronisiert werden.
- Beim Nachvollziehen historischer Bugs: siehe die oben gelisteten Dateien; sie bilden die Grundlage für spätere Gamification-Features wie gym-spezifische Challenges.
- Für UI-Studien: Select-Gym-Screen dokumentiert konkrete Fehlermeldungen (`invalid_gym_code`, `membership_sync_failed`, `missing_membership`). Diese Strings sollten in User-Tests beobachtet werden.
