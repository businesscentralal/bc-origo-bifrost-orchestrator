Write-Host "::group::PipelineInitialize"

if (Test-Path -LiteralPath "$($env:NeedsContext)" -PathType Leaf) {
    Write-Host "Load Context from file at '$($env:NeedsContext)'"
    $needsContext = "$($env:NeedsContext)" | Get-Item | Get-Content -Raw | ConvertFrom-Json
}
else {
    Write-Host "Load Context from Json"
    $needsContext = "$($env:NeedsContext)" | ConvertFrom-Json
}

$initializationJob = $needsContext.'CustomJob-Alpaca-Initialization'

$scriptsPath = "./.alpaca/Scripts/"
$scriptsArchiveUrl = $initializationJob.outputs.scriptsArchiveUrl
$scriptsArchiveDirectory = $initializationJob.outputs.scriptsArchiveDirectory

Write-Host "Collect workflow jobs from context:"
$jobs = @{}
$jobIds = $initializationJob.outputs.jobIdsJson | ConvertFrom-Json
foreach ($jobId in $jobIds.PSObject.Properties.GetEnumerator()) {
    if ($needsContext.PSObject.Properties.Name -contains $jobId.Value) {
        Write-Host " - $($jobId.Name): $($jobId.Value)"
        $jobs[$jobId.Name] = $needsContext.$($jobId.Value)
    }
}
if ($jobs.Count -eq 0) {
    Write-Host " - None"
}

Write-Host "Prepare Alpaca scripts directory at '$scriptsPath'"
if (Test-Path -Path $scriptsPath) {
    Remove-Item -Path $scriptsPath -Recurse -Force
}
New-Item -Path $scriptsPath -ItemType Directory -Force | Out-Null

if ($scriptsArchiveUrl) {
    try {
        $tempPath = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
        $tempArchivePath = "$tempPath.zip"

        Write-Host "Download Alpaca scripts archive from '$scriptsArchiveUrl'"
        Invoke-WebRequest -Uri $scriptsArchiveUrl -OutFile $tempArchivePath

        Write-Host "Extract Alpaca scripts archive"
        Expand-Archive -Path $tempArchivePath -DestinationPath $tempPath -Force

        Write-Host "Copy Alpaca scripts to '$scriptsPath'"
        Get-Item -Path (Join-Path $tempPath $scriptsArchiveDirectory) |
            Get-ChildItem |
            ForEach-Object {
                Copy-Item -Path $_.FullName -Destination $scriptsPath -Recurse -Force
            }
    }
    catch {
        throw
    }
    finally {
        if ($tempPath -and (Test-Path $tempPath)) {
            Remove-Item -Path $tempPath -Recurse -Force -ErrorAction SilentlyContinue
        }
        if ($tempArchivePath -and (Test-Path $tempArchivePath)) {
            Remove-Item -Path $tempArchivePath -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

Write-Host "Alpaca scripts found:"
$scriptFiles = Get-ChildItem -Path $scriptsPath -File -Recurse
if ($scriptFiles) {
    $scriptFiles | ForEach-Object {
        Write-Host "- $(Resolve-Path -Path $_.FullName -Relative)"
    }
} else {
    Write-Host "- None"
}

$overridesPath = Join-Path $scriptsPath "/Overrides/RunAlPipeline"
Write-Host "Alpaca overrides path: $overridesPath"
$overridePath = Join-Path $overridesPath "PipelineInitialize.ps1"
if (Test-Path $overridePath) {
    Write-Host "Invoking Alpaca override"
    . $overridePath -Jobs $jobs -ScriptsPath $scriptsPath
}

# Bifrost (core#129): the Alpaca override above moves .AL-Go/PreCompileApp.ps1 into $AlGoPreCompileApp
# and sets $PreCompileApp to COSMO Alpaca's own PreCompileApp override. Unlike Alpaca's other overrides,
# that one never calls its $AlGo... hook, so our PreCompileApp.ps1 (the internalsVisibleTo strip) would
# never run. Chain them: Alpaca's override first, then $AlGoPreCompileApp with the same parameters.
# Scope 1 is Run-AlPipeline, the scope the Alpaca override writes both variables to.
$alpacaPreCompileApp = Get-Variable -Name 'PreCompileApp' -Scope 1 -ValueOnly -ErrorAction Ignore
$alGoPreCompileApp = Get-Variable -Name 'AlGoPreCompileApp' -Scope 1 -ValueOnly -ErrorAction Ignore
if (-not $alGoPreCompileApp) {
    Write-Host "Bifrost: no `$AlGoPreCompileApp to chain (.AL-Go/PreCompileApp.ps1 missing or no Alpaca PreCompileApp override)."
}
elseif ($alpacaPreCompileApp -and ($alpacaPreCompileApp.ToString() -match '\$AlGoPreCompileApp')) {
    Write-Host "Bifrost: the COSMO Alpaca PreCompileApp override already calls `$AlGoPreCompileApp - nothing to chain."
}
elseif ($alpacaPreCompileApp) {
    Set-Variable -Name 'BifrostAlpacaPreCompileApp' -Value $alpacaPreCompileApp -Scope 1
    Set-Variable -Name 'PreCompileApp' -Scope 1 -Value {
        param(
            [string] $AppType,
            [ref] $CompilationParams
        )
        Invoke-Command -ScriptBlock $BifrostAlpacaPreCompileApp -ArgumentList $AppType, $CompilationParams
        Write-Host "Bifrost: running `$AlGoPreCompileApp (.AL-Go/PreCompileApp.ps1) after the COSMO Alpaca override."
        Invoke-Command -ScriptBlock $AlGoPreCompileApp -ArgumentList $AppType, $CompilationParams
    }
    Write-Host "Bifrost: PreCompileApp chained - COSMO Alpaca override, then `$AlGoPreCompileApp (.AL-Go/PreCompileApp.ps1)."
}

Write-Host "::endgroup::"
