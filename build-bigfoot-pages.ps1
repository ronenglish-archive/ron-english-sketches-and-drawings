# build-bigfoot-pages.ps1
# Ron English Sketches and Drawings Catalogue
# Builds the Bigfoot category from the actual image folder.
# Safe behavior:
# - Preserves exact image filenames.
# - Scans images\Sketches\bigfoot and groups files by character/page.
# - Uses the standard no-original Original Drawing section when no ORIGINAL file exists.
# - Backs up existing HTML files before overwriting.
# - Creates a build report in Sketches\bigfoot\_reports.
# - Does not overwrite Sketches\index.html.

$ErrorActionPreference = 'Stop'

$RepoRoot = 'D:\github\ron-english-sketches-and-drawings'
$ImageDir = Join-Path $RepoRoot 'images\Sketches\bigfoot'
$HtmlDir  = Join-Path $RepoRoot 'Sketches\bigfoot'
$ReportDir = Join-Path $HtmlDir '_reports'

$NoOriginalText = 'No original drawing is currently documented on this page. If one is located, it will be added here.'
$ImageExtensions = @('.jpg', '.jpeg', '.png', '.webp', '.gif')

$PageDefinitions = @(
  @{ Title = 'Lady Bigfoot'; Slug = 'lady-bigfoot.html'; Patterns = @('^Lady Bigfoot ') },
  @{ Title = 'Bigfoot Footprint'; Slug = 'bigfoot-footprint.html'; Patterns = @('^Bigfoot Footprint ') },
  @{ Title = 'Little Bigfoot'; Slug = 'little-bigfoot.html'; Patterns = @('^Little Bigfoot ') },
  @{ Title = 'Urban Bigfoot'; Slug = 'urban-bigfoot.html'; Patterns = @('^Urban Bigfoot 1 ', '^Urban Bigfoot right side 1 ', '^series 1 #52 ') },
  @{ Title = 'Bigfoot Living Room'; Slug = 'bigfoot-living-room.html'; Patterns = @('^Bigfoot Living Room ') },
  @{ Title = 'Bigfoot Messiah'; Slug = 'bigfoot-messiah.html'; Patterns = @('^Bigfoot Messiah ') },
  @{ Title = 'Midget Bigfoot'; Slug = 'midget-bigfoot.html'; Patterns = @('^Midget Bigfoot ', '^series 2 #38 ') },
  @{ Title = 'Bigfoot Tourist'; Slug = 'bigfoot-tourist.html'; Patterns = @('^Bigfoot Tourist ') },
  @{ Title = "Li'l Bigfoot with Beard"; Slug = 'lil-bigfoot-with-beard.html'; Patterns = @("^Li'l Bigfoot with beard ") },
  @{ Title = "Li'l Bigfoot"; Slug = 'lil-bigfoot.html'; Patterns = @("^Li'l Bigfoot (B&W|COLOR|ORIGINAL|card)", '^series 1 #36 ') },
  @{ Title = 'Bigfoot Feet'; Slug = 'bigfoot-feet.html'; Patterns = @('^Bigfoot feet ') },
  @{ Title = 'Urban Bigfoot with Hoodie'; Slug = 'urban-bigfoot-with-hoodie.html'; Patterns = @('^Urban Bigfoot with Hoodie ') },
  @{ Title = 'Fake Father Bigfoot'; Slug = 'fake-father-bigfoot.html'; Patterns = @('^Fake Father Bigfoot ', '^series 2 #6 ') },
  @{ Title = 'New Urban Bigfoot'; Slug = 'new-urban-bigfoot.html'; Patterns = @('^New Urban Bigfoot ') },
  @{ Title = 'Bigfoot Toddler'; Slug = 'bigfoot-toddler.html'; Patterns = @('^Bigfoot Toddler ') },
  @{ Title = 'Myth Mother Bigfoot'; Slug = 'myth-mother-bigfoot.html'; Patterns = @('^Myth Mother Bigfoot ', '^series 2 #7 ') },
  @{ Title = 'Washington Bigfoot'; Slug = 'washington-bigfoot.html'; Patterns = @('^Washington Bigfoot ') }
)

$CardInfo = @{}

$CardInfo['lil-bigfoot.html'] = @{
  Details = @(
    @{ Label = 'Affiliation'; Value = 'Bigfoots' },
    @{ Label = 'Occupation'; Value = 'Outfitting urban' },
    @{ Label = 'Preoccupation'; Value = 'Urban bigfoot' },
    @{ Label = 'Virtue'; Value = 'Cute' },
    @{ Label = 'Vice'; Value = 'Too cute' }
  )
  Poem = @'
Bigfoots stand tall,
Even though they were born real small.
Taller than a basketball player
On top of an elevator.
Why, they can even look over
The great China wall.
The bigger they are
The harder they crawl.
A big-gaited stride
Comes before the fall.
But once upon a time
Bigfoot was so little,
Obsessed with mama's nipple,
Playing second fiddle
To wanna be Neanderthals.
'@
}

$CardInfo['urban-bigfoot.html'] = @{
  Details = @(
    @{ Label = 'Affiliation'; Value = 'Bigfoots' },
    @{ Label = 'Occupation'; Value = 'Hiding in plain sight' },
    @{ Label = 'Preoccupation'; Value = 'Blending in' },
    @{ Label = 'Virtue'; Value = 'Can stay in focus for short periods of time' },
    @{ Label = 'Vice'; Value = 'Hates the forest' }
  )
  Poem = @'
I ain't never seen a UFO,
A pie in the sky, a golden rainbow.
Never sighted Elvis,
Or any bare-naked streakers,
No elves or angels, no mythical creatures.
I ain't looking for any spiritual seekers.
Gorillas are in jungles,
Not in high-top sneakers.
I never believed in no fairy tales,
No sea mobsters with magical scales,
No fire-breathing dragons,
No Jonahs in whales.
I certainly don't believe the check's in the mail.
I can't imagine farther than my mind can see.
I don't believe in Urban Bigfoot,
But he believes in me.
'@
}

$CardInfo['fake-father-bigfoot.html'] = @{
  Details = @(
    @{ Label = 'Affiliation'; Value = 'Bigfoots' },
    @{ Label = 'Occupation'; Value = 'Being a Bigfoot' },
    @{ Label = 'Preoccupation'; Value = 'Being famous' },
    @{ Label = 'Virtue'; Value = 'Can go out of focus' },
    @{ Label = 'Vice'; Value = "Can't focus" }
  )
  Poem = @'
They say my bigfoot father is just a fake.
If so my existence is a total mistake.
Maybe Eve just made up the snake.
Maybe Cathy Cowgirl
Just cooked up the steak.
Maybe myths are just baked in the cake.
But there are things you can dream
While you are still awake.
You can speed towards the cliffs
If you believe in your brakes.
You can shake up the milk,
You can rattle the snake,
But no mobster will give up the take.
And nothing is more real
Than the original fake.
'@
}

$CardInfo['myth-mother-bigfoot.html'] = @{
  Details = @(
    @{ Label = 'Affiliation'; Value = 'Bigfoots' },
    @{ Label = 'Occupation'; Value = 'Bigfoot breeder' },
    @{ Label = 'Preoccupation'; Value = 'Improving her image' },
    @{ Label = 'Virtue'; Value = 'Bathes once a year' },
    @{ Label = 'Vice'; Value = 'Fools around with monkeys' }
  )
  Poem = @'
I don't remember mother
As more than a blur-
Woods full of hunters in search of her.
She was the holy grail
For all truth seekers.
But she was mostly sighted
By some methhead tweekers.
My mother was beautiful
With out-of-focus features,
More stealthy
Than all the woodland creatures.
She was not the myth
Taught by the preachers.
My mother only existed
For the true believers.
'@
}

$CardInfo['midget-bigfoot.html'] = @{
  Details = @(
    @{ Label = 'Affiliation'; Value = 'Bigfoots' },
    @{ Label = 'Occupation'; Value = 'Being a bigfoot' },
    @{ Label = 'Preoccupation'; Value = 'His small stature' },
    @{ Label = 'Virtue'; Value = 'Can stay out of focus' },
    @{ Label = 'Vice'; Value = 'He is just an over-hyped monkey' }
  )
  Poem = @'
One tall tale
Short of the imagination.
One syllable short
Of an abbreviation.
One soul lost beyond the unknown.
Weighing in at less than 15 stone,
Hair long enough to cover his bones.
An over-active mythology out on loan.
One river short of a brook,
One page short, short of a book.
One scam short, short of a crook.
One glance short, short of a look.
That ain't no monkey, no,
That's a midget bigfoot.
'@
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

function Get-Kind {
  param([System.IO.FileInfo]$File)
  $n = $File.Name.ToLowerInvariant()
  if ($n -match '(^| )series [0-9]| card\.') { return 'Card' }
  if ($n -match 'original') { return 'Original' }
  return 'Digital'
}

function Get-ViewOrder {
  param([string]$Name)
  $n = $Name.ToLowerInvariant()
  if ($n -match 'front') { return 10 }
  if ($n -match 'back') { return 20 }
  if ($n -match 'left') { return 30 }
  if ($n -match 'right') { return 40 }
  if ($n -match 'side') { return 50 }
  if ($n -match 'three quarters') { return 60 }
  return 90
}

function Get-VersionOrder {
  param([string]$Name)
  $n = $Name.ToLowerInvariant()
  if ($n -match ' card\.') { return 0 }
  if ($n -match 'front') { return 1 }
  if ($n -match 'back') { return 2 }
  if ($n -match 'b&w|b&w|b & w') { return 3 }
  if ($n -match 'original' -and $n -notmatch 'color|colored') { return 4 }
  if ($n -match 'color|colored') { return 5 }
  return 9
}

function Get-ImageLabel {
  param(
    [System.IO.FileInfo]$File,
    [string]$Kind
  )
  $n = $File.Name.ToLowerInvariant()
  $view = ''
  if ($n -match 'front') { $view = 'Front ' }
  elseif ($n -match 'back') { $view = 'Back ' }
  elseif ($n -match 'left side') { $view = 'Left side ' }
  elseif ($n -match 'right side') { $view = 'Right side ' }
  elseif ($n -match 'side') { $view = 'Side ' }
  elseif ($n -match 'three quarters') { $view = 'Three-quarter ' }

  if ($Kind -eq 'Original') {
    if ($n -match 'color|colored') { return ($view + 'original color drawing').Trim() }
    return ($view + 'original drawing').Trim()
  }

  if ($Kind -eq 'Card') {
    if ($n -match 'front') { return 'Trading card front' }
    if ($n -match 'back') { return 'Trading card back' }
    return 'Collector card'
  }

  if ($n -match 'b&w|b & w') { return ($view + 'B and W digital version').Trim() }
  if ($n -match 'color|colored') { return ($view + 'color digital version').Trim() }
  return ($view + 'digital version').Trim()
}

function Get-ThumbFile {
  param([array]$Files)
  $nonCards = @($Files | Where-Object { (Get-Kind $_) -ne 'Card' })
  if ($nonCards.Count -eq 0) { $nonCards = @($Files) }

  $choice = @($nonCards | Where-Object { $_.Name -match '(?i)front.*color' } | Sort-Object Name | Select-Object -First 1)
  if ($choice.Count -gt 0) { return $choice[0] }

  $choice = @($nonCards | Where-Object { $_.Name -match '(?i)color|colored' } | Sort-Object Name | Select-Object -First 1)
  if ($choice.Count -gt 0) { return $choice[0] }

  $choice = @($nonCards | Where-Object { $_.Name -match '(?i)original' } | Sort-Object Name | Select-Object -First 1)
  if ($choice.Count -gt 0) { return $choice[0] }

  $choice = @($nonCards | Where-Object { $_.Name -match '(?i)front' } | Sort-Object Name | Select-Object -First 1)
  if ($choice.Count -gt 0) { return $choice[0] }

  return @($nonCards | Sort-Object Name | Select-Object -First 1)[0]
}

function Get-SharedHead {
  param([string]$Title)
  return @"
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>$Title | Bigfoot | Ron English Catalogue Raisonn&eacute;</title>
  <link rel="stylesheet" href="../../css/styles.css" />
  <style>
    :root{--border:#e5e7eb;--muted:#4b5563;--shadow:0 10px 30px rgba(0,0,0,.08);--radius:18px;--bg:#ffffff;--panel:#f3f4f6;--pill-hover:#f9fafb;}
    *{box-sizing:border-box;}
    html{scroll-behavior:smooth;}
    body{margin:0;font-family:system-ui,-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;color:#111;background:var(--bg);}
    .wrap{max-width:1240px;margin:0 auto;padding:28px 18px 60px;}
    .page-narrow{max-width:1100px;}
    .nav-pills{display:flex;flex-wrap:wrap;gap:10px;margin:22px 0;}
    .nav-pill{padding:8px 14px;border-radius:999px;border:1px solid var(--border);background:#fff;color:#111;text-decoration:none;font-size:14px;transition:background .12s ease,border-color .12s ease,transform .12s ease;}
    .nav-pill:hover{background:var(--pill-hover);border-color:#d1d5db;transform:translateY(-1px);}
    .page-header{max-width:1100px;margin:0 0 28px;padding:0;text-align:left;}
    .page-title{margin:0 0 10px;font-size:clamp(2rem,4vw,3rem);letter-spacing:-.02em;line-height:1.05;}
    .intro-text{max-width:1100px;margin:0 0 28px;padding:0;line-height:1.6;text-align:left;}
    .intro-text p{margin:0 0 14px;max-width:none;width:100%;color:var(--muted);font-size:18px;}
    .section-card{background:#fff;border:1px solid var(--border);border-radius:var(--radius);box-shadow:var(--shadow);padding:22px;margin-bottom:24px;}
    .section-card h2{margin:0 0 8px;font-size:1.4rem;}
    .section-intro{margin:0;color:var(--muted);line-height:1.6;}
    .index-grid{margin-top:28px;display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:18px;}
    .gallery-grid,.card-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:20px;}
    .originals-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:20px;}
    .gallery-item{display:block;text-decoration:none;color:inherit;background:#fff;border:1px solid var(--border);border-radius:16px;overflow:hidden;box-shadow:0 4px 18px rgba(0,0,0,.04);margin:0;transition:transform .12s ease,box-shadow .12s ease,border-color .12s ease;}
    .gallery-item:hover{transform:translateY(-2px);box-shadow:0 16px 40px rgba(0,0,0,.12);border-color:#d1d5db;}
    .gallery-item a{display:block;color:inherit;text-decoration:none;}
    .gallery-item img{display:block;width:100%;object-fit:contain;background:var(--panel);padding:8px;border-bottom:1px solid var(--border);}
    .index-grid .gallery-item img{height:260px;padding:10px;}
    .gallery-grid .gallery-item img{height:300px;}
    .originals-grid .gallery-item img{height:440px;}
    .card-grid .gallery-item img{height:520px;padding:10px;}
    .entry-body{padding:16px 18px 18px;display:flex;flex-direction:column;align-items:center;justify-content:center;text-align:center;}
    .work-title{margin:0;padding:0;width:100%;font-size:18px;line-height:1.35;font-weight:600;text-align:center;}
    .work-subtitle{margin:6px 0 0;padding:0;width:100%;font-size:14px;line-height:1.45;color:var(--muted);text-align:center;}
    .image-caption{padding:10px 12px 12px;font-size:14px;line-height:1.45;color:var(--muted);text-align:center;}
    .card-text-block{margin-top:20px;padding:18px;border:1px solid var(--border);border-radius:14px;background:var(--panel);display:grid;grid-template-columns:minmax(240px,.95fr) minmax(280px,1.05fr);gap:24px;align-items:start;}
    .compact-card-text{grid-template-columns:1fr;}
    .text-label{display:block;font-size:.78rem;text-transform:uppercase;letter-spacing:.08em;color:var(--muted);margin-bottom:8px;}
    .card-details{display:grid;gap:8px;}.card-detail{margin:0;line-height:1.55;}.poem{margin:0;white-space:pre-line;line-height:1.65;}
    .back-link{margin-top:28px;}.back-link a{display:inline-block;text-decoration:none;color:#111;border:1px solid var(--border);border-radius:999px;padding:10px 16px;background:#fff;}.back-link a:hover{background:#f9fafb;}
    footer{margin-top:34px;padding-top:16px;border-top:1px solid var(--border);color:var(--muted);font-size:14px;}
    @media (max-width:1100px){.index-grid{grid-template-columns:repeat(3,minmax(0,1fr));}}
    @media (max-width:820px){.index-grid{grid-template-columns:repeat(2,minmax(0,1fr));}.card-text-block{grid-template-columns:1fr;}}
    @media (max-width:560px){.wrap{padding:22px 14px 50px;}.index-grid,.gallery-grid,.card-grid,.originals-grid{grid-template-columns:1fr;}.index-grid .gallery-item img,.gallery-grid .gallery-item img{height:260px;}.originals-grid .gallery-item img{height:340px;}.card-grid .gallery-item img{height:420px;}}
  </style>
</head>
"@
}

function Add-ImageCard {
  param(
    [System.Text.StringBuilder]$Builder,
    [System.IO.FileInfo]$File,
    [string]$Kind,
    [string]$AltPrefix
  )
  $path = Convert-ToWebPath -FromHtmlDir $HtmlDir -FullImagePath $File.FullName
  $pathAttr = HtmlEncode $path
  $label = HtmlEncode (Get-ImageLabel -File $File -Kind $Kind)
  $alt = HtmlEncode ($AltPrefix + ' ' + (Get-ImageLabel -File $File -Kind $Kind) + ' by Ron English')
  [void]$Builder.AppendLine('        <figure class="gallery-item">')
  [void]$Builder.AppendLine('          <a href="' + $pathAttr + '" target="_blank" rel="noopener noreferrer">')
  [void]$Builder.AppendLine('            <img src="' + $pathAttr + '" alt="' + $alt + '" loading="lazy" />')
  [void]$Builder.AppendLine('          </a>')
  [void]$Builder.AppendLine('          <figcaption class="image-caption">' + $label + '</figcaption>')
  [void]$Builder.AppendLine('        </figure>')
}

function Add-CardTextBlock {
  param(
    [System.Text.StringBuilder]$Builder,
    [hashtable]$Info
  )
  if ($null -eq $Info) { return }
  $details = @($Info.Details)
  $poem = [string]$Info.Poem
  $hasDetails = $details.Count -gt 0
  $hasPoem = ![string]::IsNullOrWhiteSpace($poem)
  if (!$hasDetails -and !$hasPoem) { return }
  $className = 'card-text-block'
  if (!$hasDetails -or !$hasPoem) { $className = 'card-text-block compact-card-text' }
  [void]$Builder.AppendLine('')
  [void]$Builder.AppendLine('      <div class="' + $className + '">')
  if ($hasDetails) {
    [void]$Builder.AppendLine('        <div class="card-column">')
    [void]$Builder.AppendLine('          <span class="text-label">Card details</span>')
    [void]$Builder.AppendLine('          <div class="card-details">')
    foreach ($detail in $details) {
      [void]$Builder.AppendLine('            <p class="card-detail"><strong>' + (HtmlEncode $detail.Label) + ':</strong> ' + (HtmlEncode $detail.Value) + '</p>')
    }
    [void]$Builder.AppendLine('          </div>')
    [void]$Builder.AppendLine('        </div>')
  }
  if ($hasPoem) {
    [void]$Builder.AppendLine('')
    [void]$Builder.AppendLine('        <div class="card-column">')
    [void]$Builder.AppendLine('          <span class="text-label">Poem</span>')
    [void]$Builder.AppendLine('          <p class="poem">' + (HtmlEncode $poem.Trim()) + '</p>')
    [void]$Builder.AppendLine('        </div>')
  }
  [void]$Builder.AppendLine('      </div>')
}

function Build-IndexPage {
  param([array]$Groups)
  $html = New-Object System.Text.StringBuilder
  [void]$html.AppendLine((Get-SharedHead -Title 'Bigfoot | Sketches and Drawings'))
  [void]$html.AppendLine('<body>')
  [void]$html.AppendLine('  <main class="wrap">')
  [void]$html.AppendLine('    <nav class="nav-pills" aria-label="Site navigation">')
  [void]$html.AppendLine('      <a class="nav-pill" href="https://ronenglish-archive.github.io/ron-english-catalogue-raisonne/">Catalogue home</a>')
  [void]$html.AppendLine('      <a class="nav-pill" href="../index.html">Sketches</a>')
  [void]$html.AppendLine('      <a class="nav-pill" href="index.html">Bigfoot</a>')
  [void]$html.AppendLine('    </nav>')
  [void]$html.AppendLine('    <header class="page-header"><h1 class="page-title">Bigfoot</h1></header>')
  [void]$html.AppendLine('    <section class="intro-text"><p>Bigfoot character drawings from the Ron English archive, including original drawings, digitized versions, turnarounds, and related card material where available.</p></section>')
  [void]$html.AppendLine('    <section class="index-grid" aria-label="Bigfoot sketches">')
  foreach ($group in $Groups) {
    $thumb = Get-ThumbFile -Files $group.Files
    $thumbPath = Convert-ToWebPath -FromHtmlDir $HtmlDir -FullImagePath $thumb.FullName
    $thumbPathAttr = HtmlEncode $thumbPath
    $title = HtmlEncode $group.Title
    $slug = HtmlEncode $group.Slug
    $count = @($group.Files).Count
    $plural = 's'
    if ($count -eq 1) { $plural = '' }
    [void]$html.AppendLine('')
    [void]$html.AppendLine('      <a class="gallery-item" href="' + $slug + '">')
    [void]$html.AppendLine('        <img src="' + $thumbPathAttr + '" alt="' + $title + ' by Ron English" loading="lazy" />')
    [void]$html.AppendLine('        <div class="entry-body"><p class="work-title">' + $title + '</p><p class="work-subtitle">' + $count + ' image' + $plural + '</p></div>')
    [void]$html.AppendLine('      </a>')
  }
  [void]$html.AppendLine('')
  [void]$html.AppendLine('    </section>')
  [void]$html.AppendLine('    <footer>Published via GitHub Pages for long-term public access.</footer>')
  [void]$html.AppendLine('  </main>')
  [void]$html.AppendLine('</body>')
  [void]$html.AppendLine('</html>')
  return $html.ToString()
}

function Build-CharacterPage {
  param([pscustomobject]$Group)
  $title = HtmlEncode $Group.Title
  $originals = @($Group.Files | Where-Object { (Get-Kind $_) -eq 'Original' } | Sort-Object @{Expression={Get-ViewOrder $_.Name}}, @{Expression={Get-VersionOrder $_.Name}}, Name)
  $digitals = @($Group.Files | Where-Object { (Get-Kind $_) -eq 'Digital' } | Sort-Object @{Expression={Get-ViewOrder $_.Name}}, @{Expression={Get-VersionOrder $_.Name}}, Name)
  $cards = @($Group.Files | Where-Object { (Get-Kind $_) -eq 'Card' } | Sort-Object @{Expression={Get-VersionOrder $_.Name}}, Name)
  $html = New-Object System.Text.StringBuilder
  [void]$html.AppendLine((Get-SharedHead -Title $title))
  [void]$html.AppendLine('<body>')
  [void]$html.AppendLine('  <main class="wrap page-narrow">')
  [void]$html.AppendLine('    <nav class="nav-pills" aria-label="Site navigation">')
  [void]$html.AppendLine('      <a class="nav-pill" href="https://ronenglish-archive.github.io/ron-english-catalogue-raisonne/">Catalogue home</a>')
  [void]$html.AppendLine('      <a class="nav-pill" href="../index.html">Sketches</a>')
  [void]$html.AppendLine('      <a class="nav-pill" href="index.html">Bigfoot</a>')
  [void]$html.AppendLine('    </nav>')
  [void]$html.AppendLine('    <header class="page-header"><h1 class="page-title">' + $title + '</h1></header>')
  [void]$html.AppendLine('')
  [void]$html.AppendLine('    <section class="section-card" aria-labelledby="original-drawing">')
  [void]$html.AppendLine('      <h2 id="original-drawing">Original Drawing</h2>')
  if ($originals.Count -gt 0) {
    [void]$html.AppendLine('      <div class="originals-grid">')
    foreach ($file in $originals) { Add-ImageCard -Builder $html -File $file -Kind 'Original' -AltPrefix $Group.Title; [void]$html.AppendLine('') }
    [void]$html.AppendLine('      </div>')
  } else {
    [void]$html.AppendLine('      <p class="section-intro">' + (HtmlEncode $NoOriginalText) + '</p>')
  }
  [void]$html.AppendLine('    </section>')
  [void]$html.AppendLine('')
  if ($digitals.Count -gt 0) {
    [void]$html.AppendLine('    <section class="section-card" aria-labelledby="digitized-versions">')
    [void]$html.AppendLine('      <h2 id="digitized-versions">Digitized Versions</h2>')
    [void]$html.AppendLine('      <div class="gallery-grid">')
    foreach ($file in $digitals) { Add-ImageCard -Builder $html -File $file -Kind 'Digital' -AltPrefix $Group.Title; [void]$html.AppendLine('') }
    [void]$html.AppendLine('      </div>')
    [void]$html.AppendLine('    </section>')
    [void]$html.AppendLine('')
  }
  if ($cards.Count -gt 0) {
    [void]$html.AppendLine('    <section class="section-card" aria-labelledby="collector-cards">')
    [void]$html.AppendLine('      <h2 id="collector-cards">Collector Cards</h2>')
    [void]$html.AppendLine('      <div class="card-grid">')
    foreach ($file in $cards) { Add-ImageCard -Builder $html -File $file -Kind 'Card' -AltPrefix $Group.Title; [void]$html.AppendLine('') }
    [void]$html.AppendLine('      </div>')
    if ($CardInfo.ContainsKey($Group.Slug)) { Add-CardTextBlock -Builder $html -Info $CardInfo[$Group.Slug] }
    [void]$html.AppendLine('    </section>')
    [void]$html.AppendLine('')
  }
  [void]$html.AppendLine('    <div class="back-link"><a href="index.html">&larr; Back to Bigfoot</a></div>')
  [void]$html.AppendLine('  </main>')
  [void]$html.AppendLine('</body>')
  [void]$html.AppendLine('</html>')
  return $html.ToString()
}

Ensure-Folder $HtmlDir
Ensure-Folder $ReportDir

if (!(Test-Path $ImageDir)) {
  Write-Host ''
  Write-Host 'ERROR: Bigfoot image folder not found:' -ForegroundColor Red
  Write-Host $ImageDir -ForegroundColor Yellow
  Write-Host ''
  exit 1
}

$files = @(Get-ChildItem -Path $ImageDir -File | Where-Object { $ImageExtensions -contains $_.Extension.ToLowerInvariant() } | Sort-Object Name)
if ($files.Count -eq 0) {
  Write-Host ''
  Write-Host 'No image files found in:' -ForegroundColor Yellow
  Write-Host $ImageDir
  Write-Host ''
  exit 1
}

$groups = New-Object System.Collections.Generic.List[object]
$used = New-Object System.Collections.Generic.HashSet[string]
$ungrouped = New-Object System.Collections.Generic.List[object]

foreach ($def in $PageDefinitions) {
  $matched = @()
  foreach ($file in $files) {
    foreach ($pattern in $def.Patterns) {
      if ($file.Name -match $pattern) {
        $matched += $file
        [void]$used.Add($file.FullName)
        break
      }
    }
  }
  $matched = @($matched | Sort-Object @{Expression={Get-Kind $_}}, @{Expression={Get-ViewOrder $_.Name}}, @{Expression={Get-VersionOrder $_.Name}}, Name -Unique)
  if ($matched.Count -eq 0) {
    Write-Host ''
    Write-Host ('STOPPED: No files found for page group: ' + $def.Title) -ForegroundColor Red
    Write-Host 'No HTML pages were written.' -ForegroundColor Yellow
    exit 1
  }
  $groups.Add([pscustomobject]@{ Title = $def.Title; Slug = $def.Slug; Files = $matched })
}

foreach ($file in $files) {
  if (!$used.Contains($file.FullName)) {
    $ungrouped.Add($file)
  }
}

$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$reportRows = New-Object System.Collections.Generic.List[object]
foreach ($group in $groups) {
  foreach ($file in $group.Files) {
    $reportRows.Add([pscustomobject]@{
      Status = 'Grouped'
      Character = $group.Title
      Page = $group.Slug
      Section = Get-Kind $file
      File = $file.Name
      FullPath = $file.FullName
    })
  }
}
foreach ($file in $ungrouped) {
  $reportRows.Add([pscustomobject]@{
    Status = 'Ungrouped'
    Character = ''
    Page = ''
    Section = ''
    File = $file.Name
    FullPath = $file.FullName
  })
}

$csvPath = Join-Path $ReportDir 'bigfoot-build-report.csv'
$txtPath = Join-Path $ReportDir 'bigfoot-build-summary.txt'
$reportRows | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

$summary = @()
$summary += 'Bigfoot build report'
$summary += "Generated: $timestamp"
$summary += ''
$summary += "Image folder: $ImageDir"
$summary += "HTML folder:  $HtmlDir"
$summary += ''
$summary += ('Image files found: ' + $files.Count)
$summary += ('Page groups built: ' + $groups.Count)
$summary += ('Ungrouped files: ' + $ungrouped.Count)
$summary += ''
$summary += 'Pages created or updated:'
$summary += '- Sketches\bigfoot\index.html'
foreach ($group in $groups) { $summary += ('- Sketches\bigfoot\' + $group.Slug + ' - ' + $group.Title) }
$summary += ''
$summary += 'Pages using the no-original standard:'
foreach ($group in $groups) {
  $originals = @($group.Files | Where-Object { (Get-Kind $_) -eq 'Original' })
  if ($originals.Count -eq 0) { $summary += ('- ' + $group.Title) }
}
if ($ungrouped.Count -gt 0) {
  $summary += ''
  $summary += 'Ungrouped files to review:'
  foreach ($file in $ungrouped) { $summary += ('- ' + $file.Name) }
}
$summary | Set-Content -Path $txtPath -Encoding UTF8

$indexPath = Join-Path $HtmlDir 'index.html'
Backup-IfExists $indexPath
Build-IndexPage -Groups $groups | Set-Content -Path $indexPath -Encoding UTF8

foreach ($group in $groups) {
  $pagePath = Join-Path $HtmlDir $group.Slug
  Backup-IfExists $pagePath
  Build-CharacterPage -Group $group | Set-Content -Path $pagePath -Encoding UTF8
}

Write-Host ''
Write-Host 'Bigfoot pages built successfully.' -ForegroundColor Green
Write-Host ''
Write-Host 'Created or updated:'
Write-Host " - $indexPath"
foreach ($group in $groups) { Write-Host (' - ' + (Join-Path $HtmlDir $group.Slug)) }
Write-Host ''
Write-Host 'Reports:'
Write-Host " - $csvPath"
Write-Host " - $txtPath"
Write-Host ''
Write-Host 'No-original standard applied to:' -ForegroundColor Yellow
foreach ($group in $groups) {
  $originals = @($group.Files | Where-Object { (Get-Kind $_) -eq 'Original' })
  if ($originals.Count -eq 0) { Write-Host (' - ' + $group.Title) }
}
if ($ungrouped.Count -gt 0) {
  Write-Host ''
  Write-Host 'Some files were not grouped. Review the report before pushing.' -ForegroundColor Yellow
}
Write-Host ''
