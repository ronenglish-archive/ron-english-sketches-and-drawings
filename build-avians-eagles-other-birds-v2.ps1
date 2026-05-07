# build-avians-eagles-other-birds-v2.ps1
# Ron English Sketches and Drawings Catalogue
# V2 update:
# - Pages with no original drawing now use the standard Original Drawing section:
#   "No original drawing is currently documented on this page. If one is located, it will be added here."
# - The no-original statement is no longer placed under Cataloguing Notes.
#
# Builds:
# - Sketches\avians\index.html
# - Sketches\avians\eagles\index.html
# - Sketches\avians\eagles\eagle-head.html
# - Sketches\avians\eagles\eagle-weed.html
# - Sketches\avians\eagles\lightning-bird.html
# - Sketches\avians\other birds\index.html
# - Sketches\avians\other birds\bird.html
# - Sketches\avians\other birds\bird-beak.html
# - Sketches\avians\other birds\staples-pigeon.html
#
# Safe behavior:
# - Preserves exact image filenames.
# - Checks required image files before writing pages.
# - Backs up existing HTML files before overwriting.
# - Auto-detects whether category images are in images\Sketches\avians\eagles,
#   images\Sketches\avians\other birds, or directly in images\Sketches\avians.

$ErrorActionPreference = 'Stop'

$RepoRoot = 'D:\github\ron-english-sketches-and-drawings'

$AviansImageRoot = Join-Path $RepoRoot 'images\Sketches\avians'
$AviansHtmlRoot  = Join-Path $RepoRoot 'Sketches\avians'

$EaglesHtmlDir = Join-Path $AviansHtmlRoot 'eagles'
$OtherBirdsHtmlDir = Join-Path $AviansHtmlRoot 'other birds'

$ReportDir = Join-Path $AviansHtmlRoot '_reports'

$NoOriginalText = 'No original drawing is currently documented on this page. If one is located, it will be added here.'

$HeroFiles = @{
  Ducks = 'Duck HERO.png'
  Eagles = 'Eagle HERO.png'
  OtherBirds = 'Other Birds HERO.png'
}

$EaglePages = @(
  @{
    Title = 'Eagle Head'
    Slug = 'eagle-head.html'
    Thumb = 'Eagle Head COLOR digital.png'
    Originals = @(
      @{
        File = 'Eagle Head ORIGINAL.jpg'
        Label = 'Original drawing'
        Alt = 'Eagle Head original drawing by Ron English'
      }
    )
    Digitals = @(
      @{
        File = 'Eagle Head B&W digital.jpeg'
        Label = 'B and W digital version'
        Alt = 'Eagle Head black-and-white digital version by Ron English'
      },
      @{
        File = 'Eagle Head COLOR digital.png'
        Label = 'Color digital version'
        Alt = 'Eagle Head color digital version by Ron English'
      }
    )
    Notes = @()
  },
  @{
    Title = 'Eagle Weed'
    Slug = 'eagle-weed.html'
    Thumb = 'Eagle Weed COLOR digital.jpg'
    Originals = @()
    Digitals = @(
      @{
        File = 'Eagle Weed COLOR digital.jpg'
        Label = 'Color digital version'
        Alt = 'Eagle Weed color digital version by Ron English'
      }
    )
    Notes = @()
  },
  @{
    Title = 'Lightning Bird'
    Slug = 'lightning-bird.html'
    Thumb = 'Lightning Bird COLOR digital.jpg'
    Originals = @()
    Digitals = @(
      @{
        File = 'Lightning Bird COLOR digital.jpg'
        Label = 'Color digital version'
        Alt = 'Lightning Bird color digital version by Ron English'
      }
    )
    Notes = @()
  }
)

$OtherBirdPages = @(
  @{
    Title = 'Bird'
    Slug = 'bird.html'
    Thumb = 'Bird B&W digital.png'
    Originals = @(
      @{
        File = 'Bird ORIGINAL.jpeg'
        Label = 'Original drawing'
        Alt = 'Bird original drawing by Ron English'
      }
    )
    Digitals = @(
      @{
        File = 'Bird B&W digital.png'
        Label = 'B and W digital version'
        Alt = 'Bird black-and-white digital version by Ron English'
      }
    )
    Notes = @()
  },
  @{
    Title = 'Bird Beak'
    Slug = 'bird-beak.html'
    Thumb = 'Bird Beak COLOR digital.png'
    Originals = @()
    Digitals = @(
      @{
        File = 'Bird Beak B&W digital.png'
        Label = 'B and W digital version'
        Alt = 'Bird Beak black-and-white digital version by Ron English'
      },
      @{
        File = 'Bird Beak COLOR digital.png'
        Label = 'Color digital version'
        Alt = 'Bird Beak color digital version by Ron English'
      }
    )
    Notes = @()
  },
  @{
    Title = 'Staples Pigeon'
    Slug = 'staples-pigeon.html'
    Thumb = 'Staples Pigeon ORIGINAL.jpg'
    Originals = @(
      @{
        File = 'Staples Pigeon ORIGINAL.jpg'
        Label = 'Original drawing'
        Alt = 'Staples Pigeon original drawing by Ron English'
      }
    )
    Digitals = @()
    Notes = @()
  }
)

function HtmlEncode {
  param([AllowNull()][string]$Text)
  if ($null -eq $Text) { return '' }
  return [System.Net.WebUtility]::HtmlEncode($Text)
}

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
    $backupPath = "$Path.bak-$stamp"
    Copy-Item -Path $Path -Destination $backupPath -Force
    Write-Host "Backed up existing file: $backupPath"
  }
}

function Find-ImageFile {
  param(
    [string]$PreferredFolder,
    [string]$FileName
  )

  $candidateOne = Join-Path $PreferredFolder $FileName
  if (Test-Path $candidateOne) {
    return $candidateOne
  }

  $candidateTwo = Join-Path $AviansImageRoot $FileName
  if (Test-Path $candidateTwo) {
    return $candidateTwo
  }

  return $null
}

function Convert-ToWebPath {
  param(
    [string]$FromHtmlDir,
    [string]$FullImagePath
  )

  $fromUri = New-Object System.Uri(($FromHtmlDir.TrimEnd('\') + '\'))
  $toUri = New-Object System.Uri($FullImagePath)
  $relative = $fromUri.MakeRelativeUri($toUri).ToString()
  $relative = [System.Uri]::UnescapeDataString($relative)
  return $relative -replace '\\','/'
}

function Build-ImageLookup {
  param(
    [array]$Pages,
    [string]$PreferredFolder
  )

  $lookup = @{}
  foreach ($page in $Pages) {
    $allFiles = New-Object System.Collections.Generic.List[string]
    $allFiles.Add($page.Thumb)
    foreach ($item in $page.Originals) { $allFiles.Add($item.File) }
    foreach ($item in $page.Digitals) { $allFiles.Add($item.File) }

    $uniqueFiles = $allFiles | Sort-Object -Unique
    foreach ($file in $uniqueFiles) {
      if (!$lookup.ContainsKey($file)) {
        $found = Find-ImageFile -PreferredFolder $PreferredFolder -FileName $file
        if ($null -ne $found) {
          $lookup[$file] = $found
        }
      }
    }
  }

  return $lookup
}

function Check-RequiredImages {
  param(
    [array]$Pages,
    [string]$PreferredFolder,
    [string]$CategoryName
  )

  $missing = New-Object System.Collections.Generic.List[string]

  foreach ($page in $Pages) {
    $allFiles = New-Object System.Collections.Generic.List[string]
    $allFiles.Add($page.Thumb)
    foreach ($item in $page.Originals) { $allFiles.Add($item.File) }
    foreach ($item in $page.Digitals) { $allFiles.Add($item.File) }

    $uniqueFiles = $allFiles | Sort-Object -Unique
    foreach ($file in $uniqueFiles) {
      $found = Find-ImageFile -PreferredFolder $PreferredFolder -FileName $file
      if ($null -eq $found) {
        $missing.Add("$CategoryName : $file")
      }
    }
  }

  return $missing
}

function Get-SharedHead {
  param(
    [string]$Title,
    [string]$CssPath
  )

  return @"
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>$Title | Ron English Catalogue Raisonne</title>

  <link rel="stylesheet" href="$CssPath" />

  <style>
    :root{
      --border:#e5e7eb;
      --muted:#4b5563;
      --shadow:0 10px 30px rgba(0,0,0,.08);
      --radius:18px;
      --bg:#ffffff;
      --panel:#f3f4f6;
      --card:#ffffff;
      --pill-hover:#f9fafb;
    }

    *{
      box-sizing:border-box;
    }

    html{
      scroll-behavior:smooth;
    }

    body{
      margin:0;
      font-family:system-ui,-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;
      color:#111;
      background:var(--bg);
      padding-left:0;
      padding-right:0;
    }

    .wrap{
      max-width:1240px;
      margin:0 auto;
      padding:28px 18px 60px;
    }

    .page-narrow{
      max-width:1100px;
    }

    .nav-pills{
      display:flex;
      flex-wrap:wrap;
      gap:10px;
      margin-top:22px;
      margin-bottom:22px;
    }

    .nav-pill{
      padding:8px 14px;
      border-radius:999px;
      border:1px solid var(--border);
      background:#fff;
      color:#111;
      text-decoration:none;
      font-size:14px;
      transition:background .12s ease, border-color .12s ease, transform .12s ease;
    }

    .nav-pill:hover{
      background:var(--pill-hover);
      border-color:#d1d5db;
      transform:translateY(-1px);
    }

    .page-header{
      max-width:1100px;
      margin:0 0 28px;
      padding:0;
      text-align:left;
    }

    .page-title{
      margin:0 0 10px;
      font-size:clamp(2rem,4vw,3rem);
      letter-spacing:-.02em;
      line-height:1.05;
    }

    .intro-text{
      max-width:1100px;
      margin:0 0 28px;
      padding:0;
      line-height:1.6;
      text-align:left;
    }

    .intro-text p{
      margin:0 0 14px;
      max-width:none;
      width:100%;
      color:var(--muted);
      font-size:18px;
    }

    .section-card{
      background:#fff;
      border:1px solid var(--border);
      border-radius:var(--radius);
      box-shadow:var(--shadow);
      padding:22px;
      margin-bottom:24px;
    }

    .section-card h2{
      margin:0 0 8px;
      font-size:1.4rem;
    }

    .section-intro{
      margin:0 0 18px;
      color:var(--muted);
      line-height:1.6;
    }

    .gallery-grid{
      margin-top:0;
      display:grid;
      grid-template-columns:repeat(auto-fit,minmax(220px,1fr));
      gap:20px;
    }

    .category-grid{
      margin-top:28px;
      display:grid;
      grid-template-columns:repeat(4,minmax(0,1fr));
      gap:18px;
    }

    .originals-grid{
      display:grid;
      grid-template-columns:repeat(auto-fit,minmax(260px,1fr));
      gap:20px;
    }

    .gallery-item{
      display:block;
      text-decoration:none;
      color:inherit;
      background:#fff;
      border:1px solid var(--border);
      border-radius:var(--radius);
      overflow:hidden;
      box-shadow:var(--shadow);
      transition:transform .12s ease, box-shadow .12s ease, border-color .12s ease;
    }

    .gallery-item:hover{
      transform:translateY(-2px);
      box-shadow:0 16px 40px rgba(0,0,0,.12);
      border-color:#d1d5db;
    }

    .gallery-item img{
      width:100%;
      object-fit:contain;
      display:block;
      background:var(--panel);
      padding:10px;
      border-bottom:1px solid var(--border);
      margin:0;
      border-radius:0;
    }

    .category-grid .gallery-item img{
      height:220px;
    }

    .gallery-grid .gallery-item img{
      height:300px;
    }

    .originals-grid .gallery-item img{
      height:440px;
    }

    .entry-body{
      padding:16px 18px 18px;
      display:flex;
      flex-direction:column;
      align-items:center;
      justify-content:center;
      text-align:center;
    }

    .work-title{
      margin:0;
      padding:0;
      width:100%;
      font-size:18px;
      line-height:1.35;
      font-weight:600;
      text-align:center;
    }

    .work-note{
      margin:6px 0 0;
      padding:0;
      color:var(--muted);
      font-size:14px;
      line-height:1.45;
      text-align:center;
    }

    .note-list{
      margin:0;
      padding-left:1.2rem;
      color:var(--muted);
      line-height:1.6;
    }

    .back-link{
      margin-top:28px;
    }

    .back-link a{
      display:inline-block;
      text-decoration:none;
      color:#111;
      border:1px solid var(--border);
      border-radius:999px;
      padding:10px 16px;
      background:#fff;
    }

    .back-link a:hover{
      background:#f9fafb;
    }

    footer{
      margin-top:34px;
      padding-top:16px;
      border-top:1px solid var(--border);
      color:var(--muted);
      font-size:14px;
    }

    @media (max-width:1100px){
      .category-grid{
        grid-template-columns:repeat(3,minmax(0,1fr));
      }
    }

    @media (max-width:820px){
      .category-grid{
        grid-template-columns:repeat(2,minmax(0,1fr));
      }
    }

    @media (max-width:640px){
      .wrap{
        padding:22px 14px 50px;
      }

      .category-grid,
      .gallery-grid,
      .originals-grid{
        grid-template-columns:1fr;
      }

      .category-grid .gallery-item img{
        height:240px;
      }

      .gallery-grid .gallery-item img{
        height:250px;
      }

      .originals-grid .gallery-item img{
        height:340px;
      }
    }
  </style>
</head>
"@
}

function Add-ImageCard {
  param(
    [System.Text.StringBuilder]$Builder,
    [hashtable]$Item,
    [hashtable]$ImageLookup,
    [string]$HtmlDir
  )

  $full = $ImageLookup[$Item.File]
  $href = Convert-ToWebPath -FromHtmlDir $HtmlDir -FullImagePath $full
  $hrefAttr = HtmlEncode $href
  $alt = HtmlEncode $Item.Alt
  $label = HtmlEncode $Item.Label

  [void]$Builder.AppendLine('        <a class="gallery-item" href="' + $hrefAttr + '" target="_blank" rel="noopener noreferrer">')
  [void]$Builder.AppendLine('          <img src="' + $hrefAttr + '" alt="' + $alt + '" loading="lazy" />')
  [void]$Builder.AppendLine('          <div class="entry-body">')
  [void]$Builder.AppendLine('            <p class="work-note">' + $label + '</p>')
  [void]$Builder.AppendLine('          </div>')
  [void]$Builder.AppendLine('        </a>')
}

function Build-CharacterPage {
  param(
    [hashtable]$Page,
    [string]$CategoryName,
    [string]$CategoryIndexLabel,
    [string]$HtmlDir,
    [hashtable]$ImageLookup
  )

  $title = HtmlEncode $Page.Title
  $cssPath = '../../../css/styles.css'
  $html = New-Object System.Text.StringBuilder

  [void]$html.AppendLine((Get-SharedHead -Title $title -CssPath $cssPath))
  [void]$html.AppendLine('<body>')
  [void]$html.AppendLine('  <main class="wrap page-narrow">')
  [void]$html.AppendLine('    <nav class="nav-pills" aria-label="Site navigation">')
  [void]$html.AppendLine('      <a class="nav-pill" href="https://ronenglish-archive.github.io/ron-english-catalogue-raisonne/">Catalogue home</a>')
  [void]$html.AppendLine('      <a class="nav-pill" href="../../index.html">Sketches</a>')
  [void]$html.AppendLine('      <a class="nav-pill" href="../index.html">Avians</a>')
  [void]$html.AppendLine('      <a class="nav-pill" href="index.html">' + (HtmlEncode $CategoryIndexLabel) + '</a>')
  [void]$html.AppendLine('    </nav>')
  [void]$html.AppendLine('')
  [void]$html.AppendLine('    <header class="page-header">')
  [void]$html.AppendLine('      <h1 class="page-title">' + $title + '</h1>')
  [void]$html.AppendLine('    </header>')
  [void]$html.AppendLine('')

  [void]$html.AppendLine('    <section class="section-card" aria-labelledby="original-drawing">')
  [void]$html.AppendLine('      <h2 id="original-drawing">Original Drawing</h2>')

  if ($Page.Originals.Count -gt 0) {
    [void]$html.AppendLine('')
    [void]$html.AppendLine('      <div class="originals-grid">')

    foreach ($item in $Page.Originals) {
      Add-ImageCard -Builder $html -Item $item -ImageLookup $ImageLookup -HtmlDir $HtmlDir
      [void]$html.AppendLine('')
    }

    [void]$html.AppendLine('      </div>')
  }
  else {
    [void]$html.AppendLine('      <p class="section-intro">' + (HtmlEncode $NoOriginalText) + '</p>')
  }

  [void]$html.AppendLine('    </section>')
  [void]$html.AppendLine('')

  if ($Page.Digitals.Count -gt 0) {
    [void]$html.AppendLine('    <section class="section-card" aria-labelledby="digitized-versions">')
    [void]$html.AppendLine('      <h2 id="digitized-versions">Digitized Versions</h2>')
    [void]$html.AppendLine('')
    [void]$html.AppendLine('      <div class="gallery-grid">')

    foreach ($item in $Page.Digitals) {
      Add-ImageCard -Builder $html -Item $item -ImageLookup $ImageLookup -HtmlDir $HtmlDir
      [void]$html.AppendLine('')
    }

    [void]$html.AppendLine('      </div>')
    [void]$html.AppendLine('    </section>')
    [void]$html.AppendLine('')
  }

  if ($Page.Notes.Count -gt 0) {
    [void]$html.AppendLine('    <section class="section-card" aria-labelledby="notes">')
    [void]$html.AppendLine('      <h2 id="notes">Cataloguing Notes</h2>')
    [void]$html.AppendLine('      <ul class="note-list">')
    foreach ($note in $Page.Notes) {
      [void]$html.AppendLine('        <li>' + (HtmlEncode $note) + '</li>')
    }
    [void]$html.AppendLine('      </ul>')
    [void]$html.AppendLine('    </section>')
    [void]$html.AppendLine('')
  }

  [void]$html.AppendLine('    <div class="back-link">')
  [void]$html.AppendLine('      <a href="index.html">&larr; Back to ' + (HtmlEncode $CategoryIndexLabel) + '</a>')
  [void]$html.AppendLine('    </div>')
  [void]$html.AppendLine('  </main>')
  [void]$html.AppendLine('</body>')
  [void]$html.AppendLine('</html>')

  return $html.ToString()
}

function Build-CategoryIndexPage {
  param(
    [string]$Title,
    [string]$Intro,
    [array]$Pages,
    [string]$HtmlDir,
    [hashtable]$ImageLookup
  )

  $titleEncoded = HtmlEncode $Title
  $html = New-Object System.Text.StringBuilder

  [void]$html.AppendLine((Get-SharedHead -Title ($Title + ' | Sketches and Drawings') -CssPath '../../../css/styles.css'))
  [void]$html.AppendLine('<body>')
  [void]$html.AppendLine('  <main class="wrap">')
  [void]$html.AppendLine('    <nav class="nav-pills" aria-label="Site navigation">')
  [void]$html.AppendLine('      <a class="nav-pill" href="https://ronenglish-archive.github.io/ron-english-catalogue-raisonne/">Catalogue home</a>')
  [void]$html.AppendLine('      <a class="nav-pill" href="../../index.html">Sketches</a>')
  [void]$html.AppendLine('      <a class="nav-pill" href="../index.html">Avians</a>')
  [void]$html.AppendLine('      <a class="nav-pill" href="index.html">' + $titleEncoded + '</a>')
  [void]$html.AppendLine('    </nav>')
  [void]$html.AppendLine('')
  [void]$html.AppendLine('    <header class="page-header">')
  [void]$html.AppendLine('      <h1 class="page-title">' + $titleEncoded + '</h1>')
  [void]$html.AppendLine('    </header>')
  [void]$html.AppendLine('')
  [void]$html.AppendLine('    <section class="intro-text">')
  [void]$html.AppendLine('      <p>' + (HtmlEncode $Intro) + '</p>')
  [void]$html.AppendLine('    </section>')
  [void]$html.AppendLine('')
  [void]$html.AppendLine('    <section class="section-card" aria-labelledby="category-gallery">')
  [void]$html.AppendLine('      <h2 id="category-gallery">' + $titleEncoded + ' Characters</h2>')
  [void]$html.AppendLine('      <div class="gallery-grid">')

  foreach ($page in $Pages) {
    $thumbFull = $ImageLookup[$page.Thumb]
    $thumbPath = Convert-ToWebPath -FromHtmlDir $HtmlDir -FullImagePath $thumbFull
    $thumbPathAttr = HtmlEncode $thumbPath
    $pageTitle = HtmlEncode $page.Title
    $pageSlug = HtmlEncode $page.Slug

    [void]$html.AppendLine('        <a class="gallery-item" href="' + $pageSlug + '">')
    [void]$html.AppendLine('          <img src="' + $thumbPathAttr + '" alt="' + $pageTitle + ' by Ron English" loading="lazy" />')
    [void]$html.AppendLine('          <div class="entry-body">')
    [void]$html.AppendLine('            <p class="work-title">' + $pageTitle + '</p>')
    [void]$html.AppendLine('          </div>')
    [void]$html.AppendLine('        </a>')
    [void]$html.AppendLine('')
  }

  [void]$html.AppendLine('      </div>')
  [void]$html.AppendLine('    </section>')
  [void]$html.AppendLine('')
  [void]$html.AppendLine('    <footer>')
  [void]$html.AppendLine('      Published via GitHub Pages for long-term public access.')
  [void]$html.AppendLine('    </footer>')
  [void]$html.AppendLine('  </main>')
  [void]$html.AppendLine('</body>')
  [void]$html.AppendLine('</html>')

  return $html.ToString()
}

function Build-AviansIndexPage {
  $ducksHeroRel = '../../images/Sketches/avians/Duck HERO.png'
  $eaglesHeroRel = '../../images/Sketches/avians/Eagle HERO.png'
  $otherBirdsHeroRel = '../../images/Sketches/avians/Other Birds HERO.png'

  $html = New-Object System.Text.StringBuilder

  [void]$html.AppendLine((Get-SharedHead -Title 'Avians | Sketches and Drawings' -CssPath '../../css/styles.css'))
  [void]$html.AppendLine('<body>')
  [void]$html.AppendLine('  <main class="wrap">')
  [void]$html.AppendLine('    <nav class="nav-pills" aria-label="Site navigation">')
  [void]$html.AppendLine('      <a class="nav-pill" href="https://ronenglish-archive.github.io/ron-english-catalogue-raisonne/">Catalogue home</a>')
  [void]$html.AppendLine('      <a class="nav-pill" href="../index.html">Sketches</a>')
  [void]$html.AppendLine('    </nav>')
  [void]$html.AppendLine('')
  [void]$html.AppendLine('    <header class="page-header">')
  [void]$html.AppendLine('      <h1 class="page-title">Avians</h1>')
  [void]$html.AppendLine('    </header>')
  [void]$html.AppendLine('')
  [void]$html.AppendLine('    <section class="intro-text">')
  [void]$html.AppendLine('      <p>Avian character drawings from the Ron English archive, organized by bird-related categories.</p>')
  [void]$html.AppendLine('    </section>')
  [void]$html.AppendLine('')
  [void]$html.AppendLine('    <section class="category-grid" aria-label="Avian sketch categories">')
  [void]$html.AppendLine('')
  [void]$html.AppendLine('      <a class="gallery-item" href="buzzards/index.html">')
  [void]$html.AppendLine('        <img src="../../images/Sketches/buzzards-hero.jpg" alt="Buzzard drawings by Ron English" loading="lazy" />')
  [void]$html.AppendLine('        <div class="entry-body">')
  [void]$html.AppendLine('          <p class="work-title">Buzzards</p>')
  [void]$html.AppendLine('        </div>')
  [void]$html.AppendLine('      </a>')
  [void]$html.AppendLine('')
  [void]$html.AppendLine('      <a class="gallery-item" href="ducks/index.html">')
  [void]$html.AppendLine('        <img src="' + (HtmlEncode $ducksHeroRel) + '" alt="Duck drawings by Ron English" loading="lazy" />')
  [void]$html.AppendLine('        <div class="entry-body">')
  [void]$html.AppendLine('          <p class="work-title">Ducks</p>')
  [void]$html.AppendLine('        </div>')
  [void]$html.AppendLine('      </a>')
  [void]$html.AppendLine('')
  [void]$html.AppendLine('      <a class="gallery-item" href="eagles/index.html">')
  [void]$html.AppendLine('        <img src="' + (HtmlEncode $eaglesHeroRel) + '" alt="Eagle drawings by Ron English" loading="lazy" />')
  [void]$html.AppendLine('        <div class="entry-body">')
  [void]$html.AppendLine('          <p class="work-title">Eagles</p>')
  [void]$html.AppendLine('        </div>')
  [void]$html.AppendLine('      </a>')
  [void]$html.AppendLine('')
  [void]$html.AppendLine('      <a class="gallery-item" href="other birds/index.html">')
  [void]$html.AppendLine('        <img src="' + (HtmlEncode $otherBirdsHeroRel) + '" alt="Other bird drawings by Ron English" loading="lazy" />')
  [void]$html.AppendLine('        <div class="entry-body">')
  [void]$html.AppendLine('          <p class="work-title">Other Birds</p>')
  [void]$html.AppendLine('        </div>')
  [void]$html.AppendLine('      </a>')
  [void]$html.AppendLine('')
  [void]$html.AppendLine('    </section>')
  [void]$html.AppendLine('')
  [void]$html.AppendLine('    <footer>')
  [void]$html.AppendLine('      Published via GitHub Pages for long-term public access.')
  [void]$html.AppendLine('    </footer>')
  [void]$html.AppendLine('')
  [void]$html.AppendLine('  </main>')
  [void]$html.AppendLine('</body>')
  [void]$html.AppendLine('</html>')

  return $html.ToString()
}

Ensure-Folder $AviansHtmlRoot
Ensure-Folder $EaglesHtmlDir
Ensure-Folder $OtherBirdsHtmlDir
Ensure-Folder $ReportDir

if (!(Test-Path $AviansImageRoot)) {
  Write-Host ''
  Write-Host 'ERROR: Avians image folder not found:' -ForegroundColor Red
  Write-Host $AviansImageRoot -ForegroundColor Yellow
  Write-Host ''
  exit 1
}

$missingHeroes = New-Object System.Collections.Generic.List[string]
foreach ($hero in $HeroFiles.Values) {
  $heroPath = Join-Path $AviansImageRoot $hero
  if (!(Test-Path $heroPath)) {
    $missingHeroes.Add($hero)
  }
}

$EaglesPreferredImageDir = Join-Path $AviansImageRoot 'eagles'
$OtherBirdsPreferredImageDir = Join-Path $AviansImageRoot 'other birds'

$missingEagles = Check-RequiredImages -Pages $EaglePages -PreferredFolder $EaglesPreferredImageDir -CategoryName 'Eagles'
$missingOtherBirds = Check-RequiredImages -Pages $OtherBirdPages -PreferredFolder $OtherBirdsPreferredImageDir -CategoryName 'Other Birds'

$allMissing = New-Object System.Collections.Generic.List[string]
foreach ($m in $missingHeroes) { $allMissing.Add("Hero : $m") }
foreach ($m in $missingEagles) { $allMissing.Add($m) }
foreach ($m in $missingOtherBirds) { $allMissing.Add($m) }

if ($allMissing.Count -gt 0) {
  Write-Host ''
  Write-Host 'STOPPED: Some expected image files were not found.' -ForegroundColor Red
  Write-Host 'No HTML pages were written.' -ForegroundColor Yellow
  Write-Host ''
  Write-Host 'Missing files:'
  foreach ($file in $allMissing) {
    Write-Host " - $file"
  }
  Write-Host ''
  Write-Host 'The script checks category subfolders first, then images\Sketches\avians.'
  Write-Host 'Please check capitalization, spaces, extensions, and B&W exactly.'
  exit 1
}

$EagleLookup = Build-ImageLookup -Pages $EaglePages -PreferredFolder $EaglesPreferredImageDir
$OtherBirdLookup = Build-ImageLookup -Pages $OtherBirdPages -PreferredFolder $OtherBirdsPreferredImageDir

$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$reportRows = New-Object System.Collections.Generic.List[object]

foreach ($page in $EaglePages) {
  foreach ($item in $page.Originals) {
    $reportRows.Add([pscustomobject]@{
      Category = 'Eagles'
      Character = $page.Title
      Page = $page.Slug
      Section = 'Original Drawing'
      File = $item.File
      FoundAt = $EagleLookup[$item.File]
    })
  }
  foreach ($item in $page.Digitals) {
    $reportRows.Add([pscustomobject]@{
      Category = 'Eagles'
      Character = $page.Title
      Page = $page.Slug
      Section = 'Digitized Versions'
      File = $item.File
      FoundAt = $EagleLookup[$item.File]
    })
  }
}

foreach ($page in $OtherBirdPages) {
  foreach ($item in $page.Originals) {
    $reportRows.Add([pscustomobject]@{
      Category = 'Other Birds'
      Character = $page.Title
      Page = $page.Slug
      Section = 'Original Drawing'
      File = $item.File
      FoundAt = $OtherBirdLookup[$item.File]
    })
  }
  foreach ($item in $page.Digitals) {
    $reportRows.Add([pscustomobject]@{
      Category = 'Other Birds'
      Character = $page.Title
      Page = $page.Slug
      Section = 'Digitized Versions'
      File = $item.File
      FoundAt = $OtherBirdLookup[$item.File]
    })
  }
}

$csvPath = Join-Path $ReportDir 'avians-eagles-other-birds-build-report.csv'
$txtPath = Join-Path $ReportDir 'avians-eagles-other-birds-build-summary.txt'

$reportRows | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

$summary = @()
$summary += 'Avians Eagles and Other Birds build report'
$summary += "Generated: $timestamp"
$summary += ''
$summary += "Avians image root: $AviansImageRoot"
$summary += "Avians HTML root:  $AviansHtmlRoot"
$summary += ''
$summary += 'Pages created or updated:'
$summary += '- Sketches\avians\index.html'
$summary += '- Sketches\avians\eagles\index.html'
foreach ($page in $EaglePages) {
  $summary += ('- Sketches\avians\eagles\' + $page.Slug)
}
$summary += '- Sketches\avians\other birds\index.html'
foreach ($page in $OtherBirdPages) {
  $summary += ('- Sketches\avians\other birds\' + $page.Slug)
}
$summary += ''
$summary += 'No-original standard applied to:'
$summary += '- Eagle Weed'
$summary += '- Lightning Bird'
$summary += '- Bird Beak'
$summary += ''
$summary += 'Images used:'
foreach ($row in $reportRows) {
  $summary += ('- ' + $row.Category + ' / ' + $row.Character + ' / ' + $row.Section + ': ' + $row.File + ' -> ' + $row.FoundAt)
}
$summary | Set-Content -Path $txtPath -Encoding UTF8

$aviansIndexPath = Join-Path $AviansHtmlRoot 'index.html'
Backup-IfExists $aviansIndexPath
Build-AviansIndexPage | Set-Content -Path $aviansIndexPath -Encoding UTF8

$eaglesIndexPath = Join-Path $EaglesHtmlDir 'index.html'
Backup-IfExists $eaglesIndexPath
Build-CategoryIndexPage -Title 'Eagles' -Intro 'Eagle-related character drawings from the Ron English archive, including original drawings and digitized versions where available.' -Pages $EaglePages -HtmlDir $EaglesHtmlDir -ImageLookup $EagleLookup | Set-Content -Path $eaglesIndexPath -Encoding UTF8

foreach ($page in $EaglePages) {
  $pagePath = Join-Path $EaglesHtmlDir $page.Slug
  Backup-IfExists $pagePath
  Build-CharacterPage -Page $page -CategoryName 'eagles' -CategoryIndexLabel 'Eagles' -HtmlDir $EaglesHtmlDir -ImageLookup $EagleLookup | Set-Content -Path $pagePath -Encoding UTF8
}

$otherBirdsIndexPath = Join-Path $OtherBirdsHtmlDir 'index.html'
Backup-IfExists $otherBirdsIndexPath
Build-CategoryIndexPage -Title 'Other Birds' -Intro 'Additional bird-related character drawings from the Ron English archive, including original drawings and digitized versions where available.' -Pages $OtherBirdPages -HtmlDir $OtherBirdsHtmlDir -ImageLookup $OtherBirdLookup | Set-Content -Path $otherBirdsIndexPath -Encoding UTF8

foreach ($page in $OtherBirdPages) {
  $pagePath = Join-Path $OtherBirdsHtmlDir $page.Slug
  Backup-IfExists $pagePath
  Build-CharacterPage -Page $page -CategoryName 'other birds' -CategoryIndexLabel 'Other Birds' -HtmlDir $OtherBirdsHtmlDir -ImageLookup $OtherBirdLookup | Set-Content -Path $pagePath -Encoding UTF8
}

Write-Host ''
Write-Host 'Avians Eagles and Other Birds pages built successfully.' -ForegroundColor Green
Write-Host ''
Write-Host 'Created or updated:'
Write-Host " - $aviansIndexPath"
Write-Host " - $eaglesIndexPath"
foreach ($page in $EaglePages) {
  Write-Host (' - ' + (Join-Path $EaglesHtmlDir $page.Slug))
}
Write-Host " - $otherBirdsIndexPath"
foreach ($page in $OtherBirdPages) {
  Write-Host (' - ' + (Join-Path $OtherBirdsHtmlDir $page.Slug))
}
Write-Host ''
Write-Host 'Reports:'
Write-Host " - $csvPath"
Write-Host " - $txtPath"
Write-Host ''
Write-Host 'No-original standard applied to:' -ForegroundColor Yellow
Write-Host ' - Eagle Weed'
Write-Host ' - Lightning Bird'
Write-Host ' - Bird Beak'
Write-Host ''
