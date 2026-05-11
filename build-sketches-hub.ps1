# build-sketches-hub.ps1
# Builds the clean hub / landing page repo for the split Ron English sketches-and-drawings site.
#
# Destination hub repo:
# D:\github\ron-english-sketches
#
# IMPORTANT:
# - This script changes ONLY the hub repo:
#   D:\github\ron-english-sketches
# - It does NOT delete, move, rename, or edit files in the old source repo.
# - It does NOT edit any of the six split content repos.
# - It creates a backup of the destination hub repo before changing it.
# - It creates:
#   index.html
#   README.md
#   .nojekyll
#   _hub-audit summary files

$ErrorActionPreference = "Stop"

$DestinationRepo = "D:\github\ron-english-sketches"

$ScriptName = "build-sketches-hub"
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

$BackupRoot = "D:\github-backups\ron-english-sketches-and-drawings"
$BackupFolder = Join-Path $BackupRoot ($ScriptName + "-" + $Timestamp)

$AuditFolder = Join-Path $DestinationRepo "_hub-audit"
$LogPath = Join-Path $AuditFolder ($ScriptName + "-" + $Timestamp + "-log.txt")
$SummaryPath = Join-Path $AuditFolder ($ScriptName + "-" + $Timestamp + "-summary.txt")
$LinksCsvPath = Join-Path $AuditFolder ($ScriptName + "-" + $Timestamp + "-hub-links.csv")

$IndexPath = Join-Path $DestinationRepo "index.html"
$ReadmePath = Join-Path $DestinationRepo "README.md"
$NoJekyllPath = Join-Path $DestinationRepo ".nojekyll"

$Sections = @(
    @{
        Title = "Grins"
        Label = "Grins"
        Url = "https://ronenglish-archive.github.io/ron-english-sketches-grins/"
        LocalRepo = "D:\github\ron-english-sketches-grins"
        Description = "The Grins section of the sketches-and-drawings catalogue."
        Meta = "Standalone section"
    },
    @{
        Title = "Aliens"
        Label = "Aliens"
        Url = "https://ronenglish-archive.github.io/ron-english-sketches-aliens/"
        LocalRepo = "D:\github\ron-english-sketches-aliens"
        Description = "Alien characters, extraterrestrial studies, and related drawings."
        Meta = "Standalone section"
    },
    @{
        Title = "Animals"
        Label = "Animals"
        Url = "https://ronenglish-archive.github.io/ron-english-sketches-animals/"
        LocalRepo = "D:\github\ron-english-sketches-animals"
        Description = "Animal-related sections including amphibians, aquatic dwellers, avians, mammals, reptiles, insects, snails, and ungulates."
        Meta = "Grouped repository"
    },
    @{
        Title = "Mythic / Dark"
        Label = "Mythic / Dark"
        Url = "https://ronenglish-archive.github.io/ron-english-sketches-mythic-dark/"
        LocalRepo = "D:\github\ron-english-sketches-mythic-dark"
        Description = "Mythic, dark, skeletal, monstrous, symbolic, and related sections."
        Meta = "Grouped repository"
    },
    @{
        Title = "Objects"
        Label = "Objects"
        Url = "https://ronenglish-archive.github.io/ron-english-sketches-objects/"
        LocalRepo = "D:\github\ron-english-sketches-objects"
        Description = "Objects and flowers sections, with supplemental animation assets preserved."
        Meta = "Grouped repository"
    },
    @{
        Title = "Pop Culture"
        Label = "Pop Culture"
        Url = "https://ronenglish-archive.github.io/ron-english-sketches-pop-culture/"
        LocalRepo = "D:\github\ron-english-sketches-pop-culture"
        Description = "Celebrity characters, character balls, Combrats, and TVities."
        Meta = "Grouped repository"
    }
)

function Ensure-Folder {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Force -Path $Path | Out-Null
    }
}

function Write-Log {
    param([string]$Message)

    $Line = ("[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message)
    Write-Host $Line
    Add-Content -LiteralPath $LogPath -Value $Line
}

function Backup-DestinationRepo {
    Ensure-Folder $BackupFolder

    Write-Log ("Creating destination backup at: " + $BackupFolder)

    $Items = @(Get-ChildItem -LiteralPath $DestinationRepo -Force)

    foreach ($Item in $Items) {
        if ($Item.Name -eq ".git") {
            continue
        }

        $TargetPath = Join-Path $BackupFolder $Item.Name
        Copy-Item -LiteralPath $Item.FullName -Destination $TargetPath -Recurse -Force
    }
}

function Test-RequiredPaths {
    if (-not (Test-Path -LiteralPath $DestinationRepo)) {
        throw ("Destination hub repo does not exist: " + $DestinationRepo)
    }

    if (-not (Test-Path -LiteralPath (Join-Path $DestinationRepo ".git"))) {
        throw ("Destination folder does not look like a Git repo because .git is missing: " + $DestinationRepo)
    }
}

function New-HubIndex {
    $Cards = @()

    foreach ($Section in $Sections) {
        $Cards += @"
      <article class="portal-card">
        <p class="card-kicker">$($Section.Meta)</p>
        <h2>$($Section.Title)</h2>
        <p>$($Section.Description)</p>
        <a class="card-link" href="$($Section.Url)">Open $($Section.Label)</a>
      </article>
"@
    }

    $CardsHtml = $Cards -join "`r`n"

    $Html = @"
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Ron English Sketches and Drawings</title>
  <meta name="description" content="A hub for the split Ron English sketches-and-drawings catalogue repositories." />
  <style>
    :root {
      color-scheme: dark;
      --bg: #0f1014;
      --panel: rgba(255, 255, 255, 0.065);
      --panel-strong: rgba(255, 255, 255, 0.095);
      --line: rgba(255, 255, 255, 0.16);
      --line-strong: rgba(255, 255, 255, 0.28);
      --text: #f6f1e8;
      --muted: rgba(246, 241, 232, 0.72);
      --soft: rgba(246, 241, 232, 0.52);
      --accent: #f7c948;
      --accent-2: #7dd3fc;
      --accent-3: #fb7185;
      --shadow: rgba(0, 0, 0, 0.38);
    }

    * {
      box-sizing: border-box;
    }

    html {
      scroll-behavior: smooth;
    }

    body {
      margin: 0;
      min-height: 100vh;
      font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      background:
        radial-gradient(circle at 18% 12%, rgba(247, 201, 72, 0.18), transparent 30rem),
        radial-gradient(circle at 82% 18%, rgba(125, 211, 252, 0.13), transparent 28rem),
        radial-gradient(circle at 70% 82%, rgba(251, 113, 133, 0.10), transparent 30rem),
        linear-gradient(145deg, #0b0c10 0%, #12131a 48%, #0c0d12 100%);
      color: var(--text);
    }

    a {
      color: inherit;
    }

    .site-shell {
      width: min(1220px, calc(100vw - 2rem));
      margin: 0 auto;
      padding: 1rem 0 4rem;
    }

    .site-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 1rem;
      padding: 1rem 0;
    }

    .brand {
      display: inline-flex;
      align-items: center;
      gap: 0.7rem;
      color: var(--text);
      text-decoration: none;
      font-weight: 800;
      letter-spacing: 0.03em;
    }

    .brand-mark {
      width: 36px;
      height: 36px;
      border-radius: 999px;
      display: grid;
      place-items: center;
      background: linear-gradient(135deg, rgba(247, 201, 72, 0.95), rgba(125, 211, 252, 0.85));
      color: #111114;
      font-weight: 900;
      box-shadow: 0 12px 30px rgba(0,0,0,0.28);
    }

    .top-nav {
      display: flex;
      flex-wrap: wrap;
      justify-content: flex-end;
      gap: 0.55rem;
    }

    .top-nav a {
      min-height: 38px;
      display: inline-flex;
      align-items: center;
      padding: 0.55rem 0.82rem;
      border: 1px solid var(--line);
      border-radius: 999px;
      background: rgba(255,255,255,0.045);
      color: var(--muted);
      text-decoration: none;
      font-size: 0.92rem;
    }

    .top-nav a:hover {
      color: var(--text);
      border-color: var(--line-strong);
      background: rgba(255,255,255,0.08);
    }

    .hero {
      margin-top: 1rem;
      min-height: min(680px, calc(100vh - 7rem));
      display: grid;
      place-items: center;
      padding: clamp(2rem, 6vw, 5rem);
      border: 1px solid var(--line);
      border-radius: 34px;
      background:
        linear-gradient(135deg, rgba(255,255,255,0.095), rgba(255,255,255,0.035)),
        var(--panel);
      box-shadow: 0 28px 95px var(--shadow);
      position: relative;
      overflow: hidden;
    }

    .hero::before {
      content: "";
      position: absolute;
      inset: -30%;
      background:
        radial-gradient(circle at 30% 40%, rgba(247, 201, 72, 0.16), transparent 18rem),
        radial-gradient(circle at 70% 58%, rgba(125, 211, 252, 0.12), transparent 18rem),
        radial-gradient(circle at 48% 74%, rgba(251, 113, 133, 0.10), transparent 16rem);
      filter: blur(8px);
      pointer-events: none;
    }

    .hero-inner {
      position: relative;
      z-index: 1;
      max-width: 950px;
      text-align: center;
    }

    .eyebrow {
      margin: 0 0 1rem;
      color: var(--accent);
      font-size: 0.78rem;
      text-transform: uppercase;
      letter-spacing: 0.22em;
      font-weight: 800;
    }

    h1 {
      margin: 0;
      font-size: clamp(3rem, 9vw, 7.4rem);
      line-height: 0.88;
      letter-spacing: -0.075em;
    }

    .hero-copy {
      max-width: 780px;
      margin: 1.35rem auto 0;
      color: var(--muted);
      font-size: clamp(1.06rem, 2vw, 1.28rem);
      line-height: 1.75;
    }

    .hero-actions {
      display: flex;
      flex-wrap: wrap;
      justify-content: center;
      gap: 0.8rem;
      margin-top: 2rem;
    }

    .button {
      min-height: 46px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      padding: 0.78rem 1.05rem;
      border-radius: 999px;
      border: 1px solid var(--line);
      background: rgba(255,255,255,0.07);
      color: var(--text);
      text-decoration: none;
      font-weight: 700;
    }

    .button.primary {
      color: #171103;
      background: var(--accent);
      border-color: transparent;
    }

    .button:hover {
      transform: translateY(-1px);
      border-color: var(--line-strong);
    }

    .section {
      margin-top: 1.25rem;
      padding: clamp(1.2rem, 3vw, 2rem);
      border: 1px solid var(--line);
      border-radius: 28px;
      background: rgba(255,255,255,0.04);
    }

    .section-header {
      display: flex;
      flex-wrap: wrap;
      align-items: flex-end;
      justify-content: space-between;
      gap: 1rem;
      margin-bottom: 1rem;
    }

    .section-title {
      margin: 0;
      font-size: clamp(1.6rem, 4vw, 2.6rem);
      letter-spacing: -0.045em;
    }

    .section-note {
      margin: 0;
      max-width: 560px;
      color: var(--soft);
      line-height: 1.6;
    }

    .portal-grid {
      display: grid;
      grid-template-columns: repeat(3, minmax(0, 1fr));
      gap: 1rem;
    }

    .portal-card {
      min-height: 260px;
      display: flex;
      flex-direction: column;
      padding: 1.25rem;
      border: 1px solid var(--line);
      border-radius: 24px;
      background:
        radial-gradient(circle at 20% 10%, rgba(255,255,255,0.095), transparent 13rem),
        var(--panel);
      transition: transform 170ms ease, background 170ms ease, border-color 170ms ease;
    }

    .portal-card:hover {
      transform: translateY(-3px);
      background:
        radial-gradient(circle at 20% 10%, rgba(255,255,255,0.13), transparent 13rem),
        var(--panel-strong);
      border-color: var(--line-strong);
    }

    .card-kicker {
      margin: 0 0 0.8rem;
      color: var(--accent);
      text-transform: uppercase;
      letter-spacing: 0.16em;
      font-size: 0.72rem;
      font-weight: 800;
    }

    .portal-card h2 {
      margin: 0;
      font-size: clamp(1.55rem, 3vw, 2.2rem);
      letter-spacing: -0.045em;
    }

    .portal-card p {
      margin: 0.8rem 0 0;
      color: var(--muted);
      line-height: 1.6;
    }

    .card-link {
      margin-top: auto;
      padding-top: 1.4rem;
      color: var(--text);
      text-decoration: none;
      font-weight: 800;
    }

    .card-link::after {
      content: " ->";
      color: var(--accent);
    }

    .footer {
      margin-top: 1.25rem;
      padding: 1.25rem;
      color: var(--soft);
      text-align: center;
      line-height: 1.7;
    }

    @media (max-width: 920px) {
      .portal-grid {
        grid-template-columns: repeat(2, minmax(0, 1fr));
      }

      .site-header {
        align-items: flex-start;
        flex-direction: column;
      }

      .top-nav {
        justify-content: flex-start;
      }
    }

    @media (max-width: 640px) {
      .site-shell {
        width: min(100% - 1rem, 1220px);
      }

      .hero {
        border-radius: 26px;
        padding: 2rem 1rem;
      }

      h1 {
        font-size: clamp(2.7rem, 15vw, 4.6rem);
      }

      .portal-grid {
        grid-template-columns: 1fr;
      }

      .section {
        border-radius: 22px;
        padding: 1rem;
      }

      .portal-card {
        min-height: 220px;
      }
    }
  </style>
</head>
<body>
  <div class="site-shell">
    <header class="site-header" aria-label="Site header">
      <a class="brand" href="./">
        <span class="brand-mark">RE</span>
        <span>Sketches and Drawings</span>
      </a>
      <nav class="top-nav" aria-label="Split catalogue sections">
        <a href="https://ronenglish-archive.github.io/ron-english-sketches-grins/">Grins</a>
        <a href="https://ronenglish-archive.github.io/ron-english-sketches-aliens/">Aliens</a>
        <a href="https://ronenglish-archive.github.io/ron-english-sketches-animals/">Animals</a>
        <a href="https://ronenglish-archive.github.io/ron-english-sketches-mythic-dark/">Mythic / Dark</a>
        <a href="https://ronenglish-archive.github.io/ron-english-sketches-objects/">Objects</a>
        <a href="https://ronenglish-archive.github.io/ron-english-sketches-pop-culture/">Pop Culture</a>
      </nav>
    </header>

    <main>
      <section class="hero" aria-labelledby="page-title">
        <div class="hero-inner">
          <p class="eyebrow">Ron English archive</p>
          <h1 id="page-title">Sketches and Drawings</h1>
          <p class="hero-copy">
            A public hub for the split sketches-and-drawings catalogue repositories. Each section opens as its own GitHub Pages site, keeping the archive lighter, faster, and easier to maintain.
          </p>
          <div class="hero-actions">
            <a class="button primary" href="#sections">Explore sections</a>
            <a class="button" href="https://ronenglish-archive.github.io/ron-english-sketches-grins/">Start with Grins</a>
          </div>
        </div>
      </section>

      <section class="section" id="sections" aria-labelledby="sections-title">
        <div class="section-header">
          <h2 class="section-title" id="sections-title">Catalogue sections</h2>
          <p class="section-note">
            The original large sketches-and-drawings site has been divided into focused repositories for smoother GitHub Pages publishing.
          </p>
        </div>

        <div class="portal-grid">
$CardsHtml
        </div>
      </section>
    </main>

    <footer class="footer">
      <p>Ron English sketches-and-drawings catalogue hub. The original source repository remains preserved separately while the public site is served through split section repositories.</p>
    </footer>
  </div>
</body>
</html>
"@

    Set-Content -LiteralPath $IndexPath -Value $Html -Encoding UTF8
    Write-Log ("Wrote hub index: " + $IndexPath)
}

function New-Readme {
    $Readme = @'
# Ron English Sketches and Drawings

This repository is the public hub for the split Ron English sketches-and-drawings GitHub Pages site.

Live section repositories:

- Grins: https://ronenglish-archive.github.io/ron-english-sketches-grins/
- Aliens: https://ronenglish-archive.github.io/ron-english-sketches-aliens/
- Animals: https://ronenglish-archive.github.io/ron-english-sketches-animals/
- Mythic / Dark: https://ronenglish-archive.github.io/ron-english-sketches-mythic-dark/
- Objects: https://ronenglish-archive.github.io/ron-english-sketches-objects/
- Pop Culture: https://ronenglish-archive.github.io/ron-english-sketches-pop-culture/

The original large source repository remains preserved separately.
'@

    Set-Content -LiteralPath $ReadmePath -Value $Readme -Encoding UTF8
    Write-Log ("Wrote README: " + $ReadmePath)
}

function New-NoJekyll {
    Set-Content -LiteralPath $NoJekyllPath -Value "" -Encoding UTF8
    Write-Log ("Wrote .nojekyll: " + $NoJekyllPath)
}

function Write-LinkCsv {
    $Rows = @()

    foreach ($Section in $Sections) {
        $Rows += [PSCustomObject]@{
            Section = $Section.Title
            LiveUrl = $Section.Url
            LocalRepo = $Section.LocalRepo
            LocalRepoExists = (Test-Path -LiteralPath $Section.LocalRepo)
            Description = $Section.Description
        }
    }

    $Rows | Export-Csv -LiteralPath $LinksCsvPath -NoTypeInformation -Encoding UTF8
    Write-Log ("Wrote hub links CSV: " + $LinksCsvPath)
}

function Write-Summary {
    $SummaryLines = @()
    $SummaryLines += "Ron English sketches hub build summary"
    $SummaryLines += ("Generated: " + (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
    $SummaryLines += ""
    $SummaryLines += "Destination hub repo:"
    $SummaryLines += $DestinationRepo
    $SummaryLines += ""
    $SummaryLines += "Backup folder:"
    $SummaryLines += $BackupFolder
    $SummaryLines += ""
    $SummaryLines += "Created or updated:"
    $SummaryLines += "- index.html"
    $SummaryLines += "- README.md"
    $SummaryLines += "- .nojekyll"
    $SummaryLines += "- _hub-audit links and summary files"
    $SummaryLines += ""
    $SummaryLines += "Linked live repositories:"
    foreach ($Section in $Sections) {
        $SummaryLines += ("- " + $Section.Title + ": " + $Section.Url)
    }
    $SummaryLines += ""
    $SummaryLines += "Important:"
    $SummaryLines += "- The old large source repo was not changed."
    $SummaryLines += "- The six split content repos were not changed."
    $SummaryLines += "- This script only built the hub repo."

    Set-Content -LiteralPath $SummaryPath -Value $SummaryLines -Encoding UTF8
    Write-Log ("Wrote summary: " + $SummaryPath)
}

# Main run

Ensure-Folder $AuditFolder

Write-Log "Starting hub build."
Write-Log ("Destination hub repo: " + $DestinationRepo)

Test-RequiredPaths
Backup-DestinationRepo

New-HubIndex
New-Readme
New-NoJekyll
Write-LinkCsv
Write-Summary

Write-Log "Done."

Write-Host ""
Write-Host "DONE. The hub repo was built."
Write-Host ""
Write-Host "Hub repo:"
Write-Host $DestinationRepo
Write-Host ""
Write-Host "Backup folder:"
Write-Host $BackupFolder
Write-Host ""
Write-Host "Now test this local file:"
Write-Host "D:\github\ron-english-sketches\index.html"
Write-Host ""
Write-Host "If it looks good, commit and push the ron-english-sketches repo, then enable GitHub Pages."
