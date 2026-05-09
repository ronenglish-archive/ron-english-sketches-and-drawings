[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$RepoRoot = 'D:\github\ron-english-sketches-and-drawings'

$PagesToFix = @(
    (Join-Path $RepoRoot 'Sketches\celebrity-characters\pepe\index.html'),
    (Join-Path $RepoRoot 'Sketches\celebrity-characters\pepe\pepe-squarepants\index.html')
)

$CenteringBlock = @"
  <!-- Strong card-title centering override -->
  <style id="strong-card-title-centering-override">
    .index-grid,
    .gallery-grid,
    .originals-grid,
    .card-grid {
      justify-items: center !important;
    }

    .gallery-item {
      text-align: center !important;
    }

    .index-grid > .gallery-item,
    .gallery-grid > .gallery-item,
    .originals-grid > .gallery-item,
    .card-grid > .gallery-item {
      width: 100% !important;
      max-width: 100% !important;
      display: flex !important;
      flex-direction: column !important;
      align-items: stretch !important;
      justify-content: flex-start !important;
    }

    .gallery-item > a {
      width: 100% !important;
      display: block !important;
      text-align: center !important;
    }

    .gallery-item img {
      display: block !important;
      margin-left: auto !important;
      margin-right: auto !important;
    }

    .entry-body {
      width: 100% !important;
      display: flex !important;
      flex-direction: column !important;
      align-items: center !important;
      justify-content: center !important;
      text-align: center !important;
      padding-left: 18px !important;
      padding-right: 18px !important;
    }

    .work-title,
    .entry-body .work-title,
    .entry-body p,
    figcaption {
      width: 100% !important;
      max-width: none !important;
      display: block !important;
      margin-left: auto !important;
      margin-right: auto !important;
      text-align: center !important;
      align-self: center !important;
    }

    .back-link,
    .back-link a {
      text-align: left !important;
    }
  </style>
"@

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
        $backupPath = Join-Path $backupDir "$name-before-strong-centering-$timestamp$ext"

        Copy-Item -LiteralPath $Path -Destination $backupPath -Force
        Write-Host "Backup created: $backupPath"
    }
}

function Fix-Page {
    param([Parameter(Mandatory=$true)][string]$PagePath)

    if (-not (Test-Path -LiteralPath $PagePath)) {
        Write-Warning "Page not found, skipping: $PagePath"
        return
    }

    Backup-FileIfExists -Path $PagePath

    $html = [System.IO.File]::ReadAllText($PagePath)

    # Remove earlier failed page-specific centering blocks if present.
    $html = [regex]::Replace(
        $html,
        '(?is)\s*<!-- Page-specific centering fix -->\s*<style id="pepe-squarepants-centering-fix">.*?</style>\s*',
        "`r`n"
    )

    $html = [regex]::Replace(
        $html,
        '(?is)\s*<!-- Force caption/text centering fix -->\s*<style id="force-pepe-squarepants-caption-centering">.*?</style>\s*',
        "`r`n"
    )

    $html = [regex]::Replace(
        $html,
        '(?is)\s*<!-- Strong card-title centering override -->\s*<style id="strong-card-title-centering-override">.*?</style>\s*',
        "`r`n"
    )

    if ($html -match '(?i)</head>') {
        # Put this last in the head, so it wins over the earlier style block.
        $html = [regex]::Replace($html, '(?i)</head>', "$CenteringBlock`r`n</head>", 1)
    }
    else {
        throw "Could not find </head> in: $PagePath"
    }

    # Normalize the title container on the Pepe index specifically.
    # This makes every title container full width, which fixes titles that look offset.
    $html = $html.Replace('<div class="entry-body">', '<div class="entry-body" style="width:100%; text-align:center; display:flex; align-items:center; justify-content:center;">')
    $html = $html.Replace('<p class="work-title">', '<p class="work-title" style="width:100%; text-align:center; margin-left:auto; margin-right:auto;">')

    [System.IO.File]::WriteAllText($PagePath, $html, [System.Text.UTF8Encoding]::new($false))
    Write-Host "Applied strong centering to: $PagePath"
}

foreach ($page in $PagesToFix) {
    Fix-Page -PagePath $page
}

Write-Host ""
Write-Host "Done. Refresh with Ctrl+F5:"
Write-Host "  D:\github\ron-english-sketches-and-drawings\Sketches\celebrity-characters\pepe\index.html"
Write-Host "  D:\github\ron-english-sketches-and-drawings\Sketches\celebrity-characters\pepe\pepe-squarepants\index.html"
