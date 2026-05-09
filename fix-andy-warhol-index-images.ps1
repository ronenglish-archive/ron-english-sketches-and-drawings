[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$RepoRoot = 'D:\github\ron-english-sketches-and-drawings'
$AndyIndexPath = Join-Path $RepoRoot 'Sketches\celebrity-characters\andy-warhol\index.html'
$ImageFolderName = 'Andy Warhol'

$PopTotImage = 'Pop Tot Baby Warhol colorway 5.jpg'
$YoungAndyImage = 'Young Andy 25 original.jpg'

function Encode-Part {
    param([AllowEmptyString()][string]$Text)

    if ([string]::IsNullOrEmpty($Text)) {
        return $Text
    }

    return [System.Uri]::EscapeDataString($Text)
}

function New-AndyImageSrc {
    param([Parameter(Mandatory=$true)][string]$FileName)

    return '../../../images/Sketches/celebrity-characters/' + (Encode-Part $ImageFolderName) + '/' + (Encode-Part $FileName)
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
        $backupPath = Join-Path $backupDir "$name-before-warhol-index-image-fix-$timestamp$ext"

        Copy-Item -LiteralPath $Path -Destination $backupPath -Force
        Write-Host "Backup created: $backupPath"
    }
}

function Test-ImageExists {
    param([Parameter(Mandatory=$true)][string]$FileName)

    $path = Join-Path $RepoRoot "images\Sketches\celebrity-characters\$ImageFolderName\$FileName"
    if (-not (Test-Path -LiteralPath $path)) {
        Write-Warning "Image file not found: $path"
    }
}

function Update-CardImageByHref {
    param(
        [Parameter(Mandatory=$true)][string]$Html,
        [Parameter(Mandatory=$true)][string[]]$HrefCandidates,
        [Parameter(Mandatory=$true)][string]$NewSrc,
        [Parameter(Mandatory=$true)][string]$NewAlt,
        [Parameter(Mandatory=$true)][string]$Label
    )

    foreach ($href in $HrefCandidates) {
        $escapedHref = [regex]::Escape($href)

        $cardPattern = '(?is)<a\b(?=[^>]*\bclass="[^"]*\bgallery-item\b[^"]*")[^>]*href="' + $escapedHref + '"[^>]*>.*?</a>'

        if ($Html -match $cardPattern) {
            $updated = [regex]::Replace($Html, $cardPattern, {
                param($match)

                $card = $match.Value

                $card = [regex]::Replace($card, '(<img\b[^>]*\bsrc=")[^"]*(")', {
                    param($imgMatch)
                    return $imgMatch.Groups[1].Value + $NewSrc + $imgMatch.Groups[2].Value
                }, 1)

                $card = [regex]::Replace($card, '(<img\b[^>]*\balt=")[^"]*(")', {
                    param($altMatch)
                    return $altMatch.Groups[1].Value + $NewAlt + $altMatch.Groups[2].Value
                }, 1)

                return $card
            }, 1)

            Write-Host "Updated $Label card image using href: $href"
            return [pscustomobject]@{
                Html = $updated
                Changed = $true
            }
        }
    }

    Write-Warning "Could not find $Label card by exact href. Tried: $($HrefCandidates -join ', ')"
    return [pscustomobject]@{
        Html = $Html
        Changed = $false
    }
}

if (-not (Test-Path -LiteralPath $AndyIndexPath)) {
    throw "Andy Warhol index page not found: $AndyIndexPath"
}

Test-ImageExists -FileName $PopTotImage
Test-ImageExists -FileName $YoungAndyImage

Backup-FileIfExists -Path $AndyIndexPath

$html = [System.IO.File]::ReadAllText($AndyIndexPath)
$originalHtml = $html

$popTotSrc = New-AndyImageSrc -FileName $PopTotImage
$youngAndySrc = New-AndyImageSrc -FileName $YoungAndyImage

# Pop Tot Baby Warhol should use Pop Tot Baby Warhol colorway 5.jpg.
$result = Update-CardImageByHref `
    -Html $html `
    -HrefCandidates @('pop-tot-baby-warhol/index.html','pop-tot-warhol/index.html') `
    -NewSrc $popTotSrc `
    -NewAlt 'Pop Tot Baby Warhol drawings by Ron English' `
    -Label 'Pop Tot Baby Warhol'

$html = $result.Html

# Young Andy should use Young Andy 25 original.jpg.
$result = Update-CardImageByHref `
    -Html $html `
    -HrefCandidates @('young-andy/index.html','young-andy-25/index.html','young-andy-25-original/index.html') `
    -NewSrc $youngAndySrc `
    -NewAlt 'Young Andy drawings by Ron English' `
    -Label 'Young Andy'

$html = $result.Html

if ($html -ne $originalHtml) {
    [System.IO.File]::WriteAllText($AndyIndexPath, $html, [System.Text.UTF8Encoding]::new($false))
    Write-Host ""
    Write-Host "Updated Andy Warhol index:"
    Write-Host "  $AndyIndexPath"
}
else {
    Write-Host ""
    Write-Host "No changes were made. The expected cards may use different hrefs."
}

Write-Host ""
Write-Host "Expected index images now:"
Write-Host "  Pop Tot Baby Warhol -> $PopTotImage"
Write-Host "  Young Andy -> $YoungAndyImage"
Write-Host ""
Write-Host "Refresh this page with Ctrl+F5:"
Write-Host "  D:\github\ron-english-sketches-and-drawings\Sketches\celebrity-characters\andy-warhol\index.html"
