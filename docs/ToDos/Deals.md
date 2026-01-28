# Deals Feature - Checklist Roadmap (Firestore/Flutter)

Ziel: Das bestehende Placeholder-Feature "Deals" in einen voll funktionsfähigen Bereich verwandeln, der echte Angebote von Partnern (z.B. More Nutrition) anzeigt, Rabattcodes bereitstellt und Klicks trackt.

Status-Legende:
- [ ] nicht gestartet
- [~] in Arbeit
- [x] abgeschlossen

---

## Phase 0: Scope und Anforderungen (MUST-HAVE)

### 0.1 Feature-Scope
- [x] **Angebots-Liste**: Darstellung von Deals in einer ansprechenden Liste/Grid.
- [x] **Deal-Details**: Bild, Titel, Beschreibung, Rabattcode, Ablaufdatum, Deeplink.
- [x] **Interaktion**: Code kopieren (Clipboard) und Link öffnen (Browser/App).
- [x] **Tracking**: Klicks auf "Deal ansehen" erfassen (für Partner-Reporting).
- [x] **Beispiel-Content**: Start mit realem Partner "More Nutrition".

### 0.2 Daten-Integrität
- [x] Deals werden serverseitig (Firestore) gespeichert, nicht hardcoded in der App.
- [x] Admin-tragene Pflege (kein User-Generated Content).

---

## Phase 1: Datenmodell (Firestore) (MUST-HAVE)

### 1.1 Firestore Collections

- [x] `deals/{dealId}`
  - `title`: string (z.B. "20% auf alles")
  - `description`: string (z.B. "Nutze den Code für maximalen Rabatt...")
  - `partnerName`: string (z.B. "More Nutrition")
  - `partnerLogoUrl`: string (URL zum Logo)
  - `imageUrl`: string (URL zum Produktbild/Banner)
  - `code`: string (z.B. "DANNY20")
  - `link`: string (Affiliate-Link, z.B. "https://more-nutrition.de?ref=...")
  - `category`: string (z.B. "Supplements", "Clothing")
  - `isActive`: bool
  - `priority`: number (für Sortierung: 1 = oben)
  - `validUntil`: timestamp (optional, für Ablaufdatum)
  - `createdAt`: timestamp

- [x] `deals/{dealId}/stats/clicks` (Optional: Subcollection oder Counter)
  - Einfacherer Ansatz für MVP: `deals/{dealId}` hat ein Feld `clickCount` (atomar inkrementiert) ODER eigene Collection `analytics/deals/clicks/{clickId}` für detailliertes Tracking (wann, wer).
  - **Entscheidung MVP**: `clickCount` field im Deal-Dokument inkrementieren (weniger Reads/Writes) ODER separate `analytics_deals` Collection.
  - *Empfehlung*: Separate Collection `gyms/{gymId}/analytics/deals` oder global `analytics/deals` um Writes auf Deal-Dokument zu minimieren.

---

## Phase 2: Security Rules (MUST-HAVE)

### 2.1 Rules definieren
- [x] `match /deals/{dealId}`
  - `allow read`: if `request.auth != null` (Jeder eingeloggte User sieht Deals).
  - `allow write`: if `isAdmin()` (Nur Admins dürfen Deals anlegen/bearbeiten).

---

## Phase 3: Admin / Content Pflege (MUST-HAVE)

### 3.1 Datensatz anlegen (Seeding)
- [x] Skript oder Admin-UI bauen, um den ersten Deal ("More Nutrition") anzulegen.
  - Alternativ: Manuell via Firebase Console für den ersten Test.
  - Langfristig: "Deals verwalten" im Admin-Dashboard der App (`AdminDashboardScreen`).

---

## Phase 4: Frontend Implementierung (Flutter) (MUST-HAVE)

### 4.1 Data Layer
- [x] `Deal` Model erstellen (`freezed` oder `json_serializable`).
- [x] `DealsRepository` erstellen (Firestore Stream/Future).
- [x] `DealsProvider` (Riverpod) für State Management (Loading, Data, Error).

### 4.2 UI Components
- [x] `DealCard` Widget entwickeln:
  - Hochwertiges Design (gemäß "Premium"-Anspruch).
  - Anzeige von Bild, Logo, Titel, Rabattcode.
  - Button "Code kopieren".
  - Button "Zum Shop" (öffnet Link).
- [x] `DealsScreen` umbauen:
  - `ListView` / `GridView` basierend auf `DealsProvider`.
  - Loading-States (Shimmer) und Error-Handling.
  - Empty-State (falls keine aktiven Deals).

### 4.3 Logik & Interaktion
- [x] `Clipboard`-Funktion: "Code kopieren" -> Snackbar Feedback ("Code 'DANNY20' kopiert").
- [x] `url_launcher`: Link öffnen (externer Browser).
- [x] Klick-Tracking: Beim Klick auf "Zum Shop" Event an Firestore senden.

---

## Phase 5: Analytics & Tracking (OPTIONAL für MVP)

### 5.1 Klick-Tracking
- [ ] Service `AnalyticsService.trackDealClick(dealId)`.
- [ ] Firestore Write (z.B. `analytics_deals` add document).

---

## Phase 6: Rollout & Test

### 6.1 Testing
- [ ] Integrationstest: Deal im Backend anlegen -> erscheint in App.
- [ ] Link-Test: Führt der Link zum korrekten Shop?
- [ ] Code-Test: Wird der richtige Code kopiert?

### 6.2 Launch
- [ ] Feature Flag `enableDeals` (falls gewünscht für schrittweisen Rollout).
- [ ] Deployment (iOS/Android).
