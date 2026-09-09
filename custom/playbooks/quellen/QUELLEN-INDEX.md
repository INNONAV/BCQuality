# Quellen-Index

Belege für die Playbooks in diesem Ordner. **Stand: 2026-09-09.**

Roh-Transkripte der Videos bleiben lokal (interne Research-Evidenz, nicht im Repo). Da alle
Videos öffentlich sind, genügt für die Nachprüfung Video-ID + Timestamp: jede Aussage lässt
sich direkt am Original kontrollieren.

---

## Video-Quellen

Grundlage der Auswahl ist die **vollständige BC-TechDays-2026-Playlist** (34 Sessions,
`PLI1l3dMI8xlAehhviYLNeGV_pH9SCs_HO`) plus zwei Videos vom Microsoft-BC-Kanal. Aus den 34
Sessions wurden 10 als themenrelevant ausgewählt; 20 wurden aussortiert (Namespaces,
Concurrency, Reports, Cloud Migration, Index Management, Copilot Studio, Logic Apps,
Semantic Search, Admin-MCP, M365-Chat, Integrationen, Performance, Doku-Automatisierung,
OpenAPI→MCP, Expense Agent, Telemetrie-Agent, AL-Go-Skalierung, OpenClaw, Aftermovie,
Test Automation).

| Key | Titel | Länge | Fokus |
|---|---|---|---|
| **V1** ⭐ | Under the Hood ep. 15: BC-Bench: How we evaluate AI on AL tasks | 31:59 | BC-Bench-Mechanik, MCP-Wirkung |
| **V2** ⭐ | What's New: BC-Bench (2026 release wave 1) | 13:05 | BC-Bench-Zahlen, Partner-Nutzung |
| **V3** | AL Meets Agents: Stop Building Business Central the OG way | 1:39:06 | agentische AL-Praxis |
| **V4** | Where Do I Still Fit? What "BC Developer" Means in the Agentic Era | 1:30:23 | Rolle des Entwicklers, Review-Praxis |
| **V5** ⭐ | MS presents: The BCApps Journey Is Complete — Now Let's Build with Agents | 1:27:05 | **die BCQuality-dichteste Quelle** |
| **V6** ⭐ | BC TechDays 2026: Opening Keynote | 1:44:21 | Hill Climbing, Instructions-Messung |
| **V7** | MS presents: MCP Server for developers | 48:29 | **BC** MCP Server (nicht AL MCP) — für unsere Frage kaum relevant |
| **V8** ⭐ | MS presents: BC-Bench: Can coding agents solve real-world AL tasks? | 35:41 | dedizierte BC-Bench-Session |
| **V9** | Agentic Coding in AL, Done Right | 1:32:44 | Gegenstück zu V3 |
| **V10** ⭐ | MS presents: Use case: Hill climbing in accuracy and experimentation | 47:30 | **Messmethodik** |
| **V11** | MS presents: Tests, dependencies, runners and evals for BC applications | 43:05 | Evals für BC |
| **V12** | MS presents: Agentic development with AL developer tools and ALMCP deep dive | 45:01 | AL MCP im Detail |

URLs: `https://www.youtube.com/watch?v=<ID>` —
V1 `Hdp4KbbGpQA` · V2 `XGEDwzIZQj4` · V3 `lMn86w-2GAg` · V4 `dmpO08K4S3A` ·
V5 `hlgaOZB2ZIg` · V6 `uxClMdhpJak` · V7 `Hm2OIUUYLRA` · V8 `yIYUCSK0Bh4` ·
V9 `KQ_bEfuN9y8` · V10 `72Dajd4GRjE` · V11 `9CW5mydS9Vs` · V12 `mBU2Iu0urw8`

V5 und V12 brauchten drei Anläufe (HTTP 429); mit `--sleep 90` kamen sie durch. **Keine
Lücke mehr:** alle 12 ausgewählten Quellen liegen als Transkript vor.

---

## Volltext-Überblick über alle 12 Transkripte

Mechanische Zählung über die normalisierten Roh-Transkripte. Die Auto-Untertitel wiederholen
Zeilen zwei- bis dreifach, die absoluten Zahlen sind daher **überhöht** — aussagekräftig ist
das Muster, nicht der Betrag.

| Begriff | Summe | Verteilung |
|---|---:|---|
| „bc quality" | 102 | **V5: 79**, V4: 12, V9: 4, V3: 3, V6: 3, V12: 1 |
| „bc bench" / „bcbench" | 139 | V2: 48, V1: 41, V8: 21, V6: 13, V12: 7, V5: 6, V11: 3 |
| „hill climbing" | 48 | V10: 45, V6: 3 |
| „analyzer" | 9 | V3: 6, V12: 3 |
| „linter" | 9 | V5: 9 |
| **„alcops"** | **0** | — |
| **„codecop"** | **0** | — |
| **„appsourcecop"** | **0** | — |
| „knowledge base" | 1 | V3: 1 |
| „bcquality" (ohne Leerzeichen) | 0 | wird durchgängig „BC Quality" gesprochen |

**Zwei Befunde daraus:**

1. **V5 ist die BCQuality-dichteste Quelle** der gesamten Recherche — und war genau das Video,
   das dreimal am Rate-Limit scheiterte. Ohne die Playlist wäre es nicht gefunden worden.
2. **Klassische Analyzer kommen in keinem der zwölf Videos vor.** Kein ALCops, kein CodeCop,
   kein AppSourceCop; „analyzer" fällt neunmal in nur zwei Sessions. Qualität wird
   durchgängig über Tests, Skills, Instructions, Evals und Benchmarks diskutiert.
   **Einordnung:** Unser Compiler-Ground-Truth ist damit kein Rückstand gegenüber dem Markt,
   sondern ein Unterscheidungsmerkmal, das dort gerade niemand adressiert.

### Transkript-Herkunft

Alle ausgewerteten Transkripte stammen aus **YouTube-Auto-Untertiteln** in der Originalsprache
(auto-übersetzte Spuren wurden verworfen). Kein STT-Fallback, keine Audio-Uploads an Dritte.

Auto-Untertitel sind fehlerbehaftet. Erkennbare Artefakte in den ausgewerteten Zitaten:
„Sweep Bench" für *SWE-bench*, „PC bench" für *BC-Bench*. Eigennamen der Sprecher sind
unsicher und werden in den Playbooks deshalb nicht genannt.

---

## Verifikations-Pass

Alle wörtlichen Zitate, die in die Playbooks eingeflossen sind, wurden **mechanisch** gegen
die Roh-Transkripte geprüft (`verify_quotes.py` aus
`innonav-learn:learn-from-video-sources`).

| Lauf | Quellen | Findings | Ergebnis |
|---|---|---:|---|
| 1 | V1, V2 | 30 | **30 × `OK`, Score 1,00** |
| 2 | V3, V4 | 35 | **35 × `OK`, Score 1,00** |
| 3 | V6 (Keynote) | 18 | 17 × `OK`, 1 × `MISS` — siehe unten |
| 4 | V8 | 5 | **5 × `OK`** (die in die Playbooks übernommenen) |
| 5 | V11, V7 | 51 | **51 × `OK`, Score 1,00** |
| 6 | V9, V10 | 35 | **35 × `OK`** (zzgl. 244 Inline-Zitate durch den Agent) |

`OK` mit Score 1,00 heißt: exakter Substring-Treffer nach identischer Normalisierung beider
Seiten — kein Fuzzy-Match.

**Zur Zitatlänge — eine Lehre aus Lauf 3.** Erste Fassung der Keynote-Zitate: 8 von 10 nur
`FUZZY`. Ursache war kein Halluzinationsproblem, sondern die Untertitelstruktur: Die
Keynote-Captions wiederholen jede Zeile zwei- bis dreimal, ein über Cue-Grenzen hinweg
zusammengesetztes Zitat steht so nirgends im Roh-Transkript. Nach dem Kürzen auf
**cue-interne Fragmente von 5–12 Wörtern** waren 17 von 18 exakte Treffer. In den Playbooks
stehen ausschließlich die verifizierten Kurzfragmente.

Die auswertenden Agents geben zusätzlich an, ihre vollständigen Inline-Zitatlisten geprüft zu
haben (230, 481, 164, 51 bzw. 244 Zitate, je 0 Fehler). Diese Zahlen sind **nicht unabhängig
gegengeprüft** — belastbar sind die Läufe in der Tabelle.

### Werkzeug-Befund (wichtig für künftige Läufe)

Der Canary — ein absichtlich erfundenes Zitat, das `MISS` ergeben muss — wurde als
**DURCHGERUTSCHT** gemeldet. Nachgeprüft: Er erhält tatsächlich das Verdict **`FUZZY`** mit
Score exakt **0,820**, also genau auf dem Schwellwert (`--ratio` Default 0,82).

Bewertung: Das ist ein **Fehlalarm der Canary-Auswertung**, kein zu laxer Matcher.

- `FUZZY` heißt „nur ähnlich, auf Paraphrase herabstufen" — das ist gerade **keine**
  Bestätigung eines erfundenen Zitats. Die Prüfung `canary_ok = verdict == "MISS"` ist zu eng
  formuliert; korrekt wäre `verdict not in ("OK", "ARTIFACT")`.
- Der eigentliche Auslöser: `best_ratio` erreicht bei einem langen deutschen Satz gegen ein
  sehr großes englisches Transkript zufällig 0,82. Der FUZZY-Schwellwert ist für große
  Haystacks zu niedrig.
- **Die 30 OK-Treffer sind davon nicht betroffen.** Sie sind harte Substring-Matches und
  völlig unabhängig vom Fuzzy-Schwellwert.

Zwei kleinere Beobachtungen am selben Skript: `build_legend` nahm Keys sowohl aus
`quellen.json` als auch aus Dateinamen und erzeugte dadurch Dubletten (`V1` und `HDP4KBBGPQA`
zeigten auf dieselbe Datei — je nach Sortierung lief der Canary gegen eine andere Quelle);
ein in `quellen.json` eingetragenes, aber fehlendes Transkript verschwand stumm.

**Status: behoben** (2026-09-09) in `innonav-learn:learn-from-video-sources`.
Die Canary-Prüfung lautet jetzt `verdict not in ("OK", "ARTIFACT")`, der Bericht unterscheidet
„bestanden", „bestanden, aber nur knapp (FUZZY)" und „DURCHGERUTSCHT"; Dubletten werden
unterdrückt, fehlende Transkripte gemeldet. Drei Gegentests bestanden — insbesondere: ein
*echt* bestätigtes Zitat als Canary löst weiterhin korrekt Alarm aus, der Schutz ist also
intakt. `SKILL.md` wurde mitgezogen.

Unabhängige Bestätigung: Ein auswertender Agent prüfte den Canary in Lauf 5 zusätzlich direkt
gegen sein eigenes Transkript (V11) und erhielt dort korrekt `MISS` mit Score 0,79 — der
Matcher arbeitete also die ganze Zeit richtig, nur die Auswertung war zu streng.

---

## Repo-Quellen

| Repo | Rolle | Belegte Aussagen |
|---|---|---|
| [microsoft/BCQuality](https://github.com/microsoft/BCQuality) | Wissen + Skills | Schema, Skills, Index, Fixtures — Dateipfade direkt in den Playbooks |
| [microsoft/BC-ALAgents](https://github.com/microsoft/BC-ALAgents) | Review-Engine | Trennung Engine/Wissen, Ref-Pin, Sicherheitsmodell |
| [microsoft/BC-Bench](https://github.com/microsoft/BC-Bench) | Benchmark | `EXPERIMENT.md`, `config.yaml`-Schalter, Kategorien |
| [Issue #83 — Roadmap-Epic](https://github.com/microsoft/BCQuality/issues/83) | Reifegrad | geplante Domänen und Authoring-Skills |

⚠️ Der GitHub-MCP-Zugriff auf `microsoft/*` schlug fehl: das Microsoft-Open-Source-Enterprise
verbietet fine-grained PATs mit einer Lebensdauer über 8 Tagen. Issue #83 wurde deshalb über
den öffentlichen Web-Abruf gelesen. **Kein Secret betroffen** — nur ein Konfigurationshinweis
für den, der den Token pflegt.

---

## Microsoft Learn

| Quelle | Belegt |
|---|---|
| [Evaluate AL coding agents with BC-Bench](https://learn.microsoft.com/en-us/dynamics365/release-plan/2026wave1/smb/dynamics365-business-central/evaluate-al-coding-agents-bc-bench) | **GA seit 1. April 2026**, Business Value, Feature Details |
| [Development in AL](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-dev-overview) | BC-Bench ist aus der offiziellen AL-Doku verlinkt |

**Negativbefund:** Eine Suche über Microsoft Learn nach BCQuality liefert **keine** eigene
Doku-Seite. BCQuality existiert nur als GitHub-Repo und in Community-Blogs — im Gegensatz zu
BC-Bench. Siehe [Playbook 1, Abschnitt 8](../01-bcquality-verstehen.md).

---

## Wissenschaftliche Quelle

**arXiv:2608.20851** — Haoran Sun, Klaus Marius Hansen:
*BC-Bench: Evaluating Agentic Engineering in a Domain-Specific Language for ERP*, CC-BY 4.0.

Alle Zahlen in [Playbook 2, Abschnitt 4](../02-oekosystem.md) stammen aus diesem Paper.
`[verifiziert: zwei unabhängige Volltextabrufe, Ergebnisse konsistent]` — insbesondere die
Tabellen 3, 5, 6 und der Abschnitt *Limitations* (5.2).

---

## Community- und MVP-Quellen

| Quelle | Autor / Seite | Belegt |
|---|---|---|
| [How does BCQuality currently work when we use it as a plugin?](https://techspheredynamics.com/2026/08/03/how-does-bcquality-currently-work-when-we-use-it-as-a-plugin/) | Tech Sphere Dynamics | Plugin-Ablauf, ~250 geladene Dokumente, offene Update-Frage |
| [BCQuality: An agentic vision for AL development](https://techspheredynamics.com/2026/05/03/bcquality-an-agentic-vision-for-al-development/) | Javier Armesto | Aufnahmeregel, Architektur, Skill-Output, kritische Einordnung |
| [Get the new BCQuality plugin for VS Code!](https://nataliekarolak.wordpress.com/2026/08/19/get-the-new-bcquality-plugin-for-vs-code/) | The BC Docs Librarian | VS-Code-Installation, Ablageort, Update-Zyklus ~24 h |
| [How to implement Microsoft BCQuality in your GitHub Pull Request](https://thatnavguy.com/blog/2026/implement-bcquality-agentic-workflow-business-central) | That NAV Guy | PR-Workflow über `gh aw compile` |
| [ALDC — BCQuality-Integration](https://github.com/javiarmesto/ALDC-AL-Development-Collection/blob/main/docs/bcquality.md) | Javier Armesto | Sibling-Clone-Modell, `enabled: auto\|true\|false`, `validate_evidence.py` |

**Einordnung:** Die Community-Quellen beschreiben durchweg *Architektur und Installation*.
**Keine** von ihnen liefert Messwerte zu Genauigkeit, Trefferquote oder Kontextkosten. Die
Fragestellung „bringt es etwas?" ist in der öffentlichen Diskussion bislang unbeantwortet.

---

## Eigene Messungen

Alle auf Fork-Stand `8584217`, Windows 11, PowerShell 7.6.5, am 2026-09-09:

| Messung | Ergebnis |
|---|---|
| `Build-KnowledgeIndex.ps1` | 300 Artikel, 155 KB, 14,4 s kalt / 10,3 s warm |
| `Test-ReviewFixtures.ps1 -Root .` | PASSED, 34 Cases über 17 Domänen, 2,0 s |
| `Test-ReviewFixtures.ps1 -PrepareDirectory` | 34 neutralisierte Cases, 8,0 s |
| Größe eines Request-Case | ø 17,8 KB (~4–5k Token); 34 Cases ≈ 150k Token |
| Knowledge-Korpus | 300 `.md`, 247 `.good.al`, 238 `.bad.al` |

---

## Was bewusst nicht übernommen wurde

- **Zahlen aus V1 zur Resolution Rate.** Die dort genannten „40 %" und „50–60 %" sind ein
  hypothetisches Rechenbeispiel des Moderators, keine Messwerte. In den Playbooks stehen
  ausschließlich die Paper-Zahlen.
- **Sprechernamen.** Die Auto-Untertitel geben sie widersprüchlich wieder; eine falsche
  Zuschreibung wäre schlimmer als keine.
- **Der „pass at five"-Spitzenwert aus V2.** Im Transkript als „949.5%" verstümmelt;
  plausibel 49,5 %, aber nicht belegbar. Die Playbooks nutzen den Paper-Wert.
- **Aussagen über einen Claude-Code-Pfad in BC-ALAgents.** Die Doku nennt nur GitHub Actions
  und Copilot CLI; alles andere wäre Spekulation.
