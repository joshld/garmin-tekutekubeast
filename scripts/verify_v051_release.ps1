param([string]$Package='bin/TekuTekuBeast-0.5.1.iq',
      [string]$Release='bin/TekuTekuBeast-0.5.1-release.prg')
$ErrorActionPreference='Stop'
$project=Split-Path $PSScriptRoot -Parent
$packagePath=(Resolve-Path -LiteralPath (Join-Path $project $Package)).Path
$releasePath=(Resolve-Path -LiteralPath (Join-Path $project $Release)).Path
$destination=Join-Path $project 'bin/export-v051-final'
New-Item -ItemType Directory -Force -Path $destination | Out-Null
# The SDK export is 7-Zip, not ZIP. Extract only the known public metadata and
# Enduro 4 program, never a private key or an arbitrary archive path.
$program='006-B5169-00/TekuTekuBeast-0.5.1.prg'
& tar -xf $packagePath -C $destination manifest.xml dev_key.pub $program
if($LASTEXITCODE -ne 0){throw 'Cannot extract signed SDK export'}
[xml]$manifest=Get-Content -LiteralPath (Join-Path $destination 'manifest.xml') -Raw
$app=$manifest.SelectSingleNode('//*[local-name()="application"]')
if($app.id -ne '54A4F9D3B6584CA4B01C232D20438E5B' -or $app.entry -ne 'TekuTekuBeastApp'){
    throw 'Production application identity mismatch'
}
$parts=@($manifest.SelectNodes('//*[local-name()="product"]'))
if($parts.Count -ne 19){throw "Unexpected hardware-part count: $($parts.Count)"}
$keyHash=(Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $destination 'dev_key.pub')).Hash
if($keyHash -ne '276489F20EC9F9605CADE733D7F5D60FB04E8696C5E50FF8E431F873825FCA7C'){
    throw 'Signing public key differs from retained v0.4/v0.5 exports'
}
$exportedPath=Join-Path $destination $program
$releaseHash=(Get-FileHash -Algorithm SHA256 -LiteralPath $releasePath).Hash
$exportedHash=(Get-FileHash -Algorithm SHA256 -LiteralPath $exportedPath).Hash
if($releaseHash -ne $exportedHash){throw 'Enduro 4 exported program differs from standalone release'}
Write-Output "ARTIFACT_ID: $($app.id)"
Write-Output "ARTIFACT_PARTS: $($parts.Count)"
Write-Output "ARTIFACT_PUBLIC_KEY: $keyHash"
foreach($file in @($packagePath,$releasePath,$exportedPath)){
    $item=Get-Item -LiteralPath $file
    Write-Output "ARTIFACT_SHA256: $((Get-FileHash -Algorithm SHA256 -LiteralPath $file).Hash) bytes=$($item.Length) $file"
}
Write-Output 'ARTIFACT_CHECK: PASS; exported Enduro 4 program still requires actual simulator execution'
