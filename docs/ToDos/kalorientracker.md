# Kalorientracker - Checklist Roadmap (Firestore/Flutter)

Ziel: Kalorientracker als neues Feature mit eigener Page integrieren, kostenarm in Firestore, sauberer UX-Flow, klare Migration und Monitoring.

Status-Legende:
- [ ] nicht gestartet
- [~] in Arbeit
- [x] abgeschlossen

---

## Phase 0: Scope und Produkt-Entscheidungen (MUST-HAVE)

### 0.1 Feature-Scope definieren
- [ ] MVP: Tagesziel + Tageslog + Jahreskalender (unter/on/ueber Ziel)
- [ ] Optional: Wochen-Templates, Makro-Ziele, Barcode-Scan
- [ ] Optional: Produktdaten-Cache (lokal + Firestore)
- [ ] Optional: Fotos/Notizen pro Tag (nur wenn noetig)

### 0.2 UX-Flow festlegen
- [ ] Neuer Tab oder eigener Screen mit Route `nutrition`
- [ ] Tagesansicht: Ziel + Eingaben + Tagesstand
- [ ] Kalenderansicht: Jahreskalender mit Statusfarben
- [ ] Eintrag erstellen: Scan -> Produkt -> Menge -> speichern
- [ ] Fallback: Manuelle Eingabe ohne Barcode

---

## Phase 1: Datenmodell (MUST-HAVE)

### 1.1 Firestore Collections

- [ ] `users/{uid}/nutrition_goal_templates/{templateId}`
  - `{ name, kcal, macros: { protein, carbs, fat }, weekdays: [1-7], isActive }`

- [ ] `users/{uid}/nutrition_goals/{yyyyMMdd}`
  - `{ kcal, macros: { protein, carbs, fat }, source: "template|manual", updatedAt }`

- [ ] `users/{uid}/nutrition_logs/{yyyyMMdd}`
  - `{ date, total: { kcal, protein, carbs, fat }, entries: [ ... ], status: "under|on|over", updatedAt }`
  - entries (optional, begrenzen): `{ name, kcal, protein, carbs, fat, barcode, qty }`

- [ ] `users/{uid}/nutrition_year_summary/{yyyy}`
  - `{ days: { "2025-02-14": "under", "2025-02-15": "over", ... } }`

- [ ] `nutrition_products/{barcode}`
  - `{ name, kcalPer100, proteinPer100, carbsPer100, fatPer100, updatedAt }`

### 1.2 Entscheidung: entries im Tagesdoc
- [ ] Standard: entries im Tagesdoc (einfach, kostenguensig)
- [ ] Nur wenn notwendig: `nutrition_entries` als eigene Collection
- [ ] Max Eintraege pro Tag begrenzen (z.B. 50)

---

## Phase 2: Firestore Rules und Indizes (MUST-HAVE)

### 2.1 Security Rules
- [ ] `users/{uid}/nutrition_*` nur Owner read/write
- [ ] `nutrition_products/{barcode}` read fuer authenticated
- [ ] `nutrition_products/{barcode}` write nur owner oder admin/Function
- [ ] Validierung: kcal und macros >= 0, limitierte Groesse der entries

### 2.2 Indizes
- [ ] Keine Collection-Queries noetig (doc reads)
- [ ] Falls Reports pro Range: composite index fuer `nutrition_logs` by date

---

## Phase 3: Writes/Reads-Optimierung (MUST-HAVE)

### 3.1 Tageslog Update
- [ ] Schreibpfad: 1 Update pro Eintrag (merge)
- [ ] total.* inkrementieren, status neu berechnen
- [ ] Bei Statuswechsel `nutrition_year_summary/{yyyy}` aktualisieren

### 3.2 Jahreskalender
- [ ] Jahreskalender holt 1 Doc (`nutrition_year_summary/{yyyy}`)
- [ ] Kein Scan von 365 Tagesdocs

### 3.3 Barcode Cache
- [ ] Lokal zuerst suchen (Hive/SQLite)
- [ ] Nur bei Miss Firestore lesen
- [ ] Bei manueller Eingabe Firestore einmalig schreiben

---

## Phase 4: Flutter-Implementierung (MUST-HAVE)

### 4.1 Routing und Navigation
- [ ] Neue Route `nutrition`
- [ ] Einbindung in BottomNav oder Drawer
- [ ] Deep Link optional

### 4.2 UI Screens
- [ ] Tagesansicht: Ziel, Fortschritt, Eintraege, CTA "Hinzufuegen"
- [ ] Kalenderansicht: Jahresgrid mit Farblegende
- [ ] Entry Flow: Scan -> Produkt -> Menge -> bestaetigen
- [ ] Goals Editor: Tagesziel/Makros setzen oder Template

### 4.3 State Management
- [ ] Repository Layer fuer `nutrition_*`
- [ ] Lokal-Caching fuer Products
- [ ] Optimistisch schreiben (UI sofort aktualisieren)

---

## Phase 5: Backend/Functions (OPTIONAL)

### 5.1 Cloud Functions (nur wenn serverseitige Validierung gewuenscht)
- [ ] onWrite nutrition_logs -> recalculates totals/status (optional)
- [ ] onWrite nutrition_products -> normalize values (optional)

---

## Phase 6: Analytics und Monitoring (MUST-HAVE)

### 6.1 Kostenkontrolle
- [ ] Firebase Budget Alerts fuer Reads/Writes setzen
- [ ] In-App Debug-Zaehler fuer Reads/Writes (dev)

### 6.2 Produktnutzung
- [ ] Track "daily entry count" (lokal oder Analytics)
- [ ] Track "barcode cache hit rate"

---

## Phase 7: Testplan (MUST-HAVE)

### 7.1 Unit Tests
- [ ] status Berechnung: under/on/over
- [ ] totals Berechnung aus entries
- [ ] template -> goal copy

### 7.2 Integration Tests
- [ ] Tageslog schreiben und lesen
- [ ] Jahreskalender summary aktualisieren
- [ ] Barcode cache hit/miss

---

## Phase 8: Rollout (MUST-HAVE)

### 8.1 Feature Flag
- [ ] Nutrition feature togglable
- [ ] Rollout in Wellen (beta users)

### 8.2 Data Safety
- [ ] Backward compatibility (alte Clients ignorieren neue Collections)
- [ ] Fehler-Handling bei fehlenden Goals/Logs

---

## Appendix: Beispiel-Queries

- Tageslog lesen:
  - `users/{uid}/nutrition_logs/{yyyyMMdd}` (doc read)
- Tagesziel lesen:
  - `users/{uid}/nutrition_goals/{yyyyMMdd}` (doc read)
- Jahreskalender:
  - `users/{uid}/nutrition_year_summary/{yyyy}` (doc read)
- Barcode:
  - `nutrition_products/{barcode}` (doc read)
