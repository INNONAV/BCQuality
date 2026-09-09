# Playbook 4 — Vorgehen: starten und validieren

**Stand:** 2026-09-09 · **Zielgruppe:** wer die Einführung umsetzt
**Grundsatz:** Kein Rollout ohne Messung. Jede Phase hat ein Abbruchkriterium.

---

## Leitidee

Wir beantworten nicht die Frage „ist BCQuality gut?", sondern vier Fragen nacheinander, jede
mit einem messbaren Ergebnis und einem Gate:

| Phase | Frage | Aufwand | Gate |
|---|---|---|---|
| **0** | Läuft die Werkzeugkette überhaupt? | 1 h | Fixture-Lauf grün |
| **1** | Findet BCQuality auf *unserem* Code echte Befunde? | 1 Tag | ≥ 3 belegte Befunde, die unser Review nicht hatte |
| **2** | Ist es messbar besser oder schlechter als unser Stack? | 2–3 Tage | Precision/Recall gegen ein eigenes Golden Set |
| **3** | Hält es im echten Betrieb? | 4 Wochen | Akzeptanzquote der Findings im Team |

Wer nur wenig Zeit hat: **Phase 0 und 1 sind der Kern.** Sie kosten zusammen gut einen Tag
und beantworten schon, ob sich das Weiterlesen lohnt.

---

## Phase 0 — Werkzeugkette (1 Stunde)

### Voraussetzungen

| Werkzeug | Wozu | Prüfen mit |
|---|---|---|
| PowerShell 7+ | Index-Build, Fixture-Harness | `pwsh --version` |
| Git | Fork-Sync | `git --version` |
| Claude Code | Plugin-Host | vorhanden |

`[gemessen: 2026-09-09]` PowerShell 7.6.5 reicht.

### Ein Befehl statt vier

```powershell
pwsh ./custom/playbooks/scripts/Check-Phase0.ps1
```

Das Skript prüft alles vier auf einmal — Voraussetzungen, Upstream-Abstand, Index-Build,
Fixture-Lauf — und endet mit **GATE 0 BESTANDEN** oder einer Liste dessen, was fehlt. Es
ändert nichts am Repo außer der ohnehin ignorierten `knowledge-index.json` und legt den
`upstream`-Remote an, falls er fehlt. Ohne Netz: `-SkipFetch`.

Referenzlauf `[gemessen: 2026-09-09]`, Windows 11, PowerShell 7.6.5:

```
[ OK ] PowerShell 7+          7.6.5
[ OK ] git                    git version 2.55.0.windows.3
[ OK ] Fork aktuell           0 hinterher, 1 eigene Commits
[ OK ] Index gebaut           300 Artikel in 3.9s
[ OK ] Fixtures               PASSED: 34 cases cover 17 leaf domains (1.9s)
GATE 0 BESTANDEN
```

⚠️ Die Laufzeiten schwanken erheblich — derselbe Index-Build dauerte in zwei Läufen 3,9 s und
22,6 s (Cache-Zustand). Das ist unkritisch, bestätigt aber die Regel aus
[Playbook 1](01-bcquality-verstehen.md): **Index einmal pro Session bauen, nicht pro Aufruf** —
und widerlegt die Behauptung der Upstream-Doku, der Build laufe „well under a second".

### Was das Skript einzeln tut

| Prüfung | Befehl dahinter | Erwartung |
|---|---|---|
| Voraussetzungen | `pwsh --version`, `git --version` | PowerShell **7+** (5.1 reicht nicht) |
| Upstream-Abstand | `git fetch upstream` + `rev-list --count` | Hinterherhinken ist ein Hinweis, kein Fehler |
| Index | `tools/Build-KnowledgeIndex.ps1` | ~300 Artikel |
| Fixtures | `tools/Test-ReviewFixtures.ps1 -Root .` | PASSED, 34 Cases, 17 Domänen |

**Gate 0:** Exit-Code 0. Sonst hier stoppen — ohne Index arbeiten die Skills im teuren
Fallback-Modus (Dateien lesen statt Index).

### Fork-Anschluss

`[erledigt: 2026-09-09]` Der `upstream`-Remote auf `microsoft/BCQuality` ist eingerichtet, der
Fork war beim Check **0 Commits hinterher**. Sync später mit:

```powershell
git fetch upstream && git merge upstream/main
```

Der `/custom/`-Layer kann dabei nicht kollidieren — Upstream befüllt ihn nie. Nach jedem Sync
`Check-Phase0.ps1` erneut laufen lassen: Breaking Changes sind angekündigt, und der
Fixture-Lauf ist der billigste Weg, sie zu bemerken.

### BCQuality als Claude-Code-Plugin einbinden

Das Repo bringt `plugin.json` und `.claude-plugin/marketplace.json` (Version `0.2.0`) bereits
mit. Registriert wird **ein** Skill: `al-code-review`.

**Immer die Fork-URL verwenden** (`INNONAV/BCQuality`), nicht `microsoft/BCQuality` — sonst
fehlt unser `/custom/`-Layer.

#### Namenskollision — geprüft, keine

`[gemessen: 2026-09-09]` Abgleich von `al-code-review` gegen alle 47 Skill-Namen und
19 Command-Namen der `innonav-*`-Plugins: **keine Kollision**. Unsere heißen `review`
(Command), `pr-review` und `analyze`. Der Name ist auch bewusst nicht `al-review` — den
belegt BC-ALAgents.

Relevant, weil manche Hosts alle Plugin-Skills in **eine** gemeinsame Namensliste laden.

#### Routing-Überschneidung — die gibt es sehr wohl

Kein Namenskonflikt heißt nicht, dass das Richtige triggert. Die Beschreibungen überlappen
deutlich:

| Skill | deckt ab |
|---|---|
| BCQuality `al-code-review` | „AL pull request, working-tree diff, branch, or individual AL file" |
| unser `/review` | „across files or a branch" |
| unser `/analyze` | „a single file" |
| unser `pr-review` | remote PR |

Ein „review this AL file" kann damit bei beiden landen.

**Regel für den Pilot: BCQuality immer explizit aufrufen**, nie implizit triggern lassen —
sonst weißt du hinterher nicht, welcher Stack das Ergebnis erzeugt hat, und der Vergleich in
Phase 1 ist wertlos. Das deckt sich mit der Community-Erfahrung, dass das Plugin zuverlässiger
arbeitet, wenn man ausdrücklich um einen Review bittet.

⚠️ Der Skill hieß bis Version `0.2.0` `bcquality-al-review`. Alte Allowlists und explizite
Aufrufe müssen angepasst werden.

---

## Phase 1 — Erstkontakt auf echtem Code (1 Tag)

**Ziel:** Herausfinden, ob BCQuality auf unserem Code etwas findet, das wir nicht schon wissen.

### Repo-Auswahl

Nimm **ein** Kunden-Repo mit diesen Eigenschaften:
- aktiv entwickelt, damit Findings jemanden interessieren
- schwerpunktmäßig **Performance oder UI oder Style** — dort ist der Korpus dicht (65/32/35
  Artikel). **Nicht** mit `query` (2 Artikel), `appsource` (4) oder `testing` (6) starten,
  sonst misst man die Korpuslücke statt die Methode.

### Durchführung

Drei Läufe über **denselben** Diff, Ergebnisse getrennt ablegen:

| Lauf | Was | Ablage |
|---|---|---|
| A | unser `/review` wie bisher | `.dev/vergleich/A-innonav.md` |
| B | BCQuality-Skill `al-code-review` allein | `.dev/vergleich/B-bcquality.json` |
| C | beides, unser Review mit BCQuality als zusätzlicher Quelle | `.dev/vergleich/C-kombiniert.md` |

### Auswertung — die vier Kategorien

Jedes Finding aus B in genau eine Schublade:

| Kategorie | Bedeutung | Was es uns sagt |
|---|---|---|
| **Neu & richtig** | BCQuality fand es, wir nicht, es stimmt | ← der eigentliche Mehrwert |
| **Doppelt** | beide fanden es | kein Gewinn, aber Bestätigung |
| **Falsch positiv** | BCQuality fand es, es stimmt nicht | Kosten |
| **Übersehen** | wir fanden es, BCQuality nicht | Korpuslücke |

Für jedes „Neu & richtig" den zitierten Knowledge-Pfad notieren — daraus wird später die
Liste der Artikel, die sich für uns wirklich rechnen.

### Gleich mitprüfen: AL-MCP mit eigenen Cops

Der einzige Zusatz mit **gemessen signifikanter** Wirkung ist nicht BCQuality, sondern der
AL-MCP-Server (+5 Pp resolution rate, +10 Pp pass@5, [Playbook 2](02-oekosystem.md)) — weil
der Agent damit kompilieren und Symbole suchen kann. Und er lässt Analyzer über die
LSP-Verbindung mitlaufen, inklusive eigener Cops (Parameter beim MCP-Start) `[V12]`.

**Prüfe deshalb in Phase 1 gleich mit:** Bekommt ein Agent über AL-MCP unsere
INNOCop-Diagnostics? Wenn ja, ist das der billigste echte Qualitätsgewinn der ganzen Liste —
unabhängig davon, wie BCQuality abschneidet.

**Gate 1:** Mindestens **3 belegte Befunde** der Kategorie *Neu & richtig*, und
*Falsch positiv* nicht höher als *Neu & richtig*.
Wird das verfehlt: nicht weitermachen. Stattdessen [Playbook 5](05-uebernahmekandidaten.md) —
die Mechanik übernehmen, das Wissen liegen lassen.

### Belegtreue prüfen — nicht überspringen

Ein zitierender Reviewer ist nur so viel wert wie seine Zitate. Prüfe für jedes Finding aus B
mechanisch, ob `references[0].path` wirklich existiert:

```powershell
$r = Get-Content .dev/vergleich/B-bcquality.json -Raw | ConvertFrom-Json
$r.findings | ForEach-Object {
    $p = $_.references[0].path
    [pscustomobject]@{
        Id     = $_.id
        Pfad   = $p
        Exists = if ($p) { Test-Path $p } else { 'agent-finding' }
        IdOk   = ($_.id -eq $p)
    }
} | Format-Table -AutoSize
```

**Jede Zeile mit `Exists = False` ist eine erfundene Quelle** und ein K.-o.-Kriterium für den
Beleg-Anspruch. Der Reference-Integrity-Gate in [`skills/do.md`](../../skills/do.md) soll das
verhindern — hier prüfen wir, ob er in der Praxis hält.

---

## Phase 2 — Messen (2–3 Tage)

Ab hier wird es quantitativ. Zwei Wege, unterschiedlich teuer.

### Die Methode: Hill Climbing — von Microsoft übernommen

Bevor es um Werkzeuge geht, das Vorgehen. Microsoft beschreibt es in der TechDays-Keynote
explizit, und es ist genau das, was wir brauchen:

1. **Baseline messen, ohne jedes Extra** — „no specialized agents, no instructions, no tools"
   `[V6 @01:03:48]`. Bei uns: unser Review-Stack ohne BCQuality.
2. **Eine Variable ändern, messen, entscheiden.** „one variable at a time, you measure it"
   `[V6 @01:03:48]` — steigt die Genauigkeit, behalten; sonst zurücknehmen.
3. Erst danach die nächste Variable.

**Warum das hier zwingend ist:** Wenn wir BCQuality, ein neues Modell und geänderte
Instructions gleichzeitig einführen, wissen wir hinterher nicht, was gewirkt hat. Microsoft
hat mit genau dieser Disziplin herausgefunden, dass ihre große Sammel-Instruction das
Ergebnis um 5 % *verschlechterte* — bei einem Sammel-Rollout wäre das nie aufgefallen.

**Konkrete Variablen-Reihenfolge für uns:**

| # | Variable | Erwartung |
|---|---|---|
| 0 | Baseline: unser Review, aktuelles Modell, ALCops an | Referenzwert |
| 1 | Modell wechseln (stärkstes verfügbares) | laut Paper der größte Einzelhebel |
| 2 | BCQuality additiv dazu | die eigentliche Frage |
| 3 | Instructions kürzen statt erweitern | siehe 5-%-Befund |

### Die Regeln dazu — aus Microsofts eigener Hill-Climbing-Session

Eine ganze TechDays-Session behandelt nichts anderes als diese Methodik. Die sechs Regeln
daraus, alle direkt auf uns anwendbar:

1. **Wirklich nur eine Änderung pro Lauf.** Sonst
   „you don't even know which one of the changes … influence the metric" `[V10 @07:44]`.
   Dann behalten oder zurücknehmen — zehn bis mehrere hundert Iterationen sind normal.
2. **Eine Kernmetrik festlegen**, nicht fünf. Microsoft nutzt F-beta. Für uns: eine Zahl, die
   Recall und Falsch-Positive gewichtet zusammenfasst, plus Token als Nebenzielgröße.
3. **Ground Truth muss stimmen.** Der zweitgrößte Sprung in ihrer eigenen Messreihe kam
   nicht aus einer Modell- oder Prompt-Änderung, sondern aus der **Korrektur der eigenen
   fehlerhaften Ground Truth** (88 % → 91 %). Ein Golden Set mit falschen Erwartungen misst
   Unsinn, egal wie sauber der Rest ist.
4. **Baseline absichtlich schwach ansetzen.** Mit einem bewusst simplen Prompt starten, damit
   die Verbesserungen sichtbar werden.
5. **Modellversion pinnen.** Jedes Modell-Update erzwingt eine Re-Evaluierung. Tragbar ist
   das nur, weil ihre Pipeline in einer halben Stunde durchläuft — unsere sollte das auch.
6. **Overfitting im Blick behalten.** Wenn eine KI den Prompt gegen den Eval-Datensatz
   optimiert, optimiert sie irgendwann den Datensatz statt die Fähigkeit. Ein zurückgehaltenes
   Testset ist Pflicht.

Ihre gemessene Iterationsreihe als Größenordnung: schlankeres Schema plus Feldbeschreibungen
plus Validatoren → **88 %**; Ground-Truth-Korrektur → **91 %**; Modellwechsel plus Werkzeuge
plus Validator-Rückkopplung → **95,5–96 %**. Freigabeschwelle intern: **> 95 %**.

**Der für uns wichtigste Einzelbefund daraus:** Ein **skill-optimierter Prompt schlug den
handgeschriebenen Produktions-Prompt in allen Modellklassen**. Ein stärkeres Modell kostete
+30 %. Anders gesagt — Prompt- und Kontextarbeit war hier der billigere Hebel als das teurere
Modell. Das steht in produktiver Spannung zum BC-Bench-Paper, wo die Modellwahl der
signifikante Faktor war. Beides kann stimmen: Das Paper misst Bug-Fixing auf fremdem Code,
diese Session eine eng umrissene, wiederkehrende Aufgabe. **Für uns heißt das: Schritt 1
(Modell) und Schritt 3 (Kontext) beide messen und nicht vorab entscheiden, welcher gewinnt.**

### Weg A — Eigenes Golden Set (empfohlen für den Start)

Baue eine INNONAV-Variante des Fixture-Harness. Die Mechanik steht schon:
[`evaluation/README.md`](../../evaluation/README.md).

1. **20–30 Fälle aus echten Reviews sammeln.** Für jeden Fall:
   - eine `.bad.al` mit genau einem bekannten Verstoß
   - eine `.good.al`, die denselben Code korrekt umsetzt (Kontrolle für False Positives)
   - die erwartete Regel-ID bzw. den erwarteten Knowledge-Pfad

   Quelle: unsere `.dev/03-code-review.md`-Historie und die ALCops-Baselines.

2. **Neutralisieren** — Case-IDs hashen, `Good`/`Bad` aus Objektnamen entfernen,
   Kommentarzeilen löschen. Das Harness macht das bereits; wir müssen es nur nachbauen oder
   die Fälle in die BCQuality-Struktur legen.

3. **Beide Stacks gegen dieselben Fälle laufen lassen** und zwei Zahlen bilden:
   - **Recall** — Anteil der Fälle, in denen der erwartete Verstoß gefunden wurde
   - **Clean Rate** — Anteil der `.good.al`, auf denen **kein** Finding entstand

   BCQuality setzt beide Schwellen auf `1.0`
   ([`evaluation/review-fixtures.json`](../../evaluation/review-fixtures.json)). Als
   Einstiegsziel für uns realistischer: **Recall ≥ 0,8 und Clean Rate ≥ 0,9.**

   **Realitätsanker:** Microsofts eigener Code-Review-Agent erreicht **57 % Kommentar-Accuracy
   und 49 % Severity-Accuracy** `[V8 @26:57, @27:12]`. Wer sich 90 % vornimmt, misst am Ende
   nur die eigene Enttäuschung.

4. **Wiederholungen — aber nicht gleich fünf.** BC-Bench nutzt `repeat: 5`; die
   TechDays-Session rät Einsteigern ausdrücklich zu weniger: 2–3 Läufe reichen oft für
   Signifikanz, und man soll mit **einem** Lauf und dem **günstigsten** Modell anfangen —
   „it is a real cost to run these" `[V8 @33:31]`. Für uns heißt das: mit 1 Lauf die Mechanik
   prüfen, dann auf 3 gehen, 5 nur für eine Entscheidung mit Tragweite.

**Kosten:** Ein voller BCQuality-Fixture-Lauf sind 34 Requests à ~17,8 KB
`[gemessen: 2026-09-09]`, zusammen ~150k Token. Bei drei Wiederholungen über zwei
Konfigurationen liegt man im niedrigen einstelligen Euro-Bereich pro Durchgang.

### Weg B — BC-Bench (aussagekräftiger, teurer)

BC-Bench unterstützt Claude Code als Runner und kann Plugins laden — genau unser Fall.

**Voraussetzungen** (aus dem Microsoft-Video, wörtlich belegt): „you will have to have a
GitHub account and a subscription to one of the agent" `[V2 @10:31]`. Das Repo ist
MIT-lizenziert und öffentlich.

**Zwei Wege für eigene Tasks**, beide von Microsoft genannt:

- Eigene Fälle ins offizielle Dataset beitragen — „partners can simply plug in this own uh
  their own code base in in the data set" `[V1 @26:33]`. Ein Partner-Dataset ist geplant.
- Oder: „fork the repository. It's MIT-licensed and public. Uh replace…" `[V2 @11:12]` —
  Dataset durch eigene Tasks ersetzen, privates Repo. Konkret: forken, alle Microsoft-Tasks
  löschen, eigene einsetzen `[V8 @31:06]`.

⚠️ **Eine Ehrlichkeit, die unsere Erwartung dämpft:** Microsofts Code ist öffentlich und in
den Modellen mittrainiert. Für privaten Partnercode gilt laut derselben Session
„there will be a gap" `[V8 @31:26]` — Ergebnisse auf unserem Kundencode werden also
tendenziell schlechter ausfallen als die Leaderboard-Werte. Ein weiterer Grund, den eigenen
Golden-Set-Weg (Weg A) nicht als Notlösung zu betrachten, sondern als den aussagekräftigeren.

⚠️ **Kostenwarnung direkt von Microsoft:** Eine Neuberechnung aller Ergebnisse nach jedem
Harness-Update sei „simply too expensive" `[V2 @09:47]`. Wenn Microsoft das sagt, sollten wir
nicht planen, den vollen Benchmark regelmäßig laufen zu lassen. **Für uns heißt das: Weg A
(eigenes Golden Set) ist der Regelbetrieb, Weg B eine einmalige Standortbestimmung.**

```bash
# Fork von microsoft/BC-Bench (externe PRs werden nicht angenommen)
# Konfiguration: src/bcbench/agent/shared/config.yaml
#   plugins:            -> unser Plugin bzw. BCQuality
#   instructions.enabled -> Nudge, damit Skills auch benutzt werden
#   mcp.servers          -> alcops, al-tools

# Smoke-Test, ein Task, ~2 min
uv run bcbench run copilot microsoft__BCApps-5633 --category bug-fix --repo-path /pfad/zu/BCApps
```

Dann die Stufen aus `EXPERIMENT.md`: Test-Run (4 Einträge, ~10 min) → einzelner Full-Run →
`repeat: 5`.

**Vorher die Hypothese aufschreiben**, z. B.: *„BCQuality als Plugin hebt die Resolution Rate
in `code-review` um mindestens 5 Prozentpunkte, weil AL-spezifische Fehlannahmen des Modells
korrigiert werden."* Ohne Hypothese ist das Ergebnis nicht interpretierbar.

⚠️ **Zwei Fallen, beide aus den Quellen belegt:**

- **Skills sind diskretionär.** Der Agent sieht sie, nutzt sie aber nur, wenn er will. Ohne
  `instructions.enabled: true` plus Nudge misst man womöglich, dass der Skill nie aufgerufen
  wurde — nicht, dass er nichts bringt.
- **Die Kategorie `code-review` ist die richtige.** `bug-fix` und `test-generation` messen
  Codeerzeugung, nicht Review-Qualität. Ein BCQuality-Effekt ist dort systematisch schwer
  nachweisbar.

### Was das Paper für unsere Erwartung bedeutet

Realistische Erwartungshaltung, damit niemand enttäuscht wird:

- **Modellwahl wirkt stärker als Harness-Wahl** (p = 0,026 für Modell vs. p = 0,728 / 0,075
  für Harness). Wenn wir Ergebnisqualität wollen, ist das aktuelle Top-Modell der größere
  Hebel als jede Wissensbasis.
- Nur **2 von 22** nachanalysierten Fehlschlägen gingen auf *Wrong AL/API Usage* zurück —
  also auf genau das, was BCQuality heilt. Die großen Blöcke waren *Incomplete Fix* (10) und
  *Incorrect Business Logic* (10).
- **Microsofts einziger gemessener Tooling-Effekt war nicht nachweisbar.** Zum AL-MCP-Server:
  „the short answer is not conclusively" `[V1 @14:41]`, und
  „we cannot claim that the the tools we're building made it better" `[V1 @15:07]`.
- **Das offizielle Dataset misst nicht unseren Code.** Microsoft sagt das selbst: die Tasks
  stammen aus eigenen Repos und sind damit „not representative for your solution" `[V2 @10:04]`.
  Ein guter BC-Bench-Wert ist deshalb kein Beleg dafür, dass es bei unseren Kunden wirkt —
  ein weiterer Grund, Weg A ernst zu nehmen.

**Einordnung:** Ein großer Sprung ist unwahrscheinlich. Der plausible Gewinn liegt woanders —
in **Nachvollziehbarkeit** und **weniger False Positives**, nicht in „findet mehr".
Das sollte man auch so messen: Nicht nur „wie viele Findings?", sondern
**„wie viele Findings hält das Team für berechtigt?"**

---

## Phase 3 — Pilotbetrieb (4 Wochen)

**Geltungsbereich:** ein Team, ein bis zwei Repos, freiwillige Teilnahme.

**Betriebsmodell:** BCQuality **additiv** zu unserem Review, nicht als Ersatz. Der
ALCops-Ground-Truth und die Adversarial Verification bleiben.

**Blockiert nichts.** Findings sind advisory, kein Merge-Gate. Erst wenn Precision belegt ist,
lässt sich über ein Gate reden — und dann nur für `blocker`-Severity mit
Knowledge-Beleg, nie für Agent-Findings (die sind per Kontrakt auf `minor` gedeckelt).

### Wöchentliche Kennzahlen

| Kennzahl | Wie erhoben | Zielkorridor |
|---|---|---|
| Akzeptanzquote | ACCEPT-FIX ÷ alle Findings | **> 60 %** |
| False-Positive-Rate | DISMISS mit Begründung ÷ alle | **< 20 %** |
| Zitat-Trefferquote | Findings mit existierendem `references[0].path` | **100 %** |
| Laufzeit pro Review | Wallclock | im Rahmen des bisherigen Reviews |
| Token pro Review | Host-Telemetrie | dokumentieren, kein Zielwert |

**Gate 3:** Akzeptanzquote > 60 % **und** Zitat-Trefferquote 100 %.
Verfehlt → zurück zu [Playbook 5](05-uebernahmekandidaten.md), nur die Mechanik übernehmen.

---

## Betriebsentscheidungen, die vorab zu klären sind

### Fork-Pflege

Wir arbeiten auf `INNONAV/BCQuality` (Fork von `microsoft/BCQuality`).

- **Upstream-Sync**: monatlich `git fetch upstream && git merge upstream/main`. Der
  `/custom/`-Layer kann dabei nicht kollidieren — Upstream fasst ihn nie an (der
  `guard-custom-layer`-Workflow schließt solche PRs dort automatisch).
- **Breaking Changes sind angekündigt.** Nach jedem Sync: `Build-KnowledgeIndex.ps1` und
  `Test-ReviewFixtures.ps1` laufen lassen, bevor jemand damit arbeitet.
- **Eigene Inhalte gehören nach `/custom/knowledge/` und `/custom/skills/`** — nach demselben
  Frontmatter-Schema ([Playbook 1, Abschnitt 4](01-bcquality-verstehen.md)). Nur so greift die
  Layer-Präzedenz und nur so bleibt der Merge sauber.

### Was NICHT in den Fork gehört

- Kundencode, Kundennamen, Tenant-IDs, Telemetriedaten. Der Fork ist auf GitHub; unsere
  `/custom/`-Knowledge-Dateien sind **generische AL-Muster**, keine Kundenartefakte.
- Beim Herausdestillieren einer Regel aus Kundencode: Objektnamen und Feldnamen abstrahieren,
  bevor sie in eine `.bad.al` wandern.

### Rollen

| Rolle | Aufgabe |
|---|---|
| Fork-Maintainer | Upstream-Sync, CI grün halten, `/custom/`-Reviews |
| Pilot-Team | Phase 1 und 3 durchführen, Findings dispositionieren |
| Plugin-Maintainer | [Playbook 5](05-uebernahmekandidaten.md) umsetzen |

---

## Zusammengefasst als Checkliste

```
[x] Phase 0  Check-Phase0.ps1 gruen (pwsh, Fork, Index, Fixtures)   [2026-09-09]
[x] Phase 0  upstream-Remote eingerichtet, Fork 0 Commits hinterher [2026-09-09]
[x] Phase 0  Skill-Namenskollision geprueft — keine                 [2026-09-09]
[ ] Phase 0  BCQuality-Plugin mit FORK-URL installiert (interaktiv)
[ ] Phase 1  Repo mit dichter Domäne gewählt (performance/ui/style)
[ ] Phase 1  Läufe A/B/C über denselben Diff
[ ] Phase 1  Findings in 4 Kategorien einsortiert
[ ] Phase 1  Zitat-Existenz mechanisch geprüft
[ ] GATE 1   >= 3x "Neu & richtig", FP <= Neu&richtig
[ ] Phase 2  Golden Set 20-30 Faelle mit .good.al-Kontrolle
[ ] Phase 2  Hypothese schriftlich vor dem ersten Lauf
[ ] Phase 2  >= 3 Wiederholungen je Konfiguration
[ ] GATE 2   Recall >= 0,8 und Clean Rate >= 0,9
[ ] Phase 3  Pilot 4 Wochen, advisory, kein Merge-Gate
[ ] GATE 3   Akzeptanz > 60 %, Zitat-Trefferquote 100 %
```

---

## Was unabhängig von jeder BCQuality-Entscheidung sofort zu tun ist

Diese drei Punkte kamen bei der Analyse heraus und haben nichts mit BCQuality zu tun. Sie
sollten nicht auf das Ergebnis der Phasen warten:

1. **`pr-review` bekommt ALCops-Baseline und Adversarial Verification.** Der Pfad, der
   öffentlich in fremde PRs schreibt, ist heute unser ungeprüftester.
2. **Skeptiker-Agent vom Autor-Agent trennen.** Derselbe Prompt und dasselbe Modell zur
   Selbstwiderlegung ist keine unabhängige Verifikation.
3. **Findings-Report zusätzlich als JSON auf Platte schreiben.** Ohne das ist nichts von
   Phase 2 automatisierbar — und zwar für keinen der beiden Stacks.
