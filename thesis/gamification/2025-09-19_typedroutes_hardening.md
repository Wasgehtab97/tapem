# Typed Routes Hardening – Arbeitsprotokoll

## Prompt

„Typed Routes Hardening (langfristige Lösung)“ – siehe Benutzeranweisung vom aktuellen Arbeitstag.

## Ziel

Das Next.js-Frontend im Ordner `website` so umrüsten, dass alle Navigationspfade zentral typisiert und sicher sind, damit das Experimental-Flag `typedRoutes` störungsfrei bleibt und Deployments ohne falsch konfigurierte Pfade funktionieren.

## Kontext

- Kernmodule: `src/lib/routes.ts`, `middleware.ts`, Navigations-Komponenten (`gym-subnav`, `layout/*`), Login-Flows (`src/components/admin/admin-login-form.tsx`, `src/app/(portal)/login/*`).
- Ergänzend: ESLint-Konfiguration (`website/.eslintrc.json`) und `website/README.md` (Dokumentation der neuen Richtlinien).
- Host-Setup bleibt dreigeteilt (Marketing, Portal, Admin) und nutzt weiterhin `src/config/sites.ts`.

## Ergebnis

### Implementierte Änderungen

- Neue kanonische Routenquelle mit `defineRoute`, Host-Metadaten (`site`), Safe-Redirect-APIs (`safeNextPath`, `safeAfterLoginRoute`) und Guard-Hilfen (`isAppRoute`, `findRouteDefinition`).
- Migration sämtlicher Navigationen auf `route.href`-Konstanten; Login-/Logout-Flows verwenden ausschließlich die Safe-Redirect-API.
- Middleware aktualisiert (alle Redirects/Allowlists auf zentrale Routen abgestimmt) und neue ESLint-Regel gegen String-Literal-Navigationen ergänzt.
- README um „Typed Routes – Richtlinien“ erweitert.

### Build-/Deploy-Status

```bash
$ npm install
npm ERR! 403 Forbidden - GET https://registry.npmjs.org/firebase

$ npm run build
> next build
sh: 1: next: not found

$ npx vercel --prod --confirm
npm ERR! 403 Forbidden - GET https://registry.npmjs.org/vercel
```

*Interpretation:* Die Containerumgebung blockiert den Download der benötigten npm-Pakete (403 Forbidden). Ohne lauffähiges `node_modules` scheitern Build und Vercel-CLI. Die vorgenommenen Quelltextanpassungen berücksichtigen dies; ein erfolgreicher Build ist lokal/auf Vercel möglich, sobald der Paketmirror erreichbar ist.

### Screenshots

Die gewünschten Navigations-Screenshots konnten nicht erzeugt werden, weil der Next.js-Dev-Server mangels installierbarer Abhängigkeiten nicht startbar war (siehe Build-Log oben). Bitte nach Paketinstallation lokal/auf Vercel nachholen.

### Abweichungen

- Deployment-Checks (`npm run build`, `vercel --prod`) konnten wegen fehlender Paketinstallation nicht durchgeführt werden.
- Kein weiterer Scope-Drift; Flutter/Backend unangetastet.

## Lessons Learned

- Eine zentrale Routenquelle mit Site-Metadaten vereinfacht Middleware- und Guard-Logik erheblich.
- Safe-Redirect-Utilities schützen zuverlässig vor Missbrauch der `?next=`-Parameter und reduzieren Duplikate im Code.
- Linter-Regeln gegen String-Literal-Navigationen sind essenziell, sobald `typedRoutes` aktiv ist.
- Für reproduzierbare Builds sollten Mirror- oder Offline-Registries vorbereitet werden, damit Abhängigkeiten auch in restriktiven Umgebungen verfügbar bleiben.
