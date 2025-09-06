# Avatars V2 Rules Tests

Planned emulator test cases:

- **Nicht-Mitglied kann Gym-Katalog nicht lesen.**
- **Mitglied kann Gym-Katalog lesen.**
- **Client kann `users/{uid}/avatarsOwned` nicht schreiben.**
- **Authed Nutzer kann globalen Katalog lesen.**
- **Unangemeldeter Nutzer kann globale Kataloge nicht lesen.**
- **Owner darf `users/{uid}.equippedAvatarRef` setzen/ändern/löschen.**
- **Fremder User darf `equippedAvatarRef` nicht schreiben.**
- **Lesen von `users/{uid}/avatarsOwned` nur durch Owner.**
- **Write auf `users/{uid}/avatarsOwned` bleibt verboten.**
- **Mirror-Trigger aktualisiert `publicProfiles/{uid}` korrekt.**
