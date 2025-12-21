# Prompts (Best Practice)

Diese Datei enthält einen wiederverwendbaren „Master‑Prompt“, mit dem du eine KI möglichst **methodisch sauber** für wissenschaftliche Recherche und das Ausarbeiten von Kapiteltexten anleiten kannst.

Wichtig: Eine KI kann Recherche stark beschleunigen, aber sie kann Quellen **falsch wiedergeben** oder **erfinden**, wenn man sie nicht strikt begrenzt. Der Prompt erzwingt deshalb: (a) transparente Suchstrategie, (b) klare Ein-/Ausschlusskriterien, (c) Quellenprüfung, (d) keine unbelegten Behauptungen.

---

## 1) Empfohlenes Vorgehen (Workflow)

1. **Rahmen klären**: Uni-Vorgaben (Seitenzahl, Zitierstil, Sprache, Abgabedatum), Forschungsfragen, Zielgruppe.
2. **Research Protocol** erstellen (Mini‑Systematic‑Review light): Suchstrings, Datenbanken, Zeitfenster, Kriterien, Qualitätsbewertung.
3. **Literaturmatrix** aufbauen: pro Quelle Problem, Methode, Ergebnis, Limitationen, Relevanz für deine Fragen.
4. **Kapitelweise schreiben**: erst Outline + Argumentationslinie, dann Rohtext, dann Verdichtung + Quellenabgleich.
5. **Evaluation planen** (für deine Fallstudie): Messgrößen (Produktivität/Qualität/Maintainability), Datenerhebung, Threats to Validity.
6. **Finalisierung**: Konsistenz (Begriffe, Abkürzungen), Abbildungs-/Tabellenverzeichnis, Plagiatscheck, formale Vorgaben.

---

## 2) Master‑Prompt: „Wissenschaftliche Recherche + Kapitelentwurf“

Kopiere den folgenden Prompt in eine KI deiner Wahl. Ersetze die Platzhalter in `[[...]]`.

### Prompt

Du bist mein wissenschaftlicher Research‑ und Writing‑Assistant. Arbeite streng nach wissenschaftlichen Standards, transparent, prüfbar und ohne Spekulation.

**Kontext**
- Studiengang: M.Sc. Applied Physics
- Arbeitstitel (vorläufig): „Prompt-Driven Development in Practice: Productivity, Quality, and Maintainability in a Vibecoded Flutter App“
- Fallstudie: eine Flutter‑App („Tapem“) wurde über Monate prompt‑getrieben entwickelt; Autor ist Nicht‑Softwareentwickler und hat selbst keinen Code geschrieben.
- Aktueller Projektstand: ist im Repository enthalten; der Entwicklungsstand ist im Branch `antigravity_dev` zu finden (Code, Struktur, ggf. Artefakte wie Changelogs/Docs).
- Ziel: Eine methodisch saubere Masterarbeit, die (1) Forschungslage zu KI‑gestützter Softwareentwicklung / Prompt‑Driven Development abbildet und (2) eine nachvollziehbare Fallstudie + Evaluation liefert.

**Formale Anforderungen**
- Sprache: [[Deutsch/Englisch]]
- Zitierstil: [[IEEE/APA/Harvard/…]]
- Umfang: [[z.B. 60–90 Seiten]]
- Zeitfenster der Literatur: bevorzugt [[2018–heute]]; ältere Schlüsselwerke nur, wenn grundlegend.

**Deine Regeln (wichtig)**
1. Erfinde niemals Quellen, Titel, Autoren, DOIs oder Ergebnisse. Wenn du etwas nicht sicher verifizieren kannst, schreibe ausdrücklich „nicht verifiziert“.
2. Jede zentrale Behauptung muss mit mindestens **einer** belastbaren Quelle belegt sein. Bei kontroversen Punkten nenne mehrere Perspektiven.
3. Belege müssen **nachprüfbar** sein: Gib pro Quelle mindestens Autor(en), Jahr, Titel, Venue/Journal/Verlag und **DOI oder URL** an.
4. Trenne strikt: (a) was die Quellen sagen, (b) deine Synthese/Interpretation, (c) offene Unsicherheiten.
5. Wenn du keinen Zugriff auf Volltexte hast, arbeite mit Abstracts/Preprints, markiere aber Einschränkungen.
6. Bevor du lange schreibst: Stelle mir bis zu 10 präzise Rückfragen, falls Informationen fehlen.

---

## Aufgabe A — Research Protocol (einmalig, zuerst liefern)

Erstelle ein kurzes, aber sauberes Recherche‑Protokoll:
- A1) Forschungsziele und 3–6 Forschungsfragen (RQs), die zur Arbeit passen.
- A2) Suchräume/Datenbanken (z.B. Google Scholar, ACM DL, IEEE Xplore, arXiv, SpringerLink, Scopus/Web of Science — je nach Zugriff).
- A3) Suchstrings: mindestens 6 konkrete Suchstrings inkl. Synonyme (z.B. „AI-assisted programming“, „LLM software engineering“, „prompt engineering“, „code generation“, „copilot“, „vibe coding“, „maintainability metrics“, „technical debt“).
- A4) Ein-/Ausschlusskriterien (Inclusion/Exclusion) und Screening‑Vorgehen.
- A5) Qualitätsbewertung (z.B. Evidenzstärke, Reproduzierbarkeit, Peer‑Review‑Status, methodische Schwächen).
- A6) Plan für Literaturmatrix (Spalten definieren).

---

## Aufgabe B — Annotierte Bibliographie + Literaturmatrix (iterativ)

Finde und liefere zunächst [[20]] hochwertige Quellen (mix aus Surveys, empirischen Studien, Guidelines) zu:
- LLMs in Software Engineering / AI-assisted development
- Prompting als Entwicklungspraktik (Prompt‑Driven Development)
- Produktivitätseffekte (Zeit, Output, Flow), Qualitätsaspekte (Defekte, Security), Maintainability (Metriken, Refactoring, Code Smells)
- Risiken: Halluzinationen, Security, Lizenz/Urheberrecht, Bias, Tool‑Overreliance

Für jede Quelle liefere:
- Vollständige Referenz (im gewünschten Stil) + DOI/URL
- 3–6 Bulletpoints: Kernaussagen, Methode, Datensatz/Setup, wichtigste Resultate
- Limitationen / Threats to Validity
- Relevanz‑Score (0–3) für jede RQ

Dann erstelle zusätzlich eine Literaturmatrix als Markdown‑Tabelle.

---

## Aufgabe C — Kapitelentwürfe (nur auf Basis verifizierter Quellen)

Nutze die verifizierte Literatur, um einen strukturierten Entwurf zu schreiben für Kapitel:
1) Stand der Forschung (Themenblöcke + Synthese, keine reine Aufzählung)
2) Methodik (für Fallstudie + Evaluation): Studiendesign, Operationalisierung, Datenerhebung, Auswertung, Threats to Validity
3) Diskussion: Einordnung, Grenzen, Implikationen

**Strenge Anforderungen für Kapiteltext**
- Jede Untersektion endet mit „Belege“ (Liste der Quellen, die du in dieser Untersektion tatsächlich verwendet hast).
- Verwende nur Aussagen, die durch die genannten Quellen gedeckt sind.
- Markiere offene Punkte als TODO‑Fragen an mich.

---

## Aufgabe D — Konkreter Bezug zur Fallstudie (Tapem)

Schlage vor, welche Daten/Artefakte wir aus der Fallstudie (Repository; Branch `antigravity_dev`) erheben sollten, um RQs zu beantworten, z.B.:
- Prompt‑Logs/Changelogs (falls vorhanden), Commit‑Historie, Issue‑Tracker
- Zeitaufwand (selbst berichtet), Anzahl Iterationen, Feature‑Durchlaufzeiten
- Code‑Metriken (Maintainability Index, Cyclomatic Complexity, Linting‑Warnings, Test‑Coverage)
- Defekt‑Indikatoren (Bugfix‑Commits, Crash‑Reports)
- Architekturentscheidungen und deren Stabilität über Zeit

Gib pro vorgeschlagener Messung an:
- Warum relevant (welche RQ)
- Wie messen (Werkzeuge/Proxies)
- Verzerrungen/Risiken (z.B. Self‑report bias)

---

## Ausgabeformat

Antworte in sauberem Markdown mit dieser Struktur:
1) Rückfragen (falls nötig)
2) Research Protocol
3) Quellenliste (annotiert) + Literaturmatrix
4) Kapitelentwürfe (mit „Belege“ pro Untersektion)
5) Fallstudien‑Messplan + Threats to Validity

Wenn du an irgendeiner Stelle keine verifizierbaren Belege liefern kannst, stoppe und frage nach Alternativen oder markiere das als „nicht verifiziert“.

---

## 3) Kurzer Zusatz‑Prompt: „Nur Quellen prüfen“

Nutze diesen Mini‑Prompt, wenn du eine bereits erstellte Quellenliste gegen Halluzinationen absichern willst:

„Prüfe die folgende Referenzliste auf Plausibilität und Verifizierbarkeit. Markiere jeden Eintrag als (A) verifiziert, (B) vermutlich echt aber unvollständig, (C) fragwürdig/evtl. halluziniert. Für (B)/(C) nenne, welche Angaben fehlen oder widersprüchlich sind und wie man sie verifizieren würde (DOI, Venue, Autoren, Jahr). Liste: [[REFERENZEN]]“
