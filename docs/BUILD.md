# Build, test and release packaging

Current workflow for the fixed v0.5.2 identities. Run from the repository root.
[Validation](VALIDATION.md) records executed checks; commands below are
instructions, not claims of new runs.

## Environment and safe inputs

Use Connect IQ SDK 9.2.x, Enduro 4 device support and Java 17.
The Windows wrapper reads Garmin SDK Manager's selected SDK.
[Garmin SDK Manager](https://developer.garmin.com/connect-iq/sdk/) and the
Monkey C extension provide installation/verification. Keep the existing
`developer_key` private, backed up locally and out of Git; never replace it
to update an existing app.

Use `scripts/build.ps1`: it prepares constrained-profile catalogs/scopes and
fail-closed public exclusions. Direct `monkey.jungle` compilation, including
`scripts/build.sh` on Linux/macOS, is owner input, **not public Store input**.
Windows SDK builds are validated; equivalent non-Windows public packaging is
not claimed.

For owner-only Linux/macOS development with `monkeyc` on PATH:

```bash
CIQ_DEVELOPER_KEY="/path/to/existing/developer_key.der" ./scripts/build.sh
# Start connectiq, then run the result:
monkeydo build/TekuTekuBeast.prg enduro4
```

Do not use this direct owner-source route for a public Store export or replace
the existing key merely because a setup message suggests generating one.

| Build | UUID | DEV / saves |
| --- | --- | --- |
| Public, default | `53C660EBC4454BCF9292E5591EEC18DA` | Compiled out; separate new pet |
| Developer Beta, `-Owner` | `54A4F9D3B6584CA4B01C232D20438E5B` | Retained; original pet |

Both use the original signing identity pinned in `config/build-identities.json`.
QA harnesses have isolated IDs; never publish them. Update the matching app
without uninstalling or clearing Storage. No automatic cross-app save transfer.

## Everyday Enduro 4 development

Start the Garmin simulator GUI in Normal launch mode first.

```powershell
# Public input, signed foreground program
& scripts/build.ps1 -Device enduro4
& scripts/run-simulator.ps1 -Device enduro4
# Personal release-mode program with DEV
& scripts/build.ps1 -Owner -Release -Device enduro4 -Output bin/owner-enduro4.prg
# Owner rules/migration/DEV/transaction regressions
& scripts/unit-matrix.ps1 -Devices enduro4 -EvidencePrefix focused
# Public-input tests: omit -Owner
& scripts/build.ps1 -Tests -Device enduro4 -Jungle tests/release/monkey.jungle -Output bin/matrix-public-enduro4-tests.prg
& scripts/run-simulator.ps1 -Tests -Device enduro4 -Program bin/matrix-public-enduro4-tests.prg
```

“Matrix” in a script name does not authorize an all-device run. Default to
Enduro 4; add a representative only for demonstrated platform risk. Ask before
any full cross-device suite. Reuse passing evidence with unchanged inputs.
Documentation-only work needs no SDK run. Outputs/logs are ignored under `bin/`.

Default gradual typechecking is level 0 plus actual compilation/linking and
native tests. Level 1 did not complete in the prior focused compatibility window;
it is not a pass.

## Targeted visual, background and Glance checks

Run only when relevant to the changed boundary, not as an automatic full matrix.

```powershell
& scripts/device-matrix.ps1 -Devices enduro4 -Jungle tests/compatibility/monkey.jungle -EvidencePrefix focused
# Background stress fixture: isolated QA identity, not the real pet
& scripts/build.ps1 -Owner -Device enduro4 -Jungle tests/background/monkey.jungle -Output bin/background-enduro4.prg
& scripts/run-simulator.ps1 -Device enduro4 -Program bin/background-enduro4.prg
# Set Settings > Glance Launch Mode > Glance first; restore Normal afterwards
& scripts/glance-matrix.ps1 -Devices enduro4 -EvidencePrefix focused
```

Background QA populates three paused games, 123456 fixture XP and inventory.
Trigger Steps Progress / Sleep / Wake via Simulation > Background Events;
inspect memory/writes and reopen persistence. Fixture XP is not real activity.
Never clear production Storage. Native Glance checks must use its restricted VM,
not a full-app budget.

For Issue #21 only, build `tests/lighting/monkey.jungle` with `-Owner -Device
enduro4` to a separate QA `.prg`. Its 70-scene audit uses the isolated matrix ID
and RAM saves. After PASS, tap previews/toggles lights, UP/DOWN changes themes
and BACK changes sky phase; stop the QA VM to flush its runner log. These are
fixture controls, not altered production button mappings.

For Issue #17, build `tests/sleep/monkey.jungle` with `-Owner -Device enduro4`
to a separate QA `.prg`. The RAM-only audit checks 62 sleep/wake/grumpy sprite,
menu, notice, game and Care scenes. After PASS, tap once for a 20-minute nap
scenario; subsequent inputs use the normal production Actions/Wake Up controls.
Stop the isolated QA VM to flush its layout/memory log. This does not touch the
real pet or Store packages.

For Issue #20, `tests/battle/monkey.jungle` uses the same isolated QA identity and
RAM saves. Its Enduro 4 audit covers all named-move grids, effects, outcomes and
sleep/motion states and identical-fighter sequential feedback. It exits after its
report; SELECT during the audit skips to production controls with identical
Nimble fighters and RAM-only encounters (`autoExit=false` retains the report).
Stop the QA VM to flush interactive counters;
do not clear Storage. Native unit tests include deterministic battles and the
separate encounter/claim document.

For manual stage-by-stage battle playtesting, build
`tests/battle-playtest/monkey.jungle` with `-Owner -Device enduro4` to a separate
QA program. UP/DOWN selects Pip, Nimble, Adult Grove, Champion Ember or Legendary
Tide/Wisp; SELECT opens the production battle view/input. BACK returns to the
chooser. Continue Last resumes after a VM restart. Pet fixtures stay in RAM;
only `qa.fixture` / `qa.battle.0` through `.5` persist under the isolated matrix
UUID, never either real app. The harness supplies encounters for playtesting;
native tests, not this fixture supply, verify genuine discovery limits.

`tests/runtime/monkey.jungle` is the bounded, RAM-only resource audit. Build with
`-Owner -Device enduro4` to an ignored `bin/matrix-resource*.prg`, use Normal
launch mode, then run it to completion. It samples five production renderers,
counts deep-copy roots/containers and save writes, and advances idle-game
callbacks without starting their timers. Heap samples include QA overhead and
are lower bounds, not allocator-wide peaks; elapsed times are coarse SDK-host
measurements. Use the SDK Active Memory report for compiled code/data and VM
peak/object counters. Never publish this isolated matrix-identity harness.

## Static checks and fixtures

```powershell
python scripts/check_project.py
python scripts/prepare_rule_vectors.py --check
python scripts/prepare_battle_data.py --check
```

Structural preflight (also used by GitHub Actions) is not compilation or
simulator evidence. Native `-Tests` builds refresh JSON-derived test literals.
All Windows builds fail closed if `data/battle-v1.json` differs from generated
`BeastBattleData.mc`; after an intentional data edit run
`python scripts/prepare_battle_data.py` and review the data/native diff together.
See [rule contracts](ARCHITECTURE.md) and
[fixture format](../tests/core-vectors/README.md). For artwork changes only,
`scripts/verify_v051_art.py` and `scripts/prepare_v051_world.py` retain existing
build-time checks/preparation; never generate artwork on the watch.

## Public versus private Store packages

Current guards pin version/filenames to 0.5.2. These commands replace outputs:
preserve original artifact hashes/evidence before rebuilding. Issue #19 did not
re-export or replace the signed v0.5.2 IQs.

```powershell
# Public .iq: all advertised hardware parts; DEV excluded
& scripts/build.ps1 -Export -Release -Output bin/TekuTekuBeast-Public-0.5.2.iq
# Owner-requested PRIVATE Beta .iq: original UUID; DEV included
& scripts/build.ps1 -DeveloperBetaExport
```

`-Export -Owner` is rejected. The explicit private exception rejects QA input
and the public filename; it produces `bin/TekuTekuBeast-Dev-0.5.2.iq`.
Never attach that binary to a published public GitHub release or public Garmin
listing. Any private draft download must remain restricted to maintainers.

Export every advertised hardware part, verify UUID/version/key/SDK signatures,
coverage, public symbol exclusion and retained personal DEV, then run targeted
risk-based regressions. Exporting all parts is not a simulator matrix.

`scripts/verify_public_identity_release.ps1` and
`scripts/verify_developer_beta_release.ps1` check the recorded v0.5.2 artifacts
and representative-program matches, including pinned original hashes; they are
not generic verifiers for changed source. Exact paths/hashes and executed export
checks remain in the [public record](releases/v0.5.2/PUBLIC_RELEASE_0_5_2.md)
and [private record](releases/v0.5.2/DEVELOPER_BETA_0_5_2.md).
Never relabel these old checks as fresh source validation.

## Installation and publication

Public IQ belongs to the separate public listing; private Developer Beta IQ
updates the existing Beta listing. The historical ambiguous
`TekuTekuBeast-0.5.2.iq` is not for a new public app. Enter `0.5.2` in the Store
version field; the in-app string is `0.5.2 beta`.

The owner handles uploads through the
[developer dashboard](https://apps-developer.garmin.com/developer/dashboard).
No publication without explicit approval. Device-specific `.prg` files can be
USB sideloaded into `GARMIN/APPS`; they are not Store uploads or iPhone apps.
Avoid duplicate Store/USB installs or uninstalling to switch when progress exists.
See [Fenix 6S Pro installation](INSTALL_FENIX_6S_PRO.md) and
[physical acceptance](WATCH_ACCEPTANCE.md). Simulator checks do not prove
real-watch saves, Glance behavior, system tones, sleep callbacks or battery use.
