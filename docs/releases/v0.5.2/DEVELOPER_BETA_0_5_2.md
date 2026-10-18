# Private Developer Beta v0.5.2 IQ
> Version-specific release evidence, not everyday build instructions. Start with
> [current guides](../../../README.md#documentation).

Requested by the owner after public/developer identity separation. The private
package updates the existing Developer Beta listing, with Developer Mode included.
It is not the new public application. No Garmin upload is performed by Codex.

- File: `D:\working\garmin-tekutekubeast\bin\TekuTekuBeast-Dev-0.5.2.iq`
- Developer Beta UUID: `54A4F9D3B6584CA4B01C232D20438E5B` (unchanged).
- Public UUID: `53C660EBC4454BCF9292E5591EEC18DA` (unchanged, not used here).
- Original signing key retained; public-key SHA256:
  `276489F20EC9F9605CADE733D7F5D60FB04E8696C5E50FF8E431F873825FCA7C`.
- In-app and Store-form version: **0.5.2 beta** / **0.5.2**.
- The same validated 47 profiles / 72 hardware parts are retained.

```powershell
& scripts/build.ps1 -DeveloperBetaExport
& scripts/verify_developer_beta_release.ps1
```

Default `-Export` still produces public-only input and cannot include DEV.
`-Export -Owner` remains rejected. The explicit private switch forces owner
input and rejects QA manifests/tests and the public filename. Root manifest,
gameplay, saving, public UUID/package and the original personal Enduro 4 program
are unchanged. Existing owner 33-test and compatibility evidence is reused;
no simulator matrix or physical-watch test is rerun for this packaging change.

Keep the existing Developer Beta installed. Upload this IQ as an update of that
listing, never as an update of the separate public app. Current real saves are
not embedded in the IQ and no save is reset, moved or copied by the build.
The original pet remains in the Beta app's storage when it is updated normally.

The developer binary must not be attached to a published public GitHub release.
If a phone download is provided via a GitHub draft, access must remain restricted
to repository maintainers and anonymous access must be checked as unavailable.

## Executed export verification

SDK export **BUILD SUCCESSFUL**, 72/72 parts. Verification **PASS** in
`bin/developer-beta-verification.log`; the exported Enduro 4 program matches the
original signed personal program exactly, including developer menus, clock
acceleration and mutation/scenario methods. Original UUID, key fingerprint,
compiled version and every advertised signed hardware part were checked.
Public/owner rejection guards, private filename guard and private QA exclusion
guard passed. The public IQ hash remains
`A1555CE4F1532389C7A7C92356586C761525F76808A36EB5C8E9539CC85832DE`.

Developer IQ: **17,438,315 bytes**, SHA256:
`0C02C43710E40042AE9904863616A113F03522E52B578842433E737BF10CD442`.

No gameplay, identity configuration or root manifest was changed. This is export
verification with reused native test evidence, not a new physical-watch test.
