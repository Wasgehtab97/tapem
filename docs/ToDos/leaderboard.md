# Leaderboard Rework Roadmap (LoL-inspired)
End-to-end plan to align our leaderboard to the League of Legends look & feel while keeping performance and UX solid. Work through phases in order; each has a checklist to gate progression.

## Phase 0 – Alignment & Scope
- [ ] Review current UX flows (Studio/Friends, Season chips, Level chips, Device lists, Powerlifting) and freeze scope for v1.
- [ ] Approve target visual references (crest style, table layout, banner treatment, colors, typography).
- [ ] Decide rollout mechanism (feature flag / remote config key).

## Phase 1 – Visual System Definition
- [ ] Define tier system: names, XP/level thresholds, color ramps, accent metals (bronze → challenger).
- [ ] Typography stack: display serif/condensed for headers + grotesk for body; confirm available fonts or embed.
- [ ] Token spec: strokes, glows, gradients, shadows, corner radii per surface (table, banner, chips).
- [ ] Document spacing, icon sizes, and dividers for table layout.

## Phase 2 – Assets Production
- [ ] Create/export crest SVG/PNG per tier + monochrome variants for low-state.
- [ ] Produce vignette/nebula background and subtle particle overlay (mobile-friendly sizes).
- [ ] Export underlay/overlay gradients for selected row and active chips.
- [ ] Add assets to `assets/` and register in `pubspec.yaml`.

## Phase 3 – Theme & Tokens
- [ ] Extend `AppBrandTheme` / design tokens with tier palettes, strokes, glows, and vignette references.
- [ ] Add helper API: `tierColors(tier)`, `tierCrest(tier)`, `tableStroke(tier)`.
- [ ] Wire fonts into theme (GoogleFonts or bundled assets) and test fallback.

## Phase 4 – Layout Refactor (LeaderboardScreen)
- [ ] Replace card stack with table-like layout (Rank | Name | XP | Level/LP) + thin dividers.
- [ ] Add right-side “banner” column showing current user tier, crest, LP/XP to next tier.
- [ ] Redesign chips: slim, underlined, tier-colored; reduce pill padding.
- [ ] Keep Studio/Friends + Season tabs functional; ensure empty/loading states match new style.

## Phase 5 – Device Leaderboards
- [ ] Align `DeviceXpLeaderboardScreen` and rank-provider list to the same table styling and ordering (level desc, xp desc).
- [ ] Add row highlight for current user; add XP-to-next-level microbar.
- [ ] Unify filters (showInLeaderboard/admin exclusion) across stream and fetch variants.

## Phase 6 – Powerlifting Leaderboard
- [ ] Apply new table skin; add crest/banner using strength tier mapping (totalE1rmKg → tier).
- [ ] Include per-lift columns with consistent formatting; highlight self row.

## Phase 7 – Motion & Feedback
- [ ] Add gradient sweep on row select/refresh (AnimatedContainer/ShaderMask).
- [ ] Rank change feedback (+Δ/-Δ badge, brief upward/downward motion).
- [ ] Pull-to-refresh animation using crest spin or gem pulse.

## Phase 8 – Data & Performance
- [ ] Add `username` denormalization to leaderboard docs or introduce a small cache to remove N+1 user fetches.
- [ ] Add query limits/pagination for large gyms; keep top N + self.
- [ ] Ensure ordering consistency (level desc, xp desc) across all views.
- [ ] Verify Firestore indexes for new queries.

## Phase 9 – Accessibility & Localization
- [ ] Color-contrast check for dark background + gold/teal accents.
- [ ] Support RTL and long names; truncate with ellipsis.
- [ ] Localize new copy (tier labels, LP/XP strings, tooltips).

## Phase 10 – QA & Analytics
- [ ] Snapshot tests for widgets with new theme tokens.
- [ ] Golden tests for key screens (Studio, Friends, Device, Powerlifting).
- [ ] Instrument analytics: screen views, tab switches, refreshes, row taps, CTA to “train now”.
- [ ] Capture performance (frame timings) on mid/low devices.

## Phase 11 – Rollout
- [ ] Behind feature flag; internal dogfood → pilot gym → full release.
- [ ] Release notes + in-app “What’s new” highlight.
- [ ] Post-launch bug sweep and metric review (engagement with leaderboard).

## Phase 12 – Polish & Future
- [ ] Add seasonal split banners and time-to-reset countdown.
- [ ] Optional prestige borders for top 1/0.1%.
- [ ] Experiment with dynamic particles tied to rank changes.

## File Touchpoints (for implementation)
- UI: `lib/features/xp/presentation/screens/leaderboard_screen.dart`, `lib/features/rank/presentation/screens/rank_screen.dart`, `lib/features/xp/presentation/screens/device_xp_leaderboard_screen.dart`, `lib/features/rank/presentation/screens/powerlifting_leaderboard_screen.dart`
- Styling: `lib/core/theme/design_tokens.dart`, `lib/core/theme/app_brand_theme.dart`, `lib/features/rank/presentation/device_level_style.dart`
- Data consistency: `lib/features/rank/data/sources/firestore_rank_source.dart`, `lib/core/providers/rank_provider.dart`, `lib/features/xp/presentation/screens/device_xp_leaderboard_screen.dart`
- Assets & fonts: `assets/` and `pubspec.yaml`
