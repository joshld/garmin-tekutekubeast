param([string]$Device='enduro4',[string]$Program='bin/v04.prg',[switch]$Tests)
$project=Split-Path $PSScriptRoot -Parent
$sdk=(Get-Content "$env:APPDATA\Garmin\ConnectIQ\current-sdk.cfg" -Raw).Trim()
$java='C:\Program Files\Eclipse Adoptium\jdk-17.0.20.101-hotspot\bin\java.exe'
$arguments=@("-Djava.io.tmpdir=$project\bin\build-temp",'-classpath',"$sdk\bin\monkeybrains.jar",'com.garmin.monkeybrains.monkeydodeux.MonkeyDoDeux','-f',(Join-Path $project $Program),'-d',$Device,'-s',"$sdk\bin\shell.exe")
if($Tests){$arguments+='-t'}
& $java @arguments
exit $LASTEXITCODE
