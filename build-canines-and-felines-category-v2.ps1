[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$RepoRoot = 'D:\github\ron-english-sketches-and-drawings'

$CategoryTitle = 'Canines and Felines'
$CategorySlug = 'canines-and-felines'

$ImageCategoryFolderName = 'Canines and felines'
$ImageRoot = Join-Path $RepoRoot "images\Sketches\$ImageCategoryFolderName"

$HtmlRoot = Join-Path $RepoRoot "Sketches\$CategorySlug"
$SketchesIndexPath = Join-Path $RepoRoot 'Sketches\index.html'

$Subcategories = @(
    [pscustomobject]@{ Title='Cats'; Slug='cats'; ImageFolder='Cats' },
    [pscustomobject]@{ Title='Dogs'; Slug='dogs'; ImageFolder='Dogs' },
    [pscustomobject]@{ Title='Foxes'; Slug='foxes'; ImageFolder='Foxes' },
    [pscustomobject]@{ Title='Wolves'; Slug='wolves'; ImageFolder='Wolves' }
)

function Encode-Part {
    param([AllowEmptyString()][string]$Text)

    if ([string]::IsNullOrEmpty($Text)) {
        return $Text
    }

    return [System.Uri]::EscapeDataString($Text)
}

function ConvertTo-Slug {
    param([Parameter(Mandatory=$true)][string]$Text)

    $slug = $Text.ToLowerInvariant()
    $slug = $slug -replace '&', ' and '
    $slug = $slug -replace "['’]", ''
    $slug = $slug -replace '[^a-z0-9]+', '-'
    $slug = $slug.Trim('-')

    if ([string]::IsNullOrWhiteSpace($slug)) {
        $slug = 'untitled'
    }

    return $slug
}

function New-WebImagePath {
    param(
        [Parameter(Mandatory=$true)][string]$Prefix,
        [Parameter(Mandatory=$true)][string]$SubfolderName,
        [Parameter(Mandatory=$true)][string]$FileName
    )

    return "$Prefix/$(Encode-Part $ImageCategoryFolderName)/$(Encode-Part $SubfolderName)/$(Encode-Part $FileName)"
}

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
        $backupPath = Join-Path $backupDir "$name-before-canines-felines-build-$timestamp$ext"

        Copy-Item -LiteralPath $Path -Destination $backupPath -Force
        Write-Host "Backup created: $backupPath"
    }
}

function Get-ImageKind {
    param([Parameter(Mandatory=$true)][string]$FileName)

    if ($FileName -match '(?i)\bcard\b') {
        return 'Card'
    }

    if ($FileName -match '(?i)\bORIGINAL\b|original') {
        return 'Original'
    }

    return 'Digitized'
}

function Get-BaseTitleFromFileName {
    param([Parameter(Mandatory=$true)][string]$FileName)

    $name = [System.IO.Path]::GetFileNameWithoutExtension($FileName)
    $s = $name.Trim()

    # Remove copy markers first.
    $s = $s -replace '(?i)\s*-\s*Copy$', ''
    $s = $s -replace '(?i)\s+copy$', ''

    # Cards belong with the character/page they name.
    $s = $s -replace '(?i)\s+card\s*\d*$', ''

    $changed = $true
    while ($changed) {
        $before = $s

        # Remove image-state descriptors.
        $s = $s -replace '(?i)\s+B&W$', ''
        $s = $s -replace '(?i)\s+BW$', ''
        $s = $s -replace '(?i)\s+COLORWAY\s+\d+$', ''
        $s = $s -replace '(?i)\s+colorway\s+\d+$', ''
        $s = $s -replace '(?i)\s+COLOR\s+\(?\d+\)?$', ''
        $s = $s -replace '(?i)\s+COLOR-\d+$', ''
        $s = $s -replace '(?i)\s+COLOR$', ''
        $s = $s -replace '(?i)\s+ORIGINAL\s+COLOR-\d+$', ''
        $s = $s -replace '(?i)\s+ORIGINAL\s+COLOR\s+\(?\d+\)?$', ''
        $s = $s -replace '(?i)\s+ORIGINAL\s+COLOR$', ''
        $s = $s -replace '(?i)\s+ORIGINAL\s+\(?\d+\)?$', ''
        $s = $s -replace '(?i)\s+ORIGINAL$', ''
        $s = $s -replace '(?i)\s+original\s+B&W$', ''
        $s = $s -replace '(?i)\s+original$', ''

        # Remove view descriptors after the state descriptors have been stripped.
        # Do not remove "Face" because many real titles use "Face 1", "Kiss Face", etc.
        $s = $s -replace '(?i)\s+three quarters$', ''
        $s = $s -replace '(?i)\s+right side$', ''
        $s = $s -replace '(?i)\s+left side$', ''
        $s = $s -replace '(?i)\s+front$', ''
        $s = $s -replace '(?i)\s+back$', ''
        $s = $s -replace '(?i)\s+side$', ''
        $s = $s -replace '(?i)\s+head$', ''
        $s = $s -replace '(?i)\s+portrait$', ''
        $s = $s -replace '(?i)\s+tail$', ''
        $s = $s -replace '(?i)\s+full$', ''
        $s = $s -replace '(?i)\s+half$', ''

        $s = $s.Trim()
        $changed = ($s -ne $before)
    }

    if ([string]::IsNullOrWhiteSpace($s)) {
        $s = $name
    }

    # A couple of tiny display fixes while preserving source filenames.
    $s = $s -replace '\s+', ' '
    $s = $s -replace '(?i)^FACLESS DOG$', 'Faceless Dog'

    return $s.Trim()
}

function Get-GroupKey {
    param([Parameter(Mandatory=$true)][string]$BaseTitle)

    $key = $BaseTitle.ToLowerInvariant()
    $key = $key -replace '&', ' and '
    $key = $key -replace "['’]", ''
    $key = $key -replace '(?i)facless', 'faceless'
    $key = $key -replace '[^a-z0-9]+', ' '
    $key = $key.Trim()
    return $key
}

function Get-FilesForSubcategory {
    param([Parameter(Mandatory=$true)][pscustomobject]$Subcategory)

    $folder = Join-Path $ImageRoot $Subcategory.ImageFolder

    if (-not (Test-Path -LiteralPath $folder)) {
        throw "Image folder not found: $folder"
    }

    return @(Get-ChildItem -LiteralPath $folder -File | Where-Object {
        $_.Extension -match '^\.(jpg|jpeg|png|webp|gif|avif|tif|tiff)$'
    } | Sort-Object Name)
}

function Get-GroupsForSubcategory {
    param([Parameter(Mandatory=$true)][pscustomobject]$Subcategory)

    $files = Get-FilesForSubcategory -Subcategory $Subcategory
    $byKey = @{}

    foreach ($file in $files) {
        $baseTitle = Get-BaseTitleFromFileName -FileName $file.Name
        $key = Get-GroupKey -BaseTitle $baseTitle

        if (-not $byKey.ContainsKey($key)) {
            $byKey[$key] = [pscustomobject]@{
                Title = $baseTitle
                Slug = ConvertTo-Slug -Text $baseTitle
                Files = New-Object System.Collections.Generic.List[System.IO.FileInfo]
            }
        }

        $byKey[$key].Files.Add($file)
    }

    return @($byKey.Values | Sort-Object Title)
}

function Select-ThumbFile {
    param(
        [Parameter(Mandatory=$true)][System.IO.FileInfo[]]$Files,
        [string]$SubcategoryTitle = ''
    )

    $nonCards = @($Files | Where-Object { $_.Name -notmatch '(?i)\bcard\b' })

    $categoryPreferredPatterns = @()
    if ($SubcategoryTitle -eq 'Cats') {
        $categoryPreferredPatterns = @('(?i)^Cats Logo COLOR', '(?i)^Cats Logo ORIGINAL', '(?i)^Cat With Dog COLOR')
    }
    elseif ($SubcategoryTitle -eq 'Dogs') {
        $categoryPreferredPatterns = @('(?i)^Dogs Logo COLOR', '(?i)^Dogs Logo ORIGINAL', '(?i)^Dogs Family Icon COLOR')
    }
    elseif ($SubcategoryTitle -eq 'Foxes') {
        $categoryPreferredPatterns = @('(?i)^Foxes Family Icon COLOR', '(?i)^Foxy Fox COLOR', '(?i)^Faux Fox COLOR')
    }
    elseif ($SubcategoryTitle -eq 'Wolves') {
        $categoryPreferredPatterns = @('(?i)^Wolf Family Icon COLOR', '(?i)^Gray Wolf COLOR', '(?i)^Black Wolf COLOR')
    }

    foreach ($pattern in $categoryPreferredPatterns) {
        $candidate = @($Files | Where-Object { $_.Name -match $pattern } | Sort-Object Name | Select-Object -First 1)
        if ($candidate.Count -gt 0) {
            return $candidate[0]
        }
    }

    $rules = @(
        { param($f) $f.Name -match '(?i)\bCOLOR\b' -and $f.Name -notmatch '(?i)\b(side|back|tail)\b' -and $f.Name -notmatch '(?i)colorway' },
        { param($f) $f.Name -match '(?i)\bORIGINAL COLOR\b' -and $f.Name -notmatch '(?i)\b(side|back|tail)\b' },
        { param($f) $f.Name -match '(?i)\bORIGINAL\b' -and $f.Name -notmatch '(?i)\b(side|back|tail)\b' },
        { param($f) $f.Name -match '(?i)\bCOLOR\b' },
        { param($f) $f.Name -match '(?i)\bB&W\b' },
        { param($f) $true }
    )

    foreach ($rule in $rules) {
        $candidate = @($nonCards | Where-Object { & $rule $_ } | Sort-Object Name | Select-Object -First 1)
        if ($candidate.Count -gt 0) {
            return $candidate[0]
        }
    }

    return ($Files | Sort-Object Name | Select-Object -First 1)
}

function New-FigureHtml {
    param(
        [Parameter(Mandatory=$true)][System.IO.FileInfo]$File,
        [Parameter(Mandatory=$true)][string]$AltText,
        [Parameter(Mandatory=$true)][string]$ImagePrefix,
        [Parameter(Mandatory=$true)][string]$SubfolderName
    )

    $src = New-WebImagePath -Prefix $ImagePrefix -SubfolderName $SubfolderName -FileName $File.Name

    $ext = $File.Extension.ToLowerInvariant()
    if ($ext -eq '.tif' -or $ext -eq '.tiff') {
@"
        <figure class="gallery-item file-link-card">
          <a href="$src" target="_blank" rel="noopener noreferrer">
            <div class="file-placeholder">TIFF source file</div>
          </a>
        </figure>
"@
    }
    else {
@"
        <figure class="gallery-item">
          <a href="$src" target="_blank" rel="noopener noreferrer">
            <img src="$src" alt="$AltText" loading="lazy" />
          </a>
        </figure>
"@
    }
}

function Get-SharedCss {
@"
  <style>
    :root{ --border:#e5e7eb; --muted:#4b5563; --shadow:0 10px 30px rgba(0,0,0,.08); --radius:18px; --bg:#ffffff; --panel:#f3f4f6; --pill-hover:#f9fafb; }
    *{ box-sizing:border-box; }
    html{ scroll-behavior:smooth; }
    body{ margin:0; font-family:system-ui,-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif; color:#111; background:var(--bg); padding-left:0; padding-right:0; }
    .wrap{ max-width:1240px; margin:0 auto; padding:28px 18px 60px; }
    .page-narrow{ max-width:1100px; }
    .nav-pills{ display:flex; flex-wrap:wrap; gap:10px; margin:22px 0; justify-content:center; text-align:center; }
    .nav-pill{ padding:8px 14px; border-radius:999px; border:1px solid var(--border); background:#fff; color:#111; text-decoration:none; font-size:14px; transition:background .12s ease,border-color .12s ease,transform .12s ease; }
    .nav-pill:hover{ background:var(--pill-hover); border-color:#d1d5db; transform:translateY(-1px); }
    .page-header{ max-width:1100px; margin:0 auto 28px; padding:0; text-align:center; }
    .page-title{ margin:0 0 10px; font-size:clamp(2rem,4vw,3rem); letter-spacing:-.02em; line-height:1.05; text-align:center; }
    .section-card{ background:#fff; border:1px solid var(--border); border-radius:var(--radius); box-shadow:var(--shadow); padding:22px; margin-bottom:24px; }
    .section-card h2{ margin:0 0 8px; font-size:1.4rem; text-align:center; }
    .section-intro{ margin:0 0 18px; color:var(--muted); line-height:1.6; text-align:center; }
    .index-grid{ margin-top:28px; display:grid; grid-template-columns:repeat(auto-fit,minmax(220px,1fr)); gap:18px; justify-items:center; }
    .gallery-grid,.originals-grid,.card-grid{ display:grid; grid-template-columns:repeat(auto-fit,minmax(240px,1fr)); gap:20px; justify-items:center; }
    .gallery-item{ width:100%; display:block; text-decoration:none; color:inherit; background:#fff; border:1px solid var(--border); border-radius:16px; overflow:hidden; box-shadow:0 4px 18px rgba(0,0,0,.04); margin:0; transition:transform .12s ease,box-shadow .12s ease,border-color .12s ease; text-align:center; }
    .gallery-item:hover{ transform:translateY(-2px); box-shadow:0 16px 40px rgba(0,0,0,.12); border-color:#d1d5db; }
    .gallery-item a{ display:block; color:inherit; text-decoration:none; text-align:center; }
    .gallery-item img{ display:block; width:100%; object-fit:contain; background:var(--panel); padding:8px; border-bottom:0; margin-left:auto; margin-right:auto; }
    .index-grid .gallery-item img{ height:240px; padding:10px; border-bottom:1px solid var(--border); }
    .originals-grid .gallery-item img{ height:420px; }
    .gallery-grid .gallery-item img{ height:320px; }
    .card-grid .gallery-item img{ height:420px; }
    .file-placeholder{ min-height:220px; display:flex; align-items:center; justify-content:center; text-align:center; background:var(--panel); color:var(--muted); padding:18px; font-weight:600; }
    .entry-body{ width:100%; padding:16px 18px 18px; display:flex; flex-direction:column; align-items:center; justify-content:center; text-align:center; }
    .work-title{ margin:0 auto; padding:0; width:100%; font-size:18px; line-height:1.35; font-weight:600; text-align:center; }
    .back-link{ margin-top:28px; text-align:left; }
    .back-link a{ display:inline-block; text-decoration:none; color:#111; border:1px solid var(--border); border-radius:999px; padding:10px 16px; background:#fff; text-align:left; }
    .back-link a:hover{ background:#f9fafb; }
    footer{ margin-top:34px; padding-top:16px; border-top:1px solid var(--border); color:var(--muted); font-size:14px; text-align:center; }
    @media (max-width:560px){ .wrap{ padding:22px 14px 50px; } .index-grid,.gallery-grid,.originals-grid,.card-grid{ grid-template-columns:1fr; } .index-grid .gallery-item img{ height:240px; } .originals-grid .gallery-item img{ height:340px; } .gallery-grid .gallery-item img{ height:280px; } .card-grid .gallery-item img{ height:340px; } }
  </style>
"@
}

function New-SectionHtml {
    param(
        [Parameter(Mandatory=$true)][string]$SectionId,
        [Parameter(Mandatory=$true)][string]$Title,
        [Parameter(Mandatory=$true)][string]$GridClass,
        [Parameter(Mandatory=$true)][string[]]$Figures
    )

    if ($Figures.Count -eq 0) {
        return ''
    }

    $figuresHtml = $Figures -join "`r`n"

@"

    <section class="section-card" aria-labelledby="$SectionId">
      <h2 id="$SectionId">$Title</h2>
      <div class="$GridClass">
$figuresHtml
      </div>
    </section>
"@
}

function Build-IndividualPage {
    param(
        [Parameter(Mandatory=$true)][pscustomobject]$Subcategory,
        [Parameter(Mandatory=$true)][pscustomobject]$Group
    )

    $htmlFolder = Join-Path (Join-Path $HtmlRoot $Subcategory.Slug) $Group.Slug
    $htmlPath = Join-Path $htmlFolder 'index.html'

    if (-not (Test-Path -LiteralPath $htmlFolder)) {
        New-Item -ItemType Directory -Path $htmlFolder -Force | Out-Null
    }

    Backup-FileIfExists -Path $htmlPath

    $originalFiles = @($Group.Files | Where-Object { (Get-ImageKind -FileName $_.Name) -eq 'Original' } | Sort-Object Name)
    $digitizedFiles = @($Group.Files | Where-Object { (Get-ImageKind -FileName $_.Name) -eq 'Digitized' } | Sort-Object Name)
    $cardFiles = @($Group.Files | Where-Object { (Get-ImageKind -FileName $_.Name) -eq 'Card' } | Sort-Object Name)

    $sections = @()

    if ($originalFiles.Count -gt 0) {
        $figures = @()
        foreach ($file in $originalFiles) {
            $figures += New-FigureHtml -File $file -AltText "$($Group.Title) original drawing by Ron English" -ImagePrefix '../../../../images/Sketches' -SubfolderName $Subcategory.ImageFolder
        }

        $title = if ($originalFiles.Count -gt 1) { 'Original Drawings' } else { 'Original Drawing' }
        $sections += New-SectionHtml -SectionId 'original-drawing' -Title $title -GridClass 'originals-grid' -Figures $figures
    }
    else {
        $sections += @"

    <section class="section-card" aria-labelledby="original-drawing">
      <h2 id="original-drawing">Original Drawing</h2>
      <p class="section-intro">No original drawing is currently documented on this page. If one is located, it will be added here.</p>
    </section>
"@
    }

    if ($digitizedFiles.Count -gt 0) {
        $figures = @()
        foreach ($file in $digitizedFiles) {
            $figures += New-FigureHtml -File $file -AltText "$($Group.Title) digitized version by Ron English" -ImagePrefix '../../../../images/Sketches' -SubfolderName $Subcategory.ImageFolder
        }

        $sections += New-SectionHtml -SectionId 'digitized-versions' -Title 'Digitized Versions' -GridClass 'gallery-grid' -Figures $figures
    }

    if ($cardFiles.Count -gt 0) {
        $figures = @()
        foreach ($file in $cardFiles) {
            $figures += New-FigureHtml -File $file -AltText "$($Group.Title) collector card by Ron English" -ImagePrefix '../../../../images/Sketches' -SubfolderName $Subcategory.ImageFolder
        }

        $sections += New-SectionHtml -SectionId 'collector-cards' -Title 'Collector Cards' -GridClass 'card-grid' -Figures $figures
    }

    $sectionsHtml = $sections -join ''
    $css = Get-SharedCss

    $html = @"
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>$($Group.Title) | $($Subcategory.Title) | Canines and Felines | Ron English Catalogue Raisonné</title>

  <link rel="stylesheet" href="../../../../css/styles.css" />

$css
</head>
<body>
  <main class="wrap page-narrow">
    <nav class="nav-pills" aria-label="Site navigation">
      <a class="nav-pill" href="https://ronenglish-archive.github.io/ron-english-catalogue-raisonne/">Catalogue home</a>
      <a class="nav-pill" href="../../../index.html">Sketches</a>
      <a class="nav-pill" href="../../index.html">Canines and Felines</a>
      <a class="nav-pill" href="../index.html">$($Subcategory.Title)</a>
    </nav>

    <header class="page-header">
      <h1 class="page-title">$($Group.Title)</h1>
    </header>$sectionsHtml

    <div class="back-link">
      <a href="../index.html">&larr; Back to $($Subcategory.Title)</a>
    </div>

    <footer>
      Published via GitHub Pages for long-term public access.
    </footer>
  </main>
</body>
</html>
"@

    [System.IO.File]::WriteAllText($htmlPath, $html, [System.Text.UTF8Encoding]::new($false))
    Write-Host "Built: $htmlPath"
}

function Build-SubcategoryIndex {
    param(
        [Parameter(Mandatory=$true)][pscustomobject]$Subcategory,
        [Parameter(Mandatory=$true)][object[]]$Groups
    )

    $htmlFolder = Join-Path $HtmlRoot $Subcategory.Slug
    $htmlPath = Join-Path $htmlFolder 'index.html'

    if (-not (Test-Path -LiteralPath $htmlFolder)) {
        New-Item -ItemType Directory -Path $htmlFolder -Force | Out-Null
    }

    Backup-FileIfExists -Path $htmlPath

    $cards = @()

    foreach ($group in ($Groups | Sort-Object Title)) {
        $thumb = Select-ThumbFile -Files $group.Files
        $src = New-WebImagePath -Prefix '../../../images/Sketches' -SubfolderName $Subcategory.ImageFolder -FileName $thumb.Name

        $cards += @"
      <a class="gallery-item" href="$($group.Slug)/index.html">
        <img src="$src" alt="$($group.Title) drawings by Ron English" loading="lazy" />
        <div class="entry-body">
          <p class="work-title">$($group.Title)</p>
        </div>
      </a>
"@
    }

    $cardsHtml = $cards -join "`r`n"
    $css = Get-SharedCss

    $html = @"
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>$($Subcategory.Title) | Canines and Felines | Ron English Catalogue Raisonné</title>

  <link rel="stylesheet" href="../../../css/styles.css" />

$css
</head>
<body>
  <main class="wrap page-narrow">
    <nav class="nav-pills" aria-label="Site navigation">
      <a class="nav-pill" href="https://ronenglish-archive.github.io/ron-english-catalogue-raisonne/">Catalogue home</a>
      <a class="nav-pill" href="../../index.html">Sketches</a>
      <a class="nav-pill" href="../index.html">Canines and Felines</a>
    </nav>

    <header class="page-header">
      <h1 class="page-title">$($Subcategory.Title)</h1>
    </header>

    <section class="index-grid" aria-label="$($Subcategory.Title) sketch and drawing pages">
$cardsHtml
    </section>

    <div class="back-link">
      <a href="../index.html">&larr; Back to Canines and Felines</a>
    </div>

    <footer>
      Published via GitHub Pages for long-term public access.
    </footer>
  </main>
</body>
</html>
"@

    [System.IO.File]::WriteAllText($htmlPath, $html, [System.Text.UTF8Encoding]::new($false))
    Write-Host "Built: $htmlPath"
}

function Build-CategoryIndex {
    param([Parameter(Mandatory=$true)][hashtable]$GroupsBySubcategory)

    $htmlPath = Join-Path $HtmlRoot 'index.html'

    if (-not (Test-Path -LiteralPath $HtmlRoot)) {
        New-Item -ItemType Directory -Path $HtmlRoot -Force | Out-Null
    }

    Backup-FileIfExists -Path $htmlPath

    $cards = @()

    foreach ($subcategory in $Subcategories) {
        $groups = @($GroupsBySubcategory[$subcategory.Slug])
        if ($groups.Count -eq 0) {
            continue
        }

        $allFiles = @()
        foreach ($group in $groups) {
            $allFiles += $group.Files
        }

        $thumb = Select-ThumbFile -Files $allFiles -SubcategoryTitle $subcategory.Title
        $src = New-WebImagePath -Prefix '../../images/Sketches' -SubfolderName $subcategory.ImageFolder -FileName $thumb.Name

        $cards += @"
      <a class="gallery-item" href="$($subcategory.Slug)/index.html">
        <img src="$src" alt="$($subcategory.Title) drawings by Ron English" loading="lazy" />
        <div class="entry-body">
          <p class="work-title">$($subcategory.Title)</p>
        </div>
      </a>
"@
    }

    $cardsHtml = $cards -join "`r`n"
    $css = Get-SharedCss

    $html = @"
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Canines and Felines | Sketches &amp; Drawings | Ron English Catalogue Raisonné</title>

  <link rel="stylesheet" href="../../css/styles.css" />

$css
</head>
<body>
  <main class="wrap page-narrow">
    <nav class="nav-pills" aria-label="Site navigation">
      <a class="nav-pill" href="https://ronenglish-archive.github.io/ron-english-catalogue-raisonne/">Catalogue home</a>
      <a class="nav-pill" href="../index.html">Sketches</a>
    </nav>

    <header class="page-header">
      <h1 class="page-title">Canines and Felines</h1>
    </header>

    <section class="index-grid" aria-label="Canines and Felines subcategories">
$cardsHtml
    </section>

    <div class="back-link">
      <a href="../index.html">&larr; Back to Sketches</a>
    </div>

    <footer>
      Published via GitHub Pages for long-term public access.
    </footer>
  </main>
</body>
</html>
"@

    [System.IO.File]::WriteAllText($htmlPath, $html, [System.Text.UTF8Encoding]::new($false))
    Write-Host "Built: $htmlPath"
}

function Update-MainSketchesIndex {
    param([Parameter(Mandatory=$true)][hashtable]$GroupsBySubcategory)

    if (-not (Test-Path -LiteralPath $SketchesIndexPath)) {
        Write-Warning "Main Sketches index not found, skipping main index update: $SketchesIndexPath"
        return
    }

    $allFiles = @()
    foreach ($subcategory in $Subcategories) {
        $groups = @($GroupsBySubcategory[$subcategory.Slug])
        foreach ($group in $groups) {
            $allFiles += $group.Files
        }
    }

    $heroFile = $null
    $heroSubcategory = $null
    $preferred = @(
        [pscustomobject]@{ Sub='Cats'; Name='Cats Logo COLOR.jpg' },
        [pscustomobject]@{ Sub='Dogs'; Name='Dogs Logo COLOR.jpg' },
        [pscustomobject]@{ Sub='Foxes'; Name='Foxes Family Icon COLOR.jpg' },
        [pscustomobject]@{ Sub='Wolves'; Name='Wolf Family Icon COLOR.jpg' }
    )

    foreach ($pref in $preferred) {
        $subcategory = $Subcategories | Where-Object { $_.Title -eq $pref.Sub } | Select-Object -First 1
        if ($null -eq $subcategory) { continue }

        $candidate = Join-Path (Join-Path $ImageRoot $subcategory.ImageFolder) $pref.Name
        if (Test-Path -LiteralPath $candidate) {
            $heroFile = Get-Item -LiteralPath $candidate
            $heroSubcategory = $subcategory
            break
        }
    }

    if ($null -eq $heroFile) {
        $firstSub = $Subcategories | Select-Object -First 1
        $heroFile = Select-ThumbFile -Files $allFiles
        $heroSubcategory = $firstSub
    }

    $heroSrc = '../images/Sketches/' + (Encode-Part $ImageCategoryFolderName) + '/' + (Encode-Part $heroSubcategory.ImageFolder) + '/' + (Encode-Part $heroFile.Name)

    Backup-FileIfExists -Path $SketchesIndexPath

    $html = [System.IO.File]::ReadAllText($SketchesIndexPath)
    $originalHtml = $html

    $newCard = @"
      <a class="gallery-item" href="canines-and-felines/index.html">
        <img src="$heroSrc" alt="Canines and Felines drawings by Ron English" loading="lazy" />
        <div class="entry-body">
          <p class="work-title">Canines and Felines</p>
        </div>
      </a>
"@

    $cardPattern = '(?is)<a\b(?=[^>]*\bclass="[^"]*\bgallery-item\b[^"]*")[^>]*href="canines-and-felines/index\.html"[^>]*>.*?</a>'

    if ($html -match $cardPattern) {
        $html = [regex]::Replace($html, $cardPattern, $newCard, 1)
        Write-Host "Updated existing Canines and Felines card on Sketches index."
    }
    elseif ($html -match '(?is)(<section\b[^>]*class="[^"]*(?:index-grid|gallery-grid)[^"]*"[^>]*>)(.*?)(</section>)') {
        $html = [regex]::Replace($html, '(?is)(<section\b[^>]*class="[^"]*(?:index-grid|gallery-grid)[^"]*"[^>]*>)(.*?)(</section>)', {
            param($m)
            return $m.Groups[1].Value + $m.Groups[2].Value + "`r`n" + $newCard + "`r`n" + $m.Groups[3].Value
        }, 1)
        Write-Host "Added Canines and Felines card to Sketches index."
    }
    else {
        Write-Warning "Could not find an index/gallery grid on Sketches index. Category page was built, but the main Sketches index was not updated."
    }

    if ($html -ne $originalHtml) {
        [System.IO.File]::WriteAllText($SketchesIndexPath, $html, [System.Text.UTF8Encoding]::new($false))
    }
}

if (-not (Test-Path -LiteralPath $ImageRoot)) {
    throw "Image root not found: $ImageRoot"
}

if (-not (Test-Path -LiteralPath $HtmlRoot)) {
    New-Item -ItemType Directory -Path $HtmlRoot -Force | Out-Null
}

$GroupsBySubcategory = @{}

foreach ($subcategory in $Subcategories) {
    Write-Host ""
    Write-Host "Scanning $($subcategory.Title)..."

    $groups = @(Get-GroupsForSubcategory -Subcategory $subcategory)
    $GroupsBySubcategory[$subcategory.Slug] = $groups

    Build-SubcategoryIndex -Subcategory $subcategory -Groups $groups

    foreach ($group in $groups) {
        Build-IndividualPage -Subcategory $subcategory -Group $group
    }
}

Build-CategoryIndex -GroupsBySubcategory $GroupsBySubcategory
Update-MainSketchesIndex -GroupsBySubcategory $GroupsBySubcategory

Write-Host ""
Write-Host "Done. Canines and Felines category built."
Write-Host "Check:"
Write-Host "  D:\github\ron-english-sketches-and-drawings\Sketches\canines-and-felines\index.html"
Write-Host ""
Write-Host "Then check:"
Write-Host "  D:\github\ron-english-sketches-and-drawings\Sketches\canines-and-felines\cats\index.html"
Write-Host "  D:\github\ron-english-sketches-and-drawings\Sketches\canines-and-felines\dogs\index.html"
Write-Host "  D:\github\ron-english-sketches-and-drawings\Sketches\canines-and-felines\foxes\index.html"
Write-Host "  D:\github\ron-english-sketches-and-drawings\Sketches\canines-and-felines\wolves\index.html"
Write-Host ""
Write-Host "The script also tried to add/update the Canines and Felines card on:"
Write-Host "  D:\github\ron-english-sketches-and-drawings\Sketches\index.html"
