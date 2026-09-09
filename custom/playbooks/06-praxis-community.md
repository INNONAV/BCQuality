# Playbook 6 — Was die Praxis sagt: agentische AL-Entwicklung bei anderen

**Stand:** 2026-09-09
**Quellen:** zwei BC-TechDays-2026-Sessions (V3, V4) — je Aussage Timestamp und wörtliches
Zitat, mechanisch gegen die Roh-Transkripte geprüft (35/35 `OK`). Siehe
[Quellen-Index](quellen/QUELLEN-INDEX.md).

Dieses Playbook enthält **Methoden**, nicht Produktwissen. Es beantwortet: Wie arbeiten
erfahrene BC-Leute heute wirklich mit Agenten — und was raten sie ab?

---

## 1. Der wichtigste Befund für unsere Fragestellung

**BCQuality ist bekannt, aber niemand zeigt es im Einsatz.** In beiden Sessions fällt der Name
— und in beiden bleibt es bei der Erwähnung:

| Wer | Aussage | Charakter |
|---|---|---|
| Sprecher V3 `@62:39` | „probably move to BC quality uh as well." | **Absicht**, keine Erfahrung |
| Sprecher V4 `@40:08` | „Uh BC quality that's its own little talk" | Verweis auf einen anderen Vortrag |
| Sprecher V4 `@41:41` | „definitely part of that story, but it's" | eingeordnet, aber der Kern sei der Verifikationsprozess |
| Publikum V4 `@89:17` | „Yeah. So I started doing what VC quality" | als **Vorbild für Struktur**, nicht als Werkzeug |
| Sprecher V9 `@09:58` | „told about the BC Quality app" | Rückverweis auf einen anderen Vortrag |
| Sprecher V9 `@17:25` | „We can link the same way the BC quality, for example, if we need." | **Möglichkeit** (Submodule), kein Einsatz |
| Sprecher V9 `@47:56` | „Maybe we should then replace that with a basic quality." | **Erwägung** `[unsicher: „a basic quality" ist vermutlich „BC Quality"]` |

Die letzte Zeile ist aufschlussreich für die reale Ausgangslage: Der Sprecher nutzt heute die
**AL Guidelines als heruntergeladene Rules** — „I'm using the AL guidelines to download these
rules" `[V9 @47:39]` — und erwägt, sie durch BCQuality zu ersetzen. Das ist der Status quo,
gegen den BCQuality antritt.

**Einordnung:** Über inzwischen sechs unabhängige Quellen hinweg dasselbe Muster. BCQuality
hat Bekanntheit und konzeptionelle Ausstrahlung (die Zerlegung in viele kleine Skills wird
kopiert), aber **kein einziger Sprecher berichtet von eigenem produktivem Einsatz mit
Ergebnissen.** Es wird verwiesen, erwogen, angekündigt — nicht gezeigt.
`[konvergent: Paper, V1, V2, V3, V4, V8, V9]`

Wenn wir eine Pilotmessung machen ([Playbook 4](04-vorgehen-start-validierung.md)), sind wir
damit nicht spät dran, sondern früh.

Nebenbefund, ebenso bemerkenswert: **klassische Analyzer kommen in beiden Vorträgen nicht
vor** — kein CodeCop, kein AppSourceCop, kein Linter. Qualität wird ausschließlich über
Tests, Skills, Instructions und Pipeline-Reviews diskutiert.
**Einordnung:** Unser ALCops-Ground-Truth ist damit kein Rückstand, sondern ein
Unterscheidungsmerkmal, das im Markt gerade unterbelichtet ist.

---

## 2. Der stärkste übertragbare Satz

> „instructions are just hopes. Tests are contracts." — `[V4 @48:00]`

Der Kontext macht es scharf. In einer Live-Demo setzt der Sprecher den Agenten unter Druck,
und statt den Fehler zu beheben, kommentiert dieser die Prüfungen aus:

> „My assert statements have just been…" — `[V4 @44:00]`

Die daraus abgeleitete Guardrail ist hart und eindeutig:

> „to change the tests. If the tests need…" — `[V4 @47:48]`
> — der Agent **darf** Tests nicht ändern, er muss an den Menschen eskalieren.

Und die Konsequenz für die verbleibende Menschenarbeit:

> „is this test good or bad? Is this…" — `[V4 @48:26]`

**Einordnung — direkt auf uns anwendbar:** Unsere `rules/*.md` und Agent-Prompts sind nach
dieser Logik *Hoffnungen*. Unsere Fixture-Paare aus
[Playbook 5, Rang 2](05-uebernahmekandidaten.md) wären *Verträge*. Das ist dasselbe Argument
wie BCQualitys `review-fixtures`, nur aus der Praxis heraus formuliert — und es stärkt den
Fall für Regressionstests unabhängig von jeder BCQuality-Entscheidung.

Prüfen sollten wir außerdem, ob unser `/test`- und `/verify-tests`-Pfad diese Guardrail
explizit enthält: *Der Agent darf Testerwartungen nicht abschwächen, um einen Lauf grün zu
bekommen.*

---

## 3. Code Review ist nicht tot — alle vier Sprecher widersprechen

Die These „Code Review ist überflüssig, wenn der Agent schreibt" wird in V4 ausdrücklich
referiert (ein bekannter BC-Entwickler prüfe gar nicht mehr, `[V4 @04:20]`) — und dann
zurückgewiesen:

> „read the code any faster. That doesn't…" — `[V4 @41:30]`
> Mehr erzeugter Code macht das Lesen nicht schneller.

Die Praxis-Antwort aus V3 ist eine **Aufteilung in drei Reviews**:

1. Ein Agenten-Review in **komplett frischem Kontext** — „really want this to be a completely"
   `[V3 @76:33]`. Der Reviewer darf nicht wissen, wie der Code entstanden ist.
2. Ein **automatisches Review auf jedem Pull Request** — „will be automatically reviewed with
   pull" `[V3 @78:27]`.
3. Ein fachliches Review durch den Consultant.

Dazu eine Governance-Entscheidung, die wir übernehmen sollten:

> „I me as a manager would like to override…" — `[V3 @79:14]`

Findings werden bewusst als **PR-Kommentar** ausgeliefert, nicht als hartes Gate — damit ein
Verantwortlicher überstimmen kann.

**Einordnung:** Deckt sich exakt mit der Empfehlung in
[Playbook 4, Phase 3](04-vorgehen-start-validierung.md), BCQuality zunächst advisory zu
betreiben. Punkt 1 — frischer Kontext für den Reviewer — ist zudem eine billige Verbesserung
für unseren Stack: unsere Skeptiker teilen sich heute Prompt und Modell mit den Autoren der
Findings.

---

## 4. Kontext ist das eigentliche Handwerk

> „you build a prompt. The job is that you…" — `[V4 @17:29]`
> Die Aufgabe ist nicht, Prompts zu schreiben, sondern die Infrastruktur um den Prompt.

Gemessenes Gegenbeispiel, warum das zählt:

> „We have spent 24,000 tokens just to say…" — `[V4 @25:04]`
> 24.000 Token für ein bloßes „Hello", wenn alle Werkzeuge am Agenten hängen.

Die Antwort darauf:

> „specialized machines. In GitHub copilot…" — `[V4 @26:09]`
> Spezialisierte Agenten mit jeweils wenigen Werkzeugen statt eines Alleskönners.

Und für die Wissensablage der Gegenpol zur Sammel-Instruction:

> „you overload it with a cookbook." — `[V3 @19:18]`
> Alles in eine große Instruction-Datei zu packen ist das Anti-Pattern.

**Einordnung:** Genau die Architektur, die BCQuality mit 300 atomaren Dateien plus Index
umsetzt — und genau das Gegenteil unserer 1.015-Zeilen-`CLAUDE.md`. Das stützt
[Playbook 5, Rang 6](05-uebernahmekandidaten.md), ändert aber nichts an der Reihenfolge:
erst Fixtures, dann Umbau.

Ein praktisches Detail zum Mitnehmen: `[V3 @37:18]` — GitHub Copilot liest `CLAUDE.md`, aber
**nicht** `AGENTS.md`. Wer beide Hosts bedient, muss das wissen.

---

## 5. Der Reflection Loop

Die vielleicht wichtigste Arbeitsmethode aus beiden Sessions:

> „mistake don't fix the mistake. Fix the…" — `[V4 @28:19]`
> Macht die Maschine einen Fehler: nicht den Fehler beheben, sondern die Maschinerie.

Operationalisiert als feste Schlussfrage jeder Session:

> „your instructions or skills so that the…" — `[V4 @29:13]`
> Was muss an Instructions oder Skills geändert werden, damit das nicht wieder passiert?

**Einordnung:** Das ist inhaltlich dasselbe wie BCQualitys Aufnahmeregel — jede Datei existiert,
weil ein Modell ohne sie etwas falsch macht. Nur eben als tägliche Praxis statt als
Repo-Politik. Bei uns gibt es dafür bereits `innonav-it:improve-skill` und
`/submit-feedback`; was fehlt, ist die **Gewohnheit**, sie am Ende einer Session tatsächlich
aufzurufen.

Ergänzende Faustregel zur Modellwahl:

> „build with your big thinking models and…" — `[V4 @37:42]`
> Skills mit den starken Modellen bauen, dann mit günstigen ausführen.

Und aus V3 dieselbe Beobachtung von der anderen Seite:

> „more mature your skills get, the less…" — `[V3 @96:20]`
> Je reifer die Skills, desto schwächer darf das Modell sein.

**Einordnung mit Vorbehalt:** Das steht in Spannung zum BC-Bench-Paper, wo die Modellwahl der
signifikante Faktor war und der Harness nicht (siehe
[Playbook 2, Abschnitt 4](02-oekosystem.md)). Beides kann stimmen — das Paper misst
Bug-Fixing auf fremdem Code, die Sprecher reden über wiederkehrende Aufgaben im eigenen
Repo. Aber wer daraus „wir können auf ein billigeres Modell wechseln" ableitet, sollte das
messen, nicht annehmen.

---

## 6. Wovon abgeraten wird

Der Kernfehler, in einem Satz:

> „approached the tool first instead of the problem first" — *Tool-first statt Problem-first.*

Konkrete Warnungen:

| Warnung | Beleg |
|---|---|
| Nicht mit einem Code-Index-Werkzeug starten — `grep` reicht meist | „Grap is going to be wonderful for most" `[V4 @72:46]` |
| Warnstory: fünf Stunden Werkzeugkonfiguration statt einen Agenten zu bauen | „week configuring Serena." `[V4 @72:10]` |
| Einsparungen sind nicht verlässlich: einmalig ~50 % weniger Credits, aber sofort relativiert | „50% fewer credits on co-pilot" `[V3 @49:06]` / „not always save" `[V3 @49:22]` |
| Nicht jedes MCP ist ein Gewinn — ein Sprecher verwirft den Azure-DevOps-MCP zugunsten der CLI | „DevOps user. I just don't like the MCP." `[V3 @55:49]` |
| Für Flotten-Management gibt es noch keine Best Practices | *„no best practices yet"* |
| Agenten machen niemanden weniger beschäftigt | — |

Die Einstiegsempfehlung dagegen:

> „and build the smallest possible agent…" — `[V4 @73:13]`
> Den kleinstmöglichen Agenten für die kleinste nervige Aufgabe bauen.

**Einordnung:** Direkt auf unser Vorhaben gemünzt heißt das: **nicht** BCQuality vollflächig
ausrollen und dann schauen. Ein Repo, eine Domäne, ein messbarer Vergleich — so ist
[Playbook 4](04-vorgehen-start-validierung.md) auch gebaut.

---

## 6b. Eine Pipeline, die tatsächlich läuft — mit Zahlen

Die Session „Agentic Coding in AL, Done Right" zeigt als einzige eine produktiv laufende
autonome Bug-Fix-Pipeline (Claude Code SDK, containerisiert) mit **vier Gates**:

1. Qualitätsprüfung des Tickets selbst — schlechtes Ticket, kein Lauf
2. Plan-Review, maximal dreimal, danach **menschliche Freigabe**
3. Acht Reviewer, darunter ein **Devil's Advocate**
4. PR wird nur als **Draft** geöffnet

**Gemessene Ergebnisse:** rund **70 % der Bugs autonom gelöst**, **10–25 USD pro Bug**.

**Einordnung:** Das ist die konkreteste Wirtschaftlichkeitszahl der ganzen Recherche. Sie
bezieht sich auf Bug-Fixing, nicht auf Review — aber sie gibt eine Größenordnung dafür, was
ein agentischer Durchlauf kosten darf, bevor er sich nicht mehr rechnet. Die Gate-Architektur
ist unserem Disposition-Loop verwandt und bestätigt ihn.

### Die Kostenwarnung, die man einmal gelesen haben muss

Ein Review-Lauf lief aus dem Ruder: **226 Subagenten**, das **Wochenlimit in 15 Minuten**
aufgebraucht, **30 USD** verbrannt `[V9 @23:53, @24:19]`.

**Für uns:** Unsere Review-Pipeline fächert ebenfalls auf (vier Spezialisten plus ein
Skeptiker pro Finding). Bei einem großen Diff ist derselbe Effekt möglich. Eine harte
Obergrenze für die Zahl paralleler Verifikations-Agents gehört eingebaut, bevor jemand das
bei uns herausfindet.

### Der häufigste AL-Fehler agentisch erzeugten Codes

> „Direct assignment of the value to the field without any validations" `[V9 @34:57]`

Und der Merksatz dazu:

> „AI doesn't always write correct code. But it always writes code that looks correct"
> `[V9 @35:40]`

**Einordnung:** Direktzuweisung statt `Validate` ist ein AL-spezifischer, mechanisch
prüfbarer Defekt — und damit ein Musterbeispiel für eine Knowledge-Datei nach
BCQuality-Aufnahmeregel. Wenn wir eine eigene `/custom/knowledge/`-Datei schreiben, ist das
ein guter erster Kandidat. Vorher prüfen, ob BCQuality sie schon hat.

---

## 7. Was wir mitnehmen

| Erkenntnis | Wohin |
|---|---|
| Tests sind Verträge, Instructions nur Hoffnungen | stärkt [Playbook 5, Rang 2](05-uebernahmekandidaten.md) — Fixtures |
| Agent darf Testerwartungen nicht abschwächen | als Guardrail in unseren `/test`-Pfad prüfen |
| Reviewer in frischem Kontext | billige Verbesserung, adressiert unsere Skeptiker-Schwäche |
| Cross-Modell-Review statt Selbstwiderlegung | [Playbook 5, Rang 4b](05-uebernahmekandidaten.md) |
| Findings als PR-Kommentar, überstimmbar | bestätigt „advisory, kein Gate" in Phase 3 |
| Reflection Loop als Sessionabschluss | Gewohnheit etablieren, Werkzeuge haben wir schon |
| Klein anfangen, Problem vor Werkzeug | Phasenmodell in Playbook 4 |
| Obergrenze für parallele Agents | **neu** — 226-Subagenten-Warnung, in unsere Pipeline einbauen |
| Direktzuweisung statt `Validate` | Kandidat für die erste eigene `/custom/knowledge/`-Datei |
| 10–25 USD pro autonom gefixtem Bug | Wirtschaftlichkeits-Größenordnung |
| BCQuality: bekannt, aber nirgends belegt im Einsatz | wir messen selbst — kein Nachzügler-Risiko |

### Der Querbezug zwischen den Sessions

Die Praxis-Sessions (V3, V4, V9) zeigen ausgereifte Setups, aber **kaum Messdisziplin** — die
genannten Zahlen sind Einzelfälle ohne Kontrollgruppe. Die Microsoft-Sessions (V8, V10)
liefern die Messdisziplin, aber keine BCQuality-Erfahrung.

Ein Detail belegt, warum das zusammengehört: Ein Praxis-Sprecher räumt ein, dass seine eigenen
Modellkostenzahlen **durch einen Messfehler verzerrt** waren — die Thinking-Tokens fehlten
`[V9 @90:33]`. Wer misst, muss auch die Messung prüfen. Genau dafür ist die Disziplin aus
[Playbook 4](04-vorgehen-start-validierung.md) da.

---

## Belastbarkeit dieser Quellen

Konferenzvorträge sind **Erfahrungsberichte, keine Messungen**. Die genannten Zahlen
(600 h → 8 h, 80.000 SQL-Statements → 1, 24.000 Token für „Hello") sind Einzelfälle ohne
Kontrollgruppe. Sie taugen als Illustration, nicht als Planungsgrundlage.

Belastbar ist dagegen die **Konvergenz**: vier Sprecher aus zwei unabhängigen Sessions kommen
bei Code Review, Tests als Guardrail und „klein anfangen" zum selben Ergebnis.
