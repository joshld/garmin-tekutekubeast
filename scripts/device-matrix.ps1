param([string[]]$Devices=@('enduro4','enduro3','fenix7x','fenix7xpro','fenix8solar51mm','fenix8solar47mm','fenix7','fenix7s','fr265','fr965','venu3','vivoactive5'))
$project=Split-Path $PSScriptRoot -Parent
$results=@()
$expectedTests=[regex]::Matches((Get-Content "$project/source/StateTests.mc" -Raw),'(?m)^function \w+Test\(logger\)').Count
if(Test-Path "$project/bin/v05-device-matrix.json"){$results=@(Get-Content "$project/bin/v05-device-matrix.json" -Raw | ConvertFrom-Json)}
foreach($device in $Devices){
    $results=@($results | Where-Object {$_.device -ne $device})
    try {
        Write-Output "MATRIX UNIT BUILD $device"
        & "$PSScriptRoot/build.ps1" -Device $device -Tests -Jungle 'tests/matrix/monkey.jungle' -Output "bin/matrix-$device-tests.prg"
        $unit=& "$PSScriptRoot/run-simulator.ps1" -Device $device -Tests -Program "bin/matrix-$device-tests.prg"
        $unit | Set-Content "$project/bin/matrix-$device-tests.log"
        if(!($unit -contains "PASSED (passed=$expectedTests, failed=0, errors=0)")){throw "Expected $expectedTests passing unit tests"}
        Write-Output "MATRIX LAYOUT BUILD $device"
        & "$PSScriptRoot/build.ps1" -Device $device -Jungle 'tests/matrix/monkey.jungle' -Output "bin/matrix-$device.prg"
        $layout=& "$PSScriptRoot/run-simulator.ps1" -Device $device -Program "bin/matrix-$device.prg"
        $layout | Set-Content "$project/bin/matrix-$device-layout.log"
        if(!($layout -match '^LAYOUT_AUDIT: \d+ scenes; 0 failures$')){throw "Layout audit did not pass: $layout"}
        $memory=@($layout | Select-String '^LAYOUT_MEMORY: peak=(\d+) total=(\d+)$')
        if($memory.Count -eq 0){throw 'Missing layout memory measurement'}
        $m=$memory[-1].Matches[0]
        $results+=@{device=$device;unit='PASS';layout='PASS';peak=[int]$m.Groups[1].Value;total=[int]$m.Groups[2].Value;tests=$expectedTests}
        Write-Output "MATRIX PASS $device"
    } catch {
        $results+=@{device=$device;error="$($_.Exception.Message)"}
        Write-Output "MATRIX FAIL $device : $($_.Exception.Message)"
    }
    $results | ConvertTo-Json -Depth 4 | Set-Content "$project/bin/v05-device-matrix.json"
}
