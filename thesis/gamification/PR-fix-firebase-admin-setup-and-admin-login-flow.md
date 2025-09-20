# PR: Fix Firebase Admin Setup & Admin Login Flow

## Ziel & Kontext
- Health-Check und Firebase Admin waren nicht funktionsfähig (`GET /api/_health/firebase-admin` 404, "Firebase ist noch nicht konfiguriert").
- Admin-Login scheiterte, Session-Cookies wurden nicht gesetzt, Dashboard-Anfragen liefen ins Leere.
- Firestore-Aggregate schlugen mit `FAILED_PRECONDITION` fehl – fehlende Indizes mussten dokumentiert und abgefedert werden.
- Theme-Color-Warnings von Next.js sowie Emulator-Support und konsistente Konfiguration waren offen.

## Verwendeter Prompt (vollständig)
Ziel (kurz):
Bringe die Next.js-Website lokal zum Laufen mit echter Firebase-Anbindung:

Firebase Admin SDK initialisieren (prod + Emulator-Support),

Health-Check-Route bereitstellen,

korrekten Login-Flow (Firebase Auth Web → Session-Cookie) implementieren,

Admin-Seiten mit echten Firestore-Daten füttern,

Fehler aus den Logs (u.a. 404 Health-Check, „Firebase Admin nicht konfiguriert“, FAILED_PRECONDITION bei Aggregates) beheben,

Index-Handling & Fallbacks sauber lösen,

Theme-Color-Warnings aus Next.js beseitigen.
Ergebnis: Auf localhost:3000 kann ich „Für Studios: Login“ nutzen, mich als Admin anmelden und im /admin-Bereich Live-Daten aus Firestore sehen.

0) Kontext / Symptome / Hinweise

Beim Klick auf „Für Studios: Login“ erscheint „Firebase ist noch nicht konfiguriert“. Beim Versuch, sich mit einem Admin-Account einzuloggen, erscheint derselbe Hinweis erneut.

Der Header-Schalter „Nur Vorschau → Rolle: admin“ zeigt die Admin-Page, dort laden Kennzahlen aber teilweise nicht.

Logs zeigen u.a.:

GET /api/_health/firebase-admin 404 (Health-Check-Route fehlt/ist falsch verdrahtet).

Mehrfach 9 FAILED_PRECONDITION bei Query/AggregateQuery → sehr wahrscheinlich fehlende Firestore-Indizes für verwendete (ggf. kombinierte) Filter/Sortierungen; bitte Link/Fehler aufbereiten und Build-Status behandeln.

Warnings: „Unsupported metadata themeColor … move it to viewport export“.

Die Flutter-App ist mit demselben Firebase-Projekt verbunden und funktioniert → nutze deren Konfiguration als Quelle der Wahrheit (Projekt-ID, Collections, Rollenmodell).

1) Gewünschte Architektur / Verhalten
1.1 Firebase Admin Bootstrap (Server-only)

Erstelle/vereinheitliche ein Modul src/server/firebase/admin.ts mit:

Singleton-Init des Firebase Admin SDK (firebase-admin), niemals doppelt initialisieren.

Konfig-Quellen (prod & lokal):

Primär: Service-Account über ENV (keine Secrets committen!).

FIREBASE_PROJECT_ID

FIREBASE_CLIENT_EMAIL

FIREBASE_PRIVATE_KEY (achte auf \n → echte Zeilenumbrüche: .replace(/\\n/g, '\n'))

Optional: GOOGLE_APPLICATION_CREDENTIALS (Pfad zur JSON) – nur lokal/doc.

Emulator-Support: Wenn USE_FIREBASE_EMULATOR=true, verbinde Admin mit FIRESTORE_EMULATOR_HOST und FIREBASE_AUTH_EMULATOR_HOST.

Hilfsfunktionen:

assertFirebaseAdminReady() → wirft saubere Dev-Fehler mit Hinweis, welche ENV fehlt.

getFirebaseAdminConfigSummary() → { projectId, mode: 'emulator'|'production', usesServiceAccount: boolean }.

Exportiere adminApp und firestore = admin.firestore(); verwende immer admin.firestore() statt direktem @google-cloud/firestore im Code.

1.2 Health-Check Route

Implementiere app/api/health/firebase-admin/route.ts (nicht mit Unterstrich, Runtime NodeJS):

export const runtime = 'nodejs', export const dynamic='force-dynamic', revalidate = 0.

GET() ruft assertFirebaseAdminReady(), gibt JSON mit ok, projectId, mode, usesServiceAccount.

Setze Cache-Control: no-store.

Entferne jegliche metadata-Exporte in API-Routen (fixe damit die Theme-Color-Warnings).

Passe die UI an, dass der Health-Check auf /api/health/firebase-admin prüft.

1.3 Login-Flow (Firebase Auth Web → Session-Cookie)

Client: Verwende Firebase Web SDK (nur Public-Keys aus ENV NEXT_PUBLIC_*).

Server: Implementiere Endpunkte

POST /api/auth/login: erwartet idToken vom Client, prüft via Admin verifyIdToken, erstellt Session-Cookie (admin.auth().createSessionCookie) mit geeigneten Expire-Einstellungen (z.B. 7 Tage), setzt HTTP-only, Secure (nur bei HTTPS), SameSite=Lax. Antwort 204.

POST /api/auth/logout: löscht Cookie, optional admin.auth().revokeRefreshTokens(uid).

Optional GET /api/auth/me: gibt minimales Profil / Rollen zurück.

Rollenprüfung: Nutze dein vorhandenes Rollenmodell (wie in der Flutter-App). Prüfe entweder:

Liste erlaubter Admin-E-Mails via ENV (ADMIN_ALLOWED_EMAILS) oder

Rollenfeld in Firestore (users/{uid}.role in ['admin','owner']).

Implementiere isAdmin(uid) Helper im Server, nutze diesen im Middleware-Gate & auf dem Server.

Middleware: in src/middleware.ts (App-Router):

Schütze /admin (und Unterpfade). Wenn kein gültiges Session-Cookie → Redirect /admin/login.

In DEV kann ein Feature-Flag (DEV_PREVIEW_ROLE_SWITCHES=true) die bisherigen „Nur Vorschau“-Rollenschalter behalten; im Prod sind sie deaktiviert.

1.4 Server-Datenzugriff vereinheitlichen

Alle Serverqueries auf admin.firestore() umstellen (keine gemischte Nutzung von @google-cloud/firestore).

Stelle sicher, dass alle RSC/Server-Actions/Server-Utils im Node runtime laufen – niemals im Edge-Runtime.

Aggregate-/Count-Fallback:

Wenn AggregateQuery.get() mit Code 9 FAILED_PRECONDITION fehlschlägt, fange ab und prüfe, ob es sich um „Index erforderlich“ handelt.

Extrahiere ggf. vorhandenen Index-Link aus der Fehlermeldung und logge ihn sauber (sowie im Admin-UI Hinweis „Index wird gebaut…“).

Fallback: einfache query.get() und snapshot.size (limitieren, wenn nötig), damit das Dashboard nicht bricht, solange Indizes gebaut werden.

Queries & Indizes:

Lege/aktualisiere firestore.indexes.json mit den konkret verwendeten Kombis (Sammlungen/Filter/OrderBy), die im Admin-Bereich genutzt werden (KPIs, Event-Logs, Activity-Aggregates).

Dokumentiere im README, wie Indizes per Firebase CLI deployt werden.

Collections/Schema: Richte dich nach der Flutter-App (gleiches Project, gleiche Collections). Falls Namen abweichen, gleiche die Website darauf an (nicht die Flutter-App).

1.5 Next.js Meta-Warnings fixen

Entferne themeColor aus export const metadata. Verwende stattdessen export const viewport = { themeColor: ... } in Layouts/Pages (/, /admin, /admin/login).

Stelle sicher, dass API-Routen keine metadata exportieren.

1.6 DX / Config / Doku

.env.example auffrischen (keine Secrets):

Client: NEXT_PUBLIC_FIREBASE_API_KEY, NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN, NEXT_PUBLIC_FIREBASE_PROJECT_ID, NEXT_PUBLIC_FIREBASE_APP_ID, NEXT_PUBLIC_FIREBASE_MEASUREMENT_ID

Server: FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, FIREBASE_PRIVATE_KEY

Optional: USE_FIREBASE_EMULATOR, FIRESTORE_EMULATOR_HOST=localhost:8080, FIREBASE_AUTH_EMULATOR_HOST=localhost:9099

Optional: ADMIN_ALLOWED_EMAILS=admin1@test.de,admin2@...

DEV_PREVIEW_ROLE_SWITCHES=false (default)

README Schritt-für-Schritt (kurz & präzise):

.env ausfüllen (Hinweis auf \n im Private Key).

Optional Emulator starten (firebase emulators:start).

pnpm i && pnpm dev (oder npm/yarn, wie im Repo Standard ist).

Health-Check: curl http://localhost:3000/api/health/firebase-admin → { ok: true, ... }.

Client-Login (Firebase Web) → Session-Cookie → Redirect /admin.

Indizes deployen (Befehl angeben).

Scripts in package.json:

"dev:emulator" (setzt Emulator-ENVs & startet Dev),

"health:admin" (curl auf Health-Check und hübsch ausgeben).

2) Änderungen am Code (konkret)

WICHTIG: Keine Secrets committen. Keine neuen externen Services. Behalte die bestehende Logik, wo möglich – nur reparieren/vereinheitlichen.

Firebase Admin Bootstrap
Datei: src/server/firebase/admin.ts

Implementiere sicheren Singleton-Init inkl. ENV-Parsing, Emulator-Support, assertFirebaseAdminReady, getFirebaseAdminConfigSummary.

Exportiere getFirebaseAdminApp(), firestore, auth.

Health-Check Route
Datei: app/api/health/firebase-admin/route.ts

Implementiere GET() wie beschrieben.

Setze runtime='nodejs', dynamic='force-dynamic', revalidate=0, Cache-Control: no-store.

Auth Endpoints
Dateien:

app/api/auth/login/route.ts (POST)

app/api/auth/logout/route.ts (POST)

optional app/api/auth/me/route.ts (GET)

Implementiere Session-Cookie-Logik mit Admin SDK. Timeout/Name der Cookies als Konstanten in src/server/auth/cookies.ts.

Middleware Gate
Datei: src/middleware.ts

Prüfe Session-Cookie auf /admin(.*).

Bei ungültig → Redirect /admin/login.

DEV-Feature-Flag für Vorschau-Rollenschalter.

Admin-Dashboard Daten
Dateien: src/server/admin/dashboard-data.ts (und verwandte Utils)

Stelle auf admin.firestore() um.

Implementiere robustes Error-Handling für code=9 FAILED_PRECONDITION inkl. Fallback auf snapshot.size & Hinweistext „Index wird erstellt/benötigt“.

Sammle Query-Kombinationen und ergänze firestore.indexes.json.

UI-Anpassungen
Dateien: app/(admin)/admin/page.tsx, app/(admin)/admin/login/page.tsx, Header-Komponenten

Login-Seite nutzt Firebase Web SDK, holt idToken, POST an /api/auth/login, bei 204 → Redirect /admin.

Health-Check-Badge in Login-Page (optional): zeigt ok/failed von /api/health/firebase-admin.

Entferne/verschiebe themeColor in export const viewport.

„Nur Vorschau“-Rollenschalter hinter DEV-Flag verstecken.

Konfiguration & Indizes

firestore.indexes.json ergänzen (auf Basis der Queries im Admin-Bereich).

.env.example & README aktualisieren.

.gitignore sicherstellen (keine Keys / JSON-Creds).

3) Tests & Manuelle Abnahme
3.1 Smoke-Tests (automatisierbar/minimal)

pnpm health:admin → { ok:true, projectId:..., mode:... }.

Request auf eine einfache Firestore-Collection (z.B. gyms, users) via Server-Utils → keine Exceptions.

3.2 Manuelle Checkliste (lokal)

Landing → „Für Studios: Login“ klicken → keine „Firebase nicht konfiguriert“-Warnung mehr.

E-Mail/Passwort-Login (oder beliebiger aktivierter Provider) → POST /api/auth/login 204, Cookie gesetzt, Redirect /admin.

Admin-Dashboard lädt KPIs; wenn Index fehlt, erscheint ein nicht-blockierender Hinweis mit Link/Info; nach Index-Build verschwinden Hinweise automatisch.

Event-Logs/Analysen laden, keine FAILED_PRECONDITION-Crashes.

Health-Check: GET /api/health/firebase-admin gibt 200 { ok:true }.

Theme-Color-Warnings sind verschwunden.

„Nur Vorschau“-Rollenschalter existieren nur, wenn DEV_PREVIEW_ROLE_SWITCHES=true.

4) Sicherheit & Compliance

Keine Secrets in Git. Nur Platzhalter in .env.example.

Admin-Queries laufen ausschließlich Server-seitig (Node runtime), niemals im Edge/Client.

Cookies: httpOnly, SameSite=Lax, in Prod Secure.

Beachte DSGVO: Keine unnötigen Personendaten in Logs.

5) PR-Meta

PR-Name: codex/fix-firebase-admin-setup-and-admin-login-flow

Labels: bugfix, firebase, auth, admin, nextjs

Changelog (kurz): Admin-Init vereinheitlicht, Health-Check hinzugefügt, Auth-Session-Cookies, Index-Fallbacks, Meta-Warnings behoben, DX verbessert.

6) ⚠️ Pflicht: Gamification-Dokument für die Masterarbeit

Erstelle zusätzlich in diesem PR die Datei:
thesis/gamification/PR-fix-firebase-admin-setup-and-admin-login-flow.md

Mit folgendem Inhalt (Template ausfüllen):

# PR: Fix Firebase Admin Setup & Admin Login Flow

## Ziel & Kontext
- Kurzbeschreibung des Problems (Health-Check 404, „Firebase nicht konfiguriert“, FAILED_PRECONDITION/Indizes, etc.)
- Ziel des PRs (stabile Admin-Verbindung, funktionierender Login, Datenabruf)

## Verwendeter Prompt (vollständig)
<Hier den gesamten Codex-Prompt einfügen>

## Umsetzung (Übersicht)
- Geänderte/Neu angelegte Dateien
- Architekturentscheidungen (Admin Singleton, Session-Cookies, Index-Fallbacks)
- Emulator/Prod-Modi
- Sicherheit (Cookies, Server-only)

## Ergebnis
- Manuelle Checks: <Stichpunkte, Screenshots/Links>
- Offene Punkte/Nacharbeit: <falls vorhanden>

## Lessons Learned
- <kurze Reflexion zur Methode Prompt-Driven Development>

7) Wenn etwas unklar ist

Erschließe fehlende Details aus der Flutter-App im selben Repo (Collections, Rollen, Projekt-ID). Stelle keine Rückfragen im Code – entscheide pragmatisch, dokumentiere Annahmen im PR-Text unter „Offene Punkte“.

Fertig.

## Umsetzung (Übersicht)
- Firebase-Admin-Bootstrap inkl. Emulator-Support vereinheitlicht und Health-Check-Router neu erstellt.
- Neue Auth-Endpunkte (`/api/auth/login`, `/api/auth/logout`, `/api/auth/me`) mit Session-Cookies (SameSite=Lax) implementiert und Middleware angepasst.
- Admin-Dashboard-Abfragen auf `admin.firestore()` umgestellt, Index-Fehler abgefangen und `firestore.indexes.json` erweitert.
- Theme-Color-Handhabung auf `viewport` umgestellt und Dev-Rollenschalter hinter `DEV_PREVIEW_ROLE_SWITCHES`-Flag versteckt.
- DX verbessert (.env.example, README, neue npm-Skripte `dev:emulator` und `health:admin`).

## Ergebnis
- Manuelle Checks: Health-Endpoint reagiert, Session-Cookies werden erstellt/gelöscht, Dashboard zeigt Warnungen bei fehlenden Indizes.
- Offene Punkte/Nacharbeit: Firestore-Indizes müssen in Firebase bereitgestellt werden (siehe README).

## Lessons Learned
- Präzise Prompts helfen, komplexe Infrastruktur-Themen (Auth, Firestore, DX) strukturiert umzusetzen.
