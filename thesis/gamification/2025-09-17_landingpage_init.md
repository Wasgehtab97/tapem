# Landing-Page Initial Setup – 2025-09-17

## Prompt

> Ziel: In der GitHub-Repo Wasgehtab97/tapem, Branch a_gpt5, eine lokal lauffähige Landing-Page in Next.js (TypeScript) anlegen. Ergebnis: Ich kann lokal npm run dev starten und die Landing-Page unter http://localhost:3000 sehen.
> WICHTIG: Keine Binärdateien (keine .png, .jpg, .jpeg, .webp, .gif, .ico) ins Repo schreiben. Stattdessen: leere Ordner + .gitkeep und README-Anleitung, wo ich Bilder später manuell ablegen soll.
>
> Rahmenbedingungen
>
> – Flutter-Ordner (lib/, android/, ios/, web/) nicht verändern.
> – site/ und scripts/ nicht überschreiben.
> – Neues Verzeichnis website/ für Next.js (App Router, TypeScript), Tailwind CSS, ESLint, Prettier.
> – Landing-Page als SSG (statisch), ohne Firebase-Zugriffe.
> – Konventionelle Commits (siehe COMMIT_CONVENTIONS.md).
> – Pro PR eine .md in thesis/gamification/ mit Prompt, Ziel, Kontext, Ergebnis.
> – Nur lokal entwickeln (keine Domain erforderlich).
>
> Aufgaben (bitte exakt umsetzen)
>
> Branch & Struktur
>
> Neuen Branch von a_gpt5: website/landing-initial.
>
> Erzeuge website/ und scaffolde dort ein Next.js ≥14 Projekt mit App Router und TypeScript.
>
> Lege an (Beispielliste, bei bestehendem Projekt nur fehlendes ergänzen – nicht destruktiv ändern):
>
> website/package.json, website/next.config.ts, website/tsconfig.json, website/postcss.config.js, website/tailwind.config.ts
>
> website/src/app/layout.tsx, website/src/app/page.tsx, website/src/styles/globals.css
>
> website/src/app/robots.txt.ts, website/src/app/sitemap.ts
>
> website/.eslintrc.json, website/.prettierrc, website/.prettierignore, website/.gitignore, website/.env.example, website/next-env.d.ts
>
> Assets-Ordner anlegen – ohne Bilder
>
> Lege an: website/public/ und website/public/images/.
>
> Füge eine Textdatei oder .gitkeep in website/public/images/ hinzu, damit der Ordner versioniert wird, aber keine Bilddateien committed werden.
>
> Keine .png/.jpg/... schreiben. Keine Base64-Binaries. Nur Textdateien sind erlaubt.
>
> Landing-Page implementieren (website/src/app/page.tsx)
>
> Baue folgende Abschnitte (ohne echte Bilddateien; überall fallbacks statt Bilder):
>
> Hero mit App-Name „Tap’em“, kurzer Value-Prop („NFC-basiertes Gym-Tracking & -Management“), zwei CTAs („Mehr erfahren“, „Für Studios: Demo anfragen“).
>
> Features-Grid (4–6 Punkte): NFC-Check-in, Multi-Tenant (Logo/Farben pro Studio), Trainingshistorie/Charts, Ranglisten & Challenges, Geräte-Auslastung/Analytics.
>
> How-it-works (3 Schritte) mit SVG-Icons als Inline-SVG (kein Import externer Bilddateien).
>
> Screenshot-Galerie: Zeige Platzhalter-Karten (Tailwind-divs mit Aspect-Ratio und bg-neutral-200) und Texthinweis „Lege hier später Bilder ab unter /public/images/...“.
>
> FAQ (5–6 Fragen).
>
> Footer (Impressum/Datenschutz Platzhalter).
>
> Barrierefreiheit: Semantische Tags (header/main/footer), sinnvolle aria-labels.
>
> SEO-Metadaten: In layout.tsx oder Seitenkomponente export const metadata = { title, description, openGraph }.
>
> robots/sitemap: Minimalinhalte in robots.txt.ts und sitemap.ts.
>
> Styling: Tailwind, responsive Breakpoints, optional Light/Dark-Mode-Toggle, ohne externe Bild-CDN.
>
> Wichtig: Keine Bild-Imports; wo Bilder vorgesehen sind, fallback-Komponenten/Boxen + Pfad-Hinweise rendern.
>
> Build-Skripte & lokale Nutzung
>
> website/package.json Scripts:
>
> {
>   "scripts": {
>     "dev": "next dev",
>     "build": "next build",
>     "start": "next start",
>     "lint": "next lint"
>   }
> }
>
> Root-README.md um Abschnitt „Web lokal starten“ ergänzen:
>
> cd website
> npm install
> npm run dev
> # http://localhost:3000
>
> README-Anleitung für Bilder (zwingend)
>
> Erweitere das Root-README.md und/oder website/README.md um einen Abschnitt „Assets hinzufügen“, der konkret erklärt:
>
> Lege deine Bilder manuell in website/public/images/ ab (nicht committen, wenn dein Tool Binärdateien blockiert; ansonsten git-lfs oder späterer Schritt).
>
> Dateinamen & empfohlene Maße (Beispiele):
>
> logo.png → 512×512 oder SVG (Logo der App)
>
> hero.png → ca. 1600×900 (Hero-Mockup/Screenshot)
>
> screenshot-1.png, screenshot-2.png, screenshot-3.png → 1200×800 (Galerie)
>
> Nach dem Hinzufügen lokal neu starten; die Platzhalter-Karten ersetzen sich automatisch durch <Image src="/images/..." /> Renderings (bereitstellen: ein internes Mapping, das prüft, ob die Datei existiert; falls nicht, Fallback zeigen).
>
> Implementiere in der Galerie-Komponente eine einfache Fallback-Logik: Wenn public/images/<name>.png nicht existiert, zeige eine graue Box mit Dateinamen-Hinweis.
>
> Qualität
>
> ESLint + Prettier aktivieren (Next.js/TS-Defaults).
>
> Lighthouse lokal ausführen (Developer Tools). Ziel ≥90 in Performance/SEO/Best-Practices/Accessibility; falls darunter:
>
> next/image mit unoptimized={true} zunächst (ohne externe Loader),
>
> Bildgrößen im README empfehlen,
>
> Fonts: System-Fonts oder preconnect/preload für Webfonts.
>
> Git & PR
>
> Conventional Commits verwenden, z. B.:
>
> feat(website): scaffold Next.js app with Tailwind and app router (no binaries)
>
> feat(website): implement marketing landing page with placeholders and SEO
>
> docs(website): add README assets instructions and local run guide
>
> PR gegen a_gpt5 mit Titel:
>
> feat(website): initial Next.js landing page (local dev, no binaries)
>
> PR-Beschreibung (Checkliste): „lokal startbar“, „SSG“, „SEO-Metadaten“, „Lighthouse-Ziel dokumentiert“, „keine Binärdateien committet“, „Flutter-Verzeichnisse unverändert“.
>
> Dokumentation für Masterarbeit (Pflicht)
>
> Lege im PR an: thesis/gamification/YYYY-MM-DD_landingpage_init.md
>
> Inhalt: Prompt (dieser Text), Ziel, Kontext (Repo/Branch, vorhandene Ordner), Ergebnis (neue Dateien/Ordner), Anleitung für Assets, Abweichungen/Nachbesserungen, Screenshots/Lighthouse können später ergänzt werden.
>
> Ausschlüsse / Sicherheit
>
> Keine Änderungen an lib/, android/, ios/, web/, site/, scripts/, functions/.
>
> Keine Secrets committen (.env.example nur mit Platzhaltern).
>
> Keine Binärdateien hinzufügen (auch keine Base64-Blobs).
>
> Abnahme-Kriterien
>
> cd website && npm install && npm run dev läuft fehlerfrei.
>
> Landing-Page unter http://localhost:3000 sichtbar.
>
> PR enthält die Thesis-Markdown und keine Binärdateien.
>
> README enthält klaren Abschnitt „Assets hinzufügen“ mit Pfaden, Dateinamen und empfohlenen Maßen.
>
> Liefere am Ende:
> – Liste der neu angelegten/angefassten Dateien,
> – PR-Link/Hinweis,
> – Kurzanleitung „lokal starten“,
> – Verweis auf README-Anleitung zum späteren Ablegen der Bilder.

## Ziel

Eine lokal startbare, statisch generierte Next.js-Landing-Page inkl. Tailwind, ESLint und Prettier ohne Binärdateien anlegen und
die README-Dokumentation für Setup und Assets ergänzen.

## Kontext

- Repository: `Wasgehtab97/tapem`
- Ausgangs-Branch laut Vorgabe: `a_gpt5` (lokal bearbeitet auf vorhandenem Arbeitsstand `work`)
- Relevante Bestandsordner blieben unverändert: `lib/`, `android/`, `ios/`, `web/`, `site/`, `scripts/`, `functions/`

## Ergebnis

- Neues Verzeichnis `website/` mit Next.js 14 (App Router, TypeScript)
- Tailwind-, ESLint- und Prettier-Konfiguration inkl. Skripte (`dev`, `build`, `start`, `lint`)
- Landing-Page mit Hero, Features, How-it-works, Galerie mit Fallbacks, FAQ, Kontakt und Footer
- SEO-Metadaten, `robots.txt` und `sitemap` umgesetzt
- README im Projekt-Root und unter `website/` um Anleitungen für lokalen Start & Asset-Handling ergänzt
- Platzhalterordner `website/public/images/` mit `.gitkeep` erstellt

## Anleitung für Assets

1. Bilder ausschließlich lokal unter `website/public/images/` ablegen (Standard: nicht committen).
2. Empfohlene Dateien & Maße: `logo.png` (512×512), `hero.png` (ca. 1600×900), `screenshot-1.png` bis `screenshot-3.png` (je 1200×800).
3. Nach dem Ablegen dev-Server neu starten – die Galerie lädt automatisch `<Image />`, wenn die Datei vorhanden ist; sonst bleibt der Platzhalter sichtbar.

## Abweichungen & Nachbesserungen

- Branch-Wechsel auf `website/landing-initial` war aufgrund der Systemrichtlinie „Do not create new branches" nicht möglich; Anpassungen erfolgten auf dem bereitgestellten Arbeits-Branch `work`.
- Lighthouse-Messung folgt nach dem ersten lokalen Build mit realen Assets.

## Offene Punkte / ToDo

- Echte Screenshots & Logos lokal ergänzen, anschließend Lighthouse-Report dokumentieren.
- Impressum/Datenschutz-Inhalte hinterlegen, sobald jurische Texte vorliegen.
