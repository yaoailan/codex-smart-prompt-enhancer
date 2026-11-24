[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Command = "get"
)

$ErrorActionPreference = "Stop"
$skillRoot = Split-Path -Parent $PSScriptRoot
$statePath = Join-Path $skillRoot "state.json"
$normalizedCommand = $Command.ToLowerInvariant()
$validCommands = @("get", "status", "on", "enable", "off", "disable")

if ($validCommands -notcontains $normalizedCommand) {
    [Console]::Error.WriteLine("Usage: skill-state.ps1 [get|on|off]")
    exit 2
}

function Write-State {
    param([bool]$Enabled)

    $payload = [ordered]@{
        enabled   = $Enabled
        updatedAt = (Get-Date).ToUniversalTime().ToString("o")
    } | ConvertTo-Json -Compress

    $tempPath = Join-Path $skillRoot (".state-" + [Guid]::NewGuid().ToString("N") + ".tmp")
    try {
        [IO.File]::WriteAllText($tempPath, $payload, [Text.UTF8Encoding]::new($false))
        Move-Item -LiteralPath $tempPath -Destination $statePath -Force
    }
    finally {
        if (Test-Path -LiteralPath $tempPath) {
            Remove-Item -LiteralPath $tempPath -Force
        }
    }
}

function Read-State {
    if (-not (Test-Path -LiteralPath $statePath)) {
        Write-State $true
        return $true
    }

    try {
        $state = Get-Content -LiteralPath $statePath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        if ($state.enabled -is [bool]) {
            return [bool]$state.enabled
        }
    }
    catch {
        # A damaged local state must never disable the feature unexpectedly.
    }

    Write-State $true
    return $true
}

switch ($normalizedCommand) {
    { $_ -in @("on", "enable") } {
        Write-State $true
        break
    }
    { $_ -in @("off", "disable") } {
        Write-State $false
        break
    }
}

$enabled = Read-State
if ($enabled) {
    Write-Output "enabled"
}
else {
    Write-Output "disabled"
}

exit 0
