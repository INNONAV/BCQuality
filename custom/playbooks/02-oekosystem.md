# Playbook 2 — Das Ökosystem: BCQuality, BC-ALAgents, BC-Bench

**Stand:** 2026-09-09 · **Belegbasis:** Microsoft Learn, GitHub-Repos, arXiv-Paper — siehe [Quellen-Index](quellen/QUELLEN-INDEX.md)

---

## 1. Die zentrale Erkenntnis: drei Repos, drei Rollen

Wer nur BCQuality anschaut, versteht die Hälfte. Microsoft hat die Aufgabe bewusst in drei
getrennte Repos zerlegt:

```
  Was geprüft wird          Wie geprüft wird           Ob es besser wird
  ────────────────          ─────────────────          ─────────────────
  microsoft/BCQuality  →    microsoft/BC-ALAgents  →   microsoft/BC-Bench
  Wissen + Skills           Engine (GitHub Action      Benchmark
  (300 Artikel)             + Copilot CLI)             (101 Tasks)
```

BC-ALAgents beschreibt die Trennung selbst so:

> "An open-source, forkable engine that runs a tool-enabled GitHub Copilot CLI review"
> — [microsoft/BC-ALAgents](https://github.com/microsoft/BC-ALAgents)

mit der Kette `Consumer-Repo (Policy) → BC-ALAgents (Engine) → BCQuality (Review-Regeln)`.

**Einordnung — das ist die wichtigste Übernahme aus dieser ganzen Recherche.** Nicht eine
einzelne Regel, sondern die Aufteilung: *Wissen*, *Mechanik* und *Messung* sind drei Artefakte
mit eigener Versionierung und eigenem Lebenszyklus. Unser Plugin vermischt heute alle drei
(Wissen in Prompts, Mechanik in denselben Prompts, Messung gar nicht). Siehe
[Playbook 3](03-vergleich-innonav.md) und [Playbook 5](05-uebernahmekandidaten.md).

---

## 2. BC-ALAgents — die Engine

| | |
|---|---|
| Zweck | AL-PR-Reviews als GitHub Action, Findings als Inline-PR-Kommentare |
| Motor | GitHub Copilot CLI |
| Konfiguration | `.github/bcquality.config.yaml`, mit **Ref-Pin** auf einen BCQuality-Stand |
| Versionierung | `X.Y.Z` — `X.Y` aus der Engine, **`Z` aus dem BCQuality-Inhalt** |
| Sicherheitsmodell | Review-Job read-only ohne Write-Token; separater Publish-Job postet nur aus Artifacts |

Lokal ausführbar über `agents/ALReviewAgent/scripts/Invoke-CopilotPRReview.ps1` mit
`REVIEW_PHASE`, `BCQUALITY_ROOT`, `REVIEW_WORKSPACE`, `BCQUALITY_CONFIG_PATH`.

Zwei Details, die für uns zählen:

- **Der Ref-Pin.** Der Consumer pinnt einen konkreten BCQuality-Stand. Reviews sind damit
  reproduzierbar — ein Upstream-Commit ändert nicht rückwirkend, was gestern geprüft wurde.
  Unser Plugin hat kein Äquivalent: Prompt-Änderungen wirken sofort auf alle.
- **Die geteilte Versionsnummer.** Dass die Patch-Stelle aus dem *Wissensstand* kommt, macht
  die Trennung Engine/Wissen auch im Release sichtbar.

⚠️ Die Doku nennt für BC-ALAgents nur GitHub Actions und Copilot CLI. Ein Claude-Code-Pfad ist
dort **nicht beschrieben** `[unsicher — nicht abschließend geprüft]`. Für uns ist BC-ALAgents
damit eher Architektur-Vorbild als direkt nutzbares Werkzeug.

---

## 3. BC-Bench — die Messung

Das ist das ausgereifteste Stück des Ökosystems und für unsere Fragestellung das wichtigste.

| | |
|---|---|
| Status | **GA seit 1. April 2026** (Release Plan 2026 Wave 1) |
| Learn-Verankerung | ja, verlinkt aus *Development in AL* |
| Vorbild | SWE-Bench |
| Datenbasis | kuratierte AL-Probleme aus echten Pull Requests |
| Kategorien | `bug-fix`, `test-generation`, `code-review`, `nl2al` |
| Unterstützte Runner | GitHub Copilot CLI, **Claude Code**, BC PR Review (BC-ALAgents + BCQuality) |
| Paper | arXiv:2608.20851 — Sun, Hansen: *BC-Bench: Evaluating Agentic Engineering in a Domain-Specific Language for ERP* |

> "BC‑Bench provides a repeatable benchmark for AL bug fix and test creation tasks in Business
> Central, producing measurable results […] instead of subjective impressions, helping
> developers understand what improvements actually work."
> — [Microsoft Learn, Release Plan 2026 Wave 1](https://learn.microsoft.com/en-us/dynamics365/release-plan/2026wave1/smb/dynamics365-business-central/evaluate-al-coding-agents-bc-bench)

**Claude Code wird explizit als unterstützter Runner geführt** — mit derselben geteilten
Konfiguration wie Copilot. Das ist für uns entscheidend: Wir können unser eigenes Setup gegen
denselben Maßstab messen wie Microsoft.

### Wie BC-Bench mechanisch arbeitet

Aus den beiden Microsoft-Videos, jedes Zitat mechanisch gegen das Roh-Transkript geprüft
(30/30 wörtlich belegt, siehe [Quellen-Index](quellen/QUELLEN-INDEX.md)):

- **Offline-Harness nach SWE-bench-Methodik.**
  „BC Bench is a offline evaluation framework" `[V1 @01:53]` ·
  „Um it is very heavily inspired by Sweep Bench" `[V1 @02:22]`
  („Sweep Bench" = SWE-bench, Auto-Untertitel-Artefakt).
- **Tasks kommen aus echten Bug-Reports** des internen Backlogs. Pro Task: Problem Statement,
  Base Commit und der originale, von Menschen geschriebene Unit-Test.
  Der Base Commit sorgt dafür, dass der Agent „the exact same context as the human engineer"
  hat `[V1 @06:05]`.
- **Pass-Kriterium ist hart und binär:** der menschliche Unit-Test wird ausgeführt —
  „to verify if the fix is correct and if the test pass, then we count that" `[V1 @04:12]`.
- **Runner:** „actually using AL Go and BC Container Helper to help us run tests" `[V1 @05:04]`.
- **Drei Auswahlkriterien** für Tasks: ein PR = genau ein Bug; „the bug must have all the
  context it needed to solve to be solved" `[V1 @08:38]`; und
  „the test must not have dependency on the fix" `[V1 @08:59]` — sonst entstehen
  falsch-positive Bestehen.
- **Umgang mit Rauschen:** „all the numbers you see here are aggregated across five runs"
  `[V2 @06:52]`. Zusätzlich *pass at five* — der Anteil der Tasks, der „has been consistently
  resolved across all five runs" `[V2 @08:53]`. Bei überlappenden Konfidenzintervallen wird
  ausdrücklich **kein** Ranking behauptet: „the 65% on the lower range is lower than the 67%"
  `[V2 @07:34]`.

⚠️ **Datenstand beachten:** Das Video nennt „66 tasks in the data set" `[V1 @09:19]`, das
Paper 101. Das Dataset wächst; die Zahlen oben stammen aus dem Paper (jüngerer Stand).

### Warum AL überhaupt ein eigener Benchmark sein muss

„Whereas in AL, we only have 330 as of the time of this recording" `[V2 @02:11]` — gemeint
sind öffentliche AL-Repos, gegenüber rund 2 Millionen Python-Repos. Die Trainingsdatenbasis
für AL ist um Größenordnungen dünner. Das ist die Begründung dafür, dass allgemeine
Coding-Benchmarks für AL nichts aussagen — und deckt sich mit dem Paper-Befund, dass
SWE-Bench-Fortschritte nicht auf AL durchschlagen.

### Der Experiment-Workflow

Aus `EXPERIMENT.md` des BC-Bench-Repos. Zentrale Steuerdatei:
`src/bcbench/agent/shared/config.yaml`

| Schalter | Wirkung |
|---|---|
| `instructions.enabled` | kompletter Ordner (Instructions + Skills + Agents) ins Test-Repo |
| `skills.enabled` | nur Skill-Dateien |
| `agents.enabled` + Name | nur Agent-Dateien, `--agent=<name>` an die CLI |
| `mcp.servers` | MCP-Server registrieren |
| `plugins` | Agent-Plugins aus GitHub oder lokal laden ← **unser Einstiegspunkt** |

Ablauf in sechs Stufen: Branch → lokaler Smoke-Test (1 Task, ~2 min) → Test-Run (4 Einträge,
~10 min) → einzelner Full-Run → 5 Wiederholungen → Auswertung über Notebooks.

Zwei Regeln aus der Doku, die man nicht überspringen sollte:

> "Agent-Runs sind verrauscht" — deshalb typischerweise `repeat: 5`.

Und: **vor dem Start eine Hypothese schriftlich formulieren** („Custom Instructions sollten
Resolution um ~X% verbessern, weil…"), damit Ergebnisse interpretierbar bleiben.

Eine Feinheit, die man kennen muss:

> Skills sind **diskretionär** — der Agent *sieht* sie, nutzt sie aber nur, wenn er sie für
> nötig hält.

Um Skill-Nutzung zu erzwingen, braucht es zusätzlich einen Nudge in `AGENTS.md` plus
`instructions.enabled: true`. Andernfalls misst man womöglich, dass ein Skill nie aufgerufen
wurde — nicht, dass er nichts bringt.

⚠️ **Externe PRs werden nicht angenommen.** Wer eigene Tasks will, forkt und ersetzt
`dataset/`.

---

## 4. Die harten Zahlen aus dem Paper

Aus arXiv:2608.20851. `[verifiziert: zwei unabhängige Abrufe des Volltexts, konsistent]`

### Dataset

101 Tasks (85 aus BaseApp, 16 aus anderen Apps), 67 mit Bildern. Durchschnittlicher
Gold-Patch: 1,3 geänderte Dateien, 18,9 Codezeilen.

### Bug Fixing — Resolution Rate (Table 3)

| Harness | Modell | Mean (95 % CI) | pass^5 | Dauer |
|---|---|---|---|---|
| Claude Code | claude-opus-4.6 | **68,5 %** (65,7–71,3) | 49,5 % | 284 s |
| GitHub Copilot | claude-opus-4.6 | 65,1 % (62,6–67,6) | 50,5 % | 314 s |
| GitHub Copilot | gpt-5.2-codex | 60,8 % (59,4–62,2) | 49,5 % | 196 s |
| GitHub Copilot | claude-opus-4.5 | 59,8 % (58,3–61,3) | — | — |
| GitHub Copilot | gpt-5.3-codex | 55,8 % (54,3–57,3) | — | 106 s |
| GitHub Copilot | gpt-4.1 | 16,6 % (15,6–17,2) | 5,0 % | 256 s |

### Das entscheidende Ergebnis: Modell schlägt Harness

| Vergleich | p-Wert | signifikant? |
|---|---|---|
| **Harness** (Copilot vs. Claude Code), claude-opus-4.5 | 0,728 | nein |
| **Harness** (Claude Code vs. Copilot), claude-opus-4.6 | 0,075 | nein (marginal) |
| **Modell** (opus-4.6 vs. 4.5), gleicher Harness | **0,026** | **ja** |
| **Modell** (gpt-5.2-codex vs. 5.1-codex-max) | **0,019** | **ja** |

> "In the Bug Fixing category, under our evaluated settings, between-model differences in
> resolution rate are larger than differences between the two evaluated agent harnesses"

Und, ebenso wichtig:

> "improvements reported on general-purpose benchmarks do not consistently transfer to AL"

Konkret: gpt-5.3-codex vs. gpt-5.2-codex in Test Generation — p = 0,672, also kein
messbarer Unterschied, obwohl 5.3 auf SWE-Bench Pro besser abschneidet.

### Wo Agents scheitern (Table 12/13)

Von 176 Fehlern aus 505 Trials (Copilot + claude-opus-4.6, Bug Fixing):

| Fehlerart | Anteil |
|---|---:|
| Wrong Solution | 44,3 % |
| Incorrect File | 29,5 % |
| Incorrect Region | 18,2 % |
| Build Failure | 5,7 % |
| Timeout | 2,3 % |

Die manuelle Nachanalyse der „Wrong Solution"-Fälle: 10 Tasks *Incomplete Fix*, 10 Tasks
*Incorrect Business Logic*, nur 2 Tasks *Wrong AL/API Usage*.

**Einordnung — das ist unbequem für die BCQuality-These.** Wenn nur 2 von 22 nachanalysierten
Fehlschlägen auf falsche AL/API-Nutzung zurückgehen, dann adressiert eine Wissensbasis, die
genau solche AL-Fehler verhindern soll, den kleinsten Fehleranteil. Die großen Blöcke sind
*die falsche Datei finden* und *die Fachlogik verstehen* — beides löst BCQuality nicht.
Das ist kein Gegenbeweis, aber es senkt die erwartbare Wirkung deutlich und ist ein Grund,
vor der Einführung zu messen statt zu glauben.

### Weitere Kontexteffekte

- **Mehr als eine Datei zu ändern kostet über 20 Prozentpunkte**: 1 Datei 65–70 %,
  2+ Dateien 42–43 %.
- **Patch-Größe:** 1–10 LoC 75–78 %, 11–25 LoC 38–49 %, 26+ LoC 49–50 %.
- **Fachbereich:** Manufacturing 64–88 %, Inventory 65–70 %, Finance 51–62 %,
  Shopify/Warehouse 40–54 %.

### Limitationen der Autoren

- *Limited Dataset Diversity* — 101 Tasks nur aus Microsoft-eigenen Repos; „Feature
  development, upgrades, localization, and performance tuning remain unexplored."
- *Limited Representation of Real-Development Environment* — Agents arbeiten default auf der
  Codebase als „plain text", ohne AL-Tooling wie Kompilation.
- *Dependency on Tests* — bestandene Tests garantieren keine korrekte Lösung.

---

### Microsofts eigene Methode: Hill Climbing

Die TechDays-Keynote beschreibt, wie Microsoft BC-Bench tatsächlich einsetzt — und das ist die
direkteste Vorlage für unser eigenes Vorgehen.

**Schritt 1: Baseline ohne alles.** Harness plus damaliges Spitzenmodell, sonst nichts —
„no specialized agents, no instructions, no tools" `[V6 @01:03:48]`, dann
„we run the BC bench and we get the number" `[V6 @01:03:48]`.

**Schritt 2: eine Variable nach der anderen.** Die Methode heißt beim Namen
„applying the hill climbing strategy" `[V6 @01:03:48]` — man nimmt
„one variable at a time, you measure it" `[V6 @01:03:48]`, und behält die Änderung nur, wenn
die Genauigkeit steigt; sonst wird sie zurückgenommen.

Der Reihe nach getestet: neues Modell → besser, behalten. Neues Tool → besser, behalten.
Dann spezialisierter Agent mit Instructions.

### Der wichtigste Messbefund: mehr Kontext machte es schlechter

An dieser Stelle erzählt Microsoft eine Niederlage im Klartext. Für einen internen
Test-Schreib-Agenten wurden alle vorhandenen Coding Guidelines, Teststrukturen und Muster in
eine große Instruction gepackt — unter der Annahme „More context is better" `[V6 @01:04:42]`.

> „the result was actually opposite" · „It was 5% worse" · „the more context is not always
> better" — `[V6 @01:04:42]`

Die Korrektur:

> „So we shorten our instruction, make them more precise." `[V6 @01:04:42]`

Und mit derselben Modell- und Tool-Konfiguration wie zuvor:

> „we applied our shortened instruction and it was 10% better" `[V6 @01:06:14]`

**Einordnung — das ist der praktisch folgenreichste Befund dieser ganzen Recherche, und er
schneidet in beide Richtungen:**

- **Pro BCQuality:** Präzise, kurze, gezielt geladene Regeln wirken messbar — hier +10 %.
  Genau das ist BCQualitys Architektur: nicht ein Riesendokument, sondern 300 atomare Dateien,
  von denen ein Review nur die paar lädt, die in die Worklist kommen. Der Index existiert
  genau dafür.
- **Contra naiver Einsatz:** Wer BCQuality falsch anbindet — den ganzen Korpus in den Kontext
  kippen, statt über Index und Worklist zu filtern — landet im gemessenen 5-%-Minus. Der
  Mechanismus, der BCQuality nützlich macht, ist nicht das Wissen, sondern die **Auswahl**.
- **Für unser eigenes Plugin unbequem:** Unsere `CLAUDE.md` hat 1.015 Zeilen und wird
  vollständig geladen. Das ist strukturell genau das „throw all the way to the instruction",
  das hier 5 % gekostet hat. Das stützt [Playbook 5, Rang 6](05-uebernahmekandidaten.md)
  deutlich stärker, als ich es dort zunächst gewichtet hatte.

⚠️ Zu den Prozentzahlen: Sie stammen aus einer Keynote-Erzählung ohne Angabe von Kategorie,
Stichprobe oder Konfidenzintervall. Als Größenordnung belastbar, als exakter Wert nicht. Die
im selben Zug genannte Zahl „51.7" für ein Opus-4.6-Setup lässt sich keiner Kategorie sicher
zuordnen `[unsicher]` und wird hier nicht weiterverwendet.

Ausdrücklich für Partner gedacht ist der Benchmark ohnehin:

> „BCbench is an um open source project so you can take it" `[V6 @01:06:14]`
> — um eigene Agents, Skills und Tools zu evaluieren.

### Der AL-MCP-Server: erst unentschieden, dann signifikant

Hier gibt es eine zeitliche Entwicklung, die man nicht verwechseln darf.

**Früherer Stand (V1, Under the Hood).** Auf die direkte Frage, ob der AL-MCP-Server die
Genauigkeit verbessert hat:

> „Well, the the short answer is not conclusively." `[V1 @14:41]`
> „we cannot claim that the the tools we're building made it better" `[V1 @15:07]`

Die mittlere Resolution Rate stieg, aber die Konfidenzintervalle überlappten.

**Späterer Stand (V8, TechDays-Session).** Dieselbe Frage, neu gemessen — GitHub Copilot CLI
mit Opus 4.6, mit gegen ohne AL-MCP:

| Metrik | Effekt |
|---|---|
| mean resolution rate | **≈ +5 Prozentpunkte** `[V8 @20:25]` |
| pass@5 | **≈ +10 Prozentpunkte** `[V8 @21:02]` |
| 95-%-Konfidenzintervalle | **überlappen nicht** |

> „the ALMCP did give us a significant improvement over without it" `[V8 @20:51]`

Die genannte Begründung ist für uns die eigentliche Nachricht: Der Agent kann mit dem
MCP-Server **kompilieren und Symbole suchen**, also seine eigene Arbeit verifizieren
`[V8 @21:06]`.

**Einordnung — das ist ein starkes Argument, aber nicht für BCQuality.** Was hier gemessen
signifikant wirkt, ist *Verifikationsfähigkeit*: der Agent bekommt eine Rückmeldung aus der
echten Toolchain. Genau das leistet bei uns die ALCops-/al-tools-Anbindung — und genau das
leistet BCQuality strukturell **nicht**, denn es liefert Text, keinen Compiler.

Wer aus dieser Zahl ableitet „Zusatz-Tooling wirkt, also wird BCQuality auch wirken", zieht
den falschen Schluss. Die belegte Wirkung hängt am Kompilieren, nicht am Wissen.

Ein zweites Tooling-Experiment aus derselben Session, ebenfalls nützlich: Output-Kompression
hatte **keinen** Effekt auf die Bug-Fixing-Rate `[V8 @29:55]` — man kann also komprimieren
und Kosten sparen, ohne Qualität zu verlieren.

Und zur Harness-Frage, konsistent mit dem Paper: kein signifikanter Unterschied zwischen
GitHub Copilot CLI und Claude Code bei festem Modell —
„the model choice is probably more significant" `[V8 @21:45]`.

### Was Microsoft an seinem eigenen Review-Agenten misst

Aus derselben Session, und für uns direkt als Zielgröße verwendbar:

| Metrik des Code-Review-Agenten | Wert |
|---|---|
| Kommentar-Accuracy | **57 %** `[V8 @26:57]` |
| Severity-Accuracy | **49 %** `[V8 @27:12]` |

**Einordnung:** Das ist Microsofts eigener, produktiv eingesetzter Review-Agent — und knapp
jeder zweite Kommentar trifft nicht. Zwei Konsequenzen für uns: Erstens ist das die
realistische Messlatte, an der wir uns orientieren sollten, nicht 90 %. Zweitens ist es die
beste verfügbare Begründung dafür, Review-Findings **advisory** zu halten statt als Merge-Gate
([Playbook 4, Phase 3](04-vorgehen-start-validierung.md)).

Weitere Kontexteffekte aus V8, die zum Paper passen: Patches unter 10 Codezeilen werden zu
rund 80 % gelöst, darüber nur noch zu rund 50 % `[V8 @22:44]`.

---

## 5. Der wichtigste Negativbefund

**BCQuality kommt weder im BC-Bench-Paper noch in den BC-Bench-Videos vor.**

Zwei unabhängige Prüfungen, beide negativ:

1. **Paper.** Gezielt gegen den Volltext geprüft: die Begriffe „BCQuality" und
   „knowledge base" erscheinen **nicht**. „custom instructions" und „skills" erscheinen nur
   als *Möglichkeiten des Frameworks* (Section 1: „designed to support experimentation with
   different agent configurations, such as custom instructions, tools, and skills"), nicht
   als gemessene Variablen. Kontrollierte Experimente zu AL-MCP und AL-LSP stehen unter
   *Future Work*.
2. **Die drei BC-Bench-Videos.** Volltextsuche über V1, V2 und V8 (die dedizierte
   TechDays-Session): **0 Treffer** für „BC Quality", „BCQuality" und „knowledge base" —
   ebenso 0 für „ALCops", „CodeCop", „analyzer", „linter". In V8 fehlen zusätzlich
   „custom instructions" und „AGENTS.md" vollständig.

`[konvergent: Paper, V1, V2, V8]`

Besonders sprechend ist eine Publikumsfrage am Ende von V8 — *„how to evaluate which skills
are not even necessary anymore?"* `[V8 @33:18]`. Darauf folgt **keine inhaltliche Antwort**,
nur ein Hinweis auf die Laufkosten.

**Einordnung:** Die Wirkung von Skills und Wissensbasen zu messen ist keine offene
Forschungsfrage — es ist eine Frage, die gestellt wird und unbeantwortet bleibt. Wer sie für
sich beantworten will, muss selbst messen.

**Einordnung — das ist die Antwort auf „ist BCQuality besser als unser Plugin?":**
Es gibt **keine öffentliche Messung**, dass BCQuality die Ergebnisqualität verbessert.
Microsoft hat den Benchmark gebaut, aber die eigene Wissensbasis (noch) nicht damit gemessen —
jedenfalls nicht in dieser Veröffentlichung. Wer behauptet, BCQuality sei besser oder
schlechter als unser Stack, hat dafür heute keine Datengrundlage. **Wir müssen selbst messen.**
Das Vorgehen dafür steht in [Playbook 4](04-vorgehen-start-validierung.md).

---

## 5b. Was Microsoft selbst über die Grenzen von BCQuality sagt

Die Session „The BCApps Journey Is Complete — Now Let's Build with Agents" ist die
BCQuality-dichteste Quelle der gesamten Recherche. Sie stellt das Repo vor — dreischichtig,
Knowledge Files maximal 100 Zeilen, YAML-Frontmatter, kein Inline-Code — und enthält zugleich
die deutlichsten Einschränkungen, die irgendwo zu finden waren. Bemerkenswert, weil sie von
Microsoft selbst kommen:

**1. Deterministische Prüfung schlägt agentische Entscheidung.**

> „compile errors are preferable" `[V5]`

Und für einfache Regeln der ausdrückliche Rat, sie in einen **Custom-Linter** zu geben statt
in eine Knowledge-Datei —

> „because a compile is much cheaper than an agentic decision" `[V5]`

**Einordnung — das ist die stärkste externe Bestätigung für unseren eigenen Ansatz.** Unser
ALCops-/INNOCop-Ground-Truth ist nach Microsofts eigener Argumentation genau der richtige
erste Filter. BCQuality ist das, was danach kommt: für die Fälle, die kein Analyzer prüfen
kann. Es ersetzt den Compiler nicht — es ergänzt ihn. Wer bei uns überlegt, ALCops zugunsten
einer Wissensbasis zurückzufahren, argumentiert gegen Microsoft.

**2. Bekannter Kontext schadet.**

> „it and end up doing worse" `[V5]`
> — Kontext, den das Modell ohnehin kennt, verschlechtert das Ergebnis.

**Einordnung:** Das ist die inhaltliche Begründung hinter BCQualitys Aufnahmeregel — und
zugleich die Warnung an jeden, der einen eigenen Regelkatalog anschließt. Unsere `rules/*.md`
enthalten reichlich Material, das ein aktuelles Modell ohnehin anwendet. Nach diesem Befund
ist das nicht bloß überflüssig, sondern **schädlich**. Es passt exakt zum gemessenen
5-%-Rückgang aus der Keynote.

**3. Die Guardrails, die Microsoft dazu nennt:** Human-in-the-loop zwischen allen Agenten;
crawl-walk-run statt Big Bang; **Evals als Release-Gate** (Demo-Schwelle 90 %); Kontrolle
gegen Prompt-Injection und Rauschen.

---

## 6. Installationswege für BCQuality

Vier dokumentierte Wege, in aufsteigender Kopplung:

| Weg | Befehl / Vorgehen | Für uns |
|---|---|---|
| **URL im Prompt** | Repo-URL im Prompt nennen | Nullaufwand, kein Update-Pfad |
| **VS Code Plugin** | Command Palette → *Chat: Install Plugin from Source* → Repo-URL | Auto-Update ~24 h; Ablage unter `%USERPROFILE%\.vscode\agent-plugins\github.com\microsoft\BCQuality` |
| **Copilot CLI** | `copilot plugin install microsoft/BCQuality` | für Copilot-Nutzer |
| **Claude Code Plugin** | `plugin.json` + `.claude-plugin/marketplace.json` liegen im Repo, Version `0.2.0` | **unser Weg** |

Bei Fork-Nutzung überall die **Fork-URL** statt `microsoft/BCQuality` angeben — sonst bekommt
man den Upstream ohne unseren `/custom/`-Layer.

Praxishinweis aus der Community: Das Plugin arbeitet zuverlässiger, wenn man **explizit um
einen Review bittet**, statt auf automatische Anwendung zu hoffen — deckt sich mit der
BC-Bench-Beobachtung, dass Skills diskretionär sind.

⚠️ Bei einer Plugin-Installation wird **der ganze Baum** ausgeliefert (~300 Artikel + 485
AL-Beispiele). `BCQUALITY_ENABLED_LAYERS` filtert nur die Sichtbarkeit, nicht die Platte.
