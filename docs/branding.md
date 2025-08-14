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

## Usage

```dart
final brand = Theme.of(context).extension<AppBrandTheme>();
```

Use these widgets for any prominent branded surface or primary action.
Neutral surfaces (lists, backgrounds) remain on the default theme.
