# fix-grins-b-manual-corrections.ps1
# Ron English Sketches and Drawings Catalogue
#
# Rebuilds the Grins B-name batch with manual corrections from review.
#
# Important:
# - This does NOT delete any image files from your computer.
# - "Remove" means the image is removed from the generated page/index only.
# - Existing HTML files are backed up before being overwritten.
# - The generated B block in Sketches\grins\index.html is replaced safely.
#
# Corrections included:
# - Baby Grin ORIGINAL COLOR.jpg -> collector card
# - Badly Drawn Batman Grin ORIGINAL COLOR.jpg -> digitized, no original
# - Bart Grin front/side ORIGINAL COLOR.jpg -> excluded
# - Baseball Grin ORIGINAL COLOR 2/3.jpg -> collector cards
# - Basketball Grin ORIGINAL COLOR.jpg -> collector card
# - Batman Grin ORIGINAL.jpg -> excluded
# - Batman Grin ORIGINAL COLOR.jpg -> collector card
# - Batman Grin side ORIGINAL.jpg -> digitized
# - Batman Grin three quarters COLOR files -> own page: Batman Grin Torso
# - Batman Grin Icon .jpg -> excluded
# - Big Boy Grin ORIGINAL COLOR.jpg -> excluded
# - Bored Ape Cowboy Grin COLOR 2.jpg -> moved to Bored Ape Grin
# - Bored Ape Cowboy Grin index thumbnail -> Bored Ape Cowboy Grin COLOR.jpg
# - Bored Ape Grin index thumbnail -> Bored Ape Cowboy Grin COLOR 2.jpg
# - B-Rex Grin ORIGINAL COLOR.jpg -> collector card

param(
  [switch]$ReportOnly
)

$ErrorActionPreference = 'Stop'

$RepoRoot = 'D:\github\ron-english-sketches-and-drawings'
$ImageDir = Join-Path $RepoRoot 'images\Sketches\grins'
$HtmlDir  = Join-Path $RepoRoot 'Sketches\grins'
$ReportDir = Join-Path $HtmlDir '_reports'

$NoOriginalText = 'No original drawing is currently documented on this page. If one is located, it will be added here.'
$ImageExtensions = @('.jpg', '.jpeg', '.png', '.webp', '.gif', '.avif')

# Exact filenames to exclude from generated pages.
$ExcludeFiles = @(
  'Bart Grin front ORIGINAL COLOR.jpg',
  'Bart Grin side ORIGINAL COLOR.jpg',
  'Batman Grin ORIGINAL.jpg',
  'Batman Grin Icon .jpg',
  'Big Boy Grin ORIGINAL COLOR.jpg'
)

# Exact classification overrides.
# Valid kinds: Originals, Digitals, Cards
$KindOverrides = @{
  'Baby Grin ORIGINAL COLOR.jpg' = 'Cards'
  'Badly Drawn Batman Grin ORIGINAL COLOR.jpg' = 'Digitals'
  'Baseball Grin ORIGINAL COLOR 2.jpg' = 'Cards'
  'Baseball Grin ORIGINAL COLOR 3.jpg' = 'Cards'
  'Basketball Grin ORIGINAL COLOR.jpg' = 'Cards'
  'Batman Grin ORIGINAL COLOR.jpg' = 'Cards'
  'Batman Grin side ORIGINAL.jpg' = 'Digitals'
  'B-Rex Grin ORIGINAL COLOR.jpg' = 'Cards'
}

# Exact grouping overrides.
$GroupOverrides = @{
  'Batman Grin three quarters COLOR 1.png' = 'Batman Grin Torso'
  'Batman Grin three quarters COLOR 2.png' = 'Batman Grin Torso'
  'Batman Grin three quarters COLOR 3.png' = 'Batman Grin Torso'
  'Batman Grin three quarters COLOR 4.png' = 'Batman Grin Torso'
  'Bored Ape Cowboy Grin COLOR 2.jpg' = 'Bored Ape Grin'
}

# Exact thumbnail overrides.
$ThumbOverrides = @{
  'Bored Ape Cowboy Grin' = 'Bored Ape Cowboy Grin COLOR.jpg'
  'Bored Ape Grin' = 'Bored Ape Cowboy Grin COLOR 2.jpg'
  'Batman Grin Torso' = 'Batman Grin three quarters COLOR 1.png'
}

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

function Convert-ToSlug {
  param([string]$Text)
  $slug = $Text.ToLowerInvariant()
  $slug = $slug -replace '&', ' and '
  $slug = $slug -replace '[’‘''`]', ''
  $slug = $slug -replace '[^a-z0-9]+', '-'
  $slug = $slug.Trim('-')
  if ([string]::IsNullOrWhiteSpace($slug)) { return 'untitled' }
  return $slug
}

function Clean-CharacterName {
  param([string]$FileName)

  if ($GroupOverrides.ContainsKey($FileName)) {
    return $GroupOverrides[$FileName]
  }

  $clean = [System.IO.Path]::GetFileNameWithoutExtension($FileName)
  $clean = $clean -replace '\s+', ' '
  $clean = $clean.Trim()
  $changed = $true

  while ($changed) {
    $before = $clean

    $clean = [regex]::Replace($clean, '\s+B\s*&\s*W$', '', 'IgnoreCase')
    $clean = [regex]::Replace($clean, '\s+B&W$', '', 'IgnoreCase')
    $clean = [regex]::Replace($clean, '\s+BW$', '', 'IgnoreCase')
    $clean = [regex]::Replace($clean, '\s+COLOR(?:\s+\d+)?$', '', 'IgnoreCase')
    $clean = [regex]::Replace($clean, '\s+COLOUR(?:\s+\d+)?$', '', 'IgnoreCase')
    $clean = [regex]::Replace($clean, '\s+ORIGINAL\s+COLOR\s+colorway\s+\d+$', '', 'IgnoreCase')
    $clean = [regex]::Replace($clean, '\s+ORIGINAL\s+COLOUR\s+colorway\s+\d+$', '', 'IgnoreCase')
    $clean = [regex]::Replace($clean, '\s+ORIGINAL\s+colorway\s+\d+$', '', 'IgnoreCase')
    $clean = [regex]::Replace($clean, '\s+ORIGINAL\s+COLOR(?:\s+\d+)?$', '', 'IgnoreCase')
    $clean = [regex]::Replace($clean, '\s+ORIGINAL\s+COLOUR(?:\s+\d+)?$', '', 'IgnoreCase')
    $clean = [regex]::Replace($clean, '\s+ORIGINAL(?:\s+\d+)?$', '', 'IgnoreCase')
    $clean = [regex]::Replace($clean, '\s+colorway\s+\d+$', '', 'IgnoreCase')
    $clean = [regex]::Replace($clean, '\s+colourway\s+\d+$', '', 'IgnoreCase')
    $clean = [regex]::Replace($clean, '\s+card$', '', 'IgnoreCase')
    $clean = [regex]::Replace($clean, '\s+raw file copy$', '', 'IgnoreCase')
    $clean = [regex]::Replace($clean, '\s+copy$', '', 'IgnoreCase')

    # Remove view descriptors at the end.
    $clean = [regex]::Replace($clean, '\s+right side(?:\s+\d+)?$', '', 'IgnoreCase')
    $clean = [regex]::Replace($clean, '\s+left side(?:\s+\d+)?$', '', 'IgnoreCase')
    $clean = [regex]::Replace($clean, '\s+three quarters(?:\s+\d+)?$', '', 'IgnoreCase')
    $clean = [regex]::Replace($clean, '\s+crouching(?:\s+\d+)?$', '', 'IgnoreCase')
    $clean = [regex]::Replace($clean, '\s+flying(?:\s+\d+)?$', '', 'IgnoreCase')
    $clean = [regex]::Replace($clean, '\s+chubby(?:\s+\d+)?$', '', 'IgnoreCase')
    $clean = [regex]::Replace($clean, '\s+short(?:\s+\d+)?$', '', 'IgnoreCase')
    $clean = [regex]::Replace($clean, '\s+front(?:\s+\d+)?$', '', 'IgnoreCase')
    $clean = [regex]::Replace($clean, '\s+back(?:\s+\d+)?$', '', 'IgnoreCase')
    $clean = [regex]::Replace($clean, '\s+side(?:\s+\d+)?$', '', 'IgnoreCase')
    $clean = [regex]::Replace($clean, '\s+face(?:\s+\d+)?$', '', 'IgnoreCase')
    $clean = [regex]::Replace($clean, '\s+head(?:\s+\d+)?$', '', 'IgnoreCase')
    $clean = [regex]::Replace($clean, '\s+closeup$', '', 'IgnoreCase')

    $clean = $clean -replace '\s+', ' '
    $clean = $clean.Trim(' -_')
    $changed = ($clean -ne $before)
  }

  if ([string]::IsNullOrWhiteSpace($clean)) {
    return [System.IO.Path]::GetFileNameWithoutExtension($FileName)
  }
  return $clean
}

function Get-FileKind {
  param([string]$FileName)
  if ($KindOverrides.ContainsKey($FileName)) { return $KindOverrides[$FileName] }
  $n = $FileName.ToLowerInvariant()
  if ($n -match '\bcard\b') { return 'Cards' }
  if ($n -match '\boriginal\b') { return 'Originals' }
  return 'Digitals'
}

function Get-SortRank {
  param([string]$FileName)
  $n = $FileName.ToLowerInvariant()
  $rank = 500
  if ($n -match 'front') { $rank -= 50 }
  elseif ($n -match 'back') { $rank -= 40 }
  elseif ($n -match 'left side') { $rank -= 30 }
  elseif ($n -match 'right side') { $rank -= 25 }
  elseif ($n -match 'side') { $rank -= 20 }
  elseif ($n -match 'face') { $rank -= 15 }
  elseif ($n -match 'head') { $rank -= 10 }
  if ($n -match 'b\s*&\s*w|b&w|bw') { $rank -= 5 }
  if ($n -match 'color|colour') { $rank += 5 }
  if ($n -match 'original') { $rank -= 100 }
  if ($n -match 'card') { $rank += 100 }
  return $rank
}

function Get-ImageFullPath {
  param([string]$FileName)
  return Join-Path $ImageDir $FileName
}

function Convert-ToWebPath {
  param(
    [string]$FromHtmlDir,
    [string]$FullImagePath
  )
  $fromUri = New-Object System.Uri(($FromHtmlDir.TrimEnd('\') + '\'))
  $toUri = New-Object System.Uri($FullImagePath)
  # Keep URI encoding intact so filenames with spaces, &, apostrophes, parentheses, or # work in browsers.
  $relative = $fromUri.MakeRelativeUri($toUri).ToString()
  return $relative -replace '\\','/'
}

function Pick-Thumbnail {
  param(
    [string]$Title,
    [array]$Originals,
    [array]$Digitals,
    [array]$Cards
  )
  if ($ThumbOverrides.ContainsKey($Title)) { return $ThumbOverrides[$Title] }
  $all = @()
  foreach ($item in $Digitals) { $all += $item }
  foreach ($item in $Originals) { $all += $item }
  foreach ($item in $Cards) { $all += $item }
  $preferred = $Digitals | Where-Object { $_.File -match 'COLOR|COLOUR|colorway|colourway' -and $_.File -notmatch 'side|back|left|right' } | Select-Object -First 1
  if ($preferred) { return $preferred.File }
  $preferred = $Originals | Where-Object { $_.File -match 'COLOR|COLOUR' -and $_.File -notmatch 'side|back|left|right' } | Select-Object -First 1
  if ($preferred) { return $preferred.File }
  $preferred = $Digitals | Where-Object { $_.File -notmatch 'side|back|left|right' } | Select-Object -First 1
  if ($preferred) { return $preferred.File }
  if ($all.Count -gt 0) { return $all[0].File }
  return ''
}

function Make-ImageItem {
  param([System.IO.FileInfo]$File)
  $base = [System.IO.Path]::GetFileNameWithoutExtension($File.Name)
  return @{ File = $File.Name; Alt = "$base by Ron English"; SortRank = (Get-SortRank -FileName $File.Name) }
}

function Add-ImageCard {
  param(
    [System.Text.StringBuilder]$Builder,
    [hashtable]$Item,
    [string]$GridHtmlDir
  )
  $full = Get-ImageFullPath $Item.File
  $href = Convert-ToWebPath -FromHtmlDir $GridHtmlDir -FullImagePath $full
  $hrefAttr = HtmlEncode $href
  $alt = HtmlEncode $Item.Alt
  [void]$Builder.AppendLine('        <figure class="gallery-item">')
  [void]$Builder.AppendLine('          <a href="' + $hrefAttr + '" target="_blank" rel="noopener noreferrer">')
  [void]$Builder.AppendLine('            <img src="' + $hrefAttr + '" alt="' + $alt + '" loading="lazy" />')
  [void]$Builder.AppendLine('          </a>')
  [void]$Builder.AppendLine('        </figure>')
}

function Get-SharedHead {
  param([string]$Title)
  return @"
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>$Title | Grins | Ron English Catalogue Raisonn&eacute;</title>

  <link rel="stylesheet" href="../../css/styles.css" />

  <style>
    :root{ --border:#e5e7eb; --muted:#4b5563; --shadow:0 10px 30px rgba(0,0,0,.08); --radius:18px; --bg:#ffffff; --panel:#f3f4f6; --pill-hover:#f9fafb; }
    *{ box-sizing:border-box; }
    html{ scroll-behavior:smooth; }
    body{ margin:0; font-family:system-ui,-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif; color:#111; background:var(--bg); padding-left:0; padding-right:0; }
    .wrap{ max-width:1240px; margin:0 auto; padding:28px 18px 60px; }
    .page-narrow{ max-width:1100px; }
    .nav-pills{ display:flex; flex-wrap:wrap; gap:10px; margin:22px 0; }
    .nav-pill{ padding:8px 14px; border-radius:999px; border:1px solid var(--border); background:#fff; color:#111; text-decoration:none; font-size:14px; transition:background .12s ease, border-color .12s ease, transform .12s ease; }
    .nav-pill:hover{ background:var(--pill-hover); border-color:#d1d5db; transform:translateY(-1px); }
    .page-header{ max-width:1100px; margin:0 0 28px; padding:0; text-align:left; }
    .page-title{ margin:0 0 10px; font-size:clamp(2rem,4vw,3rem); letter-spacing:-.02em; line-height:1.05; }
    .intro-text{ max-width:1100px; margin:0 0 28px; padding:0; line-height:1.6; text-align:left; }
    .intro-text p{ margin:0 0 14px; max-width:none; width:100%; color:var(--muted); font-size:18px; }
    .section-card{ background:#fff; border:1px solid var(--border); border-radius:var(--radius); box-shadow:var(--shadow); padding:22px; margin-bottom:24px; }
    .section-card h2{ margin:0 0 8px; font-size:1.4rem; }
    .section-intro{ margin:0 0 18px; color:var(--muted); line-height:1.6; }
    .index-grid{ margin-top:28px; display:grid; grid-template-columns:repeat(4,minmax(0,1fr)); gap:18px; }
    .gallery-grid,.card-grid{ display:grid; grid-template-columns:repeat(auto-fit,minmax(220px,1fr)); gap:20px; }
    .originals-grid{ display:grid; grid-template-columns:repeat(auto-fit,minmax(260px,1fr)); gap:20px; }
    .gallery-item{ display:block; text-decoration:none; color:inherit; background:#fff; border:1px solid var(--border); border-radius:16px; overflow:hidden; box-shadow:0 4px 18px rgba(0,0,0,.04); margin:0; transition:transform .12s ease, box-shadow .12s ease, border-color .12s ease; }
    .gallery-item:hover{ transform:translateY(-2px); box-shadow:0 16px 40px rgba(0,0,0,.12); border-color:#d1d5db; }
    .gallery-item a{ display:block; color:inherit; text-decoration:none; }
    .gallery-item img{ display:block; width:100%; object-fit:contain; background:var(--panel); padding:8px; border-bottom:0; }
    .index-grid .gallery-item img{ height:260px; padding:10px; border-bottom:1px solid var(--border); }
    .gallery-grid .gallery-item img{ height:300px; }
    .originals-grid .gallery-item img{ height:440px; }
    .card-grid .gallery-item img{ height:520px; padding:10px; }
    .entry-body{ padding:16px 18px 18px; display:flex; flex-direction:column; align-items:center; justify-content:center; text-align:center; }
    .work-title{ margin:0; padding:0; width:100%; font-size:18px; line-height:1.35; font-weight:600; text-align:center; }
    .back-link{ margin-top:28px; }
    .back-link a{ display:inline-block; text-decoration:none; color:#111; border:1px solid var(--border); border-radius:999px; padding:10px 16px; background:#fff; }
    .back-link a:hover{ background:#f9fafb; }
    footer{ margin-top:34px; padding-top:16px; border-top:1px solid var(--border); color:var(--muted); font-size:14px; }
    @media (max-width:1100px){ .index-grid{ grid-template-columns:repeat(3,minmax(0,1fr)); } }
    @media (max-width:820px){ .index-grid{ grid-template-columns:repeat(2,minmax(0,1fr)); } }
    @media (max-width:560px){ .wrap{ padding:22px 14px 50px; } .index-grid,.gallery-grid,.card-grid,.originals-grid{ grid-template-columns:1fr; } .index-grid .gallery-item img,.gallery-grid .gallery-item img{ height:260px; } .originals-grid .gallery-item img{ height:340px; } .card-grid .gallery-item img{ height:420px; } }
  </style>
</head>
"@
}

function Build-CharacterPage {
  param([hashtable]$Page)
  $title = HtmlEncode $Page.Title
  $html = New-Object System.Text.StringBuilder
  [void]$html.AppendLine((Get-SharedHead -Title $title))
  [void]$html.AppendLine('<body>')
  [void]$html.AppendLine('  <main class="wrap page-narrow">')
  [void]$html.AppendLine('    <nav class="nav-pills" aria-label="Site navigation">')
  [void]$html.AppendLine('      <a class="nav-pill" href="https://ronenglish-archive.github.io/ron-english-catalogue-raisonne/">Catalogue home</a>')
  [void]$html.AppendLine('      <a class="nav-pill" href="../index.html">Sketches</a>')
  [void]$html.AppendLine('      <a class="nav-pill" href="index.html">Grins</a>')
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
    foreach ($item in $Page.Originals) { Add-ImageCard -Builder $html -Item $item -GridHtmlDir $HtmlDir; [void]$html.AppendLine('') }
    [void]$html.AppendLine('      </div>')
  } else {
    [void]$html.AppendLine('      <p class="section-intro">' + (HtmlEncode $NoOriginalText) + '</p>')
  }
  [void]$html.AppendLine('    </section>')
  [void]$html.AppendLine('')
  if ($Page.Digitals.Count -gt 0) {
    [void]$html.AppendLine('    <section class="section-card" aria-labelledby="digitized-versions">')
    [void]$html.AppendLine('      <h2 id="digitized-versions">Digitized Versions</h2>')
    [void]$html.AppendLine('      <div class="gallery-grid">')
    foreach ($item in $Page.Digitals) { Add-ImageCard -Builder $html -Item $item -GridHtmlDir $HtmlDir; [void]$html.AppendLine('') }
    [void]$html.AppendLine('      </div>')
    [void]$html.AppendLine('    </section>')
    [void]$html.AppendLine('')
  }
  if ($Page.Cards.Count -gt 0) {
    [void]$html.AppendLine('    <section class="section-card" aria-labelledby="collector-cards">')
    [void]$html.AppendLine('      <h2 id="collector-cards">Collector Cards</h2>')
    [void]$html.AppendLine('      <div class="card-grid">')
    foreach ($item in $Page.Cards) { Add-ImageCard -Builder $html -Item $item -GridHtmlDir $HtmlDir; [void]$html.AppendLine('') }
    [void]$html.AppendLine('      </div>')
    [void]$html.AppendLine('    </section>')
    [void]$html.AppendLine('')
  }
  [void]$html.AppendLine('    <div class="back-link">')
  [void]$html.AppendLine('      <a href="index.html">&larr; Back to Grins</a>')
  [void]$html.AppendLine('    </div>')
  [void]$html.AppendLine('  </main>')
  [void]$html.AppendLine('</body>')
  [void]$html.AppendLine('</html>')
  return $html.ToString()
}

function Get-IndexCardHtml {
  param([hashtable]$Page)
  $thumbFull = Get-ImageFullPath $Page.Thumb
  $thumbPath = Convert-ToWebPath -FromHtmlDir $HtmlDir -FullImagePath $thumbFull
  $thumbPathAttr = HtmlEncode $thumbPath
  $title = HtmlEncode $Page.Title
  $slug = HtmlEncode $Page.Slug
  return @"

      <a class="gallery-item" href="$slug">
        <img src="$thumbPathAttr" alt="$title by Ron English" loading="lazy" />
        <div class="entry-body">
          <p class="work-title">$title</p>
        </div>
      </a>
"@
}

Ensure-Folder $HtmlDir
Ensure-Folder $ReportDir

if (!(Test-Path $ImageDir)) {
  Write-Host ''
  Write-Host 'ERROR: Grins image folder not found:' -ForegroundColor Red
  Write-Host $ImageDir -ForegroundColor Yellow
  Write-Host ''
  exit 1
}

$files = Get-ChildItem -Path $ImageDir -File |
  Where-Object { $ImageExtensions -contains $_.Extension.ToLowerInvariant() -and $_.Name -match '^[Bb]' -and ($ExcludeFiles -notcontains $_.Name) } |
  Sort-Object Name

$groupMap = @{}
foreach ($file in $files) {
  $title = Clean-CharacterName -FileName $file.Name
  $key = Convert-ToSlug -Text $title
  $kind = Get-FileKind -FileName $file.Name
  $item = Make-ImageItem -File $file
  if (!$groupMap.ContainsKey($key)) {
    $groupMap[$key] = @{ Title = $title; Slug = "$key.html"; Originals = New-Object System.Collections.Generic.List[object]; Digitals = New-Object System.Collections.Generic.List[object]; Cards = New-Object System.Collections.Generic.List[object] }
  }
  if ($kind -eq 'Originals') { $groupMap[$key].Originals.Add($item) }
  elseif ($kind -eq 'Cards') { $groupMap[$key].Cards.Add($item) }
  else { $groupMap[$key].Digitals.Add($item) }
}

$pages = @()
foreach ($key in ($groupMap.Keys | Sort-Object)) {
  $g = $groupMap[$key]
  $originals = @($g.Originals | Sort-Object @{Expression={$_.SortRank}}, @{Expression={$_.File}})
  $digitals = @($g.Digitals | Sort-Object @{Expression={$_.SortRank}}, @{Expression={$_.File}})
  $cards = @($g.Cards | Sort-Object @{Expression={$_.File}})
  $thumb = Pick-Thumbnail -Title $g.Title -Originals $originals -Digitals $digitals -Cards $cards
  $pages += @{ Title = $g.Title; Slug = $g.Slug; Thumb = $thumb; Originals = $originals; Digitals = $digitals; Cards = $cards }
}

# Validate thumb override files exist.
$missing = New-Object System.Collections.Generic.List[string]
foreach ($page in $pages) {
  if (![string]::IsNullOrWhiteSpace($page.Thumb) -and !(Test-Path (Join-Path $ImageDir $page.Thumb))) { $missing.Add($page.Thumb) }
}
if ($missing.Count -gt 0) {
  Write-Host ''
  Write-Host 'STOPPED: Some required thumbnail files were not found.' -ForegroundColor Red
  foreach ($file in ($missing | Sort-Object -Unique)) { Write-Host " - $file" }
  exit 1
}

# Build reports.
$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$csvPath = Join-Path $ReportDir 'grins-b-manual-corrections-report.csv'
$txtPath = Join-Path $ReportDir 'grins-b-manual-corrections-summary.txt'
$reportRows = New-Object System.Collections.Generic.List[object]
foreach ($page in $pages) {
  foreach ($item in $page.Originals) { $reportRows.Add([pscustomobject]@{ Batch='B'; Character=$page.Title; Page=$page.Slug; Section='Original Drawing'; File=$item.File; FullPath=(Get-ImageFullPath $item.File) }) }
  foreach ($item in $page.Digitals) { $reportRows.Add([pscustomobject]@{ Batch='B'; Character=$page.Title; Page=$page.Slug; Section='Digitized Versions'; File=$item.File; FullPath=(Get-ImageFullPath $item.File) }) }
  foreach ($item in $page.Cards) { $reportRows.Add([pscustomobject]@{ Batch='B'; Character=$page.Title; Page=$page.Slug; Section='Collector Cards'; File=$item.File; FullPath=(Get-ImageFullPath $item.File) }) }
}
$reportRows | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
$summary = @()
$summary += 'Grins B manual corrections report'
$summary += "Generated: $timestamp"
$summary += ''
$summary += "B-name image files scanned after exclusions: $($files.Count)"
$summary += "Pages generated: $($pages.Count)"
$summary += ''
$summary += 'Excluded from generated pages:'
foreach ($file in $ExcludeFiles) { $summary += ('- ' + $file) }
$summary += ''
$summary += 'Kind overrides:'
foreach ($key in ($KindOverrides.Keys | Sort-Object)) { $summary += ('- ' + $key + ' -> ' + $KindOverrides[$key]) }
$summary += ''
$summary += 'Group overrides:'
foreach ($key in ($GroupOverrides.Keys | Sort-Object)) { $summary += ('- ' + $key + ' -> ' + $GroupOverrides[$key]) }
$summary += ''
$summary += 'Pages:'
foreach ($page in $pages) { $summary += ('- ' + $page.Title + ' -> ' + $page.Slug + ' | originals: ' + $page.Originals.Count + ', digitals: ' + $page.Digitals.Count + ', cards: ' + $page.Cards.Count + ', thumb: ' + $page.Thumb) }
$summary | Set-Content -Path $txtPath -Encoding UTF8

if ($ReportOnly) {
  Write-Host ''
  Write-Host 'Report-only mode complete. No HTML pages were written.' -ForegroundColor Green
  Write-Host ''
  Write-Host 'Reports:'
  Write-Host " - $csvPath"
  Write-Host " - $txtPath"
  Write-Host ''
  exit 0
}

# Rebuild all B pages.
foreach ($page in $pages) {
  $pagePath = Join-Path $HtmlDir $page.Slug
  Backup-IfExists $pagePath
  Build-CharacterPage -Page $page | Set-Content -Path $pagePath -Encoding UTF8
}

# Update index B block.
$indexPath = Join-Path $HtmlDir 'index.html'
if (!(Test-Path $indexPath)) {
  Write-Host ''
  Write-Host 'ERROR: Grins index not found. Run build-grins-a-pages.ps1 first.' -ForegroundColor Red
  Write-Host $indexPath -ForegroundColor Yellow
  Write-Host ''
  exit 1
}
Backup-IfExists $indexPath
$indexHtml = Get-Content -Path $indexPath -Raw -Encoding UTF8
$indexHtml = [regex]::Replace($indexHtml, '(?s)\s*<!-- BEGIN GENERATED GRINS B -->.*?<!-- END GENERATED GRINS B -->', '')
$blockBuilder = New-Object System.Text.StringBuilder
[void]$blockBuilder.AppendLine('')
[void]$blockBuilder.AppendLine('      <!-- BEGIN GENERATED GRINS B -->')
foreach ($page in $pages) { [void]$blockBuilder.Append((Get-IndexCardHtml -Page $page)) }
[void]$blockBuilder.AppendLine('')
[void]$blockBuilder.AppendLine('      <!-- END GENERATED GRINS B -->')
$block = $blockBuilder.ToString()
$sectionMatch = [regex]::Match($indexHtml, '(?s)<section class="index-grid"[^>]*>.*?</section>')
if ($sectionMatch.Success) {
  $section = $sectionMatch.Value
  $newSection = [regex]::Replace($section, '\s*</section>\s*$', ($block + "`n    </section>"))
  $indexHtml = $indexHtml.Substring(0, $sectionMatch.Index) + $newSection + $indexHtml.Substring($sectionMatch.Index + $sectionMatch.Length)
} else {
  Write-Host ''
  Write-Host 'ERROR: Could not find the Grins index-grid section.' -ForegroundColor Red
  Write-Host 'Individual pages were created, but index.html was not updated.' -ForegroundColor Yellow
  Write-Host ''
  exit 1
}
Set-Content -Path $indexPath -Value $indexHtml -Encoding UTF8

Write-Host ''
Write-Host 'Grins B manual corrections applied successfully.' -ForegroundColor Green
Write-Host ''
Write-Host 'Updated:'
Write-Host " - $indexPath"
foreach ($page in $pages) { Write-Host (' - ' + (Join-Path $HtmlDir $page.Slug)) }
Write-Host ''
Write-Host 'Reports:'
Write-Host " - $csvPath"
Write-Host " - $txtPath"
Write-Host ''
Write-Host 'Important:' -ForegroundColor Yellow
Write-Host ' - No image files were deleted from your folder; excluded files were only removed from generated HTML.'
Write-Host ' - Review Batman Grin, Batman Grin Torso, Bored Ape Cowboy Grin, Bored Ape Grin, Baby Grin, Baseball Grin, Basketball Grin, and B-Rex Grin.'
Write-Host ''
