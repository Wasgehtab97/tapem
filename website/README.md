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

> **Hinweis:** `*.localhost` verweist automatisch auf `127.0.0.1`. Keine Hosts-Datei nötig. In Preview/Development stehen die Admin-Routen zusätzlich unter `https://tapem.vercel.app/admin/*` zur Verfügung.

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
| Client | `NEXT_PUBLIC_FIREBASE_MEASUREMENT_ID` | Optionales Measurement ID für Analytics |
| Server | `FIREBASE_SERVICE_ACCOUNT` | Base64-kodiertes Service-Account JSON (bevorzugt) |
| Server | `FIREBASE_PROJECT_ID` | Projekt-ID für lokale Entwicklung (Fallback) |
| Server | `FIREBASE_CLIENT_EMAIL` | Dienstkonto-E-Mail (Fallback) |
| Server | `FIREBASE_PRIVATE_KEY` | Private Key mit `\n`-Escapes (Fallback) |
| Server | `ADMIN_ALLOWLIST` | Kommagetrennte Admin-E-Mails (optional) |

Server-Variablen dürfen **nicht** mit `NEXT_PUBLIC_` beginnen, damit sie nicht im Browser landen.

### Autorisierte Domains

- `tapem.vercel.app` (Marketing)
- `portal-tapem.vercel.app` (Portal)
- `admin-tapem.vercel.app` (Admin)
- Lokal: `localhost`, `portal.localhost`, `admin.localhost`

### Session-Handling & Endpunkte

1. Admin-Login läuft clientseitig via Firebase Auth (E-Mail/Passwort).
2. Das ID-Token wird an `POST /api/admin/auth/session` gesendet; der Endpoint setzt ein `__Secure-tapem-admin-session` Cookie (HTTP-only, SameSite=Lax).
3. `GET /admin/logout` oder `DELETE /api/admin/auth/session` widerrufen die Session und leiten auf die Marketing-Startseite.
4. In Preview/Development bleibt der Dev-Stub (`/api/dev/login`) aktiv; Production akzeptiert ausschließlich echte Sessions.
5. Optional erlaubt `ADMIN_ALLOWLIST` (kommagetrennte E-Mails) den Zugriff ohne gesetzten Custom Claim.

## Admin Login (Firebase)

### Ablauf

1. Nutzer:in meldet sich in `/admin/login` über Firebase Authentication (E-Mail & Passwort) an.
2. Nach erfolgreichem Sign-In wird das ID-Token an `POST /api/admin/auth/session` geschickt.
3. Der Server erstellt ein signiertes, HTTP-only Session-Cookie (`__Secure-tapem-admin-session`).
4. Geschützte Admin-Routen verifizieren dieses Cookie serverseitig (Firebase Admin SDK + Allowlist) und verweigern Zugriff ohne Admin-Rolle.
5. `DELETE /api/admin/auth/session` oder der Aufruf von `/admin/logout` löscht die Session und widerruft Refresh-Tokens.

### Akzeptanztests

#### Lokal (`.env.local`)

- `npm install && npm run dev`
- `/admin` ohne Login → Redirect zu `/admin/login?next=/admin`
- Anmeldung mit gültigem Firebase-Admin-Account → Cookie wird gesetzt → Redirect `/admin`
- Reload `/admin` → Zugriff bleibt bestehen
- Logout (Button oder `DELETE /api/admin/auth/session`) → Cookie entfernt → `/admin` führt wieder zur Login-Seite

#### Vercel Preview/Production

- Prüfen, dass in Vercel `FIREBASE_SERVICE_ACCOUNT` (Base64) sowie alle `NEXT_PUBLIC_FIREBASE_*` Variablen gesetzt sind
- https://tapem.vercel.app aufrufen → CTA „Für Studios: Login“ → `/admin/login`
- Login wie oben → `/admin` sichtbar; Seitenquelltext / Header zeigen `noindex`
- Benutzer ohne Admin-Claim/Allowlist → 403-Seite
- Dashboard lädt KPIs/Events/Chart ohne Crash (leere Zustände zulässig)

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

- Marketing verlinkt ausschließlich interne Abschnitte + CTA „Für Studios: Login“ (führt auf `/admin/login`).
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

## Typed Routes – Richtlinien

### Kanonische Quelle

- Alle Pfade werden zentral in `src/lib/routes.ts` gepflegt. Jede Route ist ein Objekt mit `href` (Pfad) und `site` (Marketing, Portal, Admin).
- Verwende ausschließlich die exportierten Konstanten (`MARKETING_ROUTES`, `PORTAL_ROUTES`, `ADMIN_ROUTES`). Der Zugriff auf `href` stellt sicher, dass Next.js typedRoutes keine Fehler meldet.
- Host-Awareness: `route.site` signalisiert, auf welchem Host der Pfad erreichbar ist. Für Cross-Host-Links (`buildSiteUrl`) immer die passende Route verwenden.

### Navigation & Router

- Beispiel `<Link>`: `href={PORTAL_ROUTES.gym.href}`. Für optionale Query-Parameter ein `UrlObject` nutzen (`{ pathname: PORTAL_ROUTES.gym.href, query: { ... } }`).
- Beispiel `router.push`: `router.push(PORTAL_ROUTES.gymMembers.href)` oder `router.replace({ pathname: ADMIN_ROUTES.dashboard.href, query: { filter: 'active' } });`.
- Menü-Definitionen sollten die komplette Route (`{ route: PORTAL_ROUTES.gym, label: 'Dashboard' }`) speichern, damit Site-Informationen verfügbar bleiben.

### Safe Redirects

- `safeNextPath` validiert externe Eingaben (`?next=`) strikt gegen eine Allowlist und liefert immer einen erlaubten Pfad zurück.
- `safeAfterLoginRoute` kapselt die Standard-Allowlist für Portal/Admin nach der Anmeldung und fällt auf `DEFAULT_AFTER_LOGIN` (Portal `/gym`) zurück.
- Für serverseitige Guards steht zusätzlich `isAfterLoginRoute` zur Verfügung, um Header/Query-Werte schnell zu prüfen.

### Neue Routen hinzufügen

1. In `src/lib/routes.ts` mit `defineRoute('portal', '/neuer-pfad')` (oder entsprechender Site) ergänzen.
2. Falls die Route geschützt ist, in die passenden Sets aufnehmen (`PORTAL_PROTECTED_PATHS`, `AFTER_LOGIN_ROUTES` etc.).
3. Navigationsdaten, Middleware und eventuell `safeNextPath`/`safeAfterLoginRoute` erweitern.
4. Bei dynamischen Segmenten ein Helper in `routes.ts` hinzufügen, der ein typisiertes `UrlObject` zurückliefert (z. B. `portalMemberDetailsRoute(memberId)` mit `{ pathname, query }`).

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

