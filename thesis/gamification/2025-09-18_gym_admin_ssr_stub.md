# Gym/Admin SSR Stub – Dev-Auth

## Prompt
Implementiere SSR-Grundgerüste für `/gym` (Betreiber-Portal) und `/admin` (Monitoring) im Next.js-Teil der Tap'em-Webseite, inklusive Dev-Login-Stub ohne Firebase.

## Ziel
- Server-seitig gerenderte Dashboards für Betreiber:innen und Admins bereitstellen.
- Dev-Rollen per Cookie-basierter Stub-Auth setzen und schützen.
- Navigation, No-Index-Header und Dokumentation ergänzen.

## Kontext
- Repository: `Wasgehtab97/tapem`
- Branch: `a_gpt5`
- Scope: `website/` (Next.js App Router) + projektweite README & Thesis-Log

## Ergebnis
- Neue Server-Guards (`src/lib/auth/server.ts`) und Rollentypen (`src/lib/auth/types.ts`).
- Dev-Login/-Logout-APIs mit Cookie-Stubs (`/api/dev/login`, `/api/dev/logout`).
- Login-Seite `/login` inkl. Hinweisbanner & Role-Switch-Formular.
- Globale Navigation mit Dev-Toolbar (Rollenumschaltung) und Footer.
- SSR-Routen `/gym` (Übersicht, Mitglieder, Challenges, Leaderboard) mit Mock-Daten aus `src/server/mocks/gym.ts`.
- SSR-Admin-Dashboard `/admin` (KPIs + Event-Tabelle) für Rolle `admin`.
- README-Updates (Root & `website/README.md`) sowie `.env.example` Platzhalter.
- Thesis-Doku & Maintainer-Hinweise vervollständigt.

### Screens / Links
- `/login` – Dev-Login Stub (lokal & Vercel Preview)
- `/gym` – Betreiber-Dashboard (SSR, Mock-Daten)
- `/admin` – Admin-Monitoring (SSR, Mock-Daten)

## Abweichungen / Nacharbeiten
- Firebase Auth & Firestore-Anbindung stehen noch aus; aktuell rein statische Mocks.
- Dev-Toolbar verwendet Fetch-basierte Buttons für sofortige Cookie-Aktualisierung.

## Preview-URL
- Lokaler Start: `npm run dev` im Ordner `website/`
- Vercel Preview verwendet identische Dev-Auth-Stubs (nicht in Production aktiv)
