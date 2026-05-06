Set-Location "D:\github\ron-english-sketches-and-drawings"

$repo = "D:\github\ron-english-sketches-and-drawings"
$ducksFolder = Join-Path $repo "Sketches\avians\ducks"
$reportFile = Join-Path $repo "ducks-final-encoding-check.txt"

$backupRoot = Join-Path $repo "_script-backups"
$backupFolder = Join-Path $backupRoot ("ducks-html-before-entity-fix-final2-" + (Get-Date -Format "yyyyMMdd-HHmmss"))

New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null

Get-ChildItem -LiteralPath $ducksFolder -Filter "*.html" | ForEach-Object {
  Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $backupFolder $_.Name) -Force
}

$utf8Bom = New-Object System.Text.UTF8Encoding($true)

function Join-Chars {
  param([int[]]$Codes)

  $s = ""
  foreach ($code in $Codes) {
    $s += [char]$code
  }
  return $s
}

function Fix-Text {
  param([string]$Text)

  # Build problematic mojibake sequences from codepoints so the script itself
  # does not contain broken smart quotes or dashes.
  $euro = [char]0x20AC
  $tm = [char]0x2122
  $tilde = [char]0x02DC
  $oe = [char]0x0153
  $c1quote = [char]0x009D
  $ndashLike = [char]0x201C
  $mdashLike = [char]0x201D
  $ellipsisLike = [char]0x00A6

  $literalApos = (Join-Chars @(0x00E2,0x20AC,0x2122))
  $entityApos = "&#226;" + $euro + $tm

  $literalLeftQuote = (Join-Chars @(0x00E2,0x20AC,0x02DC))
  $entityLeftQuote = "&#226;" + $euro + $tilde

  $literalOpenQuote = (Join-Chars @(0x00E2,0x20AC,0x0153))
  $entityOpenQuote = "&#226;" + $euro + $oe

  $literalCloseQuote = (Join-Chars @(0x00E2,0x20AC,0x009D))
  $entityCloseQuote = "&#226;" + $euro + $c1quote

  $literalEnDash = (Join-Chars @(0x00E2,0x20AC,0x201C))
  $entityEnDash = "&#226;" + $euro + $ndashLike

  $literalEmDash = (Join-Chars @(0x00E2,0x20AC,0x201D))
  $entityEmDash = "&#226;" + $euro + $mdashLike

  $literalEllipsis = (Join-Chars @(0x00E2,0x20AC,0x00A6))
  $entityEllipsis = "&#226;" + $euro + $ellipsisLike

  # Entity-encoded mojibake from WebUtility.HtmlEncode, like: &#226;€™
  $Text = $Text.Replace($entityApos, "'")
  $Text = $Text.Replace($entityLeftQuote, "'")
  $Text = $Text.Replace($entityOpenQuote, '"')
  $Text = $Text.Replace($entityCloseQuote, '"')
  $Text = $Text.Replace($entityEnDash, "-")
  $Text = $Text.Replace($entityEmDash, "-")
  $Text = $Text.Replace($entityEllipsis, "...")

  # Numeric entity variants, if any.
  $Text = $Text.Replace("&#226;&#8364;&#8482;", "'")
  $Text = $Text.Replace("&#226;&#8364;&#732;", "'")
  $Text = $Text.Replace("&#226;&#8364;&#339;", '"')
  $Text = $Text.Replace("&#226;&#8364;&#157;", '"')
  $Text = $Text.Replace("&#226;&#8364;&#8220;", "-")
  $Text = $Text.Replace("&#226;&#8364;&#8221;", "-")
  $Text = $Text.Replace("&#226;&#8364;&#166;", "...")

  # Literal mojibake variants, if any.
  $Text = $Text.Replace($literalApos, "'")
  $Text = $Text.Replace($literalLeftQuote, "'")
  $Text = $Text.Replace($literalOpenQuote, '"')
  $Text = $Text.Replace($literalCloseQuote, '"')
  $Text = $Text.Replace($literalEnDash, "-")
  $Text = $Text.Replace($literalEmDash, "-")
  $Text = $Text.Replace($literalEllipsis, "...")

  # Fix catalogue title accent in two common mojibake forms.
  $badEAcute = (Join-Chars @(0x00C3,0x00A9))  # Ã©
  $Text = $Text.Replace("Catalogue Raisonn" + $badEAcute, "Catalogue Raisonn&eacute;")
  $Text = $Text.Replace("Catalogue Raisonn&#195;&#169;", "Catalogue Raisonn&eacute;")

  # Keep the back arrow safe.
  $Text = $Text -replace ">.*?Back to Ducks</a>", ">&larr; Back to Ducks</a>"

  return $Text
}

Get-ChildItem -LiteralPath $ducksFolder -Filter "*.html" | ForEach-Object {
  $path = $_.FullName
  $text = [System.IO.File]::ReadAllText($path)
  $fixed = Fix-Text $text

  [System.IO.File]::WriteAllText($path, $fixed, $utf8Bom)
}

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("DUCKS FINAL ENCODING CHECK")
$lines.Add("Generated: $(Get-Date)")
$lines.Add("Folder: $ducksFolder")
$lines.Add("Backup: $backupFolder")
$lines.Add("")

$badCount = 0

Get-ChildItem -LiteralPath $ducksFolder -Filter "*.html" | Sort-Object Name | ForEach-Object {
  $path = $_.FullName
  $text = [System.IO.File]::ReadAllText($path)

  if ($text.Contains("&#226;") -or $text.Contains("&#195;") -or $text.Contains("â") -or $text.Contains("Ã")) {
    $badCount++
    $lines.Add("STILL HAS POSSIBLE MOJIBAKE: $($_.Name)")

    $text -split "`r?`n" | ForEach-Object {
      if ($_.Contains("&#226;") -or $_.Contains("&#195;") -or $_.Contains("â") -or $_.Contains("Ã")) {
        $lines.Add("  " + $_)
      }
    }
    $lines.Add("")
  }
}

if ($badCount -eq 0) {
  $lines.Add("No &#226;, &#195;, â, or Ã patterns found in Ducks HTML files.")
}

$allie = Join-Path $ducksFolder "allie-quack.html"
if (Test-Path -LiteralPath $allie) {
  $lines.Add("")
  $lines.Add("Allie relevant lines:")
  $allieText = [System.IO.File]::ReadAllText($allie)
  $allieText -split "`r?`n" | ForEach-Object {
    if ($_ -match "always the pins|next of kin|racked again|Catalogue Raisonn|Back to Ducks") {
      $lines.Add("  " + $_)
    }
  }
}

$lines | Set-Content -LiteralPath $reportFile -Encoding UTF8

Write-Host ""
Write-Host "DONE - FINAL DUCKS ENCODING FIX 2"
Write-Host "Backup created here:"
Write-Host $backupFolder
Write-Host ""
Write-Host "Verification report:"
Write-Host $reportFile
Write-Host ""
Write-Host "Open:"
Write-Host (Join-Path $ducksFolder "allie-quack.html")
