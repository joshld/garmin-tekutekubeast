param([string]$Device='enduro4',[string]$Jungle='monkey.jungle',[string]$Output='bin/v061-public.prg',[switch]$Tests,[switch]$Export,[switch]$Release,[switch]$Owner,[switch]$DeveloperBetaExport,[int]$Typecheck=0)
$ErrorActionPreference='Stop'
$project=Split-Path $PSScriptRoot -Parent
if($DeveloperBetaExport){
    if(!$PSBoundParameters.ContainsKey('Output')){$Output='bin/TekuTekuBeast-Dev-0.6.1.iq'}
    if($Tests -or $Jungle -ne 'monkey.jungle' -or (Split-Path $Output -Leaf) -ne 'TekuTekuBeast-Dev-0.6.1.iq'){throw 'Developer Beta export requires the original manifest, no QA tests, and TekuTekuBeast-Dev-0.6.1.iq'}
    [xml]$betaManifest=Get-Content "$project/manifest.xml" -Raw
    $identities=Get-Content "$project/config/build-identities.json" -Raw | ConvertFrom-Json
    if($betaManifest.SelectSingleNode('//*[local-name()="application"]').id -ne $identities.developerBeta -or $identities.developerBeta -eq $identities.public){throw 'Invalid Developer Beta identity'}
    $Owner=$true;$Export=$true
    Write-Output "PRIVATE_DEVELOPER_BETA_EXPORT: $($identities.developerBeta); Developer Mode included"
}
if($Export -and $Owner -and !$DeveloperBetaExport){throw 'Public exports cannot include Developer Mode. Use -DeveloperBetaExport explicitly for the private Beta IQ.'}
if($Export -and ($Tests -or $Jungle -ne 'monkey.jungle')){throw 'Store exports must use the production manifest and cannot include QA tests.'}
if($Export -and !$DeveloperBetaExport -and (Split-Path $Output -Leaf) -ne 'TekuTekuBeast-Public-0.6.1.iq'){throw 'Use the distinct public package filename: TekuTekuBeast-Public-0.6.1.iq'}
$sdk=(Get-Content -LiteralPath "$env:APPDATA\Garmin\ConnectIQ\current-sdk.cfg" -Raw).Trim()
$java=(Get-Command java -ErrorAction SilentlyContinue).Source
if (!$java) {$java='C:\Program Files\Eclipse Adoptium\jdk-17.0.20.101-hotspot\bin\java.exe'}
$temp=Join-Path $project 'bin/build-temp'
New-Item -ItemType Directory -Force -Path $temp | Out-Null
$battlePython="$env:USERPROFILE\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe"
& $battlePython "$PSScriptRoot/prepare_battle_data.py" --check
if($LASTEXITCODE -ne 0){throw 'Portable battle data is out of sync; refusing to build'}
if($Tests){
    $python="$env:USERPROFILE\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe"
    & $python "$PSScriptRoot/prepare_rule_vectors.py"
    if($LASTEXITCODE -ne 0){throw 'Cannot prepare deterministic rule fixtures'}
}
if($Export -or !(Test-Path "$project/bin/scenery-barrel/SceneryPack.barrel") -or (Select-String -LiteralPath "$project/monkey.jungle" -SimpleMatch "$Device.sourcePath = bin/legacy-source" -Quiet)){
    $python="$env:USERPROFILE\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe"
    if(!(Test-Path $python)){$python=(Get-Command python -ErrorAction Stop).Source}
    & $python "$PSScriptRoot/prepare_legacy_resources.py"
    & $python "$PSScriptRoot/prepare_legacy_sources.py"
    if($LASTEXITCODE -ne 0){throw 'Cannot prepare constrained-device scope variant'}
    & $java '-Dfile.encoding=UTF-8' '-cp' "$sdk/bin/monkeybrains.jar" com.garmin.monkeybrains.MonkeyBarrelEntry -f "$project/bin/scenery-barrel/monkey.jungle" -o "$project/bin/scenery-barrel/SceneryPack.barrel" -l 0
    if($LASTEXITCODE -ne 0){throw 'Cannot prepare legacy scenery resource namespace'}
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
