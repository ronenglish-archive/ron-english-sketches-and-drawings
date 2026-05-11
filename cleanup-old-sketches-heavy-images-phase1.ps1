# cleanup-old-sketches-heavy-images-phase1.ps1
# Phase 1 cleanup for the old ron-english-sketches-and-drawings repo.
#
# Goal:
# Keep the old public flow:
#   ron-english-catalogue-raisonne
#   -> ron-english-sketches-and-drawings/Sketches/
#   -> split-repo category pages
#
# What this script does:
# 1. Backs up Sketches\index.html.
# 2. Removes the broken Words & Phrases card/link from Sketches\index.html.
# 3. Scans Sketches\index.html for local image/file references that must be preserved.
# 4. Moves old heavy immediate subfolders under images\Sketches into a backup folder,
#    while preserving root-level hero images and any protected referenced paths.
# 5. Writes cleanup reports.
#
# IMPORTANT:
# - This script changes ONLY the old repo:
#   D:\github\ron-english-sketches-and-drawings
# - It does NOT edit the six split repos.
# - It does NOT permanently delete old image folders.
# - It MOVES removable image folders to:
#   D:\github-backups\ron-english-sketches-and-drawings\cleanup-old-sketches-heavy-images-phase1-TIMESTAMP
# - It does NOT remove old Sketches category page folders yet.
# - After running, test locally before committing/pushing.

$ErrorActionPreference = "Stop"

$RepoRoot = "D:\github\ron-english-sketches-and-drawings"
$SketchesIndex = Join-Path $RepoRoot "Sketches\index.html"
$ImagesSketchesRoot = Join-Path $RepoRoot "images\Sketches"

$ScriptName = "cleanup-old-sketches-heavy-images-phase1"
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

$BackupRoot = "D:\github-backups\ron-english-sketches-and-drawings"
$BackupFolder = Join-Path $BackupRoot ($ScriptName + "-" + $Timestamp)

$AuditFolder = Join-Path $RepoRoot "_cleanup-audit"
$LogPath = Join-Path $AuditFolder ($ScriptName + "-" + $Timestamp + "-log.txt")
$MovedFoldersCsvPath = Join-Path $AuditFolder ($ScriptName + "-" + $Timestamp + "-moved-image-folders.csv")
$KeptFoldersCsvPath = Join-Path $AuditFolder ($ScriptName + "-" + $Timestamp + "-kept-image-folders.csv")
$ProtectedPathsCsvPath = Join-Path $AuditFolder ($ScriptName + "-" + $Timestamp + "-protected-paths.csv")
$MissingBridgeRefsCsvPath = Join-Path $AuditFolder ($ScriptName + "-" + $Timestamp + "-missing-bridge-references-after-cleanup.csv")
$WordsPhrasesReportCsvPath = Join-Path $AuditFolder ($ScriptName + "-" + $Timestamp + "-words-phrases-removal-report.csv")
$SummaryPath = Join-Path $AuditFolder ($ScriptName + "-" + $Timestamp + "-summary.txt")

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

function Format-Bytes {
    param([Int64]$Bytes)

    if ($Bytes -ge 1GB) {
        return ("{0:N2} GB" -f ($Bytes / 1GB))
    }
    elseif ($Bytes -ge 1MB) {
        return ("{0:N2} MB" -f ($Bytes / 1MB))
    }
    elseif ($Bytes -ge 1KB) {
        return ("{0:N2} KB" -f ($Bytes / 1KB))
    }
    else {
        return ($Bytes.ToString() + " bytes")
    }
}

function Get-FolderStats {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return [PSCustomObject]@{
            Exists = $false
            FileCount = 0
            FolderCount = 0
            TotalBytes = 0
            TotalSizeReadable = "0 bytes"
        }
    }

    $Files = @(Get-ChildItem -LiteralPath $Path -Recurse -Force -File -ErrorAction SilentlyContinue)
    $Folders = @(Get-ChildItem -LiteralPath $Path -Recurse -Force -Directory -ErrorAction SilentlyContinue)

    $MeasuredBytes = ($Files | Measure-Object -Property Length -Sum).Sum
    if ($null -eq $MeasuredBytes) {
        $TotalBytes = [Int64]0
    }
    else {
        $TotalBytes = [Int64]$MeasuredBytes
    }

    return [PSCustomObject]@{
        Exists = $true
        FileCount = $Files.Count
        FolderCount = $Folders.Count
        TotalBytes = $TotalBytes
        TotalSizeReadable = Format-Bytes $TotalBytes
    }
}

function Get-RelativeRepoPath {
    param([string]$FullPath)

    try {
        $FullResolved = [System.IO.Path]::GetFullPath($FullPath)
        $RootResolved = [System.IO.Path]::GetFullPath($RepoRoot)

        if ($FullResolved.StartsWith($RootResolved, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $FullResolved.Substring($RootResolved.Length).TrimStart("\")
        }
    }
    catch {
        return $FullPath
    }

    return $FullPath
}

function Resolve-LocalReference {
    param(
        [string]$BaseFile,
        [string]$Reference
    )

    $RefNoQuery = ($Reference -split "[?#]")[0]

    try {
        $DecodedRef = [System.Uri]::UnescapeDataString($RefNoQuery)
    }
    catch {
        $DecodedRef = $RefNoQuery
    }

    if ([string]::IsNullOrWhiteSpace($DecodedRef)) {
        return ""
    }

    $BaseDir = Split-Path -Parent $BaseFile
    $Candidate = Join-Path $BaseDir $DecodedRef

    try {
        return [System.IO.Path]::GetFullPath($Candidate)
    }
    catch {
        return $Candidate
    }
}

function Is-ExternalOrSkipReference {
    param([string]$Reference)

    if ([string]::IsNullOrWhiteSpace($Reference)) {
        return $true
    }

    if ($Reference -match '^(?i)https?:|mailto:|tel:|javascript:|data:|#') {
        return $true
    }

    return $false
}

function Add-ProtectedPath {
    param(
        [hashtable]$ProtectedMap,
        [string]$FullPath,
        [string]$Reason,
        [string]$OriginalReference
    )

    if ([string]::IsNullOrWhiteSpace($FullPath)) {
        return
    }

    try {
        $Resolved = [System.IO.Path]::GetFullPath($FullPath)
    }
    catch {
        $Resolved = $FullPath
    }

    $Key = $Resolved.ToLowerInvariant()

    if (-not $ProtectedMap.ContainsKey($Key)) {
        $ProtectedMap[$Key] = [PSCustomObject]@{
            FullPath = $Resolved
            RelativePath = Get-RelativeRepoPath $Resolved
            Reason = $Reason
            OriginalReference = $OriginalReference
            Exists = (Test-Path -LiteralPath $Resolved)
            PathType = if (Test-Path -LiteralPath $Resolved -PathType Leaf) { "File" } elseif (Test-Path -LiteralPath $Resolved -PathType Container) { "Folder" } else { "Missing" }
        }
    }
}

function Test-IsUnderPath {
    param(
        [string]$Path,
        [string]$PossibleParent
    )

    try {
        $Resolved = [System.IO.Path]::GetFullPath($Path)
        $ParentResolved = [System.IO.Path]::GetFullPath($PossibleParent)
    }
    catch {
        return $false
    }

    if ($Resolved.Equals($ParentResolved, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $true
    }

    if ($Resolved.StartsWith(($ParentResolved.TrimEnd("\") + "\"), [System.StringComparison]::OrdinalIgnoreCase)) {
        return $true
    }

    return $false
}

function Scan-ProtectedPathsFromBridge {
    $ProtectedMap = @{}

    Add-ProtectedPath -ProtectedMap $ProtectedMap -FullPath $SketchesIndex -Reason "Main bridge page" -OriginalReference "Sketches\index.html"
    Add-ProtectedPath -ProtectedMap $ProtectedMap -FullPath (Join-Path $RepoRoot "Sketches") -Reason "Container folder for bridge page" -OriginalReference "Sketches"
    Add-ProtectedPath -ProtectedMap $ProtectedMap -FullPath (Join-Path $RepoRoot ".nojekyll") -Reason "GitHub Pages support file if present" -OriginalReference ".nojekyll"
    Add-ProtectedPath -ProtectedMap $ProtectedMap -FullPath (Join-Path $RepoRoot "README.md") -Reason "Repository documentation if present" -OriginalReference "README.md"

    $Content = Get-Content -LiteralPath $SketchesIndex -Raw

    $AttrRegex = [regex]'(?is)\b(src|href|poster)\s*=\s*(["''])([^"'']+)\2'
    foreach ($Match in $AttrRegex.Matches($Content)) {
        $Attr = $Match.Groups[1].Value
        $Ref = $Match.Groups[3].Value

        if (Is-ExternalOrSkipReference $Ref) {
            continue
        }

        $Resolved = Resolve-LocalReference -BaseFile $SketchesIndex -Reference $Ref
        if ($Resolved) {
            Add-ProtectedPath -ProtectedMap $ProtectedMap -FullPath $Resolved -Reason ("Local " + $Attr + " reference from bridge page") -OriginalReference $Ref
        }
    }

    $CssUrlRegex = [regex]'(?is)url\(\s*(["'']?)([^"'')]+)\1\s*\)'
    foreach ($Match in $CssUrlRegex.Matches($Content)) {
        $Ref = $Match.Groups[2].Value.Trim()

        if (Is-ExternalOrSkipReference $Ref) {
            continue
        }

        $Resolved = Resolve-LocalReference -BaseFile $SketchesIndex -Reference $Ref
        if ($Resolved) {
            Add-ProtectedPath -ProtectedMap $ProtectedMap -FullPath $Resolved -Reason "Local CSS url(...) reference from bridge page" -OriginalReference $Ref
        }
    }

    return @($ProtectedMap.Values)
}

function Backup-IndexFile {
    $BackupIndexPath = Join-Path $BackupFolder "Sketches\index.html"
    Ensure-Folder (Split-Path -Parent $BackupIndexPath)

    Copy-Item -LiteralPath $SketchesIndex -Destination $BackupIndexPath -Force
    Write-Log ("Backed up Sketches index to: " + $BackupIndexPath)
}

function Remove-WordsAndPhrasesCard {
    $Original = Get-Content -LiteralPath $SketchesIndex -Raw
    $Updated = $Original
    $Rows = @()

    $BeforeLength = $Updated.Length

    # Pattern 1: remove an article/card block containing words-and-phrases or Words & Phrases.
    $Patterns = @(
        @{
            Name = "article containing words-and-phrases"
            Regex = [regex]'(?is)\s*<article\b[^>]*>(?:(?!</article>).)*(?:words-and-phrases|Words\s*(?:&amp;|&|\+|and)\s*Phrases)(?:(?!</article>).)*</article>\s*'
        },
        @{
            Name = "li containing words-and-phrases"
            Regex = [regex]'(?is)\s*<li\b[^>]*>(?:(?!</li>).)*(?:words-and-phrases|Words\s*(?:&amp;|&|\+|and)\s*Phrases)(?:(?!</li>).)*</li>\s*'
        },
        @{
            Name = "anchor containing words-and-phrases"
            Regex = [regex]'(?is)\s*<a\b[^>]*\bhref\s*=\s*["''][^"'']*words-and-phrases[^"'']*["''][^>]*>.*?</a>\s*'
        },
        @{
            Name = "anchor text Words and Phrases"
            Regex = [regex]'(?is)\s*<a\b[^>]*>.*?Words\s*(?:&amp;|&|\+|and)\s*Phrases.*?</a>\s*'
        }
    )

    foreach ($Pattern in $Patterns) {
        $Matches = @($Pattern.Regex.Matches($Updated))
        if ($Matches.Count -gt 0) {
            $Updated = $Pattern.Regex.Replace($Updated, "")
            $Rows += [PSCustomObject]@{
                Pattern = $Pattern.Name
                MatchesRemoved = $Matches.Count
            }
            Write-Log ("Removed Words & Phrases using pattern: " + $Pattern.Name + " / matches: " + $Matches.Count)
        }
    }

    # Pattern 2 fallback: remove individual lines containing words-and-phrases if anything remains.
    if ($Updated -match '(?is)words-and-phrases|Words\s*(?:&amp;|&|\+|and)\s*Phrases') {
        $Lines = $Updated -split "`r?`n"
        $NewLines = @()
        $RemovedLines = 0

        foreach ($Line in $Lines) {
            if ($Line -match '(?is)words-and-phrases|Words\s*(?:&amp;|&|\+|and)\s*Phrases') {
                $RemovedLines++
                continue
            }
            $NewLines += $Line
        }

        $Updated = $NewLines -join "`r`n"

        if ($RemovedLines -gt 0) {
            $Rows += [PSCustomObject]@{
                Pattern = "fallback single-line removal"
                MatchesRemoved = $RemovedLines
            }
            Write-Log ("Fallback removed Words & Phrases lines: " + $RemovedLines)
        }
    }

    $AfterLength = $Updated.Length

    if ($Updated -ne $Original) {
        Set-Content -LiteralPath $SketchesIndex -Value $Updated -Encoding UTF8
        Write-Log "Updated Sketches index to remove Words & Phrases."
    }
    else {
        Write-Log "No Words & Phrases removal was made; no matching block was found."
        $Rows += [PSCustomObject]@{
            Pattern = "No matching block found"
            MatchesRemoved = 0
        }
    }

    $Rows | Export-Csv -LiteralPath $WordsPhrasesReportCsvPath -NoTypeInformation -Encoding UTF8

    return [PSCustomObject]@{
        Changed = ($Updated -ne $Original)
        BeforeLength = $BeforeLength
        AfterLength = $AfterLength
        StillContainsWordsPhrases = ($Updated -match '(?is)words-and-phrases|Words\s*(?:&amp;|&|\+|and)\s*Phrases')
        ReportRows = $Rows
    }
}

function Get-UniqueBackupDestination {
    param([string]$DestinationPath)

    if (-not (Test-Path -LiteralPath $DestinationPath)) {
        return $DestinationPath
    }

    $Parent = Split-Path -Parent $DestinationPath
    $Leaf = Split-Path -Leaf $DestinationPath
    $Counter = 2

    do {
        $Candidate = Join-Path $Parent ($Leaf + "-duplicate-" + $Counter)
        $Counter++
    } while (Test-Path -LiteralPath $Candidate)

    return $Candidate
}

function Move-RemovableImageFolders {
    param([array]$ProtectedRows)

    $MovedRows = @()
    $KeptRows = @()

    if (-not (Test-Path -LiteralPath $ImagesSketchesRoot)) {
        Write-Log ("images\Sketches root does not exist, skipping: " + $ImagesSketchesRoot)
        return [PSCustomObject]@{
            MovedRows = $MovedRows
            KeptRows = $KeptRows
        }
    }

    $BackupImagesRoot = Join-Path $BackupFolder "moved-from-working-tree\images\Sketches"
    Ensure-Folder $BackupImagesRoot

    $Folders = @(Get-ChildItem -LiteralPath $ImagesSketchesRoot -Force -Directory | Sort-Object Name)

    foreach ($Folder in $Folders) {
        $Stats = Get-FolderStats $Folder.FullName

        $ProtectedInside = @($ProtectedRows | Where-Object {
            $_.Exists -eq $true -and (Test-IsUnderPath -Path $_.FullPath -PossibleParent $Folder.FullName)
        })

        if ($ProtectedInside.Count -gt 0) {
            $KeptRows += [PSCustomObject]@{
                FolderName = $Folder.Name
                RelativePath = Get-RelativeRepoPath $Folder.FullName
                FullPath = $Folder.FullName
                FileCount = $Stats.FileCount
                FolderCount = $Stats.FolderCount
                SizeBytes = $Stats.TotalBytes
                SizeReadable = $Stats.TotalSizeReadable
                Action = "Kept"
                Reason = "Folder contains one or more files referenced by the bridge page."
                ProtectedReferences = ($ProtectedInside | Select-Object -ExpandProperty RelativePath -Unique) -join " | "
                BackupDestination = ""
            }

            Write-Log ("Kept protected image folder: " + $Folder.Name)
            continue
        }

        $Target = Join-Path $BackupImagesRoot $Folder.Name
        $Target = Get-UniqueBackupDestination -DestinationPath $Target

        Move-Item -LiteralPath $Folder.FullName -Destination $Target

        $MovedRows += [PSCustomObject]@{
            FolderName = $Folder.Name
            RelativePath = Get-RelativeRepoPath $Folder.FullName
            OriginalFullPath = $Folder.FullName
            FileCount = $Stats.FileCount
            FolderCount = $Stats.FolderCount
            SizeBytes = $Stats.TotalBytes
            SizeReadable = $Stats.TotalSizeReadable
            Action = "Moved to backup"
            Reason = "Immediate images\Sketches subfolder not referenced by bridge page; content now served by split repos."
            BackupDestination = $Target
        }

        Write-Log ("Moved old image folder to backup: " + $Folder.Name + " -> " + $Target)
    }

    $MovedRows | Export-Csv -LiteralPath $MovedFoldersCsvPath -NoTypeInformation -Encoding UTF8
    $KeptRows | Export-Csv -LiteralPath $KeptFoldersCsvPath -NoTypeInformation -Encoding UTF8

    return [PSCustomObject]@{
        MovedRows = $MovedRows
        KeptRows = $KeptRows
    }
}

function Test-MissingBridgeReferences {
    $Rows = @()
    $Content = Get-Content -LiteralPath $SketchesIndex -Raw

    $Refs = @()

    $AttrRegex = [regex]'(?is)\b(src|href|poster)\s*=\s*(["''])([^"'']+)\2'
    foreach ($Match in $AttrRegex.Matches($Content)) {
        $Refs += [PSCustomObject]@{
            Type = "attribute:" + $Match.Groups[1].Value
            Reference = $Match.Groups[3].Value
        }
    }

    $CssUrlRegex = [regex]'(?is)url\(\s*(["'']?)([^"'')]+)\1\s*\)'
    foreach ($Match in $CssUrlRegex.Matches($Content)) {
        $Refs += [PSCustomObject]@{
            Type = "css:url"
            Reference = $Match.Groups[2].Value.Trim()
        }
    }

    foreach ($RefRow in $Refs) {
        $Ref = $RefRow.Reference

        if (Is-ExternalOrSkipReference $Ref) {
            continue
        }

        $Resolved = Resolve-LocalReference -BaseFile $SketchesIndex -Reference $Ref

        if (-not $Resolved) {
            continue
        }

        if (-not (Test-Path -LiteralPath $Resolved)) {
            $Rows += [PSCustomObject]@{
                ReferenceType = $RefRow.Type
                OriginalReference = $Ref
                ExpectedRelativePath = Get-RelativeRepoPath $Resolved
                ExpectedFullPath = $Resolved
                Status = "Missing after cleanup"
            }
        }
    }

    $Rows | Export-Csv -LiteralPath $MissingBridgeRefsCsvPath -NoTypeInformation -Encoding UTF8

    return $Rows
}

# Main run

Ensure-Folder $AuditFolder
Ensure-Folder $BackupFolder

Write-Log "Starting Phase 1 old sketches cleanup."
Write-Log ("Repo root: " + $RepoRoot)
Write-Log ("Sketches index: " + $SketchesIndex)
Write-Log ("Images Sketches root: " + $ImagesSketchesRoot)
Write-Log ("Backup folder: " + $BackupFolder)

if (-not (Test-Path -LiteralPath $RepoRoot)) {
    throw ("Repo root does not exist: " + $RepoRoot)
}

if (-not (Test-Path -LiteralPath $SketchesIndex)) {
    throw ("Sketches index does not exist: " + $SketchesIndex)
}

Backup-IndexFile

$WordsResult = Remove-WordsAndPhrasesCard

# Re-scan after modifying the bridge page so protected paths match the final version.
$ProtectedRows = @(Scan-ProtectedPathsFromBridge)
$ProtectedRows | Sort-Object RelativePath | Export-Csv -LiteralPath $ProtectedPathsCsvPath -NoTypeInformation -Encoding UTF8

$MoveResult = Move-RemovableImageFolders -ProtectedRows $ProtectedRows
$MovedRows = @($MoveResult.MovedRows)
$KeptRows = @($MoveResult.KeptRows)

$MissingRows = @(Test-MissingBridgeReferences)

$MovedBytes = [Int64](($MovedRows | Measure-Object -Property SizeBytes -Sum).Sum)
if ($null -eq $MovedBytes) {
    $MovedBytes = 0
}

$SummaryLines = @()
$SummaryLines += "Phase 1 old sketches cleanup summary"
$SummaryLines += ("Generated: " + (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$SummaryLines += ""
$SummaryLines += "Repo cleaned:"
$SummaryLines += $RepoRoot
$SummaryLines += ""
$SummaryLines += "Backup folder:"
$SummaryLines += $BackupFolder
$SummaryLines += ""
$SummaryLines += "Actions performed:"
$SummaryLines += "- Backed up Sketches\index.html."
$SummaryLines += "- Removed Words & Phrases card/link if a matching block was found."
$SummaryLines += "- Moved unprotected immediate subfolders under images\Sketches to backup."
$SummaryLines += "- Did not remove old Sketches category page folders."
$SummaryLines += "- Did not edit any split repositories."
$SummaryLines += ""
$SummaryLines += "Words & Phrases:"
$SummaryLines += ("- Index changed: " + $WordsResult.Changed)
$SummaryLines += ("- Still contains Words & Phrases text/link: " + $WordsResult.StillContainsWordsPhrases)
$SummaryLines += ""
$SummaryLines += "Image folder cleanup:"
$SummaryLines += ("- Image folders moved to backup: " + $MovedRows.Count)
$SummaryLines += ("- Image folders kept because protected/referenced: " + $KeptRows.Count)
$SummaryLines += ("- Approximate working-tree bytes moved: " + (Format-Bytes $MovedBytes))
$SummaryLines += ""
$SummaryLines += "Bridge reference validation:"
$SummaryLines += ("- Missing local bridge references after cleanup: " + $MissingRows.Count)
$SummaryLines += ""
$SummaryLines += "Reports:"
$SummaryLines += ("- Moved folders CSV: " + $MovedFoldersCsvPath)
$SummaryLines += ("- Kept folders CSV: " + $KeptFoldersCsvPath)
$SummaryLines += ("- Protected paths CSV: " + $ProtectedPathsCsvPath)
$SummaryLines += ("- Missing bridge references CSV: " + $MissingBridgeRefsCsvPath)
$SummaryLines += ("- Words & Phrases removal report: " + $WordsPhrasesReportCsvPath)
$SummaryLines += ""
$SummaryLines += "Important:"
$SummaryLines += "- This reduces the old repo working tree, but it does not remove files from Git history."
$SummaryLines += "- Test Sketches\index.html locally before committing/pushing."
$SummaryLines += "- If something is wrong, the moved folders are in the backup folder above."

Set-Content -LiteralPath $SummaryPath -Value $SummaryLines -Encoding UTF8

Write-Log ("Moved image folders: " + $MovedRows.Count)
Write-Log ("Kept image folders: " + $KeptRows.Count)
Write-Log ("Approximate working-tree bytes moved: " + (Format-Bytes $MovedBytes))
Write-Log ("Missing bridge refs after cleanup: " + $MissingRows.Count)
Write-Log "Done."

Write-Host ""
Write-Host "DONE. Phase 1 cleanup finished."
Write-Host ""
Write-Host "Moved image folders:"
Write-Host $MovedRows.Count
Write-Host ""
Write-Host "Approximate working-tree size moved:"
Write-Host (Format-Bytes $MovedBytes)
Write-Host ""
Write-Host "Missing bridge references after cleanup:"
Write-Host $MissingRows.Count
Write-Host ""
Write-Host "Backup folder:"
Write-Host $BackupFolder
Write-Host ""
Write-Host "Now test this local file:"
Write-Host "D:\github\ron-english-sketches-and-drawings\Sketches\index.html"
Write-Host ""
Write-Host "If it looks good, commit and push the old ron-english-sketches-and-drawings repo."
Write-Host "If missing bridge references is not 0, upload this CSV:"
Write-Host $MissingBridgeRefsCsvPath
