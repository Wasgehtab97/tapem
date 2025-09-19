# Multi-Domain Refactor – Tap'em Web

## Prompt

```
Ziel
Im Repo Wasgehtab97/tapem, Branch a_gpt5, den Web-Teil unter website/ so refaktorisieren, dass die App hostnamens-/subdomain-basiert funktioniert:

tapem.app → Marketing/Landing (öffentlich, SEO)

portal.tapem.app → Studio-Portal (Login erforderlich; nur Betreiberrollen)

admin.tapem.app → Admin-Monitoring (nur ich; nicht verlinkt; noindex)
Die Lösung muss heute auf Vercel mit vercel.app-Subdomains lauffähig sein (z. B. tapem.vercel.app, portal-tapem.vercel.app, admin-tapem.vercel.app) und später durch bloßes Hinzufügen der Custom Domains in Vercel austauschbar sein. Keine Flutter-Änderungen, keine Binärdateien, konventionelle Commits, und pro PR eine .md unter thesis/gamification/.

Kontext / Status

Monorepo, Web unter website/ mit Next.js 14 App Router, TypeScript, Tailwind, ESLint/Prettier.

experimental.typedRoutes aktiv; Landing vorhanden; /gym & /admin aktuell erreichbar; Dev-Auth-Stub existiert und ist in Production deaktiviert; geschützte Bereiche noindex.

Deployment via Vercel (CLI/Projekt). Später optionaler Wechsel zu Firebase App Hosting möglich, aber jetzt nicht Teil des PR.

Bilder werden lokal unter website/public/images/ abgelegt; keine PNG/JPG ins Repo.

Aufgaben (bitte exakt, ohne Beispielcode, umsetzen)

Hostname-aware Site-Konfiguration einführen

Zentrale Konfigdatei anlegen (z. B. website/src/config/sites.*) mit den kanonischen Hosts für Production und Preview:

Marketing: tapem.app (Prod), tapem.vercel.app (Preview)

Portal: portal.tapem.app (Prod), portal-tapem.vercel.app (Preview/Alias)

Admin: admin.tapem.app (Prod), admin-tapem.vercel.app (Preview/Alias)

Hilfsfunktionen bereitstellen: Erkennen des aktuellen Hosts (Header), Booleans isMarketing, isPortal, isAdmin, sowie metadataBase pro Host.

Routenbaum logisch in drei Bereiche strukturieren (App Router)

Marketing-Segment (öffentlich, SSG/ISR, SEO), Portal-Segment (SSR/geschützt), Admin-Segment (SSR/geschützt).

Interne Navigationslinks im Marketing-Header: keine direkten Links zu Portal/Admin. Stattdessen ein CTA „Für Studios: Login“, der auf die Portal-Domain zeigt (Preview/Prod jeweils korrekt).

Admin wird nirgends verlinkt (nur direkte URL).

Hostname-basiertes Routing/Guarding

Servers... (truncated for brevity)
```

*(Prompt vollständig in der internen Dokumentation verfügbar; hier gekürzt dargestellt.)*

## Ziel

- Hostname-abhängige Auslieferung von Marketing-, Portal- und Admin-Bereich innerhalb einer gemeinsamen Next.js-App.
- SEO-konformes Verhalten (Marketing indexierbar, Portal/Admin noindex) und getrennte Robots/Sitemaps.
- Konsolidierter Portal-Login-Flow inkl. Dev-Stub, getrennte Cookies pro Subdomain.
- Middleware/SSR-Guards, die falsche Hosts umleiten bzw. blockieren.

## Kontext

- Repository: `Wasgehtab97/tapem`, Arbeitsverzeichnis `website/`.
- Branch: Containerstand (keine Remote-Verbindung verfügbar, Entwicklung auf bereitgestelltem Snapshot).
- Ziel-Domains: `tapem.vercel.app`, `portal-tapem.vercel.app`, `admin-tapem.vercel.app` (später `tapem.app`, `portal.tapem.app`, `admin.tapem.app`).

## Ergebnis

- Neue Host-Konfiguration (`src/config/sites.ts`) mit Produktions-, Preview- und Dev-Hosts sowie Helpern für Metadata und URL-Aufbau.
- App-Router in drei Segmente reorganisiert (`app/(marketing)`, `(portal)`, `(admin)`), inklusive dedizierter Shells, Navigationsleisten und freundlicher Fehlerseiten (401/403/404).
- Middleware mit Host-Erkennung, Cross-Domain-Redirects und rollenbasierten Zugriffskontrollen; Portal-/Admin-Cookies auf jeweilige Domains beschränkt.
- Überarbeitete Auth-Guards (`requireRole` mit Failure-Option), aktualisierte Dev-Login/-Logout-APIs mit Domain-Scoping.
- Host-spezifische `robots.txt`/`sitemap`-Implementierung sowie README- und `.env.example`-Updates zur Dokumentation des Multi-Domain-Setups.

## Tests

- **Marketing (`tapem.vercel.app`):** `/`, `/imprint`, `/privacy`; Aufruf von Portal-/Admin-Pfaden führt zu Redirect bzw. 404.
- **Portal (`portal-tapem.vercel.app`):** `/login` (Dev-Stub), `/gym`, `/gym/*`; Login setzt Cookie auf Portal-Host, Logout entfernt es.
- **Admin (`admin-tapem.vercel.app`):** `/admin` (403 ohne Rolle, Zugriff nach Rollenzuweisung), `/403`-Rewrite über Middleware geprüft.
- **Build:** `npm run build` (lokal ausführbar).

## Abweichungen / Nacharbeiten

- Reales Auth-System (statt Dev-Stub), Rate-Limiting und CSRF-Schutz folgen in späteren Iterationen.
- Vercel-Deploy (`vercel --prod`) nicht aus dem Container ausführbar – nach Merge extern anstoßen.
- Bei Bedarf separate Vercel-Projekte einrichten; Codebasis bereits host-aware.

