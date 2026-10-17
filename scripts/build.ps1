param([string]$Device='enduro4',[string]$Jungle='monkey.jungle',[string]$Output='bin/v052-public.prg',[switch]$Tests,[switch]$Export,[switch]$Release,[switch]$Owner,[int]$Typecheck=0)
$ErrorActionPreference='Stop'
$project=Split-Path $PSScriptRoot -Parent
if($Export -and $Owner){throw 'Store exports cannot include Developer Mode. Use a signed -Owner program for personal use.'}
if($Export -and ($Tests -or $Jungle -ne 'monkey.jungle')){throw 'Store exports must use the production manifest and cannot include QA tests.'}
$sdk=(Get-Content -LiteralPath "$env:APPDATA\Garmin\ConnectIQ\current-sdk.cfg" -Raw).Trim()
$java=(Get-Command java -ErrorAction SilentlyContinue).Source
if (!$java) {$java='C:\Program Files\Eclipse Adoptium\jdk-17.0.20.101-hotspot\bin\java.exe'}
$temp=Join-Path $project 'bin/build-temp'
New-Item -ItemType Directory -Force -Path $temp | Out-Null
if($Export -or (Select-String -LiteralPath "$project/monkey.jungle" -SimpleMatch "$Device.sourcePath = bin/legacy-source" -Quiet)){
    $python="$env:USERPROFILE\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe"
    if(!(Test-Path $python)){$python=(Get-Command python -ErrorAction Stop).Source}
    & $python "$PSScriptRoot/prepare_legacy_resources.py"
    & $python "$PSScriptRoot/prepare_legacy_sources.py"
    if($LASTEXITCODE -ne 0){throw 'Cannot prepare constrained-device scope variant'}
}
if(!$Owner){
    $python="$env:USERPROFILE\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe"
    $publicArgs=@("$PSScriptRoot/prepare_public_sources.py",'--jungle',$Jungle)
    if($Tests){$publicArgs+='--tests'}
    & $python @publicArgs
    if($LASTEXITCODE -ne 0){throw 'Public source exclusion failed; refusing to build'}
    $Jungle='bin/public-build/monkey.jungle'
}
$arguments=@('-Xms512m','-Dfile.encoding=UTF-8',"-Djava.io.tmpdir=$temp",'-cp',"$sdk\bin\monkeybrains.jar",'com.garmin.monkeybrains.Monkeybrains','-f',(Join-Path $project $Jungle),'-o',(Join-Path $project $Output),'-y',(Join-Path $project 'developer_key'))
# Explicit gradual type checking as well as the compiler/linker and SDK tests.
if($Typecheck -ge 0){$arguments+=@('-l',$Typecheck.ToString())}
if ($Tests) {$arguments+='--unit-test'}
if ($Release -and !$Export) {$arguments+='-r'}
if ($Export) {$arguments+=@('-e','-r')} else {$arguments+=@('-d',$Device)}
& $java @arguments
if ($LASTEXITCODE -ne 0) {throw "Build failed ($LASTEXITCODE)"}
