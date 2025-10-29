# Onboarding Funnel Feature

## Overview
The onboarding funnel helps studio operators monitor the activation of new app members. It exposes the following capabilities:

- Dedicated dashboard card on the reporting screen (admin only) that links to the onboarding funnel.
- Overview of the total number of registered app members for the selected gym.
- Search flow for four-digit member numbers that reveals the associated profile, registration date, onboarding assignment date, and training-day count.
- Deterministic assignment of four-digit member numbers (0001–9999) for each gym during membership creation.

All strings are localized and the UI follows the existing design system components.

## Firestore Data Model

```
/gyms/{gymId}/users/{userId}
  memberNumber: string  // four-digit identifier per gym
  onboardingAssignedAt: timestamp  // when the number was assigned

/gyms/{gymId}/config/onboarding
  nextMemberNumber: number  // next available sequence value
  lastAssignedNumber: string  // last issued member number
  limitReachedAt: timestamp  // present when the range is exhausted
  updatedAt: timestamp  // last mutation time

/users/{userId}
  username: string
  email: string
  createdAt: timestamp

/users/{userId}/trainingDayXP/{dayKey}
  ... // existing XP and training day aggregation data
```

### Member Number Assignment
- Implemented directly in the Flutter app when memberships are created via `FirestoreMembershipService.ensureMembership`.
- Logic:
  1. Abort if the membership document already contains a `memberNumber` (idempotent).
  2. Read `/gyms/{gymId}/config/onboarding.nextMemberNumber` inside a Firestore transaction.
  3. If the counter is absent, default to `1`.
  4. Reject assignments beyond `9999` and mark the config with `limitReachedAt`.
  5. Persist the formatted number (`padStart(4, '0')`) on the membership document together with `onboardingAssignedAt`.
  6. Increment and write `nextMemberNumber` and `lastAssignedNumber` back to the config document.
- All writes happen inside a single Firestore transaction on the client to avoid race conditions while respecting security rules.

## Flutter Architecture

### Data Access Layer
`OnboardingFunnelRepository` ( `lib/features/onboarding_funnel/data`) encapsulates all Firestore reads:
- `getRegisteredMemberCount` returns the total membership count using aggregate queries with a `get()` fallback for emulators/tests.
- `getMemberByNumber` resolves the member profile, registration timestamp, onboarding timestamp, and training-day count.

### State Management
`OnboardingFunnelProvider` ( `lib/features/onboarding_funnel/presentation/providers`) exposes:
- Count loading state (`isLoadingCount`, `memberCount`, `countErrorMessage`).
- Search state with result payload, last query, and error types (`notFound`, `failure`).
- `ensureInitialized` resets state per gym and hydrates the initial count.

### UI
- `OnboardingFunnelScreen` hosts the page, renders the count card, search form, and results.
- `OnboardingMemberCard` displays member details and offers a tap target that opens a detail sheet.
- Entry point via a new `BrandActionTile` on the report dashboard (admins only).
- Routing provided through `AppRouter.onboardingFunnel`; protected by `restrictedRoutesForMembers`.

### Localization
New strings live in `lib/l10n/app_en.arb` and `app_de.arb`. After editing, run:

```bash
flutter gen-l10n
```

## Testing
- Flutter unit tests: repository and provider coverage in `test/features/onboarding_funnel/...`.

## Migration Notes
- For legacy data, run an ad-hoc backfill script that iterates memberships without `memberNumber`, invoking the same transaction logic as the client helper.
- Monitor the `gyms/{gymId}/config/onboarding` document for `nextMemberNumber` approaching 9999 and plan a rollover strategy if a gym ever grows beyond the range.

## Future Enhancements
- Persist drop-off metrics (first scan, third visit, tenth visit) under `/gyms/{gymId}/analytics/onboarding/{userId}` and surface them on the funnel page.
- Add export functionality (CSV) for the onboarding search results.
- Extend the dashboard with charts (e.g., weekly activation counts) once sufficient data exists.
