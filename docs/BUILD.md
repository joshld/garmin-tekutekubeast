# Build and simulator instructions

This is a native Garmin Connect IQ **watch app**, primarily tested on **Enduro 4**.
See [v0.5.1 validation](V0_5_1_VALIDATION.md) for current work and accepted profiles;
the [v0.4 device matrix](DEVICE_MATRIX.md) is historical evidence. Steps
come from `Toybox.ActivityMonitor` and background step events; no phone or FIT
import is needed. Passive and care growth are separate from genuine watch XP.

## Development environment

1. Download the official [Garmin Connect IQ SDK Manager](https://developer.garmin.com/connect-iq/sdk/) for Windows/Linux/macOS; read and accept Garmin's own SDK terms during setup.
2. Install Connect IQ SDK **9.2.x** and **Enduro 4** device support, including simulator files/fonts.
3. Install the official **Monkey C** VS Code extension. Run `Monkey C: Verify Installation`.
4. For an existing installation, retain its existing private signing key. Do not
   generate a replacement to update the published app. For a brand-new project,
   the Monkey C extension can generate a key. Keep it private, backed up and
   out of version control; local `developer_key` is ignored.

## Windows v0.5.1 build and regression

The checked-in PowerShell scripts use the SDK selected by Garmin's SDK Manager
and Java 17. Build outputs and test logs are ignored under `bin/`.

```powershell
./scripts/build.ps1
./scripts/run-simulator.ps1
./scripts/device-matrix.ps1 -EvidencePrefix v051
# Set simulator Settings > Glance Launch Mode > Glance before this command:
./scripts/glance-matrix.ps1 -EvidencePrefix v051
# Restore Normal launch mode for normal gameplay and unit tests.
./scripts/build.ps1 -Release -Output bin/TekuTekuBeast-0.5.1-release.prg
./scripts/build.ps1 -Export -Typecheck 0 -Output bin/TekuTekuBeast-0.5.1.iq
```

Internal unit/layout/Glance harnesses have isolated QA IDs and in-memory saves.
Never upload those QA binaries. The production app contains the actual
Developer Mode; no second user-facing app is required. See
[v0.5.1 validation](V0_5_1_VALIDATION.md) for executed tests and hardware limitations.

The normal build explicitly uses gradual type checking (`-Typecheck 1`). The
large all-profile runtime matrix/export may use `-Typecheck 0` to avoid repeating
the same slow common-code inference per hardware part; it still uses Garmin's
actual compiler/linker and executes every profile's tests/rendering. A separate
gradual-checked production build is required in the release record. Historical
v0.4/v0.5 evidence is not overwritten or renamed to the new version.

Landscape assets are prepared at build time, never on the watch:

```powershell
python scripts/verify_v051_art.py
python scripts/prepare_v051_world.py
python scripts/check_project.py
```

Only `TekuTekuBeast-0.5.1.iq` from the production manifest is a Store upload.
Do not upload SDK QA programs or the `.prg`. Update the existing beta at the
[developer dashboard](https://apps-developer.garmin.com/developer/dashboard),
not a new app listing. Owner approval is required before submission; do not
uninstall the existing watch installation.

The native background stress fixture has a separate SDK-only application ID:

```powershell
./scripts/build.ps1 -Device enduro4 -Jungle tests/background/monkey.jungle -Output bin/background-enduro4.prg
./scripts/run-simulator.ps1 -Device enduro4 -Program bin/background-enduro4.prg
```

It creates a populated QA save with three paused sessions and 123,456 fixture XP,
then uses the unchanged production service. Trigger Steps Progress, Sleep and
Wake through the SDK Background Events dialog, inspect `BACKGROUND_MEMORY`,
then reopen the fixture and check unchanged XP, three sessions and inventory.
These are test fixture values, not genuine credited activity. Never install or
upload the QA program as the real game. Normal and Glance modes have different
VM budgets; the Glance matrix rejects a full-app budget masquerading as a pass.

## Command-line build

On Linux/macOS, with `monkeyc` available on the PATH:

```bash
CIQ_DEVELOPER_KEY="$HOME/.keys/garmin/developer_key.der" ./scripts/build.sh
```

The compiled result (only if this succeeds) is `build/TekuTekuBeast.prg`.

Manual equivalent:

```bash
monkeyc -f monkey.jungle -d enduro4 -w -o build/TekuTekuBeast.prg -y "$CIQ_DEVELOPER_KEY"
```

## Running in Garmin simulator

Start Garmin's `connectiq` simulator GUI, then:

```bash
monkeydo build/TekuTekuBeast.prg enduro4
```

On the Enduro 4 simulation target, use the simulator menus to set/advance step data and **Simulation → Background Events** to trigger a steps event. Verify these cases:

- First launch saves today's current step count as the initial baseline.
- An additional 1,000 watch-recorded steps increases XP by 1,000 after foreground sync or background step event.
- Reopening the app and triggering the same step event never adds duplicate XP.
- Daily rollover doesn't treat yesterday's watermark as today's steps.
- Natural hatch around 24h, accelerated hatch never before 8h; 2,000 steps alone
  must not instantly hatch a new egg. Existing earned stages do not regress.
- Zero-step meals and earned snacks, delayed poop and cleaning, daily budgets,
  clock rollback and restart persistence.
- Legendary around 25 passive days / 21 active minimum, all zero-step family
  routes and mastery every 25,000 growth (not fabricated watch steps).
- DEV accelerated scenarios discard without losing genuine steps from testing.

You can also test the watch UI with the Enduro 4 five-button navigation.

## Real watch installation

For Store updates use the production signed `.iq` export and update the same
existing beta listing. Do not uninstall the watch app first: uninstalling may
remove Garmin Storage. The user has confirmed Developer Mode is visible and the
Glance now appears on their physical Enduro 4. Full save preservation and Glance
launch/session checks remain open; see [WATCH_ACCEPTANCE.md](WATCH_ACCEPTANCE.md).
A PRG can be sideloaded via `GARMIN/APPS` where Garmin
exposes that folder; avoid duplicate Store/sideload installations.

## Automated checks

`python3 scripts/check_project.py` is a **static structural check only**. The GitHub Actions workflow runs this preflight on every push/PR. It **does not compile Monkey C or run a Garmin simulator**: a real Connect IQ SDK + Enduro 4 device definition and developer key are required. Never commit personal Garmin credentials or developer signing keys.

For Connect IQ specifics, see [Garmin SDK Getting Started](https://developer.garmin.com/connect-iq/connect-iq-basics/getting-started/) and [Background Services](https://developer.garmin.com/connect-iq/articles/core-topics/Backgrounding.html).
