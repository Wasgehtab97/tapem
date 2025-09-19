# Firebase Web Admin Login – Implementierung

## Prompt
```
Ziel
Bringe das Monorepo Wasgehtab97/tapem (Branch a_gpt5) in den Zustand, dass:

die Next.js-Website unter /website produktionsreif mit Firebase (Auth + Firestore) verbunden ist (Vercel + Spark-Plan tauglich),

echte Anmeldung für Admins über E-Mail/Passwort funktioniert (kein Dev-Stub in Production),

der Bereich Admin nur mit gültiger Admin-Rolle zugänglich ist und in Aufbau/Struktur der Flutter-Admin-Ansicht ähnelt (KPIs, Logs, Tabellen/Charts),

Marketing/Portal/Admin weiterhin sauber über das Multi-Domain-Refactor (PR2) getrennt sind, inkl. Middleware-Guards und noindex für nicht-öffentliche Bereiche,

jede Änderung vollständig dokumentiert wird (README + Thesis-Markdown).

[...] (gekürzt für Lesbarkeit)
```

## Ziel
Produktionsfähige Firebase-Anbindung für den Admin-Bereich der Next.js-Webapp, inklusive echter Session-Cookies, Middleware-Guards, Firestore-Dashboards und aktualisierter Dokumentation.

## Kontext
- Repository: `Wasgehtab97/tapem`
- Branch: `web/firebase-admin-login`
- Relevante Ordner: `website/src/app`, `website/src/lib`, `website/src/server`, `thesis/gamification`

## Ergebnis
- Firebase Client-Initialisierung (`website/src/lib/firebase/client.ts`) und Admin SDK (`website/src/server/firebase/admin.ts`).
- Neue Auth-API (`/api/admin/session`), Login-/Logout-Routen, aktualisierte Middleware & Guard-Logik.
- Admin-Dashboard konsumiert Live-Daten aus Firestore (`website/src/server/admin/dashboard-data.ts`).
- Dokumentation & `.env.example` erweitert, README um „Firebase Web-Integration“ ergänzt.
- Screenshots: Lokale Generierung aktuell nicht möglich, da `npm install` wegen Registry-Beschränkungen (403) blockiert. Nachbereitungsbedarf: Screenshot von Login & Dashboard nach erfolgreichem Deploy nachreichen.

## Abweichungen / Nacharbeiten
- `npm install` (und damit `npm run build`) scheitert im Container an 403 (Registry-Policy). Tests müssen nach Abklärung mit funktionierender Registry erneut ausgeführt werden.
- Screenshots der Oberfläche stehen noch aus (siehe oben).

## Vergleich „Vibecoding vs. manuell“
- *Vibecoding:* Schnell, aber ohne reale Firebase-Sessions; Admin-Guards nur per Dev-Stub.
- *Manuell (diese Umsetzung):* Session-Cookies via Admin SDK, Firestore-Aggregationen und Middleware-Kontrollen; erfordert sorgfältige ENV-Pflege, bietet aber produktionsreife Sicherheit.
