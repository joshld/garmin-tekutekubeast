# Default is Enduro 4 only. Explicit -Devices selects an affected/compatibility
# set; obtain owner approval before an all-supported public-release sweep.
param([string[]]$Devices=@('enduro4'),[string]$EvidencePrefix='v05',[int]$Typecheck=0,[string]$Jungle='tests/matrix/monkey.jungle')
$project=Split-Path $PSScriptRoot -Parent
$results=@()
$expectedTests=[regex]::Matches((Get-Content "$project/source/StateTests.mc" -Raw),'(?m)^function \w+Test\(logger\)').Count
if(Test-Path "$project/bin/$EvidencePrefix-device-matrix.json"){$results=@(Get-Content "$project/bin/$EvidencePrefix-device-matrix.json" -Raw | ConvertFrom-Json)}
foreach($device in $Devices){
    $results=@($results | Where-Object {$_.device -ne $device})
    try {
        Write-Output "MATRIX UNIT BUILD $device"
        & "$PSScriptRoot/build.ps1" -Device $device -Tests -Typecheck $Typecheck -Jungle $Jungle -Output "bin/matrix-$device-tests.prg"
        $unit=& "$PSScriptRoot/run-simulator.ps1" -Device $device -Tests -Program "bin/matrix-$device-tests.prg"
        $unit | Set-Content "$project/bin/$EvidencePrefix-$device-tests.log"
        if(!($unit -contains "PASSED (passed=$expectedTests, failed=0, errors=0)")){throw "Expected $expectedTests passing unit tests"}
        Write-Output "MATRIX LAYOUT BUILD $device"
        & "$PSScriptRoot/build.ps1" -Device $device -Typecheck $Typecheck -Jungle $Jungle -Output "bin/matrix-$device.prg"
        $layout=& "$PSScriptRoot/run-simulator.ps1" -Device $device -Program "bin/matrix-$device.prg"
        $layout | Set-Content "$project/bin/$EvidencePrefix-$device-layout.log"
        if(!($layout -match '^LAYOUT_AUDIT: \d+ scenes; 0 failures$')){
            $brief=(@($layout | Select-Object -First 8)-join ' ')
            if($brief.Length -gt 400){$brief=$brief.Substring(0,400)}
            throw "Layout audit did not pass: $brief (full log: $EvidencePrefix-$device-layout.log)"
        }
        $memory=@($layout | Select-String '^LAYOUT_MEMORY: peak=(\d+) total=(\d+)$')
        if($memory.Count -eq 0){throw 'Missing layout memory measurement'}
        $m=$memory[-1].Matches[0]
        $results+=@{device=$device;unit='PASS';layout='PASS';peak=[int]$m.Groups[1].Value;total=[int]$m.Groups[2].Value;tests=$expectedTests;coverage=$Jungle}
        Write-Output "MATRIX PASS $device"
    } catch {
        $results+=@{device=$device;error="$($_.Exception.Message)"}
        Write-Output "MATRIX FAIL $device : $($_.Exception.Message)"
    }
    $results | ConvertTo-Json -Depth 4 | Set-Content "$project/bin/$EvidencePrefix-device-matrix.json"
}
if(@($results | Where-Object {$_.error}).Count -gt 0){throw 'Device audit failures; inspect the recorded logs'}
