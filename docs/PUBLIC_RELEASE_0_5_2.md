# v0.5.2: separate public application

Owner-authorized identity separation after the original same-UUID candidate.
The earlier `TekuTekuBeast-0.5.2.iq` uses the Developer Beta UUID and must not be
used to create the separate public listing. Its historical hash/evidence remain
in `RELEASE_0_5_2_VERIFICATION.md`.

## Fixed identities

| Build | Application UUID | Developer Mode | Save |
| --- | --- | --- | --- |
| Existing Developer Beta / `-Owner` | `54A4F9D3B6584CA4B01C232D20438E5B` | Retained | Current original pet |
| Public / default build | `53C660EBC4454BCF9292E5591EEC18DA` | Removed before compilation | Separate new pet |

Both use the existing signing key. Public-key SHA256:
`276489F20EC9F9605CADE733D7F5D60FB04E8696C5E50FF8E431F873825FCA7C`.
The root `manifest.xml` is unchanged. `config/build-identities.json` pins both
UUIDs; public preparation clones the root manifest and changes only its UUID.
Existing QA manifests keep their isolated identities. There is no data-copy,
cross-app storage, migration, uninstall, watch installation or reset operation.

The apps have different installation/storage identities and can coexist.
Public starts a new pet; it does not adopt the Developer Beta's current beast.
Keep the Developer Beta installed to retain its pet and DEV tools. Both currently
use the same display name, so check listing identity and the Developer setting
when distinguishing them. Physical Enduro 4 dual-install acceptance has not
been performed by Codex.

[Garmin manifest UUID documentation](https://developer.garmin.com/connect-iq/articles/core-topics/Manifest_and_Permissions.html)
defines the application identity; [Garmin persistence documentation](https://developer.garmin.com/connect-iq/articles/core-topics/Persisting_Data.html)
states storage is available only to its application. Separation is an inference
from that platform contract and verified distinct manifests, not a claim of
physical-watch testing.

## Public code and compatibility

Public compilation still physically removes owner menus/handlers, accelerated
time, mutation methods, forced stage/family overrides, sky previews and DEV
badges. Existing runtime absence tests and signed-symbol checks apply unchanged.
The personal signed Enduro 4 program retains `enableDev` and `setSpeed` and its
SHA256 remains `B15A82B0585B7B2007082FA2BCE0C4D5806CE96030978F8A017CE5DFCFDAB908`.

The exact validated **47 SDK profiles / 72 hardware parts** remain, including
standard `fenix6spro`. No gameplay/source/resources or supported product entries
changed. Prior native compatibility tests, focused public Enduro 4/Fenix 6S Pro
tests and personal Enduro 4 tests are reused; no device matrix was rerun.

## Build and verify

```powershell
& scripts/build.ps1 -Release -Device enduro4 -Output bin/TekuTekuBeast-Public-0.5.2-enduro4.prg
& scripts/build.ps1 -Release -Device fenix6spro -Output bin/TekuTekuBeast-Public-0.5.2-fenix6spro.prg
& scripts/build.ps1 -Export -Release -Output bin/TekuTekuBeast-Public-0.5.2.iq
& scripts/verify_public_identity_release.ps1
```

Store export rejects the ambiguous old filename, owner mode and QA manifests.
The public export recompiles every advertised hardware part with its new UUID;
this is package production, not a simulator matrix. SDK signing uses the original
private key. Verification checks distinct UUIDs, unchanged owner identity/key,
all advertised parts and SDK signatures, matching standalone/exported programs,
public symbol exclusion and retained personal tools.

The in-app version and filename are **0.5.2 beta**. Garmin's exported application
manifest has no semantic release-version attribute; enter **0.5.2** in the Store
upload form. SDK package/signature checks do not guarantee Store acceptance.

## New public listing

Upload only `TekuTekuBeast-Public-0.5.2.iq` as a new regular public application,
with beta status explained in its description rather than selecting a
developer-only Beta App listing. Keep the existing Developer Beta listing and
installation. Do not upload this new-UUID package as an update of the old listing.
No Garmin upload/publication was performed. Native Glance, sleep/background
delivery, dual-install behavior, sound/haptics and battery still need hardware
acceptance as already documented. Older Fenix profiles retain foreground catch-up
and their native-watch-app Glance limitation.

## Verified final artifact

`D:\working\garmin-tekutekubeast\bin\TekuTekuBeast-Public-0.5.2.iq`

17,197,074 bytes. SHA256:
`A1555CE4F1532389C7A7C92356586C761525F76808A36EB5C8E9539CC85832DE`.

`bin/public-identity-export.log`: **BUILD SUCCESSFUL**, 72/72 parts.
`bin/public-identity-verification.log`: **PASS**. Public UUID matches the fixed
configuration; Developer Beta UUID is unchanged. The original signing-key
fingerprint matches; both SDK signatures are present on all 72 hardware parts.
Exported public Enduro 4 and Fenix 6S Pro programs are byte-identical to their
standalone signed builds and contain the compiled `Version 0.5.2 beta` string.
Their symbols exclude DEV mutation/time methods and QA fixtures. The personal
binary retains DEV and its previous hash. Root manifest and gameplay/save source
have no changes. These are SDK/build/identity checks, not physical dual-install
or Garmin Store acceptance. No full simulator matrix was run.

GitHub downloads use a separate `v0.5.2-public` tag so the earlier `v0.5.2`
tag/assets can retain historical identity and evidence without rewriting tags.
