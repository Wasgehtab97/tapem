# Branding Guidelines

The app uses a global `AppBrandTheme` [`ThemeExtension`] to expose
common brand tokens. Retrieve it via
`Theme.of(context).extension<AppBrandTheme>()` and avoid hard coded
magenta/violet values.

## Components

- **BrandGradientCard** – gradient surfaces with rounded corners and
  correct on-brand text/icon colours.
- **BrandGradientHeader** – top rounded header for expansion tiles.
- **BrandPrimaryButton** – primary call‑to‑action button with gradient
  background.
- **BrandOutline** – neutral surfaces with a branded gradient outline.

## Usage

```dart
final brand = Theme.of(context).extension<AppBrandTheme>();
```

Use these widgets for any prominent branded surface or primary action.
Neutral surfaces (lists, backgrounds) remain on the default theme.
`BrandOutline` fits best for cards or chips on dark backgrounds where only the
stroke should carry the brand colours, while `BrandGradientCard` and
`BrandPrimaryButton` render filled gradient surfaces for content and actions
respectively.

### Outline tokens

```dart
final outline = Theme.of(context).extension<AppBrandTheme>()!;
Container(
  decoration: BoxDecoration(
    gradient: outline.outlineGradient,
    borderRadius: outline.outlineRadius,
  ),
);
```
