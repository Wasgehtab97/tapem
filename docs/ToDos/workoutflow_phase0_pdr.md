## Workout Flow PDR (Phase 0)

Status: Draft v1 (in Review)  
Letzte Aktualisierung: 2026-02-13  
Owner: Mobile/Core Team

Zweck: Diese Spezifikation friert das Soll-Verhalten fuer Start, Stop, Auto-Ende, Tageszuordnung und Session-Highlights ein, damit Phase 1+ ohne Interpretationsspielraum umgesetzt werden kann.

---

## 1. Scope

In Scope:

- Start ueber Profil-Play
- Start ueber Gym-Page und NFC
- Manuelles Ende ueber WorkoutDay `Training speichern`
- Manuelles Ende ueber Profil-Stop
- Auto-Ende nach Inaktivitaet
- Persistenz + Wiederherstellung bei App-Restart
- Session-Highlights inkl. Nachholung
- Tageszuordnung bei Mitternachtsueberlauf

Out of Scope:

- UI-Redesign
- Neue Gamification-Features
- Neue Pricing-/Business-Logik

---

## 2. Begriffe (verbindlich)

- `Training gestartet`: Session-State wechselt von `Idle` nach `Running`.
- `Satz abgehakt`: Ein Satz wird als abgeschlossen markiert und hat einen `completedAt` Timestamp.
- `Training beendet`: Session wird finalisiert (save oder discard), Timer ist nicht mehr `Running`.
- `Trainingstag`: Der Tag, der durch den Session-Start bestimmt wird (`anchorDayKey`), unabhaengig vom Endzeitpunkt.
- `Starttag`: Kalendertag des Session-Starts (`anchorStartAt`).
- `Endzeit`: Zeitstempel, der fuer Dauer/Meta verwendet wird.

---

## 3. Harte Invarianten

- I1: Es darf pro User + Gym nur eine aktive Workout-Session geben.
- I2: `anchorStartAt` und `anchorDayKey` werden bei Session-Start gesetzt und nie nachtraeglich geaendert.
- I3: Alle Daten (Session, XP, Story, Meta, Highlights) werden dem `anchorDayKey` zugeordnet.
- I4: Auto-Ende erfolgt genau 60 Minuten nach dem letzten abgehakten Satz.
- I5: Bei Auto-Ende ist `endTime == lastSetCompletedAt`.
- I6: Finalize ist idempotent (kein Doppel-Save bei Retry/Mehrfach-Trigger).
- I7: Highlights duerfen nicht verloren gehen; falls nicht sofort zeigbar, muessen sie nachholbar gespeichert werden.

---

## 4. Startregeln (Soll)

### 4.1 Profil-Play

- Action: User tippt grossen Play-Button auf Profil.
- Ergebnis: Session wird gestartet.
- Ergebnis: Timer startet sofort.
- Ergebnis: `anchorStartAt` und `anchorDayKey` werden sofort gesetzt.

### 4.2 Gym/NFC -> WorkoutDay

- Action: User fuegt ueber Gym-Page oder NFC eine Uebung zur WorkoutDay hinzu.
- Ergebnis: Session-Kontext wird erstellt/aktiviert.
- Ergebnis: Timer startet noch nicht.
- Ergebnis: Timer startet erst beim ersten abgehakten Satz.

### 4.3 Erster Satz

- Action: erster Satz wird abgehakt.
- Ergebnis: Wenn Timer noch nicht laeuft, startet er sofort.
- Ergebnis: `lastSetCompletedAt` wird gesetzt.
- Ergebnis: Inaktivitaetsfenster (60 Minuten) wird gestartet.

---

## 5. Endregeln (Soll)

### 5.1 Manuell ueber WorkoutDay

- Trigger: Klick auf `Training speichern`.
- Ergebnis: Einheitlicher Finish-Orchestrator wird ausgefuehrt.
- Ergebnis: Session wird finalisiert.
- Ergebnis: Timer wird beendet.
- Ergebnis: Navigation zur Profilseite.
- Ergebnis: Session-Highlights werden angezeigt.

### 5.2 Manuell ueber Profil-Stop

- Trigger: Klick auf grossen Stop-Button auf Profilseite.
- Ergebnis: Gleicher Finish-Orchestrator wie bei WorkoutDay.
- Ergebnis: Session wird finalisiert.
- Ergebnis: Timer wird beendet.
- Ergebnis: Session-Highlights werden angezeigt.

---

## 6. Auto-Ende bei Vergessen

- Trigger: 60 Minuten ohne neuen `Satz abgehakt` Event.
- Bedingung: Es gibt mindestens einen abgehakten Satz.
- Ergebnis: Session wird automatisch finalisiert.
- Ergebnis: `endTime` wird auf `lastSetCompletedAt` gesetzt.
- Ergebnis: Dauer wird als `endTime - anchorStartAt` berechnet.
- Ergebnis: Highlight-Payload wird persistiert.
- Ergebnis: Falls App nicht aktiv/offen, werden Highlights beim naechsten App-Start angezeigt.

Fallback ohne abgeschlossene Saetze:

- Wenn nie ein Satz abgehakt wurde, wird nicht gespeichert.
- Session wird verworfen (discard), keine Highlights.

---

## 7. Mitternachtsregel (Starttag-Invariante)

Beispiel:

- Start: 2026-02-13 23:00
- Letzter Satz: 2026-02-14 00:20
- Manuelles Ende oder Auto-Ende spaeter

Soll:

- `anchorDayKey = 2026-02-13`
- Alle Trainingsdaten dieser Session gehoeren zu 2026-02-13
- Kein Split auf zwei Trainingstage

Das gilt fuer:

- Session-Meta
- Session/Logs
- XP-Zuordnung
- Story/Highlights
- Tagesansichten und Aggregationen

---

## 8. Recovery- und Offline-Verhalten

- App-Kill waehrend `Running`: Zustand wird aus persistiertem Session-State wiederhergestellt.
- App-Restart nach Auto-Ende: finalize-Ergebnis und pending-highlights muessen rekonstruierbar sein.
- Offline beim Finalize: lokal persistieren und in Sync queue einreihen.
- Offline beim Finalize: idempotente Remote-Nachlieferung bei Netzrueckkehr.
- Offline beim Finalize: kein doppeltes Finale durch Retry.

---

## 9. Akzeptanzkriterien (testbar)

AK-1 Profil-Start:

- Given User startet ueber Profil-Play
- When kein Satz wurde abgehakt
- Then Timer laeuft sofort und Session ist `Running`

AK-2 Gym/NFC-Start:

- Given User fuegt ueber Gym/NFC eine Uebung hinzu
- When noch kein Satz wurde abgehakt
- Then Timer laeuft nicht
- And beim ersten abgehakten Satz startet Timer sofort

AK-3 Manuelles Ende:

- Given Session mit abgeschlossenen Saetzen
- When User beendet ueber WorkoutDay `Training speichern` oder Profil-Stop
- Then derselbe Finish-Orchestrator wird genutzt
- And Timer endet
- And Session wird finalisiert
- And Highlights werden angezeigt

AK-4 Auto-Ende:

- Given letzter Satz wurde um T abgehakt
- When bis T + 60 Minuten kein weiterer Satz abgehakt wird
- Then Session wird automatisch beendet
- And `endTime == T`

AK-5 Highlights-Nachholung:

- Given Session wurde auto-finalisiert waehrend App geschlossen war
- When User oeffnet App an einem spaeteren Tag
- Then Session-Highlights werden genau einmal nachgeholt angezeigt

AK-6 Mitternacht:

- Given Session startet vor 00:00 und endet nach 00:00
- Then alle Daten sind dem Starttag zugeordnet

AK-7 Idempotenz:

- Given doppelter Finalize-Trigger (z. B. retry + UI)
- Then es entsteht genau eine finale Session-Speicherung

---

## 10. Technische Leitplanken fuer Phase 1

- Ein zentraler Coordinator ist Pflicht.
- Timer-Service darf keine konkurrierende Business-Logik mehr enthalten.
- `anchorStartAt`, `anchorDayKey`, `lastSetCompletedAt`, `finalizedAt`, `finalizeReason` muessen persistiert werden.
- Persistente Queue fuer `pending_highlights` mit dedupe key.

---

## 11. Review-Freigabe

- [ ] Product Review
- [ ] Engineering Review
- [ ] QA Review
- [ ] Freigabe fuer Phase 1
