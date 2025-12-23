## XP Season + Zeitraum-Rangliste – Spezifikation (Option C ohne Neutral-Zonen)

Ziel: Eine hybride Rangliste mit zwei klaren Modi:
- Gesamt (Lifetime)
- Season (Jahr, z.B. 2026)
Optional: Zeitraum-Filter innerhalb der Season (4/8/26/52 Wochen).

Entscheidung (final):
- Es gibt **nur einen globalen Streak**.
- Season-Rangliste summiert ausschließlich XP-Events im Season-Zeitfenster.
- Kein Reset des Streaks, keine Grace-Period, kein Bonus-Cap.
- Strafen (z.B. XP-Abzug pro inaktive Woche) werden als **XP-Events** mit Timestamp
  erfasst und zählen nur dann in der Season, wenn sie im Season-Zeitraum liegen.

---

## Regeln (klar & konsistent)

1) XP-Event-basierte Berechnung
- Jede XP-Veränderung ist ein Event: `delta`, `reason`, `timestamp`.
- Season-Rangliste = Summe aller Events im Season-Zeitraum.
- Gesamt-Rangliste = Summe aller Events über die gesamte Historie.

2) Streak-Bonus
- Streak läuft global und wird nicht zurückgesetzt.
- Der Bonus für einen Trainingstag zählt als Event zum Trainingszeitpunkt.
- Fällt das Event in die Season, zählt es in der Season-Rangliste.

3) Inaktivitäts-Penalty
- Wöchentlicher XP-Abzug wird als Event mit Timestamp der jeweiligen Woche gespeichert.
- Penalty zählt nur in der Season, wenn das Event im Season-Zeitraum liegt.

4) Season-Grenzen
- Season 2026: 01.01.2026 00:00:00 bis 31.12.2026 23:59:59 (lokale App-Zeit).
- Die Season ist nicht an Trainingsstreaks gekoppelt, sondern rein zeitbasiert.

5) UX
- Ranglisten-Tabs: `Gesamt` und `Season 2026`.
- Optionaler Zeitraum-Filter in Season: `4W`, `8W`, `26W`, `52W`, `YTD`.
- Copy: “Season zählt nur XP-Events in diesem Zeitraum. Gesamt bleibt unverändert.”

---

## Datenmodell / Backend

### XP-Event (bestehendes oder neues Schema)
- `userId`
- `delta` (int)
- `reason` (enum/string)
- `timestamp` (UTC)
- optional: `gymId`, `source`, `meta`

### Leaderboard-Query
- Season-Rangliste: Summe `delta` pro `userId` im Zeitfenster.
- Gesamt-Rangliste: Summe `delta` pro `userId` ohne Zeitfilter.
- Zeitraum-Filter: dynamisches Zeitfenster (jetzt - X Wochen).

---

## Aufgaben (MVP)

### 1) Datenhaltung
- [ ] Sicherstellen, dass **jede** XP-Aenderung als Event gespeichert wird.
- [ ] Penalty-Events mit klarer Woche/Timestamp erzeugen.

### 2) Ranglisten-Logik
- [ ] API/Query: Summierung nach `timestamp`-Range.
- [ ] UI: Tabs fuer `Gesamt` und `Season {year}`.
- [ ] Optional: Zeitraum-Filter in der Season.

### 3) UX & Copy
- [ ] Kurzer Hinweistext in der Season-Rangliste.
- [ ] Fallback: Wenn keine Events im Zeitraum, klare Empty-State Copy.

---

## Testfaelle (Beispiele)

1) User hat 39 Streak-Tage vor Neujahr, trainiert am 01.01.
- Gesamt: XP + Streak-Bonus wird vergeben.
- Season 2026: Das Event liegt im Januar -> zaehlt voll in Season.

2) User trainiert nicht in Woche 2 der Season
- Penalty-Event in Woche 2 -> zaehlt in Season.
- Gesamt bleibt ebenfalls korrekt.

3) Zeitraum-Filter 4W in Season
- Zeigt nur XP-Events der letzten 4 Wochen.

