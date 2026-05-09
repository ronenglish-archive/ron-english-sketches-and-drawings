[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$RepoRoot = 'D:\github\ron-english-sketches-and-drawings'
$BrainsRoot = Join-Path $RepoRoot 'Sketches\brains'
$BuildScriptPath = Join-Path $RepoRoot 'build-brains-category.ps1'

function Backup-FileIfExists {
    param([Parameter(Mandatory=$true)][string]$Path)

    if (Test-Path -LiteralPath $Path) {
        $folder = Split-Path -Parent $Path
        $backupDir = Join-Path $folder '_backups'

        if (-not (Test-Path -LiteralPath $backupDir)) {
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        }

        $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        $name = [System.IO.Path]::GetFileNameWithoutExtension($Path)
        $ext = [System.IO.Path]::GetExtension($Path)
        $backupPath = Join-Path $backupDir "$name-before-brains-path-fix-$timestamp$ext"

        Copy-Item -LiteralPath $Path -Destination $backupPath -Force
        Write-Host "Backup created: $backupPath"
    }
}

function Fix-BrainsIndex {
    $indexPath = Join-Path $BrainsRoot 'index.html'

    if (-not (Test-Path -LiteralPath $indexPath)) {
        Write-Warning "Brains index not found: $indexPath"
        return
    }

    Backup-FileIfExists -Path $indexPath

    $html = [System.IO.File]::ReadAllText($indexPath)
    $original = $html

    # From Sketches/brains/index.html to repo root:
    # CSS needs ../../css/styles.css
    # Images need ../../images/Sketches/brains/...
    $html = $html.Replace('href="../css/styles.css"', 'href="../../css/styles.css"')
    $html = $html.Replace('src="../images/Sketches/brains/', 'src="../../images/Sketches/brains/')
    $html = $html.Replace('href="../images/Sketches/brains/', 'href="../../images/Sketches/brains/')

    if ($html -ne $original) {
        [System.IO.File]::WriteAllText($indexPath, $html, [System.Text.UTF8Encoding]::new($false))
        Write-Host "Fixed paths in Brains index: $indexPath"
    }
    else {
        Write-Host "Brains index paths already looked correct: $indexPath"
    }
}

function Fix-IndividualBrainsPage {
    param([Parameter(Mandatory=$true)][string]$PagePath)

    Backup-FileIfExists -Path $PagePath

    $html = [System.IO.File]::ReadAllText($PagePath)
    $original = $html

    # From Sketches/brains/[page]/index.html to repo root:
    # CSS needs ../../../css/styles.css
    # Images need ../../../images/Sketches/brains/...
    $html = $html.Replace('href="../../css/styles.css"', 'href="../../../css/styles.css"')
    $html = $html.Replace('src="../../images/Sketches/brains/', 'src="../../../images/Sketches/brains/')
    $html = $html.Replace('href="../../images/Sketches/brains/', 'href="../../../images/Sketches/brains/')

    # Fix nav/back links on individual pages.
    $html = $html.Replace('href="../index.html">Sketches</a>', 'href="../../index.html">Sketches</a>')
    $html = $html.Replace('href="index.html">Brains</a>', 'href="../index.html">Brains</a>')
    $html = $html.Replace('href="index.html">&larr; Back to Brains</a>', 'href="../index.html">&larr; Back to Brains</a>')

    if ($html -ne $original) {
        [System.IO.File]::WriteAllText($PagePath, $html, [System.Text.UTF8Encoding]::new($false))
        Write-Host "Fixed paths in individual page: $PagePath"
    }
    else {
        Write-Host "Individual page paths already looked correct: $PagePath"
    }
}

function Fix-BuildScriptForFutureRuns {
    if (-not (Test-Path -LiteralPath $BuildScriptPath)) {
        Write-Host "Build script not found, skipping future-run patch: $BuildScriptPath"
        return
    }

    Backup-FileIfExists -Path $BuildScriptPath

    $text = [System.IO.File]::ReadAllText($BuildScriptPath)
    $original = $text

    # These fixes patch the generator so the same broken paths do not return if you rerun it.
    $text = $text.Replace("-ImagePrefix '../../images/Sketches/brains'", "-ImagePrefix '../../../images/Sketches/brains'")
    $text = $text.Replace("New-WebImagePath -Prefix '../images/Sketches/brains'", "New-WebImagePath -Prefix '../../images/Sketches/brains'")

    $text = $text.Replace('<link rel="stylesheet" href="../../css/styles.css" />', '<link rel="stylesheet" href="../../../css/styles.css" />')
    $text = $text.Replace('<link rel="stylesheet" href="../css/styles.css" />', '<link rel="stylesheet" href="../../css/styles.css" />')

    $text = $text.Replace('<a class="nav-pill" href="../index.html">Sketches</a>', '<a class="nav-pill" href="../../index.html">Sketches</a>')
    $text = $text.Replace('<a class="nav-pill" href="index.html">Brains</a>', '<a class="nav-pill" href="../index.html">Brains</a>')
    $text = $text.Replace('<a href="index.html">&larr; Back to Brains</a>', '<a href="../index.html">&larr; Back to Brains</a>')

    if ($text -ne $original) {
        [System.IO.File]::WriteAllText($BuildScriptPath, $text, [System.Text.UTF8Encoding]::new($false))
        Write-Host "Patched build script for future Brains rebuilds: $BuildScriptPath"
    }
    else {
        Write-Host "Build script already looked patched: $BuildScriptPath"
    }
}

if (-not (Test-Path -LiteralPath $BrainsRoot)) {
    throw "Brains HTML folder not found: $BrainsRoot"
}

Fix-BrainsIndex

$individualPages = @(Get-ChildItem -LiteralPath $BrainsRoot -Recurse -File -Filter 'index.html' | Where-Object {
    $_.FullName -ne (Join-Path $BrainsRoot 'index.html') -and
    $_.FullName -notmatch '\\_backups\\'
})

foreach ($page in $individualPages) {
    Fix-IndividualBrainsPage -PagePath $page.FullName
}

Fix-BuildScriptForFutureRuns

Write-Host ""
Write-Host "Done. The Brains image paths have been corrected."
Write-Host "Refresh:"
Write-Host "  D:\github\ron-english-sketches-and-drawings\Sketches\brains\index.html"
Write-Host ""
Write-Host "Then click a few individual pages to confirm the images load."
