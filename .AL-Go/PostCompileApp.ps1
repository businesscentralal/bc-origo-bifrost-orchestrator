Param(
    [string] $appFilePath,
    [string] $appType,
    $compilationParams
)

# Bifrost internalsVisibleTo guard (core#129).
#
# Run-AlPipeline calls this after each app compiles, with the produced .app, the app type and the
# compilation parameters. For the main app it:
#   1. fails every build mode except 'Test' when the manifest the app was compiled from (app.json)
#      or the compiled .app (NavxManifest.xml) still grants internalsVisibleTo to an app that is not
#      on the allow-list below - the allow-list is empty, so the Default build (the artifact AL-Go
#      releases, deploys and delivers to AppSource) must carry no grant at all;
#   2. only reports the grants in the 'Test' build mode, which builds and runs the test app and
#      therefore keeps its grant;
#   3. restores the app.json that PreCompileApp.ps1 rewrote.
# Test apps and BCPT apps are not checked.

# App ids that may keep an internalsVisibleTo grant outside the 'Test' build mode. Keep it empty.
$allowedInternalsVisibleTo = @()

if ($compilationParams -is [ref]) {
    $compilationParams = $compilationParams.Value
}
if ($appType -ne 'app') {
    return
}

function Get-BifrostAppJsonGrants {
    param([string] $Path)
    $appJson = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($appJson.PSObject.Properties.Name -notcontains 'internalsVisibleTo') {
        return @()
    }
    return @($appJson.internalsVisibleTo | Where-Object { $_ } | ForEach-Object {
        [pscustomobject]@{ Id = [string]$_.id; Name = [string]$_.name; Publisher = [string]$_.publisher }
    })
}

function Get-BifrostAppFileGrants {
    param([string] $Path)
    Add-Type -AssemblyName System.IO.Compression
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    # A compiled .app is a NAVX header followed by a zip archive; find the first zip local file header.
    $offset = -1
    $searchEnd = [Math]::Min($bytes.Length - 4, 65536)
    for ($i = 0; $i -lt $searchEnd; $i++) {
        if ($bytes[$i] -eq 0x50 -and $bytes[$i + 1] -eq 0x4B -and $bytes[$i + 2] -eq 0x03 -and $bytes[$i + 3] -eq 0x04) {
            $offset = $i
            break
        }
    }
    if ($offset -lt 0) {
        throw "Bifrost internalsVisibleTo check: '$Path' contains no zip archive, cannot read NavxManifest.xml."
    }
    $stream = [System.IO.MemoryStream]::new($bytes, $offset, $bytes.Length - $offset, $false)
    $zip = [System.IO.Compression.ZipArchive]::new($stream, [System.IO.Compression.ZipArchiveMode]::Read)
    try {
        $entry = $zip.Entries | Where-Object { $_.FullName -eq 'NavxManifest.xml' } | Select-Object -First 1
        if (-not $entry) {
            throw "Bifrost internalsVisibleTo check: '$Path' has no NavxManifest.xml."
        }
        $reader = [System.IO.StreamReader]::new($entry.Open())
        try {
            [xml] $manifest = $reader.ReadToEnd()
        }
        finally {
            $reader.Dispose()
        }
    }
    finally {
        $zip.Dispose()
        $stream.Dispose()
    }
    return @($manifest.SelectNodes("//*[local-name()='InternalsVisibleTo']/*") | ForEach-Object {
        [pscustomobject]@{ Id = [string]$_.GetAttribute('Id'); Name = [string]$_.GetAttribute('Name'); Publisher = [string]$_.GetAttribute('Publisher') }
    })
}

function Format-BifrostGrants {
    param([object[]] $Grants)
    if (-not $Grants -or $Grants.Count -eq 0) {
        return 'none'
    }
    return (($Grants | ForEach-Object { "'$($_.Name)' ($($_.Publisher), $($_.Id))" }) -join ', ')
}

$buildMode = "$($env:BuildMode)"
$appJsonPath = Join-Path $compilationParams.appProjectFolder 'app.json'
$backupPath = "$appJsonPath.precompile.bak"
$appFiles = @($appFilePath | Where-Object { $_ })

try {
    $manifestGrants = @(Get-BifrostAppJsonGrants -Path $appJsonPath)
    $appFileGrants = @()
    foreach ($appFile in $appFiles) {
        $appFileGrants += @(Get-BifrostAppFileGrants -Path $appFile)
    }
    if ($appFiles.Count -eq 0 -and $buildMode -ne 'Test') {
        throw "Bifrost internalsVisibleTo check FAILED: build mode '$buildMode' - the compiler returned no .app file to check."
    }
    $appFileNames = ($appFiles | ForEach-Object { Split-Path $_ -Leaf }) -join ', '

    if ($buildMode -eq 'Test') {
        Write-Host "Bifrost internalsVisibleTo check: build mode 'Test' keeps the test grant. app.json: $(Format-BifrostGrants $manifestGrants); $($appFileNames): $(Format-BifrostGrants $appFileGrants)."
        return
    }

    $unexpected = @(@($manifestGrants) + @($appFileGrants) | Where-Object { $allowedInternalsVisibleTo -notcontains $_.Id })
    if ($unexpected.Count -gt 0) {
        throw "Bifrost internalsVisibleTo check FAILED: build mode '$buildMode' - unexpected internalsVisibleTo grant(s). app.json: $(Format-BifrostGrants $manifestGrants); $($appFileNames): $(Format-BifrostGrants $appFileGrants). Allowed ids: $(if ($allowedInternalsVisibleTo.Count) { $allowedInternalsVisibleTo -join ', ' } else { 'none' }). PreCompileApp.ps1 must strip the grant (core#129)."
    }
    Write-Host "Bifrost internalsVisibleTo check PASSED: build mode '$buildMode' - app.json and $appFileNames carry no internalsVisibleTo grant (allow-list: $(if ($allowedInternalsVisibleTo.Count) { $allowedInternalsVisibleTo -join ', ' } else { 'empty' }))."
}
finally {
    if (Test-Path -LiteralPath $backupPath) {
        Move-Item -LiteralPath $backupPath -Destination $appJsonPath -Force
        Write-Host "PostCompileApp: restored $appJsonPath."
    }
}
