Set-Location "D:\github\ron-english-sketches-and-drawings"

$repo = "D:\github\ron-english-sketches-and-drawings"
$ducksFolder = Join-Path $repo "Sketches\avians\ducks"
$reportFile = Join-Path $repo "ducks-final-encoding-check.txt"

$backupRoot = Join-Path $repo "_script-backups"
$backupFolder = Join-Path $backupRoot ("ducks-html-before-final-encoding-fix-" + (Get-Date -Format "yyyyMMdd-HHmmss"))

New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null

Get-ChildItem -LiteralPath $ducksFolder -Filter "*.html" | ForEach-Object {
  Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $backupFolder $_.Name) -Force
}

$utf8Bom = New-Object System.Text.UTF8Encoding($true)

function Fix-MojibakeText {
  param([string]$text)

  # First decode HTML entities. This catches patterns like:
  # it&#226;€™s  -> itâ€™s
  # Raisonn&eacute; -> Raisonné
  $text = [System.Net.WebUtility]::HtmlDecode($text)

  # Build common mojibake strings from codepoints so PowerShell cannot misread them.
  $badRightApos = -join ([char]0x00E2, [char]0x20AC, [char]0x2122) # â€™
  $badLeftApos  = -join ([char]0x00E2, [char]0x20AC, [char]0x02DC) # â€˜
  $badOpenQuote = -join ([char]0x00E2, [char]0x20AC, [char]0x0153) # â€œ
  $badCloseQuote1 = -join ([char]0x00E2, [char]0x20AC, [char]0x009D) # â€�
  $badCloseQuote2 = -join ([char]0x00E2, [char]0x20AC, [char]0xFFFD) # â€� as replacement form
  $badEnDash    = -join ([char]0x00E2, [char]0x20AC, [char]0x201C) # â€“
  $badEmDash    = -join ([char]0x00E2, [char]0x20AC, [char]0x201D) # â€”
  $badEllipsis  = -join ([char]0x00E2, [char]0x20AC, [char]0x00A6) # â€¦
  $badLeftArrow = -join ([char]0x00E2, [char]0x2020, [char]0x0090) # â†

  # Replace mojibake with safe ASCII or HTML entities.
  $text = $text.Replace($badRightApos, "'")
  $text = $text.Replace($badLeftApos, "'")
  $text = $text.Replace($badOpenQuote, '"')
  $text = $text.Replace($badCloseQuote1, '"')
  $text = $text.Replace($badCloseQuote2, '"')
  $text = $text.Replace($badEnDash, "-")
  $text = $text.Replace($badEmDash, "-")
  $text = $text.Replace($badEllipsis, "...")
  $text = $text.Replace($badLeftArrow, "&larr;")

  # Also catch literal visible forms if they survived.
  $text = $text.Replace("â€™", "'")
  $text = $text.Replace("â€˜", "'")
  $text = $text.Replace("â€œ", '"')
  $text = $text.Replace("â€�", '"')
  $text = $text.Replace("â€“", "-")
  $text = $text.Replace("â€”", "-")
  $text = $text.Replace("â€¦", "...")
  $text = $text.Replace("â†", "&larr;")

  # Replace actual curly punctuation with safe ASCII so local browsers cannot misread it.
  $text = $text.Replace([string][char]0x2019, "'") # ’
  $text = $text.Replace([string][char]0x2018, "'") # ‘
  $text = $text.Replace([string][char]0x201C, '"') # “
  $text = $text.Replace([string][char]0x201D, '"') # ”
  $text = $text.Replace([string][char]0x2014, "-") # —
  $text = $text.Replace([string][char]0x2013, "-") # –

  # Fix the catalogue title using an HTML entity for the accent.
  $text = $text.Replace("Catalogue RaisonnÃ©", "Catalogue Raisonn&eacute;")
  $text = $text.Replace("Catalogue Raisonné", "Catalogue Raisonn&eacute;")

  # Keep the back-arrow safe.
  $text = $text -replace ">.*?Back to Ducks</a>", ">&larr; Back to Ducks</a>"

  # Re-escape ampersands inside src/href attributes only.
  # This restores filenames like B&W.png to B&amp;W.png after HtmlDecode.
  $text = [regex]::Replace($text, '(?<attr>\b(?:src|href)=")(?<val>[^"]*)"', {
    param($m)
    $attr = $m.Groups["attr"].Value
    $val = $m.Groups["val"].Value

    # Do not double-escape existing entities; HtmlDecode already decoded them,
    # so this is normally safe.
    $val = $val.Replace("&", "&amp;")

    return $attr + $val + '"'
  })

  return $text
}

Get-ChildItem -LiteralPath $ducksFolder -Filter "*.html" | ForEach-Object {
  $path = $_.FullName
  $text = Get-Content -LiteralPath $path -Raw
  $fixed = Fix-MojibakeText $text
  [System.IO.File]::WriteAllText($path, $fixed, $utf8Bom)
}

# Verification report.
$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("DUCKS FINAL ENCODING CHECK")
$lines.Add("Generated: $(Get-Date)")
$lines.Add("Folder: $ducksFolder")
$lines.Add("")
$lines.Add("Files still containing suspicious patterns:")
$lines.Add("------------------------------------------")

$found = $false

Get-ChildItem -LiteralPath $ducksFolder -Filter "*.html" | Sort-Object Name | ForEach-Object {
  $text = Get-Content -LiteralPath $_.FullName -Raw

  if (
    $text.Contains("&#226;") -or
    $text.Contains("â") -or
    $text.Contains("Ã") -or
    $text.Contains([string][char]0x2019)
  ) {
    $found = $true
    $lines.Add($_.Name)
  }
}

if (-not $found) {
  $lines.Add("None found.")
}

$lines.Add("")
$lines.Add("Allie lines containing poem text:")
$lines.Add("------------------------------------------")

$allieFile = Join-Path $ducksFolder "allie-quack.html"
if (Test-Path -LiteralPath $allieFile) {
  $allieText = Get-Content -LiteralPath $allieFile -Raw
  ($allieText -split "`r?`n") | ForEach-Object {
    if ($_ -match "it|Allie|you|pins|Back to Ducks|Raisonn") {
      $lines.Add($_)
    }
  }
}
else {
  $lines.Add("allie-quack.html not found.")
}

$lines | Set-Content -LiteralPath $reportFile -Encoding UTF8

Write-Host ""
Write-Host "DONE - Ducks final encoding fix."
Write-Host "Backup created here:"
Write-Host $backupFolder
Write-Host ""
Write-Host "Verification report:"
Write-Host $reportFile
Write-Host ""
Write-Host "Open:"
Write-Host (Join-Path $ducksFolder "allie-quack.html")
