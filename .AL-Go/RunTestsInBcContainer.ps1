param([hashtable] $Parameters)

# Alpaca v2.11 invokes this AL-Go hook inside its own override, retaining its
# missing-test guard. Keep ordinary isolation for rollback-dependent tests and
# use Microsoft's disabled-isolation runner only where the AL source requires it.
$testRoot = Join-Path $PSScriptRoot '../test'
$manifest = Get-Content (Join-Path $testRoot 'app.json') -Raw | ConvertFrom-Json
if ([string]$Parameters.extensionId -ne [string]$manifest.id) {
    return (Run-TestsInBcContainer @Parameters)
}
if (!$Parameters.JUnitResultFileName) { throw 'Isolation-aware execution requires JUnit evidence.' }
foreach ($filter in @('testCodeunit', 'testCodeunitRange', 'testFunction', 'testGroup', 'requiredTestIsolation', 'testType')) {
    if ($Parameters[$filter] -and $Parameters[$filter] -ne '*') {
        throw "Full-suite execution cannot accept a partial $filter filter."
    }
}

$groups = @{ Codeunit = @(); Disabled = @() }
$expected = @{}
foreach ($file in Get-ChildItem $testRoot -Filter '*.al' -File -Recurse) {
    $source = Get-Content $file.FullName -Raw
    if ($source -notmatch '(?im)^\s*Subtype\s*=\s*Test\s*;') { continue }
    if ($source -notmatch '(?im)^\s*codeunit\s+(\d+)\s+"[^"]+"') { throw "Cannot identify $file" }
    $id = $Matches[1]
    $isolation = 'Codeunit'
    if ($source -match '(?im)^\s*RequiredTestIsolation\s*=\s*(\w+)\s*;') { $isolation = $Matches[1] }
    if (!$groups.ContainsKey($isolation)) { throw "Unsupported isolation $isolation in $file" }
    $groups[$isolation] += $id
    $methods = [regex]::Matches($source, '(?is)\[Test\]\s*(?:\[[^\]]+\]\s*)*procedure\s+"?(\w+)"?\s*\(')
    if (!$methods.Count) { throw "No test methods identified in $file" }
    foreach ($method in $methods) {
        $key = "$id/$($method.Groups[1].Value)"
        if ($expected.ContainsKey($key)) { throw "Duplicate source test $key" }
        $expected[$key] = $true
    }
}
if (!$expected.Count) { throw 'The source test inventory is empty.' }

$combined = [xml]'<testsuites />'
if ($Parameters.AppendToJUnitResultFile -and (Test-Path -LiteralPath $Parameters.JUnitResultFileName)) {
    $combined = [xml](Get-Content -LiteralPath $Parameters.JUnitResultFileName -Raw)
}
$seen = @{}
$allPassed = $true
foreach ($isolation in @('Codeunit', 'Disabled')) {
    if (!$groups[$isolation].Count) { continue }
    $groupParameters = $Parameters.Clone()
    $groupParameters.testCodeunitRange = ($groups[$isolation] | Sort-Object {[int]$_}) -join '|'
    $groupParameters.testRunnerCodeunitId = if ($isolation -eq 'Disabled') { 130451 } else { 130450 }
    $groupParameters.JUnitResultFileName = "$($Parameters.JUnitResultFileName).$isolation.xml"
    $groupParameters.AppendToJUnitResultFile = $false
    $groupParameters.returnTrueIfAllPassed = $true
    Write-Host "Bifrost full suite: $isolation isolation, runner $($groupParameters.testRunnerCodeunitId), codeunits $($groupParameters.testCodeunitRange)."
    $passed = Run-TestsInBcContainer @groupParameters
    $allPassed = $allPassed -and ($passed -eq $true)
    [xml]$result = Get-Content -LiteralPath $groupParameters.JUnitResultFileName -Raw
    foreach ($case in $result.SelectNodes('//testcase')) {
        $id = ([string]$case.classname -split ' ')[0]
        $key = "$id/$($case.name)"
        if (!$expected.ContainsKey($key) -or $seen.ContainsKey($key)) { throw "Unexpected or duplicate executed test $key" }
        $seen[$key] = $true
        if ($case.SelectSingleNode('skipped')) { $allPassed = $false }
        if ($case.SelectSingleNode('failure') -or $case.SelectSingleNode('error')) { $allPassed = $false }
    }
    foreach ($suite in $result.SelectNodes('/testsuites/testsuite')) {
        [void]$combined.DocumentElement.AppendChild($combined.ImportNode($suite, $true))
    }
    # Save even failing test evidence for AL-Go's normal analysis/artifact steps.
    $combined.Save($Parameters.JUnitResultFileName)
}
if ($seen.Count -ne $expected.Count) { throw "Incomplete full suite: executed $($seen.Count) of $($expected.Count) source tests." }
Write-Host "Bifrost full suite: $($seen.Count) distinct source tests executed; all passed=$allPassed."
return $allPassed
