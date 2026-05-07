# fix-all-sketches-centering-format.ps1
# Ron English Sketches and Drawings Catalogue
#
# Applies the preferred centered formatting to ALL existing HTML pages under:
# D:\github\ron-english-sketches-and-drawings\Sketches
#
# Centers:
# - Top pill links
# - Page titles
# - Intro text
# - Section headings such as Original Drawing, Digitized Versions, Collector Cards
# - Card/work titles
# - Footer text
#
# Keeps left-aligned:
# - Back to... links
#
# Safe behavior:
# - Backs up every edited HTML file.
# - Adds one clearly marked CSS override block.
# - Removes older Grins-only centering override blocks if present.
# - Can be rerun safely.
# - Does not touch images.
#
# Optional:
#   .\fix-all-sketches-centering-format.ps1 -ReportOnly
# shows which files would be updated without writing changes.

param(
  [switch]$ReportOnly
)

$ErrorActionPreference = 'Stop'

$RepoRoot = 'D:\github\ron-english-sketches-and-drawings'
$SketchesDir = Join-Path $RepoRoot 'Sketches'
$ReportDir = Join-Path $SketchesDir '_reports'

$OldBeginMarker = '/* BEGIN GRINS CENTERING OVERRIDES */'
$OldEndMarker = '/* END GRINS CENTERING OVERRIDES */'

$BeginMarker = '/* BEGIN SKETCHES CENTERING OVERRIDES */'
$EndMarker = '/* END SKETCHES CENTERING OVERRIDES */'

$OverrideCss = @"

    /* BEGIN SKETCHES CENTERING OVERRIDES */
    .nav-pills{
      justify-content:center;
      text-align:center;
    }

    .page-header{
      text-align:center;
      margin-left:auto;
      margin-right:auto;
    }

    .page-title,
    h1.page-title{
      text-align:center;
    }

    .intro-text{
      text-align:center;
      margin-left:auto;
      margin-right:auto;
    }

    .intro-text p{
      text-align:center;
      margin-left:auto;
      margin-right:auto;
    }

    .section-card h2,
    .section-card h3{
      text-align:center;
    }

    .section-intro{
      text-align:center;
      margin-left:auto;
      margin-right:auto;
    }

    .entry-body{
      align-items:center;
      justify-content:center;
      text-align:center;
    }

    .entry-body h3,
    .entry-body p,
    .work-title,
    .work-subtitle,
    .image-caption,
    .gallery-item .entry-body .work-title,
    .gallery-item .entry-body .work-subtitle,
    .gallery-item .entry-body .work-note{
      text-align:center;
      width:100%;
    }

    footer{
      text-align:center;
    }

    .back-link{
      text-align:left;
    }

    .back-link a{
      text-align:left;
    }
    /* END SKETCHES CENTERING OVERRIDES */
"@

function Ensure-Folder {
  param([string]$Path)
  if (!(Test-Path $Path)) {
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
  }
}

function Backup-IfExists {
  param([string]$Path)

  if (Test-Path $Path) {
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $backupPath = "$Path.bak-centering-$stamp"
    Copy-Item -Path $Path -Destination $backupPath -Force
    return $backupPath
  }

  return ''
}

if (!(Test-Path $SketchesDir)) {
  Write-Host ''
  Write-Host 'ERROR: Sketches folder not found:' -ForegroundColor Red
  Write-Host $SketchesDir -ForegroundColor Yellow
  Write-Host ''
  exit 1
}

Ensure-Folder $ReportDir

$htmlFiles = Get-ChildItem -Path $SketchesDir -Filter '*.html' -File -Recurse |
  Where-Object {
    $_.FullName -notmatch '\\_reports\\' -and
    $_.Name -notmatch '\.bak-' -and
    $_.FullName -notmatch '\.bak-'
  } |
  Sort-Object FullName

if ($htmlFiles.Count -eq 0) {
  Write-Host ''
  Write-Host 'No HTML files found in:' -ForegroundColor Yellow
  Write-Host $SketchesDir
  Write-Host ''
  exit 0
}

$rows = New-Object System.Collections.Generic.List[object]

foreach ($file in $htmlFiles) {
  $path = $file.FullName
  $relativePath = $path.Substring($RepoRoot.Length + 1)

  $html = Get-Content -Path $path -Raw -Encoding UTF8
  $originalHtml = $html

  # Remove previous global centering override if present.
  $globalPattern = '(?s)\s*/\* BEGIN SKETCHES CENTERING OVERRIDES \*/.*?/\* END SKETCHES CENTERING OVERRIDES \*/'
  $html = [regex]::Replace($html, $globalPattern, '')

  # Remove older Grins-only centering override if present, so there is only one centering block.
  $grinsPattern = '(?s)\s*/\* BEGIN GRINS CENTERING OVERRIDES \*/.*?/\* END GRINS CENTERING OVERRIDES \*/'
  $html = [regex]::Replace($html, $grinsPattern, '')

  if ($html -match '</style>') {
    $html = $html -replace '</style>', ($OverrideCss + "`n  </style>")
  }
  else {
    # Fallback for any page without an internal style block.
    $styleBlock = "<style>`n$OverrideCss`n  </style>`n"
    $html = $html -replace '</head>', ($styleBlock + '</head>')
  }

  $willChange = ($html -ne $originalHtml)

  $rows.Add([pscustomobject]@{
    File = $file.Name
    RelativePath = $relativePath
    FullPath = $path
    WillChange = $willChange
    Backup = ''
    Status = $(if ($willChange) { 'Will update' } else { 'No change' })
  })
}

$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$csvPath = Join-Path $ReportDir 'all-sketches-centering-format-report.csv'
$txtPath = Join-Path $ReportDir 'all-sketches-centering-format-summary.txt'

if ($ReportOnly) {
  $rows | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

  $summary = @()
  $summary += 'All Sketches centering format report'
  $summary += "Generated: $timestamp"
  $summary += ''
  $summary += "Sketches folder: $SketchesDir"
  $summary += "HTML files found: $($htmlFiles.Count)"
  $summary += "HTML files that would be updated: $(@($rows | Where-Object { $_.WillChange }).Count)"
  $summary += ''
  $summary += 'Report-only mode: no files were changed.'
  $summary | Set-Content -Path $txtPath -Encoding UTF8

  Write-Host ''
  Write-Host 'Report-only mode complete. No files were changed.' -ForegroundColor Green
  Write-Host ''
  Write-Host 'Reports:'
  Write-Host " - $csvPath"
  Write-Host " - $txtPath"
  Write-Host ''
  exit 0
}

$editedRows = New-Object System.Collections.Generic.List[object]

foreach ($row in $rows) {
  if ($row.WillChange) {
    $backupPath = Backup-IfExists $row.FullPath

    $html = Get-Content -Path $row.FullPath -Raw -Encoding UTF8

    $globalPattern = '(?s)\s*/\* BEGIN SKETCHES CENTERING OVERRIDES \*/.*?/\* END SKETCHES CENTERING OVERRIDES \*/'
    $html = [regex]::Replace($html, $globalPattern, '')

    $grinsPattern = '(?s)\s*/\* BEGIN GRINS CENTERING OVERRIDES \*/.*?/\* END GRINS CENTERING OVERRIDES \*/'
    $html = [regex]::Replace($html, $grinsPattern, '')

    if ($html -match '</style>') {
      $html = $html -replace '</style>', ($OverrideCss + "`n  </style>")
    }
    else {
      $styleBlock = "<style>`n$OverrideCss`n  </style>`n"
      $html = $html -replace '</head>', ($styleBlock + '</head>')
    }

    Set-Content -Path $row.FullPath -Value $html -Encoding UTF8

    $row.Backup = $backupPath
    $row.Status = 'Updated'
    $editedRows.Add($row)
  }
}

$rows | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

$summary = @()
$summary += 'All Sketches centering format report'
$summary += "Generated: $timestamp"
$summary += ''
$summary += "Sketches folder: $SketchesDir"
$summary += "HTML files found: $($htmlFiles.Count)"
$summary += "HTML files updated: $($editedRows.Count)"
$summary += ''
$summary += 'Formatting applied:'
$summary += '- Centered top pill navigation.'
$summary += '- Centered page titles.'
$summary += '- Centered intro text.'
$summary += '- Centered section headings, including Original Drawing, Digitized Versions, and Collector Cards.'
$summary += '- Centered card/work titles and image captions.'
$summary += '- Centered footer text.'
$summary += '- Kept Back to... links left-aligned.'
$summary += ''
$summary += 'Updated files:'
foreach ($row in $editedRows) {
  $summary += ('- ' + $row.RelativePath)
}
$summary | Set-Content -Path $txtPath -Encoding UTF8

Write-Host ''
Write-Host 'All Sketches centering formatting applied successfully.' -ForegroundColor Green
Write-Host ''
Write-Host "HTML files updated: $($editedRows.Count)"
Write-Host ''
Write-Host 'Reports:'
Write-Host " - $csvPath"
Write-Host " - $txtPath"
Write-Host ''
Write-Host 'Backups were created before editing each updated file.' -ForegroundColor Yellow
Write-Host ''
