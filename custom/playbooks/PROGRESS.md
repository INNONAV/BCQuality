# Arbeitsstand — BCQuality-Evaluierung

**Letzte Aktualisierung:** 2026-09-14
**Zweck:** Wiedereinstieg ohne die ganze Vorgeschichte lesen zu müssen.
**Vollständige Analyse:** [README.md](README.md) → Playbooks 1–6.

---

## In einem Satz

Lauf B (Batch B1) ist ausgewertet und **Gate 1 ist erreicht** — 6 verifizierte Befunde
„neu & richtig" gegen 5 Fehlalarme, gemessen gegen die *Maximal*-Baseline A0.
Belegtreue: 50 von 50 Zitaten echt, keine erfundene Quelle.

**Als Nächstes: Batch B2** (`src/ReportTemplates`) — unblockiert und sofort startbar.
A1 und C hängen am ausgefallenen `alcops`-MCP. Alles Operative steht unter
[Wiedereinstieg](#wiedereinstieg--hier-weitermachen).

---

## Erledigt

### Recherche und Wissensbasis
- **12 Videos ausgewertet** (BC TechDays 2026 + Microsoft-Kanal), Auswahl aus der
  vollständigen 34-Session-Playlist. Jedes Zitat mechanisch gegen die Roh-Transkripte
  geprüft: **6 Verifikationsläufe, 174 Zitate, alle verwendeten belegt.**
- Dazu: BC-Bench-Paper (arXiv:2608.20851), Microsoft Learn, 5 MVP-Quellen, eigene Messungen.
- **6 Playbooks + Quellen-Index** unter `custom/playbooks/`. Commits `3c566b4`, `a563d4c`,
  `2e847ff` auf `main`.

### Gate 0 — Werkzeugkette (alle Punkte grün)
| Punkt | Ergebnis |
|---|---|
| PowerShell 7+, git | ✅ 7.6.5 / 2.55.0 |
| `upstream`-Remote auf `microsoft/BCQuality` | ✅ Fork **0 Commits hinterher** |
| Knowledge-Index | ✅ 300 Artikel |
| Review-Fixtures | ✅ PASSED, 34 Cases, 17 Domänen |
| Skill-Namenskollision | ✅ keine (gegen 47 Skills + 19 Commands geprüft) |
| BCQuality-Plugin installiert | ✅ meldet sich als `bcquality:al-code-review` |

Reproduzierbar mit **`pwsh ./custom/playbooks/scripts/Check-Phase0.ps1`** (`-SkipFetch` ohne Netz).

⚠️ **Nachtrag `[gemessen: 2026-09-10]`: Gate 0 prüft den falschen Index.** `Check-Phase0.ps1`
baut und zählt `knowledge-index.json` im Repo-Checkout. Der Skill liest ihn aber aus der
installierten Plugin-Kopie (`~/.claude/plugins/cache/bcquality/bcquality/0.2.0/`), und dort
existierte gar keiner — der Index wird nicht ausgeliefert und war seit der Installation nie
gebaut worden. Lauf B wäre still im Fallback-Modus gelaufen (Dateien lesen statt Index);
Entry sagt ausdrücklich, ein fehlgeschlagener Index-Build sei kein fehlgeschlagener Review.
Vor Lauf B nachgeholt: 300 Artikel, gleiche Zahl wie im Checkout.
**Offen:** `Check-Phase0.ps1` muss den Index dort prüfen, wo der Skill ihn liest.

### Sofortmaßnahmen am INNONAV-Plugin (Repo `ClaudeCodePlugin`)
Drei Lücken, die nichts mit BCQuality zu tun hatten, aber beim Vergleich auffielen:

1. **`pr-review` hatte weder ALCops-Baseline noch Adversarial Verification** — ausgerechnet
   der Pfad, der öffentlich in fremde PRs schreibt. Beides ergänzt (Step 3b und 5a).
2. **Skeptiker teilte sich Modell mit dem Reviewer** — läuft jetzt auf `opus` statt `sonnet`.
3. **Kein maschinenlesbarer Report** — neu `.dev/03-code-review.json` und
   `.dev/pr-review-<id>.json`, mit den Feldern `evidence` und `confidence`.

Commit `6e29447` auf `master` (gepusht). Doku-Nachtrag **[PR #13](https://github.com/INNONAV/ClaudeCodePlugin/pull/13) gemerged** am 2026-09-09 (Merge-Commit `4091952`).

---

## Phase 1 — Gate bestanden, Scope noch offen

**Ziel:** Findet BCQuality auf unserem Code etwas, das unser Review nicht findet?
**Aufwand:** ~1 Tag. Vollständige Anleitung in
[04-vorgehen-start-validierung.md](04-vorgehen-start-validierung.md).

### Repo — entschieden `[2026-09-10]`

**`INNO Header Footer Text`** im Monorepo `INNOApps`, 109 AL-Dateien, 23.668 LOC.
Erfüllt das Auswahlkriterium: ~60 PageExt (UI, 32 Regeln), dazu Style (35) und über
RecordRef- und Posting-Subscriber auch Performance (65). Kein Query-, AppSource- oder
Testing-Schwerpunkt.

**Der Glücksfall:** Für diese App liegt in `App/.dev/review-2026-09-05/` bereits ein
vollständiges INNONAV-Vollreview auf Stand `2429cfe` — ALCops-Baseline mit 585 Diagnosen,
3 Workflows, ~50 Agents, 26 dispositionierte Befunde (S1–S19, W1–W7).

### Ablauf — vier Läufe statt drei

Alle auf demselben Codestand `2429cfe` (Worktree im Scratchpad, Arbeitsbaum unangetastet):

| Lauf | Was | Ablage |
|---|---|---|
| **A0** | das vorhandene Vollreview — Maximal-Baseline | `App/.dev/review-2026-09-05/` |
| **A1** | normaler `/review`-Lauf — Alltags-Baseline | `.dev/vergleich/A1-innonav.md` |
| **B** | `bcquality:al-code-review` allein | `.dev/vergleich/B-bcquality.json` |
| **C** | beides kombiniert | `.dev/vergleich/C-kombiniert.md` |

**Warum A doppelt:** A0 ist kein Alltagslauf. Gegen ~50 Agents mit ALCops-Ground-Truth würde
BCQuality die drei „neu & richtig" mit hoher Wahrscheinlichkeit verfehlen — und ein verfehltes
Gate wäre dann nicht interpretierbar („BCQuality schwach" und „A0 war erschöpfend" sind ohne
A1 nicht unterscheidbar). **Gate 1 wird gegen A1 entschieden**, A0 beantwortet zusätzlich die
härtere Frage.

**Scope:** Kernmodule in zwei Batches — B1 = `HeaderFooterTexts` + `Extensions` + `Foundation`
+ `_Upgrade` (77 Dateien, 8.703 LOC), B2 = `ReportTemplates` (9 Dateien, 11.367 LOC).
Testcode bleibt draußen (Domäne `testing` hat nur 6 Artikel — das misst die Korpuslücke).

Protokoll mit allen Entscheidungen: `App/.dev/vergleich/00-protokoll.md`.

### Ergebnis Lauf B, Batch B1 `[2026-09-10]`

17 Leaves (16 Sub-Skills + `al-agents-review` als Peer), isoliert ausgeführt, 181 von 300
Artikeln evaluiert. **50 Findings** — 0 blocker, 18 major, 24 minor, 8 info; 45 knowledge-backed,
5 agent findings.

**Belegtreue bestanden, ohne Einschränkung:** 50 von 50 zitierten Pfaden existieren,
50 von 50 `id`-Werte stimmen mit `references[0].path` überein, kein zitierter Artikel fällt
bei BC 28 weg. Prüfbar mit `App/.dev/vergleich/Check-Findings.ps1`.

| Kategorie | Zahl |
|---|---|
| neu & richtig (am Code verifiziert) | **6** |
| neu, plausibel, ungeprüft | 32 |
| doppelt | 7 (davon 5 gegen die ALCops-Baseline) |
| falsch positiv | **5** |

**Gate 1 erreicht** (≥ 3 neu & richtig, FP ≤ neu & richtig) — und zwar gegen A0, die härtere
Baseline. Vollständige Auswertung: `App/.dev/vergleich/B-auswertung.md`.

**Der wichtigste Befund ist aber ein anderer:** Alle 5 Fehlalarme stammen aus derselben
Ursache — sie laufen gegen Regeln, die INNONAV im zentralen Ruleset
(`INNONAV/ALRulesets`) bewusst abgeschaltet hat (AA0005, AA0021, AA0073, AA0248, AA0470;
insgesamt stehen dort **54 Regeln auf `action: "None"`**). BCQuality hat für genau diesen
Fall den `/custom/knowledge/`-Layer mit Vorrang vor `/microsoft/` — **unser Layer ist leer.**
Die 54 Ausnahmen liegen maschinenlesbar mit Begründung vor; daraus den Custom-Layer zu
erzeugen ist der billigste konkrete Gewinn aus diesem Lauf und lohnt sich unabhängig davon,
ob BCQuality eingeführt wird.

Zweiter Befund: 3 der 6 verifizierten Treffer sind **Agent-Findings ohne Korpus-Beleg** — sie
messen das Modell, nicht die Wissensbasis.

### Gate 1 — erreicht `[2026-09-10]`

**≥ 3 belegte Befunde** *neu und richtig*, und *falsch positiv* nicht häufiger als
*neu und richtig* → **6 zu 5, bestanden.** Gemessen gegen A0, die härtere Baseline; gegen A1
kann es nur besser ausfallen, weil Fehlalarme baseline-unabhängig sind und *doppelt* nach
*neu* wandert.

Damit ist der Weg frei für Phase 2 (Golden Set) und Phase 3 (Pilot). Vorher sind aber die
drei offenen Läufe zu Ende zu bringen — sonst steht das Gate auf 40 % des Scopes.

---

## Wiedereinstieg — hier weitermachen

### Umgebung wiederherstellen

Zwei Dinge sind **nicht** Teil des Repos und müssen stehen, bevor irgendein Lauf startet:

**1. Knowledge-Index in der installierten Plugin-Kopie.** Nicht im Checkout — dort liegt er
schon und wird nicht gelesen.

```powershell
pwsh "$env:USERPROFILE/.claude/plugins/cache/bcquality/bcquality/0.2.0/tools/Build-KnowledgeIndex.ps1"
```

Erwartung: `300 article(s)`. Fehlt er, läuft der Review still im Fallback-Modus — **ohne
Fehlermeldung**, Entry wertet einen fehlgeschlagenen Index-Build ausdrücklich nicht als
fehlgeschlagenen Review. Nach jedem Plugin-Update erneut nötig.

**2. Worktree auf dem Vergleichsstand.** Alle Läufe müssen denselben Code sehen.

```powershell
cd "C:\Users\d.metzler\Documents\Repo\GitHub\INNOApps"
git worktree list          # steht er noch? Pfad enthält "hf-2429cfe"
git worktree add --detach <neuer-pfad> 2429cfe    # falls nicht
```

Stand 2026-09-14 existiert er noch unter dem Scratchpad-Pfad der Session vom 2026-09-10.
Er liegt im Temp-Verzeichnis und kann jederzeit wegbereinigt werden — **vor dem Verlassen auf
ihn prüfen**, Neuanlage kostet 30 Sekunden.

### Was fehlt, in dieser Reihenfolge

| # | Lauf | Warum in dieser Reihenfolge | Blocker |
|---|---|---|---|
| 1 | **Batch B2** — `src/ReportTemplates` (9 Dateien, 11.367 LOC) | schließt den Scope von Lauf B. Dort liegen **S1, S2, S5** — drei der schwersten A0-Befunde. Bis das nicht gemessen ist, steht Gate 1 auf 8.703 von 20.070 LOC. | keiner |
| 2 | **A1** — normaler `/review`-Lauf auf `2429cfe` | die Alltags-Baseline, gegen die das Gate laut Playbook eigentlich zu entscheiden ist | **`alcops`-MCP** (siehe unten) |
| 3 | **C** — unser Review mit BCQuality als zusätzlicher Quelle | beantwortet die eigentliche Betriebsfrage: bringt die Kombination mehr als jeder Teil allein? | wie A1 |

**B2 ist unblockiert und kann sofort laufen** — mit demselben Aufbau wie B1: Entry-Dispatch,
17 Leaves in isolierten Kontexten, Briefing aus `00-protokoll.md`. Zwei Korrekturen gegenüber
B1 übernehmen:

- **`bc-version: 28` setzen.** In B1 wurde es weggelassen, mit falscher Begründung aus dem
  `app.json` des Arbeitsbaums. Der Stand `2429cfe` sagt `application/platform 28.0.0.0`,
  `runtime 17.0`. Ohne die Angabe sind alle Findings unnötig auf `confidence: medium` gedeckelt.
- **Scope-Hinweis anpassen:** B2 sind Report-Objekte mit RDLC-Bindung, keine Codeunits.

### Blocker für A1 und C

`alcops` meldet `CONNECTION_CLOSED`. A0 hatte 585 ALCops-Diagnosen als Ground Truth — ohne die
ist A1 nicht mit A0 vergleichbar, und der Vergleich verliert seinen Anker.

Zwei Wege: den MCP-Server wieder ans Laufen bringen, oder die Baseline über
`al_compile`/`al_getdiagnostics` aus `al-tools` erzeugen und dokumentieren, dass A1 eine
andere Diagnosequelle nutzt als A0.

**Gute Nachricht:** `al-mcp-server` ist seit 2026-09-14 wieder verbunden. Damit ist die
Playbook-Zusatzfrage messbar geworden — *bekommt ein Agent darüber unsere INNOCop-Diagnostics?*
Das ist laut Playbook 2 der einzige Zusatz mit gemessen signifikanter Wirkung (+5 Pp
resolution rate) und damit unabhängig von BCQuality der billigste Qualitätsgewinn. **Bei A1
gleich mitprüfen.**

### Unabhängig davon: der Custom-Layer

Der konkreteste Gewinn aus Lauf B hängt an keinem der drei Läufe und kann parallel laufen:
aus den **54 auf `action: "None"` gesetzten Regeln** in `INNONAV/ALRulesets` den
`/custom/knowledge/`-Layer erzeugen. Das hätte alle fünf Fehlalarme von B1 verhindert.
Die Regeln liegen mit Begründung als JSON vor.

### Wo was liegt

Alles unter `INNOApps/INNO Header Footer Text/App/.dev/vergleich/` — **untracked, nicht
committet:**

| Datei | Inhalt |
|---|---|
| `00-protokoll.md` | Methode, Scope, alle bewussten Entscheidungen samt dokumentiertem `bc-version`-Fehler |
| `A0-referenzkarte.md` | die 26 A0-Befunde auf Datei und Scope abgebildet — Grundlage für *doppelt* / *übersehen* |
| `B-auswertung.md` | **die Auswertung** — Einsortierung, Gate-1-Rechnung, Methodenbefunde |
| `B-bcquality.json` | Rollup aller 50 Findings nach DO-Contract, mit `sub-results` |
| `raw/B1-*.json` | die 17 Leaf-Rohberichte |
| `B1-entry-dispatch.json` | Entry-Dispatch-Record (2 dispatched, 16 skipped) |
| `Check-Findings.ps1` | Belegtreue-Gate + BC-Versions-Prüfung, wiederverwendbar für B2 |
| `scope-B1.txt` / `scope-B2.txt` | die Dateilisten beider Batches |

Ebenfalls uncommittet: diese `PROGRESS.md` im BCQuality-Fork.

---

## Danach

**Phase 2 — Messen** (2–3 Tage): eigenes Golden Set mit 20–30 Fallpaaren, Hill-Climbing nach
Microsofts Methode (eine Variable pro Lauf), Recall ≥ 0,8 und Clean Rate ≥ 0,9 als Einstiegsziel.
Realitätsanker: Microsofts eigener Review-Agent liegt bei 57 % / 49 %.

⚠️ **Aus Lauf B nachzutragen:** Die Variablenreihe braucht eine **Kontrollgruppe
ohne Korpus**. In B1 war die Hälfte der verifizierten Treffer ein Agent-Finding ohne jeden
Artikel dahinter — ohne Kontrollgruppe schreibt man der Wissensbasis zu, was das Modell
geleistet hat. Konkret als Variable 2a vor der BCQuality-Messung: derselbe Lauf mit
`BCQUALITY_ENABLED_LAYERS` auf einen leeren Layer.

**Phase 3 — Pilot** (4 Wochen): ein Team, advisory, kein Merge-Gate. Gate: Akzeptanzquote
> 60 % und Zitat-Trefferquote 100 %.

**Unabhängig davon** — Playbook 5, Rang 2: Regressions-Fixtures für unser eigenes Plugin,
20 Fallpaare. Das ist die größte verbleibende strukturelle Lücke und kann parallel laufen.

---

## Offene Punkte

| Was | Wer | Anmerkung |
|---|---|---|
| **`alcops`-MCP ausgefallen** | Daniel | `CONNECTION_CLOSED`. **Blockiert A1 und C** — ohne ALCops-Baseline kein Anker gegen A0 |
| `/custom/knowledge/` aus dem Ruleset erzeugen | offen | 54 Regeln auf `action: "None"` in `INNONAV/ALRulesets`; hätte alle 5 Fehlalarme aus B1 verhindert |
| Release-Stand v26/v27 prüfen | Team HF | zwei zurückgehaltene Upgrade-Kandidaten werden zu Datenverlust-Befunden, falls die Elemente ausgeliefert wurden (siehe `B-auswertung.md`, Nebenbefunde) |
| `Message(...)`-Argumente vertauscht an **zwei** Stellen | Team HF | `HeaderFooterTextMgt:1945` **und `:2001`** — BCQuality meldete nur eine |
| `Check-Phase0.ps1` prüft den falschen Index | offen | muss die installierte Plugin-Kopie prüfen, nicht den Checkout — siehe Nachtrag oben |
| Versionsbump `innonav-al-development` | Maintainer | `[Unreleased]` schneiden via `/plugin-version` |
| GitHub-PAT auf ≤ 8 Tage Laufzeit | Daniel | sonst bleibt `microsoft/*` über MCP gesperrt |
| Default-Python 3.14 reparieren | Daniel | defekt (`No module named 'encodings'`), 3.11 läuft |
| Dedizierter Skeptiker-Agent | offen | teilt sich noch den Domänen-Prompt mit dem Reviewer |

---

## Der fachliche Hintergrund — und was die Messung davon bestätigt hat

**Der Kernbefund:** Über 12 Videos, ein Paper und 5 MVP-Quellen hinweg gibt es **keine
einzige Messung und keinen Erfahrungsbericht** zu BCQuality. Es wird verwiesen, erwogen,
angekündigt — nicht gezeigt. Deshalb messen wir selbst, statt zu glauben.

**Drei Befunde, die die Erwartung prägen:**
- **Microsoft stellt den Compiler über die Wissensbasis** („a compile is much cheaper than an
  agentic decision"). Unser ALCops-Ground-Truth ist ein Alleinstellungsmerkmal — in keinem der
  zwölf Videos kommt ein Analyzer überhaupt vor.
- **Zu viel Kontext schadet messbar**: Microsofts Sammel-Instruction kostete 5 %, das Kürzen
  brachte 10 %. Betrifft auch unsere 1.015-zeilige `CLAUDE.md`.
- **Modellwahl schlägt Harness-Wahl** (p = 0,026 gegen p = 0,728). Und nur 2 von 22
  nachanalysierten Fehlschlägen waren vom Typ, den eine Wissensbasis heilt.

**Realistische Erwartung:** Kein großer Sprung. Der plausible Gewinn liegt in
Nachvollziehbarkeit und weniger Fehlalarmen — nicht in „findet mehr". Entsprechend messen:
nicht wie viele Findings kommen, sondern wie viele das Team für berechtigt hält.

### Abgleich nach Lauf B `[2026-09-10]`

Die Erwartung hat gehalten — in beide Richtungen:

| Erwartung aus der Recherche | Messung an B1 |
|---|---|
| Analyzer schlägt Wissensbasis | **bestätigt.** 107 ToolTip-Diagnosen aus ALCops gegen 3 aus BCQuality, 99 XML-Doku-Diagnosen gegen 1. Die Domain `style` — zweitgrößte im Korpus — lieferte 10 Findings: 2 doppelt gegen aktive Regeln, 5 Fehlalarme gegen abgeschaltete Hausregeln, 3 verbleibend. |
| kein großer Sprung | **bestätigt.** 50 Findings, davon 0 `blocker`; 32 der 50 liegen in der größten Datei — die Verteilung folgt der Codemasse, nicht der Kritikalität. |
| Gewinn bei Nachvollziehbarkeit und Fehlalarmen | **bestätigt.** 50 von 50 Zitaten echt. Mehrere Leaves haben echte Kandidaten *selbst widerlegt* statt sie zu melden — gegen `AppSourceCop.json`, gegen Microsoft Learn, gegen das ausgepackte Base-App-Symbolpaket. |
| eine Wissensbasis heilt wenig | **teilweise widerlegt.** Der stärkste Fachdefekt des Laufs — kein Rename-Subscriber für zwölf Dokumenttabellen — kam aus einem kuratierten Artikel. |

**Neu hinzugekommen, in der Recherche nicht vorhergesehen:** Die Hälfte der verifizierten Treffer sind **Agent-Findings ohne Korpus-Beleg**. BCQuality misst sich selbst als Wissensbasis — ein gutes Ergebnis kann trotzdem vom Modell dahinter stammen. Phase 2 muss das trennen: eine Messreihe **ohne** Korpus als Kontrollgruppe, sonst schreibt man dem Korpus zu, was das Modell geleistet hat.

---

## Fork-Pflege

```powershell
git fetch upstream && git merge upstream/main
pwsh ./custom/playbooks/scripts/Check-Phase0.ps1   # nach jedem Sync
```

Der `/custom/`-Layer kann nicht kollidieren — Upstream befüllt ihn nie. Breaking Changes sind
angekündigt; der Fixture-Lauf ist der billigste Weg, sie zu bemerken.
