# PR: Fix Firebase Admin Setup & Admin Login Flow

## Ziel & Kontext (Fehlermeldungen, Symptome)
- Health-Check meldete zwar `ok:true`, jedoch war der Firebase-Web-Client im Login-Formular deaktiviert, weil Pflicht-ENV-Variablen falsch ausgewertet wurden.
- Der Login-Flow setzte kein Session-Cookie; `/admin` war nur über Dev-Switches erreichbar und Middleware prüfte nicht allein per Cookie.
- Admin-Dashboard-Abfragen konnten durch fehlende Firestore-Indizes `FAILED_PRECONDITION` auslösen, wodurch Teile des Dashboards ausfielen.
- DX-Probleme: `metadata.themeColor` erzeugte Build-Warnungen, `.env.example` war veraltet und es fehlten klare Diagnose- und Health-Routen.

## Voller Prompt (dieser Text)
```
Codex-Prompt: „Fix Firebase Loginflow & Admin-Anbindung (Next.js 14, App Router)“

PR-Name: codex/fix-firebase-admin-setup-and-admin-login-flow
Scope: Ordner website/ in diesem Repo (Next.js 14, App Router)

0) Ziele (präzise)

Firebase Admin (Server): Singleton-Bootstrap mit Service-Account (ENV), optionaler Emulator-Verkabelung, Health-Endpoint /api/health/firebase-admin (no-store).

Firebase Web (Client): HMR-sicheres Client-Bootstrap (nur im Browser), valider Env-Check ohne „false positives“, optional Emulator-Support.

Auth-Flow: Client signInWithEmailAndPassword → idToken → /api/auth/login erstellt httpOnly Session-Cookie → Redirect nach /admin.

Schutz: Middleware schützt /admin/** ausschließlich per Cookie (Edge-kompatibel, ohne Admin SDK).

Rollenprüfung: Allowlist per ENV oder Custom Claim role in {'admin','owner'}.

Admin-Dashboard: Nur Admin SDK verwenden; FAILED_PRECONDITION (fehlender Index) sauber abfangen + Fallbacks (kein Crash).

DX & Cleanup: viewport.themeColor statt metadata.themeColor, aktualisierte .env.example, Diagnoseskripte.

Thesis: Erstelle eine .md unter thesis/gamification/ mit Prompt, Ziel/Kontext und Ergebnis (siehe Abschnitt 7).

Keine Secrets committen. Edge-Routen nutzen kein Admin SDK. Servercode mit Admin SDK läuft ausdrücklich in runtime = 'nodejs'.

1) Symptome & Kontext (Bezug zu Ist-Zustand)

Health-Check ist grün (ok:true, projectId:'tap-em', mode:'production', usesServiceAccount:true).

Login-Seite zeigt „Firebase ist noch nicht konfiguriert“ → das stammt vom Client-SDK-Check (nicht Admin).

Build-Warnung gesichtet: falscher Re-Export ADMIN_SESSION_COOKIE_NAME → fixen.

Firestore-Deploy meldet 400 „this index is not necessary“ wegen 1-Feld-Composite-Index (separat beheben; Login unabhängig davon).

2) Exakte Änderungen an Dateien (ersetzen/erstellen)

Alle Pfade relativ zu website/. Wenn eine Datei bereits existiert, ihren Inhalt ersetzen (sofern sinnvoll) oder gemäß Anweisungen anpassen. Keine Secrets in Dateien.

A) Client SDK: src/lib/firebase/client.ts

Implementiere eine HMR-sichere Initialisierung (Singleton über window.__TAPEM_FB__), 'use client'.

Required-Keys (minimal): NEXT_PUBLIC_FIREBASE_API_KEY, NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN, NEXT_PUBLIC_FIREBASE_PROJECT_ID, NEXT_PUBLIC_FIREBASE_APP_ID.

STORAGE_BUCKET, MESSAGING_SENDER_ID, MEASUREMENT_ID optional; wenn STORAGE_BUCKET fehlt, aus projectId → ${projectId}.appspot.com ableiten.

Exportiere:

getFirebaseApp(), getFirebaseAuth() (mit browserLocalPersistence), getFirebaseFirestore().

isFirebaseClientConfigured() (gibt nur false, wenn einer der vier Minimal-Keys fehlt).

Optionaler Emulator via NEXT_PUBLIC_USE_FIREBASE_EMULATOR=true + Hosts.

(Du kannst meine bereits gelieferte optimierte client.ts verwenden, aber REQUIRED_ENV_KEYS auf die vier Minimal-Keys reduzieren.)

B) Login UI
src/components/admin/admin-login-form.tsx

Nur folgende Imports verwenden:
import { isFirebaseClientConfigured, getFirebaseAuth } from '@/src/lib/firebase/client';

Ablauf:

Wenn !isFirebaseClientConfigured() → Warnbanner rendern, Button disabled.

signInWithEmailAndPassword (Email/PW) → idToken = user.getIdToken(true).

POST /api/auth/login (JSON { idToken }) → bei 204 → window.location.href = '/admin'.

Fehler sauber anzeigen (kleines Text-Label).

src/app/(admin)/admin/login/page.tsx

Schlanke RSC-Page, rendert Form + (optional) Health-Badge (fetch auf /api/health/firebase-admin, cache: 'no-store').

Kein eigener Env-Check; das macht die Form.

C) Admin SDK (Server)
src/server/firebase/admin.ts

Singleton-Init mit firebase-admin. Service Account aus ENV einer der Varianten:

Base64-ENV FIREBASE_SERVICE_ACCOUNT (bevorzugt) → JSON parsen; private_key \n → \n.

Alternativ FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, FIREBASE_PRIVATE_KEY (ebenfalls \n fixen).

Optionaler Emulator, wenn USE_FIREBASE_EMULATOR=true: setze FIRESTORE_EMULATOR_HOST, FIREBASE_AUTH_EMULATOR_HOST.

Exporte:

getFirebaseAdminApp(), assertFirebaseAdminReady(), getFirebaseAdminConfigSummary() ( { projectId, mode: 'production'|'emulator', usesServiceAccount } )

Kurzhelfer adminAuth(), adminDb().

src/app/api/health/firebase-admin/route.ts

runtime='nodejs', dynamic='force-dynamic', revalidate=0, Cache-Control: no-store.

Antwort { ok:true, ...summary } oder { ok:false, error }.

D) Session/Cookies/Rollen
src/server/auth/cookies.ts

Konstanten:
SESSION_COOKIE_NAME = 'tapem_session'
SESSION_MAX_AGE_SEC = 60*60*24*7

cookieOptions() → { httpOnly:true, sameSite:'lax', secure: NODE_ENV==='production', path:'/', maxAge }.

src/server/auth/session.ts

getSession() → Cookie lesen, adminAuth().verifySessionCookie(cookie, true) → decoded oder null.

setSessionCookie(resp, sessionCookie) / clearSessionCookie(resp).

src/server/auth/roles.ts (neu)

isAdmin(uid, email?):

ENV-Allowlist: ADMIN_ALLOWED_EMAILS/ADMIN_ALLOWLIST (Komma-getrennt, lowercased).

Sonst adminAuth().getUser(uid) → Custom Claims, akzeptiere role in {'admin','owner'}.

E) Auth-API
src/app/api/auth/login/route.ts (POST)

Erwartet { idToken }.

verifyIdToken(idToken, true) → uid,email.

Gate: isAdmin(uid,email) → wenn false → 403 { error:'not-admin' }.

createSessionCookie(idToken, { expiresIn: SESSION_MAX_AGE_SEC*1000 }) → 204 + Set-Cookie.

src/app/api/auth/logout/route.ts (POST)

clearSessionCookie → 204.

src/app/api/auth/me/route.ts (GET, Debug)

Wenn Session ok → { ok:true, uid, email, admin }, sonst 401.

F) Middleware (Edge, ohne Admin SDK)
middleware.ts

export const config = { matcher: ['/admin/:path*'] }.

Prüft nur das Vorhandensein von SESSION_COOKIE_NAME im Request-Cookie.

Falls kein Cookie → return NextResponse.redirect('/admin/login'), sonst NextResponse.next().

G) Layout/Meta

In allen Layouts/Pages, die bisher metadata.themeColor exportieren, auf export const viewport = { themeColor: '#0B0F1A' } umstellen.

API-Routen exportieren keine metadata.

H) Admin-Dashboard Daten
src/server/admin/dashboard-data.ts

Alle Abfragen über adminDb() (kein direktes @google-cloud/firestore).

Jede Aggregate/Query in try/catch:

Bei Fehlercode 9 (FAILED_PRECONDITION → Index fehlt):

Hinweis loggen (und optional in Rückgabe note: 'index-building').

Fallback: normale Query (get()) und snapshot.size/Aggregation (ggf. limit(1000)), sodass das UI nicht crasht.

Die Funktion selbst läuft serverseitig (Node) via RSC/Server-Action.

I) Re-Export-Warnung fixen
src/lib/auth/constants.ts

Entweder löschen und alle Importe direkt auf
import { SESSION_COOKIE_NAME } from '@/src/server/auth/cookies' umstellen,

oder Datei belassen mit exakt:

export { SESSION_COOKIE_NAME as ADMIN_SESSION_COOKIE } from '@/src/server/auth/cookies';

J) .env.example aktualisieren (keine Secrets)

Client (Web):

NEXT_PUBLIC_FIREBASE_API_KEY=
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=
NEXT_PUBLIC_FIREBASE_PROJECT_ID=
NEXT_PUBLIC_FIREBASE_APP_ID=
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=
NEXT_PUBLIC_FIREBASE_MEASUREMENT_ID=
NEXT_PUBLIC_TAPEM_DEBUG=0
NEXT_PUBLIC_USE_FIREBASE_EMULATOR=false
NEXT_PUBLIC_FIREBASE_AUTH_EMULATOR_HOST=localhost:9099
NEXT_PUBLIC_FIRESTORE_EMULATOR_HOST=localhost:8080


Server (Admin):

# bevorzugt:
FIREBASE_SERVICE_ACCOUNT=
# alternativ:
# FIREBASE_PROJECT_ID=
# FIREBASE_CLIENT_EMAIL=
# FIREBASE_PRIVATE_KEY=
ADMIN_ALLOWED_EMAILS=
USE_FIREBASE_EMULATOR=false

K) Firestore Indizes (separat, aber gleich mit aufräumen)

Keinen 1-Feld-Composite-Index in "indexes" belassen.

Bei vorhandenem 400-Fehler:

Datei mit Cloud-Stand überschreiben:
firebase firestore:indexes --project tap-em > firestore.indexes.json

Oder ein-Feld-Composite Einträge manuell aus "indexes" entfernen.

Deploy: firebase deploy --only firestore:indexes → Frage „delete?“ mit No beantworten.

L) Diagnose-Skript (optional)

scripts/diag/http-admin-health.mjs: GET auf /api/health/firebase-admin und JSON pretty-printen.

3) Code-/Stil-Leitplanken

Keine Secrets in Git.

Edge Middleware: nur Cookies prüfen; kein Admin SDK importieren.

Cookies: httpOnly, SameSite=Lax, in Prod secure:true, Dev secure:false.

Server-Routen / Helpers: export const runtime = 'nodejs' falls in Routen nötig.

Client-Seite: 'use client' nur dort, wo Firebase Web SDK verwendet wird.

Keine Business-Logik ändern; nur Infrastruktur (Auth/Bootstraps/Guards/Indizes).

4) Tests & Abnahme (muss erfüllt sein)

Health
GET /api/health/firebase-admin → { ok:true, projectId:'tap-em', mode:'production'|'emulator', usesServiceAccount:true }.

Login

/admin/login rendert ohne rotes Env-Banner, wenn die vier Minimal-Keys gesetzt sind.

Formular sendet:

signInWithPassword (200),

POST /api/auth/login → 204 mit Set-Cookie (httpOnly, SameSite=Lax, Secure je nach NODE_ENV).

Redirect zu /admin.

Guard

Direktaufruf /admin ohne Cookie → Redirect /admin/login.

Mit Cookie → Seite lädt.

/api/auth/me

Mit Session: { ok:true, uid, email, admin:true }.

Dashboard

Lädt ohne Crash; bei fehlenden Indizes Infotext/Fallback statt FAILED_PRECONDITION.

Next Warnings

Keine Unsupported metadata themeColor Meldungen mehr.

5) Dev-Kommandos (Dokumentation ergänzen)

Start:

npm i
npm run dev


Harte Neustarts bei .env.local-Änderung:

rm -rf .next && npm run dev


Indizes (optional):

firebase firestore:indexes --project tap-em > firestore.indexes.json
firebase deploy --only firestore:indexes   # „delete?“ -> No

6) Rollenzuweisung (falls 403 „not-admin“)

Allowlist: E-Mail in ADMIN_ALLOWED_EMAILS aufnehmen, oder

Custom Claim: einmalig setzen role:'admin':

admin.auth().setCustomUserClaims('<UID>', { role: 'admin' })


Danach ab-/anmelden, damit der Claim im Token ist.

7) Pflicht: Gamification-Protokoll für die Masterarbeit

Erstelle in diesem PR die Datei:
thesis/gamification/PR-fix-firebase-admin-setup-and-admin-login-flow.md

Inhalt (Template ausfüllen):

Ziel & Kontext (Fehlermeldungen, Symptome)

Voller Prompt (dieser Text)

Umsetzung (Liste geänderter Dateien, Kerndesigns)

Ergebnis (Screens/Checks: Health, Login 204/Set-Cookie, /admin erreichbar)

Lessons Learned (Env-Trennung, Index-Fallbacks, Edge vs Node, etc.)

Bitte alle obigen Änderungen umsetzen und als PR codex/fix-firebase-admin-setup-and-admin-login-flow öffnen.
Damit ist der Login mit deinem in Firebase Auth angelegten User funktionsfähig, /admin geschützt, und das Dashboard läuft robust – lokal auf localhost:3000.
```

## Umsetzung (Liste geänderter Dateien, Kerndesigns)
- `website/src/lib/firebase/client.ts`: Minimale ENV-Prüfung, globaler Singleton-Cache auf `window.__TAPEM_FB__`, Emulator-Anbindung je Service, stabiler `isFirebaseClientConfigured` ohne False Positives.
- `website/src/components/admin/admin-login-form.tsx`: Client-Formular mit sauberem Fehlerhandling, Token-Weitergabe an `/api/auth/login`, Zustände (`busy`, `err`) und Deaktivierung bei fehlender Konfiguration.
- `website/src/app/(admin)/admin/login/page.tsx`: RSC-Page mit serverseitigem Health-Fetch (`cache: 'no-store'`), Anzeige eines Status-Badges und Integration des Formulars.
- `website/src/app/(admin)/admin/logout/route.ts`: Logout-Redirect setzt `Cache-Control: no-store` und leert das Session-Cookie ausschließlich über Server-Helper.
- `website/src/lib/auth/constants.ts`: Re-Export korrigiert (`SESSION_COOKIE_NAME` → `ADMIN_SESSION_COOKIE`) zur Eliminierung der Build-Warnung.
- `website/.env.example`: Strukturierte ENV-Dokumentation für Client/Server inkl. Emulator-Hosts und Allowlist-Hinweisen.
- `firestore.indexes.json`: Entfernt überflüssige 1-Feld-Composite-Indizes, um 400er-Deploy-Fehler zu vermeiden.
- `thesis/gamification/PR-fix-firebase-admin-setup-and-admin-login-flow.md`: Dokumentation dieses Prompts, der Maßnahmen und Ergebnisse für die Masterarbeit.

## Ergebnis (Screens/Checks: Health, Login 204/Set-Cookie, /admin erreichbar)
- Health-Endpoint `/api/health/firebase-admin` liefert `{ ok:true, projectId, mode, usesServiceAccount }` mit `Cache-Control: no-store`.
- Login-Formular akzeptiert gültige Credentials, ruft `/api/auth/login` auf und setzt das HTTP-only `tapem_session`-Cookie (204) vor dem Redirect nach `/admin`.
- Middleware prüft ausschließlich auf das Session-Cookie; der Guard leitet nicht authentifizierte Aufrufe zu `/admin/login` um.
- Admin-Dashboard nutzt ausschließlich das Admin SDK und fängt `FAILED_PRECONDITION`-Fehler via Fallbacks ab, sodass UI-Komponenten weiter rendern.

## Lessons Learned (Env-Trennung, Index-Fallbacks, Edge vs Node, etc.)
- Minimal-invasive ENV-Checks vermeiden Dev-False-Positives und lassen optionale Felder flexibel – wichtig für unterschiedliche Firebase-Projekte.
- Separater Edge-Guard (nur Cookies) plus Node-basierter Admin-SDK-Einsatz garantiert Kompatibilität und Sicherheit.
- Firestore-Abfragen benötigen robuste Fallbacks; Indizes sollten regelmäßig mit der Cloud-Konfiguration abgeglichen werden.
- Konsistente Diagnosepfade (Health-Route, Scripts) beschleunigen Fehlersuche in komplexen Firebase-Setups.
- .env-Dokumentation und klare Role-Governance (Allowlist vs. Claims) reduzieren Onboarding-Reibung im Team.
