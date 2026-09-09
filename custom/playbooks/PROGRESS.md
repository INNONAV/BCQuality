# Arbeitsstand — BCQuality-Evaluierung

**Letzte Aktualisierung:** 2026-09-09
**Zweck:** Wiedereinstieg ohne die ganze Vorgeschichte lesen zu müssen.
**Vollständige Analyse:** [README.md](README.md) → Playbooks 1–6.

---

## In einem Satz

Gate 0 ist vollständig bestanden, die drei Sofortmaßnahmen am eigenen Plugin sind umgesetzt
und gepusht — **als Nächstes steht Phase 1 an: der A/B/C-Vergleich auf echtem Kundencode.**
Dafür fehlt nur noch die Auswahl des Repos.

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

### Sofortmaßnahmen am INNONAV-Plugin (Repo `ClaudeCodePlugin`)
Drei Lücken, die nichts mit BCQuality zu tun hatten, aber beim Vergleich auffielen:

1. **`pr-review` hatte weder ALCops-Baseline noch Adversarial Verification** — ausgerechnet
   der Pfad, der öffentlich in fremde PRs schreibt. Beides ergänzt (Step 3b und 5a).
2. **Skeptiker teilte sich Modell mit dem Reviewer** — läuft jetzt auf `opus` statt `sonnet`.
3. **Kein maschinenlesbarer Report** — neu `.dev/03-code-review.json` und
   `.dev/pr-review-<id>.json`, mit den Feldern `evidence` und `confidence`.

Commit `6e29447` auf `master` (gepusht), Doku-Nachtrag in **[PR #13](https://github.com/INNONAV/ClaudeCodePlugin/pull/13)** (offen).

---

## Als Nächstes: Phase 1

**Ziel:** Findet BCQuality auf unserem Code etwas, das unser Review nicht findet?
**Aufwand:** ~1 Tag. Vollständige Anleitung in
[04-vorgehen-start-validierung.md](04-vorgehen-start-validierung.md).

### Blocker — eine Entscheidung fehlt

**Welches Kundenrepo?** Auswahlkriterium ist hart:

- ✅ Schwerpunkt **Performance** (65 Regeln), **UI** (32) oder **Style** (35)
- ❌ **nicht** Query (2 Regeln), AppSource (4) oder Testing (6) — dort misst man die
  Korpuslücke statt die Methode

### Ablauf, wenn das Repo feststeht

Drei Läufe über **denselben Diff**:

| Lauf | Was | Ablage |
|---|---|---|
| A | unser `/review` wie bisher | `.dev/vergleich/A-innonav.md` |
| B | `bcquality:al-code-review` allein | `.dev/vergleich/B-bcquality.json` |
| C | beides kombiniert | `.dev/vergleich/C-kombiniert.md` |

⚠️ **BCQuality immer mit dem vollqualifizierten Namen `bcquality:al-code-review` aufrufen.**
Die Beschreibungen von `al-code-review`, `/review` und `/analyze` überlappen — implizit
getriggert wäre nicht zuzuordnen, welcher Stack das Ergebnis erzeugt hat, und der Vergleich
wäre wertlos.

Dann jedes Finding aus B einsortieren: *neu und richtig* · *doppelt* · *falsch positiv* ·
*übersehen*. Und die Zitat-Existenz mechanisch prüfen (PowerShell-Schnipsel steht im Playbook).

**Gleich mitprüfen:** Bekommt ein Agent über den **AL-MCP-Server** unsere INNOCop-Diagnostics?
Der MCP-Server ist der einzige Zusatz mit gemessen signifikanter Wirkung (+5 Pp resolution
rate) und lässt Analyzer über die LSP-Verbindung mitlaufen. Falls das klappt, ist es der
billigste echte Qualitätsgewinn — unabhängig davon, wie BCQuality abschneidet.

### Gate 1
**≥ 3 belegte Befunde** der Kategorie *neu und richtig*, und *falsch positiv* nicht häufiger
als *neu und richtig*.
- Erreicht → Phase 2 (Golden Set) und Phase 3 (Pilot)
- Verfehlt → BCQuality liegen lassen, nur die Mechanik übernehmen
  ([05-uebernahmekandidaten.md](05-uebernahmekandidaten.md))

---

## Danach

**Phase 2 — Messen** (2–3 Tage): eigenes Golden Set mit 20–30 Fallpaaren, Hill-Climbing nach
Microsofts Methode (eine Variable pro Lauf), Recall ≥ 0,8 und Clean Rate ≥ 0,9 als Einstiegsziel.
Realitätsanker: Microsofts eigener Review-Agent liegt bei 57 % / 49 %.

**Phase 3 — Pilot** (4 Wochen): ein Team, advisory, kein Merge-Gate. Gate: Akzeptanzquote
> 60 % und Zitat-Trefferquote 100 %.

**Unabhängig davon** — Playbook 5, Rang 2: Regressions-Fixtures für unser eigenes Plugin,
20 Fallpaare. Das ist die größte verbleibende strukturelle Lücke und kann parallel laufen.

---

## Offene Punkte

| Was | Wer | Anmerkung |
|---|---|---|
| Kundenrepo für Phase 1 auswählen | Daniel | **der eigentliche Blocker** |
| [PR #13](https://github.com/INNONAV/ClaudeCodePlugin/pull/13) reviewen und mergen | Maintainer | Doku-Nachtrag, 2 Dateien |
| Versionsbump `innonav-al-development` | Maintainer | `[Unreleased]` schneiden via `/plugin-version` |
| GitHub-PAT auf ≤ 8 Tage Laufzeit | Daniel | sonst bleibt `microsoft/*` über MCP gesperrt |
| Default-Python 3.14 reparieren | Daniel | defekt (`No module named 'encodings'`), 3.11 läuft |
| Dedizierter Skeptiker-Agent | offen | teilt sich noch den Domänen-Prompt mit dem Reviewer |

---

## Was man beim Wiedereinstieg wissen sollte

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

---

## Fork-Pflege

```powershell
git fetch upstream && git merge upstream/main
pwsh ./custom/playbooks/scripts/Check-Phase0.ps1   # nach jedem Sync
```

Der `/custom/`-Layer kann nicht kollidieren — Upstream befüllt ihn nie. Breaking Changes sind
angekündigt; der Fixture-Lauf ist der billigste Weg, sie zu bemerken.
