# audit-old-sketches-repo-cleanup.ps1
# Read-only cleanup audit for the old Ron English sketches-and-drawings repo.
#
# Purpose:
# Identify what can probably be removed from the OLD working tree while preserving the public bridge page:
#   D:\github\ron-english-sketches-and-drawings\Sketches\index.html
#
# IMPORTANT:
# - This script is READ-ONLY.
# - It does NOT delete, move, rename, or edit anything.
# - It only writes audit CSV/TXT files into:
#   D:\github\ron-english-sketches-and-drawings\_cleanup-audit
#
# The old public flow is:
#   catalogue raisonne home
#   -> ron-english-sketches-and-drawings/Sketches/
#   -> split-repo category links
#
# This audit looks for:
# - files directly needed by Sketches\index.html
# - local links still used by Sketches\index.html
# - large folders likely safe to remove later from the old working tree
# - old Sketches category folders now replaced by split repos
# - old images\Sketches folders now replaced by split repos
#
# Note:
# Removing files from the working tree reduces what is currently published,
# but it does NOT remove those files from Git history. A history cleanup is a separate, more advanced phase.

$ErrorActionPreference = "Continue"

$RepoRoot = "D:\github\ron-english-sketches-and-drawings"
$BridgeIndex = Join-Path $RepoRoot "Sketches\index.html"

$ScriptName = "audit-old-sketches-repo-cleanup"
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

$AuditRoot = Join-Path $RepoRoot "_cleanup-audit"
$AuditFolder = Join-Path $AuditRoot ($ScriptName + "-" + $Timestamp)

$LogPath = Join-Path $AuditFolder "00_cleanup-audit-log.txt"
$SummaryPath = Join-Path $AuditFolder "00_cleanup-audit-summary.txt"

$RequiredFilesCsv = Join-Path $AuditFolder "01_required_files_for_bridge.csv"
$RequiredFoldersCsv = Join-Path $AuditFolder "02_required_folders_for_bridge.csv"
$BridgeLinksCsv = Join-Path $AuditFolder "03_bridge_index_links_and_assets.csv"
$RemainingLocalLinksCsv = Join-Path $AuditFolder "04_remaining_local_links_in_bridge_index.csv"
$TopLevelCandidatesCsv = Join-Path $AuditFolder "05_candidate_removal_top_level_items.csv"
$SketchesCandidatesCsv = Join-Path $AuditFolder "06_candidate_removal_Sketches_subfolders.csv"
$ImagesSketchesCandidatesCsv = Join-Path $AuditFolder "07_candidate_removal_images-Sketches_subfolders.csv"
$LargeFilesCsv = Join-Path $AuditFolder "08_large_files_candidate_review.csv"
$AllProtectedPathsCsv = Join-Path $AuditFolder "09_all_protected_paths.csv"

New-Item -ItemType Directory -Force -Path $AuditFolder | Out-Null

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
            Path = $Path
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
        Path = $Path
        Exists = $true
        FileCount = $Files.Count
        FolderCount = $Folders.Count
        TotalBytes = $TotalBytes
        TotalSizeReadable = Format-Bytes $TotalBytes
    }
}

function Get-FileStats {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return [PSCustomObject]@{
            Path = $Path
            Exists = $false
            SizeBytes = 0
            SizeReadable = "0 bytes"
            LastWriteTime = ""
        }
    }

    $Item = Get-Item -LiteralPath $Path -Force

    return [PSCustomObject]@{
        Path = $Path
        Exists = $true
        SizeBytes = [Int64]$Item.Length
        SizeReadable = Format-Bytes ([Int64]$Item.Length)
        LastWriteTime = $Item.LastWriteTime
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
        [string]$FoundIn,
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
            FoundIn = $FoundIn
            OriginalReference = $OriginalReference
            Exists = (Test-Path -LiteralPath $Resolved)
            PathType = if (Test-Path -LiteralPath $Resolved -PathType Leaf) { "File" } elseif (Test-Path -LiteralPath $Resolved -PathType Container) { "Folder" } else { "Missing" }
        }
    }
}

function Test-IsUnderProtectedPath {
    param(
        [string]$Path,
        [array]$ProtectedRows
    )

    try {
        $Resolved = [System.IO.Path]::GetFullPath($Path)
    }
    catch {
        $Resolved = $Path
    }

    foreach ($Protected in $ProtectedRows) {
        if (-not $Protected.Exists) {
            continue
        }

        try {
            $ProtectedResolved = [System.IO.Path]::GetFullPath($Protected.FullPath)
        }
        catch {
            $ProtectedResolved = $Protected.FullPath
        }

        if ($Resolved.Equals($ProtectedResolved, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }

        if ($Resolved.StartsWith(($ProtectedResolved.TrimEnd("\") + "\"), [System.StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
    }

    return $false
}

function Scan-BridgeIndexReferences {
    $Rows = @()
    $ProtectedMap = @{}

    Add-ProtectedPath -ProtectedMap $ProtectedMap -FullPath $BridgeIndex -Reason "Main public bridge page" -FoundIn "Script baseline" -OriginalReference "Sketches\index.html"

    # Keep these if they exist; they are common GitHub Pages support files.
    Add-ProtectedPath -ProtectedMap $ProtectedMap -FullPath (Join-Path $RepoRoot ".nojekyll") -Reason "GitHub Pages support file if present" -FoundIn "Script baseline" -OriginalReference ".nojekyll"
    Add-ProtectedPath -ProtectedMap $ProtectedMap -FullPath (Join-Path $RepoRoot "README.md") -Reason "Repository documentation if present" -FoundIn "Script baseline" -OriginalReference "README.md"

    # Also protect the Sketches folder itself because it contains the bridge page.
    Add-ProtectedPath -ProtectedMap $ProtectedMap -FullPath (Join-Path $RepoRoot "Sketches") -Reason "Container folder for bridge page" -FoundIn "Script baseline" -OriginalReference "Sketches"

    $Content = Get-Content -LiteralPath $BridgeIndex -Raw

    # HTML attributes that may point to local files.
    $AttrRegex = [regex]'(?is)\b(src|href|poster)\s*=\s*(["''])([^"'']+)\2'

    foreach ($Match in $AttrRegex.Matches($Content)) {
        $AttrName = $Match.Groups[1].Value
        $Ref = $Match.Groups[3].Value

        $IsExternal = Is-ExternalOrSkipReference $Ref
        $Resolved = ""
        $Exists = ""
        $PathType = ""

        if (-not $IsExternal) {
            $Resolved = Resolve-LocalReference -BaseFile $BridgeIndex -Reference $Ref

            if ($Resolved) {
                $Exists = Test-Path -LiteralPath $Resolved
                $PathType = if (Test-Path -LiteralPath $Resolved -PathType Leaf) { "File" } elseif (Test-Path -LiteralPath $Resolved -PathType Container) { "Folder" } else { "Missing" }

                Add-ProtectedPath -ProtectedMap $ProtectedMap -FullPath $Resolved -Reason ("Local " + $AttrName + " reference from bridge page") -FoundIn "Sketches\index.html" -OriginalReference $Ref
            }
        }

        $Rows += [PSCustomObject]@{
            ReferenceType = "attribute:" + $AttrName
            OriginalReference = $Ref
            IsExternalOrSkipped = $IsExternal
            ResolvedFullPath = $Resolved
            ResolvedRelativePath = if ($Resolved) { Get-RelativeRepoPath $Resolved } else { "" }
            Exists = $Exists
            PathType = $PathType
        }
    }

    # CSS url(...) references inside the page.
    $CssUrlRegex = [regex]'(?is)url\(\s*(["'']?)([^"'')]+)\1\s*\)'

    foreach ($Match in $CssUrlRegex.Matches($Content)) {
        $Ref = $Match.Groups[2].Value.Trim()

        $IsExternal = Is-ExternalOrSkipReference $Ref
        $Resolved = ""
        $Exists = ""
        $PathType = ""

        if (-not $IsExternal) {
            $Resolved = Resolve-LocalReference -BaseFile $BridgeIndex -Reference $Ref

            if ($Resolved) {
                $Exists = Test-Path -LiteralPath $Resolved
                $PathType = if (Test-Path -LiteralPath $Resolved -PathType Leaf) { "File" } elseif (Test-Path -LiteralPath $Resolved -PathType Container) { "Folder" } else { "Missing" }

                Add-ProtectedPath -ProtectedMap $ProtectedMap -FullPath $Resolved -Reason "Local CSS url(...) reference from bridge page" -FoundIn "Sketches\index.html" -OriginalReference $Ref
            }
        }

        $Rows += [PSCustomObject]@{
            ReferenceType = "css:url"
            OriginalReference = $Ref
            IsExternalOrSkipped = $IsExternal
            ResolvedFullPath = $Resolved
            ResolvedRelativePath = if ($Resolved) { Get-RelativeRepoPath $Resolved } else { "" }
            Exists = $Exists
            PathType = $PathType
        }
    }

    return [PSCustomObject]@{
        LinkRows = $Rows
        ProtectedRows = @($ProtectedMap.Values)
    }
}

function Find-RemainingLocalLinks {
    $Rows = @()
    $Content = Get-Content -LiteralPath $BridgeIndex -Raw

    $AnchorRegex = [regex]'(?is)<a\b[^>]*\bhref\s*=\s*(["''])([^"'']+)\1[^>]*>.*?</a>'

    foreach ($Match in $AnchorRegex.Matches($Content)) {
        $Href = $Match.Groups[2].Value
        $AnchorHtml = $Match.Value
        $PlainText = ([regex]::Replace($AnchorHtml, "<[^>]+>", "")).Trim()
        $PlainText = [System.Net.WebUtility]::HtmlDecode($PlainText)

        if (Is-ExternalOrSkipReference $Href) {
            continue
        }

        $Resolved = Resolve-LocalReference -BaseFile $BridgeIndex -Reference $Href

        $Rows += [PSCustomObject]@{
            AnchorText = $PlainText
            Href = $Href
            ResolvedRelativePath = if ($Resolved) { Get-RelativeRepoPath $Resolved } else { "" }
            Exists = if ($Resolved) { Test-Path -LiteralPath $Resolved } else { "" }
            Note = "Local href remains in bridge page. Review before cleanup."
        }
    }

    return $Rows
}

function Build-TopLevelCandidateRows {
    param([array]$ProtectedRows)

    $Rows = @()
    $TopItems = @(Get-ChildItem -LiteralPath $RepoRoot -Force | Where-Object { $_.Name -ne ".git" } | Sort-Object Name)

    foreach ($Item in $TopItems) {
        $IsProtected = Test-IsUnderProtectedPath -Path $Item.FullName -ProtectedRows $ProtectedRows
        $Stats = if ($Item.PSIsContainer) { Get-FolderStats $Item.FullName } else { Get-FileStats $Item.FullName }

        $Recommendation = ""
        $Reason = ""

        if ($IsProtected) {
            $Recommendation = "KEEP for bridge or repository support"
            $Reason = "This item is the bridge page, contains the bridge page, or is directly referenced by it."
        }
        elseif ($Item.Name -eq "images") {
            $Recommendation = "REVIEW carefully"
            $Reason = "May contain assets used by bridge page. See required files report before removing subfolders."
        }
        elseif ($Item.Name -eq "_cleanup-audit" -or $Item.Name -eq "_split-bridge-audit" -or $Item.Name -eq "_repo-split-audit") {
            $Recommendation = "Optional remove later"
            $Reason = "Audit/report folder; not needed for public site unless you want the records online."
        }
        elseif ($Item.Extension -ieq ".ps1") {
            $Recommendation = "Optional remove later"
            $Reason = "Script file; not needed for public site once you have saved backups."
        }
        else {
            $Recommendation = "Candidate for removal later"
            $Reason = "Not detected as required by the bridge page."
        }

        $Rows += [PSCustomObject]@{
            Name = $Item.Name
            Type = if ($Item.PSIsContainer) { "Folder" } else { "File" }
            RelativePath = Get-RelativeRepoPath $Item.FullName
            FullPath = $Item.FullName
            IsProtectedByBridgeAudit = $IsProtected
            FileCount = if ($Item.PSIsContainer) { $Stats.FileCount } else { "" }
            FolderCount = if ($Item.PSIsContainer) { $Stats.FolderCount } else { "" }
            SizeBytes = if ($Item.PSIsContainer) { $Stats.TotalBytes } else { $Stats.SizeBytes }
            SizeReadable = if ($Item.PSIsContainer) { $Stats.TotalSizeReadable } else { $Stats.SizeReadable }
            Recommendation = $Recommendation
            Reason = $Reason
        }
    }

    return $Rows | Sort-Object SizeBytes -Descending
}

function Build-SketchesSubfolderCandidateRows {
    param([array]$ProtectedRows)

    $Rows = @()
    $SketchesRoot = Join-Path $RepoRoot "Sketches"

    if (-not (Test-Path -LiteralPath $SketchesRoot)) {
        return $Rows
    }

    $Items = @(Get-ChildItem -LiteralPath $SketchesRoot -Force | Sort-Object Name)

    foreach ($Item in $Items) {
        $IsBridge = $Item.FullName.Equals($BridgeIndex, [System.StringComparison]::OrdinalIgnoreCase)
        $IsProtected = Test-IsUnderProtectedPath -Path $Item.FullName -ProtectedRows $ProtectedRows
        $Stats = if ($Item.PSIsContainer) { Get-FolderStats $Item.FullName } else { Get-FileStats $Item.FullName }

        $Recommendation = ""
        $Reason = ""

        if ($IsBridge) {
            $Recommendation = "KEEP"
            $Reason = "This is the public bridge page."
        }
        elseif ($IsProtected) {
            $Recommendation = "KEEP / REVIEW"
            $Reason = "This item is referenced by the bridge page or is in a protected path."
        }
        elseif ($Item.PSIsContainer) {
            $Recommendation = "Strong candidate for removal later"
            $Reason = "This old category folder should now be served from a split repo."
        }
        else {
            $Recommendation = "Review"
            $Reason = "File in Sketches root not identified as bridge page."
        }

        $Rows += [PSCustomObject]@{
            Name = $Item.Name
            Type = if ($Item.PSIsContainer) { "Folder" } else { "File" }
            RelativePath = Get-RelativeRepoPath $Item.FullName
            FullPath = $Item.FullName
            IsProtectedByBridgeAudit = $IsProtected
            FileCount = if ($Item.PSIsContainer) { $Stats.FileCount } else { "" }
            FolderCount = if ($Item.PSIsContainer) { $Stats.FolderCount } else { "" }
            SizeBytes = if ($Item.PSIsContainer) { $Stats.TotalBytes } else { $Stats.SizeBytes }
            SizeReadable = if ($Item.PSIsContainer) { $Stats.TotalSizeReadable } else { $Stats.SizeReadable }
            Recommendation = $Recommendation
            Reason = $Reason
        }
    }

    return $Rows | Sort-Object SizeBytes -Descending
}

function Build-ImagesSketchesCandidateRows {
    param([array]$ProtectedRows)

    $Rows = @()
    $ImagesSketchesRoot = Join-Path $RepoRoot "images\Sketches"

    if (-not (Test-Path -LiteralPath $ImagesSketchesRoot)) {
        return $Rows
    }

    $Items = @(Get-ChildItem -LiteralPath $ImagesSketchesRoot -Force | Sort-Object Name)

    foreach ($Item in $Items) {
        $IsProtected = Test-IsUnderProtectedPath -Path $Item.FullName -ProtectedRows $ProtectedRows
        $Stats = if ($Item.PSIsContainer) { Get-FolderStats $Item.FullName } else { Get-FileStats $Item.FullName }

        $Recommendation = ""
        $Reason = ""

        if ($IsProtected) {
            $Recommendation = "KEEP / REVIEW"
            $Reason = "This item is referenced by the bridge page or is in a protected path."
        }
        elseif ($Item.PSIsContainer) {
            $Recommendation = "Strong candidate for removal later"
            $Reason = "This old image folder should now be served from a split repo."
        }
        else {
            $Recommendation = "Review"
            $Reason = "Root-level image file under images\Sketches. It may be a bridge thumbnail or an old hero file."
        }

        $Rows += [PSCustomObject]@{
            Name = $Item.Name
            Type = if ($Item.PSIsContainer) { "Folder" } else { "File" }
            RelativePath = Get-RelativeRepoPath $Item.FullName
            FullPath = $Item.FullName
            IsProtectedByBridgeAudit = $IsProtected
            FileCount = if ($Item.PSIsContainer) { $Stats.FileCount } else { "" }
            FolderCount = if ($Item.PSIsContainer) { $Stats.FolderCount } else { "" }
            SizeBytes = if ($Item.PSIsContainer) { $Stats.TotalBytes } else { $Stats.SizeBytes }
            SizeReadable = if ($Item.PSIsContainer) { $Stats.TotalSizeReadable } else { $Stats.SizeReadable }
            Recommendation = $Recommendation
            Reason = $Reason
        }
    }

    return $Rows | Sort-Object SizeBytes -Descending
}

function Build-LargeFilesRows {
    param([array]$ProtectedRows)

    $Rows = @()
    $Files = @(Get-ChildItem -LiteralPath $RepoRoot -Recurse -Force -File -ErrorAction SilentlyContinue | Where-Object {
        $_.FullName -notmatch "\\.git\\"
    })

    foreach ($File in ($Files | Sort-Object Length -Descending | Select-Object -First 300)) {
        $IsProtected = Test-IsUnderProtectedPath -Path $File.FullName -ProtectedRows $ProtectedRows

        $Recommendation = if ($IsProtected) { "KEEP / REVIEW" } else { "Candidate for removal later if not needed by bridge" }

        $Rows += [PSCustomObject]@{
            Name = $File.Name
            Extension = $File.Extension
            RelativePath = Get-RelativeRepoPath $File.FullName
            FullPath = $File.FullName
            IsProtectedByBridgeAudit = $IsProtected
            SizeBytes = [Int64]$File.Length
            SizeReadable = Format-Bytes ([Int64]$File.Length)
            LastWriteTime = $File.LastWriteTime
            Recommendation = $Recommendation
        }
    }

    return $Rows
}

# Main run

Write-Log "Starting read-only cleanup audit for old sketches-and-drawings repo."
Write-Log ("Repo root: " + $RepoRoot)
Write-Log ("Bridge index: " + $BridgeIndex)
Write-Log ("Audit folder: " + $AuditFolder)

if (-not (Test-Path -LiteralPath $RepoRoot)) {
    throw ("Repo root does not exist: " + $RepoRoot)
}

if (-not (Test-Path -LiteralPath $BridgeIndex)) {
    throw ("Bridge index does not exist: " + $BridgeIndex)
}

$BridgeScan = Scan-BridgeIndexReferences
$LinkRows = @($BridgeScan.LinkRows)
$ProtectedRows = @($BridgeScan.ProtectedRows)

$RequiredFiles = @()
$RequiredFolders = @()

foreach ($Row in $ProtectedRows) {
    if ($Row.PathType -eq "File") {
        $Stats = Get-FileStats $Row.FullPath
        $RequiredFiles += [PSCustomObject]@{
            RelativePath = $Row.RelativePath
            FullPath = $Row.FullPath
            Exists = $Row.Exists
            SizeBytes = $Stats.SizeBytes
            SizeReadable = $Stats.SizeReadable
            Reason = $Row.Reason
            FoundIn = $Row.FoundIn
            OriginalReference = $Row.OriginalReference
        }
    }
    elseif ($Row.PathType -eq "Folder") {
        $Stats = Get-FolderStats $Row.FullPath
        $RequiredFolders += [PSCustomObject]@{
            RelativePath = $Row.RelativePath
            FullPath = $Row.FullPath
            Exists = $Row.Exists
            FileCount = $Stats.FileCount
            FolderCount = $Stats.FolderCount
            SizeBytes = $Stats.TotalBytes
            SizeReadable = $Stats.TotalSizeReadable
            Reason = $Row.Reason
            FoundIn = $Row.FoundIn
            OriginalReference = $Row.OriginalReference
        }
    }
    else {
        $RequiredFiles += [PSCustomObject]@{
            RelativePath = $Row.RelativePath
            FullPath = $Row.FullPath
            Exists = $Row.Exists
            SizeBytes = ""
            SizeReadable = ""
            Reason = $Row.Reason
            FoundIn = $Row.FoundIn
            OriginalReference = $Row.OriginalReference
        }
    }
}

$RemainingLocalLinks = @(Find-RemainingLocalLinks)
$TopLevelCandidates = @(Build-TopLevelCandidateRows -ProtectedRows $ProtectedRows)
$SketchesCandidates = @(Build-SketchesSubfolderCandidateRows -ProtectedRows $ProtectedRows)
$ImagesSketchesCandidates = @(Build-ImagesSketchesCandidateRows -ProtectedRows $ProtectedRows)
$LargeFilesRows = @(Build-LargeFilesRows -ProtectedRows $ProtectedRows)

$LinkRows | Export-Csv -LiteralPath $BridgeLinksCsv -NoTypeInformation -Encoding UTF8
$RequiredFiles | Sort-Object RelativePath | Export-Csv -LiteralPath $RequiredFilesCsv -NoTypeInformation -Encoding UTF8
$RequiredFolders | Sort-Object RelativePath | Export-Csv -LiteralPath $RequiredFoldersCsv -NoTypeInformation -Encoding UTF8
$RemainingLocalLinks | Export-Csv -LiteralPath $RemainingLocalLinksCsv -NoTypeInformation -Encoding UTF8
$TopLevelCandidates | Export-Csv -LiteralPath $TopLevelCandidatesCsv -NoTypeInformation -Encoding UTF8
$SketchesCandidates | Export-Csv -LiteralPath $SketchesCandidatesCsv -NoTypeInformation -Encoding UTF8
$ImagesSketchesCandidates | Export-Csv -LiteralPath $ImagesSketchesCandidatesCsv -NoTypeInformation -Encoding UTF8
$LargeFilesRows | Export-Csv -LiteralPath $LargeFilesCsv -NoTypeInformation -Encoding UTF8
$ProtectedRows | Sort-Object RelativePath | Export-Csv -LiteralPath $AllProtectedPathsCsv -NoTypeInformation -Encoding UTF8

$RepoStats = Get-FolderStats $RepoRoot
$SketchesStats = Get-FolderStats (Join-Path $RepoRoot "Sketches")
$ImagesSketchesStats = Get-FolderStats (Join-Path $RepoRoot "images\Sketches")

$StrongSketchesRemoval = @($SketchesCandidates | Where-Object { $_.Recommendation -like "Strong candidate*" })
$StrongImagesRemoval = @($ImagesSketchesCandidates | Where-Object { $_.Recommendation -like "Strong candidate*" })

$StrongSketchesBytes = [Int64](($StrongSketchesRemoval | Measure-Object -Property SizeBytes -Sum).Sum)
if ($null -eq $StrongSketchesBytes) { $StrongSketchesBytes = 0 }

$StrongImagesBytes = [Int64](($StrongImagesRemoval | Measure-Object -Property SizeBytes -Sum).Sum)
if ($null -eq $StrongImagesBytes) { $StrongImagesBytes = 0 }

$SummaryLines = @()
$SummaryLines += "Old sketches-and-drawings cleanup audit"
$SummaryLines += ("Generated: " + (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$SummaryLines += ""
$SummaryLines += "Repo root:"
$SummaryLines += $RepoRoot
$SummaryLines += ""
$SummaryLines += "Bridge page to preserve:"
$SummaryLines += $BridgeIndex
$SummaryLines += ""
$SummaryLines += "This was a read-only audit. No files were deleted, moved, renamed, or edited."
$SummaryLines += ""
$SummaryLines += "Current sizes:"
$SummaryLines += ("- Full repo working tree, excluding Git-history meaning: " + $RepoStats.TotalSizeReadable + " / " + $RepoStats.FileCount + " files")
$SummaryLines += ("- Sketches folder: " + $SketchesStats.TotalSizeReadable + " / " + $SketchesStats.FileCount + " files")
$SummaryLines += ("- images\Sketches folder: " + $ImagesSketchesStats.TotalSizeReadable + " / " + $ImagesSketchesStats.FileCount + " files")
$SummaryLines += ""
$SummaryLines += "Bridge requirements detected:"
$SummaryLines += ("- Required/protected files: " + $RequiredFiles.Count)
$SummaryLines += ("- Required/protected folders: " + $RequiredFolders.Count)
$SummaryLines += ("- Remaining local links in bridge page: " + $RemainingLocalLinks.Count)
$SummaryLines += ""
$SummaryLines += "Potential removable working-tree size, pending review:"
$SummaryLines += ("- Strong Sketches subfolder candidates: " + (Format-Bytes $StrongSketchesBytes) + " / " + $StrongSketchesRemoval.Count + " items")
$SummaryLines += ("- Strong images\Sketches subfolder candidates: " + (Format-Bytes $StrongImagesBytes) + " / " + $StrongImagesRemoval.Count + " items")
$SummaryLines += ""
$SummaryLines += "Most important CSVs to upload:"
$SummaryLines += "01_required_files_for_bridge.csv"
$SummaryLines += "02_required_folders_for_bridge.csv"
$SummaryLines += "04_remaining_local_links_in_bridge_index.csv"
$SummaryLines += "05_candidate_removal_top_level_items.csv"
$SummaryLines += "06_candidate_removal_Sketches_subfolders.csv"
$SummaryLines += "07_candidate_removal_images-Sketches_subfolders.csv"
$SummaryLines += "08_large_files_candidate_review.csv"
$SummaryLines += ""
$SummaryLines += "Important caution:"
$SummaryLines += "Removing files from the working tree can make the published repo lighter, but it does not remove those files from Git history. True repository-size reduction needs a separate history-cleanup or fresh-replacement phase."

Set-Content -LiteralPath $SummaryPath -Value $SummaryLines -Encoding UTF8

Write-Log "Audit complete."
Write-Log ("Summary: " + $SummaryPath)

Write-Host ""
Write-Host "DONE. Read-only cleanup audit finished."
Write-Host ""
Write-Host "Audit folder:"
Write-Host $AuditFolder
Write-Host ""
Write-Host "Please upload these files first:"
Write-Host "00_cleanup-audit-summary.txt"
Write-Host "01_required_files_for_bridge.csv"
Write-Host "02_required_folders_for_bridge.csv"
Write-Host "04_remaining_local_links_in_bridge_index.csv"
Write-Host "05_candidate_removal_top_level_items.csv"
Write-Host "06_candidate_removal_Sketches_subfolders.csv"
Write-Host "07_candidate_removal_images-Sketches_subfolders.csv"
Write-Host "08_large_files_candidate_review.csv"
