[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$RepoRoot = 'D:\github\ron-english-sketches-and-drawings'
$SketchesRoot = Join-Path $RepoRoot 'Sketches'
$Utf8NoBom = New-Object System.Text.UTF8Encoding $false

$FixBlock = @'
  <style id="sketches-global-centering-and-image-fix">
    /* Global repair: center image captions/text and prevent index thumbnails from cropping. */
    .gallery-item,
    .gallery-item a,
    .gallery-item figure,
    .entry-card,
    .entry-card a,
    .index-card,
    .index-card a,
    .category-card,
    .category-card a,
    .work-card,
    .work-card a,
    .subcat-card,
    .subcat-card a,
    figure,
    figcaption,
    .entry-body,
    .work-title,
    .entry-title,
    .card-title,
    .gallery-title,
    .item-title,
    .caption,
    .thumb-caption,
    .image-caption {
      text-align: center !important;
    }

    .entry-body,
    .work-title,
    .entry-title,
    .card-title,
    .gallery-title,
    .item-title,
    figcaption,
    .caption,
    .thumb-caption,
    .image-caption {
      width: 100% !important;
      margin-left: auto !important;
      margin-right: auto !important;
      align-items: center !important;
      justify-content: center !important;
    }

    .entry-body {
      display: flex !important;
      flex-direction: column !important;
    }

    .index-grid .gallery-item img,
    .index-grid .entry-card img,
    .index-grid .index-card img,
    .index-grid .category-card img,
    .index-grid .work-card img,
    .category-grid .gallery-item img,
    .category-grid .entry-card img,
    .category-grid .index-card img,
    .category-grid .category-card img,
    .category-grid .work-card img,
    .subcategories-grid img,
    .gallery-index img,
    .sketch-grid img,
    .cards-grid img {
      object-fit: contain !important;
      object-position: center center !important;
      background: #f3f4f6 !important;
    }

    .index-grid .gallery-item,
    .index-grid .entry-card,
    .index-grid .index-card,
    .index-grid .category-card,
    .index-grid .work-card,
    .category-grid .gallery-item,
    .category-grid .entry-card,
    .category-grid .index-card,
    .category-grid .category-card,
    .category-grid .work-card {
      overflow: hidden !important;
    }

    .index-grid .gallery-item img,
    .index-grid .entry-card img,
    .index-grid .index-card img,
    .index-grid .category-card img,
    .index-grid .work-card img {
      height: 240px !important;
      max-height: 240px !important;
      padding: 10px !important;
    }

    @media (max-width: 560px) {
      .index-grid .gallery-item img,
      .index-grid .entry-card img,
      .index-grid .index-card img,
      .index-grid .category-card img,
      .index-grid .work-card img {
        height: 220px !important;
        max-height: 220px !important;
      }
    }
  </style>
'@

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
        $backupPath = Join-Path $backupDir "$name-before-centering-image-fix-$timestamp$ext"

        Copy-Item -LiteralPath $Path -Destination $backupPath -Force
    }
}

if (-not (Test-Path -LiteralPath $SketchesRoot)) {
    throw "Sketches folder not found: $SketchesRoot"
}

$htmlFiles = @(Get-ChildItem -LiteralPath $SketchesRoot -Recurse -File -Filter 'index.html' | Where-Object {
    $_.FullName -notmatch '\\_backups\\'
})

if ($htmlFiles.Count -eq 0) {
    throw "No index.html files found under: $SketchesRoot"
}

$changed = 0

foreach ($file in $htmlFiles) {
    $path = $file.FullName
    $html = [System.IO.File]::ReadAllText($path)
    $original = $html

    # Remove any older copy of this exact repair block, then add the current one.
    $html = [regex]::Replace(
        $html,
        '(?is)\s*<style\s+id="sketches-global-centering-and-image-fix">.*?</style>',
        ''
    )

    if ($html -match '(?is)</head>') {
        $html = [regex]::Replace($html, '(?is)</head>', "$FixBlock`r`n</head>", 1)
    }
    else {
        Write-Warning "No </head> tag found, skipped: $path"
        continue
    }

    if ($html -ne $original) {
        Backup-FileIfExists -Path $path
        [System.IO.File]::WriteAllText($path, $html, $Utf8NoBom)
        $changed++
    }
}

Write-Host ""
Write-Host "Done."
Write-Host "Updated $changed HTML files under:"
Write-Host "  $SketchesRoot"
Write-Host ""
Write-Host "This centered captions/titles and changed index thumbnails to object-fit: contain so images are not cut off."
Write-Host "Open a few category index pages and individual pages to verify, then push when ready."
