# Session End Fixes (Launch Readiness)

Stand: 2026-02-14
Scope: Session-Start/SetDone/Save/Finalize/Navigation/Highlights/Sync rund um Training-Ende.

## Priorisierte offene Fehler

### 1) Sync-Jobs schlagen mit `permission-denied` fehl und bleiben als Dead-Letter liegen (P0)
Beobachtung aus Logs:
- Wiederholt: `Failed to process job ... [cloud_firestore/permission-denied]`
- Danach: `exceeded retry limit, skipping`
- Queue wächst weiter (z.B. 6 -> 11 Jobs)

Risiko:
- Lokal gespeichert, aber Cloud-Daten inkonsistent.
- Historie/Rank/Community können zwischen Geräten auseinanderlaufen.

Checkliste:
- [x] Fehlerklassen im Sync-Service trennen: `transient` vs `permanent` (permission/rules/config).
- [x] Für `permanent` Job sofort in `dead-letter` überführen (mit Grund + Pfad + Erstauftreten).
- [ ] UI/Dev-Panel: Dead-Letter sichtbar machen (Anzahl + letzte Gründe).
- [ ] Beim Save-Pfad klar markieren: "lokal gesichert, Cloud-Sync blockiert" (nicht stillschweigend).
- [ ] Firestore-Rules + Pfade für Session-Write-Endpunkte prüfen (Dev/Prod getrennt).
- [x] Migrations-/Replay-Command für dead-letter Jobs implementieren (nach Rules-Fix).

Abnahme:
- [ ] Keine endlosen Retry-Loops bei permission-denied.
- [ ] Jobs gehen deterministisch in dead-letter.
- [ ] Nach Rules-Fix lassen sich betroffene Jobs gezielt replayen.

---

### 2) Multi-Session Save schließt nicht deterministisch alle Sessions des Trainingstags (P0)
Beobachtung aus Logs:
- `save_all_candidates total=2 ... attempted=1`
- Danach bleibt Workout-Screen/Workout-Tab sichtbar.

Risiko:
- User denkt "Training beendet", aber noch aktive Session-State-Reste.
- Inkonsistente Navigation und Reaktivierung alter Sessions.

Checkliste:
- [x] Save-Scope explizit definieren: "alle savebaren Sessions des aktiven Tages".
- [x] Nach Save einheitlicher Cleanup-Pfad: offene Session-Einträge schließen + Plan-Kontext bereinigen.
- [x] Fallback-Regel für nicht-savebare Sessions: explizit entscheiden (close/discard/retain) und dokumentieren.
- [x] Controller-API auf einen finalen `endDay()`-Pfad konsolidieren (manual + auto nutzen denselben Pfad).
- [ ] Test: 2+ parallele Sessions, nur 1 savebar, Endzustand ohne Workout-Tab prüfen.

Abnahme:
- [ ] Nach Ende bleibt keine aktive WorkoutDay-Session hängen.
- [ ] Workout-Tab verschwindet zuverlässig, wenn kein aktives Training mehr besteht.

---

### 3) Doppelte Finalize-Ereignisse (`session_finalized` mehrfach) (P0)
Beobachtung aus Logs:
- `session_finalized reason=manualSave ...` kommt mehrfach in kurzem Abstand.

Risiko:
- Doppel-Navigation, doppelte Side-Effects (Analytics, UI-State, Highlights-Trigger).

Checkliste:
- [x] Einen einzigen Finalize-Orchestrator festlegen (Single source of truth).
- [x] Idempotency-Key pro Session-Ende einführen (`finalizeToken`/`sessionId+reason+endMs`).
- [x] Sekundäre/defensive Finalize-Aufrufe in UI-Flows entfernen oder no-op machen.
- [x] Logging präzisieren: `finalize_skipped_duplicate` statt erneutem Finalize.
- [ ] Tests: manual save, auto save, profile stop jeweils genau 1 Finalize-Event.

Abnahme:
- [ ] Pro Endvorgang genau ein Finalize-Event.
- [ ] Keine doppelte Navigation mehr.

---

### 4) Session-Ende navigiert nicht immer auf Profil + Highlights auf Zielseite (P1)
Beobachtung:
- Teilweise bleibt User auf WorkoutDay oder bekommt einen unerwarteten Re-Entry in Workout.

Risiko:
- UX-Bruch und Verwirrung beim Ende.

Checkliste:
- [x] Für manual + auto denselben Navigations-Endpunkt verwenden (`home initialIndex=1`).
- [x] Navigation erst nach erfolgreichem Cleanup aller aktiven Sessions.
- [x] Highlights erst nach Navigation anzeigen (Queue bleibt erhalten, wenn Navigator noch nicht stabil).
- [x] Guard gegen späte Re-Routes auf Workout (stale route args) ergänzen.
- [ ] Testmatrix: App offen im Workout, offen auf Home, Background/Resume, Cold start nach Timeout.

Abnahme:
- [ ] Ende führt immer auf Profilseite.
- [ ] Highlights öffnen konsistent auf Profilseite.

---

### 5) `lastSet` im Finalize bei Manual Save teilweise `null` (P1)
Beobachtung:
- `session_finalized ... lastSet=null` trotz Save mit abgeschlossenen Sätzen.

Risiko:
- Ungenaue Diagnose, potenziell falsche Endzeit in Randfällen.

Checkliste:
- [ ] Sicherstellen, dass jeder Done-Set-Pfad `completedAt` in Coordinator meldet.
- [ ] Beim Manual Save fehlendes `lastSet` aus Session-Daten deterministisch recovern.
- [ ] Endzeit-Regeln dokumentieren: manual vs auto.
- [ ] Test: Save nach mehreren SetDone-Pfaden (markSetDone, completeAllFilledNotDone, etc.).

Abnahme:
- [ ] `lastSet` ist bei vorhandenen Done-Sets nie `null`.

---

### 6) Nicht-blockend, aber vor Launch bereinigen: externe 404-Bild-URLs (P2)
Beobachtung:
- Wiederholte `NetworkImageLoadException 404`.

Risiko:
- Rauschen in Logs, schlechtere UI-Qualität, unnötige Netzwerkfehler.

Checkliste:
- [ ] Defekte URLs ersetzen oder auf lokale Fallback-Assets umstellen.
- [ ] Retry/placeholder für Logos robust machen.
- [ ] Error-Logging für bekannte 404s drosseln.

Abnahme:
- [ ] Keine wiederholten 404-Exceptions in Standard-Flows.

---

## Schritt-für-Schritt Abarbeitungsplan

### Phase A (P0, Blocker)
1. Sync-Fehlerklassifikation + dead-letter + Replay-Mechanik.
2. Multi-Session-Ende auf einen konsolidierten `endDay()`-Pfad.
3. Doppelte Finalize-Aufrufe eliminieren + Idempotenz.

### Phase B (P1, Stabilität/Genauigkeit)
4. Navigation/Highlights endgültig angleichen (manual == auto).
5. `lastSet`-Konsistenz in allen Save/Finalize-Pfaden.

### Phase C (P2, Polishing)
6. 404-Assets und Log-Rauschen bereinigen.

---

## Verbindliche DoD für "launch-ready" (Session-Ende)
- [ ] Keine offenen P0-Punkte.
- [ ] Manual Save, Auto Save, Profile Stop laufen über einen konsistenten End-Orchestrator.
- [ ] Kein doppeltes Finalize, keine stale Reaktivierung.
- [ ] Anchor-Day/Endzeit/Duration in allen Pfaden korrekt.
- [ ] Alle Ziel-Tests (Unit + Emulator-Protokolle) grün dokumentiert.
