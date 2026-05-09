[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$RepoRoot = 'D:\github\ron-english-sketches-and-drawings'
$ScriptPath = Join-Path $RepoRoot 'build-canines-and-felines-category.ps1'

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
        $backupPath = Join-Path $backupDir "$name-before-where-object-fix-$timestamp$ext"

        Copy-Item -LiteralPath $Path -Destination $backupPath -Force
        Write-Host "Backup created: $backupPath"
    }
}

if (-not (Test-Path -LiteralPath $ScriptPath)) {
    throw "Could not find the builder script: $ScriptPath"
}

Backup-FileIfExists -Path $ScriptPath

$text = [System.IO.File]::ReadAllText($ScriptPath)
$original = $text

# Fix PowerShell parsing issue:
#   Get-ImageKind $_.Name -eq 'Original'
# must be:
#   (Get-ImageKind -FileName $_.Name) -eq 'Original'
# Without parentheses, PowerShell thinks -eq is a parameter name for Get-ImageKind.

$text = $text.Replace("Where-Object { Get-ImageKind `$_.Name -eq 'Original' }", "Where-Object { (Get-ImageKind -FileName `$_.Name) -eq 'Original' }")
$text = $text.Replace("Where-Object { Get-ImageKind `$_.Name -eq 'Digitized' }", "Where-Object { (Get-ImageKind -FileName `$_.Name) -eq 'Digitized' }")
$text = $text.Replace("Where-Object { Get-ImageKind `$_.Name -eq 'Card' }", "Where-Object { (Get-ImageKind -FileName `$_.Name) -eq 'Card' }")

# Also catch the same issue if spacing changed slightly.
$text = [regex]::Replace(
    $text,
    "Where-Object\s*\{\s*Get-ImageKind\s+\$_.Name\s+-eq\s+'Original'\s*\}",
    "Where-Object { (Get-ImageKind -FileName `$_.Name) -eq 'Original' }"
)

$text = [regex]::Replace(
    $text,
    "Where-Object\s*\{\s*Get-ImageKind\s+\$_.Name\s+-eq\s+'Digitized'\s*\}",
    "Where-Object { (Get-ImageKind -FileName `$_.Name) -eq 'Digitized' }"
)

$text = [regex]::Replace(
    $text,
    "Where-Object\s*\{\s*Get-ImageKind\s+\$_.Name\s+-eq\s+'Card'\s*\}",
    "Where-Object { (Get-ImageKind -FileName `$_.Name) -eq 'Card' }"
)

if ($text -eq $original) {
    Write-Warning "No matching bad Where-Object lines were found. The script may already be fixed, or the lines are different than expected."
}
else {
    [System.IO.File]::WriteAllText($ScriptPath, $text, [System.Text.UTF8Encoding]::new($false))
    Write-Host "Fixed PowerShell Where-Object parsing in:"
    Write-Host "  $ScriptPath"
}

Write-Host ""
Write-Host "Now rerun:"
Write-Host "  cd D:\github\ron-english-sketches-and-drawings"
Write-Host "  .\build-canines-and-felines-category.ps1"
