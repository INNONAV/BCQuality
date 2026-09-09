# Playbook 3 — BCQuality gegen unseren eigenen Review-Stack

**Stand:** 2026-09-09
**Belegbasis:** dieses Repo · Analyse von `INNONAV/ClaudeCodePlugin` (Plugin-Version 5.25.0)

---

## 0. Vorweg: Die Frage „welches ist besser?" ist so nicht beantwortbar

Zwei Gründe, beide belegbar:

1. **Es sind keine Konkurrenten, sondern verschiedene Ebenen.** BCQuality ist eine
   *Wissensbasis mit Ausgabekontrakt*. Unser Plugin ist ein *Orchestrator mit
   Compiler-Anbindung und Prozessanschluss*. Der ehrliche Vergleich ist nicht „A oder B",
   sondern „welche Teile von A fehlen in B".
2. **Für keinen von beiden gibt es Messdaten.** BCQuality wurde im BC-Bench-Paper nicht
   gemessen ([Playbook 2, Abschnitt 5](02-oekosystem.md)). Für unseren Stack existiert genau
   eine Eval-Datei im ganzen Repo, und die betrifft UAT-Generierung, nicht Review.
   **Precision und Recall unseres Reviews sind heute unbekannt.** Das ist die ehrlichste
   Aussage, die sich belegen lässt.

Was folgt, ist deshalb ein **Fähigkeitsvergleich**, kein Qualitätsurteil. Das Qualitätsurteil
liefert erst [Playbook 4](04-vorgehen-start-validierung.md).

---

## 1. Gegenüberstellung

| Achse | BCQuality | INNONAV-Plugin |
|---|---|---|
| **Wissensform** | 300 atomare `.md` mit Pflicht-Frontmatter, versioniert, einzeln zitierbar | Prosa in Prompts: ~664 Zeilen `rules/`, 1.015 Zeilen `CLAUDE.md`, ~120 Rule-IDs inline in `expert-reviewer.md` |
| **Code-Beispiele** | 247 `.good.al` + 238 `.bad.al`, maschinell paarbar | keine paarbaren Beispieldateien |
| **Ground Truth** | keiner — reine LLM-Urteile mit Zitat | **ALCops/INNOCop-Diagnostics** (`file:line`, Rule-ID, `hasCodeFix`) |
| **Beleg pro Finding** | Pflicht-Zitat auf Knowledge-Datei + Integritäts-Gate | nur Cop-Rule-ID wo vorhanden; kein `helpUri`, kein Zitat |
| **Ausgabeformat** | striktes JSON, RFC-8259, festes Schema | Markdown-Report `.dev/03-code-review.md`; JSON-Schema nur flüchtig im Workflow-Pfad |
| **Severity** | 4 Stufen (`blocker/major/minor/info`) + `confidence` (3 Stufen) | 3 Stufen (Critical/High/Minor), keine Confidence |
| **False-Positive-Schutz** | negatives Wissen als Knowledge-Datei; Agent-Findings gedeckelt auf `minor`/`medium` | **Adversarial Verification**: jedes Finding startet REFUTED, 4 AL-spezifische Widerlegungstests |
| **Regressionstest** | **34 Fixture-Cases über 17 Domänen**, in CI | **keiner** für Review |
| **Reproduzierbarkeit** | Ref-Pin über BC-ALAgents-Config | nur im `ultracode`-Workflow-Pfad; sonst Prosa-Orchestrierung |
| **Prozessanschluss** | keiner — liefert nur JSON | Disposition-Loop, `.dev/`-Artefaktkette, ADO/GitHub-Write-Back mit Approval-Gate |
| **Umfang** | 1 Aufgabe (AL-Review) | 46 Skills, 19 Commands, 17 Agents über 5 Plugins |

---

## 2. Was BCQuality kann, das wir nicht können

### 2.1 Findings mit erzwungenem Beleg

Der Reference-Integrity-Gate ([`skills/do.md`](../../skills/do.md)) verlangt vor dem Emittieren:
Pfad existiert, wurde in diesem Lauf geöffnet, `id == references[0].path`. Was durchfällt,
wird gelöscht — und darf ausdrücklich nicht als Agent-Finding gerettet werden.

Unsere Findings tragen eine Cop-Rule-ID, wo eine existiert, und sonst nichts. Ein Entwickler,
der ein Finding bestreitet, bekommt bei uns keine Belegkette. Das kollidiert direkt mit dem
INNONAV-Grundsatz *„Fakt, Annahme, Spekulation trennen"*.

### 2.2 Maschinelle Regressionsprüfung der Review-Qualität

`[gemessen: 2026-09-09]` — `pwsh ./tools/Test-ReviewFixtures.ps1 -Root .`
→ **34 Cases, 17 Domänen, 2,0 s, ohne Credentials, Exit 0.**

Zwei Schwellen, beide auf 1.0 in
[`evaluation/review-fixtures.json`](../../evaluation/review-fixtures.json):
- `minimumExpectedRecall: 1.0` — der erwartete Artikel **muss** gefunden werden
- `minimumCleanRate: 1.0` — auf der `.good.al` darf **kein** Finding entstehen

Der Clou ist die Neutralisierung: Case-IDs werden gehasht, `Good`/`Bad`-Tokens in
Objektnamen ersetzt, ganzzeilige Beispielkommentare entfernt. Das Modell kann die Antwort
nicht aus dem Dateinamen ableiten.

**Wir haben nichts Vergleichbares.** Jede Prompt-Änderung in unserem Plugin ist heute
ungetestet. Der `CHANGELOG` belegt zwei bereits eingetretene Drift-Fehler: ein falscher
Optionstyp (`ReadIsolation::` statt `IsolationLevel::`, hätte nicht kompiliert) und ein
SetLoadFields-Absolutum, das PC0031 widersprach.

### 2.3 Ein einziger Ort pro Regel

Bei uns steht dieselbe SetLoadFields/PC0031-Regel an **bis zu zehn Stellen**: `CLAUDE.md`,
`rules/al-data-access.md`, `rules/al-performance.md`, `rules/review-checklist.md`, drei
Agent-Prompts, `skills/analyze/SKILL.md`, `commands/review.md` und das Workflow-Skript. Bei
BCQuality steht sie in einer Datei, und die Skills zitieren sie.

### 2.4 Confidence und Applicability-Semantik

`confidence: high|medium|low`, gekoppelt an die Frage, ob Kontextdimensionen bekannt waren.
Fehlt die BC-Version, ist das Finding automatisch `medium` und muss das im `message` sagen.
Unsere Findings haben keine Confidence-Dimension.

### 2.5 `suggested-code`

Wörtlicher Ersatztext für die betroffenen Zeilen, direkt als GitHub-`suggestion` renderbar,
mit Pflichtbegründung (`suggested-code-omission-reason`), wenn er weggelassen wird. Unsere
Reports enthalten Fix-Beschreibungen als Prosa.

---

## 3. Was wir können, das BCQuality nicht kann

### 3.1 Echter Compiler-Ground-Truth

ALCops liefert `file:line`, Rule-ID, Severity und `hasCodeFix` aus dem tatsächlich
installierten Cop-Satz — inklusive unserer Hausregeln (INNOCop, INN0001–INN0009).
`commands/review.md` macht daraus Step 0: *„ALCops is the source of truth."* Ein
Specialist-Finding, das auf eine Cop-Regel mappt, aber nicht in der Baseline steht, wird zu
„unconfirmed" degradiert.

**BCQuality hat das strukturell nicht.** Es liest Text und zitiert Wissen; es kompiliert
nichts. Das ist der stärkste Punkt unseres Stacks, und er ist nicht ersetzbar.

**Microsoft sagt dasselbe.** In der BCQuality-Vorstellungssession selbst:
*„compile errors are preferable"*, und einfache Regeln gehören in einen Custom-Linter,
*„because a compile is much cheaper than an agentic decision"* `[V5]`. Über alle zwölf
ausgewerteten Videos hinweg kommt trotzdem **kein einziges Mal** ALCops, CodeCop oder
AppSourceCop vor. Der Markt diskutiert Qualität fast ausschließlich über Tests, Skills und
Evals — obwohl Microsoft die deterministische Prüfung ausdrücklich vorzieht.

**Einordnung:** Unser Compiler-Ground-Truth ist damit kein Rückstand, sondern ein
Alleinstellungsmerkmal mit Rückendeckung vom Hersteller.

### 3.1b Die Brücke, die beides verbindet

Ein Detail aus der ALMCP-Session, das für die Umsetzung wichtig ist: Der AL-MCP-Server kann
**Analyzer über die LSP-Verbindung mitlaufen lassen** — inklusive eigener Cops
(*„analyzers on the LSP connection as well"*, als Parameter beim MCP-Start) `[V12]`.

Das heißt: Ein Agent mit AL-MCP bekommt unsere INNOCop-Diagnostics direkt, ohne dass wir
etwas Eigenes bauen müssen. Genau das ist auch die Erklärung für den gemessenen
MCP-Effekt — der Agent kann seine eigene Arbeit verifizieren
([Playbook 2](02-oekosystem.md)). **Das ist der lohnendste Integrationspunkt der ganzen
Recherche** und sollte in Phase 1 mitgeprüft werden.

### 3.2 Adversarial Verification mit AL-spezifischen Widerlegungstests

Jedes Finding startet als **REFUTED**; ein Skeptiker liest `file:line` neu und versucht zu
widerlegen. Die vier Tests sind fachlich präzise:

- fehlendes `SetLoadFields` wird widerlegt, wenn im selben Scope geschrieben wird (PC0031) —
  ein „Fix" wäre hier stiller Datenverlust
- SecurityFiltering wird widerlegt bei Temp-Tables und Handler-Parametern
- AC0029 nur, wenn Page **und** Table beide eine ToolTip definieren
- jedes Cop-Finding ohne Baseline-Eintrag

BCQuality begegnet False Positives *präventiv* über negative Knowledge-Dateien, aber es gibt
keinen Widerlegungsschritt zur Laufzeit.

**Einordnung:** Die beiden Ansätze sind komplementär, nicht redundant. Negatives Wissen
skaliert (einmal geschrieben, wirkt überall); der Skeptiker fängt das ab, was noch niemand
aufgeschrieben hat.

### 3.3 Hausregeln und Prozess

QFIX-Lebenszyklus mit Ablaufdatum (INN0005–INN0007b), Quellsprache-Englisch-Regel ohne
Analyzer-Deckung, AppSource-Affix-/Namespace-Doktrin. Dazu Disposition-Loop
(ACCEPT-FIX/DEFER/ACKNOWLEDGE/DISMISS mit Begründungspflicht), `.dev/`-Artefaktkette und
ADO/GitHub-Anbindung mit hartem Approval-Gate. BCQuality liefert JSON und hört dort auf.

### 3.4 Breite

46 Skills über den ganzen Lebenszyklus — Requirements, Plan, Develop, Test, Review, Deploy,
Consulting, Angebote, UAT. BCQuality macht eine Sache.

---

## 4. Schwächen unseres Stacks, die diese Recherche sichtbar gemacht hat

Nicht schönreden — das sind reale Lücken:

1. **Der Remote-PR-Pfad ist der schwächste, obwohl er am meisten Schaden anrichtet.**
   `skills/pr-review/SKILL.md` hat **weder** die ALCops-Baseline **noch** die Adversarial
   Verification. Genau der Pfad, der öffentlich Kommentare in fremde PRs schreibt, läuft ohne
   Ground Truth und ohne Skeptiker-Gate. Ersatz ist ein Prosa-Hinweis auf alguidelines.dev.
   → **Sofort adressieren, unabhängig von jeder BCQuality-Entscheidung.**

2. **Die Skeptiker sind dieselben Agents wie die Autoren.** Im Workflow wird derselbe
   `agentType` für Review und Verifikation verwendet — gleiches Modell, gleicher Prompt.
   Eine echte Unabhängigkeit der Verifikation ist das nicht.

3. **Kein maschinenlesbarer, persistenter Report.** Damit ist unser Stack weder CI-fähig noch
   gegen ein Golden Set messbar. Kein SARIF, kein JSON auf Platte, keine stabilen Finding-IDs.

4. **`test-coverage-reviewer` ist praktisch BC-frei.** Keine einzige Rule-ID, keine
   Symbol-Tools, nur `Read/Glob/Grep`. Seine „Coverage Gaps (Critical)" sind Vermutungen.

5. **Determinismus nur optional.** Ohne das `Workflow`-Tool hängen Fan-out, Dedup und
   Verifikation daran, dass das Modell die Prosa-Anweisung befolgt.

6. **Kein Diff-Scope in `/review`.** Es werden ganze Dateien geprüft — bei Bestandscode
   erzeugt das Rauschen aus Alt-Verstößen.

---

## 5. Bewertung

**Ist BCQuality besser als unser Plugin?** Nein — es ist kleiner und macht weniger.
Es hat weder Compiler-Anbindung noch Prozessanschluss noch unsere Hausregeln.

**Hat BCQuality Dinge, die unserem Plugin fehlen und die wichtig sind?** Ja, und zwar genau
drei, die weh tun: **Beleg-Zwang**, **Regressionstests** und **Wissen als Daten statt als
Prompt-Prosa**.

**Einordnung — die empfohlene Richtung ist nicht „ersetzen", sondern „andocken":**
BCQuality als *zitierbare Wissensschicht* unter unsere bestehende Orchestrierung hängen. Unser
ALCops-Ground-Truth und der Skeptiker bleiben; die Findings bekommen zusätzlich einen
überprüfbaren Beleg, und wir bekommen ein Regressionsharness geschenkt.

Das ist auch die Reihenfolge, die Microsoft selbst nahelegt: erst der Compiler
(*„a compile is much cheaper than an agentic decision"*), dann die Wissensschicht für das,
was kein Analyzer prüfen kann.

### Der Vorbehalt, der bleibt

Diese Empfehlung ist eine **Hypothese, keine Messung**. Drei Befunde dämpfen die Erwartung:

1. **Modellwahl schlägt Harness-Wahl** im BC-Bench-Paper (p = 0,026 gegen p = 0,728 / 0,075).
2. **Nur 2 von 22** nachanalysierten Fehlschlägen gingen auf falsche AL/API-Nutzung zurück —
   also auf genau das, was eine Wissensbasis heilt.
3. **Zu viel Kontext schadet messbar.** Microsofts Sammel-Instruction kostete 5 %; und in der
   BCQuality-Session selbst heißt es, Kontext, den das Modell schon kennt, führe dazu, dass es
   *„end up doing worse"* `[V5]`.

Punkt 3 schneidet in beide Richtungen: Er ist das Argument **für** BCQualitys atomare
Struktur mit Index und Worklist — und **gegen** jede Anbindung, die den Korpus einfach in den
Kontext kippt. Der Mechanismus, der BCQuality nützlich macht, ist nicht das Wissen, sondern
die **Auswahl**.

Es ist gut möglich, dass BCQuality bei uns wenig bewegt. **Deshalb messen wir, bevor wir
einführen.** → [Playbook 4](04-vorgehen-start-validierung.md)
