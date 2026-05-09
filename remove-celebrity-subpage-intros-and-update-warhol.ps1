[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$RepoRoot = 'D:\github\ron-english-sketches-and-drawings'
$CelebrityRoot = Join-Path $RepoRoot 'Sketches\celebrity-characters'

$AndyIndexPath = Join-Path $CelebrityRoot 'andy-warhol\index.html'
$YoungAndyPageCandidates = @(
    (Join-Path $CelebrityRoot 'andy-warhol\young-andy\index.html'),
    (Join-Path $CelebrityRoot 'andy-warhol\young-andy-25\index.html'),
    (Join-Path $CelebrityRoot 'andy-warhol\young-andy-25-original\index.html')
)

$AndyImageFolderName = 'Andy Warhol'
$YoungAndyImageFile = 'Young Andy 25 original.jpg'

function Encode-Part {
    param([AllowEmptyString()][string]$Text)

    if ([string]::IsNullOrEmpty($Text)) {
        return $Text
    }

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
        $backupPath = Join-Path $backupDir "$name-before-ancillary-text-and-warhol-thumb-fix-$timestamp$ext"

        Copy-Item -LiteralPath $Path -Destination $backupPath -Force
        Write-Host "Backup created: $backupPath"
    }
}

function Remove-IntroTextSections {
    if (-not (Test-Path -LiteralPath $CelebrityRoot)) {
        throw "Celebrity Characters folder not found: $CelebrityRoot"
    }

    $mainCelebrityIndex = Join-Path $CelebrityRoot 'index.html'

    $htmlFiles = @(Get-ChildItem -LiteralPath $CelebrityRoot -Recurse -File -Filter '*.html' | Where-Object {
        $_.FullName -notmatch '\\_backups\\' -and
        $_.FullName -notmatch '\\_archived-merged-pages\\' -and
        $_.FullName -ne $mainCelebrityIndex
    })

    foreach ($file in $htmlFiles) {
        $html = [System.IO.File]::ReadAllText($file.FullName)
        $originalHtml = $html

        # Remove all small ancillary intro-text sections on subpages, for example:
        # "Character groups and related Warhol-inspired drawings in this section."
        $html = [regex]::Replace(
            $html,
            '(?is)\s*<section\b[^>]*class="[^"]*\bintro-text\b[^"]*"[^>]*>.*?</section>\s*',
            "`r`n"
        )

        if ($html -ne $originalHtml) {
            Backup-FileIfExists -Path $file.FullName
            [System.IO.File]::WriteAllText($file.FullName, $html, [System.Text.UTF8Encoding]::new($false))
            Write-Host "Removed ancillary intro text from: $($file.FullName)"
        }
    }
}

function Update-PopTotBabyWarholIndexThumb {
    if (-not (Test-Path -LiteralPath $AndyIndexPath)) {
        Write-Warning "Andy Warhol index page not found: $AndyIndexPath"
        return
    }

    $imagePath = Join-Path $RepoRoot "images\Sketches\celebrity-characters\$AndyImageFolderName\$YoungAndyImageFile"
    if (-not (Test-Path -LiteralPath $imagePath)) {
        Write-Warning "Image not found: $imagePath"
    }

    Backup-FileIfExists -Path $AndyIndexPath

    $newSrc = '../../../images/Sketches/celebrity-characters/' + (Encode-Part $AndyImageFolderName) + '/' + (Encode-Part $YoungAndyImageFile)

    $html = [System.IO.File]::ReadAllText($AndyIndexPath)
    $originalHtml = $html

    # Exact card href only. No broad matching.
    $cardPattern = '(?is)<a\b(?=[^>]*\bclass="[^"]*\bgallery-item\b[^"]*")[^>]*href="pop-tot-baby-warhol/index\.html"[^>]*>.*?</a>'

    $html = [regex]::Replace($html, $cardPattern, {
        param($match)

        $card = $match.Value

        $card = [regex]::Replace($card, '(<img\b[^>]*\bsrc=")[^"]*(")', {
            param($imgMatch)
            return $imgMatch.Groups[1].Value + $newSrc + $imgMatch.Groups[2].Value
        }, 1)

        $card = [regex]::Replace($card, '(<img\b[^>]*\balt=")[^"]*(")', {
            param($altMatch)
            return $altMatch.Groups[1].Value + 'Pop Tot Baby Warhol drawings by Ron English' + $altMatch.Groups[2].Value
        }, 1)

        return $card
    }, 1)

    if ($html -ne $originalHtml) {
        [System.IO.File]::WriteAllText($AndyIndexPath, $html, [System.Text.UTF8Encoding]::new($false))
        Write-Host "Updated Pop Tot Baby Warhol index thumbnail:"
        Write-Host "  $AndyIndexPath"
    }
    else {
        Write-Warning "Could not find Pop Tot Baby Warhol card in: $AndyIndexPath"
    }
}

function Ensure-YoungAndyImageOnSubpage {
    $youngAndyPage = $null

    foreach ($candidate in $YoungAndyPageCandidates) {
        if (Test-Path -LiteralPath $candidate) {
            $youngAndyPage = $candidate
            break
        }
    }

    if ($null -eq $youngAndyPage) {
        Write-Warning "Could not find a Young Andy subpage. Tried:"
        foreach ($candidate in $YoungAndyPageCandidates) {
            Write-Warning "  $candidate"
        }
        return
    }

    $imagePath = Join-Path $RepoRoot "images\Sketches\celebrity-characters\$AndyImageFolderName\$YoungAndyImageFile"
    if (-not (Test-Path -LiteralPath $imagePath)) {
        Write-Warning "Image not found: $imagePath"
    }

    Backup-FileIfExists -Path $youngAndyPage

    $src = '../../../../images/Sketches/celebrity-characters/' + (Encode-Part $AndyImageFolderName) + '/' + (Encode-Part $YoungAndyImageFile)
    $encodedFileName = Encode-Part $YoungAndyImageFile

    $html = [System.IO.File]::ReadAllText($youngAndyPage)
    $originalHtml = $html

    if ($html -match [regex]::Escape($encodedFileName) -or $html -match [regex]::Escape($YoungAndyImageFile)) {
        Write-Host "Young Andy image already appears on page:"
        Write-Host "  $youngAndyPage"
        return
    }

    $figure = @"
        <figure class="gallery-item">
          <a href="$src" target="_blank" rel="noopener noreferrer">
            <img src="$src" alt="Young Andy original drawing by Ron English" loading="lazy" />
          </a>
        </figure>
"@

    # If there is an Original Drawings grid, add the image at the top.
    if ($html -match '(?is)<div\b[^>]*class="[^"]*\boriginals-grid\b[^"]*"[^>]*>') {
        $html = [regex]::Replace(
            $html,
            '(?is)(<div\b[^>]*class="[^"]*\boriginals-grid\b[^"]*"[^>]*>)',
            "`$1`r`n$figure",
            1
        )
    }
    else {
        # Otherwise add a clean Original Drawing section before Digitized Versions or the Back link.
        $section = @"

    <section class="section-card" aria-labelledby="original-drawing">
      <h2 id="original-drawing">Original Drawing</h2>
      <div class="originals-grid">
$figure
      </div>
    </section>
"@

        if ($html -match '(?is)\s*<section\b[^>]*aria-labelledby="digitized-versions"') {
            $html = [regex]::Replace($html, '(?is)(\s*<section\b[^>]*aria-labelledby="digitized-versions")', "$section`r`n`$1", 1)
        }
        elseif ($html -match '(?is)\s*<div\b[^>]*class="[^"]*\bback-link\b[^"]*"') {
            $html = [regex]::Replace($html, '(?is)(\s*<div\b[^>]*class="[^"]*\bback-link\b[^"]*")', "$section`r`n`$1", 1)
        }
        else {
            $html = [regex]::Replace($html, '(?i)</main>', "$section`r`n</main>", 1)
        }
    }

    if ($html -ne $originalHtml) {
        [System.IO.File]::WriteAllText($youngAndyPage, $html, [System.Text.UTF8Encoding]::new($false))
        Write-Host "Added Young Andy image to subpage:"
        Write-Host "  $youngAndyPage"
    }
}

Remove-IntroTextSections
Update-PopTotBabyWarholIndexThumb
Ensure-YoungAndyImageOnSubpage

Write-Host ""
Write-Host "Done."
Write-Host "Check these pages:"
Write-Host "  D:\github\ron-english-sketches-and-drawings\Sketches\celebrity-characters\andy-warhol\index.html"
Write-Host "  D:\github\ron-english-sketches-and-drawings\Sketches\celebrity-characters\andy-warhol\young-andy\index.html"
Write-Host ""
Write-Host "Also spot-check a few category/subcategory pages to confirm the ancillary intro text is gone."
