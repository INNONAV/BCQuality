# Playbook 5 — Was wir für unser eigenes Plugin übernehmen sollten

**Stand:** 2026-09-09 · **Zielgruppe:** Maintainer von `INNONAV/ClaudeCodePlugin`

Diese Liste gilt **auch dann**, wenn wir BCQuality am Ende nicht einsetzen. Es sind
Mechaniken, keine Inhalte — und sie beheben Lücken, die in
[Playbook 3, Abschnitt 4](03-vergleich-innonav.md) belegt sind.

Sortiert nach Nutzen ÷ Aufwand.

---

## Rang 1 — Findings-Report als JSON auf Platte

**Problem:** Unser Review erzeugt `.dev/03-code-review.md` — Markdown. Das JSON-Schema
existiert nur flüchtig als Rückgabewert im `ultracode`-Workflow-Pfad und wird nie geschrieben.
Damit ist unser Review **nicht messbar, nicht CI-fähig, nicht gegen ein Golden Set prüfbar**.

**Übernahme:** Das Schema aus [`skills/do.md`](../../skills/do.md) adaptieren. Der Markdown-Report
bleibt für Menschen; das JSON kommt zusätzlich.

```json
{
  "skill": { "id": "innonav-al-review", "version": 1 },
  "outcome": "completed",
  "summary": { "counts": { "blocker": 0, "major": 2, "minor": 5, "info": 0 } },
  "findings": [
    {
      "id": "PC0031",
      "severity": "major",
      "confidence": "high",
      "domain": "Performance",
      "message": "…",
      "location": { "file": "src/…/Foo.Codeunit.al", "line": 140 },
      "references": [ { "path": "rules/al-performance.md" } ],
      "evidence": "alcops-baseline",
      "suggested-code": "…"
    }
  ],
  "suppressed": []
}
```

Zwei Erweiterungen gegenüber BCQuality, die zu **uns** passen:

- **`confidence`** übernehmen (haben wir gar nicht) — und an dieselbe Semantik koppeln:
  unbekannte Kontextdimension ⇒ höchstens `medium`.
- **`evidence`** ergänzen (hat BCQuality nicht): `alcops-baseline` | `knowledge` | `agent`.
  Damit ist auf einen Blick sichtbar, was Compiler-belegt ist und was LLM-Urteil.

**Aufwand:** klein. **Nutzen:** Voraussetzung für alles Weitere.

---

## Rang 2 — Regressions-Fixtures für die Review-Qualität

**Problem:** Wir haben **keinen** Test der Review-Qualität. Eine einzige Eval-Datei im ganzen
Repo, und die betrifft UAT-Generierung. Jede Prompt-Änderung ist ungetestet — der `CHANGELOG`
belegt zwei bereits eingetretene Drift-Fehler (`ReadIsolation::` statt `IsolationLevel::`;
ein SetLoadFields-Absolutum, das PC0031 widersprach). Beide hätte ein Fixture gefangen.

**Übernahme:** Die Mechanik aus [`evaluation/README.md`](../../evaluation/README.md) und
[`tools/Test-ReviewFixtures.ps1`](../../tools/Test-ReviewFixtures.ps1) nachbauen.

Die vier Ideen, auf die es ankommt:

1. **Paare statt Einzelfälle.** Zu jedem `.bad.al` ein `.good.al`. Der `.good.al`-Fall ist die
   **False-Positive-Kontrolle** — mindestens so wertvoll wie der Positivfall.
2. **Neutralisierung.** Case-IDs hashen, `Good`/`Bad` aus Objektnamen entfernen,
   ganzzeilige Beispielkommentare löschen. Sonst rät das Modell die Antwort aus dem Namen.
3. **Zwei Schwellen**, getrennt gemessen: `expectedRecall` und `cleanRate`.
4. **Konventionsgetrieben.** Das Harness entdeckt Fälle über Namenskonvention; eine neue
   Regel braucht keine Änderung am Scoring-Vertrag. Nur Ausnahmen stehen in einer JSON.

**Startumfang:** 20 Paare für die Regeln, die wir am häufigsten melden — PC0031, AC0029,
INN0001, INN0004, DataClassification, ToolTip. Danach: **jede neue Hausregel bringt ihr
Fixture-Paar mit**, sonst wird sie nicht gemerged.

**Aufwand:** mittel (1–2 Tage für das Harness, dann laufend klein).
**Nutzen:** hoch — behebt unsere größte strukturelle Lücke.

### Das Eval-Muster, das Microsoft parallel dazu verwendet

Aus der TechDays-Session zu Tests und Evals. Es passt genau auf unser Vorhaben und ist
**ohne BC-Produktfeature nachbaubar**:

| Baustein | Umsetzung |
|---|---|
| Ein Test, viele Fälle | Der Test bleibt normal; die Fallvariation liegt in einem **externen Data Set** `[V11 @17:51]` |
| Erwartungen extern | Auch die Assertions stehen im Data Set, nicht im Testcode `[V11 @18:19]` |
| Format | JSON oder YAML als Resource `[V11 @21:48]` |
| Fallzahl | ergibt sich aus der Zahl der Data-Set-Einträge (Demo: 8) `[V11 @22:45]` |
| Bewertung | Wiederholungsläufe und deren Vergleich `[V11 @23:24]`, plus Durchschnitte und Richtung `[V11 @20:04]` |
| Zweite Zielgröße | **Token-Verbrauch** als Kostenmetrik `[V11 @40:39]` |

Dazu die begriffliche Klarstellung, die vieles vereinfacht: Microsoft trennt Tests und Evals
nicht scharf — „even when we talk about tests and evals, they're kind of the same things"
`[V11 @00:16]`. Der Unterschied liegt in der Auswertung: ein Test ist Pass/Fail
`[V11 @01:26]`, ein Eval ist **direktional** `[V11 @02:00]` — er sagt, ob es besser oder
schlechter wurde.

**Einordnung:** Genau das brauchen wir. Unsere Review-Fixtures müssen keine harte
Pass/Fail-Schwelle haben, um nützlich zu sein — es reicht, wenn sie zeigen, ob eine
Prompt-Änderung die Trefferquote hebt oder senkt. Das senkt die Einstiegshürde deutlich:
20 Fallpaare in einer YAML-Datei plus drei Läufe genügen für ein direktionales Signal. Und
**Token-Verbrauch als zweite Zielgröße** mitzuführen kostet nichts und beantwortet die Frage,
die sonst später kommt.

⚠️ Microsoft nennt in dieser Session **keine** Schwellwerte, Coverage-Ziele, Accuracy-Grenzen
oder Score-Funktion — und auch kein LLM-as-Judge. Die Zielwerte müssen wir selbst setzen; der
Realitätsanker dafür sind die 57 % / 49 % ihres eigenen Review-Agenten
([Playbook 2](02-oekosystem.md)).

---

## Rang 3 — Reference-Integrity-Gate

**Problem:** Unsere Findings tragen eine Cop-Rule-ID, wo eine existiert, und sonst nichts.
Kein `helpUri` (obwohl `list_rules --verbose` ihn liefert), kein Zitat der Regelstelle, keine
stabile Finding-ID. Wer ein Finding bestreitet, bekommt keine Belegkette.

**Übernahme:** Die Prüfung aus [`skills/do.md`](../../skills/do.md) vor dem Emittieren:

1. Jeder zitierte Pfad existiert im Checkout **und** wurde in diesem Lauf geöffnet.
2. `findings[].id` entspricht exakt der primären Referenz.
3. Was das nicht erfüllt, wird **entfernt** — nicht in ein schwächeres Finding umgewandelt,
   nur um es zu retten.
4. Ist die Prüfung nicht möglich: `outcome: "failed"` statt unbelegter Ausgabe.

Für uns konkret: Cop-Findings bekommen den `helpUri` aus `list_rules --verbose`; Findings aus
`rules/*.md` bekommen den Dateipfad; alles ohne Beleg wird als `evidence: "agent"` markiert
und in der Severity gedeckelt.

**Aufwand:** klein. **Nutzen:** hoch — deckt sich direkt mit dem INNONAV-Grundsatz
„Fakt, Annahme, Spekulation trennen".

---

## Rang 4 — Agent-Findings deckeln

**Problem:** Bei uns kann ein reines LLM-Urteil ohne jeden Beleg als *Critical* erscheinen.

**Übernahme:** Die Deckelung aus [`skills/do.md`](../../skills/do.md):

- Findings ohne Beleg: `confidence` max. `medium`, `severity` max. `minor`
- Damit können sie **nie** ein Gate auslösen
- Präfix im `id` (`agent:`), damit sie in der Ausgabe unterscheidbar sind

Dazu die Präzisionsschranke wörtlich in unsere Reviewer-Prompts:

> "Steelman before emitting. State the strongest case that the code is correct as written…
> If that case is plausible, do not emit."

**Ausnahme für uns:** Ein Finding mit ALCops-Baseline-Treffer ist **kein** Agent-Finding —
es hat Compiler-Beleg und darf jede Severity tragen. Die Deckelung gilt nur für das, was
weder Cop noch Regeldatei stützt.

**Aufwand:** klein. **Nutzen:** hoch — trifft genau unsere größte Falsch-Positiv-Quelle.

---

## Rang 4b — Cross-Modell-Review statt Selbstwiderlegung

**Problem:** Unsere Skeptiker teilen sich Prompt *und* Modell mit den Agents, deren Findings
sie widerlegen sollen (im Workflow derselbe `agentType`). Dasselbe Modell soll sich selbst
widerlegen — das ist keine unabhängige Verifikation.

**Übernahme:** Aus der Praxis eines TechDays-Sprechers, der genau das anders macht:

> „I use Opus and then I have it call GPT-4.5 and Gemini 31 Pro preview for additional
> concurrency reviews on that" `[V9 @90:05]` `[unsicher: Versionsnummern im Auto-Untertitel verstümmelt]`

Mit einer beobachteten Rollenteilung:

> „GPT is good as like coding standards and nitpicking and things like that. But Gemini is
> more thing about what is AI specific." `[V9 @90:21]`

**Für uns konkret:** Der Skeptiker bekommt ein *anderes* Modell als der Reviewer, der das
Finding erzeugt hat. Das kostet fast nichts (der Skeptiker liest nur `file:line` plus die
Behauptung) und macht aus der Selbstbestätigung eine echte Gegenprüfung.

**Aufwand:** klein — eine Zeile Modellzuweisung in der Agent-Definition.
**Nutzen:** hoch, weil es die Verifikation überhaupt erst zu einer macht.

⚠️ Belastbarkeit: Das ist ein Erfahrungsbericht, keine Messung. Derselbe Sprecher berichtet
im selben Vortrag von einem **Fehler in der eigenen Messprozedur** — die Thinking-Tokens
fehlten in seinen Kostenzahlen `[V9 @90:33]`. Gute Erinnerung daran, die eigene Messung
selbst zu prüfen, bevor man ihr glaubt.

---

## Rang 5 — Negatives Wissen als erstklassige Regel

**Problem:** Unsere Falsch-Positiv-Abwehr steckt in vier hartcodierten Widerlegungstests im
Prompt. Ein fünfter Fall bedeutet: Prompt ändern, an bis zu zehn Stellen, ungetestet.

**Übernahme:** Das Prinzip aus [`README.md`](../../README.md) und [`skills/do.md`](../../skills/do.md):

> "A file that *prevents* a false positive […] is as valid as one that catches a defect."

Für uns: eine Regeldatei „Muster X ist **kein** Befund, weil BC Y tut" hat denselben Rang wie
eine Regeldatei „Muster Z ist ein Befund". Unsere PC0031-Carve-out (SetLoadFields auf
Write-Pfaden) ist genau so ein Fall — sie steht heute dreimal als Prompt-Prosa und sollte
**eine** Datei sein, die zitiert wird.

**Nebeneffekt:** Damit lösen sich die Duplikate. Statt derselben Regel an zehn Stellen gibt es
eine Datei plus Verweise. Das ist auch die Regel aus unseren eigenen Plugin-Wartungsvorgaben
(„Canonical + pointers, not copy-paste") — BCQuality zeigt nur, wie konsequent das aussieht.

**Aufwand:** mittel (Umbau der `rules/`-Struktur). **Nutzen:** hoch, langfristig.

---

## Rang 6 — Wissen als Daten statt Prompt-Prosa

**Problem:** Dieselbe Regel steht bei uns an bis zu zehn Stellen. Es gibt keinen Mechanismus,
der Widersprüche zwischen `CLAUDE.md`, `rules/*.md` und den Agent-Prompts erkennt —
`/validate-plugin` prüft Struktur, nicht Regelkonsistenz.

**Übernahme:** Frontmatter-Pflichtfelder plus generierter Index
([`tools/Build-KnowledgeIndex.ps1`](../../tools/Build-KnowledgeIndex.ps1)). Der Reviewer liest
den Index (155 KB) statt aller Dateien und öffnet nur die, die in die Worklist kommen.

**Der Befund, der diesen Rang aufwertet:** Microsoft hat genau unseren Ist-Zustand gemessen.
Alle Coding Guidelines in eine große Instruction zu packen machte das Ergebnis **5 % schlechter**
(„the more context is not always better"), das Kürzen auf präzise Instructions brachte
**10 % besser** — bei gleichem Modell und Tool
([Playbook 2](02-oekosystem.md)). Unsere `CLAUDE.md` hat 1.015 Zeilen und wird vollständig
geladen. Das ist strukturell dasselbe Muster.

**Die billige Teilmaßnahme vorweg:** Bevor irgendetwas umgebaut wird, lässt sich die
`CLAUDE.md` kürzen und Redundanz zu `rules/*.md` entfernen. Das ist nach dieser Messung ein
Kandidat für eine Verbesserung, nicht nur für Aufräumen — und es lässt sich mit den Fixtures
aus Rang 2 **nachweisen** statt behaupten.

**Aber ehrlich:** Der vollständige Umbau ist der größte in dieser Liste und greift tief in
unsere Struktur ein. **Nicht anfangen, bevor Rang 1–3 stehen** — ohne Fixtures merkt niemand,
wenn der Umbau etwas kaputt macht.

**Alternative mit besserem Verhältnis:** Wenn Phase 1/2 aus
[Playbook 4](04-vorgehen-start-validierung.md) positiv ausgeht, brauchen wir keinen eigenen
Korpus — dann docken wir BCQuality als Wissensschicht an und pflegen nur `/custom/`.

**Aufwand:** groß. **Nutzen:** hoch, aber erst nach Rang 1–3.

---

## Ausdrücklich NICHT übernehmen

| Was | Warum nicht |
|---|---|
| **BC-Fachwissen in Worklist-Cues** | BCQuality macht das trotz eigenem Verbot (siehe [Playbook 1, Abschnitt 8](01-bcquality-verstehen.md)). Genau der Drift-Fehler, den wir gerade abstellen wollen. Regeln gehören in Regeldateien. |
| **`enabled-layers` als Schutzmechanismus** | Ist es nicht — bei Plugin-Installation liegt alles auf der Platte. Wer wirklich denyen muss, muss den Baum beschneiden. |
| **„Index bei Zweifel neu bauen"** | Die Doku behauptet „well under a second", gemessen sind es 10–14 s. Einmal pro Session reicht. |
| **Unseren ALCops-Ground-Truth aufgeben** | BCQuality hat strukturell keinen Compiler-Beleg. Das ist unser stärkster Punkt und nicht verhandelbar. |
| **Den Prozessanschluss aufgeben** | Disposition-Loop, `.dev/`-Kette, ADO/GitHub-Write-Back mit Approval-Gate — BCQuality liefert JSON und hört auf. |

---

## Reihenfolge

```
Sofort, unabhängig von BCQuality:
  1. Findings-Report als JSON              (klein)
  2. pr-review: ALCops + Adversarial       (klein, Sicherheitslücke)
  3. Skeptiker vom Autor-Agent trennen     (klein)

Danach:
  4. Regressions-Fixtures, 20 Paare        (mittel)
  5. Reference-Integrity-Gate              (klein)
  6. Agent-Findings deckeln                (klein)

Erst wenn 1-6 stehen und Playbook 4 ein Ergebnis hat:
  7. Negatives Wissen als Regeldateien     (mittel)
  8. Wissen als Daten - ODER - BCQuality andocken  (groß / entfällt)
```

Punkte 2 und 3 stammen nicht aus BCQuality, sondern sind bei der Vergleichsanalyse
aufgefallen. Sie stehen trotzdem oben, weil sie echte Lücken schließen.
