param([string]$Device='enduro4',[string]$Jungle='monkey.jungle',[string]$Output='bin/v04.prg',[switch]$Tests,[switch]$Export)
$ErrorActionPreference='Stop'
$project=Split-Path $PSScriptRoot -Parent
$sdk=(Get-Content -LiteralPath "$env:APPDATA\Garmin\ConnectIQ\current-sdk.cfg" -Raw).Trim()
$java=(Get-Command java -ErrorAction SilentlyContinue).Source
if (!$java) {$java='C:\Program Files\Eclipse Adoptium\jdk-17.0.20.101-hotspot\bin\java.exe'}
$temp=Join-Path $project 'bin/build-temp'
New-Item -ItemType Directory -Force -Path $temp | Out-Null
$arguments=@('-Xms512m','-Dfile.encoding=UTF-8',"-Djava.io.tmpdir=$temp",'-cp',"$sdk\bin\monkeybrains.jar",'com.garmin.monkeybrains.Monkeybrains','-f',(Join-Path $project $Jungle),'-o',(Join-Path $project $Output),'-y',(Join-Path $project 'developer_key'))
if ($Tests) {$arguments+='--unit-test'}
if ($Export) {$arguments+=@('-e','-r')} else {$arguments+=@('-d',$Device)}
& $java @arguments
if ($LASTEXITCODE -ne 0) {throw "Build failed ($LASTEXITCODE)"}
