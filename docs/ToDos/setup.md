# Setup: stabiles „Vibecoding“-Projektfundament (Checklist)

Ziel: Bevor wir Features weiterbauen, richten wir ein **stabiler, wiederholbarer und dokumentierter** Workflow ein (Living Docs + Planung auf Milestone/Story-Ebene + klare Statuspflege + AI/Agent-Unterstützung).

---

## 0) Inventar & Source of Truth

- [ ] **Dokumenten-Landkarte anlegen**: `docs/INDEX.md` mit Links zu allen „Source of Truth“-Dokumenten (Überblick, Architektur, PRD, Plan, Prozesse).
- [ ] **Ownership & Update-Regeln festlegen**: in jedem Kern-Dokument oben eine kleine Kopfzeile (Owner, Status, Last updated, Next review).
- [ ] **Dubletten identifizieren** (z. B. Roadmaps/PDFs vs. Markdown) und entscheiden: Welche Datei ist verbindlich, welche nur Archiv?

---

## 1) High-Level Projektbeschreibung

- [ ] **High-Level Overview** (falls `README.md` dafür nicht „Source of Truth“ sein soll): `docs/PROJECT_OVERVIEW.md`
  - [ ] Problem/Value Proposition, Zielgruppen, Non-Goals
  - [ ] System-Kontext (App, Backend, Admin-Web, Firebase)
  - [ ] Tech-Stack + „How to run“ (nur das Nötigste, Rest verlinken)
- [ ] **Glossar**: `docs/GLOSSARY.md` (Begriffe wie Gym/Tenant/Season/XP/Device etc.)

---

## 2) Architektur-Dokumentation (Living)

- [ ] **Architecture Overview**: `docs/Architecture/README.md`
  - [ ] Module/Boundaries (Features/Core/Services) + Verantwortlichkeiten
  - [ ] Datenfluss (Client ↔ Firestore/Functions) + Security Model
  - [ ] Konventionen (State-Management, Repositories, Naming)
- [ ] **ADRs einführen**: `docs/adr/` (leichtgewichtig)
  - [ ] `docs/adr/0000-template.md`
  - [ ] Regel: jede „größere“ Architekturentscheidung bekommt eine ADR + Link im Architecture Overview

---

## 3) Product Requirements Document (PRD)

- [ ] **PRD erstellen**: `docs/PRD.md`
  - [ ] Vision, Nutzersegmente/Personas, JTBD/Use-Cases
  - [ ] Anforderungen (funktional) + Constraints (nicht-funktional)
  - [ ] MVP-Definition + Success Metrics (z. B. Activation/Retention)
  - [ ] Out of Scope + offene Fragen/Risiken

---

## 4) Contributing / Engineering Playbook

- [ ] **Root-Contributing**: `CONTRIBUTING.md` (Entry-Point, der auf Details in `docs/` verlinkt)
  - [ ] Branch/PR-Flow, Commit-Konventionen (auf `COMMIT_CONVENTIONS.md` verweisen)
  - [ ] DoD (Definition of Done): Tests, Lint, Docs, Security, Review
  - [ ] Release/Flavors (dev/prod) + Secrets/Env Regeln (auf `docs/secrets-policy.md` verweisen)
- [ ] **PR-Checkliste schärfen**: `.github/PULL_REQUEST_TEMPLATE.md` (z. B. Tests/Doku/Breaking Changes)
- [ ] **Code Review Leitfaden**: `docs/Contributing/code_review.md` (Kurzregeln + typische Risiken)

---

## 5) Entwicklungsplan: Milestones → Stories

- [ ] **Roadmap auf Milestone-Ebene**: `docs/plan/ROADMAP.md`
  - [ ] Milestone-Liste mit Ziel, Scope, Status (Planned/In Progress/Done), Link zum Detailplan
- [ ] **Milestone-Detailpläne**: `docs/plan/milestones/`
  - [ ] Pro Milestone: `Mxx_<name>/README.md` mit Ziel, Deliverables, Risiken, Abnahmekriterien
  - [ ] Stories/Tasks als Checkliste (Story-Ebene), inkl. Owner/Status/Estimate (leichtgewichtig)
- [ ] **Story-Template**: `docs/plan/templates/STORY.md` (Problem, ACs, Tech Notes, Testplan)

---

## 6) Iteration & Statuspflege („immer sauber durchiterieren“)

- [ ] **Prozess-Dokument**: `docs/process/ITERATION.md`
  - [ ] Regel: Jede Änderung aktualisiert die relevanten Docs (PRD/Arch/Plan) + Status
  - [ ] Cadence: z. B. wöchentlich „Docs & Plan Review“ (15–30 min)
  - [ ] „Decision / Change Log“: wo werden Änderungen kurz protokolliert?
- [ ] **Status-Standard** in allen Plänen einführen:
  - [ ] `Status:` (Draft | Active | Done | Deprecated)
  - [ ] `Last updated:` (Datum)
  - [ ] `Next review:` (Datum)

---

## 7) AI-/Agent-Setup (Review + Security)

- [ ] **Kontext-Optimierung** (für Coding Agents): `docs/ai/CONTEXT.md`
  - [ ] „Was ist wichtig?“ + „Welche Dateien zuerst?“ + „Was nicht laden?“
  - [ ] Standard-Kommandos (Build/Test/Lint) und wo sie stehen (`Makefile`, `scripts/`)
- [ ] **Agent: Review** (Codequalität, Architektur-Fit, Testabdeckung): z. B. `docs/ai/agents/review.md`
- [ ] **Agent: Security** (Secrets, Rules, AuthZ, Dependencies): z. B. `docs/ai/agents/security.md`
- [ ] **Definition, wann Agents genutzt werden**: z. B. „vor Merge“, „bei Auth/Payments“, „bei Rule-Changes“

---

## 8) Stabilität: Checks & Automatisierung (kurzer Audit)

- [ ] **CI-Checkliste** dokumentieren: `docs/process/CI.md` (welche Workflows, wann, was gilt als grün)
- [ ] **Security/Secrets**: prüfen, dass gitleaks + Secrets-Policy + `.env`-Handling zusammenpassen
- [ ] **Teststrategie** kurz festhalten: `docs/process/TESTING.md` (Unit/Widget/Integration/Rules/Emulator)

---

## 9) Templates (damit das System „von selbst“ stabil bleibt)

- [ ] `docs/_templates/PROJECT_OVERVIEW.md`
- [ ] `docs/_templates/ARCHITECTURE_OVERVIEW.md`
- [ ] `docs/_templates/PRD.md`
- [ ] `docs/_templates/MILESTONE.md`
- [ ] `docs/_templates/STORY.md`
- [ ] `docs/_templates/ADR.md`

---

## Quellen/Referenzen (für späteres Nachschlagen)

- [ ] Repo-Ideen vergleichen: `obra/superpowers`, `21st-dev/1code`
- [ ] Kontext-Artikel lesen/übernehmen: „Stop Wasting Tokens: How to Optimize Claude Code Context by 60%“ (Medium)

