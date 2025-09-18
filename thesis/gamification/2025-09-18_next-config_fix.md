# Next.js Config Migration – 2025-09-18

## Prompt
- Next.js-Dev-Setup reparieren, `next.config.ts` durch gültige JS-Variante ersetzen und lokale Dev-Umgebung (`npm run dev`) lauffähig machen.

## Ziel
- Funktionsfähige lokale Next.js-Konfiguration ohne TypeScript-Syntax, kompatibel mit SSR-Anforderungen und bestehendem Skript-Setup.

## Kontext
- Repository: Wasgehtab97/tapem
- Branch: a_gpt5 (lokal `work`)
- Node-Version: v22.19.0

## Ergebnis
- `website/next.config.ts` nach `website/next.config.js` umbenannt und mit CommonJS-Konfiguration für `reactStrictMode`, `images.unoptimized`, `experimental.typedRoutes`, `eslint.ignoreDuringBuilds` sowie `productionBrowserSourceMaps` ergänzt.
- Root-README um Abschnitt „Web lokal starten“ erweitert, der die notwendigen Schritte (`npm install`, `npm run dev`) dokumentiert.

## Lokale Testschritte
```bash
cd website
npm run dev
```
- Server startet ohne Fehler auf http://localhost:3000 (manuell mit `Ctrl+C` beendet).

## Lighthouse/Nachtests
- TODO: Lighthouse-Check und SSR-Verhalten nach künftigen /gym- und /admin-Anpassungen prüfen.

## Abweichungen
- Keine.
