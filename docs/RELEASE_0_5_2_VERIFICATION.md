# v0.5.2 public beta release verification

Release preparation for issues #9 and #18, 17 October 2026. No Garmin upload,
publication, listing conversion or physical-watch installation was performed.
The v0.4/v0.5/v0.5.1 verification records are retained unchanged.

## Scope and identity

47 advertised SDK profiles: existing 13 plus 34 accepted compatibility
candidates. Exact IDs, measured simulator limits and exclusions are in
[sdk-results.csv](compatibility/sdk-results.csv) and the production manifest.
Five failed profiles are excluded; three Venu 2 variants are held pending
background/input acceptance. No new models were investigated during release
completion and no complete simulator matrix was rerun.

Production application ID: `54A4F9D3B6584CA4B01C232D20438E5B`.
Signing public-key SHA256:
`276489F20EC9F9605CADE733D7F5D60FB04E8696C5E50FF8E431F873825FCA7C`.
The existing private key is reused and remains ignored by Git.

## Public versus personal build

`scripts/build.ps1` defaults to public input. The fail-closed public source
generator physically removes owner menus/handlers, developer mutation methods,
accelerated clock, forced stage/family overrides, sky previews and DEV badges
before Garmin compilation. It rejects unexpected input files and surviving
owner-tool tokens. Public tests use the same transformed production source.
Canonical owner source and all existing uncommitted compatibility work are
preserved. Test fixtures and QA identities are outside Store compilation input.

`-Owner` explicitly retains the personal in-app Developer Mode. `-Export -Owner`
was tested and rejected. Store export also rejects unit tests/custom QA jungles.
Use the documented PowerShell wrapper; direct IDE/root-jungle builds are owner
builds and must not be uploaded as public releases.

Both programs use the original ID/key and replace the same installation.
A public Store update removes DEV on the owner's watch. To regain it, install
the signed personal Enduro 4 `.prg` as an update without uninstalling/resetting.
There is no second ID, automatic migration or watch installation in this task.

## Executed focused release checks

| Check | Enduro 4 | Fenix 6S Pro |
| --- | --- | --- |
| Public unit tests | 4/4 pass | 4/4 pass |
| Public UI scenes | 57, zero truncations | 57, zero truncations |
| Sampled main heap | 102,536 / 781,976 bytes | 250,600 / 1,306,136 bytes |

The public tests verify owner methods are absent at runtime, correct Settings
indexing after removal, additive v0.4 migration, preservation of a current save,
step deduplication, 26-day growth catch-up, one-time evolution flag, unchanged
save suppression, compact Glance caching, interrupted-game recovery/claims,
single adventure charge, feeding/poop/cleaning and unchanged genuine XP.
Public UI scenes execute the production renderer across menus and stages.
The QA timer was clamped by the SDK; it is not a shipping animation change.

Personal/owner Enduro 4: all existing 33 native unit tests pass, including DEV
save isolation, advancement and existing gameplay/migration regressions.
Actual Monkey C SDK 9.2 and Java 17 are used, gradual typecheck level 0.
Optional level 1 did not complete in the earlier focused window and is not
reported as verified.

## Reused evidence

Runtime compatibility commits `70ec616` and `233edb5` have per-profile native
results in the CSV, originating from `compat-representatives`,
`compat-218-final` and `compat-new` logs. The owner implementation, resources,
SDK and dependencies tested there remain the same. Public exclusion only
removes owner functionality; new public regressions above cover that difference.
Representative coverage is 33 tests/983 scenes; other new passing profiles
have 33 tests/473 focused scenes. Existing profiles retain prior accepted
evidence; they were not all rerun for this release.

Native representative background/Glance evidence is recorded in
[COMPATIBILITY_EXPANSION.md](COMPATIBILITY_EXPANSION.md): Fenix 6S Pro tiny
cleanup delegate 10,960 / 28,576 bytes, Enduro 4 normal background 43,272 /
61,344 and compact Glance 33,304 / 61,344. Fenix 6S Pro simulator button input
played all three games and opened the normal app entry; captures are linked
there. These are simulator measurements, not physical-watch battery results.

## Upload and hardware limitations

Upload the final signed `.iq` as version **0.5.2**, described as beta. The final
artifact checks and hash are recorded below after export verification.
Garmin dashboard listing type/public visibility has not been inspected in this
task. A developer-only Beta App listing is distinct from a public beta; do not
create a different app ID or assume saved data transfers to a new listing.

Update existing installations; do not uninstall. Mum's standard Fenix 6S Pro
uses `fenix6spro`, with foreground activity/time catch-up and daily opening
recommended. Finite Garmin history can miss old steps after prolonged absence.
Older CIQ 3.x does not expose this watch-app's native Glance; use START/apps.
Newer supported watches retain Glance. No continuous GPS is added.

Physical acceptance remains: same-ID public/personal upgrade with real pet,
actual step/background and sleep/wake delivery, Garmin Glance launch/timeout,
Mum's controls/display, sound/haptics and battery. Keep #9/#18 open for those
checks and Garmin listing/publication work. See
[Mum's instructions](INSTALL_FENIX_6S_PRO.md) and [build commands](BUILD.md).

## Final signed artifacts

SDK export: **BUILD SUCCESSFUL**, all **72/72 hardware parts** for the **47**
advertised SDK profiles. Verification checked every advertised part in export
metadata, the original ID/entry/key, absent owner/QA representative symbols and
byte-identical exported versus standalone public Enduro 4/Fenix 6S Pro programs.
No final export execution on a physical watch is implied by those checks.

Store upload file (17,206,378 bytes):
`D:\working\garmin-tekutekubeast\bin\TekuTekuBeast-0.5.2.iq`

SHA256:
`90BB96CD6199795A6D55642E5710D814D8F6FAB166ACC20C8A164FEB00288889`

| Signed program under `bin/` | SHA256 |
| --- | --- |
| `TekuTekuBeast-0.5.2-enduro4.prg` (public) | `DF52CBA7ED2C6BFCD112DAA8369171A2D4092B16E2ED4B65DFD8CF30F498D85B` |
| `TekuTekuBeast-0.5.2-fenix6spro.prg` (public, Mum) | `71B9D98E64F40DD2C25B6272FD1B0FE85718A40DB09878658314756704C9F659` |
| `TekuTekuBeast-0.5.2-owner-enduro4.prg` (personal DEV) | `B15A82B0585B7B2007082FA2BCE0C4D5806CE96030978F8A017CE5DFCFDAB908` |

Raw evidence: `bin/release-public-export.log`,
`bin/release-package-verification.log`, `bin/release-public-*-tests.log`,
`bin/release-public-*-layout.log`, `bin/release-owner-unit-run.log` and the
signed-build logs. SDK outputs stay ignored. An earlier DEV-containing IQ is
retained locally as `bin/DO-NOT-UPLOAD-0.5.2-DEV-previous.iq`; it is not the release.
