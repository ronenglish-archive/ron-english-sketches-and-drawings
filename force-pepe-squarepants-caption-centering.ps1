[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$RepoRoot = 'D:\github\ron-english-sketches-and-drawings'
$PagePath = Join-Path $RepoRoot 'Sketches\celebrity-characters\pepe\pepe-squarepants\index.html'

$ForceCenteringBlock = @"
  <!-- Force caption/text centering fix -->
  <style id="force-pepe-squarepants-caption-centering">
    html body main.wrap .section-card figure,
    html body main.wrap .section-card figcaption,
    html body main.wrap .section-card .gallery-item,
    html body main.wrap .section-card .gallery-item *,
    html body main.wrap .section-card .caption,
    html body main.wrap .section-card .image-caption,
    html body main.wrap .section-card .figcaption,
    html body main.wrap .section-card .entry-body,
    html body main.wrap .section-card .work-title,
    html body main.wrap .section-card p,
    html body main.wrap .section-card span,
    html body main.wrap .section-card div {
      text-align: center !important;
    }

    html body main.wrap .section-card figure,
    html body main.wrap .section-card .gallery-item {
      display: flex !important;
      flex-direction: column !important;
      align-items: center !important;
      justify-content: center !important;
      width: 100% !important;
      margin-left: auto !important;
      margin-right: auto !important;
    }

    html body main.wrap .section-card figcaption,
    html body main.wrap .section-card .caption,
    html body main.wrap .section-card .image-caption,
    html body main.wrap .section-card .figcaption,
    html body main.wrap .section-card .entry-body,
    html body main.wrap .section-card .work-title {
      display: block !important;
      width: 100% !important;
      margin-left: auto !important;
      margin-right: auto !important;
      text-align: center !important;
      align-self: center !important;
    }

    html body main.wrap .section-card img {
      display: block !important;
      margin-left: auto !important;
      margin-right: auto !important;
    }

    html body main.wrap .back-link,
    html body main.wrap .back-link a {
      text-align: left !important;
      align-items: flex-start !important;
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
        $backupPath = Join-Path $backupDir "$name-before-force-caption-centering-$timestamp$ext"

        Copy-Item -LiteralPath $Path -Destination $backupPath -Force
        Write-Host "Backup created: $backupPath"
    }
}

function Add-Or-Replace-StyleAttribute {
    param(
        [Parameter(Mandatory=$true)][string]$Tag
    )

    $forceStyle = 'text-align:center !important; width:100% !important; display:block !important; margin-left:auto !important; margin-right:auto !important;'

    if ($Tag -match '(?i)\sstyle="([^"]*)"') {
        return [regex]::Replace($Tag, '(?i)\sstyle="[^"]*"', " style=""$forceStyle""", 1)
    }

    return $Tag -replace '>$', " style=""$forceStyle"">"
}

if (-not (Test-Path -LiteralPath $PagePath)) {
    throw "Page not found: $PagePath"
}

Backup-FileIfExists -Path $PagePath

$html = [System.IO.File]::ReadAllText($PagePath)

# Replace any previous page-specific centering attempts so the newest one wins.
$html = [regex]::Replace(
    $html,
    '(?is)\s*<!-- Page-specific centering fix -->\s*<style id="pepe-squarepants-centering-fix">.*?</style>\s*',
    "`r`n",
    1
)

$html = [regex]::Replace(
    $html,
    '(?is)\s*<!-- Force caption/text centering fix -->\s*<style id="force-pepe-squarepants-caption-centering">.*?</style>\s*',
    "`r`n",
    1
)

# Insert the force CSS immediately before </head>.
if ($html -match '(?i)</head>') {
    $html = [regex]::Replace($html, '(?i)</head>', "$ForceCenteringBlock`r`n</head>", 1)
}
else {
    throw "Could not find </head> in: $PagePath"
}

# Also force inline centering on common caption/text elements, in case an inline left-align was overriding CSS.
$tagPatterns = @(
    '<figcaption\b[^>]*>',
    '<p\b(?=[^>]*class="[^"]*(caption|title|work-title|image|entry)[^"]*")[^>]*>',
    '<div\b(?=[^>]*class="[^"]*(caption|title|work-title|image|entry)[^"]*")[^>]*>',
    '<span\b(?=[^>]*class="[^"]*(caption|title|work-title|image|entry)[^"]*")[^>]*>'
)

foreach ($pattern in $tagPatterns) {
    $html = [regex]::Replace($html, $pattern, {
        param($m)
        Add-Or-Replace-StyleAttribute -Tag $m.Value
    })
}

[System.IO.File]::WriteAllText($PagePath, $html, [System.Text.UTF8Encoding]::new($false))

Write-Host "Forced text/caption centering on:"
Write-Host "  $PagePath"
Write-Host ""
Write-Host "Refresh with Ctrl+F5:"
Write-Host "  D:\github\ron-english-sketches-and-drawings\Sketches\celebrity-characters\pepe\pepe-squarepants\index.html"
