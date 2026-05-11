# bridge-old-sketches-index-to-split-repos.ps1
# Updates the old sketches-and-drawings landing page so it keeps the old public flow:
#
# Catalogue raisonne home
# -> ron-english-sketches-and-drawings/Sketches/
# -> category cards
# -> new split-repo category pages
#
# IMPORTANT:
# - This script edits ONLY:
#   D:\github\ron-english-sketches-and-drawings\Sketches\index.html
# - It does NOT delete, move, or rename anything.
# - It does NOT edit the six split content repos.
# - It creates a backup before editing.
# - It preserves the existing design/style of the old Sketches index page.
# - It only changes href="" values for category links it recognizes.

$ErrorActionPreference = "Stop"

$RepoRoot = "D:\github\ron-english-sketches-and-drawings"
$SketchesIndex = Join-Path $RepoRoot "Sketches\index.html"

$ScriptName = "bridge-old-sketches-index-to-split-repos"
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

$BackupRoot = "D:\github-backups\ron-english-sketches-and-drawings"
$BackupFolder = Join-Path $BackupRoot ($ScriptName + "-" + $Timestamp)

$AuditFolder = Join-Path $RepoRoot "_split-bridge-audit"
$LogPath = Join-Path $AuditFolder ($ScriptName + "-" + $Timestamp + "-log.txt")
$UpdatedLinksCsvPath = Join-Path $AuditFolder ($ScriptName + "-" + $Timestamp + "-updated-links.csv")
$UnchangedSketchesLinksCsvPath = Join-Path $AuditFolder ($ScriptName + "-" + $Timestamp + "-unchanged-local-sketches-links.csv")
$SummaryPath = Join-Path $AuditFolder ($ScriptName + "-" + $Timestamp + "-summary.txt")

$Mappings = @(
    # Grins
    @{
        Key = "grins"
        Label = "Grins"
        Url = "https://ronenglish-archive.github.io/ron-english-sketches-grins/Sketches/grins/index.html"
        Aliases = @("grins", "grin", "grinnies", "grinnie")
    },

    # Aliens
    @{
        Key = "aliens"
        Label = "Aliens"
        Url = "https://ronenglish-archive.github.io/ron-english-sketches-aliens/Sketches/aliens/index.html"
        Aliases = @("aliens", "alien")
    },

    # Animals
    @{
        Key = "amphibians"
        Label = "Amphibians"
        Url = "https://ronenglish-archive.github.io/ron-english-sketches-animals/Sketches/amphibians/index.html"
        Aliases = @("amphibians", "amphibian", "frogs", "salamanders")
    },
    @{
        Key = "aquatic-dwellers"
        Label = "Aquatic Dwellers"
        Url = "https://ronenglish-archive.github.io/ron-english-sketches-animals/Sketches/aquatic-dwellers/index.html"
        Aliases = @("aquatic-dwellers", "aquatic dwellers", "aquatic", "fish", "mermaids", "octopi", "sharks", "dolphins")
    },
    @{
        Key = "avians"
        Label = "Avians"
        Url = "https://ronenglish-archive.github.io/ron-english-sketches-animals/Sketches/avians/index.html"
        Aliases = @("avians", "avian", "birds", "ducks", "buzzards", "eagles", "chickens")
    },
    @{
        Key = "bears"
        Label = "Bears"
        Url = "https://ronenglish-archive.github.io/ron-english-sketches-animals/Sketches/bears/index.html"
        Aliases = @("bears", "bear")
    },
    @{
        Key = "bigfoot"
        Label = "Bigfoot"
        Url = "https://ronenglish-archive.github.io/ron-english-sketches-animals/Sketches/bigfoot/index.html"
        Aliases = @("bigfoot")
    },
    @{
        Key = "canines-and-felines"
        Label = "Canines and Felines"
        Url = "https://ronenglish-archive.github.io/ron-english-sketches-animals/Sketches/canines-and-felines/index.html"
        Aliases = @("canines-and-felines", "canines and felines", "canines & felines", "canines", "felines", "dogs", "cats")
    },
    @{
        Key = "insects"
        Label = "Insects"
        Url = "https://ronenglish-archive.github.io/ron-english-sketches-animals/Sketches/insects/index.html"
        Aliases = @("insects", "insect")
    },
    @{
        Key = "monkeys"
        Label = "Monkeys"
        Url = "https://ronenglish-archive.github.io/ron-english-sketches-animals/Sketches/monkeys/index.html"
        Aliases = @("monkeys", "monkey")
    },
    @{
        Key = "reptiles"
        Label = "Reptiles"
        Url = "https://ronenglish-archive.github.io/ron-english-sketches-animals/Sketches/reptiles/index.html"
        Aliases = @("reptiles", "reptile")
    },
    @{
        Key = "small-mammals"
        Label = "Small Mammals"
        Url = "https://ronenglish-archive.github.io/ron-english-sketches-animals/Sketches/small-mammals/index.html"
        Aliases = @("small-mammals", "small mammals", "small mammal")
    },
    @{
        Key = "snails"
        Label = "Snails"
        Url = "https://ronenglish-archive.github.io/ron-english-sketches-animals/Sketches/snails/index.html"
        Aliases = @("snails", "snail")
    },
    @{
        Key = "ungulates"
        Label = "Ungulates"
        Url = "https://ronenglish-archive.github.io/ron-english-sketches-animals/Sketches/ungulates/index.html"
        Aliases = @("ungulates", "ungulate", "horses", "cows", "pigs", "sheep", "deer")
    },

    # Mythic / Dark
    @{
        Key = "brains"
        Label = "Brains"
        Url = "https://ronenglish-archive.github.io/ron-english-sketches-mythic-dark/Sketches/brains/index.html"
        Aliases = @("brains", "brain")
    },
    @{
        Key = "kaijus"
        Label = "Kaijus"
        Url = "https://ronenglish-archive.github.io/ron-english-sketches-mythic-dark/Sketches/kaijus/index.html"
        Aliases = @("kaijus", "kaiju")
    },
    @{
        Key = "kursed"
        Label = "Kursed"
        Url = "https://ronenglish-archive.github.io/ron-english-sketches-mythic-dark/Sketches/kursed/index.html"
        Aliases = @("kursed", "kursed characters")
    },
    @{
        Key = "light-cult"
        Label = "Light Cult"
        Url = "https://ronenglish-archive.github.io/ron-english-sketches-mythic-dark/Sketches/light-cult/index.html"
        Aliases = @("light-cult", "light cult")
    },
    @{
        Key = "mythical-beings"
        Label = "Mythical Beings"
        Url = "https://ronenglish-archive.github.io/ron-english-sketches-mythic-dark/Sketches/mythical-beings/index.html"
        Aliases = @("mythical-beings", "mythical beings", "mythical")
    },
    @{
        Key = "skeletons"
        Label = "Skeletons"
        Url = "https://ronenglish-archive.github.io/ron-english-sketches-mythic-dark/Sketches/skeletons/index.html"
        Aliases = @("skeletons", "skeleton")
    },
    @{
        Key = "tots"
        Label = "Tots"
        Url = "https://ronenglish-archive.github.io/ron-english-sketches-mythic-dark/Sketches/tots/index.html"
        Aliases = @("tots", "tot")
    },
    @{
        Key = "yin-yangs"
        Label = "Yin Yangs"
        Url = "https://ronenglish-archive.github.io/ron-english-sketches-mythic-dark/Sketches/yin-yangs/index.html"
        Aliases = @("yin-yangs", "yin yangs", "yin-yang", "yin yang")
    },

    # Objects
    @{
        Key = "objects"
        Label = "Objects"
        Url = "https://ronenglish-archive.github.io/ron-english-sketches-objects/Sketches/objects/index.html"
        Aliases = @("objects", "object")
    },
    @{
        Key = "flowers"
        Label = "Flowers"
        Url = "https://ronenglish-archive.github.io/ron-english-sketches-objects/Sketches/flowers/index.html"
        Aliases = @("flowers", "flower")
    },
    @{
        Key = "animation"
        Label = "Animation"
        Url = "https://ronenglish-archive.github.io/ron-english-sketches-objects/Sketches/index.html"
        Aliases = @("animation", "animation sketches", "animations")
    },

    # Pop Culture
    @{
        Key = "celebrity-characters"
        Label = "Celebrity Characters"
        Url = "https://ronenglish-archive.github.io/ron-english-sketches-pop-culture/Sketches/celebrity-characters/index.html"
        Aliases = @("celebrity-characters", "celebrity characters", "celebrities")
    },
    @{
        Key = "character-balls"
        Label = "Character Balls"
        Url = "https://ronenglish-archive.github.io/ron-english-sketches-pop-culture/Sketches/character-balls/index.html"
        Aliases = @("character-balls", "character balls")
    },
    @{
        Key = "combrats"
        Label = "Combrats"
        Url = "https://ronenglish-archive.github.io/ron-english-sketches-pop-culture/Sketches/combrats/index.html"
        Aliases = @("combrats", "combrat")
    },
    @{
        Key = "tvities"
        Label = "TVities"
        Url = "https://ronenglish-archive.github.io/ron-english-sketches-pop-culture/Sketches/tvities/index.html"
        Aliases = @("tvities", "tvitie")
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

function Normalize-Text {
    param([string]$Text)

    if ($null -eq $Text) {
        return ""
    }

    $Value = [System.Net.WebUtility]::HtmlDecode($Text)
    $Value = $Value.ToLowerInvariant()
    $Value = $Value -replace "&amp;", "and"
    $Value = $Value -replace "&", "and"
    $Value = $Value -replace "[\s_]+", "-"
    $Value = $Value -replace "[^a-z0-9\-]+", ""
    $Value = $Value -replace "-+", "-"
    $Value = $Value.Trim("-")

    return $Value
}

function Get-PlainText {
    param([string]$HtmlText)

    $NoTags = [regex]::Replace($HtmlText, "<[^>]+>", "")
    $Decoded = [System.Net.WebUtility]::HtmlDecode($NoTags)
    return $Decoded.Trim()
}

function Decode-Href {
    param([string]$Href)

    try {
        return [System.Uri]::UnescapeDataString($Href)
    }
    catch {
        return $Href
    }
}

function Get-MappingForAnchor {
    param(
        [string]$Href,
        [string]$AnchorText
    )

    $DecodedHref = Decode-Href $Href
    $HrefNoQuery = ($DecodedHref -split "[?#]")[0]
    $Combined = ($HrefNoQuery + " " + $AnchorText)
    $CombinedNorm = Normalize-Text $Combined

    foreach ($Map in $Mappings) {
        $KeyNorm = Normalize-Text $Map.Key
        $LabelNorm = Normalize-Text $Map.Label

        # Strong match from href/path.
        if ($CombinedNorm -match ("(^|-)"+[regex]::Escape($KeyNorm)+"(-|$)")) {
            return $Map
        }

        # Strong match from visible label.
        if ($CombinedNorm -match ("(^|-)"+[regex]::Escape($LabelNorm)+"(-|$)")) {
            return $Map
        }

        foreach ($Alias in $Map.Aliases) {
            $AliasNorm = Normalize-Text $Alias
            if ($AliasNorm -and $CombinedNorm -match ("(^|-)"+[regex]::Escape($AliasNorm)+"(-|$)")) {
                return $Map
            }
        }
    }

    return $null
}

function Backup-SketchesIndex {
    Ensure-Folder $BackupFolder

    $BackupIndex = Join-Path $BackupFolder "Sketches\index.html"
    Ensure-Folder (Split-Path -Parent $BackupIndex)

    Copy-Item -LiteralPath $SketchesIndex -Destination $BackupIndex -Force
    Write-Log ("Backed up Sketches index to: " + $BackupIndex)
}

function Update-SketchesIndexLinks {
    $Original = Get-Content -LiteralPath $SketchesIndex -Raw
    $Updated = $Original

    $UpdatedRows = @()

    # Match full anchors with href attributes.
    $AnchorRegex = [regex]'(?is)<a\b[^>]*\bhref\s*=\s*(["''])([^"'']+)\1[^>]*>.*?</a>'
    $HrefRegex = [regex]'(?is)\bhref\s*=\s*(["''])([^"'']+)\1'

    $Matches = @($AnchorRegex.Matches($Updated))

    # Work backwards so indices remain valid.
    for ($i = $Matches.Count - 1; $i -ge 0; $i--) {
        $Match = $Matches[$i]
        $AnchorHtml = $Match.Value
        $HrefMatch = $HrefRegex.Match($AnchorHtml)

        if (-not $HrefMatch.Success) {
            continue
        }

        $Quote = $HrefMatch.Groups[1].Value
        $OldHref = $HrefMatch.Groups[2].Value
        $AnchorText = Get-PlainText $AnchorHtml

        # Skip anchors that are clearly not category links.
        if ($OldHref -match '^(?i)mailto:|tel:|#|javascript:') {
            continue
        }

        $Map = Get-MappingForAnchor -Href $OldHref -AnchorText $AnchorText

        if ($null -eq $Map) {
            continue
        }

        $NewHref = $Map.Url

        if ($OldHref -eq $NewHref) {
            continue
        }

        $NewAnchorHtml = $HrefRegex.Replace($AnchorHtml, ('href=' + $Quote + $NewHref + $Quote), 1)

        if ($NewAnchorHtml -ne $AnchorHtml) {
            $Updated = $Updated.Substring(0, $Match.Index) + $NewAnchorHtml + $Updated.Substring($Match.Index + $Match.Length)

            $UpdatedRows += [PSCustomObject]@{
                MatchedCategory = $Map.Label
                AnchorText = $AnchorText
                OldHref = $OldHref
                NewHref = $NewHref
            }
        }
    }

    if ($Updated -ne $Original) {
        Set-Content -LiteralPath $SketchesIndex -Value $Updated -Encoding UTF8
        Write-Log ("Updated Sketches index: " + $SketchesIndex)
    }
    else {
        Write-Log "No changes were made to Sketches index."
    }

    # Reverse rows back into document order for easier reading.
    $UpdatedRows = @($UpdatedRows | Select-Object -Last $UpdatedRows.Count)
    $UpdatedRows | Export-Csv -LiteralPath $UpdatedLinksCsvPath -NoTypeInformation -Encoding UTF8

    return $UpdatedRows
}

function Find-UnchangedLocalSketchesLinks {
    $Rows = @()
    $Content = Get-Content -LiteralPath $SketchesIndex -Raw

    $AnchorRegex = [regex]'(?is)<a\b[^>]*\bhref\s*=\s*(["''])([^"'']+)\1[^>]*>.*?</a>'

    foreach ($Match in $AnchorRegex.Matches($Content)) {
        $AnchorHtml = $Match.Value
        $OldHref = $Match.Groups[2].Value
        $AnchorText = Get-PlainText $AnchorHtml

        if ($OldHref -match '^(?i)https?:|mailto:|tel:|#|javascript:') {
            continue
        }

        # We only care about links that still look like local category/page links.
        if ($OldHref -match '\.html|/|\\') {
            $Rows += [PSCustomObject]@{
                AnchorText = $AnchorText
                Href = $OldHref
                Note = "Local href remains after bridge update. Review if this should point to a split repo."
            }
        }
    }

    $Rows | Export-Csv -LiteralPath $UnchangedSketchesLinksCsvPath -NoTypeInformation -Encoding UTF8

    return $Rows
}

function Write-Summary {
    param(
        [array]$UpdatedRows,
        [array]$UnchangedRows
    )

    $SummaryLines = @()
    $SummaryLines += "Old Sketches index bridge summary"
    $SummaryLines += ("Generated: " + (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
    $SummaryLines += ""
    $SummaryLines += "Edited file:"
    $SummaryLines += $SketchesIndex
    $SummaryLines += ""
    $SummaryLines += "Backup folder:"
    $SummaryLines += $BackupFolder
    $SummaryLines += ""
    $SummaryLines += ("Category links updated: " + $UpdatedRows.Count)
    $SummaryLines += ("Remaining local links reported for review: " + $UnchangedRows.Count)
    $SummaryLines += ""
    $SummaryLines += "Updated links CSV:"
    $SummaryLines += $UpdatedLinksCsvPath
    $SummaryLines += ""
    $SummaryLines += "Unchanged local links CSV:"
    $SummaryLines += $UnchangedSketchesLinksCsvPath
    $SummaryLines += ""
    $SummaryLines += "Important:"
    $SummaryLines += "- The visual design of Sketches/index.html was preserved."
    $SummaryLines += "- Only href values for recognized category links were changed."
    $SummaryLines += "- No files were deleted, moved, or renamed."
    $SummaryLines += "- The six split repos were not changed."

    Set-Content -LiteralPath $SummaryPath -Value $SummaryLines -Encoding UTF8
}

# Main run

Ensure-Folder $AuditFolder

Write-Log "Starting old Sketches index bridge update."
Write-Log ("Repo root: " + $RepoRoot)
Write-Log ("Sketches index: " + $SketchesIndex)

if (-not (Test-Path -LiteralPath $RepoRoot)) {
    throw ("Repo root does not exist: " + $RepoRoot)
}

if (-not (Test-Path -LiteralPath $SketchesIndex)) {
    throw ("Sketches index does not exist: " + $SketchesIndex)
}

Backup-SketchesIndex

$UpdatedRows = @(Update-SketchesIndexLinks)
$UnchangedRows = @(Find-UnchangedLocalSketchesLinks)

Write-Summary -UpdatedRows $UpdatedRows -UnchangedRows $UnchangedRows

Write-Log ("Category links updated: " + $UpdatedRows.Count)
Write-Log ("Remaining local links reported for review: " + $UnchangedRows.Count)
Write-Log "Done."

Write-Host ""
Write-Host "DONE. The old Sketches index was updated to point category links to the split repos."
Write-Host ""
Write-Host "Edited file:"
Write-Host $SketchesIndex
Write-Host ""
Write-Host "Backup folder:"
Write-Host $BackupFolder
Write-Host ""
Write-Host "Now test this local file:"
Write-Host "D:\github\ron-english-sketches-and-drawings\Sketches\index.html"
Write-Host ""
Write-Host "Click Aliens, Grins/Grinnies, Animals categories, Objects, and Pop Culture categories."
Write-Host "They should open the new split-repo live pages."
Write-Host ""
Write-Host "Updated links CSV:"
Write-Host $UpdatedLinksCsvPath
Write-Host ""
Write-Host "Unchanged local links CSV:"
Write-Host $UnchangedSketchesLinksCsvPath
