# Playbook 1 — BCQuality verstehen

**Stand:** 2026-09-09 · **Belegbasis:** dieses Repo (Fork-Stand `8584217`), eigene Messungen

---

## 1. Was BCQuality ist — und was nicht

BCQuality ist **eine Wissensbasis plus ein Skill-Protokoll**. Es ist *kein* Agent, *kein*
Analyzer und *kein* Runner.

> "BCQuality contains **knowledge** and **skills**. It does not contain agents."
> — [`README.md`](../../README.md)

Der Kern ist eine ungewöhnliche Aufnahmeregel, die den ganzen Rest erklärt:

> "A file exists because a capable LLM **would get something wrong, or miss something,
> without it** — not because the topic is important."
> — [`README.md`](../../README.md)

**Einordnung:** Das ist der wichtigste konzeptionelle Unterschied zu klassischen
Coding-Guidelines. BCQuality dokumentiert nicht „was gut ist", sondern „wo das Modell
danebenliegt". Ein Katalog mit „Nutze HTTPS" fällt raus — nicht weil es falsch wäre,
sondern weil das Modell es ohnehin tut. Wer BCQuality mit unseren `rules/*.md` vergleicht,
vergleicht zwei verschiedene Gattungen.

Bemerkenswert und für uns direkt übernehmbar: **negatives Wissen ist gleichwertig.**

> "A file that *prevents* a false positive — documenting why a pattern is legitimate so the
> agent stops flagging it — is as valid as one that catches a defect."
> — [`README.md`](../../README.md)

---

## 2. Aufbau in Zahlen

`[gemessen: 2026-09-09]` auf Fork-Stand `8584217`:

| Ebene | Inhalt |
|---|---|
| Knowledge-Dateien gesamt | **300** `.md` |
| AL-Beispiele | 247 × `.good.al`, 238 × `.bad.al` |
| Action-Skills (Review) | 16 Leafs + 1 Super-Skill |
| Meta-Skills | 4 (`entry`, `read`, `do`, `write`) |
| Host-nativer Plugin-Adapter | 1 (`skills/al-code-review/SKILL.md`) |

### Domänenverteilung — sehr ungleich

| Domäne | Dateien | Domäne | Dateien |
|---|---:|---|---:|
| performance | 65 | data-modeling | 12 |
| style | 35 | breaking-changes | 9 |
| ui | 32 | web-services | 9 |
| security | 25 | error-handling | 8 |
| upgrade | 22 | telemetry | 7 |
| events | 21 | testing | 6 |
| agents *(community)* | 20 | interfaces | 5 |
| privacy | 18 | appsource | 4 |
| | | query | 2 |

**Einordnung:** Performance, Style und UI machen zusammen fast die Hälfte des Korpus aus.
`testing` (6), `appsource` (4) und `query` (2) sind faktisch Platzhalter. Wer BCQuality für
einen AppSource-Review einsetzt, bekommt heute wenig. Für Performance-Reviews ist die
Abdeckung dagegen ernstzunehmen. Das ist beim Pilotieren zu berücksichtigen: **Domäne wählen,
nicht pauschal urteilen.**

---

## 3. Die drei Schichten

```
/microsoft/   Microsoft-gestützt   — 280 Knowledge-Dateien, 16 Review-Skills
/community/   Community            — 20 Knowledge-Dateien (nur Domäne "agents"), 1 Skill
/custom/      Partner/Kunde        — leer im Upstream, unser Fork-Bereich
```

Präzedenz bei **direkt widersprüchlicher** normativer Aussage:
`/custom/` > `/community/` > `/microsoft/` ([`skills/read.md`](../../skills/read.md)).

Zwei Feinheiten, die man kennen muss:

1. **Additiv, nicht ersetzend.** Standardmäßig sieht ein Skill alle Layer und darf aus allen
   Findings melden. Präzedenz greift nur beim echten Widerspruch in `## Best Practice` /
   `## Anti Pattern`.
2. **`enabled-layers` ist kein Sicherheitsmechanismus.** Bei Plugin-Installation liegt der
   ganze Baum auf der Platte:
   > "Treat `BCQUALITY_ENABLED_LAYERS` as a selection filter, never as a security boundary."
   > — [`skills/al-code-review/SKILL.md`](../../skills/al-code-review/SKILL.md)

Der Upstream schützt `/custom/` per Workflow: PRs, die dort Inhalte anfassen, werden
**automatisch geschlossen** — aber nur im Upstream-Repo (die Job-Bedingung prüft
`github.repository`), siehe
[`.github/workflows/guard-custom-layer.yml`](../../.github/workflows/guard-custom-layer.yml).
In unserem Fork greift das nicht. Genau so ist es gedacht.

---

## 4. Das Knowledge-File-Schema

Sechs Frontmatter-Felder, **alle Pflicht** ([`skills/read.md`](../../skills/read.md)):

```yaml
---
bc-version: [all]              # oder [26,27,28] · [26..28] · [26..]
domain: performance            # freier String, keine geschlossene Liste
keywords: [query, filtering]   # 3-10, lowercase, kebab-case
technologies: [al]             # kein "all"-Sentinel erlaubt
countries: [w1]                # oder ISO-Codes; w1 = weltweit
application-area: [all]        # oder finance, manufacturing, …
---
```

Regeln, die beim Selberschreiben leicht übersehen werden:

- `## Description` ist **Pflicht**. `## Best Practice` und `## Anti Pattern` sind die
  einzigen **normativen** Sektionen — nur sie zählen bei Konflikterkennung.
- **Keine Code-Fences in der `.md`.** Beispielcode gehört in Geschwisterdateien
  `<slug>.good.al` / `<slug>.bad.al`.
- Eine Datei, die eine dieser Regeln verletzt, ist ungültig und **muss** übersprungen werden.

### Fehlender Kontext ist kein Match

Wichtiger Mechanismus, den unser Stack so nicht hat: Fehlt eine Dimension im Task-Kontext
(z. B. keine BC-Version bekannt), gilt sie als `unknown` — **nicht** als Treffer und nicht als
Ausschluss. Eine Datei mit `unknown`-Dimension ist *bedingt anwendbar*, und jedes daraus
abgeleitete Finding **muss** `confidence ≤ medium` tragen und die unbekannte Dimension im
`message` nennen.

> "Consumers MUST NOT silently treat missing context as a match."
> — [`skills/read.md`](../../skills/read.md)

---

## 5. Der Ausführungspfad

```
Host-Skill  skills/al-code-review/SKILL.md      (nur Plugin-Installation)
   └─ Routing  skills/entry.md                  → Dispatch-Record (JSON)
        └─ Super-Skill  microsoft/skills/review/al-code-review.md
             └─ 16 Leaf-Skills  al-<domain>-review.md
```

**Entry** ist der einzige Ort, an dem Routing-Logik lebt. Er nimmt einen `task-context`
(`goal`, `inputs-available`, `bc-version`, `enabled-layers`, `disabled-skills`, …) und liefert
einen Dispatch-Record. Er führt selbst nichts aus.

Eine Regel darin ist praktisch relevant: **die engste Skill gewinnt.** Bei Ziel
„performance review" wird der Super-Skill verworfen (`narrower-sub-skill-selected`) und nur
`al-performance-review` dispatched. Wer das nicht weiß, wundert sich über schmale Ergebnisse.

### Der Findings-Report

Jeder Skill liefert **striktes JSON** nach [`skills/do.md`](../../skills/do.md):

- `outcome`: `completed | not-applicable | no-knowledge | partial | failed`
  — `completed` mit leeren `findings` heißt „geprüft, nichts gefunden" und ist ausdrücklich
  *nicht* dasselbe wie `no-knowledge`.
- `severity`: `blocker | major | minor | info`
- `confidence`: `high | medium | low`
- `references[]`: Pfad zur Knowledge-Datei, optional mit SHA
- `suppressed[]`: was per Layer-Präzedenz oder Konfiguration verworfen wurde — Audit-Trail
- `suggested-code`: wörtlicher Ersatztext für die betroffenen Zeilen (für GitHub-`suggestion`-Blöcke)

**Das Herzstück ist der Reference-Integrity-Gate.** Vor dem Emittieren muss der Skill prüfen:
jeder zitierte Pfad existiert, wurde in diesem Lauf tatsächlich geöffnet, und
`findings[].id == references[0].path`. Was das nicht erfüllt, fliegt raus — und darf **nicht**
in ein Agent-Finding umgewandelt werden, nur um es zu retten. Ist die Prüfung nicht möglich:
`outcome: "failed"`.

**Einordnung:** Das ist der stärkste einzelne Baustein des ganzen Repos und der direkteste
Übernahmekandidat für uns. Es macht aus „das Modell behauptet etwas" ein „das Modell zeigt
die Quelle, und die Quelle existiert nachweislich". Siehe [Playbook 5](05-uebernahmekandidaten.md).

### Agent-Findings — der gedrosselte Nebenkanal

Findings ohne Knowledge-Beleg sind erlaubt, aber hart begrenzt: `references: []`,
`id`-Präfix `agent:`, **`confidence` max. `medium`**, **`severity` max. `minor`**. Sie können
also nie ein Gate auslösen. Dazu eine Präzisionsschranke im Klartext:

> "Steelman before emitting. State the strongest case that the code is correct as written …
> If that case is plausible, do not emit." — [`skills/do.md`](../../skills/do.md)

---

## 6. Der Knowledge-Index

Statt 300 Dateien zu öffnen, lesen die Skills eine generierte `knowledge-index.json`.

`[gemessen: 2026-09-09]`

| | |
|---|---|
| Befehl | `pwsh ./tools/Build-KnowledgeIndex.ps1` |
| Ergebnis | 300 Artikel, **155 KB** JSON |
| Laufzeit | **10,3 s** (warm) / 14,4 s (kalt) — Windows 11, PowerShell 7.6.5 |
| Committet? | Nein — steht in `.gitignore` |

Pro Artikel: `path`, `layer`, `domain`, alle vier Filterdimensionen, `keywords`, `title`,
`description`, `parsed`.

⚠️ **Widerspruch zur Doku.** [`skills/entry.md`](../../skills/entry.md) behauptet, der Index
werde „in well under a second" gebaut, und leitet daraus ab: „When in doubt, rebuild."
Gemessen sind es **10–14 Sekunden**. Bei einem Review pro PR ist das irrelevant; bei einem
Rebuild vor jedem Skill-Aufruf ist es das nicht. **Praxisregel für uns: Index einmal pro
Session bauen, nicht pro Aufruf.**

⚠️ **`pwsh` ist eine harte Abhängigkeit** für den Index. Der Adapter fängt das ab
(„If `pwsh` is unavailable or the build fails, continue — READ falls back to path-based
discovery"), aber dann liest der Agent Dateien statt Index — deutlich teurer. Auf jedem
Entwickler-Rechner, der BCQuality nutzt, muss PowerShell 7 installiert sein.

---

## 7. Was CI maschinell erzwingt

| Workflow | Prüft |
|---|---|
| `validate-frontmatter.yml` → `validate_frontmatter.py` (29,7 KB) | Frontmatter-Schema aller Knowledge-Dateien |
| `knowledge-index.yml` → `Test-KnowledgeIndex.ps1` | Index baut und stimmt mit dem Baum überein |
| `review-fixtures.yml` → `Test-ReviewFixtures.ps1` (25,2 KB) | Review-Regressionstests — siehe [Playbook 4](04-vorgehen-start-validierung.md) |
| `guard-custom-layer.yml` | schließt Upstream-PRs, die `/custom/` anfassen |
| `flag-new-top-level.yml` | markiert neue Ordner im Repo-Root (nur Kommentar, kein Block) |

**Einordnung:** Für ein Wissens-Repo ist das eine ungewöhnlich ernsthafte CI. Insbesondere
`review-fixtures.yml` — eine maschinelle Regressionsprüfung der *Review-Qualität* — ist etwas,
das unser Plugin heute nicht hat.

---

## 8. Schwachstellen und offene Punkte

Kritisch und konkret, damit niemand mit falschen Erwartungen startet:

1. **Interner Widerspruch: BC-Fachwissen steckt doch in Skills.**
   [`skills/do.md`](../../skills/do.md) sagt klar: *"Do not add a BC fact to a skill."* Der
   Worklist-Abschnitt von
   [`microsoft/skills/review/al-performance-review.md`](../../microsoft/skills/review/al-performance-review.md)
   enthält aber genau das, z. B.:
   > "Do not match a commit after a complete business unit when the same transaction persists
   > a restart-safe watermark/state and errors propagate."

   Das ist eine BC-Verhaltensaussage im Skill, kein reines Routing. Konsequenz: Der Skill
   driftet gegenüber den Knowledge-Dateien — dieselbe Krankheit, die wir in unserem eigenen
   Stack haben. **Beim Forken beobachten.**

2. **Korpus stark unausgewogen** (siehe Abschnitt 2). `query` = 2 Dateien.

3. **Reifegrad.** Der Roadmap-Epic
   ([Issue #83](https://github.com/microsoft/BCQuality/issues/83)) beschreibt Authoring-Skills,
   Pipeline-Wissen und Power-Platform-Domänen als *geplant*, nicht fertig. Der Community-Layer
   deckt bisher genau eine Domäne ab (`agents`). Breaking Changes sind angekündigt.

4. **Keine offizielle Microsoft-Learn-Dokumentation.** BC-Bench ist auf Learn verankert
   ([Development in AL](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-dev-overview)),
   BCQuality nicht — es existiert nur als GitHub-Repo und in Community-Blogs.
   **Einordnung:** Das ist ein Governance-Risiko. Ein Repo ohne Learn-Verankerung kann
   umgebaut oder eingestellt werden, ohne dass ein Deprecation-Pfad zugesagt ist.

5. **Kein Compiler-Ground-Truth.** BCQuality prüft nichts gegen den AL-Compiler oder die
   Analyzer. Alle Findings sind LLM-Urteile — nur eben mit Zitat. Unser ALCops-Pfad liefert
   hier etwas, das BCQuality strukturell nicht hat. Siehe [Playbook 3](03-vergleich-innonav.md).
