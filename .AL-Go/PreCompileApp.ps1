Param(
    [string] $appType,
    [ref] $compilationParams
)

# Bifrost: the main app lists its own test app in app.json "internalsVisibleTo" so the test app can
# exercise internal objects. That grant must never ship: any extension that copies the test app's
# id, name and publisher would get every internal object.
#
# Only the "Test" build mode keeps it - that mode builds and runs the test app. Every other build
# mode (Default = the artifact AL-Go releases, deploys and delivers to AppSource) compiles the app
# without it and without the AS0081 suppression, so AppSourceCop checks the shipped manifest.
#
# COSMO Alpaca replaces this hook with its own PreCompileApp override and keeps this script in
# $AlGoPreCompileApp; PipelineInitialize.ps1 chains the two so this script runs (core#129).
# PostCompileApp.ps1 fails the build if a grant survives and restores the original app.json.

if ($appType -ne 'app') {
    return
}
if ($env:BuildMode -eq 'Test') {
    Write-Host "PreCompileApp: build mode 'Test' - keeping internalsVisibleTo for the test app."
    return
}

$appFolder = $compilationParams.Value.appProjectFolder
$appJsonPath = Join-Path $appFolder 'app.json'
if (-not (Test-Path -LiteralPath $appJsonPath)) {
    return
}

$appJson = Get-Content -LiteralPath $appJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
$changed = $false

if ($appJson.PSObject.Properties.Name -contains 'internalsVisibleTo') {
    $appJson.PSObject.Properties.Remove('internalsVisibleTo')
    $changed = $true
}
if ($appJson.PSObject.Properties.Name -contains 'suppressWarnings') {
    $kept = @($appJson.suppressWarnings | Where-Object { $_ -ne 'AS0081' })
    if ($kept.Count -ne @($appJson.suppressWarnings).Count) {
        $appJson.suppressWarnings = $kept
        $changed = $true
    }
}

if ($changed) {
    Copy-Item -LiteralPath $appJsonPath -Destination "$appJsonPath.precompile.bak" -Force
    $appJson | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $appJsonPath -Encoding UTF8
    Write-Host "PreCompileApp: build mode '$($env:BuildMode)' - removed internalsVisibleTo and the AS0081 suppression from $appJsonPath."
}
else {
    Write-Host "PreCompileApp: build mode '$($env:BuildMode)' - $appJsonPath has no internalsVisibleTo or AS0081 suppression to remove."
}
