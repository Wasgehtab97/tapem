# Avatars V2 Emulator Tests

This suite exercises Firestore security rules and Cloud Functions for the Avatars V2 feature using the Firebase Emulator Suite.

## Test Matrix

### Rules
- Gym catalog read/write permissions
- Global catalog readability
- Inventory read / client write deny
- Equip owner-write

### Functions
- Default avatar bootstrap on user create
- Admin grant with tenant isolation and idempotence
- XP, Challenge and Event based grants
- Mirror of equipped avatar into public profile

## Running Tests

Start via npm scripts which launch the emulator automatically:

```bash
npm run test:rules   # Firestore rules tests
npm run test:functions   # Functions tests with coverage
npm run test:all     # Run both suites
```

## Flags

Functions tests stub Remote Config flags so `avatars_v2_enabled` and `avatars_v2_grants_enabled` are ON.

## Notes

The emulator is reset between tests to guarantee determinism. Challenge/event scenarios use synthetic windows and IDs as described in the fixtures.
