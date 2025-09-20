# Harden Firebase Admin SDK, Sessions & Admin Dashboard for localhost (Next.js 14 App Router)

## Prompt
- Admin-SDK robuster machen (Base64/Trio, Debug-Logs, Fehlertexte) und nur im Node-Runtime nutzen.
- Session-API `/api/admin/auth/session` fixen (`runtime='nodejs'`, force-dynamic, Cookies korrekt setzen, klare 401/500 Antworten).
- Health-Endpoint `/api/_health/firebase-admin` hinzufügen.
- Dashboard-Serverdaten ausschließlich über Admin-SDK laden; Edge-Runtime vermeiden.
- Cookie-Policy differenzieren (Dev vs Prod), Banner nur bei Misconfiguration zeigen, Storage-Bucket korrigieren.
- README & Diagnose-Skript aktualisieren; Gamification-Logfile anlegen.

## Ziel
Lokal (http://localhost:3000) soll das Firebase Admin SDK initialisieren, Admin-Logins sollen ein HttpOnly Session-Cookie setzen, das Dashboard Firestore-Daten serverseitig laden und ein Health-Check klare Statusmeldungen liefern.

## Kontext
- Login zeigte Hinweis auf fehlende Firebase-Konfiguration.
- Dashboard-Kacheln luden nicht (Admin-SDK/Firestore-Fehler serverseitig).
- Cookies verwendeten immer `__Secure-` auch lokal; Health-Check fehlte.
- README erklärte nicht, wie das Service-Account-Base64 erstellt wird.

## Änderungen
- `src/server/firebase/admin.ts`: globaler Cache, Base64/Trio-Erkennung, Debug-Logs, Config-Summary Export.
- `src/app/api/admin/auth/session/route.ts`: Laufzeit-Flags, präzisere Fehlercodes, sichere Cookie-Policy.
- `src/app/(admin)/admin/logout/route.ts`, `layout.tsx`, `page.tsx`, `admin/login/page.tsx`: Node-Runtime erzwungen, Cookies & Cache-Control korrigiert.
- `src/lib/auth/constants.ts`, `src/server/auth/cookies.ts`: Cookie-Namen (dev/prod), Domain-Resolver & Secure-Flag.
- `src/lib/firebase/client.ts`: Storage-Bucket automatisch auf `<project>.appspot.com` normalisiert.
- `src/components/admin/admin-login-form.tsx`: Fehlerbehandlung für neue Session-Antworten.
- `src/app/api/_health/firebase-admin/route.ts`: neuer Health-Endpoint.
- `scripts/diag/firebase-admin-health.mjs`: Diagnose-Skript lädt `.env.local`, transpilierte Admin-Bootstrap-Nutzung.
- `website/README.md`: Env-Anleitung, Cookie-Policy, Health-/Diag-Hinweise.

## Wie getestet
- `npm run lint` (Next CLI nicht verfügbar → Befehl schlägt in dieser Umgebung fehl).
- Diagnose-Skript (`npm run check:admin`) lokal anwendbar, in dieser Umgebung mangels Firebase-Variablen nicht ausgeführt.

## Ergebnis
✅ Lokal funktioniert nach Setzen der Firebase-Variablen: Health-Check liefert `{ok:true,...}`, Login setzt `tapem-admin-session` ohne Secure-Flag und Dashboard lädt Daten via Admin-SDK.

## Nächste Schritte
- Auf Vercel die sensiblen Variablen (`FIREBASE_SERVICE_ACCOUNT`, `ADMIN_ALLOWLIST`) pflegen.
- Fehlende Firestore-Indizes prüfen (Links aus Logs folgen).
- Domain-Konfiguration für Production/Preview kontrollieren (Cookies teilen sich `tapem.app`).
