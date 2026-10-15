param([string[]]$Devices=@('enduro4','enduro3','fenix7x','fenix7xpro','fenix8solar51mm','fenix8solar47mm','enduro','fenix6xpro','fenix7','fenix7s','fr265','fr965','venu3','vivoactive5'))
$project=Split-Path $PSScriptRoot -Parent
$results=@()
if(Test-Path "$project/bin/device-matrix.json"){$results=@(Get-Content "$project/bin/device-matrix.json" -Raw | ConvertFrom-Json)}
foreach($device in $Devices){
    $results=@($results | Where-Object {$_.device -ne $device})
    try {
        Write-Output "MATRIX UNIT BUILD $device"
        & "$PSScriptRoot/build.ps1" -Device $device -Tests -Jungle 'tests/matrix/monkey.jungle' -Output "bin/matrix-$device-tests.prg"
        $unit=& "$PSScriptRoot/run-simulator.ps1" -Device $device -Tests -Program "bin/matrix-$device-tests.prg"
        $unit | Set-Content "$project/bin/matrix-$device-tests.log"
        if(!($unit -match '^PASSED \(passed=\d+, failed=0, errors=0\)$')){throw "Unit tests did not pass"}
        Write-Output "MATRIX LAYOUT BUILD $device"
        & "$PSScriptRoot/build.ps1" -Device $device -Jungle 'tests/matrix/monkey.jungle' -Output "bin/matrix-$device.prg"
        $layout=& "$PSScriptRoot/run-simulator.ps1" -Device $device -Program "bin/matrix-$device.prg"
        $layout | Set-Content "$project/bin/matrix-$device-layout.log"
        if(!($layout -match '^LAYOUT_AUDIT: \d+ scenes; 0 failures$')){throw "Layout audit did not pass: $layout"}
        $results+=@{device=$device;unit='PASS';layout='PASS'}
        Write-Output "MATRIX PASS $device"
    } catch {
        $results+=@{device=$device;error="$($_.Exception.Message)"}
        Write-Output "MATRIX FAIL $device : $($_.Exception.Message)"
    }
    $results | ConvertTo-Json -Depth 4 | Set-Content "$project/bin/device-matrix.json"
}
