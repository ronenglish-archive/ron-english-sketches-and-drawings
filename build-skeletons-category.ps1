[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$RepoRoot = 'D:\github\ron-english-sketches-and-drawings'

$CategoryTitle = 'Skeletons'
$CategorySlug = 'skeletons'

$ImageRoot = Join-Path $RepoRoot 'images\Sketches\Skeletons'
$HtmlRoot = Join-Path $RepoRoot "Sketches\$CategorySlug"
$SketchesIndexPath = Join-Path $RepoRoot 'Sketches\index.html'

$AllowedExtensions = @('.jpg', '.jpeg', '.png', '.webp', '.gif', '.avif', '.tif', '.tiff', '.bmp')
$Utf8NoBom = New-Object System.Text.UTF8Encoding $false

function Html-Encode {
    param([AllowEmptyString()][string]$Text)
    if ($null -eq $Text) { return '' }
    return [System.Net.WebUtility]::HtmlEncode($Text)
}

function Encode-Part {
    param([AllowEmptyString()][string]$Text)
    if ([string]::IsNullOrEmpty($Text)) { return $Text }
    return [System.Uri]::EscapeDataString($Text)
}

function Split-CamelCaseSafe {
    param([Parameter(Mandatory=$true)][string]$Text)

    # Use .NET regex because PowerShell -replace is case-insensitive by default.
    $s = [regex]::Replace($Text, '([a-z])([A-Z])', '$1 $2')
    $s = [regex]::Replace($s, '([A-Z])([A-Z][a-z])', '$1 $2')
    return $s
}

function ConvertTo-TitleCaseSimple {
    param([Parameter(Mandatory=$true)][string]$Text)

    $clean = $Text -replace '_', ' '
    $clean = $clean -replace '-', ' '
    $clean = Split-CamelCaseSafe -Text $clean
    $clean = $clean -replace '\s+', ' '
    $clean = $clean.Trim()

    $words = $clean -split ' '
    $smallWords = @('and','or','of','the','in','on','with','to','for','a','an')
    $out = New-Object System.Collections.Generic.List[string]

    for ($i = 0; $i -lt $words.Count; $i++) {
        $word = $words[$i]
        if ([string]::IsNullOrWhiteSpace($word)) { continue }

        if ($word -match '^(?i)(B&W|MC|TV|DNA|PDF|PNG|JPG|JPEG|LCCC|R2|FLAT|AI|M\.U\.S\.C\.L\.E\.?)$') {
            $out.Add($word.ToUpperInvariant())
        }
        elseif ($word -match '^([A-Za-z]\.){2,}[A-Za-z]?\.?$') {
            $out.Add($word.ToUpperInvariant())
        }
        elseif (($i -gt 0) -and ($smallWords -contains $word.ToLowerInvariant())) {
            $out.Add($word.ToLowerInvariant())
        }
        elseif ($word.Length -gt 0) {
            $out.Add($word.Substring(0,1).ToUpperInvariant() + $word.Substring(1).ToLowerInvariant())
        }
    }

    return ($out -join ' ')
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

function Get-RelativePart {
    param(
        [Parameter(Mandatory=$true)][string]$FullPath,
        [Parameter(Mandatory=$true)][string]$RootPath
    )

    $root = $RootPath.TrimEnd('\','/')
    $rel = $FullPath.Substring($root.Length)
    $rel = $rel -replace '^[\\/]+', ''
    return $rel
}

function Get-UpPrefixFromHtmlFolder {
    param([Parameter(Mandatory=$true)][string]$HtmlFolder)

    $rel = Get-RelativePart -FullPath $HtmlFolder -RootPath $RepoRoot
    if ([string]::IsNullOrWhiteSpace($rel)) { return '' }

    $parts = @($rel -split '[\\/]' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    return ('../' * $parts.Count)
}

function Get-EncodedRelativeImagePath {
    param([Parameter(Mandatory=$true)][System.IO.FileInfo]$File)

    $rel = Get-RelativePart -FullPath $File.FullName -RootPath (Join-Path $RepoRoot 'images\Sketches')
    $parts = @($rel -split '[\\/]' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    $encodedParts = foreach ($part in $parts) { Encode-Part $part }
    return ($encodedParts -join '/')
}

function New-WebImagePath {
    param(
        [Parameter(Mandatory=$true)][string]$HtmlFolder,
        [Parameter(Mandatory=$true)][System.IO.FileInfo]$File
    )

    $prefix = Get-UpPrefixFromHtmlFolder -HtmlFolder $HtmlFolder
    $rel = Get-EncodedRelativeImagePath -File $File
    return "$prefix" + "images/Sketches/$rel"
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
        $backupPath = Join-Path $backupDir "$name-before-skeletons-build-$timestamp$ext"

        Copy-Item -LiteralPath $Path -Destination $backupPath -Force
        Write-Host "Backup created: $backupPath"
    }
}

function Get-ImageKind {
    param([Parameter(Mandatory=$true)][string]$FileName)

    if ($FileName -match '(?i)\bcard\b') {
        return 'Card'
    }

    if ($FileName -match '(?i)\bORIGINAL\b|\borig\b|\boriginal\b') {
        return 'Original'
    }

    return 'Digitized'
}

function Get-BaseTitleFromFileName {
    param([Parameter(Mandatory=$true)][string]$FileName)

    $name = [System.IO.Path]::GetFileNameWithoutExtension($FileName)
    $s = $name.Trim()

    # Normalize filename-only artifacts without changing the real filename.
    $s = $s -replace '_', ' '
    $s = $s -replace '\+', ' '
    $s = $s -replace '(?i)\s+COPY$', ''
    $s = $s -replace '(?i)\s+copy$', ''
    $s = $s -replace '\s+\(\d+\)$', ''
    $s = $s -replace '(?i)\s+card\s*\d*$', ''
    $s = $s -replace '(?i)\s+raw file$', ''

    $changed = $true
    while ($changed) {
        $before = $s

        # Remove image-state descriptors.
        $s = $s -replace '(?i)\s+B&W-\d+$', ''
        $s = $s -replace '(?i)\s+B&W\s+\d+$', ''
        $s = $s -replace '(?i)\s+B&W$', ''
        $s = $s -replace '(?i)\s+b&w$', ''
        $s = $s -replace '(?i)\s+BW$', ''

        $s = $s -replace '(?i)\s+COLORWAY\s+\d+$', ''
        $s = $s -replace '(?i)\s+colorway\s+\d+$', ''
        $s = $s -replace '(?i)\s+COLORWAY$', ''
        $s = $s -replace '(?i)\s+colorway$', ''
        $s = $s -replace '(?i)\s+COLOR-\d+$', ''
        $s = $s -replace '(?i)\s+COLOR\s+\d+$', ''
        $s = $s -replace '(?i)\s+COLOR$', ''

        $s = $s -replace '(?i)\s+ORIGINAL\s+COLOR-\d+(?:-\d+)?$', ''
        $s = $s -replace '(?i)\s+ORIGINAL\s+COLOR\s+\d+$', ''
        $s = $s -replace '(?i)\s+ORIGINAL\s+COLOR$', ''
        $s = $s -replace '(?i)\s+ORIGINAL-\d+(?:-\d+)?$', ''
        $s = $s -replace '(?i)\s+ORIGINAL\s+\d+$', ''
        $s = $s -replace '(?i)\s+ORIGINAL$', ''
        $s = $s -replace '(?i)\s+original$', ''
        $s = $s -replace '(?i)\s+orig$', ''

        # Remove view / pose descriptors.
        $s = $s -replace '(?i)\s+front view$', ''
        $s = $s -replace '(?i)\s+side view$', ''
        $s = $s -replace '(?i)\s+right side$', ''
        $s = $s -replace '(?i)\s+left side$', ''
        $s = $s -replace '(?i)\s+three quarters$', ''
        $s = $s -replace '(?i)\s+portrait$', ''
        $s = $s -replace '(?i)\s+front$', ''
        $s = $s -replace '(?i)\s+back$', ''
        $s = $s -replace '(?i)\s+bottom$', ''
        $s = $s -replace '(?i)\s+top$', ''
        $s = $s -replace '(?i)\s+side$', ''
        $s = $s -replace '(?i)\s+wing$', ''
        $s = $s -replace '(?i)\s+with jaw$', ''
        $s = $s -replace '(?i)\s+no jaw$', ''
        $s = $s -replace '(?i)\s+body$', ''
        $s = $s -replace '(?i)\s+drawing$', ''

        # Remove trailing duplicate/version numbers.
        $s = $s -replace '(?i)\s+R\d+$', ''
        $s = $s -replace '(?i)\s+v\d+$', ''
        $s = $s -replace '(?i)\s+AI FILE$', ''
        $s = $s -replace '(?i)\s+version\s+\d+$', ''
        $s = $s -replace '(?i)\s+\d+$', ''

        $s = $s.Trim()
        $changed = ($s -ne $before)
    }

    if ([string]::IsNullOrWhiteSpace($s)) {
        $s = $name
    }

    $s = Split-CamelCaseSafe -Text $s
    $s = $s -replace '\s+', ' '
    return (ConvertTo-TitleCaseSimple -Text $s)
}

function Get-GroupKey {
    param([Parameter(Mandatory=$true)][string]$BaseTitle)

    $key = $BaseTitle.ToLowerInvariant()
    $key = $key -replace '&', ' and '
    $key = $key -replace "['’\.]", ''
    $key = $key -replace '[^a-z0-9]+', ' '
    $key = $key.Trim()
    return $key
}

function Get-ImageFilesInFolder {
    param([Parameter(Mandatory=$true)][string]$Folder)

    return @(Get-ChildItem -LiteralPath $Folder -File | Where-Object {
        $AllowedExtensions -contains $_.Extension.ToLowerInvariant()
    } | Sort-Object Name)
}

function Get-GroupsForImageFolder {
    param([Parameter(Mandatory=$true)][string]$Folder)

    $files = @(Get-ImageFilesInFolder -Folder $Folder)
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
    param([Parameter(Mandatory=$true)][System.IO.FileInfo[]]$Files)

    $nonCards = @($Files | Where-Object { $_.Name -notmatch '(?i)\bcard\b' })
    if ($nonCards.Count -eq 0) { $nonCards = @($Files) }

    $rules = @(
        { param($f) $f.Name -match '(?i)\bCOLOR\b' -and $f.Name -notmatch '(?i)\b(side|back|tail|rear|bottom|top)\b' -and $f.Name -notmatch '(?i)colorway' },
        { param($f) $f.Name -match '(?i)\bORIGINAL COLOR\b' -and $f.Name -notmatch '(?i)\b(side|back|tail|rear|bottom|top)\b' },
        { param($f) $f.Name -match '(?i)\bORIGINAL\b|\borig\b' -and $f.Name -notmatch '(?i)\b(side|back|tail|rear|bottom|top)\b' },
        { param($f) $f.Name -match '(?i)\bCOLOR\b' },
        { param($f) $f.Name -match '(?i)\bB&W\b' },
        { param($f) $true }
    )

    foreach ($rule in $rules) {
        $candidate = @($nonCards | Where-Object { & $rule $_ } | Sort-Object Name | Select-Object -First 1)
        if ($candidate.Count -gt 0) { return $candidate[0] }
    }

    return ($Files | Sort-Object Name | Select-Object -First 1)
}

function Select-ThumbFileFromFolder {
    param([Parameter(Mandatory=$true)][string]$Folder)

    $files = @(Get-ImageFilesInFolder -Folder $Folder)
    if ($files.Count -eq 0) { return $null }
    return Select-ThumbFile -Files $files
}

function New-FigureHtml {
    param(
        [Parameter(Mandatory=$true)][System.IO.FileInfo]$File,
        [Parameter(Mandatory=$true)][string]$AltText,
        [Parameter(Mandatory=$true)][string]$HtmlFolder
    )

    $src = New-WebImagePath -HtmlFolder $HtmlFolder -File $File
    $safeAlt = Html-Encode $AltText

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
            <img src="$src" alt="$safeAlt" loading="lazy" />
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
    .section-card h2{ margin:0 0 14px; font-size:1.4rem; text-align:center; }
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

function New-BreadcrumbHtml {
    param([Parameter(Mandatory=$true)][string]$CurrentHtmlFolder)

    if ($CurrentHtmlFolder -eq $HtmlRoot) {
@"
      <a class="nav-pill" href="https://ronenglish-archive.github.io/ron-english-catalogue-raisonne/">Catalogue home</a>
      <a class="nav-pill" href="../index.html">Sketches</a>
      <a class="nav-pill" href="index.html">Skeletons</a>
"@
    }
    else {
@"
      <a class="nav-pill" href="https://ronenglish-archive.github.io/ron-english-catalogue-raisonne/">Catalogue home</a>
      <a class="nav-pill" href="../../index.html">Sketches</a>
      <a class="nav-pill" href="../index.html">Skeletons</a>
"@
    }
}

function New-SectionHtml {
    param(
        [Parameter(Mandatory=$true)][string]$SectionId,
        [Parameter(Mandatory=$true)][string]$Title,
        [Parameter(Mandatory=$true)][string]$GridClass,
        [Parameter(Mandatory=$true)][string[]]$Figures
    )

    if ($Figures.Count -eq 0) { return '' }

    $safeTitle = Html-Encode $Title
    $figuresHtml = $Figures -join "`r`n"

@"

    <section class="section-card" aria-labelledby="$SectionId">
      <h2 id="$SectionId">$safeTitle</h2>
      <div class="$GridClass">
$figuresHtml
      </div>
    </section>
"@
}

function Build-IndividualPage {
    param([Parameter(Mandatory=$true)][pscustomobject]$Group)

    $htmlFolder = Join-Path $HtmlRoot $Group.Slug
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
            $figures += New-FigureHtml -File $file -AltText "$($Group.Title) original drawing by Ron English" -HtmlFolder $htmlFolder
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
            $figures += New-FigureHtml -File $file -AltText "$($Group.Title) digitized version by Ron English" -HtmlFolder $htmlFolder
        }
        $sections += New-SectionHtml -SectionId 'digitized-versions' -Title 'Digitized Versions' -GridClass 'gallery-grid' -Figures $figures
    }

    if ($cardFiles.Count -gt 0) {
        $figures = @()
        foreach ($file in $cardFiles) {
            $figures += New-FigureHtml -File $file -AltText "$($Group.Title) collector card by Ron English" -HtmlFolder $htmlFolder
        }
        $sections += New-SectionHtml -SectionId 'collector-cards' -Title 'Collector Cards' -GridClass 'card-grid' -Figures $figures
    }

    $sectionsHtml = $sections -join ''
    $css = Get-SharedCss
    $safeTitle = Html-Encode $Group.Title
    $breadcrumbs = New-BreadcrumbHtml -CurrentHtmlFolder $htmlFolder

    $html = @"
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>$safeTitle | Skeletons | Ron English Catalogue Raisonné</title>

  <link rel="stylesheet" href="../../css/styles.css" />

$css
</head>
<body>
  <main class="wrap page-narrow">
    <nav class="nav-pills" aria-label="Site navigation">
$breadcrumbs
    </nav>

    <header class="page-header">
      <h1 class="page-title">$safeTitle</h1>
    </header>$sectionsHtml

    <div class="back-link">
      <a href="../index.html">&larr; Back to Skeletons</a>
    </div>

    <footer>
      Published via GitHub Pages for long-term public access.
    </footer>
  </main>
</body>
</html>
"@

    [System.IO.File]::WriteAllText($htmlPath, $html, $Utf8NoBom)
    Write-Host "Built: $htmlPath"
}

function New-GroupCard {
    param([Parameter(Mandatory=$true)][pscustomobject]$Group)

    $thumb = Select-ThumbFile -Files $Group.Files
    $src = New-WebImagePath -HtmlFolder $HtmlRoot -File $thumb
    $safeTitle = Html-Encode $Group.Title

@"
      <a class="gallery-item" href="$($Group.Slug)/index.html">
        <img src="$src" alt="$safeTitle drawings by Ron English" loading="lazy" />
        <div class="entry-body">
          <p class="work-title">$safeTitle</p>
        </div>
      </a>
"@
}

function Build-CategoryIndex {
    $indexPath = Join-Path $HtmlRoot 'index.html'

    if (-not (Test-Path -LiteralPath $HtmlRoot)) {
        New-Item -ItemType Directory -Path $HtmlRoot -Force | Out-Null
    }

    Backup-FileIfExists -Path $indexPath

    $groups = @(Get-GroupsForImageFolder -Folder $ImageRoot)
    $cards = @()

    foreach ($group in $groups) {
        Build-IndividualPage -Group $group
        $cards += New-GroupCard -Group $group
    }

    $cardsHtml = $cards -join "`r`n"
    $css = Get-SharedCss
    $breadcrumbs = New-BreadcrumbHtml -CurrentHtmlFolder $HtmlRoot

    $html = @"
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Skeletons | Sketches &amp; Drawings | Ron English Catalogue Raisonné</title>

  <link rel="stylesheet" href="../css/styles.css" />

$css
</head>
<body>
  <main class="wrap page-narrow">
    <nav class="nav-pills" aria-label="Site navigation">
$breadcrumbs
    </nav>

    <header class="page-header">
      <h1 class="page-title">Skeletons</h1>
    </header>

    <section class="index-grid" aria-label="Skeletons sketch and drawing pages">
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

    [System.IO.File]::WriteAllText($indexPath, $html, $Utf8NoBom)
    Write-Host "Built: $indexPath"
}

function Update-MainSketchesIndex {
    if (-not (Test-Path -LiteralPath $SketchesIndexPath)) {
        Write-Warning "Main Sketches index not found, skipping main index update: $SketchesIndexPath"
        return
    }

    $heroFile = $null
    $preferred = @(
        'Starskull Skeleton COLOR.jpg',
        'Star Skull Creature front COLOR.jpg',
        'Heart Skull ORIGINAL.jpg',
        'Lotus Skull ORIGINAL COLOR RED.jpg',
        'Skeleton Heart COLOR.jpg',
        'Mickey Skeleton COLOR.jpg',
        'Yinyang Skeleton COLOR.jpg'
    )

    foreach ($name in $preferred) {
        $candidate = Join-Path $ImageRoot $name
        if (Test-Path -LiteralPath $candidate) {
            $heroFile = Get-Item -LiteralPath $candidate
            break
        }
    }

    if ($null -eq $heroFile) {
        $heroFile = Select-ThumbFileFromFolder -Folder $ImageRoot
    }

    if ($null -eq $heroFile) {
        Write-Warning "Could not find a hero image for the Skeletons card on Sketches index."
        return
    }

    Backup-FileIfExists -Path $SketchesIndexPath

    $html = [System.IO.File]::ReadAllText($SketchesIndexPath)
    $originalHtml = $html

    $heroRel = Get-EncodedRelativeImagePath -File $heroFile
    $heroSrc = "../images/Sketches/$heroRel"

    $newCard = @"
      <a class="gallery-item" href="skeletons/index.html">
        <img src="$heroSrc" alt="Skeletons drawings by Ron English" loading="lazy" />
        <div class="entry-body">
          <p class="work-title">Skeletons</p>
        </div>
      </a>
"@

    $cardPattern = '(?is)<a\b(?=[^>]*\bclass="[^"]*\bgallery-item\b[^"]*")[^>]*href="skeletons/index\.html"[^>]*>.*?</a>'

    if ($html -match $cardPattern) {
        $html = [regex]::Replace($html, $cardPattern, $newCard, 1)
        Write-Host "Updated existing Skeletons card on Sketches index."
    }
    elseif ($html -match '(?is)(<section\b[^>]*class="[^"]*(?:index-grid|gallery-grid)[^"]*"[^>]*>)(.*?)(</section>)') {
        $html = [regex]::Replace($html, '(?is)(<section\b[^>]*class="[^"]*(?:index-grid|gallery-grid)[^"]*"[^>]*>)(.*?)(</section>)', {
            param($m)
            return $m.Groups[1].Value + $m.Groups[2].Value + "`r`n" + $newCard + "`r`n" + $m.Groups[3].Value
        }, 1)
        Write-Host "Added Skeletons card to Sketches index."
    }
    else {
        Write-Warning "Could not find an index/gallery grid on Sketches index. Skeletons page was built, but the main Sketches index was not updated."
    }

    if ($html -ne $originalHtml) {
        [System.IO.File]::WriteAllText($SketchesIndexPath, $html, $Utf8NoBom)
    }
}

if (-not (Test-Path -LiteralPath $ImageRoot)) {
    throw "Image folder not found: $ImageRoot"
}

Build-CategoryIndex
Update-MainSketchesIndex

Write-Host ""
Write-Host "Done. Skeletons category built."
Write-Host "Check:"
Write-Host "  D:\github\ron-english-sketches-and-drawings\Sketches\skeletons\index.html"
Write-Host ""
Write-Host "Then click several individual Skeletons pages to check images and titles."
