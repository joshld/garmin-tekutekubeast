param([string]$Package='bin/TekuTekuBeast-Public-0.5.2.iq')
$ErrorActionPreference='Stop'
$project=Split-Path $PSScriptRoot -Parent
$identities=Get-Content "$project/config/build-identities.json" -Raw | ConvertFrom-Json
[xml]$developerManifest=Get-Content "$project/manifest.xml" -Raw
if($developerManifest.SelectSingleNode('//*[local-name()="application"]').id -ne $identities.developerBeta){throw 'Developer Beta identity changed'}
$path=(Resolve-Path -LiteralPath (Join-Path $project $Package)).Path
$destination=Join-Path $project 'bin/export-v052-public-separate'
New-Item -ItemType Directory -Force -Path $destination | Out-Null
$base='TekuTekuBeast-Public-0.5.2'
$programs=@("006-B3288-00/$base.prg","006-B5169-00/$base.prg")
& tar -xf $path -C $destination manifest.xml dev_key.pub @programs
if($LASTEXITCODE -ne 0){throw 'Cannot extract public metadata and representative programs'}
[xml]$manifest=Get-Content "$destination/manifest.xml" -Raw
$app=$manifest.SelectSingleNode('//*[local-name()="application"]')
if($app.id -ne $identities.public -or $app.id -eq $identities.developerBeta -or $app.entry -ne 'TekuTekuBeastApp'){throw 'Wrong public identity'}
$key=(Get-FileHash "$destination/dev_key.pub" -Algorithm SHA256).Hash
if($key -ne $identities.signingPublicKeySha256){throw 'Signing identity changed'}
$parts=@($manifest.SelectNodes('//*[local-name()="product"]'))
foreach($part in $parts){if(!$part.sig -or !$part.sig2 -or !$part.sigFormat){throw 'Unsigned hardware part in public export'}}
$products=@($developerManifest.SelectNodes('//*[local-name()="product"]'))
if($products.Count -ne 47 -or $parts.Count -ne 72){throw 'Validated coverage changed'}
if(!($products | Where-Object id -eq 'fenix6spro')){throw 'Mum profile missing'}
foreach($product in $products){
    $device=Get-Content "$env:APPDATA/Garmin/ConnectIQ/Devices/$($product.id)/compiler.json" -Raw | ConvertFrom-Json
    foreach($part in $device.partNumbers){if(!($parts | Where-Object partNumber -eq $part.number)){throw "Missing hardware part: $($part.number)"}}
}
foreach($pair in @(@('fenix6spro',$programs[0]),@('enduro4',$programs[1]))){
    $standalone="$project/bin/$base-$($pair[0]).prg"
    if((Get-FileHash $standalone -Algorithm SHA256).Hash -ne (Get-FileHash (Join-Path $destination $pair[1]) -Algorithm SHA256).Hash){throw "Export/program mismatch: $($pair[0])"}
    $symbols=Get-Content "$standalone.debug.xml" -Raw
    if(!(Select-String -LiteralPath $standalone -SimpleMatch "Version $($identities.version) beta" -Quiet)){throw 'Compiled in-app version missing'}
    if($symbols -match 'enableDev|devSet|simulateSleep|setSpeed|virtualNow|testNow|StateTests|PublicReleaseQA|ReleaseFixture'){throw 'Owner/QA controls present'}
    Write-Output "PUBLIC_PROGRAM_MATCH: $($pair[0])"
}
$ownerSymbols=Get-Content "$project/bin/TekuTekuBeast-0.5.2-owner-enduro4.prg.debug.xml" -Raw
if($ownerSymbols -notmatch 'enableDev' -or $ownerSymbols -notmatch 'setSpeed'){throw 'Personal Developer Mode unavailable'}
if((Get-FileHash "$project/bin/TekuTekuBeast-0.5.2-owner-enduro4.prg" -Algorithm SHA256).Hash -ne 'B15A82B0585B7B2007082FA2BCE0C4D5806CE96030978F8A017CE5DFCFDAB908'){throw 'Existing personal program changed'}
$publicView=Get-Content "$project/bin/public-build/source/TekuTekuBeastView.mc" -Raw
if(!$publicView.Contains('Version 0.5.2 beta')){throw 'Wrong in-app version'}
Write-Output "PUBLIC_UUID: $($app.id)"
Write-Output "DEVELOPER_BETA_UUID_UNCHANGED: $($identities.developerBeta)"
Write-Output "SIGNING_PUBLIC_KEY_SHA256: $key"
Write-Output 'SDK_SIGNATURES: both signatures present on every hardware part; original SDK signing key reused'
Write-Output "VERSION: $($identities.version) beta; enter this version in Garmin upload form"
Write-Output "COVERAGE: $($products.Count) profiles / $($parts.Count) parts; fenix6spro included"
Write-Output "PACKAGE: $path bytes=$((Get-Item $path).Length) SHA256=$((Get-FileHash $path -Algorithm SHA256).Hash)"
Write-Output 'PASS: separate public identity, compiled-out DEV, retained personal DEV, exact representative programs'
