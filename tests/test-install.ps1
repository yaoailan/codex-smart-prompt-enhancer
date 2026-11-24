$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$tempRoot = Join-Path $env:TEMP ("prompt-enhance-install-" + [Guid]::NewGuid().ToString("N"))
$codexHome = Join-Path $tempRoot "codex-home"
$powerShellExe = (Get-Process -Id $PID).Path

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) {
        throw $Message
    }
}

function Invoke-Installer {
    $output = & $powerShellExe -NoProfile -File (Join-Path $projectRoot "scripts\install.ps1") -CodexHome $codexHome 2>&1 | Out-String
    $code = $LASTEXITCODE
    if (($null -eq $code -or $code -ne 0)) {
        throw "Installer failed:`n$output"
    }
    return $output
}

try {
    New-Item -ItemType Directory -Path $codexHome -Force | Out-Null
    $agentsPath = Join-Path $codexHome "AGENTS.md"
    $originalRule = "# Existing user rule`n`nKeep this line."
    [IO.File]::WriteAllText($agentsPath, $originalRule, [Text.UTF8Encoding]::new($false))

    Invoke-Installer | Out-Null
    $destination = Join-Path $codexHome "skills\prompt-enhance"
    Assert-True (Test-Path -LiteralPath (Join-Path $destination "SKILL.md")) "SKILL.md missing"
    Assert-True (Test-Path -LiteralPath (Join-Path $destination "agents\openai.yaml")) "openai.yaml missing"
    Assert-True (Test-Path -LiteralPath (Join-Path $destination "state.json")) "state.json missing"
    Assert-True (Test-Path -LiteralPath (Join-Path $destination "rules\prompt-enhance.md")) "rules file missing"

    $agents = Get-Content -LiteralPath $agentsPath -Raw
    Assert-True ($agents.Contains($originalRule)) "Existing AGENTS.md content was not preserved"
    Assert-True ($agents.Contains("# >>> prompt-enhance: smart default >>>")) "Global rule marker missing"
    Assert-True ((Test-Path (Join-Path $codexHome "AGENTS.md.backup-*"))) "AGENTS.md backup missing"

    $stateScript = Join-Path $destination "scripts\skill-state.ps1"
    & $powerShellExe -NoProfile -File $stateScript off | Out-Null
    Assert-True ($LASTEXITCODE -eq 0) "Could not disable installed state"
    $statePath = Join-Path $destination "state.json"
    $stateBeforeReinstall = [IO.File]::ReadAllText($statePath)
    $unmanagedPath = Join-Path $destination "user-note.txt"
    [IO.File]::WriteAllText($unmanagedPath, "keep", [Text.UTF8Encoding]::new($false))

    Invoke-Installer | Out-Null
    Assert-True ([IO.File]::ReadAllText($statePath) -eq $stateBeforeReinstall) "Reinstall overwrote existing state"
    Assert-True (Test-Path -LiteralPath $unmanagedPath) "Reinstall removed an unrelated file"
    $agentsAfterReinstall = Get-Content -LiteralPath $agentsPath -Raw
    Assert-True (([regex]::Matches($agentsAfterReinstall, [regex]::Escape("# >>> prompt-enhance: smart default >>>"))).Count -eq 1) "Global rule was duplicated"

    Write-Output "test-install.ps1: PASS"
}
finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }
}
