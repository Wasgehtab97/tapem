# typedRoutes/Login/Suspense/OG Fix – 2025-09-19

## Prompt
```
Ziel
Mache den Web-Teil des Repos Wasgehtab97/tapem auf Branch a_gpt5 unter website/ so stabil, dass npm run build lokal und vercel --prod in Vercel ohne Fehler laufen. Behebe systematisch alle Probleme rund um Next.js 14 App Router, experimental.typedRoutes, Login/Redirects, useSearchParams() + Suspense sowie die Open-Graph-Bildroute. Erhalte SSR/CSR-Entscheidungen wie vorgesehen, ändere keine Flutter-Bestandteile, keine Binärdateien einchecken. Dokumentiere alles PR-fertig inkl. Thesis-Markdown.

Kontext

Monorepo: Flutter-App (bestehend) + Next.js-Web (unter website/).

Web-Stack: Next.js 14 (App Router, TypeScript), Tailwind, ESLint/Prettier, experimental.typedRoutes: true, SEO-Metadaten, opengraph-image-Route, statische Landing-Page, SSR-Skeletons für /gym (mit Subnav, Overview/Members/Challenges/Leaderboard) und /admin, dev-Auth-Stub (Cookie-basiert) mit Login/Logout-API nur für Preview/Dev, No-Index für geschützte Bereiche.

Bisherige Fehlerbilder beim Build auf Vercel:

typedRoutes-Typfehler bei <Link href="…">, bei Subnav und bei Redirects (router.push(...)).

/login nutzt useSearchParams() → Build-Abbruch wegen fehlender Suspense-Boundary/Prerender-Konflikt.

OG-Bildroute meldete zuvor unzulässige CSS Properties (keine „inline-flex“ etc.).

Anforderung Gamification/Thesis: Pro PR eine .md unter thesis/gamification/ mit Prompt, Ziel, Kontext, Ergebnis, Abweichungen/Nacharbeiten. Keine Binärdateien (Bilder lokal im website/public/images/ vom Nutzer abgelegt; Repo enthält nur Platzhalter/Hinweise).

Aufgaben (bitte exakt und vollständig umsetzen)

typedRoutes-Compliance im gesamten website/-Code sicherstellen

Alle internen Navigationsziele (Navbar, Subnav, Footer, In-Page-Links, Buttons) auf echte App-Routen festziehen, sodass href/Redirect-Ziele mit typedRoutes kompatibel sind.

Interne Links: ausschließlich gültige interne Routen verwenden; Externals nicht über Next-Link.

Redirects/Router-Navigation (z. B. nach Login): nur zulässige interne Ziele; unsichere/unerwartete Werte abfangen (Whitelist/Validierung).

Ziel: keine Typfehler mehr vom Muster „Type 'string' is not assignable to Route“.

Login-Seite /login build-stabil machen

Die Seite nutzt useSearchParams() → stelle sicher, dass sie dynamisch gerendert wird (kein Prerender/SSG-Konflikt) und dass die betroffene Client-Komponente in einer Suspense-Boundary gerendert wird, damit der Build nicht mit der Meldung zu fehlender Suspense scheitert.

Die bestehende dev-Login-API bleibt nur in Preview/Dev nutzbar (Production blockiert); Verhalten beibehalten.

Open-Graph-Bildroute robust halten

Stelle sicher, dass die OG-Bildgenerierung keine unzulässigen CSS-Eigenschaften verwendet (nur erlaubte Werte), sodass die Route während des Builds nicht fehlschlägt.

Laufzeit/Output so beibehalten, dass OG in Production korrekt ausliefert.

SEO/Robots je Umgebung korrekt

Previews/Dev: noindex/nofollow (Seitenweit konsistent; geschützte Bereiche zusätzlich).

Production: Seiten sollen indexierbar sein (ausgenommen die geschützten Bereiche).

Produktionssicherheit der dev-Auth-Stub-Routen

Sicherstellen, dass dev-Login/Logout-APIs in Production deaktiviert sind (z. B. 403), damit keine Test-Auth öffentlich aktiv ist.

Preview/Dev-Verhalten bleibt unverändert (Cookies setzen, Rollenumschaltung/Toolbar).

Konfigurationszustand beibehalten

website/next.config.js ohne output: 'export', SSR bleibt möglich, experimental.typedRoutes aktiv lassen.

tsconfig so belassen, dass Typsicherheit der Routen greift.

Keine zusätzlichen Abhängigkeiten einführen, sofern nicht zwingend nötig.

Keine Binärdateien in den PR

Keine neuen Bilder/PNGs ins Repo. Hinweise belassen, wie der Nutzer die Assets lokal unter website/public/images/ hinterlegt.

Docs aktualisieren (kurz & präzise)

website/README.md (oder Root-README Web-Abschnitt) um einen Abschnitt ergänzen:

„typedRoutes: interne Routen vs. externe Links, Validierung von Redirect-Zielen.“

„CSR-Bailout & Suspense für useSearchParams() auf Seitenebene; dynamisches Rendering.“

„OG-Bild-Route: zulässige CSS-Properties; warum.“

„Preview/Prod Robots-Unterschiede; dev-Auth in Production gesperrt.“

Kurzer Testplan: welche Routen/Flows geprüft wurden.

Thesis-Markdown anlegen (Pflicht)

Datei: thesis/gamification/YYYY-MM-DD_typedroutes_login_suspense_og_fix.md.

Inhalt: Prompt (dieser Text), Ziel, Kontext (Repo/Branch, Ordner), Ergebnis (konkrete Änderungen/Dateiliste, Build-Status), bekannte Abweichungen/Nacharbeiten, Links zu Preview/Prod.

Git & PR

Konventionelle Commits verwenden (feingranular, eindeutig).

PR-Titel: fix(website): make project vercel --prod ready (typedRoutes, login suspense, og)

PR-Checkliste:

npm run build lokal grün, vercel --prod grün.

Keine typedRoutes-Typfehler mehr (Links/Redirects/Subnav/Footer etc.).

/login rendert mit Suspense, dynamisch; kein Prerender-Fehler.

OG-Bild-Route stabil (keine CSS-Verbote).

Previews noindex; Production indexbar; geschützte Bereiche noindex.

dev-Login/Logout in Production deaktiviert.

Keine Flutter-Änderungen, keine Binärdateien.

Thesis-MD vorhanden und ausgefüllt.

Ausschlüsse / Safety

Keine Änderungen an Flutter (lib/, android/, ios/, functions/ etc.).

Keine Secrets in .env committen; nur .env.example mit Platzhaltern pflegen.

Kein Vendor-Lock-In oder CI/CD-Umbau in diesem PR; Fokus rein auf Build-Stabilität und typedRoutes/Suspense/OG-Robustheit.

Erfolgskriterien (DoD)

Build & Deploy grün: npm run build lokal erfolgreich; vercel --prod ohne Fehler.

typedRoutes vollständig eingehalten: keine TypeScript-Fehler bzgl. href/router.push/Subnav/Links.

Login-Seite stabil: keine Meldung zu „missing suspense with csr bailout“; Weiterleitungen nur auf erlaubte interne Ziele.

OG-Bildroute rendert ohne CSS-Fehler.

Doku & Thesis aktualisiert wie beschrieben.

Wichtig für meine Masterarbeit
Lege zwingend die Datei unter thesis/gamification/ an (s. oben) und dokumentiere Prompt, Ziel, Kontext, Ergebnis (inkl. Build-Status/Links). Jede Abweichung bitte knapp begründen.
```

## Ziel
- Build-Stabilität für die Next.js-App mit typedRoutes, validierten Redirects, stabiler Login-Suspense und OG-Bild.

## Kontext
- Repository: Wasgehtab97/tapem (Branch a_gpt5)
- Arbeitsbereich: `website/` (Next.js Web-App)

## Ergebnis
- typedRoutes-Hilfsfunktionen und Login-Whitelist zentralisiert (`src/lib/routes.ts`).
- Login-Formular nutzt Validierung & Suspense, Seite erzwingt dynamisches Rendering.
- Auth-Redirect-Logik säubert Header-Werte, erstellt typedRoutes-konforme Login-Redirects.
- `robots.txt` unterscheidet Preview/Production und schützt `/gym*` & `/admin`.
- README um Build-Hinweise ergänzt (typedRoutes, Suspense, OG, Robots, Testplan).
- OG-Bildroute bestätigt zulässige CSS (`display: 'flex'`).
- Build-Status: `npm run build` scheiterte lokal wegen fehlender Next-Abhängigkeit (`next: not found`, Registry-403 verhindert Neuinstallation).
- Geänderte Dateien: `src/lib/routes.ts`, `src/app/login/login-form.tsx`, `src/app/login/page.tsx`, `src/lib/auth/server.ts`, `src/app/robots.txt.ts`, `website/README.md`, `thesis/gamification/2025-09-19_typedroutes_login_suspense_og_fix.md`.

## Bekannte Abweichungen / Nacharbeiten
- `npm run build` konnte nicht erfolgreich ausgeführt werden: Registry-Zugriff (npm 403) blockiert Installation von `next` & `@types/node`; damit fehlt das Binary.
- `vercel --prod` nicht geprüft (CLI erfordert Auth & Netzwerkzugriff).
- Empfehlung: In einer Netz-gestützten Umgebung erneut `npm install` und `npm run build` bzw. `vercel --prod` durchführen.

## Links zu Preview/Prod
- Preview: n/a (lokale Container-Umgebung ohne Deploy)
- Production: n/a (Deployment nicht ausgelöst)
