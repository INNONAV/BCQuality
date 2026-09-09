# INNONAV-Playbooks zu BCQuality

Interne Wissensbasis zur Frage: **Taugt `microsoft/BCQuality` als Plugin für uns, und was übernehmen wir daraus?**

Diese Playbooks liegen bewusst unter `custom/`, weil das der einzige Ordner ist, den Upstream
(`microsoft/BCQuality`) nie befüllt — ein `git pull` von Upstream kann hier keine Konflikte
erzeugen. Der Upstream-Workflow `flag-new-top-level.yml` würde einen neuen Ordner im Repo-Root
außerdem markieren; `custom/` umgeht das.

## Reihenfolge

| # | Playbook | Für wen |
|---|---|---|
| 1 | [BCQuality verstehen](01-bcquality-verstehen.md) | alle, die mit dem Repo arbeiten |
| 2 | [Das Microsoft-Ökosystem: BCQuality, BC-ALAgents, BC-Bench](02-oekosystem.md) | Entscheider, Architekten |
| 3 | [Vergleich mit unserem Plugin](03-vergleich-innonav.md) | Entscheider |
| 4 | [Vorgehen: starten und validieren](04-vorgehen-start-validierung.md) | **Startpunkt für die Umsetzung** |
| 5 | [Übernahmekandidaten für unser Plugin](05-uebernahmekandidaten.md) | Plugin-Maintainer |
| 6 | [Praxis aus der Community](06-praxis-community.md) | alle, die agentisch entwickeln |
| — | [Quellen-Index](quellen/QUELLEN-INDEX.md) | Nachprüfbarkeit |

## Sofort loslegen

```powershell
pwsh ./custom/playbooks/scripts/Check-Phase0.ps1
```

Prüft in einem Durchlauf, ob dein Klon einsatzbereit ist — Voraussetzungen, Upstream-Abstand,
Knowledge-Index, Review-Fixtures — und endet mit `GATE 0 BESTANDEN` oder einer Liste dessen,
was fehlt. Ändert nichts am Repo. Ohne Netz: `-SkipFetch`.

## Das Ergebnis

BCQuality ist **kein Ersatz** für unser Plugin — es ist kleiner, hat keinen Compiler-Beleg und
keinen Prozessanschluss. Es hat aber drei Mechaniken, die uns fehlen und wehtun:
**Beleg-Zwang für jedes Finding**, **Regressionstests der Review-Qualität** und
**Wissen als Daten statt als Prompt-Prosa**.

Ob es inhaltlich etwas bringt, ist **offen**. Über zwölf Videos, ein Paper und fünf
MVP-Quellen hinweg findet sich **keine einzige Messung und kein Erfahrungsbericht** zu
BCQuality — es wird verwiesen, erwogen und angekündigt, nicht gezeigt. Deshalb messen wir
selbst, bevor wir einführen → [Playbook 4](04-vorgehen-start-validierung.md).

Drei Befunde prägen die Empfehlung:

- **Microsoft stellt den Compiler über die Wissensbasis.** *„compile errors are preferable"*,
  einfache Regeln gehören in einen Custom-Linter, *„because a compile is much cheaper than an
  agentic decision."* Unser ALCops-Ground-Truth ist damit kein Rückstand, sondern ein
  Alleinstellungsmerkmal — in keinem der zwölf Videos kommt ein Analyzer überhaupt vor.
- **Zu viel Kontext schadet messbar.** Microsofts Sammel-Instruction kostete 5 %, das Kürzen
  brachte 10 %. Das ist zugleich das Argument für BCQualitys atomare Struktur *und* gegen jede
  Anbindung, die den Korpus einfach in den Kontext kippt.
- **Der lohnendste Integrationspunkt ist nicht BCQuality selbst**, sondern der AL-MCP-Server:
  gemessen signifikant (+5 Pp resolution rate, +10 Pp pass@5), weil der Agent kompilieren und
  Symbole suchen kann — und er lässt eigene Cops über die LSP-Verbindung mitlaufen.

## Grounding-Hinweis

Diese Playbooks enthalten **nur Belegtes**. Jede Aussage ist entweder

- durch eine Datei in diesem Repo belegt (Pfadangabe),
- durch eine externe Quelle belegt (Link im [Quellen-Index](quellen/QUELLEN-INDEX.md)),
- selbst gemessen (als `[gemessen: Datum]` markiert), oder
- als **Einordnung:** gekennzeichnet — das ist INNONAV-Interpretation, keine Quelle.

Unsicheres ist mit `[unsicher]` markiert. Lücken sind benannt, nicht überdeckt.

**Stand:** 2026-09-09 · **Fork-Basis:** `8584217` (upstream `microsoft/BCQuality`)
