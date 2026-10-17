param([string]$Package='bin/TekuTekuBeast-Dev-0.5.2.iq')
$ErrorActionPreference='Stop'
$project=Split-Path $PSScriptRoot -Parent
$identities=Get-Content "$project/config/build-identities.json" -Raw | ConvertFrom-Json
$path=(Resolve-Path -LiteralPath (Join-Path $project $Package)).Path
$destination=Join-Path $project 'bin/export-v052-developer-beta'
New-Item -ItemType Directory -Force -Path $destination | Out-Null
$program='006-B5169-00/TekuTekuBeast-Dev-0.5.2.prg'
& tar -xf $path -C $destination manifest.xml dev_key.pub $program
if($LASTEXITCODE -ne 0){throw 'Cannot extract Developer Beta metadata/program'}
[xml]$manifest=Get-Content "$destination/manifest.xml" -Raw
[xml]$source=Get-Content "$project/manifest.xml" -Raw
$app=$manifest.SelectSingleNode('//*[local-name()="application"]')
if($app.id -ne $identities.developerBeta -or $app.id -eq $identities.public -or $app.entry -ne 'TekuTekuBeastApp'){throw 'Wrong Developer Beta identity'}
$key=(Get-FileHash "$destination/dev_key.pub" -Algorithm SHA256).Hash
if($key -ne $identities.signingPublicKeySha256){throw 'Signing identity changed'}
$parts=@($manifest.SelectNodes('//*[local-name()="product"]'))
$products=@($source.SelectNodes('//*[local-name()="product"]'))
if($products.Count -ne 47 -or $parts.Count -ne 72){throw 'Validated coverage changed'}
foreach($part in $parts){if(!$part.sig -or !$part.sig2 -or !$part.sigFormat){throw 'Unsigned hardware part'}}
foreach($product in $products){
    $device=Get-Content "$env:APPDATA/Garmin/ConnectIQ/Devices/$($product.id)/compiler.json" -Raw | ConvertFrom-Json
    foreach($part in $device.partNumbers){if(!($parts | Where-Object partNumber -eq $part.number)){throw 'Advertised hardware part missing'}}
}
$original="$project/bin/TekuTekuBeast-0.5.2-owner-enduro4.prg"
$exported=Join-Path $destination $program
$expected='B15A82B0585B7B2007082FA2BCE0C4D5806CE96030978F8A017CE5DFCFDAB908'
if((Get-FileHash $original -Algorithm SHA256).Hash -ne $expected -or (Get-FileHash $exported -Algorithm SHA256).Hash -ne $expected){throw 'Developer export differs from validated personal program'}
$symbols=Get-Content "$original.debug.xml" -Raw
foreach($method in @('enableDev','devSet','setSpeed','simulateSleep','jump')){if($symbols -notmatch "symbol=`"$method`""){throw "Developer control missing: $method"}}
if(!(Select-String -LiteralPath $exported -SimpleMatch 'Version 0.5.2 beta' -Quiet)){throw 'Wrong compiled version'}
Write-Output "DEVELOPER_BETA_UUID: $($app.id)"
Write-Output "SIGNING_PUBLIC_KEY_SHA256: $key"
Write-Output 'DEV: menus, accelerated time, mutations and scenarios included; Enduro 4 program matches validated personal build exactly'
Write-Output "COVERAGE: $($products.Count) profiles / $($parts.Count) signed hardware parts"
Write-Output "PACKAGE: $path bytes=$((Get-Item $path).Length) SHA256=$((Get-FileHash $path -Algorithm SHA256).Hash)"
Write-Output 'PASS: private Developer Beta export; update existing Beta listing only; do not upload to public listing'
