# Full-bleed Page Background – 2025-09-19

## Prompt
>Ziel
>Im GitHub-Repo Wasgehtab97/tapem, Branch a_gpt5, den Web-Teil unter website/ so überarbeiten, dass der Seiten-Hintergrund vollflächig über den gesamten Viewport (Header, Main, Footer, links/rechts) einheitlich sichtbar ist (keine weißen Außenränder), und das Layout in Vollbild „full-bleed“ wirkt. Inhalt darf weiterhin in einem zentrierten Container begrenzt sein, aber der Hintergrund liegt auf der gesamten Seite. Stilistisch modern, zugänglich (AA-Kontrast), ohne Funktionsänderungen an Navigation/SSR/Stub-Auth. Deployment muss anschließend auf Vercel Production fehlerfrei laufen.
>
>Kontext / Randbedingungen
>
>Monorepo; Web liegt in website/ (Next.js 14, App Router, TypeScript, Tailwind, ESLint/Prettier).
>
>experimental.typedRoutes ist aktiv und soll unverändert aktiv bleiben (keine neuen Typfehler erzeugen).
>
>Preview/Dev: noindex; Production: Landing indexierbar; geschützte Bereiche (z. B. /gym, /admin) noindex.
>
>Dev-Auth-Stub existiert; in Production gesperrt lassen.
>
>OG-Bild-Route existiert; CSS dort muss kompatibel bleiben (kein Build-Fehler).
>
>Keine Flutter-Dateien ändern. Keine Binärdateien (Bilder) zum Repo hinzufügen.
>
>PR-Doku für Masterarbeit ist Pflicht (siehe unten).
>
>Aufgaben (bitte exakt, ohne Beispielcode, umsetzen)
>
>Globalen Seiten-Hintergrund zentral setzen
>
>Stelle sicher, dass html/body den gewünschten Seiten-Hintergrund erhalten (einheitliche Farbe/Theme-Surface) und min-h-screen bzw. gleichwertige Einstellung aktiv ist.
>
>Entferne/neutralisiere widersprüchliche globale Vorgaben (z. B. ein weißes bg-* in globalen Styles oder im Root-Layout), die den Hintergrund überschreiben.
>
>Header/Main/Footer „full-bleed“ ausrichten
>
>Header und Footer sollen flächenhaft denselben Hintergrund wie der Body zeigen (keine hellen Leisten).
>
>Content-Container (z. B. max-w-6xl, Padding) bleiben nur für Inhalt; der Hintergrund liegt außerhalb auf den vollbreiten Eltern-Elementen.
>
>Transparenz/Blur in Header ggf. angleichen, sodass keine hellen Säume entstehen.
>
>Sektionen & Komponenten auditieren
>
>Überprüfe Hero, Feature-Sektionen, FAQ, Footer, Subnav etc. auf unbeabsichtigte eigene Hintergründe (z. B. bg-white, bg-slate-50, Card-Flächen) und passe sie so an, dass sie vor dem globalen Seiten-Hintergrund liegen (transparent bzw. Theme-Surface).
>
>Rahmen/Dividers farblich an den neuen Hintergrund anpassen (Kontrast AA).
>
>Entferne überflüssige äußere Margins/Paddings, die optische „Ränder“ erzeugen.
>
>Vollbild-Wirkung überprüfen
>
>Stelle sicher, dass die Seite auf Desktop, Tablet, Mobile keine seitlichen weißen Balken zeigt (Viewport-Breite voll genutzt).
>
>Typische Problemstellen: horizontales Overflow, fixe Breiten, negative Margins. Korrigieren, ohne Layout-Sprünge zu erzeugen.
>
>Theme/Design-Konsistenz
>
>Bestehenden Theme-Toggle beibehalten; sicherstellen, dass in beiden Modi der Seiten-Hintergrund konsistent gesetzt wird.
>
>meta theme-color (System-UI-Farbe mobiler Browser) an den gewählten Seiten-Hintergrund je Theme anpassen.
>
>SEO/Robots & OG beibehalten
>
>Vorhandene Robots-Logik (Preview noindex) intakt lassen.
>
>OG-Bild-Route unverändert nutzbar halten (keine unzulässigen CSS-Eigenschaften in der Generierung).
>
>typedRoutes & Navigation nicht beschädigen
>
>Alle internen Links/Redirects (Navbar, Subnav, Footer, Buttons) müssen weiterhin typedRoutes-konform bleiben. Keine neuen Typfehler durch die Layout-Anpassungen verursachen.
>
>Qualitätssicherung
>
>Lighthouse auf der Landing: Zielwerte ≥ 90 (Performance/SEO/Best Practices/Accessibility).
>
>Screenshots (Desktop 1440 px, Mobile 375 px) in der PR-Beschreibung referenzieren.
>
>Manuelle Checks: keine Scroll-Leisten durch horizontales Overflow; Header/Footerschatten/Abgrenzungen stimmig; Farbabstände lesbar.
>
>Dokumentation
>
>website/README.md kurz ergänzen: Hintergrund-Strategie (globaler Body-Hintergrund), Container-Prinzip, Hinweise zu „full-bleed vs. content-container“, Theme-Hinweis (Dark/Light).
>
>Thesis-Markdown anlegen:
>
>Pfad: thesis/gamification/YYYY-MM-DD_full_bleed_page_background.md
>
>Inhalt: Prompt (dieser Text), Ziel, Kontext (Repo/Branch, Ordner), Ergebnis (Welche Dateien/Abschnitte geändert? Vorher/Nachher-Beschreibung), Messwerte (Lighthouse), Abweichungen/Nacharbeiten.
>
>Git & PR
>
>Konventionelle Commits verwenden.
>
>PR-Titel: style(website): full-bleed page background & layout normalization (no binaries)
>
>PR-Checkliste in Beschreibung:
>
>Vollflächiger Hintergrund ohne weiße Außenränder (Desktop/Mobile).
>
>Header/Main/Footer konsistent; Content zentriert, Hintergrund full-bleed.
>
>typedRoutes weiterhin grün; Build npm run build und Vercel Production erfolgreich.
>
>SEO/Robots/OG unverändert funktionsfähig.
>
>Keine Binärdateien; Flutter unberührt; Thesis-MD vorhanden.
>
>Ausschlüsse / Safety
>
>Keine Änderungen außerhalb website/ (außer README + Thesis-MD).
>
>Keine neuen Abhängigkeiten ohne Notwendigkeit.
>
>Keine Secrets einchecken; .env.example nur mit Platzhaltern.
>
>Erfolgskriterien (DoD)
>
>Auf Vercel Production rendert jede Seite ohne weiße Ränder (full-bleed-Hintergrund), Lighthouse-Checks ≥ 90, keine typedRoutes- oder Build-Fehler, Robots/OG korrekt, PR-Doku inkl. Thesis-Markdown vorhanden.
>
>Wichtig für Gamification/Thesis
>Lege im PR zwingend thesis/gamification/YYYY-MM-DD_full_bleed_page_background.md an (Prompt, Ziel, Kontext, Ergebnis/Messwerte, Abweichungen).

## Ziel
- Full-bleed Hintergrundgestaltung ohne helle Außenränder auf allen Breakpoints.
- Konsistente Header-/Footer-Surfaces sowie Containerstrategie für Inhalte.
- Theme-Toggle inklusive `meta theme-color`-Aktualisierung pro Modus.

## Kontext
- Repository: Wasgehtab97/tapem
- Branch: a_gpt5
- Arbeitsbereich: `website/`

## Ergebnis
- Globale Styles (`src/styles/globals.css`) mit Theme-Variablen, Spotlight-Gradient und Utility-Klassen für `bg-page`, `bg-card`, `border-subtle`, `surface-blur` u. a.
- Root-Layout überarbeitet (`src/app/layout.tsx`): Header/ Footer full-bleed, Container-Handling in den Seiten verlagert, `themeColor`-Metadata ergänzt.
- Landingpage refaktoriert (`src/app/page.tsx`): Sektionen auf transparente Flächen umgestellt, Container pro Abschnitt, CTA- und FAQ-Karten auf neue Utilities migriert.
- Detailseiten (`imprint`, `privacy`, `login`, `admin`) sowie Gym-Layout erhalten eigene Container, damit die globale Fläche frei bleibt.
- Theme-Toggle erweitert (`src/components/theme-toggle.tsx`), um `meta[name="theme-color"]` beim Umschalten zu setzen und neue Surface-Klassen zu nutzen.
- README dokumentiert die Hintergrund-Strategie, Container-Guidelines und Theme-Hinweise.

## Messwerte (Lighthouse)
- Nicht ermittelt – Lighthouse-CLI steht im Container nicht zur Verfügung. Lokaler/Preview-Check erforderlich.

## Abweichungen / Nacharbeiten
- Screenshots (Desktop 1440 px, Mobile 375 px) müssen in einer echten Browser-Session nachgereicht und in der PR-Beschreibung verlinkt werden.
- Lighthouse-Audit ≥ 90 in allen Kategorien in Preview/Production bestätigen und Werte dokumentieren.
