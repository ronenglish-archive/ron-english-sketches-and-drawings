[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$Delete
)

$ErrorActionPreference = 'Stop'

$RepoRoot = 'D:\github\ron-english-sketches-and-drawings'

if (-not (Test-Path -LiteralPath $RepoRoot)) {
    throw "Repository folder not found: $RepoRoot"
}

Write-Host ""
Write-Host "Ron English sketches cleanup"
Write-Host "Repository: $RepoRoot"
Write-Host ""

# This targets only backup artifacts created during the build/correction process:
# 1. Folders named _backups
# 2. Loose files with .bak in the filename, such as:
#    little-bigfoot.html.bak-centering-20260507-142125
#
# It does NOT target normal .html, .css, .js, .jpg, .png, etc. files unless they contain .bak in the name.

$backupFolders = @(Get-ChildItem -LiteralPath $RepoRoot -Directory -Recurse -Force | Where-Object {
    $_.Name -eq '_backups'
})

$bakFiles = @(Get-ChildItem -LiteralPath $RepoRoot -File -Recurse -Force | Where-Object {
    $_.Name -match '\.bak($|[-_.])' -or $_.Name -match '\.bak-'
})

# Avoid double-counting loose .bak files inside _backups folders, since deleting the folder handles them.
$backupFolderPaths = @($backupFolders | ForEach-Object { $_.FullName.TrimEnd('\') })

$bakFilesOutsideBackupFolders = @($bakFiles | Where-Object {
    $filePath = $_.FullName
    $insideBackupFolder = $false

    foreach ($folderPath in $backupFolderPaths) {
        if ($filePath.StartsWith($folderPath + '\', [System.StringComparison]::OrdinalIgnoreCase)) {
            $insideBackupFolder = $true
            break
        }
    }

    -not $insideBackupFolder
})

Write-Host "Found backup folders: $($backupFolders.Count)"
Write-Host "Found loose .bak files outside _backups folders: $($bakFilesOutsideBackupFolders.Count)"
Write-Host ""

if ($backupFolders.Count -gt 0) {
    Write-Host "Backup folders that will be removed:"
    $backupFolders | Sort-Object FullName | ForEach-Object {
        Write-Host "  $($_.FullName)"
    }
    Write-Host ""
}

if ($bakFilesOutsideBackupFolders.Count -gt 0) {
    Write-Host "Loose .bak files that will be removed:"
    $bakFilesOutsideBackupFolders | Sort-Object FullName | ForEach-Object {
        Write-Host "  $($_.FullName)"
    }
    Write-Host ""
}

if (-not $Delete) {
    Write-Host "PREVIEW ONLY. Nothing was deleted."
    Write-Host ""
    Write-Host "If this list looks right, run:"
    Write-Host "  .\clean-backup-files.ps1 -Delete"
    Write-Host ""
    exit 0
}

$removedFolders = 0
$removedFiles = 0

foreach ($folder in ($backupFolders | Sort-Object FullName -Descending)) {
    if (Test-Path -LiteralPath $folder.FullName) {
        Remove-Item -LiteralPath $folder.FullName -Recurse -Force
        $removedFolders++
    }
}

foreach ($file in $bakFilesOutsideBackupFolders) {
    if (Test-Path -LiteralPath $file.FullName) {
        Remove-Item -LiteralPath $file.FullName -Force
        $removedFiles++
    }
}

Write-Host ""
Write-Host "Cleanup complete."
Write-Host "Removed backup folders: $removedFolders"
Write-Host "Removed loose .bak files: $removedFiles"
Write-Host ""
Write-Host "Now refresh File Explorer or reopen the folder to confirm the backup files are gone."
