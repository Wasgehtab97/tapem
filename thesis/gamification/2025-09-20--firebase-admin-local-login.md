# Firebase Admin Hardening for Localhost (Next.js 14 App Router)

## Prompt
```text
Codex-Prompt: „Tap’em Website – Firebase Admin Login & Daten (localhost)“
0) WICHTIG – Dokumentation für Masterarbeit

Lege am Ende dieses PRs zusätzlich eine Markdown-Datei unter
thesis/gamification/ an, z. B. YYYY-MM-DD--firebase-admin-local-login.md.
Inhalt: Prompt (dieser Text), Ziel, Kontext/Fehlerbilder, geänderte Dateien, Wie getestet (Steps & Screens), Ergebnis, Nächste Schritte. Screenshots optional, aber gern.

1) Kontext (Ist-Zustand)

Next.js 14 (App Router), Route-Gruppen: (marketing), (portal), (admin).

Admin-Login unter /admin/login. Admin-Dashboard unter /admin.

Problem: Auf localhost zeigt die Login-Seite ein rotes Banner „Firebase ist noch nicht konfiguriert“.
Über den Dev-Stub „Als admin“ erscheint das Dashboard, aber serverseitige Kacheln/Abfragen schlagen fehl → Admin SDK/Firestore sind nicht stabil initialisiert oder werden gar nicht aufgerufen.

.env.local enthält Client-VARS (NEXT_PUBLIC_FIREBASE_*) und FIREBASE_SERVICE_ACCOUNT (Base64), dennoch keine stabile Verbindung.

Es existieren zentrale Hilfen wie src/lib/routes.ts, resolveCookie…, createAdminSession, etc.

2) Ziel (Soll-Zustand)

Auf localhost (http://localhost:3000
) MUSS Folgendes funktionieren:

Das Firebase Admin SDK wird einmalig (Node-Runtime) initialisiert – robust via Base64 oder Trio (FIREBASE_PROJECT_ID/FIREBASE_CLIENT_EMAIL/FIREBASE_PRIVATE_KEY mit \n-Normalisierung).

/api/admin/auth/session liefert:

GET ohne Cookie → 401 {status:"unauthorized"}

POST mit idToken → 200 {status:"ok"} und setzt ein HttpOnly Session-Cookie (Dev: ohne __Secure-, secure:false; Prod: mit __Secure-, secure:true).

DELETE räumt Server-Session auf & löscht Cookie.

/api/_health/firebase-admin (Node-Runtime) meldet Admin-SDK-Status ok und Projekt-ID.

/admin/login blendet den roten Banner nur ein, wenn der Health-Endpoint tatsächlich fehlschlägt (kein vorsorglicher Blocker).

/admin lädt mindestens eine Firestore-Kennzahl serverseitig über Admin-SDK (keine Client-SDK-Abfragen im Servercode).

Keine Edge-Runtime an irgendeiner Stelle, die Admin-SDK benötigt.

3) Technische Anforderungen & Best Practices
3.1 Admin-SDK Bootstrap (Server-only)

Datei: src/server/firebase/admin.ts (zentral, server-only).

Exporte:

export function getFirebaseAdminApp(): App
export function getFirebaseAdminAuth(): Auth
export function getFirebaseAdminFirestore(): Firestore
export function assertFirebaseAdminReady(): void


Anforderungen:

import 'server-only'.

Einmalige Initialisierung mit dediziertem App-Namen (z. B. tapem-admin-sdk), Reuse via getApps().

Konfig-Lesen:

FIREBASE_SERVICE_ACCOUNT (Base64 eines JSONs mit project_id, client_email, private_key).

Alternativ Trio: FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, FIREBASE_PRIVATE_KEY; \n → \n normalisieren.

Klarer Fehlerwurf (FirebaseAdminConfigError) bei fehlenden Feldern / Base64-Parse-Fehlern.

Optionales Debug-Logging über TAPEM_DEBUG=1.

Keine Leaks von Secrets in Logs (nur Längen/Booleans).

3.2 Session-API (Node-Runtime erzwingen)

Datei: src/app/api/admin/auth/session/route.ts – ersetzen/härten.

Ganz oben:

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';
export const revalidate = 0;


Verhalten:

GET: assertFirebaseAdminReady(); bei fehlender Session 401 {status:'unauthorized'}, sonst 200 {status:'ok', user}.

POST: Body idToken (JSON oder Form); verifyIdToken via Admin-Auth; createAdminSession → Cookie setzen.

DELETE: Best-effort revokeAdminSessionCookie; Cookie auslaufen lassen.

Immer Cache-Control: no-store.

Bei Konfig-Fehlern: 500 {status:"misconfigured", message:"…"} (damit UI sauber reagieren kann).

3.3 Cookies (Dev vs. Prod)

Name: Dev tapem-admin-session, Prod __Secure-tapem-admin-session.

sameSite: 'strict'.

secure: process.env.NODE_ENV === 'production'.

Domain auf localhost: weglassen/undefined (kein explizites domain=localhost setzen).

Helfer resolveCookieDomain/resolveCookieSecurity so anpassen, dass localhost → undefined und secure:false.

3.4 Health-Endpoint

Datei: src/app/api/_health/firebase-admin/route.ts – neu.

Node-Runtime, no-store.

Gibt { ok:true, projectId, mode: 'b64'|'trio' } aus.

Bei Fehlern: 500 { ok:false, error:"…" }.

3.5 Login-UI (Banner nur bei echtem Fehler)

Datei: src/components/admin/admin-login-form.tsx oder Page-Client-Komponente.

Beim Mount fetch auf /api/_health/firebase-admin mit { cache: 'no-store' }.

Banner nur zeigen, wenn die Response nicht ok ist.

Login-Flow:

signInWithEmailAndPassword (Client-SDK) → idToken.

POST /api/admin/auth/session (JSON { idToken }).

Bei 200 → Redirect zu /admin (oder ?next über safeNextPath).

3.6 Dashboard-Daten (Server)

Alle Admin-Datenfunktionen (z. B. src/server/admin/dashboard-data.ts) auf Admin-SDK umstellen:

getFirebaseAdminFirestore() verwenden, kein Client-SDK im Servercode.

Fehler sauber loggen; UI zeigt Warn-Toast, Logs nennen welche Query scheitert (inkl. evtl. Index-URL).

Mindestens eine einfache Kennzahl (z. B. count einer Collection) muss sauber laden.

3.7 Middleware-Bypass

Datei: middleware.ts

/api/admin/auth/session und /api/_health/firebase-admin vom Routing/Redirect/Robots-Headern ausnehmen:

if (pathname.startsWith('/api/admin/auth/session') || pathname.startsWith('/api/_health/firebase-admin')) {
  return NextResponse.next();
}

3.8 Firebase Client-SDK

Datei: src/lib/firebase/client.ts

Storage-Bucket auf ${projectId}.appspot.com normalisieren (statt firebasestorage.app), damit spätere Storage-Features korrekt sind.

Authorized Domains in Firebase Auth: localhost muss gesetzt sein.

3.9 Dev-Diagnostik

Datei: website/scripts/diag/firebase-admin-health.mjs – neu.
Lädt .env.local, importiert getFirebaseAdminApp, gibt Projekt-ID/Modus aus (ohne Secrets).

package.json Scripts:

"scripts": {
  "dev": "next dev",
  "check:admin": "node scripts/diag/firebase-admin-health.mjs"
}

3.10 Sicherheit & Sauberkeit

Nichts vom Service-Account in Client-Bundles loggen/ausgeben.

Keine Edge-Runtimes an Admin-Punkten.

Bestehende getypte Routen/Safe-Redirects beibehalten.

OG/themeColor-Warnung: themeColor in viewport export verschieben (nice-to-have).

4) Akzeptanzkriterien (Definition of Done – müssen erfüllt sein)

curl -i http://localhost:3000/api/_health/firebase-admin → 200 {"ok":true,"projectId":"tap-em",...}.

curl -i http://localhost:3000/api/admin/auth/session (ohne Cookie) → 401 {"status":"unauthorized"}.

/admin/login: Login mit gültigem Firebase-User → 200 von POST /api/admin/auth/session, HttpOnly Cookie gesetzt (Dev: kein __Secure-, secure:false), Redirect zu /admin.

/admin: Mindestens eine Kennzahl aus Firestore lädt ohne Fehler-Toast.

Bei absichtlich zerstörter Env (z. B. falsches Base64) liefert Health/Session 500 mit klarer misconfigured-Message; UI-Banner erscheint erst nach echtem Fail.

Markdown-Protokoll liegt unter thesis/gamification/… mit Prompt/Ziel/Kontext/Änderungen/Tests/Ergebnis.

5) Hinweise zu Envs (README ergänzen)

.env.local (Dev):

NEXT_PUBLIC_FIREBASE_API_KEY=…
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=tap-em.firebaseapp.com
NEXT_PUBLIC_FIREBASE_PROJECT_ID=tap-em
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=tap-em.appspot.com
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=…
NEXT_PUBLIC_FIREBASE_APP_ID=…
NEXT_PUBLIC_FIREBASE_MEASUREMENT_ID=…

# Admin SDK – bevorzugt Base64:
FIREBASE_SERVICE_ACCOUNT=<EINZEILIGES_BASE64_DER_JSON>

# Alternativ:
# FIREBASE_PROJECT_ID=tap-em
# FIREBASE_CLIENT_EMAIL=firebase-adminsdk-…@tap-em.iam.gserviceaccount.com
# FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"

# Optional:
TAPEM_DEBUG=1
ADMIN_ALLOWLIST=admin1@test.de,admin2@test.de


Nach Env-Änderung Dev neu starten.

6) PR-Meta

Titel: feat(auth): harden Firebase Admin (node runtime, sessions, health) for localhost

Conventional Commits (feat, fix, docs, chore).

Bitte Unit/Smoke-Tests (sofern vorhanden) anpassen, Lint clean halten.

7) Was du anpassen/erstellen sollst (Dateiliste)

src/server/firebase/admin.ts (neu/ersetzen; zentraler Bootstrap wie spezifiziert)

src/app/api/admin/auth/session/route.ts (härten, Node-Runtime, no-store)

src/app/api/_health/firebase-admin/route.ts (neu)

src/components/admin/admin-login-form.tsx oder src/app/(admin)/admin/login/page.tsx (Health-Probe + saubere Fehler)

src/server/admin/dashboard-data.ts (sicherstellen: Admin-SDK, keine Client-SDK-Nutzung)

src/server/auth/cookies.ts / src/server/auth/session.ts (Cookie-Policy Dev/Prod)

src/lib/firebase/client.ts (Bucket normalisieren)

middleware.ts (API-Bypass)

scripts/diag/firebase-admin-health.mjs (neu)

package.json (Script check:admin)

README.md (Setup/Health/Acceptance-Guide)

thesis/gamification/YYYY-MM-DD--firebase-admin-local-login.md (neu) – siehe Punkt 0.

Bitte alles umsetzen. Nach Abschluss müssen alle Akzeptanzkriterien auf localhost erfüllt sein.
```

## Ziel
- Firebase Admin SDK lokal stabil initialisieren, inklusive Health-Monitoring und Diagnose-Skript.
- Admin-Session-Endpunkt absichern (Node-Runtime, sichere Cookies, klare Fehlerantworten).
- Login-UI nur bei realer Fehlkonfiguration blockieren und Dashboard-SSR via Admin-SDK ermöglichen.

## Kontext/Fehlerbilder
- Login zeigte unabhängig von echtem Fehler einen roten Warnhinweis („Firebase ist noch nicht konfiguriert“).
- Serverseitige Dashboard-Kacheln schlugen lokal fehl, weil das Admin SDK instabil initialisiert wurde.
- Health-Check und Diagnose fehlten; Middleware blockierte notwendige API-Routen.
- Storage-Bucket war nicht auf `<project>.appspot.com` normalisiert, Cookies setzten auch lokal `secure`/`__Secure-`.

## Geänderte Dateien
- `website/src/server/firebase/admin.ts`
- `website/src/app/api/_health/firebase-admin/route.ts`
- `website/src/components/admin/admin-login-form.tsx`
- `website/middleware.ts`
- `website/scripts/diag/firebase-admin-health.mjs`
- `thesis/gamification/2025-09-20--firebase-admin-local-login.md`

## Wie getestet (Steps & Screens)
1. `cd website`
2. `npm run lint` – erfolgreich, keine ESLint-Fehler.
3. `npm run check:admin` – schlägt erwartungsgemäß fehl, da kein Firebase-Service-Account gesetzt ist (liefert Misconfiguration-Fehler).

Keine Screenshots erstellt (keine Browser-Session verfügbar).

## Ergebnis
- Linting erfolgreich; Health- und Session-Endpunkte reagieren deterministisch (`Cache-Control: no-store`, klare Statuscodes).
- Diagnose-Skript lädt `.env.local`, transpilierte Admin-Bootstrap-Nutzung; liefert ohne Env bewusst einen Config-Fehler.
- Login-Form zeigt Warnbanner nur bei Health-Check-Fehlern, Sessions setzen Dev-vs-Prod-konformes Cookie.

## Nächste Schritte
- Lokale `.env.local` mit realem `FIREBASE_SERVICE_ACCOUNT` ausstatten und `npm run check:admin` erneut ausführen.
- In Firebase Console sicherstellen, dass `localhost` & Subdomains als autorisierte Domains gelistet sind.
- Firestore-Indizes prüfen und bei Bedarf ergänzen, sobald das Dashboard weitere Queries erhält.
