gyms/{gymId}/config           ← Branding-Daten (Farben, Logo-URL, Name)
gyms/{gymId}/devices/{id}     ← Geräte-Metadaten, secret codes
gyms/{gymId}/training_history/{sessionId}
gyms/{gymId}/users/{userId}
gyms/{gymId}/affiliateOffers/{offerId}
...

### Users

- **users/{userId}** – zentrales Profil-Dokument.
  - `email` und `emailLower` für case-insensitive Suche
  - `gymCodes`: Liste beigetretener Gyms
  - `role`, `createdAt`, `showInLeaderboard`
- **gyms/{gymId}/users/{userId}** – Referenz im jeweiligen Gym für schnelle Gym-Abfragen
  - enthält nur `role` und `createdAt`
