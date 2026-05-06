Set-Location "D:\github\ron-english-sketches-and-drawings"

$repo = "D:\github\ron-english-sketches-and-drawings"
$pageFolder = Join-Path $repo "Sketches\avians\ducks"
$imageFolder = Join-Path $repo "images\Sketches\avians\ducks"
$summaryFile = Join-Path $repo "ducks-final-build-summary.txt"

$cssRel = "../../../css/styles.css"
$imageRel = "../../../images/Sketches/avians/ducks/"

Write-Host ""
Write-Host "RUNNING DUCKS FINAL BUILD FROM PS1 FILE"
Write-Host ""

if (-not (Test-Path -LiteralPath $imageFolder)) {
  Write-Host "ERROR: Image folder not found:"
  Write-Host $imageFolder
  exit
}

New-Item -ItemType Directory -Path $pageFolder -Force | Out-Null

$backupFolder = Join-Path $pageFolder ("backup-before-ducks-final-" + (Get-Date -Format "yyyyMMdd-HHmmss"))
New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null

Get-ChildItem -LiteralPath $pageFolder -Filter "*.html" -ErrorAction SilentlyContinue |
  Copy-Item -Destination $backupFolder -Force

Get-ChildItem -LiteralPath $pageFolder -Filter "*.html" -ErrorAction SilentlyContinue |
  Remove-Item -Force

$allFiles = Get-ChildItem -LiteralPath $imageFolder -File | Sort-Object Name
$imageFiles = $allFiles | Where-Object { $_.Extension -match "^\.(jpg|jpeg|png|webp|avif)$" }

function ConvertTo-Slug {
  param([string]$Text)
  $slug = $Text.ToLowerInvariant()
  $slug = $slug -replace "&", "and"
  $slug = $slug -replace "[^a-z0-9]+", "-"
  $slug = $slug.Trim("-")
  return $slug
}

function HtmlEncode {
  param([string]$Text)
  if ($null -eq $Text) { return "" }
  return [System.Net.WebUtility]::HtmlEncode($Text)
}

function SafeSrc {
  param([string]$FileName)
  $src = "$imageRel$FileName"
  $src = $src -replace "#", "%23"
  $src = $src -replace "&", "&amp;"
  return $src
}

function New-ImageCard {
  param(
    [string]$File,
    [string]$Alt
  )
  $src = SafeSrc $File
  $safeAlt = HtmlEncode $Alt
  return @"
        <a class="gallery-item" href="$src">
          <img src="$src" alt="$safeAlt" loading="lazy" />
        </a>

"@
}

function New-FileLink {
  param([string]$File)
  $src = SafeSrc $File
  $label = HtmlEncode $File
  return @"
        <li><a href="$src">$label</a></li>

"@
}

function New-TradingCardSection {
  param(
    [object]$Trading,
    [string]$Title
  )

  if ($null -eq $Trading) { return "" }

  $frontFile = $Trading.FrontFile
  $backFile = $Trading.BackFile

  $frontPath = SafeSrc $frontFile
  $backPath = SafeSrc $backFile
  $safeTitle = HtmlEncode $Title

  $series = HtmlEncode $Trading.Series
  $number = HtmlEncode $Trading.Number
  $rarity = HtmlEncode $Trading.Rarity

  if (-not [string]::IsNullOrWhiteSpace($Trading.Affiliation)) {
    $affiliation = HtmlEncode $Trading.Affiliation
    $occupation = HtmlEncode $Trading.Occupation
    $preoccupation = HtmlEncode $Trading.Preoccupation
    $virtue = HtmlEncode $Trading.Virtue
    $vice = HtmlEncode $Trading.Vice
    $poem = HtmlEncode $Trading.Poem

    $detailsHtml = @"
      <div class="card-text-block">
        <div class="card-column">
          <span class="text-label">Card details</span>
          <div class="card-details">
            <p class="card-detail"><strong>Series:</strong> $series</p>
            <p class="card-detail"><strong>Number:</strong> $number</p>
            <p class="card-detail"><strong>Rarity:</strong> $rarity</p>
            <p class="card-detail"><strong>Affiliation:</strong> $affiliation</p>
            <p class="card-detail"><strong>Occupation:</strong> $occupation</p>
            <p class="card-detail"><strong>Preoccupation:</strong> $preoccupation</p>
            <p class="card-detail"><strong>Virtue:</strong> $virtue</p>
            <p class="card-detail"><strong>Vice:</strong> $vice</p>
          </div>
        </div>

        <div class="card-column">
          <span class="text-label">Poem</span>
          <p class="poem">$poem</p>
        </div>
      </div>
"@
  }
  else {
    $detailsHtml = @"
      <div class="card-text-block compact-card-text">
        <div class="card-column">
          <span class="text-label">Card details</span>
          <div class="card-details">
            <p class="card-detail"><strong>Series:</strong> $series</p>
            <p class="card-detail"><strong>Number:</strong> $number</p>
            <p class="card-detail"><strong>Rarity:</strong> $rarity</p>
          </div>
        </div>
      </div>
"@
  }

  return @"
    <section class="section-card" aria-labelledby="trading-card">
      <h2 id="trading-card">Trading Card</h2>

      <div class="card-grid">
        <a class="gallery-item" href="$frontPath">
          <img src="$frontPath" alt="$safeTitle trading card front" loading="lazy" />
        </a>

        <a class="gallery-item" href="$backPath">
          <img src="$backPath" alt="$safeTitle trading card back" loading="lazy" />
        </a>
      </div>

$detailsHtml
    </section>

"@
}

$commonCss = @'
  <style>
    :root{
      --border:#e5e7eb;
      --muted:#4b5563;
      --shadow:0 10px 30px rgba(0,0,0,.08);
      --radius:18px;
      --bg:#ffffff;
      --panel:#f3f4f6;
    }

    *{ box-sizing:border-box; }

    body{
      margin:0;
      font-family:system-ui,-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;
      color:#111;
      background:var(--bg);
    }

    .wrap{
      max-width:1240px;
      margin:0 auto;
      padding:28px 18px 60px;
    }

    .nav-pills{
      display:flex;
      flex-wrap:wrap;
      gap:10px;
      margin:22px 0;
    }

    .nav-pill{
      padding:8px 14px;
      border-radius:999px;
      border:1px solid var(--border);
      background:#fff;
      color:#111;
      text-decoration:none;
      font-size:14px;
    }

    .page-header{
      max-width:1100px;
      margin:0 0 28px;
    }

    .page-title{
      margin:0 0 10px;
      font-size:clamp(2rem,4vw,3rem);
      letter-spacing:-.02em;
      line-height:1.05;
    }

    .intro-text{
      max-width:1100px;
      color:var(--muted);
      font-size:18px;
      line-height:1.6;
      margin:0 0 28px;
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

    .gallery-grid,
    .card-grid{
      display:grid;
      grid-template-columns:repeat(auto-fit,minmax(220px,1fr));
      gap:20px;
    }

    .index-grid{
      margin-top:28px;
      display:grid;
      grid-template-columns:repeat(4,minmax(0,1fr));
      gap:18px;
    }

    .gallery-item{
      display:block;
      text-decoration:none;
      color:inherit;
      background:#fff;
      border:1px solid var(--border);
      border-radius:16px;
      overflow:hidden;
      box-shadow:0 4px 18px rgba(0,0,0,.04);
    }

    .gallery-item img{
      display:block;
      width:100%;
      height:280px;
      object-fit:contain;
      background:var(--panel);
      padding:8px;
      border-bottom:1px solid var(--border);
    }

    .index-grid .gallery-item img{
      height:260px;
      padding:10px;
    }

    .card-grid .gallery-item img{
      height:520px;
      padding:10px;
    }

    .entry-body{
      padding:16px 18px 18px;
      text-align:center;
    }

    .work-title{
      margin:0;
      font-size:18px;
      line-height:1.35;
      font-weight:600;
    }

    .card-text-block{
      margin-top:20px;
      padding:18px;
      border:1px solid var(--border);
      border-radius:14px;
      background:var(--panel);
      display:grid;
      grid-template-columns:minmax(240px,0.95fr) minmax(280px,1.05fr);
      gap:24px;
      align-items:start;
    }

    .compact-card-text{
      grid-template-columns:1fr;
    }

    .text-label{
      display:block;
      font-size:.78rem;
      text-transform:uppercase;
      letter-spacing:.08em;
      color:var(--muted);
      margin-bottom:8px;
    }

    .card-details{ display:grid; gap:8px; }
    .card-detail{ margin:0; line-height:1.55; }

    .poem{
      margin:0;
      white-space:pre-line;
      line-height:1.65;
    }

    .related-file-list{
      margin:0;
      padding-left:1.2rem;
      line-height:1.7;
    }

    .related-file-list a{ color:#111; }

    .back-link{ margin-top:28px; }

    .back-link a{
      display:inline-block;
      text-decoration:none;
      color:#111;
      border:1px solid var(--border);
      border-radius:999px;
      padding:10px 16px;
      background:#fff;
    }

    footer{
      margin-top:34px;
      padding-top:16px;
      border-top:1px solid var(--border);
      color:var(--muted);
      font-size:14px;
    }

    @media (max-width:1100px){
      .index-grid{ grid-template-columns:repeat(3,minmax(0,1fr)); }
    }

    @media (max-width:820px){
      .index-grid{ grid-template-columns:repeat(2,minmax(0,1fr)); }
    }

    @media (max-width:760px){
      .card-text-block{ grid-template-columns:1fr; }
    }

    @media (max-width:560px){
      .index-grid{ grid-template-columns:1fr; }
      .gallery-item img,
      .index-grid .gallery-item img{ height:260px; }
      .card-grid .gallery-item img{ height:420px; }
    }
  </style>
'@

$records = @(
  [pscustomobject]@{ Title='Alien Quack Crown'; Pattern='^Alien Quack Crown '; Preview='Alien Quack Crown COLOR.png'; Trading=$null },
  [pscustomobject]@{
    Title='Allie Quack'; Pattern='^Allie Quack '; Preview='Allie Quack COLOR.png'
    Trading=[pscustomobject]@{
      FrontFile='series 1 #11 front - DUCKS - allie quack - common.png'
      BackFile='series 1 #11 back - DUCKS - Allie Quack - common.png'
      Series='1'; Number='11'; Rarity='Common'
      Affiliation='Ducks'; Occupation='Bowling pin'; Preoccupation='Gutter balls'
      Virtue='Stand-up gal'; Vice='Not a team player'
      Poem=@'
They say them bowlers got big balls,
But bowling pins got more gall.
They say bowling is a free-for-all,
But it’s always the pins
That take the fall.
Allie Quack, girl watch your back.
A strike would be a mighty setback.
If those balls try to pick you up,
Tell those balls they’re out of luck.
Nine little pins, Allie’s next of kin,
You know those balls can’t do you in.
If you end up a rolling pin,
Pray to God you’ll be racked again.
'@
    }
  },
  [pscustomobject]@{ Title='Bub Quack'; Pattern='^Bub Quack (sketch|and Friends)'; Preview='Bub Quack sketch 7 COLOR.png'; Trading=$null },
  [pscustomobject]@{ Title='Bub Quack Guernica'; Pattern='^Bub Quack Guernica '; Preview='Bub Quack Guernica COLOR.png'; Trading=$null },
  [pscustomobject]@{
    Title='Dr. Bub Quack'; Pattern='^(Dr Bub|Dr\. Bub|Character Cards BACKS dr bub quack|Dr Bub Quack - Quack)'; Preview='Dr. Bub Quack COLOR.png'
    Trading=[pscustomobject]@{
      FrontFile='series 1 #12 front - DUCKS - dr bub quack - common.png'
      BackFile='series 1 #12 back - DUCKS - Dr bub quack - common.png'
      Series='1'; Number='12'; Rarity='Common'
      Affiliation='Ducks'; Occupation='Quack doctor'
      Preoccupation='Prescribing the placebo drug Quack to all of Delusionville'
      Virtue='Quack is the delusion that makes everyone okay with everything'
      Vice='Lies for no reason'
      Poem=@'
He lays the golden eggs
He markets as Quack—
A potent placebo that makes cattle
believe their own bull,
And all animals believe
That they know everything,
And that everything they know is true.
Maybe Bub’s a fraud
And it’s all a scam,
Maybe pigs are really ham.
But you can’t find the divine
Without sacrificing a lamb.
'@
    }
  },
  [pscustomobject]@{ Title='Duck at War'; Pattern='^Duck at War '; Preview='Duck at War COLOR.png'; Trading=$null },
  [pscustomobject]@{ Title='Duck Boat'; Pattern='^(Duck Boat|Duck boat|duckback|duckside)'; Preview='Duck Boat Front COLOR.png'; Trading=$null },
  [pscustomobject]@{ Title='Duck Fetus'; Pattern='^Duck Fetus '; Preview='Duck Fetus COLOR.png'; Trading=$null },
  [pscustomobject]@{ Title='Duck House - Riverview Estates'; Pattern='^Duck House - Riverview Estates '; Preview='Duck House - Riverview Estates COLOR.png'; Trading=$null },
  [pscustomobject]@{
    Title='Eddie Six Quack'; Pattern='^(Eddie .Six. Quack|Eddie Six Quack early version)'; Preview='Eddie “Six” Quack COLOR.jpg'
    Trading=[pscustomobject]@{
      FrontFile='series 2 #12 front - DUCKS - Eddie Six Quack - common.jpg'
      BackFile='series 2 #12 back - DUCKS - Eddie Six Quack - common.jpg'
      Series='2'; Number='12'; Rarity='Common'
      Affiliation=''; Occupation=''; Preoccupation=''; Virtue=''; Vice=''; Poem=''
    }
  },
  [pscustomobject]@{ Title='Eddie Six Quack and Football'; Pattern='^Eddie Six Quack and Football '; Preview='Eddie Six Quack and Football COLOR.png'; Trading=$null },
  [pscustomobject]@{ Title='Flying Duck'; Pattern='^Flying Duck '; Preview='Flying Duck COLOR.jpg'; Trading=$null },
  [pscustomobject]@{ Title='Football Duck'; Pattern='^Football Duck '; Preview='Football Duck COLOR.jpg'; Trading=$null },
  [pscustomobject]@{ Title='Hatch Quack'; Pattern='^Hatch Quack '; Preview='Hatch Quack COLOR.png'; Trading=$null },
  [pscustomobject]@{
    Title='Jet Quack'; Pattern='^Jet Quack '; Preview='Jet Quack Quack COLOR.jpg'
    Trading=[pscustomobject]@{
      FrontFile='series 2 #29 front - DUCKS - Jet Quack - Uncommon.jpg'
      BackFile='series 2 #29 back - DUCKS - Jet Quack - uncommon.jpg'
      Series='2'; Number='29'; Rarity='Uncommon'
      Affiliation='Ducks'; Occupation='Racecar driver'; Preoccupation='Scrambling eggs'
      Virtue='Fearless'; Vice='Daredevil'
      Poem=@'
One hundred miles an hour
Around the track,
Chasing fame
And the mighty green backs.
That’s Jet, baby, Jet Quack.
A megalomaniac with dangerous curves,
A combustible broad with catalytic nerves.
Pistons of power beneath her bonnet.
Shredding the air
Like a red-hot rocket.
Jet gives those piggies heart attacks.
When Jet is tearing
Up the track,
Get back little piggies,
Get back.
'@
    }
  },
  [pscustomobject]@{
    Title='Punk Duck'; Pattern='^Punk Duck '; Preview='Punk Duck ORIGINAL COLOR.png'
    Trading=[pscustomobject]@{
      FrontFile='series 2 #13 front - DUCKS - Punk Duck.jpg'
      BackFile='series 2 #13 back - DUCKS - Punk Duck - common.jpg'
      Series='2'; Number='13'; Rarity='Common'
      Affiliation='Ducks'; Occupation='Slam punk poet'; Preoccupation='Indoctrination'
      Virtue='Can hold a note as long as you can hold his beer'; Vice='Lyrics ain’t too clear'
      Poem=@'
Heck if he were a hen
He might give a cluck.
Evolution could have made him
An eagle,
Not a pond-bound schmuck.
But he never got any of that
Darwinian luck.
His ancestors left him
Stuck as a duck.
A mohawk sprouting
Between the plucks,
No clue, no clan,
Just a muckety muck.
Just a punk duck.
'@
    }
  },
  [pscustomobject]@{ Title='Quack Egg'; Pattern='^Quack Egg '; Preview='Quack Egg COLOR.png'; Trading=$null },
  [pscustomobject]@{ Title='Quack Guernica'; Pattern='^Quack Guernica '; Preview='Quack Guernica 1 COLOR.png'; Trading=$null },
  [pscustomobject]@{ Title='Small Duck'; Pattern='^Small Duck '; Preview='Small Duck COLOR.jpg'; Trading=$null }
)

$summary = New-Object System.Collections.Generic.List[string]
$summary.Add("DUCKS FINAL BUILD SUMMARY")
$summary.Add("Generated: $(Get-Date)")
$summary.Add("Image files found: $($imageFiles.Count)")
$summary.Add("Total files found: $($allFiles.Count)")
$summary.Add("")

$indexCards = ""
$indexCardCount = 0

foreach ($record in $records) {
  $title = $record.Title
  $safeTitle = HtmlEncode $title
  $slug = ConvertTo-Slug $title
  $pageName = "$slug.html"
  $pagePath = Join-Path $pageFolder $pageName
  $trading = $record.Trading

  $tradingNames = @()
  if ($null -ne $trading) {
    $tradingNames += $trading.FrontFile
    $tradingNames += $trading.BackFile
  }

  $matched = $allFiles |
    Where-Object { $_.Name -match $record.Pattern } |
    Where-Object { $tradingNames -notcontains $_.Name }

  $originalFiles = @()
  $digitalFiles = @()
  $relatedFiles = @()

  foreach ($file in $matched) {
    $name = $file.Name
    if ($name -match "Character Cards BACKS|Quack ain't no yoke" -or $file.Extension -notmatch "^\.(jpg|jpeg|png|webp|avif)$") {
      $relatedFiles += $name
    }
    elseif ($name -match "ORIGINAL") {
      $originalFiles += $name
    }
    else {
      $digitalFiles += $name
    }
  }

  $sections = ""

  if ($originalFiles.Count -gt 0) {
    $cards = ""
    foreach ($file in $originalFiles) {
      $cards += New-ImageCard -File $file -Alt "$title original drawing by Ron English"
    }
    $sections += @"
    <section class="section-card" aria-labelledby="original-drawings">
      <h2 id="original-drawings">Original Drawings</h2>
      <p class="section-intro">Original drawing material documented for this Ducks record.</p>
      <div class="gallery-grid">
$cards      </div>
    </section>

"@
  }
  else {
    $sections += @"
    <section class="section-card" aria-labelledby="original-drawing">
      <h2 id="original-drawing">Original Drawing</h2>
      <p class="section-intro">No original drawing is currently documented on this page. If one is located, it will be added here.</p>
    </section>

"@
  }

  if ($digitalFiles.Count -gt 0) {
    $cards = ""
    foreach ($file in $digitalFiles) {
      $cards += New-ImageCard -File $file -Alt "$title digitized version by Ron English"
    }
    $sections += @"
    <section class="section-card" aria-labelledby="digitized-versions">
      <h2 id="digitized-versions">Digitized Versions</h2>
      <div class="gallery-grid">
$cards      </div>
    </section>

"@
  }

  if ($relatedFiles.Count -gt 0) {
    $links = ""
    foreach ($file in $relatedFiles) {
      $links += New-FileLink -File $file
    }
    $sections += @"
    <section class="section-card" aria-labelledby="related-files">
      <h2 id="related-files">Related Files</h2>
      <p class="section-intro">Related source or production files associated with this record.</p>
      <ul class="related-file-list">
$links      </ul>
    </section>

"@
  }

  if ($null -ne $trading) {
    $sections += New-TradingCardSection -Trading $trading -Title $title
  }

  $detailHtml = @"
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>$safeTitle | Ducks | Ron English Catalogue Raisonné</title>
  <link rel="stylesheet" href="$cssRel" />
$commonCss
</head>

<body>
  <main class="wrap">
    <nav class="nav-pills" aria-label="Site navigation">
      <a class="nav-pill" href="https://ronenglish-archive.github.io/ron-english-catalogue-raisonne/">Catalogue home</a>
      <a class="nav-pill" href="../../index.html">Sketches</a>
      <a class="nav-pill" href="../index.html">Avians</a>
      <a class="nav-pill" href="index.html">Ducks</a>
    </nav>

    <header class="page-header">
      <h1 class="page-title">$safeTitle</h1>
    </header>

$sections    <div class="back-link">
      <a href="index.html">← Back to Ducks</a>
    </div>
  </main>
</body>
</html>
"@

  Set-Content -LiteralPath $pagePath -Value $detailHtml -Encoding UTF8

  $preview = $null
  if ($record.Preview -and ($allFiles | Where-Object { $_.Name -eq $record.Preview } | Select-Object -First 1)) {
    $preview = $record.Preview
  }
  if (-not $preview) { $preview = $digitalFiles | Where-Object { $_ -match "COLOR" } | Select-Object -First 1 }
  if (-not $preview) { $preview = $originalFiles | Where-Object { $_ -match "COLOR" } | Select-Object -First 1 }
  if (-not $preview) { $preview = $digitalFiles | Select-Object -First 1 }
  if (-not $preview) { $preview = $originalFiles | Select-Object -First 1 }
  if (-not $preview -and $null -ne $trading) { $preview = $trading.FrontFile }

  if ($preview) {
    $previewPath = SafeSrc $preview
    $safeAlt = HtmlEncode "$title by Ron English"
    $indexCards += @"
      <a class="gallery-item" href="$pageName">
        <img src="$previewPath" alt="$safeAlt" loading="lazy" />
        <div class="entry-body">
          <p class="work-title">$safeTitle</p>
        </div>
      </a>

"@
    $indexCardCount++
  }

  $summary.Add($title)
  $summary.Add("  Matched files: $($matched.Count)")
  $summary.Add("  Originals: $($originalFiles.Count)")
  $summary.Add("  Digitized: $($digitalFiles.Count)")
  $summary.Add("  Related: $($relatedFiles.Count)")
  $summary.Add("  Preview: $preview")
  $summary.Add("  Page: $pageName")
  $summary.Add("")
}

$indexHtml = @"
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Ducks | Avians | Ron English Catalogue Raisonné</title>
  <link rel="stylesheet" href="$cssRel" />
$commonCss
</head>

<body>
  <main class="wrap">
    <nav class="nav-pills" aria-label="Site navigation">
      <a class="nav-pill" href="https://ronenglish-archive.github.io/ron-english-catalogue-raisonne/">Catalogue home</a>
      <a class="nav-pill" href="../../index.html">Sketches</a>
      <a class="nav-pill" href="../index.html">Avians</a>
    </nav>

    <header class="page-header">
      <h1 class="page-title">Ducks</h1>
    </header>

    <p class="intro-text">
      Duck-related drawings from the Ron English archive, including original drawings, digitized versions, trading cards, and related character studies where available.
    </p>

    <section class="index-grid" aria-label="Duck drawings">
$indexCards    </section>

    <footer>
      Published via GitHub Pages for long-term public access.
    </footer>
  </main>
</body>
</html>
"@

Set-Content -LiteralPath (Join-Path $pageFolder "index.html") -Value $indexHtml -Encoding UTF8
$summary | Set-Content -LiteralPath $summaryFile -Encoding UTF8

Write-Host ""
Write-Host "DONE - DUCKS FINAL BUILD FROM PS1 FILE"
Write-Host "Index cards created:" $indexCardCount
Write-Host ""
Write-Host "Summary written to:"
Write-Host $summaryFile
Write-Host ""
Write-Host "Current HTML files:"
Get-ChildItem -LiteralPath $pageFolder -Filter "*.html" | Sort-Object Name | ForEach-Object {
  Write-Host " - $($_.Name)"
}
Write-Host ""
Write-Host "Open exactly:"
Write-Host (Join-Path $pageFolder "index.html")
