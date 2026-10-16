param([string[]]$Devices=@('enduro4','enduro3','fenix7x','fenix7xpro','fenix8solar51mm','fenix8solar47mm','fenix7','fenix7s','fr265','fr965','venu3','vivoactive5'))
# Set the simulator's Settings > Glance Launch Mode to Glance before running.
$project=Split-Path $PSScriptRoot -Parent
$results=@()
if(Test-Path "$project/bin/v05-glance-matrix.json"){$results=@(Get-Content "$project/bin/v05-glance-matrix.json" -Raw | ConvertFrom-Json)}
foreach($device in $Devices){
    $results=@($results | Where-Object {$_.device -ne $device})
    try {
        & "$PSScriptRoot/build.ps1" -Device $device -Jungle 'tests/glance/monkey.jungle' -Output "bin/matrix-glance-$device.prg"
        $log=& "$PSScriptRoot/run-simulator.ps1" -Device $device -Program "bin/matrix-glance-$device.prg"
        $log | Set-Content "$project/bin/matrix-glance-$device.log"
        $measurement=@($log | Select-String '^GLANCE_AUDIT: (\d+x\d+) used=(\d+) total=(\d+)$')
        if($measurement.Count -eq 0 -or $log -match 'Error|crash' -or !($log -match '^GLANCE_LAYOUT: 0 failures$')){throw "No clean Glance measurement/layout: $log"}
        $m=$measurement[-1].Matches[0]
        $used=[int]$m.Groups[2].Value;$total=[int]$m.Groups[3].Value
        if($used -ge $total){throw 'Glance memory exhausted'}
        $results+=@{device=$device;glance='PASS';dimensions=$m.Groups[1].Value;used=$used;total=$total}
        Write-Output "GLANCE PASS $device $used / $total"
    }catch{
        $results+=@{device=$device;error="$($_.Exception.Message)"}
        Write-Output "GLANCE FAIL $device : $($_.Exception.Message)"
    }
    $results | ConvertTo-Json -Depth 4 | Set-Content "$project/bin/v05-glance-matrix.json"
}
