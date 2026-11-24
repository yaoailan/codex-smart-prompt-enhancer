[CmdletBinding()]
param(
    [string]$CodexHome
)

$ErrorActionPreference = "Stop"
$sourceRoot = Split-Path -Parent $PSScriptRoot

if ($CodexHome) {
    $codexRoot = [IO.Path]::GetFullPath($CodexHome)
}
elseif ($env:CODEX_HOME) {
    $codexRoot = [IO.Path]::GetFullPath($env:CODEX_HOME)
}
else {
    $codexRoot = Join-Path $HOME ".codex"
}

$destination = Join-Path $codexRoot "skills\prompt-enhance"
$utf8NoBom = [Text.UTF8Encoding]::new($false)

function Copy-RelativeFile {
    param([string]$RelativePath)

    $source = Join-Path $sourceRoot $RelativePath
    if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
        return
    }

    $target = Join-Path $destination $RelativePath
    $targetDirectory = Split-Path -Parent $target
    [IO.Directory]::CreateDirectory($targetDirectory) | Out-Null
    Copy-Item -LiteralPath $source -Destination $target -Force
}

New-Item -ItemType Directory -Path $destination -Force | Out-Null

foreach ($file in @("SKILL.md", "README.md", "LICENSE", "PRIVACY.md")) {
    Copy-RelativeFile $file
}

foreach ($directory in @("agents", "scripts", "rules")) {
    $sourceDirectory = Join-Path $sourceRoot $directory
    if (-not (Test-Path -LiteralPath $sourceDirectory -PathType Container)) {
        continue
    }

    Get-ChildItem -LiteralPath $sourceDirectory -File -Recurse | ForEach-Object {
        $relativePath = $_.FullName.Substring($sourceRoot.TrimEnd("\").Length + 1)
        Copy-RelativeFile $relativePath
    }
}

$statePath = Join-Path $destination "state.json"
if (-not (Test-Path -LiteralPath $statePath)) {
    $defaultState = [ordered]@{
        enabled   = $true
        updatedAt = (Get-Date).ToUniversalTime().ToString("o")
    } | ConvertTo-Json -Compress
    [IO.File]::WriteAllText($statePath, $defaultState, $utf8NoBom)
}
$state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
$stateLabel = if ([bool]$state.enabled) { "enabled" } else { "disabled" }

$markerStart = "# >>> prompt-enhance: smart default >>>"
$markerEnd = "# <<< prompt-enhance: smart default <<<"
$rulesPath = Join-Path $destination "rules\prompt-enhance.md"
$agentsPath = Join-Path $codexRoot "AGENTS.md"
$rules = [IO.File]::ReadAllText($rulesPath, $utf8NoBom).TrimEnd()
$block = $markerStart + "`n" + $rules + "`n" + $markerEnd
$existing = if (Test-Path -LiteralPath $agentsPath) {
    [IO.File]::ReadAllText($agentsPath, $utf8NoBom)
}
else {
    ""
}

$updated = $existing
$startIndex = $existing.IndexOf($markerStart, [StringComparison]::Ordinal)
$endIndex = $existing.IndexOf($markerEnd, [StringComparison]::Ordinal)

if (($startIndex -ge 0) -xor ($endIndex -ge 0)) {
    throw "AGENTS.md contains only one prompt-enhance marker. Repair the markers before reinstalling."
}

if ($startIndex -ge 0) {
    $afterEnd = $endIndex + $markerEnd.Length
    $updated = $existing.Substring(0, $startIndex) + $block + $existing.Substring($afterEnd)
}
else {
    $separator = if ($existing.Length -eq 0 -or $existing.EndsWith("`n")) { "" } else { "`n`n" }
    $updated = $existing + $separator + $block + "`n"
}

$backupPath = $null
if ($updated -ne $existing) {
    [IO.Directory]::CreateDirectory($codexRoot) | Out-Null
    if (Test-Path -LiteralPath $agentsPath) {
        $backupPath = $agentsPath + ".backup-" + (Get-Date).ToString("yyyyMMdd-HHmmss")
        Copy-Item -LiteralPath $agentsPath -Destination $backupPath -Force
    }
    [IO.File]::WriteAllText($agentsPath, $updated, $utf8NoBom)
}

Write-Output "Installed prompt-enhance to: $destination"
Write-Output "State: $stateLabel"
if ($updated -ne $existing) {
    Write-Output "Global rules: updated $agentsPath"
}
else {
    Write-Output "Global rules: unchanged $agentsPath"
}
if ($backupPath) {
    Write-Output "Backup: $backupPath"
}
