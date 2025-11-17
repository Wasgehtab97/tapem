Du bist ein erfahrener Senior Flutter-/Firebase-Engineer, der in einem bestehenden Projekt (Fitness-App „Tap’em“) arbeitet.

Ziel dieses Prompts:
- Den aktuellen IST-Zustand der Authentifizierung und des Gym-Wechsels (Multi-Tenant) analysieren.
- Einen robusten, best-practice-konformen SOLL-Zustand für Login/Registrierung/Gym-Wechsel definieren.
- Den Code schrittweise so umbauen, dass Auth- und Gym-Wechsel-Flows stabil, vorhersagbar, sicher und UX-seitig klar sind.
- Alle Änderungen transparent dokumentieren, inkl. einer eigenen .md-Datei im Verzeichnis `thesis/gamification/` für meine Masterarbeit.

KONSTRUKTIVE GRUNDSÄTZE:
- Arbeite im bestehenden Repository von Tap’em (Flutter + Firebase).
- Nutze das bestehende Architektur- und Provider-Setup, aber bring Struktur und Robustheit rein.
- Sei vorsichtig mit Breaking Changes – wenn du APIs änderst, passe alle Aufrufer an und ergänze Tests.
- Markiere Annahmen im Code und in Markdown explizit mit „Annahme:“.
- Schreibe Kommentare und neue Doku bevorzugt auf Deutsch in verständlicher Sprache, Code bleibt natürlich auf Englisch.

WICHTIG:
- Fokus dieses Prompts ist AUSSCHLIESSLICH: Auth-Flow + Gym-Wechsel-Flow + dazugehörige States (inkl. activeGymId/Claims).
- Nimm KEINE anderen Features in Angriff (Gamification, Community, usw.), außer dort, wo sie direkt vom Auth- oder Gym-Wechsel-Flow betroffen sind.
- Verändere Firestore-Regeln oder Cloud Functions nur, wenn es für Konsistenz mit dem neuen Flow unbedingt nötig ist – und dokumentiere solche Änderungen extra.
- Lege am Ende eine neue Markdown-Datei unter `thesis/gamification/` an, in der Prompt + Ergebnis dieses „virtuellen PRs“ dokumentiert werden (siehe AUFGABE 5).

------------------------------------------------
AUFGABE 1: Projekt-Scan Auth- & Gym-Wechsel-Flow (IST-Zustand)
------------------------------------------------

1. Verschaffe dir einen Überblick über alle relevanten Stellen im Code, die mit Authentifizierung und Gym-Wechsel zu tun haben. Typische Kandidaten (Beispiele, bitte im Repo verifizieren und erweitern):
   - `lib/core/providers/auth_provider.dart` oder ähnliche Auth-Provider.
   - `lib/features/auth/...` (z. B. Login-/SignUp-Screens, Gym-Code-Flows).
   - `lib/services/membership_service.dart` oder vergleichbare Services für Gym-Mitgliedschaften.
   - Alle Stellen, die `activeGymId`, Gym-Claims oder Gym-Kontexte lesen/schreiben (inkl. SharedPreferences, User-Dokumente, Claims).
   - Bootstrapping/Startup-Logik: `lib/main.dart`, `app_router.dart` und evtl. Splash-/Loading-Screens.
   - Firestore-Regeln und ggf. Cloud Functions, sofern sie direkt vom Gym-Konzept abhängen (z. B. Nutzung von `request.auth.token.gymId`, `activeGymId` oder ähnlichen Claims).

2. Mappe den IST-Flow für:
   - **App-Start** (wenn ein User bereits eingeloggt ist):
     - Woher kommen Auth-State, User-Daten, activeGymId, Claims?
     - In welcher Reihenfolge werden Provider initialisiert?
   - **Login** (bestehender User, existierendes Gym):
     - Welche Daten werden wann geladen?
     - Wo wird activeGymId gesetzt und gespeichert (User-Dokument, Claims, SharedPreferences)?
   - **Registrierung / Konto-Erstellung**:
     - Wie wird ein neuer User einem Gym zugeordnet?
     - Welche Fehlerfälle sind möglich (ungültiger Gym-Code, fehlende Mitgliedschaft, etc.)?
   - **Gym-Wechsel** (User wechselt aktiv das Gym, z. B. anderes Studio):
     - Wo und wie wird die neue Gym-Auswahl gespeichert?
     - Welche Provider/Streams reagieren darauf (oder sollten darauf reagieren)?
   - **Logout**:
     - Welche lokalen States werden zurückgesetzt?
     - Bleiben irgendwo „Zombie“-States übrig (z. B. alte Gym-Daten, alte Streams)?

3. Dokumentiere den IST-Zustand in einer neuen Markdown-Datei:
   - Pfad: `thesis/auth_flow/auth_gym_flow_analysis.md`
   - Strukturvorschlag:
     1. Überblick & Annahmen (z. B. welche Dateien betrachtet wurden, welche Rolle activeGymId spielt).
     2. IST-Flow App-Start
     3. IST-Flow Login
     4. IST-Flow Registrierung
     5. IST-Flow Gym-Wechsel
     6. IST-Flow Logout
     7. Identifizierte Probleme und Risiken
        - Halbe/inkonsistente Zustände
        - Potenzielle Datenleaks zwischen Gyms
        - UX-Probleme (z. B. „App hängt“, unklare Fehlermeldungen)
   - Schreibe in klarer, einfacher deutscher Sprache, sodass auch Nicht-Experten die Kernprobleme verstehen.

------------------------------------------------
AUFGABE 2: Zielbild – Best-Practice SOLL-Zustand für Auth & Gym-Wechsel
------------------------------------------------

Definiere anschließend ein SOLL-Zielbild, wie der Auth- und Gym-Wechsel-Flow in Tap’em aussehen soll – best practice für eine Multi-Tenant-Fitness-App mit Firebase.

1. Beschreibe in `thesis/auth_flow/auth_gym_flow_analysis.md` (neuer Abschnitt):

   8. SOLL-Zustand: Zielarchitektur Auth- & Gym-Wechsel-Flow

   Unterteile in:
   - 8.1 Prinzipien
     - z. B. „Ein User hat immer genau ein aktives Gym-Kontextobjekt im Client“, „Claims und lokale States dürfen nicht divergieren“, „Gym-Wechsel ist ein klarer, expliziter Flow mit Loading-/Fehlerzuständen“.
   - 8.2 Auth-Flow (App-Start, Login, Registrierung, Logout)
     - Beschreibe, wie ein idealer Flow für Tap’em aussehen soll.
   - 8.3 Gym-Wechsel-Flow
     - Wie wird ein Gym-Wechsel initiiert (UI)?
     - Welche Schritte passieren in welcher Reihenfolge (z. B. lokale State-Reset, Fetch neuer Membership, Claims-Update, Re-Subscribe Streams)?
   - 8.4 Fehler- und Edge-Case-Behandlung
     - z. B. ungültige oder abgelaufene Claims, User ohne gültiges Gym, Netzwerkfehler während Gym-Wechsel, etc.

2. Ergänze ein einfaches, textbasiertes Sequenzdiagramm oder tabellarische Flow-Beschreibung für:
   - App-Start
   - Login
   - Gym-Wechsel
   - Logout

   Beispiel (nur Stil, bitte mit echten Schritten füllen):

   - App-Start:
     1. Flutter-Firebase initialisieren.
     2. Aktiven Firebase-User prüfen.
     3. Lokale `activeGymId` laden.
     4. User-Profil und Membership aus Firestore holen.
     5. Konsistenz zwischen Claims, Profil, lokaler `activeGymId` prüfen.
     6. Bei Inkonsistenz: definierte Recovery-Strategie ausführen (z. B. Logout + klarer Hinweis oder geführter Gym-Auswahl-Dialog).

------------------------------------------------
AUFGABE 3: Konkrete Maßnahmen & Umsetzung im Code
------------------------------------------------

Auf Basis von IST- und SOLL-Analyse sollst du den Code so umbauen, dass Auth- und Gym-Wechsel-Flow stabil, konsistent und nachvollziehbar werden.

1. Entwirf einen „Auth/Gym-Flow-Controller“ bzw. eine zentrale Stelle, an der:
   - Der Auth-Status verwaltet wird (eingeloggt, ausgeloggt, initialisierend, fehlerhaft).
   - Der aktuelle Gym-Kontext gehalten wird (inkl. activeGymId, Membership-Infos).
   - Wechsel-Operationen koordiniert werden (Gym-Wechsel, Logout, Hard-Reset im Fehlerfall).

   Nutze bevorzugt bereits existierende Provider-Strukturen (z. B. `AuthProvider`, `GymProvider`), bringe sie aber in eine klarere Architektur:
   - Eine Stelle, die „die Wahrheit“ über den aktuellen User- und Gym-Status hält.
   - Eindeutige Methoden wie `login(...)`, `logout()`, `switchGym(...)`, `recoverFromInconsistentState(...)`.

2. Stelle sicher, dass folgende Flows robust implementiert sind:

   - **App-Start:**
     - Prüfe, ob ein Firebase-User existiert.
     - Lade zugehörige User-/Membership-Daten und gym-spezifische Settings.
     - Stelle Konsistenz zwischen Claims, Firestore-Profil und lokaler `activeGymId` her.
     - Falls unlösbare Inkonsistenz → definierter Fallback (z. B. Logout, zurück zum Login-Screen mit erklärender Meldung).

   - **Login:**
     - Nach erfolgreichem Firebase-Auth-Login:
       - User-Profil laden oder anlegen.
       - Gym-Mitgliedschaften prüfen.
       - `activeGymId` setzen (inkl. Persistenz in SharedPreferences o. ä.).
       - Claims und lokaler State synchronisieren.
     - UI-seitig: klare Loading-/Error-States bei Netzwerkfehlern, ungültigen Gym-Codes usw.

   - **Registrierung:**
     - Sicherstellen, dass ein neuer User einem Gym sauber zugeordnet wird.
     - Edge-Cases behandeln (Gym existiert nicht mehr, Einladungs-Code abgelaufen, etc.).

   - **Gym-Wechsel:**
     - Explizite Methode, z. B. `switchGym(GymId newGymId)`.
     - Reihenfolge:
       1. UI: Transition in einen klaren Loading-State.
       2. Membership prüfen: Darf der User dieses Gym nutzen?
       3. State-Reset: gym-spezifische Provider/Streams sauber neu initialisieren.
       4. Persistenz: neue `activeGymId` lokal und auf dem Server speichern, ggf. Claims aktualisieren.
       5. UI: Erfolgs-Feedback oder verständlicher Fehler.
     - Konsistente Behandlung von Fehlern (Netzwerk, keine Membership, etc.).

   - **Logout:**
     - Firebase-Logout.
     - Kompletter Reset aller user- und gym-bezogenen Provider.
     - Lokale Persistenz (SharedPreferences etc.) von User-/Gym-Daten löschen.

3. Passe alle Aufrufer im UI an:
   - Screens, die Login, Registrierung, Gym-Auswahl oder Logout anstoßen, sollen die neuen Methoden der zentralen Auth-/Gym-Steuerung nutzen.
   - Ersetze verstreute, direktere Firestore- oder SharedPreferences-Zugriffe durch klar strukturierte Methoden.

4. Füge sinnvolle Logging- und Monitoring-Hooks ein:
   - Kein wildes `print`, sondern strukturierte Logs an zentralen Stellen (z. B. bei Gym-Wechsel, Login-Fehlschlägen).
   - Bereite die Stellen so vor, dass sie später leicht mit Crashlytics/Analytics verknüpft werden können (z. B. TODO-Kommentare mit klaren Tags).

------------------------------------------------
AUFGABE 4: Tests & Qualitätssicherung
------------------------------------------------

1. Ergänze Unit- und/oder Widget-Tests für:
   - Login-Flow (erfolgreich, fehlgeschlagen, Netzwerkfehler).
   - Gym-Wechsel (erfolgreich, User hat keine Membership, Netzwerkfehler).
   - Logout (stellt sicher, dass alle relevanten Provider/States zurückgesetzt werden).

2. Falls es bereits Tests für `AuthProvider`, `GymProvider` oder Membership-Services gibt:
   - Aktualisiere diese, um den neuen Flow abzubilden.
   - Ergänze Tests für bislang ungetestete kritische Pfade.

3. Stelle sicher, dass:
   - `flutter test` sauber durchläuft.
   - `flutter analyze` keine neuen Warnungen oder Fehler produziert (hier ggf. nur im Rahmen der von dir angefassten Dateien aufräumen).

------------------------------------------------
AUFGABE 5: Gamification-/Masterarbeit-Log (.md unter thesis/gamification)
------------------------------------------------

Für meine Masterarbeit muss JEDER deiner „virtuellen PRs“ in einer separaten Markdown-Datei dokumentiert werden.

1. Lege eine neue Datei im Verzeichnis `thesis/gamification/` an, z. B.:
   - `thesis/gamification/PR_auth_gym_flow_stabilization.md`

2. Inhalt dieser Datei:
   - **Titel:** z. B. „Stabilisierung Auth- & Gym-Wechsel-Flow (Dokumentations-PR)“
   - **Kontext:** Kurzbeschreibung des Projekts (Tap’em, Flutter/Firebase, Multi-Tenant, Masterarbeit mit Prompt-Driven Development).
   - **Original-Prompt (Kurzfassung):** Zusammenfassung dieses Prompts in 5–10 Sätzen (kein Vollzitat, aber die Essenz: Analyse IST, Definition SOLL, Umsetzung, Tests).
   - **Ziel des PRs:** Was sollte mit dieser Änderung erreicht werden (robuster Auth- und Gym-Wechsel-Flow, Vermeidung halb-valider Zustände, Grundlage für Security/Market-Readiness).
   - **Geänderte/neu angelegte Dateien:** Liste aller wichtigen betroffenen Dateien (Provider, Services, Screens, Tests, \*.md-Dateien).
   - **Kurzfassung der Ergebnisse:** 5–10 Bullet-Points:
     - Was war vorher problematisch?
     - Wie sieht der neue Flow aus?
     - Welche Risiken wurden reduziert?
     - Welche Tests wurden ergänzt?
   - **Hinweise für die Masterarbeit:** 2–3 Sätze, wie diese Änderung als Beispiel für LLM-gestützte Refaktorierung von kritischen Flows und für „Prompt-Driven Hardening“ verwendet werden kann.

3. Schreibe diese Log-Datei klar und knapp auf Deutsch, so dass sie unabhängig von `auth_gym_flow_analysis.md` verständlich ist, aber ohne alles zu duplizieren.

------------------------------------------------
STIL- UND ARBEITSREGELN
------------------------------------------------

- Schreibe neue/erweiterte Dokumentation in klarer, einfacher deutscher Sprache.
- Achte bei Codeänderungen auf Lesbarkeit und klare Verantwortlichkeiten (Single Responsibility, klare Namen).
- Markiere Annahmen zum Produktverhalten und zu Anforderungen explizit.
- Mache keine unnötigen Groß-Umbauten außerhalb des Auth-/Gym-Kontexts.
- Ziel ist ein PR, der realistisch in einem professionellen Team reviewed und gemerged werden könnte.