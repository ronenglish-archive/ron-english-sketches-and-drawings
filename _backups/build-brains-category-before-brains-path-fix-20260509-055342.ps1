[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$RepoRoot = 'D:\github\ron-english-sketches-and-drawings'

$ImageFolder = Join-Path $RepoRoot 'images\Sketches\brains'
$HtmlRoot = Join-Path $RepoRoot 'Sketches\brains'
$SketchesIndexPath = Join-Path $RepoRoot 'Sketches\index.html'

$GroupDefinitions = @(
    [pscustomobject]@{ Title='Bipolar Pal'; Slug='bipolar-pal'; Pattern='(?i)^Bipolar Pal\b' },
    [pscustomobject]@{ Title='Body and Mind'; Slug='body-and-mind'; Pattern='(?i)^Body and Mind\b' },
    [pscustomobject]@{ Title='Brain Boxing Glove'; Slug='brain-boxing-glove'; Pattern='(?i)^Brain Boxing Glove\b' },
    [pscustomobject]@{ Title='Brain Boy'; Slug='brain-boy'; Pattern='(?i)^Brain Boy\b' },
    [pscustomobject]@{ Title='Brain Fire Flower'; Slug='brain-fire-flower'; Pattern='(?i)^(Brain Fire Flower|Brain Flower)\b' },
    [pscustomobject]@{ Title='Brain Halves'; Slug='brain-halves'; Pattern='(?i)^Brain Halves\b' },
    [pscustomobject]@{ Title='Brain Heart'; Slug='brain-heart'; Pattern='(?i)^(Brain Heart|Brainheart)\b' },
    [pscustomobject]@{ Title='Brain Lightning'; Slug='brain-lightning'; Pattern='(?i)^Brain\s+Lightning\b' },
    [pscustomobject]@{ Title='Brain Maze'; Slug='brain-maze'; Pattern='(?i)^Brain Maze\b' },
    [pscustomobject]@{ Title='Brain Smoke (Bomb Brain)'; Slug='brain-smoke-bomb-brain'; Pattern='(?i)^Brain Smoke \(Bomb Brain\)\b' },
    [pscustomobject]@{ Title='Brain Thinker'; Slug='brain-thinker'; Pattern='(?i)^Brain Thinker\b' },
    [pscustomobject]@{ Title='Brain Tree'; Slug='brain-tree'; Pattern='(?i)^Brain Tree\b' },
    [pscustomobject]@{ Title='Brain Wave Surfer'; Slug='brain-wave-surfer'; Pattern='(?i)^Brain Wave Surfer\b' },
    [pscustomobject]@{ Title='Captain Curious'; Slug='captain-curious'; Pattern='(?i)^Captain Curious\b' },
    [pscustomobject]@{ Title='Elephant Brain'; Slug='elephant-brain'; Pattern='(?i)^Elephant Brain\b' },
    [pscustomobject]@{ Title='Paisley Brain'; Slug='paisley-brain'; Pattern='(?i)^Paisley Brain\b' },
    [pscustomobject]@{ Title='Peace & Love'; Slug='peace-and-love'; Pattern='(?i)^Peace & Love\b' },
    [pscustomobject]@{ Title='Peace of Mind'; Slug='peace-of-mind'; Pattern='(?i)^Peace of Mind\b' },
    [pscustomobject]@{ Title="Ron's Brain"; Slug='rons-brain'; Pattern="(?i)^Ron's Brain\b" },
    [pscustomobject]@{ Title='Sex Brain'; Slug='sex-brain'; Pattern='(?i)^Sex Brain\b' },
    [pscustomobject]@{ Title='Sin of Consciousness'; Slug='sin-of-consciousness'; Pattern='(?i)^Sin of Consciousness\b' },
    [pscustomobject]@{ Title='Stellabolt Cerebella'; Slug='stellabolt-cerebella'; Pattern='(?i)^Stellabolt Cerebella\b' },
    [pscustomobject]@{ Title='Thinker on the Church Throne'; Slug='thinker-on-the-church-throne'; Pattern='(?i)^Thinker on the Church Throne\b' },
    [pscustomobject]@{ Title='Voodoo Painting'; Slug='voodoo-painting'; Pattern='(?i)^Voodoo Painting\b' },
    [pscustomobject]@{ Title='Yinyang Brain'; Slug='yinyang-brain'; Pattern='(?i)^Yinyang Brain\b' }
)

function Encode-Part {
    param([AllowEmptyString()][string]$Text)
    if ([string]::IsNullOrEmpty($Text)) { return $Text }
    return [System.Uri]::EscapeDataString($Text)
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
        $backupPath = Join-Path $backupDir "$name-before-brains-build-$timestamp$ext"
        Copy-Item -LiteralPath $Path -Destination $backupPath -Force
        Write-Host "Backup created: $backupPath"
    }
}

function Get-ImageKind {
    param([Parameter(Mandatory=$true)][string]$FileName)
    if ($FileName -match '(?i)\bcard\b') { return 'Card' }
    if ($FileName -match '(?i)ORIGINAL|original') { return 'Original' }
    return 'Digitized'
}

function New-ImageSrc {
    param(
        [Parameter(Mandatory=$true)][string]$Prefix,
        [Parameter(Mandatory=$true)][string]$FileName
    )
    return "$Prefix/$(Encode-Part $FileName)"
}

function Select-ThumbFile {
    param([Parameter(Mandatory=$true)][System.IO.FileInfo[]]$Files)

    $nonCards = @($Files | Where-Object { $_.Name -notmatch '(?i)\bcard\b' })
    $rules = @(
        { param($f) $f.Name -match '(?i)\bCOLOR\b' -and $f.Name -notmatch '(?i)\b(side|back|tail)\b' -and $f.Name -notmatch '(?i)colorway' },
        { param($f) $f.Name -match '(?i)ORIGINAL COLOR|original color' -and $f.Name -notmatch '(?i)\b(side|back|tail)\b' },
        { param($f) $f.Name -match '(?i)ORIGINAL|original' -and $f.Name -notmatch '(?i)\b(side|back|tail)\b' },
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

function New-FigureHtml {
    param(
        [Parameter(Mandatory=$true)][System.IO.FileInfo]$File,
        [Parameter(Mandatory=$true)][string]$AltText,
        [Parameter(Mandatory=$true)][string]$ImagePrefix
    )
    $src = New-ImageSrc -Prefix $ImagePrefix -FileName $File.Name
@"
        <figure class="gallery-item">
          <a href="$src" target="_blank" rel="noopener noreferrer">
            <img src="$src" alt="$AltText" loading="lazy" />
          </a>
        </figure>
"@
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
    if ($Figures.Count -eq 0) { return '' }
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
    param([Parameter(Mandatory=$true)][pscustomobject]$Group)

    $htmlFolder = Join-Path $HtmlRoot $Group.Slug
    $htmlPath = Join-Path $htmlFolder 'index.html'
    if (-not (Test-Path -LiteralPath $htmlFolder)) { New-Item -ItemType Directory -Path $htmlFolder -Force | Out-Null }
    Backup-FileIfExists -Path $htmlPath

    $originalFiles = @($Group.Files | Where-Object { (Get-ImageKind $_.Name) -eq 'Original' } | Sort-Object Name)
    $digitizedFiles = @($Group.Files | Where-Object { (Get-ImageKind $_.Name) -eq 'Digitized' } | Sort-Object Name)
    $cardFiles = @($Group.Files | Where-Object { (Get-ImageKind $_.Name) -eq 'Card' } | Sort-Object Name)

    $sections = @()
    if ($originalFiles.Count -gt 0) {
        $figures = @()
        foreach ($file in $originalFiles) { $figures += New-FigureHtml -File $file -AltText "$($Group.Title) original drawing by Ron English" -ImagePrefix '../../images/Sketches/brains' }
        $title = if ($originalFiles.Count -gt 1) { 'Original Drawings' } else { 'Original Drawing' }
        $sections += New-SectionHtml -SectionId 'original-drawing' -Title $title -GridClass 'originals-grid' -Figures $figures
    } else {
        $sections += @"

    <section class="section-card" aria-labelledby="original-drawing">
      <h2 id="original-drawing">Original Drawing</h2>
      <p class="section-intro">No original drawing is currently documented on this page. If one is located, it will be added here.</p>
    </section>
"@
    }
    if ($digitizedFiles.Count -gt 0) {
        $figures = @()
        foreach ($file in $digitizedFiles) { $figures += New-FigureHtml -File $file -AltText "$($Group.Title) digitized version by Ron English" -ImagePrefix '../../images/Sketches/brains' }
        $sections += New-SectionHtml -SectionId 'digitized-versions' -Title 'Digitized Versions' -GridClass 'gallery-grid' -Figures $figures
    }
    if ($cardFiles.Count -gt 0) {
        $figures = @()
        foreach ($file in $cardFiles) { $figures += New-FigureHtml -File $file -AltText "$($Group.Title) collector card by Ron English" -ImagePrefix '../../images/Sketches/brains' }
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
  <title>$($Group.Title) | Brains | Ron English Catalogue Raisonné</title>

  <link rel="stylesheet" href="../../css/styles.css" />

$css
</head>
<body>
  <main class="wrap page-narrow">
    <nav class="nav-pills" aria-label="Site navigation">
      <a class="nav-pill" href="https://ronenglish-archive.github.io/ron-english-catalogue-raisonne/">Catalogue home</a>
      <a class="nav-pill" href="../index.html">Sketches</a>
      <a class="nav-pill" href="index.html">Brains</a>
    </nav>

    <header class="page-header">
      <h1 class="page-title">$($Group.Title)</h1>
    </header>$sectionsHtml

    <div class="back-link">
      <a href="index.html">&larr; Back to Brains</a>
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

function Build-BrainsIndex {
    param([Parameter(Mandatory=$true)][object[]]$Groups)
    $htmlPath = Join-Path $HtmlRoot 'index.html'
    Backup-FileIfExists -Path $htmlPath
    $cards = @()
    foreach ($group in ($Groups | Sort-Object Title)) {
        $thumb = Select-ThumbFile -Files $group.Files
        $src = New-ImageSrc -Prefix '../images/Sketches/brains' -FileName $thumb.Name
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
  <title>Brains | Sketches &amp; Drawings | Ron English Catalogue Raisonné</title>

  <link rel="stylesheet" href="../css/styles.css" />

$css
</head>
<body>
  <main class="wrap page-narrow">
    <nav class="nav-pills" aria-label="Site navigation">
      <a class="nav-pill" href="https://ronenglish-archive.github.io/ron-english-catalogue-raisonne/">Catalogue home</a>
      <a class="nav-pill" href="../index.html">Sketches</a>
    </nav>

    <header class="page-header">
      <h1 class="page-title">Brains</h1>
    </header>

    <section class="index-grid" aria-label="Brains sketch and drawing pages">
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
    param([Parameter(Mandatory=$true)][object[]]$Groups)
    if (-not (Test-Path -LiteralPath $SketchesIndexPath)) {
        Write-Warning "Main Sketches index not found, skipping main index update: $SketchesIndexPath"
        return
    }
    $heroFile = $null
    foreach ($name in @('Brainheart ORIGINAL.jpg','Brain Tree ORIGINAL.jpg','Brain Tree COLOR.jpg')) {
        $candidate = Join-Path $ImageFolder $name
        if (Test-Path -LiteralPath $candidate) { $heroFile = Get-Item -LiteralPath $candidate; break }
    }
    if ($null -eq $heroFile) { $heroFile = Select-ThumbFile -Files (($Groups | Select-Object -First 1).Files) }
    $heroSrc = '../images/Sketches/brains/' + (Encode-Part $heroFile.Name)
    Backup-FileIfExists -Path $SketchesIndexPath
    $html = [System.IO.File]::ReadAllText($SketchesIndexPath)
    $originalHtml = $html
    $newCard = @"
      <a class="gallery-item" href="brains/index.html">
        <img src="$heroSrc" alt="Brains drawings by Ron English" loading="lazy" />
        <div class="entry-body">
          <p class="work-title">Brains</p>
        </div>
      </a>
"@
    $cardPattern = '(?is)<a\b(?=[^>]*\bclass="[^"]*\bgallery-item\b[^"]*")[^>]*href="brains/index\.html"[^>]*>.*?</a>'
    if ($html -match $cardPattern) {
        $html = [regex]::Replace($html, $cardPattern, $newCard, 1)
        Write-Host 'Updated existing Brains card on Sketches index.'
    } elseif ($html -match '(?is)(<section\b[^>]*class="[^"]*(?:index-grid|gallery-grid)[^"]*"[^>]*>)(.*?)(</section>)') {
        $html = [regex]::Replace($html, '(?is)(<section\b[^>]*class="[^"]*(?:index-grid|gallery-grid)[^"]*"[^>]*>)(.*?)(</section>)', {
            param($m)
            return $m.Groups[1].Value + $m.Groups[2].Value + "`r`n" + $newCard + "`r`n" + $m.Groups[3].Value
        }, 1)
        Write-Host 'Added Brains card to Sketches index.'
    } else {
        Write-Warning 'Could not find an index/gallery grid on Sketches index. Brains category page was built, but main index was not updated.'
    }
    if ($html -ne $originalHtml) { [System.IO.File]::WriteAllText($SketchesIndexPath, $html, [System.Text.UTF8Encoding]::new($false)) }
}

if (-not (Test-Path -LiteralPath $ImageFolder)) { throw "Image folder not found: $ImageFolder" }
if (-not (Test-Path -LiteralPath $HtmlRoot)) { New-Item -ItemType Directory -Path $HtmlRoot -Force | Out-Null }

$allFiles = @(Get-ChildItem -LiteralPath $ImageFolder -File | Where-Object { $_.Extension -match '^\.(jpg|jpeg|png|webp|gif|avif|tif|tiff)$' } | Sort-Object Name)
if ($allFiles.Count -eq 0) { throw "No image files found in: $ImageFolder" }

$groups = @()
$assignedPaths = New-Object 'System.Collections.Generic.HashSet[string]'
foreach ($definition in $GroupDefinitions) {
    $files = @($allFiles | Where-Object { $_.Name -match $definition.Pattern } | Sort-Object Name)
    if ($files.Count -gt 0) {
        foreach ($file in $files) { [void]$assignedPaths.Add($file.FullName) }
        $groups += [pscustomobject]@{ Title=$definition.Title; Slug=$definition.Slug; Files=$files }
    }
}
$unassigned = @($allFiles | Where-Object { -not $assignedPaths.Contains($_.FullName) })
if ($unassigned.Count -gt 0) {
    Write-Warning 'Some files were not matched to a group and were not used:'
    foreach ($file in $unassigned) { Write-Warning "  $($file.Name)" }
}

Build-BrainsIndex -Groups $groups
foreach ($group in $groups) { Build-IndividualPage -Group $group }
Update-MainSketchesIndex -Groups $groups

Write-Host ''
Write-Host 'Done. Brains category built.'
Write-Host 'Check:'
Write-Host '  D:\github\ron-english-sketches-and-drawings\Sketches\brains\index.html'
Write-Host 'Then click several Brains cards to check individual pages.'
Write-Host ''
Write-Host 'The script also tried to add/update the Brains card on:'
Write-Host '  D:\github\ron-english-sketches-and-drawings\Sketches\index.html'
