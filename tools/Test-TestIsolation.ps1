$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$hook = (Get-Command (Join-Path $repo '.AL-Go/RunTestsInBcContainer.ps1')).ScriptBlock
$temp = Join-Path ([IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString())
[void](New-Item $temp -ItemType Directory)
$script:mode = 'pass'
$script:calls = @()

function Run-TestsInBcContainer {
    param($extensionId, $JUnitResultFileName, $testCodeunitRange, $testRunnerCodeunitId,
        $AppendToJUnitResultFile, $returnTrueIfAllPassed)
    $script:calls += @{ range = $testCodeunitRange; runner = $testRunnerCodeunitId }
    [xml]$xml = '<testsuites><testsuite /></testsuites>'
    foreach ($file in Get-ChildItem (Join-Path $repo 'test') -Filter '*.al' -Recurse) {
        $source = Get-Content $file.FullName -Raw
        if ($source -notmatch '(?im)^\s*codeunit\s+(\d+)\s+"[^"]+"') { continue }
        $id = $Matches[1]
        if ($id -notin ($testCodeunitRange -split '\|')) { continue }
        foreach ($method in [regex]::Matches($source, '(?is)\[Test\]\s*(?:\[[^\]]+\]\s*)*procedure\s+"?(\w+)"?\s*\(')) {
            $case = $xml.CreateElement('testcase')
            $case.SetAttribute('classname', "$id Test")
            $case.SetAttribute('name', $method.Groups[1].Value)
            if ($id -eq '96456' -and $script:mode -in @('failure', 'skipped')) {
                [void]$case.AppendChild($xml.CreateElement($script:mode))
            }
            [void]$xml.SelectSingleNode('/testsuites/testsuite').AppendChild($case)
        }
    }
    if ($script:mode -eq 'missing' -and $testRunnerCodeunitId -eq 130451) {
        [void]$xml.SelectSingleNode('/testsuites/testsuite').RemoveChild($xml.SelectSingleNode('/testsuites/testsuite').FirstChild)
    }
    $xml.Save($JUnitResultFileName)
    return ($script:mode -ne 'failure')
}

try {
    $parameters = @{ extensionId = '194ecd04-5688-4af6-94bc-732c714251fc'; JUnitResultFileName = (Join-Path $temp 'results.xml') }
    if (!(Invoke-Command $hook -ArgumentList $parameters)) { throw 'Successful complete suite rejected.' }
    if ($script:calls.Count -ne 2 -or $script:calls[1].range -ne '96425|96456' -or $script:calls[1].runner -ne 130451 -or $script:calls[0].runner -ne 130450 -or '96456' -in ($script:calls[0].range -split '\|')) {
        throw 'Isolation partition is incorrect.'
    }
    foreach ($mode in @('failure', 'skipped')) {
        $script:mode = $mode
        if (Invoke-Command $hook -ArgumentList $parameters) { throw "$mode was reported as success." }
    }
    $script:mode = 'missing'
    $rejected = $false
    try { Invoke-Command $hook -ArgumentList $parameters | Out-Null } catch {
        if ($_.Exception.Message -notlike 'Incomplete full suite:*') { throw }
        $rejected = $true
    }
    if (!$rejected) { throw 'Missing test accepted.' }
    $parameters.testCodeunitRange = '96456'
    $rejected = $false
    try { Invoke-Command $hook -ArgumentList $parameters | Out-Null } catch {
        if ($_.Exception.Message -notlike 'Full-suite execution cannot accept*') { throw }
        $rejected = $true
    }
    if (!$rejected) { throw 'Partial suite accepted.' }
    Write-Host 'PASS: isolation selection, complete inventory, failure, skipped, missing and partial-suite guards.'
} finally {
    Remove-Item $temp -Recurse -Force
}
