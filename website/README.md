# Tap'em Web (Marketing, Portal & Admin)

Next.js 14 (App Router, TypeScript, Tailwind) liefert drei klar getrennte Segmente:

a) eine öffentliche Marketing-Landingpage (SEO),
b) ein geschütztes Studio-Portal für Betreiber:innen,
c) ein internes Admin-Monitoring.

Die Segmentierung erfolgt hostbasiert und funktioniert in Preview sowie lokal ohne zusätzliche Services.

## Hosts & Routing

| Host (Preview)                  | Zweck                     | Lokale Entwicklung              | Status |
| ------------------------------ | ------------------------- | -------------------------------- | ------ |
| `tapem.vercel.app`             | Marketing/Landing          | `http://localhost:3000`          | öffentlich, index/follow |
| `portal-tapem.vercel.app`      | Studio-Portal              | `http://portal.localhost:3000`   | Login & Betreiberrollen |
| `admin-tapem.vercel.app`       | Admin-Monitoring           | `http://admin.localhost:3000`    | nur Admin-Rolle |

> **Hinweis:** `*.localhost` verweist automatisch auf `127.0.0.1`. Keine Hosts-Datei nötig.

## Entwicklung starten

```bash
cd website
npm install
npm run dev
```

- Marketing: `http://localhost:3000`
- Portal: `http://portal.localhost:3000`
- Admin: `http://admin.localhost:3000`

Für Produktions-Builds:

```bash
npm run build
npm start
```

## Umgebungskonfiguration

`.env.example` enthält optionale Host-Overrides für lokale Tests:

```
NEXT_PUBLIC_MARKETING_HOST=localhost:3000
NEXT_PUBLIC_PORTAL_HOST=portal.localhost:3000
NEXT_PUBLIC_ADMIN_HOST=admin.localhost:3000
```

Weitere Firebase-Platzhalter und serverseitige Variablen sind in `.env.example` dokumentiert.

## Firebase Web-Integration

### Environment Variablen

| Typ | Schlüssel | Beschreibung |
| --- | -------- | ------------- |
| Client | `NEXT_PUBLIC_FIREBASE_API_KEY` | API-Key des Web-Clients |
| Client | `NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN` | Auth-Domain aus der Firebase-Konsole |
| Client | `NEXT_PUBLIC_FIREBASE_PROJECT_ID` | Projekt-ID |
| Client | `NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET` | Storage-Bucket (für optionale Uploads) |
| Client | `NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID` | Messaging Sender ID |
| Client | `NEXT_PUBLIC_FIREBASE_APP_ID` | App-ID |
| Server | `FIREBASE_PROJECT_ID` | Projekt-ID für das Admin SDK |
| Server | `FIREBASE_CLIENT_EMAIL` | Dienstkonto-E-Mail |
| Server | `FIREBASE_PRIVATE_KEY` | Private Key mit `\n`-Escapes (z. B. `"-----BEGIN...\n...END-----"`) |

Server-Variablen dürfen **nicht** mit `NEXT_PUBLIC_` beginnen, damit sie nicht im Browser landen.

### Autorisierte Domains

- `tapem.vercel.app` (Marketing)
- `portal-tapem.vercel.app` (Portal)
- `admin-tapem.vercel.app` (Admin)
- Lokal: `localhost`, `portal.localhost`, `admin.localhost`

### Session-Handling & Endpunkte

1. Admin-Login läuft clientseitig via Firebase Auth (E-Mail/Passwort).
2. Das ID-Token wird an `POST /api/admin/session` gesendet; der Endpoint setzt ein `__Secure-tapem-admin-session` Cookie (HTTP-only, SameSite=Lax).
3. `GET /admin/logout` oder `DELETE /api/admin/session` widerrufen die Session und leiten auf die Marketing-Startseite.
4. In Preview/Development bleibt der Dev-Stub (`/api/dev/login`) aktiv; Production akzeptiert ausschließlich echte Sessions.

### Guards & Middleware

- `middleware.ts` unterscheidet Marketing/Portal/Admin-Hosts und prüft Session-Cookies.
- `requireRole` validiert im Server-Kontext das Session-Cookie via Firebase Admin SDK.
- Alle Admin-Routen sind `noindex` und liefern `robots: disallow`.

### Security Rules (Firestore)

- Grundlage ist `firestore.rules` im Repository (Multi-Tenant-Setup für Gyms).
- Zugriff erfolgt nur mit `request.auth` und passender `gymId` oder Admin-Rolle.
- Global-Admins (`role == 'admin'`) erhalten Lesezugriff auf aggregierte Daten, Portal-Nutzer:innen bleiben auf ihr Gym beschränkt.

### Lokal & Produktion testen

```bash
cd website
npm install
npm run dev
# Marketing: http://localhost:3000
# Portal:   http://portal.localhost:3000
# Admin:    http://admin.localhost:3000
```

- Admin-Login mit Firebase-Benutzer (Rolle `admin`) durchführen.
- Logout via `/admin/logout` – Session-Cookie wird entfernt.
- Produktion: `npm run build` und `vercel --prod`; Session muss auf `tapem.vercel.app` gesetzt werden.

## Navigation & Rollen

| Segment     | Wichtige Routen                               | Zugriff           |
| ----------- | ---------------------------------------------- | ----------------- |
| Marketing   | `/`, `/imprint`, `/privacy`                    | öffentlich |
| Portal      | `/login`, `/gym`, `/gym/*`                     | Rollen `owner`, `operator`, `admin` |
| Admin       | `/admin`                                      | Rolle `admin` |

- Marketing verlinkt ausschließlich interne Abschnitte + CTA „Für Studios: Login“ (absolute Portal-URL).
- Portal zeigt eine eigene Navigation (Dashboard, Mitglieder, Challenges, Rangliste) – keine Admin-Links.
- Admin bleibt unverlinkt und wird nur direkt aufgerufen.

## Auth & Dev-Toolbar

- Dev-Login (`/api/dev/login`) ist ausschließlich in Development/Preview aktiv und scoped Cookies pro Host (Portal ↔︎ Admin getrennt).
- Guarding: Middleware + SSR stellen sicher, dass jeder Host nur seine Routen akzeptiert. Portal leitet Unangemeldete auf `/login?next=…`, Admin liefert 403/404 bei fehlender Rolle.
- Die Dev-Toolbar erscheint nur außerhalb von Production und erlaubt schnelles Umschalten der Rollen.

> Für echte Produktion sollten Rate-Limits, CSRF-Tokens und eine persistente Session-Strategie ergänzt werden.

## SEO, Robots & Sitemaps

- Marketing liefert eine vollständige Sitemap sowie `robots.txt` mit `allow` für Landing und `disallow` für geschützte Pfade.
- Portal & Admin antworten mit `noindex/nofollow` (X-Robots + Robots-Route) und geben keine Sitemap zurück.
- `metadataBase`, Canonicals und OG/Twitter-Daten werden dynamisch anhand des aktiven Hosts gesetzt.

## typedRoutes & Login-Whitelist

- Alle internen Links basieren auf `src/lib/routes.ts` (marketing-, portal- und admin-spezifische Konstanten).
- `ALLOWED_AFTER_LOGIN` definiert zulässige Redirect-Ziele (`/login?next=`). Unbekannte Ziele fallen auf `/gym` zurück.

## Assets

Mockups bleiben lokal unter `public/images/` (keine Binärdateien im Repo). Die Landingpage prüft wie bisher, ob entsprechende Dateien existieren und blendet ansonsten Platzhalter ein.

## Tests & Builds

- `npm run build` muss fehlerfrei durchlaufen.
- Manuelle Checks: je Host `/` aufrufen, Portal-Login-Flow (`/login → /gym`), Admin-Zugriff ohne/mit Rolle, Marketing-Host mit falschen Pfaden (Redirects/404) prüfen.

## Vercel Deployment

1. **Preview & Production (vercel.app-Subdomains)**
   - Im bestehenden Projekt unter **Domains** zusätzlich `portal-tapem.vercel.app` und `admin-tapem.vercel.app` hinzufügen.
   - Beide Domains auf Production routen lassen (Preview-Umgebung erbt automatisch).
   - Marketing bleibt auf der ursprünglichen `tapem.vercel.app`-Domain.

2. **Später mit Custom Domain**
   - Domain `tapem.app` registrieren.
   - In Vercel `tapem.app`, `portal.tapem.app`, `admin.tapem.app` eintragen und verifizieren.
   - Entsprechende DNS-Einträge (CNAME/ALIAS) für alle drei Hosts setzen.
   - Keine Codeänderung nötig – das Host-Mapping greift automatisch.

3. **Optionale Zukunft**
   - Bei Bedarf kann die App in mehrere Vercel-Projekte aufgeteilt werden (Marketing/Portal/Admin). Die Host-Logik bleibt kompatibel; lediglich Deploy-Ziele ändern sich.

## Sicherheit & Ausblick

- Keine Secrets im Repository; produktive Variablen über das Vercel-Dashboard pflegen.
- Für eine produktive Auth sollten Ratenbegrenzung, CSRF-Schutz und persistente Sessions ergänzt werden.
- Firebase/Firestore-Anbindung bleibt wie bisher geplant (Mock-Daten dienen als Platzhalter).

