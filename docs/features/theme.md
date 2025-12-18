# App Theme & Brand-Themes

Diese Datei dokumentiert, wie das App-Theme in Tap’em aktuell aufgebaut ist, wie die verschiedenen Brand-Themes funktionieren, wo der Code liegt und wie du neue Themes hinzufügen oder bestehende anpassen kannst.

Die Beschreibung bezieht sich auf den aktuellen Stand des Codes in diesem Repo.

---

## Überblick

- Die gesamte App läuft in einem **Dark-Theme**, das auf `ThemeData.dark()` basiert und über zentrale **Design Tokens** (Farben, Gradients, Abstände, Typografie) konfiguriert wird.
- Zusätzlich gibt es **Brand-Themes** für Studios (z. B. Lifthouse, Club Aktiv) sowie **manuelle Theme-Presets**, die der User in den Einstellungen auswählen kann.
- Die Theme-Ermittlung passiert dynamisch zur Laufzeit über einen `ThemeLoader`, der:
  - Gym-spezifisches Branding aus dem Backend auswertet,
  - eine eventuelle Benutzer-Override-Theme-Auswahl berücksichtigt,
  - daraus ein `ThemeData` inklusive `ThemeExtension`s für Brand-spezifische Tokens baut.
- Das fertige `ThemeData` wird über Riverpod in `MaterialApp.theme` injiziert, so dass Widgets ganz normal mit `Theme.of(context)` arbeiten.

---

## Wo liegt der relevante Code?

- Einstieg in die App (MaterialApp + Theme):
  - `lib/core/app/tapem_app.dart:1` – `TapemMaterialApp` mit `theme: ref.watch(themeLoaderProvider).theme`
- Dynamisches Laden & Kombinieren des Themes:
  - `lib/core/theme/theme_loader.dart:14` – `ThemeLoader` + `themeLoaderProvider`
- Zentrale Design Tokens (Farben, Gradients, Spacing, Typografie, Preset-Farbpaletten):
  - `lib/core/theme/design_tokens.dart:74`
- Basis-Dark-Theme & Varianten (mint, amber, neutral, magenta, Club Aktiv):
  - `lib/core/theme/theme.dart:1`
- Brand Theme Presets (IDs und Konfiguration der manuellen Themes):
  - `lib/core/theme/brand_theme_preset.dart:6`
- Brand Theme Extensions für UI-Komponenten:
  - `lib/core/theme/app_brand_theme.dart:8` – `AppBrandTheme`
  - `lib/core/theme/brand_on_colors.dart:1` – `BrandOnColors`
- User-Einstellungen & Persistenz der manuellen Theme-Wahl:
  - `lib/core/providers/theme_preference_provider.dart:11`
- UI zur Auswahl des Themes in den Einstellungen:
  - `lib/features/settings/presentation/screens/settings_screen.dart:520` – Theme-Auswahl-Grid & Aufruf von `themePreferenceProvider.setTheme`
- Ergänzende Doku zu Branding-Komponenten:
  - `docs/branding.md`

---

## Laufzeit-Fluss: Von Branding & Preferences zum Theme

High-Level-Pipeline:

1. **Branding-Daten** (z. B. Farben eines Gyms) werden über den `brandingProvider` geladen.
2. **Theme-Override des Users** (manuell gewähltes App-Theme) wird über `themePreferenceProvider` geladen.
3. Der `themeLoaderProvider` verbindet beides:
   - hört auf Änderungen an `brandingProvider` und `themePreferenceProvider`,
   - ruft `ThemeLoader.applyBranding(...)` mit Gym-ID, Branding-Daten und optionalem Override-Preset auf,
   - erzeugt daraus das aktuelle `ThemeData`.
4. `TapemMaterialApp` liest dieses Theme:
   - `lib/core/app/tapem_app.dart:32–42`
   - `final theme = ref.watch(themeLoaderProvider).theme;`
   - `MaterialApp(theme: theme, ...)`

Damit ist sichergestellt, dass sich Theme-Änderungen (anderes Studio, neue Branding-Daten, manuelles Theme in den Settings) automatisch in der UI widerspiegeln.

---

## ThemeLoader: zentrale Drehscheibe für das Theme

Datei: `lib/core/theme/theme_loader.dart:14`

**Aufgabe:**

- Hält das aktuell aktive `ThemeData` in `_currentTheme`.
- Wendet Branding-Informationen und/oder ein manuelles Theme-Preset an.
- Stellt das Theme über `themeLoaderProvider` für die gesamte App bereit.

**Wichtige Punkte:**

- Standard-Theme (Fallback):
  - `loadDefault()` setzt ein mint/türkis-basiertes Dark-Theme:
    - `AppTheme.mintDarkTheme` / `AppColors.accentMint` / `AppColors.accentTurquoise`
- Branding-Anwendung:
  - `applyBranding(String? gymId, Branding? branding, { BrandThemeId? overridePreset })`
  - Prioritäten:
    1. **Override-Preset**: Wenn `overridePreset != null`, wird ein manuelles BrandThemePreset angewendet (`_applyPreset`).
    2. **Sonderfälle nach Gym-ID**:
       - `lifthouse_koblenz` → Magenta/Violett-palette (`MagentaColors`, `MagentaTones`)
       - `Club Aktiv` / `FitnessFirst MyZeil` → Rot/Orange-Palette (`ClubAktivColors`, `ClubAktivTones`)
    3. **Allgemeines Branding**:
       - Wenn Branding-Daten (`branding.primaryColor`, `branding.secondaryColor`, etc.) vorhanden sind, werden diese verwendet.
       - Wenn Branding fehlt oder unvollständig ist, wird `loadDefault()` verwendet.
- Aus den gewählten Farben baut `_applyBrandColors(...)` das tatsächliche `ThemeData`:
  - ruft `AppTheme.customTheme(...)` auf,
  - setzt `AppGradients.brandGradient` und `AppGradients.setCtaGlow(focus)`,
  - hängt eine `AppBrandTheme`-Extension und `BrandOnColors` an das Theme (`_attachBrandTheme`).

**Provider wiring:**

Der `themeLoaderProvider` (Zeilen `293–318`) hört auf:

- `brandingProvider`:
  - Bei Änderungen: `loader.applyBranding(next.gymId, next.branding, overridePreset: preferences.override)`
- `themePreferenceProvider`:
  - Bei Änderungen: `loader.applyBranding(branding.gymId, branding.branding, overridePreset: next.override)`

Damit ist das Theme immer die Kombination aus:

- aktueller Gym-Branding-Konfiguration
- und (falls gesetzt) manuellem Theme-Override des Users.

---

## Design Tokens (`design_tokens.dart`)

Datei: `lib/core/theme/design_tokens.dart:74`

Dieses File definiert die **Low-Level-Design-Tokens**, auf denen alle Themes aufbauen:

- **Grundfarben** (`AppColors`):
  - `background`, `surface`, `textPrimary`, `textSecondary`
  - `accentMint`, `accentTurquoise`, `accentAmber`
- **Gym-spezifische Paletten**:
  - `MagentaColors` für Lifthouse
  - `ClubAktivColors` für Club Aktiv / FitnessFirst MyZeil
- **Dynamische Tonwerte**:
  - `MagentaTones` und `ClubAktivTones` passen Oberflächen-Tonwerte (`surface1`, `surface2`, `control`) an die durchschnittliche Luminanz des Brand-Gradients an, damit Kontraste stabil bleiben.
- **PresetBrandColors**:
  - Vordefinierte Farbpaletten für die manuellen Brand Themes (Azure, Amber, Forest, Royal, Neon, Copper, Arctic, Ember, Cyber, Citrus).
- **Spacing und Radii**:
  - `AppSpacing` (xs, sm, md, lg, xl)
  - `AppRadius` (card, cardLg, button, chip)
- **Typografie-Größen**:
  - `AppFontSizes` (headline, title, body, kpi)
- **Gradients & CTA Glow**:
  - `AppGradients.progress` – für Progress-Ringe/Charts.
  - `AppGradients.brandGradient` – zentraler Brand-Gradient, wird vom ThemeLoader gesetzt.
  - `AppGradients.ctaGlow` – Radial-Gradient für CTA-Hervorhebungen.

Wichtiger Punkt: **BrandGradient und CTA Glow werden zur Laufzeit angepasst**, z. B. wenn ein Theme-Preset oder Gym-Branding eine andere Primär-/Sekundärfarbe setzt.

---

## AppTheme (`theme.dart`)

Datei: `lib/core/theme/theme.dart:1`

`AppTheme` kapselt die Erzeugung von `ThemeData`:

- `_buildTheme(...)`:
  - startet von `ThemeData(brightness: Brightness.dark)`,
  - baut eine `ColorScheme.dark` basierend auf `primary`, `secondary`, `background`, `surface`, `textPrimary`, `textSecondary`, `focus`,
  - konfiguriert Standard-Komponenten:
    - `appBarTheme`, `bottomNavigationBarTheme`, `textTheme`,
    - `inputDecorationTheme`, `elevatedButtonTheme`, `outlinedButtonTheme` etc.
  - hängt die `AvatarRingTheme`-Extension als Fallback an.
- `customTheme(...)`:
  - Convenience-Funktion, die `_buildTheme` mit optionalen Overrides für Hintergrund, Textfarben, Fokus und Buttons aufruft.
- Vordefinierte Themes:
  - `mintDarkTheme` – Standard-Dark-Theme (mint + türkis).
  - `amberDarkTheme` – Dark-Theme mit amber-betonten Akzenten.
  - `neutralTheme` – Schwarz/Weiß-neutral, wird z. B. für das `blackWhite`-Preset verwendet.
  - `magentaDarkTheme`, `clubAktivDarkTheme` – spezielle Themes für bestimmte Gyms.

Der `ThemeLoader` nutzt in der Regel `AppTheme.customTheme(...)` und ergänzt dann Brand-spezifische Extensions.

---

## Brand Theme Presets & IDs (`brand_theme_preset.dart`)

Datei: `lib/core/theme/brand_theme_preset.dart:6`

Zentrale Elemente:

- `enum BrandThemeId`:
  - Listet alle manuellen Theme-Varianten auf:
    - `mintTurquoise`, `magentaViolet`, `redOrange`, `blackWhite`,
    - `azureSapphire`, `amberSunset`, `forestEmerald`, `royalPlum`,
    - `neonLime`, `copperBronze`, `arcticSky`, `emberInferno`,
    - `cyberGrape`, `citrusPunch`.
- `BrandThemeIdX`:
  - `storageValue` – String für Persistenz (Firestore / SharedPreferences).
  - `fromStorage(String)` – Mapping von String zurück auf `BrandThemeId`.
- `class BrandThemePreset`:
  - Struktur für ein manuelles Theme:
    - `id`, `nameKey` (für Lokalisierung),
    - `primary`, `secondary`, `gradientStart`, `gradientEnd`, `focus`,
    - Flags `useMagentaTokens`, `useClubAktivTokens`,
    - optionale `onColors` (`BrandOnColors`) und optionaler `background`.
- `class BrandThemePresets`:
  - Statische Instanzen für alle Presets, z. B.:
    - `mintTurquoise`, `magentaViolet`, `redOrange`, `blackWhite`, ...
  - `all` – Liste aller Presets.
  - `of(BrandThemeId)` – Lookup-Funktion für ein Preset anhand der ID.

**Wie werden Presets angewendet?**

- Die UI im Settings-Screen zeigt die Presets an:
  - `lib/features/settings/presentation/screens/settings_screen.dart:520–565`
  - `BrandThemePresets.of(id)` liefert die Farbwerte, die im Grid als Gradient-Karte visualisiert werden.
- Der `ThemeLoader` wendet Presets an:
  - `ThemeLoader._applyPreset(BrandThemePreset preset)`:
    - Für `blackWhite` wird `AppTheme.neutralTheme` speziell angepasst (`_applyBlackWhitePreset`).
    - Für alle anderen Presets:
      - `_applyBrandColors(...)` mit den Preset-Farben.
      - Optional Aufruf von `MagentaTones.normalizeFromGradient` oder `ClubAktivTones.normalizeFromGradient`.

### Neues Theme-Preset hinzufügen – Schritt für Schritt

1. **Farbpalette definieren** (falls noch nicht vorhanden):
   - In `PresetBrandColors` (`lib/core/theme/design_tokens.dart:217`) neue Konstanten hinzufügen:
     - z. B. `myThemePrimary`, `myThemeSecondary`, `myThemeGradientStart`, `myThemeGradientEnd`, `myThemeFocus`.
2. **BrandThemeId erweitern**:
   - In `BrandThemeId` ein neues Enum-Element hinzufügen.
   - In `BrandThemeIdX.storageValue` und `fromStorage` entsprechende `case`-Zweige ergänzen.
3. **BrandThemePreset anlegen**:
   - In `BrandThemePresets` eine neue `static const BrandThemePreset` mit den Farben aus Schritt 1 hinzufügen.
   - Optional `onColors` setzen, falls die Kontraste von den Defaults abweichen sollen (z. B. sehr helle Paletten).
4. **Lokalisierung ergänzen**:
   - In `lib/l10n/app_en.arb` und `lib/l10n/app_de.arb` Einträge für den Namen (`settingsThemeXYZ`) hinzufügen.
5. **Theme in der UI verfügbar machen**:
   - `ThemePreferenceProvider.availableForGym(...)` entscheidet, welche Themes für welches Gym sichtbar sind.
   - Falls das Theme für alle Gyms gelten soll, ist nach Schritt 2–4 keine weitere Anpassung notwendig.

---

## Brand Extensions: AppBrandTheme & BrandOnColors

Dateien:

- `lib/core/theme/app_brand_theme.dart:8`
- `lib/core/theme/brand_on_colors.dart:1`

**AppBrandTheme**

- `ThemeExtension<AppBrandTheme>`, die Brand-spezifische Tokens kapselt:
  - `gradient` – Gradient für CTA-/Brand-Flächen.
  - `radius`, `shadow`, `pressedOverlay`, `focusRing`, `textStyle`, `height`, `padding`.
  - Outline-spezifische Tokens:
    - `outline`, `outlineGradient`, `outlineColorFallback`,
    - `outlineWidth`, `outlineRadius`, `outlineShadow`,
    - `outlineDisabledOpacity`.
- Statische Konstruktoren:
  - `defaultTheme()` – nutzt `AppGradients.brandGradient` (z. B. mint/türkis).
  - `magenta()` – Magenta/Violett-Variante für `lifthouse_koblenz`.
  - `clubAktiv()` – Rot/Orange-Variante für Club Aktiv.

**BrandOnColors**

- `ThemeExtension<BrandOnColors>` mit Kontrast-sicheren Vordergrundfarben:
  - `onPrimary`, `onSecondary`, `onGradient`, `onCta`.
- Der `ThemeLoader` hängt `BrandOnColors` als zweite Extension an das aktuelle Theme an, so dass Widgets immer passende Text/Icon-Farben finden können.

**Zugriff in Widgets**

Typischer Zugriff sieht so aus:

```dart
final theme = Theme.of(context);
final brand = theme.extension<AppBrandTheme>();
final onColors = theme.extension<BrandOnColors>();
```

Weitere Beispiele für Komponenten, die diese Tokens nutzen, findest du in `docs/branding.md` und den Brand-Komponenten im UI-Code (z. B. `BrandGradientCard`, `BrandPrimaryButton`, `BrandOutline`).

---

## User-Einstellungen & Persistenz (`theme_preference_provider.dart`)

Datei: `lib/core/providers/theme_preference_provider.dart:11`

**Aufgabe:**

- Verwalten und Persistieren der **manuellen Theme-Auswahl** eines Users.
- Brücke zwischen:
  - Firestore (`users/{uid}/settings/theme`) und
  - lokalem Cache (`SharedPreferences`).

**Wichtige Aspekte:**

- `ThemePreferenceProvider` ist ein `ChangeNotifier` mit:
  - `_override` (`BrandThemeId?`) – aktuell ausgewähltes manuelles Theme (oder `null` für „Studio-Standard“).
  - Lade- und Fehlerstatus (`isLoading`, `error`, `hasLoaded`).
- `setUser(String? uid)`:
  - Wird von `authViewStateProvider` aufgerufen.
  - Lädt Theme-Einstellungen für den aktuellen User.
- `_load()`:
  - Lädt zunächst einen **lokalen Cache** aus `SharedPreferences` (`_loadCachedOverride`).
  - Holt danach das Dokument aus Firestore:
    - Collection: `users/{uid}/settings/theme`
    - Feld: `themeId` (String, der über `BrandThemeIdX.fromStorage` aufgelöst wird).
- `setTheme(BrandThemeId? theme)`:
  - Wird z. B. vom Settings-Screen aufgerufen, wenn der User ein neues Theme auswählt.
  - Optimistisches Update:
    - `_override` wird sofort gesetzt und `notifyListeners()` aufgerufen.
  - Persistenz:
    - In Firestore wird `themeId` gesetzt oder gelöscht.
    - Parallel wird der lokale Cache aktualisiert (`_persistOverride`).
  - Bei Fehler:
    - `_override` wird zurückgerollt, Fehler in `error` gespeichert, Cache wieder auf den alten Wert gesetzt und Exception weitergereicht.
- `manualDefaultForGym(String? gymId)`:
  - Liefert das **Standard-Preset**, das für ein Gym als „Studio-Standard“-Label genutzt wird, z. B.:
    - `lifthouse_koblenz` → `BrandThemeId.magentaViolet`
    - `Club Aktiv` / `FitnessFirst MyZeil` → `null` (kein spezielles Default-Preset, das Branding ist hier vorrangig).
    - alle anderen → `BrandThemeId.mintTurquoise`.
- `availableForGym(String? gymId)`:
  - Liste aller `BrandThemeId`, sortiert so, dass das Default-Preset (falls vorhanden) vorne steht.

Der `settings_screen` nutzt diese Informationen, um das Theme-Grid und Labels korrekt zu bauen.

---

## UI: Theme-Auswahl im Settings-Screen

Datei: `lib/features/settings/presentation/screens/settings_screen.dart:520–590`

**Ablauf:**

- `_showThemeDialog()`:
  - Holt `ThemePreferenceProvider` und `AuthController` (für `gymId`).
  - Ruft `themePref.manualDefaultForGym(gymId)` und `themePref.availableForGym(gymId)` auf.
  - Baut ein `GridView` mit:
    - Einem Eintrag für „Studio-Standard“ (ggf. mit Label des Default-Presets),
    - weiteren Einträgen für alle möglichen manuellen Themes (`additionalOptions`).
  - Jeder Eintrag nutzt `BrandThemePresets.of(id)` zur Visualisierung (Gradient im Card-Hintergrund).
- `_onThemeSelected(BuildContext dialogContext, BrandThemeId? id)`:
  - Schliesst den Dialog (`Navigator.pop`).
  - Ruft `ref.read(themePreferenceProvider).setTheme(id)` auf.
  - Zeigt bei Fehler einen SnackBar mit `settingsThemeSaveError`.

Sobald `setTheme` abgeschlossen ist, werden über `themeLoaderProvider` und `MaterialApp` automatisch alle Screens mit dem neuen Theme gerendert.

---

## Gym-spezifisches Verhalten

Zusammenfassung des aktuellen Verhaltens in `ThemeLoader.applyBranding`:

- Gym-ID `lifthouse_koblenz`:
  - Ohne Branding-Daten:
    - `BrandThemePresets.magentaViolet` (magenta/violett) wird als Default verwendet (`_applyMagentaDefaults()`).
  - Mit Branding-Daten:
    - `primary`, `secondary`, `gradientStart`, `gradientEnd` kommen aus der Branding-Collection, fallback auf `MagentaColors`.
    - `MagentaTones.normalizeFromGradient` sorgt dafür, dass Oberflächen-Tonwerte zur Luminanz des Gradients passen.
- Gym-ID `Club Aktiv` oder `FitnessFirst MyZeil`:
  - Ohne Branding-Daten:
    - `_applyClubAktivDefaults()` nutzt `ClubAktivColors` und `ClubAktivTones`.
  - Mit Branding-Daten:
    - Branding-Farben werden verwendet, aber die Tonwerte weiterhin über `ClubAktivTones` normalisiert.
- Alle anderen Gyms:
  - Wenn keine oder unvollständige Branding-Farben vorhanden sind → `loadDefault()` (mint/türkis).
  - Wenn vollständige Branding-Farben vorhanden sind:
    - `primary` und `secondary` kommen aus Branding.
    - Gradient-Start/-Ende und Fokus werden daraus abgeleitet.

In jedem Fall wird anschließend – sofern kein User-Override gesetzt ist – das resultierende Branding-Theme im gesamten UI verwendet.

---

## Cyberpunk-Neon-Theme (aktueller Stand)

Dieses Kapitel beschreibt den aktuellen Stand des neuen „Cyberpunk Neon“-Themes: wie es technisch eingebunden ist, wie es sich von den bisherigen Presets unterscheidet und welche nächsten Schritte das Design noch hochwertiger und einheitlicher machen können.

### Ziele des Cyberpunk-Themes

- Ein deutlich **dynamischerer, futuristischer Look** für die gesamte App, basierend auf Neon-Cyan- und Magenta-Akzenten.
- Stärkere **Glows, Outline-Effekte und Gradients**, ohne die Lesbarkeit oder Struktur zu zerstören.
- Vollständig optional – das bestehende Dark-Theme + Gym-Brandings bleiben unverändert und sind weiterhin standardmäßig aktiv.

### Technische Integration

**1. Neue Theme-ID & Preset**

- `lib/core/theme/brand_theme_preset.dart:7`:
  - `BrandThemeId` wurde um `cyberpunkNeon` erweitert.
  - Mapping für Persistenz:
    - `storageValue` → `'cyberpunkNeon'`
    - `BrandThemeIdX.fromStorage('cyberpunkNeon')` → `BrandThemeId.cyberpunkNeon`
  - `BrandThemePreset`:
  - Neues Flag `useCyberpunkTokens` (analog zu `useMagentaTokens` / `useClubAktivTokens`).
- `BrandThemePresets.cyberpunkNeon`:
  - `id: BrandThemeId.cyberpunkNeon`
  - `nameKey: 'settingsThemeCyberpunkNeon'`
  - Farbpalette (leicht „filmisch“ angepasst):
    - `primary: Color(0xFF00CFEA)` – etwas dunkleres electric cyan (Primary-Akzent).
    - `secondary: Color(0xFFFF2AA5)` – neon magenta.
    - `gradientStart: Color(0xFF00E5FF)` – helles Cyan für den linken Gradient-Anker.
    - `gradientEnd: Color(0xFFB300FF)` – violett-magenta Neon für den rechten Gradient-Anker.
    - `focus: Color(0xFF8CFBFF)` – klarer, heller Cyan-Fokus für Glow/Focusstates.
  - Flags & Kontraste:
    - `useCyberpunkTokens: true`
    - `onColors: BrandOnColors(onPrimary: Colors.black, onSecondary: Colors.black, onGradient: Colors.black, onCta: Colors.black)` – damit Texte/Icons auf Neon-Flächen konsequent dunkel sind.
  - Hintergrund:
    - `background: Color(0xFF050813)` – sehr dunkles, leicht bläuliches „Night-City“-Black.

**2. Brand-Extension & Surface-Tokens für Cyberpunk**

- Datei: `lib/core/theme/app_brand_theme.dart:256`
- `AppBrandTheme.cyberpunk()`:
  - Basis ist `AppGradients.brandGradient` (wird durch das Preset auf Cyan→Violett-Magenta gesetzt).
  - CTA-/Button-Look:
    - `radius: BorderRadius.circular(AppRadius.button * 1.3)` – etwas stärker gerundet als das Default-Theme.
    - `shadow`: zweistufiger Neon-Glow:
      - innerer Glow mit kleinem BlurRadius nahe am Element (Cyan),
      - äußerer, weicher Glow mit größerem BlurRadius (Magenta/Violett).
    - `pressedOverlay`: farbiges Overlay auf Basis der ersten Gradient-Farbe (`gradient.colors.first.withOpacity(0.14)`), statt neutralem Weiß → holographischer Tap-State.
    - `focusRing`: fast volle Intensität der ersten Gradient-Farbe (`withOpacity(0.9)`).
    - `textStyle`: `fontWeight.w700` + `letterSpacing: 0.6` für einen klaren, futuristischen CTA-Text.
    - `height: 52` + etwas breiteres `padding` (horizontal `AppSpacing.md + 4`) → CTAs wirken bewusster „premium“.
  - Outline-Parameter (für `BrandOutline` u. a.):
    - `outlineRadius: BorderRadius.circular(AppRadius.cardLg)`
    - `outlineWidth: 2.6` (leicht erhöht gegenüber Default).
    - `outlineShadow`: zwei abgestufte Glows (Cyan näher am Rand, Magenta weiter außen), die den Neon-Rand betonen.
  - Ziel: Brand-Flächen wie Primär-Buttons, Gradient-Karten, Outline-Chips bekommen einen klar futuristischen, leuchtenden Charakter, ohne dass andere Themes beeinflusst werden.
  - Neue Surface-Token:
    - `surfaceColor`: zusätzliches Feld in `AppBrandTheme`, das optional eine Brand-spezifische Flächenfarbe beschreibt.
    - Für Cyberpunk wird `surfaceColor` aus `0xFF050813` + etwas Cyan abgeleitet (leicht getönte, sehr dunkle Fläche).
    - `BrandOutline` (`lib/core/widgets/brand_outline.dart`) nutzt `brand.surfaceColor ?? theme.colorScheme.surface` für den inneren Card-Hintergrund.
      - Effekt: Set-Listen, Brand-Karten etc. bekommen im Cyberpunk-Theme automatisch einen stimmig getönten Hintergrund, ohne dass Feature-Widgets Theme-spezifische Ifs kennen müssen.

**3. ThemeLoader-Anpassungen**

- Datei: `lib/core/theme/theme_loader.dart`

Änderungen:

- `_applyBrandColors(...)`:
  - Signatur ergänzt um:
    - `bool useCyberpunk = false`
    - `Color? background`
  - Cyberpunk-spezifische Behandlung von Background & Surfaces:
    - Wenn `useCyberpunk == true`:
      - `resolvedBackground` wird auf `BrandThemePreset.background` bzw. `0xFF050813` gesetzt.
      - `resolvedSurface` und `resolvedSurface2` werden mit `Tone.color` aus `resolvedBackground` abgeleitet (leicht aufgehellte, cyan-getönte Varianten).
      - Diese Werte werden an `AppTheme.customTheme` übergeben (`background`, optional `surface`, `surface2`).
    - Für alle anderen Themes (ohne `useCyberpunkTokens`) bleibt das Verhalten unverändert:
      - `background` bleibt `null` → `AppTheme.customTheme` nutzt die globalen Dark-Defaults (`AppColors.background` / `AppColors.surface`).
  - `BrandOnColors` wird wie gehabt gesetzt, sodass die Kontrastfarben für jede Theme-Variante korrekt bleiben.
- `_applyPreset(BrandThemePreset preset)`:
  - Gibt `preset.useCyberpunkTokens` an `_applyBrandColors` weiter:
    - `useCyberpunk: preset.useCyberpunkTokens`
- `_attachBrandTheme(...)`:
  - Neue Flag-Option `bool useCyberpunk = false`.
  - Verzweigung:
    - `useMagenta` → `AppBrandTheme.magenta()`
    - `useClubAktiv` → `AppBrandTheme.clubAktiv()`
    - `useNeutral` → spezielles Schwarz/Weiß-Theme für `blackWhite`
    - `useCyberpunk` → `AppBrandTheme.cyberpunk()`
    - sonst → `AppBrandTheme.defaultTheme().copyWith(...)`
  - Damit gilt:
    - Aktiviert man `BrandThemeId.cyberpunkNeon`, wird automatisch `AppBrandTheme.cyberpunk()` verwendet.
    - Für alle bisherigen Themes ändert sich nichts; sie benutzen weiterhin ihre existierenden Extensions.

**4. Settings-UI & Lokalisierung**

- Theme-Auswahl-Label:
  - Datei: `lib/features/settings/presentation/screens/settings_screen.dart:345`
  - `_themeOptionLabel(...)`:
    - Neu: `case BrandThemeId.cyberpunkNeon: return loc.settingsThemeCyberpunkNeon;`
- Lokalisierung:
  - `lib/l10n/app_en.arb:945ff`:
    - `"settingsThemeCyberpunkNeon": "Cyberpunk Neon"`
  - `lib/l10n/app_de.arb:947ff`:
    - `"settingsThemeCyberpunkNeon": "Cyberpunk Neon"`
- Persistenz & Provider:
  - `ThemePreferenceProvider` arbeitet mit `BrandThemeId.values` und `BrandThemeIdX.storageValue/fromStorage`.
  - Durch die Erweiterung der Enum und Mappings ist `cyberpunkNeon` automatisch:
    - in Firestore (`themeId: "cyberpunkNeon"`) speicherbar,
    - in SharedPreferences (`theme_override_<uid>`) persistierbar,
    - über `availableForGym` auswählbar.

**5. Verhalten zur Laufzeit**

- Wenn der User in den Einstellungen:
  - „Cyberpunk Neon“ auswählt:
    - `themePreferenceProvider.override = BrandThemeId.cyberpunkNeon`
    - `ThemeLoader.applyBranding(..., overridePreset: BrandThemeId.cyberpunkNeon)` wird getriggert.
    - `BrandThemePresets.cyberpunkNeon` liefert:
      - Neon-Farben + Background + `useCyberpunkTokens: true`.
    - `ThemeLoader` setzt:
      - `AppTheme.customTheme(...)` mit:
        - `background: 0xFF050813` (Night-City-Black),
        - `surface` / `surface2`: leicht aufgehellte, cyan-getönte Varianten via `Tone.color`.
      - `AppGradients.brandGradient` auf Cyan→Violett-Magenta (`0xFF00E5FF` → `0xFFB300FF`),
      - `AppBrandTheme.cyberpunk()` + `BrandOnColors` als Extensions.
      - `BrandOutline`-basierte Komponenten nutzen automatisch `AppBrandTheme.surfaceColor` als Card-Hintergrund.
  - Bei allen Komponenten, die bereits `AppBrandTheme` und `BrandOnColors` nutzen:
    - erscheinen CTA-Buttons, Gradient-Karten, Outline-Elemente etc. automatisch im Cyberpunk-Look.
- Wenn ein anderes Theme oder „Gym default“ gewählt ist:
  - wird `useCyberpunkTokens` nicht gesetzt und `AppBrandTheme.cyberpunk()` nicht verwendet.
  - Alle bisherigen Themes bleiben optisch unverändert.

---

## Anime-Theme „Anime Bloom“

Dieses Theme orientiert sich visuell an modernen Anime-UIs: weiche Sakura-Pinks, klarer Himmel-Blauverlauf, subtile Glows – alles weiterhin auf einem dunklen Grund, damit es mit dem bestehenden App-Look harmoniert.

### Ziele des Anime-Themes

- Ein **weicher, verspielter, aber dennoch hochwertiger** Look als Gegenpol zum sehr technischen Cyberpunk-Theme.
- Fokus auf **Sakura-/Pastellgradienten** und sanften Glows, ohne Lesbarkeit oder Struktur zu verlieren.
- Integration ausschließlich über das Theme-System (Presets + ThemeLoader + `AppBrandTheme`), ohne Feature-Widgets anzupassen.

### Technische Integration

**1. Neue Theme-ID & Preset**

- `lib/core/theme/brand_theme_preset.dart:7`:
  - `BrandThemeId` wurde um `animeBloom` erweitert.
  - Mapping für Persistenz:
    - `storageValue` → `'animeBloom'`
    - `BrandThemeIdX.fromStorage('animeBloom')` → `BrandThemeId.animeBloom`
- `PresetBrandColors` (`lib/core/theme/design_tokens.dart`):
  - Neue Anime-Palette:
    - `animePrimary: 0xFFFF8AC9` – Sakura-Pink.
    - `animeSecondary: 0xFF80D8FF` – klares Himmelblau.
    - `animeGradientStart: 0xFFFFC1E3` – sanftes Sakura.
    - `animeGradientEnd: 0xFF80D8FF` – klarer Himmel.
    - `animeFocus: 0xFFFFE4F3` – heller Cherry-Blossom-Glow.
- `BrandThemePresets.animeBloom`:
  - `id: BrandThemeId.animeBloom`
  - `nameKey: 'settingsThemeAnimeBloom'`
  - Farbzuordnung:
    - `primary: PresetBrandColors.animePrimary`
    - `secondary: PresetBrandColors.animeSecondary`
    - `gradientStart: PresetBrandColors.animeGradientStart`
    - `gradientEnd: PresetBrandColors.animeGradientEnd`
    - `focus: PresetBrandColors.animeFocus`
  - Flags & Kontraste:
    - `useAnimeTokens: true` – aktiviert eine Anime-spezifische Brand-Extension.
    - `onColors: BrandOnColors(...)` – alle `on*`-Farben sind schwarz, damit Text/Icon auf den sehr hellen Gradients klar lesbar bleibt.
  - Hintergrund:
    - `background: Color(0xFF090813)` – sehr dunkler, minimal violett getönter Hintergrund, der zur Pastellpalette passt.

**2. Brand-Extension für Anime**

- Datei: `lib/core/theme/app_brand_theme.dart`
- Neue Factory: `AppBrandTheme.anime()`:
  - Basierend auf `AppGradients.brandGradient` (Sakura → Himmelblau).
  - CTA-/Button-Look:
    - `radius: BorderRadius.circular(AppRadius.button * 1.2)` – etwas weicher als das Default-Theme.
    - `shadow`: zwei weiche Glows:
      - innerer, rosa Glow (`gradient.colors.first`) mit moderatem BlurRadius,
      - äußerer, blauer Glow (`gradient.colors.last`) mit größerem BlurRadius.
    - `pressedOverlay`: leichtes Overlay aus der zweiten Gradient-Farbe (`gradient.colors.last.withOpacity(0.12)`), gibt einen „soft pressed“-Effekt.
    - `focusRing`: `gradient.colors.first.withOpacity(0.8)` – klar erkennbar, aber nicht so aggressiv wie im Cyberpunk-Theme.
    - `textStyle`: `fontWeight.w600` + `letterSpacing: 0.4` – etwas leichter als Cyberpunk, um den weicheren Stil zu betonen.
    - `height: 50` und `padding: EdgeInsets.symmetric(horizontal: AppSpacing.md)` – zwischen Default und Cyberpunk angesiedelt.
  - Outline-Parameter:
    - `outlineWidth: 2.2`
    - `outlineRadius: BorderRadius.circular(AppRadius.cardLg)`
    - `outlineShadow`: zwei weiche Glows (Sakura näher am Element, Himmelblau weiter außen), die den Rahmen betonen ohne zu „nach vorne zu springen“.
  - Surface-Token:
    - `surfaceColor`: wird aus `0xFF090813` + etwas Sakura-Farbe abgeleitet.
    - `BrandOutline` nutzt diese `surfaceColor` analog zu Cyberpunk automatisch als Card-Hintergrund.

**3. ThemeLoader-Anpassungen für Anime**

- Datei: `lib/core/theme/theme_loader.dart`

Änderungen gegenüber dem generischen Handling:

- `BrandThemePreset`:
  - Neues Flag `useAnimeTokens` neben `useMagentaTokens`, `useClubAktivTokens`, `useCyberpunkTokens`.
- `_applyBrandColors(...)`:
  - Signatur ergänzt um:
    - `bool useAnime = false`
  - Surface-Handling:
    - Anime nutzt (anders als Cyberpunk) die standardmäßigen Surfaces aus `AppTheme.customTheme` – der Anime-Look kommt primär über den Gradient + `AppBrandTheme.anime()` + `surfaceColor` auf Brand-Komponenten.
    - Deshalb gibt es **keine** Anime-spezifische `_Tone`-Normalisierung im ThemeLoader (Hintergrund kommt direkt aus `BrandThemePreset.background`).
- `_applyPreset(BrandThemePreset preset)`:
  - Reicht `preset.useAnimeTokens` an `_applyBrandColors` durch:
    - `useAnime: preset.useAnimeTokens`
- `_attachBrandTheme(...)`:
  - Signatur ergänzt um:
    - `bool useAnime = false`
  - Verzweigung:
    - `useMagenta` → `AppBrandTheme.magenta()`
    - `useClubAktiv` → `AppBrandTheme.clubAktiv()`
    - `useNeutral` → neutrales Schwarz/Weiß-Theme
    - `useCyberpunk` → `AppBrandTheme.cyberpunk()`
    - `useAnime` → `AppBrandTheme.anime()`
    - sonst → `AppBrandTheme.defaultTheme().copyWith(...)`

Damit gilt:

- Für Cyberpunk werden Hintergrund + Surfaces + Glows **stärker** angepasst (Night-City-Black + Neon-Glow).
- Für Anime werden Hintergrund + Brand-Components weich, pastellicy, aber die globalen Surfaces bleiben näher am Standard-Dark-Theme.

**4. Settings-UI & Lokalisierung**

- Theme-Auswahl-Label:
  - Datei: `lib/features/settings/presentation/screens/settings_screen.dart`
  - `_themeOptionLabel(...)`:
    - Neues Mapping: `case BrandThemeId.animeBloom: return loc.settingsThemeAnimeBloom;`
- Lokalisierung:
  - `lib/l10n/app_en.arb`:
    - `"settingsThemeAnimeBloom": "Anime Bloom"`
  - `lib/l10n/app_de.arb`:
    - `"settingsThemeAnimeBloom": "Anime Bloom"`

Da `ThemePreferenceProvider` mit `BrandThemeId.values` arbeitet, wird `animeBloom` automatisch:

- in Firestore (`themeId: "animeBloom"`) gespeichert,
- in SharedPreferences gecached,
- in der Liste der verfügbaren Themes (`availableForGym`) angezeigt.

**5. Verhalten zur Laufzeit**

- Wenn der User in den Einstellungen „Anime Bloom“ auswählt:
  - `themePreferenceProvider.override = BrandThemeId.animeBloom`
  - `themeLoader.applyBranding(..., overridePreset: BrandThemeId.animeBloom)` wird ausgelöst.
  - `BrandThemePresets.animeBloom` liefert:
    - Sakura-/Sky-Palette + `background: 0xFF090813` + `useAnimeTokens: true`.
  - `ThemeLoader` setzt:
    - `AppTheme.customTheme(...)` mit dem Anime-Hintergrund.
    - `AppGradients.brandGradient` auf Sakura → Himmelblau.
    - `AppBrandTheme.anime()` + `BrandOnColors` als Extensions.
  - Components, die `AppBrandTheme`/`BrandOnColors` / `BrandOutline` nutzen (z. B. Primary-Buttons, Gradient-Cards, Session-Set-Outline), werden automatisch im Anime-Look gerendert.
- Wenn der User ein anderes Theme oder „Gym default“ wählt:
  - `useAnimeTokens` ist `false`.
  - `AppBrandTheme.anime()` wird nicht verwendet, die App bleibt im jeweiligen anderen Brand-Look.

**6. Neues Theme nach dem Anime-/Cyberpunk-Muster bauen**

Wenn du später ein weiteres, sehr charakteristisches Theme hinzufügen möchtest (z. B. „Hologram Core“ oder „Infrared Neon“), kannst du dich exakt an Cyberpunk und Anime orientieren:

1. In `PresetBrandColors` eine Palette definieren.
2. `BrandThemeId` + `BrandThemePresets.*` erweitern (inkl. optionalem Flag `useXYZTokens`).
3. In `AppBrandTheme` eine passende Factory bauen (`*.xyz()`), optional mit eigener `surfaceColor`.
4. In `ThemeLoader._applyPreset` das Flag an `_applyBrandColors` durchreichen und in `_attachBrandTheme` eine neue Branch ergänzen.
5. UI-/Lokalisierungs-Strings hinzufügen.

Feature-Widgets bleiben dabei unverändert – sie lesen ausschließlich aus:

- `Theme.of(context).colorScheme` für generische Farben und
- `AppBrandTheme` + `BrandOnColors` / `BrandOutline` für alles Brand-Spezifische.

Dadurch kann die App jederzeit weitere dynamische Themes aufnehmen, ohne dass pro Feature-Screen Sonderfälle implementiert werden müssen.

**6. Leitfaden: weitere dynamische Brand-Themes nach Cyberpunk-Muster**

Wenn du ein weiteres „stark charakteristisches“ Theme bauen möchtest (z. B. ein Hologram-/Infrared-Theme), kannst du exakt dem Cyberpunk-Pfad folgen:

1. **Preset anlegen**
   - `BrandThemeId` um einen neuen Wert erweitern.
   - In `BrandThemeIdX.storageValue` + `fromStorage` passende Mappings ergänzen.
   - In `BrandThemePresets` ein neues `BrandThemePreset`:
     - Primär-/Sekundärfarben + Gradient-Start/-Ende + Fokus definieren.
     - Optional `background` setzen (wenn du ein eigenes Screen-Black willst).
     - Optional `onColors` setzen, falls Vordergrundkontraste von den Defaults abweichen.
     - Falls du eigene Brand-Extension-Tokens brauchst (analog zu Cyberpunk): neues Flag hinzufügen (`useMyThemeTokens`).
2. **Brand-Extension implementieren**
   - In `AppBrandTheme` eine weitere Factory-Methode wie `AppBrandTheme.cyberpunk()` hinzufügen:
     - Spezialisiere `shadow`, `pressedOverlay`, `focusRing`, `textStyle`, `height`, `padding`, `outline*` und optional `surfaceColor`.
   - Wenn du `surfaceColor` nutzt, greift `BrandOutline` automatisch darauf zu.
3. **ThemeLoader erweitern**
   - In `_applyPreset` dein neues Flag (`useMyThemeTokens`) an `_applyBrandColors` durchreichen.
   - In `_applyBrandColors` optional Background/Surfaces für dein Theme ableiten (analog zur Cyberpunk-Branch mit `Tone.color`).
   - In `_attachBrandTheme` eine neue Branch ergänzen:
     - `useMyTheme` → `AppBrandTheme.myTheme()`; ansonsten Defaults belassen.
4. **UI & Lokalisierung**
   - Dein Theme in `_themeOptionLabel` (`settings_screen.dart`) eintragen.
   - Lokalisierungsschlüssel in `app_en.arb` / `app_de.arb` ergänzen.

Wichtig: Feature-Widgets sollten weiterhin **nie** direkt auf ein bestimmtes Theme prüfen, sondern immer nur:

- `Theme.of(context).colorScheme` für neutrale UI,
- `theme.extension<AppBrandTheme>()` + `BrandOnColors` + ggf. `BrandOutline` für Brand- und CTA-Flächen.

So bleiben alle bestehenden Themes stabil, und neue dynamische Themes können rein über Presets, ThemeLoader und `AppBrandTheme` integriert werden – das Cyberpunk-Theme dient dabei als vollständiges, praxiserprobtes Beispiel.

---

## Flame-Theme „Flame Inferno“

Dieses Theme ist ein heißes, energiegeladenes Gegenstück zu Anime und Cyberpunk: tiefe Glut im Hintergrund, orangene/rote Flammen-Gradients und ein kräftiger Glow, der sich aber trotzdem sauber in das Dark-Theme einfügt.

### Ziele des Flame-Themes

- Ein **feuriger, kraftvoller Look** mit Fokus auf roten/orangen Flammen und Glut.
- Stärkung von CTAs und Brand-Flächen durch „heiße“ Gradients und Glows.
- Keine Sonderfälle im Feature-Code – alle Effekte laufen über Theme-Presets, ThemeLoader und `AppBrandTheme`.

### Technische Integration

**1. Flame-Palette & Preset**

- `PresetBrandColors` (`lib/core/theme/design_tokens.dart`):
  - `flamePrimary: 0xFFFF5722` – tiefes „Flammen-Orange-Rot“.
  - `flameSecondary: 0xFFFFC107` – leuchtendes Amber.
  - `flameGradientStart: 0xFFFF7043` – aufgehellte Glut als Gradient-Beginn.
  - `flameGradientEnd: 0xFFFFC107` – helles Flammen-Ambers als Gradient-Ende.
  - `flameFocus: 0xFFFFE082` – sanfter, hellgelber Fokus-Glow.
- `BrandThemeId.flameInferno` (`lib/core/theme/brand_theme_preset.dart`):
  - neue ID für das Flame-Theme.
  - `BrandThemeIdX.storageValue/fromStorage` Maps `"flameInferno"` ↔ `BrandThemeId.flameInferno`.
- `BrandThemePreset`: neues Flag `useFlameTokens` für Theme-spezifische Brand-Tokens.
- `BrandThemePresets.flameInferno`:
  - `id: BrandThemeId.flameInferno`
  - `nameKey: 'settingsThemeFlameInferno'`
  - Farben:
    - `primary: PresetBrandColors.flamePrimary`
    - `secondary: PresetBrandColors.flameSecondary`
    - `gradientStart: PresetBrandColors.flameGradientStart`
    - `gradientEnd: PresetBrandColors.flameGradientEnd`
    - `focus: PresetBrandColors.flameFocus`
  - Flags & Kontraste:
    - `useFlameTokens: true`
    - `onColors: BrandOnColors(...)` – alle `on*`-Farben schwarz für sichere Lesbarkeit auf hellen Flammenflächen.
  - Hintergrund:
    - `background: 0xFF120608` – tiefes, rötliches Glut-Schwarz.

**2. Brand-Extension für Flame**

- Datei: `lib/core/theme/app_brand_theme.dart`
- Neue Factory: `AppBrandTheme.flame()`:
  - verwendet `AppGradients.brandGradient` (Flame-Verlauf) als Basis.
  - CTA-/Button-Styling:
    - `radius: AppRadius.button * 1.15` → leicht kräftiger als Default.
    - `shadow`: zwei starke, warme Glows:
      - innerer Glow (erste Gradientfarbe) mit höherem Blur und Offset `(0, 10)`.
      - äußerer Glow (zweite Gradientfarbe) mit großem Blur und Offset `(0, 18)`.
    - `pressedOverlay`: `gradient.colors.first.withOpacity(0.18)` → „heiße“ Press-Feedback-Schicht.
    - `focusRing`: `gradient.colors.last.withOpacity(0.95)` → helle, fast lodernde Fokus-Kante.
    - `textStyle`: `fontWeight.w700`, `letterSpacing: 0.5` – klarer, kräftiger CTA-Text.
    - `height: 50`, `padding: EdgeInsets.symmetric(horizontal: AppSpacing.md)`.
  - Outline-Parameter:
    - `outlineWidth: 2.4`, `outlineRadius: BorderRadius.circular(AppRadius.cardLg)`.
    - `outlineShadow`: zwei Glows (Orange/Amber) mit höherer Intensität, bewusst „feurig“.
  - Surface-Token:
    - `surfaceColor`: Mischung aus `0xFF120608` und der ersten Gradient-Farbe (`lerp(..., 0.14)`).
    - `BrandOutline` nutzt diese `surfaceColor` automatisch für Card-Innenflächen → z. B. Session-Cards oder Rank-Cards wirken wie glühende Flammen-Panels im Flame-Theme.

**3. ThemeLoader-Anpassungen für Flame**

- `BrandThemePreset`:
  - neues Flag `useFlameTokens`, das in `_applyPreset` an `_applyBrandColors` übergeben wird.
- `_applyBrandColors(...)` (`lib/core/theme/theme_loader.dart`):
  - Signatur ergänzt um `bool useFlame = false`.
  - Background-/Surface-Handling:
    - wenn `useFlame == true`:
      - `resolvedBackground = 0xFF120608`.
      - `resolvedSurface = Tone.color(resolvedBackground, +0.07)` – leicht aufgehellte Glutoberfläche.
      - `resolvedSurface2 = Tone.color(resolvedBackground, +0.11)` – noch etwas hellere UI-Fläche (z. B. für Karten).
    - diese Werte werden an `AppTheme.customTheme` übergeben (`background`, `surface`, `surface2`).
  - `BrandOnColors` unverändert → sichert Kontraste auf Flammenflächen.
- `_attachBrandTheme(...)`:
  - Signatur ergänzt um `bool useFlame = false`.
  - Branching:
    - `useMagenta` → `AppBrandTheme.magenta()`
    - `useClubAktiv` → `AppBrandTheme.clubAktiv()`
    - `useNeutral` → neutrales Schwarz/Weiß-Theme
    - `useCyberpunk` → `AppBrandTheme.cyberpunk()`
    - `useAnime` → `AppBrandTheme.anime()`
    - `useFlame` → `AppBrandTheme.flame()`
    - sonst → `AppBrandTheme.defaultTheme().copyWith(...)`

**4. Settings & Lokalisierung**

- `_themeOptionLabel` (`lib/features/settings/presentation/screens/settings_screen.dart`):
  - neue Case:
    - `BrandThemeId.flameInferno` → `loc.settingsThemeFlameInferno`.
- Lokalisierung:
  - `lib/l10n/app_en.arb`:
    - `"settingsThemeFlameInferno": "Flame Inferno"`
  - `lib/l10n/app_de.arb`:
    - `"settingsThemeFlameInferno": "Flame Inferno"`
  - `app_localizations.dart` + `app_localizations_en.dart` + `app_localizations_de.dart` wurden um den Getter `settingsThemeFlameInferno` ergänzt.

**5. Verhalten zur Laufzeit**

- Wenn „Flame Inferno“ in den Einstellungen ausgewählt wird:
  - `themePreferenceProvider.override = BrandThemeId.flameInferno`
  - `themeLoader.applyBranding(..., overridePreset: BrandThemeId.flameInferno)` wird aufgerufen.
  - `BrandThemePresets.flameInferno` liefert:
    - Flame-Farbpalette, Glut-Hintergrund, `useFlameTokens: true`.
  - `ThemeLoader` erzeugt dann:
    - `AppTheme.customTheme(...)` mit Flame-Background + leicht aufgehellten Glut-Surfaces.
    - `AppGradients.brandGradient` = Flame-Gradient (Glut-Orange → Amber).
    - `AppBrandTheme.flame()` + `BrandOnColors` als Theme-Extensions.
  - Komponenten, die `AppBrandTheme`/`BrandOnColors`/`BrandOutline` nutzen (Buttons, Cards, Rank-/Workout-/XP-Cards), bekommen automatisch:
    - feurige Gradients,
    - stärkere orange/amber Glows,
    - dunkle Glut-Flächen im Hintergrund.
- Wenn ein anderes Theme gewählt ist:
  - `useFlameTokens` ist false → Flame-Branch wird nicht verwendet.
  - Dank der eingeschränkten Flags bleiben alle anderen Themes unverändert.

### Hinweise zu Flammen-Animationen

Aktuell ist das Flame-Theme vollständig über statische Tokens umgesetzt (Farben, Glows, Flächen). Für echte Flammen-Animationen (leichtes Flackern / Pulsieren) bietet sich ein eigener, wiederverwendbarer Widget-Typ an, z. B.:

- `FlamePrimaryButton` – eine spezialisierte Variante von `BrandPrimaryButton` mit animiertem Glow.
- `FlameBadge` – kleines rundes Icon mit pulsierendem Flammen-Schein.

Diese Widgets sollten:

- `AppBrandTheme.flame()`-Tokens verwenden (z. B. `gradient`, `shadow`, `focusRing`),
- über einen `AnimationController.repeat` subtil die Opacity/BlurRadius der Shadows modulieren,
- und nur dann aktiv sein, wenn `BrandThemeId.flameInferno` bzw. passende Tokens verwendet werden.

Dadurch bleibt die Basis-UI performant und ruhig, während du für einzelne CTAs/Badges gezielt eine „flackernde“ Flammen-Inszenierung hinzufügen kannst.

## Nächste Schritte für ein noch hochwertigeres Cyberpunk-Design

Der technische Unterbau ist bereit, um das Cyberpunk-Theme auf ein sehr hohes, einheitliches Niveau zu bringen. Die nächsten Schritte betreffen vor allem Konsistenz, gezielte UI-Komponenten und subtile Animationen.

### 1. Hart codierte Farben weiter abbauen

Ziel: Alle wesentlichen Screens sollen vollständig auf Theme-/Brand-Tokens basieren.

- Repo-weit `Colors.*`-Verwendungen in Feature-UI systematisch durchgehen (einige prominente Stellen sind z. B. XP-, Community-, Gym-Management-Views).
- Ersetzen durch:
  - `theme.colorScheme.*` für neutrale UI-Elemente,
  - `theme.extension<AppBrandTheme>()` / `BrandOnColors` für Brand-Flächen.
- Wichtig: Dabei sicherstellen, dass bestehende Themes optisch gleich bleiben:
  - Statt harte Farbwerte zu ändern, nur die Quelle (Theme vs. Literal) austauschen.

### 2. Cyberpunk-spezifische Komponenten einführen

Ziel: Wiederverwendbare Bausteine, die dem Cyberpunk-Theme einen klaren Charakter geben, aber bei anderen Themes neutral aussehen.

Beispiele:

- `CyberpunkCard`:
  - Nutzt Brand-Gradient + Glow + leichte Outline,
  - im Cyberpunk-Theme neonfarbig, in anderen Themes dezent.
- `NeonPill` / `NeonChip`:
  - Für Tags, Filter, Status-Badges,
  - mit optional animiertem Glow (z. B. bei „aktiv“).
- `GlitchHeader` / „Holo“-Header:
  - Für wichtige Screens (XP-Leaderboard, Community, Profil),
  - nutzt Gradient, Blur und Layering auf Basis der bestehenden Theme-Tokens.

Diese Widgets sollten ausschließlich Theme-/Brand-Tokens nutzen, damit sie ohne weiteren Code in allen Themes funktionieren.

### 3. Animierte Akzente & Motion

Ziel: Cyberpunk soll sich nicht nur in Farbgebung, sondern auch in Bewegungen subtil unterscheiden.

Ideen:

- Leichte Animation von Gradients (z. B. langsam verschiebende Neon-Verläufe) in prominenten Bereichen.
- Pulsierende Focus-Ringe oder Glows bei wichtigen CTAs.
- Subtile Opacity-/Scale-Animationen beim Hovern/Tappen von Karten und Chips.

Wichtig: Animationen sollten sparsam und ressourcenschonend sein, um UX und Performance nicht negativ zu beeinflussen.

### 4. Typografie-Feintuning im Cyberpunk-Theme

Ziel: Headlines, KPI-Zahlen und Labels sollen im Cyberpunk-Theme eine eigene „Stimme“ haben, ohne das Reading zu verschlechtern.

- In `AppTheme` optional ein eigenes TextPreset für Cyberpunk:
  - z. B. leicht schmalere Headlines, andere Gewichtung für Titel vs. Body,
  - betonte KPI-Zahlen mit spezieller Farbe/Shadow.
- Abgestimmt mit `AppBrandTheme.cyberpunk().textStyle`, damit Brand-Buttons und -Cards typografisch konsistent sind.

### 5. Visual QA über alle Themes

Ziel: Sicherstellen, dass Änderungen für Cyberpunk andere Themes nicht ungewollt verschlechtern.

- Nach größeren Änderungen:
  - manuell durch alle Theme-Optionen gehen (Gym default + einige Presets + Cyberpunk Neon),
  - Schlüssel-Screens prüfen (Home/Dashboard, XP, Community, Report, Settings).
- Checkliste:
  - Kontrast (Text/Icons vs. Hintergrund),
  - Lesbarkeit von Fortschrittsanzeigen und Badges,
  - Konsistenz von Buttons und Karten über die App hinweg.

Wenn du diese Schritte nacheinander umsetzt, kannst du das Cyberpunk-Theme schrittweise von einem „neonfarbenen Skin“ zu einem durchgängig hochwertigen, markentauglichen Designsystem ausbauen, ohne die bestehenden Themes zu beeinträchtigen.

---

## Theme in Widgets verwenden

Für „normale“ Flutter-Widgets:

- Nutze bevorzugt die Standard-APIs:
  - `Theme.of(context).colorScheme`
  - `Theme.of(context).textTheme`
  - `Theme.of(context).scaffoldBackgroundColor`, `cardColor`, etc.
- Vermeide harte Farbwerte – nutze stattdessen:
  - `AppColors` / `AppGradients` nur in **globalen** Styles bzw. systemnahen Widgets,
  - in Feature-Widgets immer `Theme.of(context)` und `ThemeExtension`s.

Für Brand-spezifische Oberflächen:

- Greife auf `AppBrandTheme` und `BrandOnColors` zu:

```dart
final theme = Theme.of(context);
final brand = theme.extension<AppBrandTheme>()!;
final onColors = theme.extension<BrandOnColors>()!;

Container(
  decoration: BoxDecoration(
    gradient: brand.gradient,
    borderRadius: brand.radius,
    boxShadow: brand.shadow,
  ),
  child: Text(
    'CTA',
    style: brand.textStyle.copyWith(color: brand.onBrand),
  ),
);
```

Weitere Best Practices dazu findest du in `docs/branding.md`.

---

## Bestehende Themes anpassen oder erweitern

**1. Farben eines vorhandenen manuellen Themes ändern**

- Passe die entsprechenden Konstanten in `PresetBrandColors` an (`design_tokens.dart:217`).
- Alternativ kannst du die `BrandThemePreset`-Definition in `brand_theme_preset.dart` direkt ändern (z. B. `gradientStart`, `gradientEnd`, `focus`).
- Der Settings-Screen und der `ThemeLoader` greifen automatisch auf diese aktualisierten Werte zu.

**2. Default-Theme für ein bestimmtes Gym ändern**

- Verwende `ThemePreferenceProvider.manualDefaultForGym` (`theme_preference_provider.dart:146`):
  - Ergänze/ändere die Zuordnung von Gym-ID zu `BrandThemeId`.
- Optional kannst du im Branding-Backend die Standardfarben ändern; diese landen im `Branding`-Model und werden im `ThemeLoader` ausgewertet.

**3. Branding-basiertes Theme-Handling ändern**

- Die Logik liegt in `ThemeLoader.applyBranding`:
  - Sonderfälle nach Gym-ID,
  - Fallbacks, wenn Branding unvollständig ist,
  - Wahl von `useMagentaTokens` / `useClubAktivTokens`.
- Anpassungen hier wirken sich global auf alle Gyms/Lokationen aus.

Wenn du dir unsicher bist, ob eine Änderung Branding oder Theme-Presets betrifft, ist der grobe Unterschied:

- **Branding** = Gym-spezifische Farben aus dem Backend.
- **Theme-Preset** = manuell vom User gewählte App-Theme-Variante, unabhängig vom Gym-Branding (oder als Overlay darüber).

---

## TL;DR

- Das aktuelle Theme-System ist:
  - global dark, mit dynamischen Brand-Akzenten,
  - kombiniert Gym-Branding mit optionaler User-Override-Theme-Auswahl,
  - kapselt alle Brand-spezifischen Werte in `ThemeExtension`s.
- Wenn du ein neues Theme brauchst:
  - Farben in `PresetBrandColors` definieren,
  - `BrandThemeId` + `BrandThemePresets` erweitern,
  - Lokalisierung ergänzen,
  - optional `manualDefaultForGym` anpassen.
- Wenn du neue UI-Komponenten baust:
  - **niemals Brand-Farben hardcoden**,
  - immer `Theme.of(context)` + `AppBrandTheme` / `BrandOnColors` bzw. `colorScheme` verwenden.

Damit solltest du das aktuelle Theme-System vollständig verstehen und sicher erweitern können.
