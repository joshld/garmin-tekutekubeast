# Quick/default: Enduro 4 only. Affected/full sets require explicit -Devices.
param([string[]]$Devices=@('enduro4'),[string]$EvidencePrefix='v05',[int]$Typecheck=0)
$project=Split-Path $PSScriptRoot -Parent
$expected=[regex]::Matches((Get-Content "$project/source/StateTests.mc" -Raw),'(?m)^function \w+Test\(logger\)').Count
$revision=(& git -c "safe.directory=$($project.Replace('\','/'))" -C $project rev-parse --short HEAD).Trim()
$results=@()
if(Test-Path "$project/bin/$EvidencePrefix-unit-matrix.json"){$results=@(Get-Content "$project/bin/$EvidencePrefix-unit-matrix.json" -Raw | ConvertFrom-Json)}
foreach($device in $Devices){
    $results=@($results | Where-Object {$_.device -ne $device})
    try{
        & "$PSScriptRoot/build.ps1" -Device $device -Typecheck $Typecheck -Tests -Jungle 'tests/matrix/monkey.jungle' -Output "bin/matrix-unit-$device.prg"
        $log=& "$PSScriptRoot/run-simulator.ps1" -Device $device -Tests -Program "bin/matrix-unit-$device.prg"
        $log | Set-Content "$project/bin/$EvidencePrefix-final-unit-$device.log"
        if(!($log -contains "PASSED (passed=$expected, failed=0, errors=0)")){throw 'Missing complete passing summary'}
        $results+=@{device=$device;unit='PASS';tests=$expected;revision=$revision}
        Write-Output "FINAL UNIT PASS $device ($expected)"
    }catch{
        $results+=@{device=$device;error="$($_.Exception.Message)";revision=$revision}
        Write-Output "FINAL UNIT FAIL $device : $($_.Exception.Message)"
    }
    $results | ConvertTo-Json -Depth 4 | Set-Content "$project/bin/$EvidencePrefix-unit-matrix.json"
}
if(@($results | Where-Object {$_.error}).Count -gt 0){throw 'One or more final unit profiles failed; inspect logs'}
