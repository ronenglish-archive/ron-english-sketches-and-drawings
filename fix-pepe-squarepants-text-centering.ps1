[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$RepoRoot = 'D:\github\ron-english-sketches-and-drawings'
$PagePath = Join-Path $RepoRoot 'Sketches\celebrity-characters\pepe\pepe-squarepants\index.html'

$CenteringBlock = @"
  <!-- Page-specific centering fix -->
  <style id="pepe-squarepants-centering-fix">
    .gallery-item,
    .gallery-item a,
    .gallery-item p,
    .gallery-item figcaption,
    figure,
    figcaption,
    .entry-body,
    .work-title,
    .section-card,
    .section-card p,
    .section-card h2,
    .page-header,
    .page-title,
    footer {
      text-align: center !important;
    }

    .gallery-item {
      display: flex !important;
      flex-direction: column !important;
      align-items: center !important;
      justify-content: center !important;
    }

    .gallery-item img {
      margin-left: auto !important;
      margin-right: auto !important;
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
        $backupPath = Join-Path $backupDir "$name-before-text-centering-fix-$timestamp$ext"

        Copy-Item -LiteralPath $Path -Destination $backupPath -Force
        Write-Host "Backup created: $backupPath"
    }
}

if (-not (Test-Path -LiteralPath $PagePath)) {
    throw "Page not found: $PagePath"
}

Backup-FileIfExists -Path $PagePath

$html = [System.IO.File]::ReadAllText($PagePath)
$originalHtml = $html

$existingBlockPattern = '(?is)\s*<!-- Page-specific centering fix -->\s*<style id="pepe-squarepants-centering-fix">.*?</style>\s*'

if ($html -match $existingBlockPattern) {
    $html = [regex]::Replace($html, $existingBlockPattern, "`r`n$CenteringBlock`r`n", 1)
}
elseif ($html -match '(?i)</head>') {
    $html = [regex]::Replace($html, '(?i)</head>', "$CenteringBlock`r`n</head>", 1)
}
else {
    throw "Could not find </head> in: $PagePath"
}

[System.IO.File]::WriteAllText($PagePath, $html, [System.Text.UTF8Encoding]::new($false))

Write-Host "Text centering fixed on:"
Write-Host "  $PagePath"
Write-Host ""
Write-Host "Refresh this page:"
Write-Host "  D:\github\ron-english-sketches-and-drawings\Sketches\celebrity-characters\pepe\pepe-squarepants\index.html"
