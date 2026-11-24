$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$tempRoot = Join-Path $env:TEMP ("prompt-enhance-state-" + [Guid]::NewGuid().ToString("N"))
$powerShellExe = (Get-Process -Id $PID).Path

function Assert-Equal {
    param($Actual, $Expected, [string]$Message)
    if ($Actual -ne $Expected) {
        throw "$Message (expected: $Expected, actual: $Actual)"
    }
}

function Invoke-StateScript {
    param([string]$ScriptPath, [string]$Command)

    $previousErrorAction = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $output = & $powerShellExe -NoProfile -File $ScriptPath $Command 2>&1 | Out-String
        $code = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorAction
    }
    return [pscustomobject]@{
        Code   = if ($null -eq $code) { 0 } else { $code }
        Output = $output.Trim()
    }
}

try {
    $scriptDirectory = Join-Path $tempRoot "scripts"
    New-Item -ItemType Directory -Path $scriptDirectory -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $projectRoot "scripts\skill-state.ps1") -Destination $scriptDirectory
    $stateScript = Join-Path $scriptDirectory "skill-state.ps1"
    $statePath = Join-Path $tempRoot "state.json"

    $result = Invoke-StateScript $stateScript "get"
    Assert-Equal $result.Code 0 "Default state command failed"
    Assert-Equal $result.Output "enabled" "Default state should be enabled"
    Assert-Equal (Test-Path -LiteralPath $statePath) $true "Default state file was not created"

    $result = Invoke-StateScript $stateScript "off"
    Assert-Equal $result.Code 0 "Disable command failed"
    Assert-Equal $result.Output "disabled" "Disable command returned wrong state"
    $state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
    Assert-Equal $state.enabled $false "Disabled state was not persisted"

    $result = Invoke-StateScript $stateScript "get"
    Assert-Equal $result.Output "disabled" "Persisted disabled state was not read"

    $result = Invoke-StateScript $stateScript "on"
    Assert-Equal $result.Code 0 "Enable command failed"
    Assert-Equal $result.Output "enabled" "Enable command returned wrong state"

    $beforeInvalid = Get-Content -LiteralPath $statePath -Raw
    $result = Invoke-StateScript $stateScript "invalid"
    Assert-Equal ($result.Code -ne 0) $true "Invalid command should fail"
    $afterInvalid = Get-Content -LiteralPath $statePath -Raw
    Assert-Equal $afterInvalid $beforeInvalid "Invalid command changed state"

    [IO.File]::WriteAllText($statePath, "{broken", [Text.UTF8Encoding]::new($false))
    $result = Invoke-StateScript $stateScript "get"
    Assert-Equal $result.Output "enabled" "Corrupt state should recover to enabled"
    $repaired = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
    Assert-Equal $repaired.enabled $true "Repaired state was not persisted"

    Write-Output "test-state.ps1: PASS"
}
finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }
}
