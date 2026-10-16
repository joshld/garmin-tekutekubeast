param([string]$Device='enduro4',[string]$Program='bin/v05.prg',[switch]$Tests)
$project=Split-Path $PSScriptRoot -Parent
$sdk=(Get-Content "$env:APPDATA\Garmin\ConnectIQ\current-sdk.cfg" -Raw).Trim()
$java='C:\Program Files\Eclipse Adoptium\jdk-17.0.20.101-hotspot\bin\java.exe'
$arguments=@("-Djava.io.tmpdir=$project\bin\build-temp",'-classpath',"$sdk\bin\monkeybrains.jar",'com.garmin.monkeybrains.monkeydodeux.MonkeyDoDeux','-f',(Join-Path $project $Program),'-d',$Device,'-s',"$sdk\bin\shell.exe")
if($Tests){$arguments+='-t'}
if($Program -like 'bin/matrix-*'){
    $python="$env:USERPROFILE\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe"
    if(!(Test-Path $python)){$python=(Get-Command python -ErrorAction Stop).Source}
    $bridge=@("$PSScriptRoot/simulator_bridge.py",'--sdk',$sdk,'--java',$java,'--program',(Join-Path $project $Program),'--device',$Device,'--temp',"$project/bin/build-temp")
    if($Tests){$bridge+='--tests'}
    $result=& $python @bridge
    $code=$LASTEXITCODE
}else{
    $result=& $java @arguments
    $code=$LASTEXITCODE
}
$result | Write-Output
# SDK shell can return 1 after successful test completion. Require its explicit
# complete summary, not just an exit code or the presence of one passing test.
if($Tests -and ($result -match '^PASSED \(passed=\d+, failed=0, errors=0\)$')){exit 0}
exit $code
