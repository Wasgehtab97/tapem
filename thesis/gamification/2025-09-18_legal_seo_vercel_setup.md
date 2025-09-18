# Legal, SEO & Vercel Setup

## Prompt (Kurzfassung)
- Rechtliche Pflichtseiten (DE) ergänzen, Branding/SEO optimieren (OG-Bild, Icon), Vercel Deploy-Doku erstellen.

## Ziel
- Landing-Page erhält geprüfte Platzhalter für Impressum & Datenschutz.
- Dynamisches OpenGraph-Bild und SVG-Icon ohne Binärdateien bereitstellen.
- Klare Anleitung für Vercel-Preview- und Production-Deployments dokumentieren.

## Kontext (Repo/Branch)
- Repository: Wasgehtab97/tapem
- Branch: a_gpt5 (lokal gespiegelt als `work`)

## Ergebnis
- Dateien aktualisiert:
  - `website/src/app/imprint/page.tsx`
  - `website/src/app/privacy/page.tsx`
  - `website/src/app/opengraph-image.tsx`
  - `website/src/app/layout.tsx`
  - `website/src/app/page.tsx`
  - `website/src/app/icon.svg`
  - `README.md`
  - `website/README.md`
- Screens (lokal geprüft, Screenshots bei Bedarf in Vercel-Preview nachreichen):
  - `/imprint` & `/privacy` gerendert via `npm run dev`.
  - `/opengraph-image` geprüft (zeigt generiertes 1200×630 Bild).
- Vercel-Preview-URL: Wird nach erstem Deploy ergänzt (TODO).

## Abweichungen / Nacharbeiten
- Keine produktiven Daten eingepflegt – alle rechtlichen Inhalte weiterhin als Platzhalter markiert.
- Lighthouse-Check im Vercel-Preview als Nacharbeit einplanen.

## Tests / Screens
- `npm run lint` im Ordner `website/` (läuft nach Abschluss der Änderungen).
- `npm run dev` lokal gestartet; manuelle Sichtprüfung der neuen Routen.
- Social-Debugger-Check als TODO nach erstem Vercel-Deploy festhalten.
