# Gerichte Feature – Analyse & ToDos (Frontend & Backend)

Status-Legende:
- [ ] nicht gestartet
- [~] in Arbeit
- [x] abgeschlossen

---

## Kurzfazit (Top Issues)
1) `nutrition_recipes` fehlen komplett in den Firestore-Rules → aktuell weder les- noch schreibbar (Permission-Denied) bzw. ungeschützt, je nach Umgebung. **Blocker.**
2) Rezepte werden mit `updatedAt` als String gespeichert; restliche Nutrition-Daten nutzen `timestamp` → Inkonsistenz, Sortierung/Validation schwer.
3) Rezept → Eintrag: Router reicht `recipe` nicht weiter, Quick-Add speichert volle Rezept-Makros als „pro 100g“ mit fixer `qty=100` → Makros/Gramm falsch und Portionierung nicht möglich.
4) Rezept zu Mahlzeit hinzufügen schreibt für jede Zutat einzeln (`addEntry` pro Zutat) und triggert pro Zutat einen Year-Summary-Write → Write-Amplification bei großen Rezepten.
5) Keine Tests/Validierung: Zutatenliste unlimitiert validiert, keine Feld-Typ-Checks im Backend, keine UI-Suche/Filter/Paging bei Rezepten.

---

## Datenmodell & Backend (Firestore)
- [ ] Rules ergänzen: `match /users/{uid}/nutrition_recipes/{id}` mit Owner-Check, max Zutaten (z.B. 50), Feldtypen (`name` string >0, `ingredients` list), `grams` > 0, Makros >= 0, `updatedAt` timestamp optional.
- [ ] Migration: `updatedAt` auf `Timestamp`; bestehende String-Werte konvertieren (Small script / one-off Cloud Function).
- [ ] Optional: Feld `totalGrams` + `per100` Server-seitig speichern, um Client-Rechnung zu validieren.
- [ ] Index prüfen: aktuell nur `orderBy('name')` → kein zusätzlicher Index nötig, aber nach Rule-Änderung verifizieren.
- [ ] Write-Pfad optimieren: Sammel-Schreibpfad für „Rezept zu Mahlzeit“ (berechne Gesamt-Log einmal, schreibe Log + Year-Summary einmal).
- [ ] Consistency: `nutrition_logs.entries.qty` wird genutzt, aber Rezepte setzen `qty=100` fix; Backend sollte `qty` optional akzeptieren aber >=1 validieren.

## Frontend – Gerichte UX/Flows
- [ ] Router-Fix: `NutritionRecipeListScreen` → `AppRouter.nutritionEntry` muss `initialRecipe` weiterreichen; `NutritionEntryScreen` soll Zutaten anzeigen und Makros aus Zutaten normalisiert setzen.
- [ ] Quick-Add korrigieren: Statt „Makros gesamt als per100“ -> entweder Portion = 1 Rezept (qty=1, Makros=gesamt) ODER per100 korrekt normalisieren (`sumMakros * 100 / totalGrams`).
- [ ] Portionierungs-Flow: Im Recipe-Selection Dialog Faktor/Portion wählen (z.B. 0.5 / 1 / 2 Portionen) und Makros skalieren; UI-Slider oder Stepper.
- [ ] „Gericht zu Mahlzeit hinzufügen“ sollte `addRecipeToMeal` nutzen (ein Write pro Rezept) oder neuen Batch-Weg; Quick-Add Button daran koppeln.
- [ ] Rezept-Liste: Suchfeld/Filter, optional Pagination (FireStore `limit`), sort order (`updatedAt` desc) falls viele Rezepte.
- [ ] Edit-Screen: Gesamtgramm/Portion anzeigen, Warnung bei fehlendem Namen/Zutaten, Loading/Error-Handling verbessern (Snackbar/State).
- [ ] Offline/Retry: Rezepte-Liste nutzt einmaliges `loadRecipes`; ggf. Refresh/Retry-Button und Loading-State anzeigen.

## Daten- und Kostenaspekte
- [ ] Write-Amplification entschärfen (siehe Backend): einmaliger Log-Write je Rezept statt n Writes.
- [ ] Optional Caching: Rezepte lokal cachen (SharedPreferences/Hive) um Reads zu sparen und Offline-UX zu verbessern.

## Tests & Qualität
- [ ] Unit-Tests: `NutritionRepository.fetch/upsert/deleteRecipe`, `addRecipeToMeal` (Skalierung, Limit 50 Zutaten, Write-Zahl).
- [ ] Widget-Tests: Recipe List (Quick-Add, Edit-Navigation), Recipe Edit (Zutat hinzufügen/ändern/löschen), Entry Screen mit `initialRecipe` (Makro-Berechnung richtig?).
- [ ] Integration-Test (Firebase Emulator): Rules-Coverage für `nutrition_recipes`, Schreibblock bei invaliden Feldern/zu vielen Zutaten.

## Rollout / Migration
- [ ] Regeln deployen + Emulator-Test.
- [ ] Daten-Migration (updatedAt String → Timestamp) vor App-Release ausführen.
- [ ] App-Update mit Router/Quick-Add-Fix ausrollen; danach Monitoring auf Firestore-Write-Volumen (Rezepte) einschalten.

---

## Offene Fragen
- Portionierung: Soll 1 Portion = gesamtes Rezept sein oder 100 g? (entscheidet Datenmodell und Quick-Add-Berechnung)
- Maximale Zutatenzahl je Rezept? (Performance/UX)
- Sollen Rezepte zwischen Nutzern teilbar sein? (würde Sammlung + Rules ändern)
