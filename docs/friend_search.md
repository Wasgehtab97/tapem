# Friend Username Search

The app searches in the `publicProfiles` collection. Documents mirror a subset of `users/*` fields via Cloud Functions (`mirrorPublicProfile`) and contain:

- `username`
- `usernameLower` (lower‑cased)
- `primaryGymCode`
- `avatarUrl`
- `createdAt`

## Query

```dart
orderBy('usernameLower')
  .startAt([prefix])
  .endAt([prefix + '\u{f8ff}'])
```

- Input is trimmed and lower‑cased.
- Queries fire only for inputs with at least **2 characters**.
- Results are limited to 20 items.

## Testing

1. Ensure users have public profiles (Function + backfill).
2. Run the app, open the Friends tab → Search.
3. Enter a prefix like `ad` or `the` (lowercase). Matching users should appear.
4. Try full usernames to verify exact matches.

Look out for:

- Case insensitivity (always lowercase).
- Prefix behaviour (`the` matches `themain`).
- Debounce delay (~400 ms) before the query fires.

