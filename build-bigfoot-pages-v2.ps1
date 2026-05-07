# build-bigfoot-pages-v2.ps1
# Ron English Sketches and Drawings Catalogue
#
# V2 updates:
# - Removes the image-count text from the Bigfoot index cards.
# - Removes captions/text below images on individual pages.
# - Adds Bigfoot Family Icon as its own Bigfoot page.
# - Moves Bigfoot Footprint ORIGINAL.jpg into the Bigfoot Feet page.
# - Archives the old standalone bigfoot-footprint.html page if it exists.
# - Splits collector-card sections so trading-card front/back images sit two per row,
#   with any extra no-info collector card placed below.
# - Ensures trading-card images are included for Urban Bigfoot, Li'l Bigfoot,
#   Fake Father Bigfoot, Myth Mother Bigfoot, and Midget Bigfoot.
#
# Safe behavior:
# - Preserves exact image filenames.
# - Checks every expected image before writing HTML.
# - Backs up existing HTML files before overwriting.
# - Creates a build report in Sketches\bigfoot\_reports.

$ErrorActionPreference = 'Stop'

$RepoRoot = 'D:\github\ron-english-sketches-and-drawings'
$ImageDir = Join-Path $RepoRoot 'images\Sketches\bigfoot'
$HtmlDir  = Join-Path $RepoRoot 'Sketches\bigfoot'
$ReportDir = Join-Path $HtmlDir '_reports'

$NoOriginalText = 'No original drawing is currently documented on this page. If one is located, it will be added here.'

$Pages = @(
  @{
    Title = 'Lady Bigfoot'
    Slug = 'lady-bigfoot.html'
    Thumb = 'Lady Bigfoot COLOR.jpg'
    Originals = @(
      @{ File = 'Lady Bigfoot ORIGINAL.jpg'; Alt = 'Lady Bigfoot original drawing by Ron English' }
    )
    Digitals = @(
      @{ File = 'Lady Bigfoot B&W.jpg'; Alt = 'Lady Bigfoot black-and-white digital version by Ron English' },
      @{ File = 'Lady Bigfoot COLOR.jpg'; Alt = 'Lady Bigfoot color digital version by Ron English' }
    )
    TradingCards = @()
    AdditionalCards = @()
    CardDetails = @()
    Poem = ''
  },
  @{
    Title = 'Little Bigfoot'
    Slug = 'little-bigfoot.html'
    Thumb = 'Little Bigfoot COLOR.jpg'
    Originals = @(
      @{ File = 'Little Bigfoot ORIGINAL.jpg'; Alt = 'Little Bigfoot original drawing by Ron English' }
    )
    Digitals = @(
      @{ File = 'Little Bigfoot B&W.jpg'; Alt = 'Little Bigfoot black-and-white digital version by Ron English' },
      @{ File = 'Little Bigfoot COLOR.jpg'; Alt = 'Little Bigfoot color digital version by Ron English' }
    )
    TradingCards = @()
    AdditionalCards = @()
    CardDetails = @()
    Poem = ''
  },
  @{
    Title = 'Urban Bigfoot'
    Slug = 'urban-bigfoot.html'
    Thumb = 'Urban Bigfoot 1 front COLOR.jpg'
    Originals = @(
      @{ File = 'Urban Bigfoot 1 front ORIGINAL.jpg'; Alt = 'Urban Bigfoot front original drawing by Ron English' },
      @{ File = 'Urban Bigfoot 1 back ORIGINAL.jpg'; Alt = 'Urban Bigfoot back original drawing by Ron English' },
      @{ File = 'Urban Bigfoot 1 left side ORIGINAL.jpg'; Alt = 'Urban Bigfoot left side original drawing by Ron English' },
      @{ File = 'Urban Bigfoot 1 right side ORIGINAL.jpg'; Alt = 'Urban Bigfoot right side original drawing by Ron English' }
    )
    Digitals = @(
      @{ File = 'Urban Bigfoot 1 front B&W.jpg'; Alt = 'Urban Bigfoot front black-and-white digital version by Ron English' },
      @{ File = 'Urban Bigfoot 1 back B&W.jpg'; Alt = 'Urban Bigfoot back black-and-white digital version by Ron English' },
      @{ File = 'Urban Bigfoot 1 left side B&W.jpg'; Alt = 'Urban Bigfoot left side black-and-white digital version by Ron English' },
      @{ File = 'Urban Bigfoot right side 1 B&W.jpg'; Alt = 'Urban Bigfoot right side black-and-white digital version by Ron English' },
      @{ File = 'Urban Bigfoot 1 front COLOR.jpg'; Alt = 'Urban Bigfoot front color digital version by Ron English' },
      @{ File = 'Urban Bigfoot 1 back COLOR.jpg'; Alt = 'Urban Bigfoot back color digital version by Ron English' },
      @{ File = 'Urban Bigfoot 1 left side COLOR.jpg'; Alt = 'Urban Bigfoot left side color digital version by Ron English' },
      @{ File = 'Urban Bigfoot 1 right side COLOR.jpg'; Alt = 'Urban Bigfoot right side color digital version by Ron English' }
    )
    TradingCards = @(
      @{ File = 'series 1 #52 front - BIGFOOTS - urban bigfoot - ultrarare.jpg'; Alt = 'Urban Bigfoot trading card front' },
      @{ File = 'series 1 #52 back - BIGFOOTS - Urban Bigfoot - ultrarare.jpg'; Alt = 'Urban Bigfoot trading card back' }
    )
    AdditionalCards = @()
    CardDetails = @(
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
  },
  @{
    Title = 'Bigfoot Living Room'
    Slug = 'bigfoot-living-room.html'
    Thumb = 'Bigfoot Living Room 1A B&W.jpg'
    Originals = @(
      @{ File = 'Bigfoot Living Room 1 ORIGINAL.jpg'; Alt = 'Bigfoot Living Room 1 original drawing by Ron English' },
      @{ File = 'Bigfoot Living Room 2 ORIGINAL.jpg'; Alt = 'Bigfoot Living Room 2 original drawing by Ron English' }
    )
    Digitals = @(
      @{ File = 'Bigfoot Living Room 1A B&W.jpg'; Alt = 'Bigfoot Living Room 1A black-and-white digital version by Ron English' },
      @{ File = 'Bigfoot Living Room 1B B&W.jpg'; Alt = 'Bigfoot Living Room 1B black-and-white digital version by Ron English' }
    )
    TradingCards = @()
    AdditionalCards = @()
    CardDetails = @()
    Poem = ''
  },
  @{
    Title = 'Bigfoot Messiah'
    Slug = 'bigfoot-messiah.html'
    Thumb = 'Bigfoot Messiah COLOR.jpg'
    Originals = @(
      @{ File = 'Bigfoot Messiah ORIGINAL.jpg'; Alt = 'Bigfoot Messiah original drawing by Ron English' }
    )
    Digitals = @(
      @{ File = 'Bigfoot Messiah B&w.jpg'; Alt = 'Bigfoot Messiah black-and-white digital version by Ron English' },
      @{ File = 'Bigfoot Messiah COLOR.jpg'; Alt = 'Bigfoot Messiah color digital version by Ron English' }
    )
    TradingCards = @()
    AdditionalCards = @()
    CardDetails = @()
    Poem = ''
  },
  @{
    Title = 'Midget Bigfoot'
    Slug = 'midget-bigfoot.html'
    Thumb = 'Midget Bigfoot COLOR.jpg'
    Originals = @(
      @{ File = 'Midget Bigfoot ORIGINAL.jpg'; Alt = 'Midget Bigfoot original drawing by Ron English' }
    )
    Digitals = @(
      @{ File = 'Midget Bigfoot B&W.jpg'; Alt = 'Midget Bigfoot black-and-white digital version by Ron English' },
      @{ File = 'Midget Bigfoot COLOR.jpg'; Alt = 'Midget Bigfoot color digital version by Ron English' }
    )
    TradingCards = @(
      @{ File = 'series 2 #38 front - BIGFOOTS - MIdget Bigfoot - rare.jpg'; Alt = 'Midget Bigfoot trading card front' },
      @{ File = 'series 2 #38 back - BIGFOOTS - Midget Bigfoot - rare.jpg'; Alt = 'Midget Bigfoot trading card back' }
    )
    AdditionalCards = @(
      @{ File = 'Midget Bigfoot card.jpg'; Alt = 'Midget Bigfoot collector card' }
    )
    CardDetails = @(
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
  },
  @{
    Title = 'Bigfoot Tourist'
    Slug = 'bigfoot-tourist.html'
    Thumb = 'Bigfoot Tourist COLOR.jpg'
    Originals = @(
      @{ File = 'Bigfoot Tourist ORIGINAL.jpg'; Alt = 'Bigfoot Tourist original drawing by Ron English' },
      @{ File = 'Bigfoot Tourist ORIGINAL COLOR.jpg'; Alt = 'Bigfoot Tourist original color drawing by Ron English' }
    )
    Digitals = @(
      @{ File = 'Bigfoot Tourist B&W.jpg'; Alt = 'Bigfoot Tourist black-and-white digital version by Ron English' },
      @{ File = 'Bigfoot Tourist COLOR.jpg'; Alt = 'Bigfoot Tourist color digital version by Ron English' }
    )
    TradingCards = @()
    AdditionalCards = @()
    CardDetails = @()
    Poem = ''
  },
  @{
    Title = "Li'l Bigfoot"
    Slug = 'lil-bigfoot.html'
    Thumb = "Li'l Bigfoot COLOR.jpg"
    Originals = @(
      @{ File = "Li'l Bigfoot ORIGINAL.jpg"; Alt = "Li'l Bigfoot original drawing by Ron English" }
    )
    Digitals = @(
      @{ File = "Li'l Bigfoot B&W.jpg"; Alt = "Li'l Bigfoot black-and-white digital version by Ron English" },
      @{ File = "Li'l Bigfoot COLOR.jpg"; Alt = "Li'l Bigfoot color digital version by Ron English" }
    )
    TradingCards = @(
      @{ File = 'series 1 #36 front - BIGFOOTS - Lil Bigfoot - uncommon.jpg'; Alt = "Li'l Bigfoot trading card front" },
      @{ File = "series 1 #36 back - BIGFOOT - Li'l Bigfoot - uncommon.jpg"; Alt = "Li'l Bigfoot trading card back" }
    )
    AdditionalCards = @(
      @{ File = "Li'l Bigfoot card.jpg"; Alt = "Li'l Bigfoot collector card" }
    )
    CardDetails = @(
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
  },
  @{
    Title = 'Bigfoot Feet'
    Slug = 'bigfoot-feet.html'
    Thumb = 'Bigfoot feet ORIGINAL.jpg'
    Originals = @(
      @{ File = 'Bigfoot feet ORIGINAL.jpg'; Alt = 'Bigfoot feet original drawing by Ron English' },
      @{ File = 'Bigfoot Footprint ORIGINAL.jpg'; Alt = 'Bigfoot Footprint original drawing by Ron English' }
    )
    Digitals = @()
    TradingCards = @()
    AdditionalCards = @()
    CardDetails = @()
    Poem = ''
  },
  @{
    Title = 'Urban Bigfoot with Hoodie'
    Slug = 'urban-bigfoot-with-hoodie.html'
    Thumb = 'Urban Bigfoot with Hoodie front.jpg'
    Originals = @()
    Digitals = @(
      @{ File = 'Urban Bigfoot with Hoodie front.jpg'; Alt = 'Urban Bigfoot with Hoodie front digital version by Ron English' },
      @{ File = 'Urban Bigfoot with Hoodie side.jpg'; Alt = 'Urban Bigfoot with Hoodie side digital version by Ron English' }
    )
    TradingCards = @()
    AdditionalCards = @()
    CardDetails = @()
    Poem = ''
  },
  @{
    Title = 'Fake Father Bigfoot'
    Slug = 'fake-father-bigfoot.html'
    Thumb = 'Fake Father Bigfoot COLOR.jpg'
    Originals = @(
      @{ File = 'Fake Father Bigfoot ORIGINAL.jpg'; Alt = 'Fake Father Bigfoot original drawing by Ron English' }
    )
    Digitals = @(
      @{ File = 'Fake Father Bigfoot B&w.jpg'; Alt = 'Fake Father Bigfoot black-and-white digital version by Ron English' },
      @{ File = 'Fake Father Bigfoot COLOR.jpg'; Alt = 'Fake Father Bigfoot color digital version by Ron English' }
    )
    TradingCards = @(
      @{ File = 'series 2 #6 front - BIGFOOTS - fake Father Bigfoot - common.jpg'; Alt = 'Fake Father Bigfoot trading card front' },
      @{ File = 'series 2 #6 back - BIGFOOTS - Fake Father Bigfoot - common.jpg'; Alt = 'Fake Father Bigfoot trading card back' }
    )
    AdditionalCards = @(
      @{ File = 'Fake Father Bigfoot card.jpg'; Alt = 'Fake Father Bigfoot collector card' }
    )
    CardDetails = @(
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
  },
  @{
    Title = 'New Urban Bigfoot'
    Slug = 'new-urban-bigfoot.html'
    Thumb = 'New Urban Bigfoot COLOR.jpg'
    Originals = @(
      @{ File = 'New Urban Bigfoot ORIGINAL.jpg'; Alt = 'New Urban Bigfoot original drawing by Ron English' }
    )
    Digitals = @(
      @{ File = 'New Urban Bigfoot B&W.jpg'; Alt = 'New Urban Bigfoot black-and-white digital version by Ron English' },
      @{ File = 'New Urban Bigfoot COLOR.jpg'; Alt = 'New Urban Bigfoot color digital version by Ron English' }
    )
    TradingCards = @()
    AdditionalCards = @(
      @{ File = 'New Urban Bigfoot card.jpg'; Alt = 'New Urban Bigfoot collector card' }
    )
    CardDetails = @()
    Poem = ''
  },
  @{
    Title = 'Bigfoot Toddler'
    Slug = 'bigfoot-toddler.html'
    Thumb = 'Bigfoot Toddler COLOR.jpg'
    Originals = @()
    Digitals = @(
      @{ File = 'Bigfoot Toddler B&W.jpg'; Alt = 'Bigfoot Toddler black-and-white digital version by Ron English' },
      @{ File = 'Bigfoot Toddler COLOR.jpg'; Alt = 'Bigfoot Toddler color digital version by Ron English' }
    )
    TradingCards = @()
    AdditionalCards = @()
    CardDetails = @()
    Poem = ''
  },
  @{
    Title = "Li'l Bigfoot with Beard"
    Slug = 'lil-bigfoot-with-beard.html'
    Thumb = "Li'l Bigfoot with beard front COLOR.jpg"
    Originals = @(
      @{ File = "Li'l Bigfoot with beard front ORIGINAL.jpg"; Alt = "Li'l Bigfoot with beard front original drawing by Ron English" },
      @{ File = "Li'l Bigfoot with beard front ORIGINAL COLORED.jpg"; Alt = "Li'l Bigfoot with beard front original colored drawing by Ron English" },
      @{ File = "Li'l Bigfoot with beard front ORIGINAL COLOR rainbow.jpg"; Alt = "Li'l Bigfoot with beard front original color rainbow drawing by Ron English" },
      @{ File = "Li'l Bigfoot with beard back ORIGINAL.jpg"; Alt = "Li'l Bigfoot with beard back original drawing by Ron English" },
      @{ File = "Li'l Bigfoot with beard side ORIGINAL.jpg"; Alt = "Li'l Bigfoot with beard side original drawing by Ron English" },
      @{ File = "Li'l Bigfoot with beard three quarters ORIGINAL.jpg"; Alt = "Li'l Bigfoot with beard three-quarter original drawing by Ron English" }
    )
    Digitals = @(
      @{ File = "Li'l Bigfoot with beard front B&W.jpg"; Alt = "Li'l Bigfoot with beard front black-and-white digital version by Ron English" },
      @{ File = "Li'l Bigfoot with beard back B&W.jpg"; Alt = "Li'l Bigfoot with beard back black-and-white digital version by Ron English" },
      @{ File = "Li'l Bigfoot with beard side B&w.jpg"; Alt = "Li'l Bigfoot with beard side black-and-white digital version by Ron English" },
      @{ File = "Li'l Bigfoot with beard three quarters B&W.jpg"; Alt = "Li'l Bigfoot with beard three-quarter black-and-white digital version by Ron English" },
      @{ File = "Li'l Bigfoot with beard front COLOR.jpg"; Alt = "Li'l Bigfoot with beard front color digital version by Ron English" },
      @{ File = "Li'l Bigfoot with beard back COLOR.jpg"; Alt = "Li'l Bigfoot with beard back color digital version by Ron English" },
      @{ File = "Li'l Bigfoot with beard side COLOR.jpg"; Alt = "Li'l Bigfoot with beard side color digital version by Ron English" },
      @{ File = "Li'l Bigfoot with beard three quarters COLOR.jpg"; Alt = "Li'l Bigfoot with beard three-quarter color digital version by Ron English" }
    )
    TradingCards = @()
    AdditionalCards = @()
    CardDetails = @()
    Poem = ''
  },
  @{
    Title = 'Myth Mother Bigfoot'
    Slug = 'myth-mother-bigfoot.html'
    Thumb = 'Myth Mother Bigfoot COLOR.jpg'
    Originals = @()
    Digitals = @(
      @{ File = 'Myth Mother Bigfoot B&W.jpg'; Alt = 'Myth Mother Bigfoot black-and-white digital version by Ron English' },
      @{ File = 'Myth Mother Bigfoot COLOR.jpg'; Alt = 'Myth Mother Bigfoot color digital version by Ron English' }
    )
    TradingCards = @(
      @{ File = 'series 2 #7 front - BIGFOOTS - Myth Mother Bigfoot - common copy.jpg'; Alt = 'Myth Mother Bigfoot trading card front' },
      @{ File = 'series 2 #7 back - BIGFOOTS - Myth Mother Bigfoot - common.jpg'; Alt = 'Myth Mother Bigfoot trading card back' }
    )
    AdditionalCards = @(
      @{ File = 'Myth Mother Bigfoot card.jpg'; Alt = 'Myth Mother Bigfoot collector card' }
    )
    CardDetails = @(
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
  },
  @{
    Title = 'Washington Bigfoot'
    Slug = 'washington-bigfoot.html'
    Thumb = 'Washington Bigfoot ORIGINAL.jpg'
    Originals = @(
      @{ File = 'Washington Bigfoot ORIGINAL.jpg'; Alt = 'Washington Bigfoot original drawing by Ron English' }
    )
    Digitals = @(
      @{ File = 'Washington Bigfoot B&w.jpg'; Alt = 'Washington Bigfoot black-and-white digital version by Ron English' }
    )
    TradingCards = @()
    AdditionalCards = @()
    CardDetails = @()
    Poem = ''
  },
  @{
    Title = 'Bigfoot Family Icon'
    Slug = 'bigfoot-family-icon.html'
    Thumb = 'Bigfoot Family Icon COLOR.jpg'
    Originals = @()
    Digitals = @(
      @{ File = 'Bigfoot Family Icon COLOR.jpg'; Alt = 'Bigfoot Family Icon color digital version by Ron English' }
    )
    TradingCards = @()
    AdditionalCards = @()
    CardDetails = @()
    Poem = ''
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

function Backup-AndRemoveIfExists {
  param([string]$Path)

  if (Test-Path $Path) {
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $backupPath = "$Path.bak-removed-$stamp"
    Move-Item -Path $Path -Destination $backupPath -Force
    Write-Host "Archived old standalone file: $backupPath"
  }
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
  $relative = $fromUri.MakeRelativeUri($toUri).ToString()
  $relative = [System.Uri]::UnescapeDataString($relative)
  return $relative -replace '\\','/'
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

function Add-CardTextBlock {
  param(
    [System.Text.StringBuilder]$Builder,
    [array]$CardDetails,
    [string]$Poem
  )

  $hasDetails = ($null -ne $CardDetails -and $CardDetails.Count -gt 0)
  $hasPoem = ![string]::IsNullOrWhiteSpace($Poem)

  if (!$hasDetails -and !$hasPoem) {
    return
  }

  $className = 'card-text-block'
  if (!$hasDetails -or !$hasPoem) {
    $className = 'card-text-block compact-card-text'
  }

  [void]$Builder.AppendLine('')
  [void]$Builder.AppendLine('      <div class="' + $className + '">')

  if ($hasDetails) {
    [void]$Builder.AppendLine('        <div class="card-column">')
    [void]$Builder.AppendLine('          <span class="text-label">Card details</span>')
    [void]$Builder.AppendLine('          <div class="card-details">')
    foreach ($detail in $CardDetails) {
      [void]$Builder.AppendLine('            <p class="card-detail"><strong>' + (HtmlEncode $detail.Label) + ':</strong> ' + (HtmlEncode $detail.Value) + '</p>')
    }
    [void]$Builder.AppendLine('          </div>')
    [void]$Builder.AppendLine('        </div>')
  }

  if ($hasPoem) {
    [void]$Builder.AppendLine('')
    [void]$Builder.AppendLine('        <div class="card-column">')
    [void]$Builder.AppendLine('          <span class="text-label">Poem</span>')
    [void]$Builder.AppendLine('          <p class="poem">' + (HtmlEncode $Poem.Trim()) + '</p>')
    [void]$Builder.AppendLine('        </div>')
  }

  [void]$Builder.AppendLine('      </div>')
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

    .section-card h3{
      margin:22px 0 14px;
      font-size:1.05rem;
    }

    .section-intro{
      margin:0 0 18px;
      color:var(--muted);
      line-height:1.6;
    }

    .index-grid{
      margin-top:28px;
      display:grid;
      grid-template-columns:repeat(4,minmax(0,1fr));
      gap:18px;
    }

    .gallery-grid,
    .card-grid{
      display:grid;
      grid-template-columns:repeat(auto-fit,minmax(220px,1fr));
      gap:20px;
    }

    .trading-card-grid{
      display:grid;
      grid-template-columns:repeat(2,minmax(0,1fr));
      gap:20px;
    }

    .additional-card-grid{
      display:grid;
      grid-template-columns:minmax(220px,420px);
      gap:20px;
      margin-top:0;
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
      border-radius:16px;
      overflow:hidden;
      box-shadow:0 4px 18px rgba(0,0,0,.04);
      margin:0;
      transition:transform .12s ease, box-shadow .12s ease, border-color .12s ease;
    }

    .gallery-item:hover{
      transform:translateY(-2px);
      box-shadow:0 16px 40px rgba(0,0,0,.12);
      border-color:#d1d5db;
    }

    .gallery-item a{
      display:block;
      color:inherit;
      text-decoration:none;
    }

    .gallery-item img{
      display:block;
      width:100%;
      object-fit:contain;
      background:var(--panel);
      padding:8px;
      border-bottom:0;
    }

    .index-grid .gallery-item img{
      height:260px;
      padding:10px;
      border-bottom:1px solid var(--border);
    }

    .gallery-grid .gallery-item img{
      height:300px;
    }

    .originals-grid .gallery-item img{
      height:440px;
    }

    .card-grid .gallery-item img,
    .trading-card-grid .gallery-item img,
    .additional-card-grid .gallery-item img{
      height:520px;
      padding:10px;
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

    .card-column{
      min-width:0;
    }

    .text-label{
      display:block;
      font-size:.78rem;
      text-transform:uppercase;
      letter-spacing:.08em;
      color:var(--muted);
      margin-bottom:8px;
    }

    .card-details{
      display:grid;
      gap:8px;
    }

    .card-detail{
      margin:0;
      line-height:1.55;
    }

    .poem{
      margin:0;
      white-space:pre-line;
      line-height:1.65;
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
      .index-grid{
        grid-template-columns:repeat(3,minmax(0,1fr));
      }
    }

    @media (max-width:820px){
      .index-grid{
        grid-template-columns:repeat(2,minmax(0,1fr));
      }

      .card-text-block{
        grid-template-columns:1fr;
      }
    }

    @media (max-width:560px){
      .wrap{
        padding:22px 14px 50px;
      }

      .index-grid,
      .gallery-grid,
      .card-grid,
      .trading-card-grid,
      .additional-card-grid,
      .originals-grid{
        grid-template-columns:1fr;
      }

      .index-grid .gallery-item img,
      .gallery-grid .gallery-item img{
        height:260px;
      }

      .originals-grid .gallery-item img{
        height:340px;
      }

      .card-grid .gallery-item img,
      .trading-card-grid .gallery-item img,
      .additional-card-grid .gallery-item img{
        height:420px;
      }
    }
  </style>
</head>
"@
}

function Build-IndexPage {
  $html = New-Object System.Text.StringBuilder

  [void]$html.AppendLine((Get-SharedHead -Title 'Bigfoot | Sketches and Drawings'))
  [void]$html.AppendLine('<body>')
  [void]$html.AppendLine('  <main class="wrap">')
  [void]$html.AppendLine('    <nav class="nav-pills" aria-label="Site navigation">')
  [void]$html.AppendLine('      <a class="nav-pill" href="https://ronenglish-archive.github.io/ron-english-catalogue-raisonne/">Catalogue home</a>')
  [void]$html.AppendLine('      <a class="nav-pill" href="../index.html">Sketches</a>')
  [void]$html.AppendLine('      <a class="nav-pill" href="index.html">Bigfoot</a>')
  [void]$html.AppendLine('    </nav>')
  [void]$html.AppendLine('')
  [void]$html.AppendLine('    <header class="page-header">')
  [void]$html.AppendLine('      <h1 class="page-title">Bigfoot</h1>')
  [void]$html.AppendLine('    </header>')
  [void]$html.AppendLine('')
  [void]$html.AppendLine('    <section class="intro-text">')
  [void]$html.AppendLine('      <p>Bigfoot character drawings from the Ron English archive, including original drawings, digitized versions, turnarounds, and related card material where available.</p>')
  [void]$html.AppendLine('    </section>')
  [void]$html.AppendLine('')
  [void]$html.AppendLine('    <section class="index-grid" aria-label="Bigfoot sketches">')

  foreach ($page in $Pages) {
    $thumbFull = Get-ImageFullPath $page.Thumb
    $thumbPath = Convert-ToWebPath -FromHtmlDir $HtmlDir -FullImagePath $thumbFull
    $thumbPathAttr = HtmlEncode $thumbPath
    $pageTitle = HtmlEncode $page.Title
    $pageSlug = HtmlEncode $page.Slug

    [void]$html.AppendLine('')
    [void]$html.AppendLine('      <a class="gallery-item" href="' + $pageSlug + '">')
    [void]$html.AppendLine('        <img src="' + $thumbPathAttr + '" alt="' + $pageTitle + ' by Ron English" loading="lazy" />')
    [void]$html.AppendLine('        <div class="entry-body">')
    [void]$html.AppendLine('          <p class="work-title">' + $pageTitle + '</p>')
    [void]$html.AppendLine('        </div>')
    [void]$html.AppendLine('      </a>')
  }

  [void]$html.AppendLine('')
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
  [void]$html.AppendLine('      <a class="nav-pill" href="index.html">Bigfoot</a>')
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
      Add-ImageCard -Builder $html -Item $item -GridHtmlDir $HtmlDir
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
    [void]$html.AppendLine('      <div class="gallery-grid">')
    foreach ($item in $Page.Digitals) {
      Add-ImageCard -Builder $html -Item $item -GridHtmlDir $HtmlDir
      [void]$html.AppendLine('')
    }
    [void]$html.AppendLine('      </div>')
    [void]$html.AppendLine('    </section>')
    [void]$html.AppendLine('')
  }

  $hasTradingCards = ($Page.TradingCards.Count -gt 0)
  $hasAdditionalCards = ($Page.AdditionalCards.Count -gt 0)

  if ($hasTradingCards -or $hasAdditionalCards) {
    [void]$html.AppendLine('    <section class="section-card" aria-labelledby="collector-cards">')
    [void]$html.AppendLine('      <h2 id="collector-cards">Collector Cards</h2>')

    if ($hasTradingCards) {
      [void]$html.AppendLine('      <div class="trading-card-grid">')
      foreach ($item in $Page.TradingCards) {
        Add-ImageCard -Builder $html -Item $item -GridHtmlDir $HtmlDir
        [void]$html.AppendLine('')
      }
      [void]$html.AppendLine('      </div>')
      Add-CardTextBlock -Builder $html -CardDetails $Page.CardDetails -Poem $Page.Poem
    }
    elseif (($Page.CardDetails.Count -gt 0) -or ![string]::IsNullOrWhiteSpace($Page.Poem)) {
      Add-CardTextBlock -Builder $html -CardDetails $Page.CardDetails -Poem $Page.Poem
    }

    if ($hasAdditionalCards) {
      if ($hasTradingCards) {
        [void]$html.AppendLine('')
        [void]$html.AppendLine('      <h3>Additional Collector Card</h3>')
      }

      [void]$html.AppendLine('      <div class="additional-card-grid">')
      foreach ($item in $Page.AdditionalCards) {
        Add-ImageCard -Builder $html -Item $item -GridHtmlDir $HtmlDir
        [void]$html.AppendLine('')
      }
      [void]$html.AppendLine('      </div>')
    }

    [void]$html.AppendLine('    </section>')
    [void]$html.AppendLine('')
  }

  [void]$html.AppendLine('    <div class="back-link">')
  [void]$html.AppendLine('      <a href="index.html">&larr; Back to Bigfoot</a>')
  [void]$html.AppendLine('    </div>')
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

$expectedFiles = New-Object System.Collections.Generic.List[string]
foreach ($page in $Pages) {
  $expectedFiles.Add($page.Thumb)
  foreach ($item in $page.Originals) { $expectedFiles.Add($item.File) }
  foreach ($item in $page.Digitals) { $expectedFiles.Add($item.File) }
  foreach ($item in $page.TradingCards) { $expectedFiles.Add($item.File) }
  foreach ($item in $page.AdditionalCards) { $expectedFiles.Add($item.File) }
}

$expectedFiles = $expectedFiles | Sort-Object -Unique
$missing = New-Object System.Collections.Generic.List[string]

foreach ($file in $expectedFiles) {
  $full = Join-Path $ImageDir $file
  if (!(Test-Path $full)) {
    $missing.Add($file)
  }
}

if ($missing.Count -gt 0) {
  Write-Host ''
  Write-Host 'STOPPED: Some expected image files were not found.' -ForegroundColor Red
  Write-Host 'No HTML pages were written.' -ForegroundColor Yellow
  Write-Host ''
  Write-Host 'Missing files:'
  foreach ($file in $missing) {
    Write-Host " - $file"
  }
  Write-Host ''
  Write-Host 'Please check capitalization, spaces, apostrophes, extensions, and B&W exactly.'
  exit 1
}

$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$reportRows = New-Object System.Collections.Generic.List[object]

foreach ($page in $Pages) {
  foreach ($item in $page.Originals) {
    $reportRows.Add([pscustomobject]@{
      Character = $page.Title
      Page = $page.Slug
      Section = 'Original Drawing'
      File = $item.File
      FullPath = (Get-ImageFullPath $item.File)
    })
  }

  foreach ($item in $page.Digitals) {
    $reportRows.Add([pscustomobject]@{
      Character = $page.Title
      Page = $page.Slug
      Section = 'Digitized Versions'
      File = $item.File
      FullPath = (Get-ImageFullPath $item.File)
    })
  }

  foreach ($item in $page.TradingCards) {
    $reportRows.Add([pscustomobject]@{
      Character = $page.Title
      Page = $page.Slug
      Section = 'Trading Cards'
      File = $item.File
      FullPath = (Get-ImageFullPath $item.File)
    })
  }

  foreach ($item in $page.AdditionalCards) {
    $reportRows.Add([pscustomobject]@{
      Character = $page.Title
      Page = $page.Slug
      Section = 'Additional Collector Card'
      File = $item.File
      FullPath = (Get-ImageFullPath $item.File)
    })
  }
}

$csvPath = Join-Path $ReportDir 'bigfoot-build-report-v2.csv'
$txtPath = Join-Path $ReportDir 'bigfoot-build-summary-v2.txt'

$reportRows | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

$summary = @()
$summary += 'Bigfoot build report V2'
$summary += "Generated: $timestamp"
$summary += ''
$summary += "Image folder: $ImageDir"
$summary += "HTML folder:  $HtmlDir"
$summary += ''
$summary += 'Pages created or updated:'
$summary += '- Sketches\bigfoot\index.html'
foreach ($page in $Pages) {
  $summary += ('- Sketches\bigfoot\' + $page.Slug + ' - ' + $page.Title)
}
$summary += ''
$summary += 'Archived stale standalone page if present:'
$summary += '- Sketches\bigfoot\bigfoot-footprint.html'
$summary += ''
$summary += 'Pages using the no-original standard:'
foreach ($page in $Pages) {
  if ($page.Originals.Count -eq 0) {
    $summary += ('- ' + $page.Title)
  }
}
$summary += ''
$summary += 'Images used:'
foreach ($row in $reportRows) {
  $summary += ('- ' + $row.Character + ' / ' + $row.Section + ': ' + $row.File)
}
$summary | Set-Content -Path $txtPath -Encoding UTF8

$indexPath = Join-Path $HtmlDir 'index.html'
Backup-IfExists $indexPath
Build-IndexPage | Set-Content -Path $indexPath -Encoding UTF8

$oldFootprintPath = Join-Path $HtmlDir 'bigfoot-footprint.html'
Backup-AndRemoveIfExists $oldFootprintPath

foreach ($page in $Pages) {
  $pagePath = Join-Path $HtmlDir $page.Slug
  Backup-IfExists $pagePath
  Build-CharacterPage -Page $page | Set-Content -Path $pagePath -Encoding UTF8
}

Write-Host ''
Write-Host 'Bigfoot pages V2 built successfully.' -ForegroundColor Green
Write-Host ''
Write-Host 'Created or updated:'
Write-Host " - $indexPath"
foreach ($page in $Pages) {
  Write-Host (' - ' + (Join-Path $HtmlDir $page.Slug))
}
Write-Host ''
Write-Host 'Reports:'
Write-Host " - $csvPath"
Write-Host " - $txtPath"
Write-Host ''
Write-Host 'V2 updates applied:' -ForegroundColor Yellow
Write-Host ' - Removed image counts from the Bigfoot index.'
Write-Host ' - Removed text/captions below images on individual pages.'
Write-Host ' - Added Bigfoot Family Icon.'
Write-Host ' - Moved Bigfoot Footprint ORIGINAL.jpg into Bigfoot Feet.'
Write-Host ' - Trading-card front/back images now display two per row, with additional no-info card below.'
Write-Host ''
