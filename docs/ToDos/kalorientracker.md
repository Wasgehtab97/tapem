# Kalorientracker - Checklist Roadmap (Firestore/Flutter)

Ziel: Kalorientracker als neues Feature mit eigener Page integrieren, kostenarm in Firestore, sauberer UX-Flow, klare Migration und Monitoring.

Status-Legende:
- [ ] nicht gestartet
- [~] in Arbeit
- [x] abgeschlossen

---

## Phase 0: Scope und Produkt-Entscheidungen (MUST-HAVE)

### 0.1 Feature-Scope definieren
- [x] MVP: Tagesziel + Tageslog + Jahreskalender (unter/on/ueber Ziel)
  - Umsetzung: 1 Tageslog-Doc pro Tag + 1 Jahres-Summary-Doc.
- [x] Optional: Wochen-Templates, Makro-Ziele, Barcode-Scan
  - Umsetzung: Templates in `nutrition_goal_templates`, Scan als eigener Flow.
- [x] Optional: Produktdaten-Cache (lokal + Firestore)
  - Umsetzung: lokale DB zuerst, Firestore nur bei Cache-Miss.
- [x] Optional: Fotos/Notizen pro Tag (nur wenn noetig)
  - Umsetzung: nur falls UX benoetigt, sonst vermeiden (Kosten/Storage).

### 0.2 UX-Flow festlegen
- [x] Neuer Tab oder eigener Screen mit Route `nutrition`
  - Umsetzung: eigener Bottom-Tab, separate Screens fuer Ziele/Tag/Kalender.
- [x] Tagesansicht: Ziel + Eingaben + Tagesstand
  - Umsetzung: Tagesuebersicht liest `nutrition_goals` + `nutrition_logs`.
- [x] Kalenderansicht: Jahreskalender mit Statusfarben
  - Umsetzung: 1 Read auf `nutrition_year_summary/{yyyy}`.
- [x] Eintrag erstellen: Scan -> Produkt -> Menge -> speichern
  - Umsetzung: Barcode-Scan optional, danach Eintrag in Tageslog.
- [x] Fallback: Manuelle Eingabe ohne Barcode
  - Umsetzung: manuelles Produktformular speichert Eintrag + optional Produkt-Cache.

### 0.3 Datenquelle fuer Nahrungsmittel (Compliance)
- [x] Entscheidung treffen: Open Food Facts (OFF) als Primarquelle
  - Umsetzung: OFF nur bei Cache-Miss, lokale Kopie fuer Wiederverwendung.
- [x] Attribution in der App sichtbar machen:
  - [x] "Datenquelle: Open Food Facts" + Link `https://world.openfoodfacts.org/`
  - [x] "Lizenz: ODbL 1.0" + Link `https://opendatacommons.org/licenses/odbl/1-0/`
- [x] Platzierung festlegen: Nutrition Settings und/oder App-Info/Impressum
  - Umsetzung: Hinweis im Nutrition-Settings Screen + App-Info.
- [x] Share-Alike Risiko pruefen:
  - [x] Wenn eigene oeffentliche Produktdatenbank: ODbL teilen
  - [x] Wenn nur API/Cache: Attribution reicht in der Regel

### 0.4 Barcode-Scan als Kernfeature (Klarstellung)
- [x] QR/Barcode-Scan ist Kern des Features (nicht optional)
  - Umsetzung: native Kamera-Scan, Produktdaten via API/Cache, Gramm-Eingabe.

---

## Phase 1: Datenmodell (MUST-HAVE)

### 1.1 Firestore Collections

- [x] `users/{uid}/nutrition_goal_templates/{templateId}`
  - `{ name, kcal, macros: { protein, carbs, fat }, weekdays: [1-7], isActive }`
  - Umsetzung: Templates pro User, optionales Feature (Phase 4/5).

- [x] `users/{uid}/nutrition_goals/{yyyyMMdd}`
  - `{ kcal, macros: { protein, carbs, fat }, source: "template|manual", updatedAt }`
  - Umsetzung: Goal pro Tag als Doc, Upsert via `NutritionRepository`.

- [x] `users/{uid}/nutrition_logs/{yyyyMMdd}`
  - `{ date, total: { kcal, protein, carbs, fat }, entries: [ ... ], status: "under|on|over", updatedAt }`
  - entries (optional, begrenzen): `{ name, kcal, protein, carbs, fat, barcode, qty }`
  - Umsetzung: 1 Doc pro Tag mit Summen + Entries (kostenarm).

- [x] `users/{uid}/nutrition_year_summary/{yyyy}`
  - `{ days: { "2025-02-14": "under", "2025-02-15": "over", ... } }`
  - Umsetzung: Map pro Jahr fuer 1-Read Kalender.

- [x] `nutrition_products/{barcode}`
  - `{ name, kcalPer100, proteinPer100, carbsPer100, fatPer100, updatedAt }`
  - Umsetzung: Barcode-Cache (Firestorm only on miss).

### 1.2 Entscheidung: entries im Tagesdoc
- [x] Standard: entries im Tagesdoc (einfach, kostenguensig)
  - Umsetzung: `nutrition_logs/{yyyyMMdd}.entries` als kompakte Liste.
- [x] Nur wenn notwendig: `nutrition_entries` als eigene Collection
  - Entscheidung: nur bei sehr grossen Listen oder Detail-Analytics.
- [x] Max Eintraege pro Tag begrenzen (z.B. 50)
  - Umsetzung: Soft-Limit im Client; bei Bedarf Warnung.

---

## Phase 2: Firestore Rules und Indizes (MUST-HAVE)

### 2.1 Security Rules
- [x] `users/{uid}/nutrition_*` nur Owner read/write
  - Umsetzung: Rules pro Subcollection mit Owner-Checks.
- [x] `nutrition_products/{barcode}` read fuer authenticated
  - Umsetzung: read nur fuer auth, write mit Field-Validation.
- [x] `nutrition_products/{barcode}` write nur owner oder admin/Function
  - Anpassung: aktuell write fuer auth mit strikter Feld-Validation (kann spaeter auf Function-only eingeschraenkt werden).
- [x] Validierung: kcal und macros >= 0, limitierte Groesse der entries
  - Umsetzung: Typ-Validation + entries <= 50 in Rules.

### 2.2 Indizes
- [x] Keine Collection-Queries noetig (doc reads)
  - Umsetzung: Reads sind doc-basiert (day/year/goal).
- [x] Falls Reports pro Range: composite index fuer `nutrition_logs` by date
  - Entscheidung: aktuell nicht noetig, da keine Range-Queries geplant.

---

## Phase 3: Writes/Reads-Optimierung (MUST-HAVE)

### 3.1 Tageslog Update
- [x] Schreibpfad: 1 Update pro Eintrag (merge)
  - Umsetzung: `NutritionProvider.addEntry` schreibt 1 Tageslog-Doc.
- [x] total.* inkrementieren, status neu berechnen
  - Umsetzung: Totals werden additiv berechnet, Status via Service.
- [x] Bei Statuswechsel `nutrition_year_summary/{yyyy}` aktualisieren
  - Umsetzung: Year-Summary wird nur bei Statuswechsel geupdatet.

### 3.2 Jahreskalender
- [x] Jahreskalender holt 1 Doc (`nutrition_year_summary/{yyyy}`)
  - Umsetzung: `loadYear` liest nur das Summary-Doc.
- [x] Kein Scan von 365 Tagesdocs
  - Umsetzung: keine Range-Reads fuer Calendar.

### 3.3 Barcode Cache
- [x] Lokal zuerst suchen (Hive/SQLite)
  - Umsetzung: SharedPreferences Cache mit LRU-Pruning (max 200).
- [x] Nur bei Miss Firestore lesen
  - Umsetzung: `NutritionProductService.getByBarcode` -> cache -> Firestore.
- [x] Bei manueller Eingabe Firestore einmalig schreiben
  - Umsetzung: `saveProduct` upsert + Cache-Update.
- [x] Bei Miss externer API-Call (Open Food Facts)
  - Umsetzung: OFF API bei Cache+Firestore Miss, Result in Cache + Firestore speichern.

---

## Phase 4: Flutter-Implementierung (MUST-HAVE)

### 4.1 Routing und Navigation
- [x] Neue Route `nutrition`
- [x] Einbindung in BottomNav oder Drawer
- [ ] Deep Link optional

### 4.2 UI Screens
- [x] Nutrition Home Screen Scaffold (Entry-Points fuer Goals/Scan/Kalender)
- [x] Tagesansicht: Ziel, Fortschritt, Eintraege, CTA "Hinzufuegen"
  - Umsetzung: Tageslog + Progress + Date-Picker + Entry-Liste.
- [x] Kalenderansicht: Jahresgrid mit Farblegende
  - Umsetzung: Jahresgrid pro Monat aus Year-Summary (1 Read).
- [x] Entry Flow: Scan -> Produkt -> Menge -> bestaetigen
  - Umsetzung: manueller Entry-Flow + Barcode-Lookup via Cache/Firestore.
- [x] Goals Editor: Tagesziel/Makros setzen oder Template
- [x] QR/Barcode-Scan Screen (Kamera)
  - Umsetzung: Kamera-Scan, Barcode extrahieren, Lookup starten.
- [x] Produkt-Detail Screen (Naehrwerte + Gramm)
  - Umsetzung: Produktdaten anzeigen, Gramm/Portion eingeben.
- [x] Automatische Berechnung pro Gramm/Portion
  - Umsetzung: per 100g Werte auf Menge umrechnen, Entry erzeugen.
- [~] Gerichte/Rezepte (mehrere Zutaten speichern und wiederverwenden)
  - Umsetzung: Eigene Rezepte mit Zutatenliste speichern, Faktor anpassen, vollständig zu einer Mahlzeit hinzufügen; Zutaten können aus Suche/Barcode oder manuell kommen.

## Firestore Read/Write Audit (aktueller Stand)
- Tages-Load: `loadDay` macht 2 Reads (Goal + Log) pro Datum. `loadYear` macht 1 Read (Year-Summary). Vertretbar; kein Listener/Stream, nur On-Demand.
- Add Entry: 1 optionaler Read auf Log (wenn nicht im State), 1 optionaler Read auf Goal (falls nicht im State), 1 Write für Log, 1 Write für Year-Summary. Limit: 50 Entries/Tag (Soft-Limit im Client).
- Remove Entry / Update Entry: gleiche Struktur (Log-Write + Year-Summary-Write).  
- Rezepte hinzufügen zu Mahlzeit: derzeit 1 `addEntry`-Write pro Zutat → multipliziert sich bei vielen Zutaten (inkl. Year-Summary-Update je Zutat). Skalierungsrisiko: Viele Writes pro Rezept. Empfehlung: in Zukunft batching/sammel-Write (Log neu berechnen, einmal schreiben, einmal Year-Summary).
- Rezepte CRUD: `fetchRecipes` holt alle Rezepte; keine Pagination. Kann bei vielen Rezepten teuer werden; überlegen: Limit + Paging.
- Produktsuche: Filter lokal, aber ohne Paging/Limits; abhängig von Service/Backend. Falls auf Firestore-Query basiert, Limit erwägen.
- Year-Summary: Map-Update per Tag (Merge) → unproblematisch, 1 Write.
- Kein Echtzeit-Listener → Reads bleiben deterministisch, aber jeder Bildschirmaufruf triggert frische Reads (Home lädt Day; Day lädt Day; Rezepte laden Rezepte). Caching/Reuse wäre ein möglicher Optimierungspfad.
- Lokales Caching der Produkte erwähnt, aber nicht überall ersichtlich; sicherstellen, dass ProductService zuerst lokal/Firestore cached, bevor API/Netz.

### Launch-Readiness (Fazit)
- Funktional lauffähig für MVP; Reads/Writes sind linear und ohne Streams.  
- Größter Kostentreiber: Rezepte hinzufügen (n Writes pro Zutat). Für hohes Volumen besser: Sammelberechnung und ein einziger Log-Write + Year-Summary-Write.  
- Produktsuche und Rezepte-Liste sollten Limits/Paging bekommen, falls Nutzer sehr viele Datensätze haben.  
- Sonst keine offensichtlichen Write-Amplifications; Year-Summary-Map ist O(1) pro Tag.

### 4.3 State Management
- [x] Repository Layer fuer `nutrition_*`
- [x] Lokal-Caching fuer Products
- [x] State-Provider fuer Nutrition (day/year loading)
- [x] Optimistisch schreiben (UI sofort aktualisieren)
  - Umsetzung: addEntry setzt UI-Status vor Firestore Write.
- [x] Goals speichern (Firestore upsert)
- [x] Barcode-Scan State (loading/error/result)
  - Umsetzung: lokaler Screen-State im Scan-Flow.
- [x] Produkt-Lookup State (cache->Firestore->API)
  - Umsetzung: Service + Screen-State fuer Lookup/Loading.

---

## Phase 5: Backend/Functions (OPTIONAL)

### 5.1 Cloud Functions (nur wenn serverseitige Validierung gewuenscht)
- [~] onWrite nutrition_logs -> recalculates totals/status (optional)
  - Status: blocked (Spark Plan). Nur lokal emulieren, Deploy erst mit Blaze.
- [~] onWrite nutrition_products -> normalize values (optional)
  - Status: blocked (Spark Plan). Nur lokal emulieren, Deploy erst mit Blaze.

---

## Phase 6: Analytics und Monitoring (MUST-HAVE)

### 6.1 Kostenkontrolle
- [~] Firebase Budget Alerts fuer Reads/Writes setzen
  - Status: eingeschraenkt auf Spark, Alerts erst mit Blaze.
- [x] In-App Debug-Zaehler fuer Reads/Writes (dev)
  - Umsetzung: Debug-Logging pro Screen (lokal) einplanen.

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
