<#
.SYNOPSIS
    Phase-0-Bereitschaftscheck fuer die BCQuality-Evaluierung (INNONAV).

.DESCRIPTION
    Prueft in einem Durchlauf, ob dieser Klon einsatzbereit ist:
      1. Voraussetzungen (PowerShell 7+, git)
      2. Abstand zu microsoft/BCQuality  (nur lesend, kein Merge)
      3. Knowledge-Index laesst sich bauen
      4. Review-Fixtures laufen durch

    Aendert nichts am Repo ausser der ohnehin ignorierten knowledge-index.json.
    Legt den upstream-Remote an, falls er fehlt.

    Hintergrund und Interpretation: custom/playbooks/04-vorgehen-start-validierung.md

.PARAMETER SkipFetch
    Ueberspringt den Upstream-Abgleich (fuer Laeufe ohne Netz).

.EXAMPLE
    pwsh ./custom/playbooks/scripts/Check-Phase0.ps1

.OUTPUTS
    Exit 0 = Gate 0 bestanden. Exit 1 = mindestens eine Pruefung fehlgeschlagen.
#>
[CmdletBinding()]
param(
    [switch] $SkipFetch
)

$ErrorActionPreference = 'Stop'

# Repo-Wurzel aus dem Skriptpfad ableiten, damit der Aufruf aus jedem
# Arbeitsverzeichnis funktioniert.
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..' '..' '..')).Path

$script:Failures = @()

function Write-Head([string] $Text) {
    Write-Host ''
    Write-Host "--- $Text " -NoNewline
    Write-Host ('-' * [Math]::Max(0, 58 - $Text.Length))
}

function Write-Result([string] $Label, [bool] $Ok, [string] $Detail) {
    $mark = if ($Ok) { '[ OK ]' } else { '[FAIL]' }
    $color = if ($Ok) { 'Green' } else { 'Red' }
    Write-Host $mark -ForegroundColor $color -NoNewline
    Write-Host (' {0,-34} {1}' -f $Label, $Detail)
    if (-not $Ok) { $script:Failures += $Label }
}

Write-Host ''
Write-Host '======== BCQuality Phase 0 — Bereitschaftscheck ========'
Write-Host "Repo: $RepoRoot"

# --- 1. Voraussetzungen ------------------------------------------------------
Write-Head '1. Voraussetzungen'

$psOk = $PSVersionTable.PSVersion.Major -ge 7
Write-Result 'PowerShell 7+' $psOk $PSVersionTable.PSVersion

$git = Get-Command git -ErrorAction SilentlyContinue
Write-Result 'git' ([bool]$git) $(if ($git) { (git --version) } else { 'nicht gefunden' })

# --- 2. Upstream-Abstand -----------------------------------------------------
Write-Head '2. Abstand zu microsoft/BCQuality'

if ($SkipFetch) {
    Write-Host '       uebersprungen (-SkipFetch)'
} elseif (-not $git) {
    Write-Host '       uebersprungen (kein git)'
} else {
    Push-Location $RepoRoot
    try {
        $hasUpstream = (git remote) -contains 'upstream'
        if (-not $hasUpstream) {
            git remote add upstream 'https://github.com/microsoft/BCQuality.git' | Out-Null
            Write-Host '       upstream-Remote angelegt'
        }

        git fetch upstream --quiet 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            # Kein Netz ist kein Grund, den ganzen Check zu versenken.
            Write-Result 'Upstream erreichbar' $false 'fetch fehlgeschlagen (Netz? VPN?)'
        } else {
            $behind = [int](git rev-list --count 'HEAD..upstream/main')
            $ahead = [int](git rev-list --count 'upstream/main..HEAD')
            $detail = "$behind hinterher, $ahead eigene Commits"
            if ($behind -eq 0) {
                Write-Result 'Fork aktuell' $true $detail
            } else {
                # Bewusst KEIN Fehler: hinterherhinken ist normal, nur sichtbar machen.
                Write-Host '[HINW]' -ForegroundColor Yellow -NoNewline
                Write-Host (' {0,-34} {1}' -f 'Fork hinter Upstream', $detail)
                Write-Host '       -> git merge upstream/main  (danach diesen Check erneut laufen lassen)'
            }
        }
    } finally {
        Pop-Location
    }
}

# --- 3. Knowledge-Index ------------------------------------------------------
Write-Head '3. Knowledge-Index'

$indexScript = Join-Path $RepoRoot 'tools/Build-KnowledgeIndex.ps1'
$sw = [Diagnostics.Stopwatch]::StartNew()
try {
    $out = & pwsh -NoProfile -File $indexScript 2>&1
    $sw.Stop()
    $count = ($out | Select-String -Pattern '(\d+) article' | Select-Object -First 1).Matches.Groups[1].Value
    $ok = $LASTEXITCODE -eq 0 -and [int]$count -gt 0
    Write-Result 'Index gebaut' $ok "$count Artikel in $([Math]::Round($sw.Elapsed.TotalSeconds,1))s"
} catch {
    $sw.Stop()
    Write-Result 'Index gebaut' $false $_.Exception.Message
}

# --- 4. Review-Fixtures ------------------------------------------------------
Write-Head '4. Review-Fixtures'

$fixtureScript = Join-Path $RepoRoot 'tools/Test-ReviewFixtures.ps1'
$sw = [Diagnostics.Stopwatch]::StartNew()
try {
    $out = & pwsh -NoProfile -File $fixtureScript -Root $RepoRoot 2>&1
    $sw.Stop()
    $ok = $LASTEXITCODE -eq 0
    $line = ($out | Select-String -Pattern 'PASSED|FAILED' | Select-Object -First 1)
    $detail = if ($line) { "$line ($([Math]::Round($sw.Elapsed.TotalSeconds,1))s)" } else { 'keine PASSED/FAILED-Zeile' }
    Write-Result 'Fixtures' $ok $detail
} catch {
    $sw.Stop()
    Write-Result 'Fixtures' $false $_.Exception.Message
}

# --- Fazit -------------------------------------------------------------------
Write-Host ''
Write-Host ('=' * 64)
if ($script:Failures.Count -eq 0) {
    Write-Host 'GATE 0 BESTANDEN' -ForegroundColor Green
    Write-Host 'Weiter mit Phase 1 — custom/playbooks/04-vorgehen-start-validierung.md'
    exit 0
} else {
    Write-Host 'GATE 0 NICHT BESTANDEN' -ForegroundColor Red
    Write-Host ('Fehlgeschlagen: ' + ($script:Failures -join ', '))
    Write-Host 'Ohne Index arbeiten die Skills im teuren Fallback-Modus — erst reparieren.'
    exit 1
}
