param([string]$Package='bin/TekuTekuBeast-0.5.2.iq')
$ErrorActionPreference='Stop'
$project=Split-Path $PSScriptRoot -Parent
$packagePath=(Resolve-Path -LiteralPath (Join-Path $project $Package)).Path
$destination=Join-Path $project 'bin/export-v052'
New-Item -ItemType Directory -Force -Path $destination | Out-Null
$partPrograms=@('006-B3288-00/TekuTekuBeast-0.5.2.prg','006-B5169-00/TekuTekuBeast-0.5.2.prg')
& tar -xf $packagePath -C $destination manifest.xml dev_key.pub @partPrograms
if($LASTEXITCODE -ne 0){throw 'Cannot extract the known public metadata/programs'}
[xml]$manifest=Get-Content -LiteralPath "$destination/manifest.xml" -Raw
$app=$manifest.SelectSingleNode('//*[local-name()="application"]')
if($app.id -ne '54A4F9D3B6584CA4B01C232D20438E5B' -or $app.entry -ne 'TekuTekuBeastApp'){throw 'Production identity changed'}
$key=(Get-FileHash -LiteralPath "$destination/dev_key.pub" -Algorithm SHA256).Hash
if($key -ne '276489F20EC9F9605CADE733D7F5D60FB04E8696C5E50FF8E431F873825FCA7C'){throw 'Signing identity changed'}
$parts=@($manifest.SelectNodes('//*[local-name()="product"]'))
[xml]$sourceManifest=Get-Content -LiteralPath "$project/manifest.xml" -Raw
$products=@($sourceManifest.SelectNodes('//*[local-name()="product"]'))
foreach($device in @('fenix6spro','enduro4')){
    $symbols=Get-Content "$project/bin/TekuTekuBeast-0.5.2-$device.prg.debug.xml" -Raw
    if($symbols -match 'enableDev|devSet|simulateSleep|setSpeed|virtualNow|StateTests|PublicReleaseQA|ReleaseFixture'){
        throw "Public program contains owner/QA symbols: $device"
    }
}
foreach($product in $products){
    $device=Get-Content "$env:APPDATA/Garmin/ConnectIQ/Devices/$($product.id)/compiler.json" -Raw | ConvertFrom-Json
    foreach($part in $device.partNumbers){
        if(!($parts | Where-Object {$_.partNumber -eq $part.number})){throw "Export lacks $($product.id) part $($part.number)"}
    }
}
foreach($pair in @(@('fenix6spro',$partPrograms[0]),@('enduro4',$partPrograms[1]))){
    $standalone="$project/bin/TekuTekuBeast-0.5.2-$($pair[0]).prg"
    $exported=Join-Path $destination $pair[1]
    if((Get-FileHash $standalone -Algorithm SHA256).Hash -ne (Get-FileHash $exported -Algorithm SHA256).Hash){throw "Export/standalone mismatch: $($pair[0])"}
    Write-Output "PROGRAM_MATCH: $($pair[0]) $((Get-FileHash $exported -Algorithm SHA256).Hash) bytes=$((Get-Item $exported).Length)"
}
Write-Output "PACKAGE_SHA256: $((Get-FileHash $packagePath -Algorithm SHA256).Hash) bytes=$((Get-Item $packagePath).Length)"
Write-Output "RELEASE_IDENTITY: $($app.id) key=$key"
Write-Output "RELEASE_COVERAGE: $($products.Count) SDK profiles; $($parts.Count) hardware parts; every advertised part present"
Write-Output 'RELEASE_METADATA: PASS; native execution is recorded separately, never inferred from hashes'
Write-Output 'PUBLIC_SYMBOLS: PASS; owner mutation methods and QA entry/fixtures absent from signed representative programs'
