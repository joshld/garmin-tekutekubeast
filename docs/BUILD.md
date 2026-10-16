# Build and simulator instructions

This is a native Garmin Connect IQ **watch app**, primarily tested on **Enduro 4**.
See [device matrix](DEVICE_MATRIX.md) for individually accepted profiles. Steps
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

## Windows v0.4 build and regression

The checked-in PowerShell scripts use the SDK selected by Garmin's SDK Manager
and Java 17. Build outputs and test logs are ignored under `bin/`.

```powershell
./scripts/build.ps1
./scripts/run-simulator.ps1
./scripts/device-matrix.ps1
# Set simulator Settings > Glance Launch Mode > Glance before this command:
./scripts/glance-matrix.ps1
# Restore Normal launch mode for normal gameplay and unit tests.
./scripts/build.ps1 -Export -Output bin/TekuTekuBeast-0.4.0.iq
```

Internal unit/layout/Glance harnesses have isolated QA IDs and in-memory saves.
Never upload those QA binaries. The production app contains the actual
Developer Mode; no second user-facing app is required. See
[validation](V0_4_VALIDATION.md) for executed tests and hardware limitations.

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
remove Garmin Storage. Physical-watch upgrade and Glances-list checks still
need to be performed. A PRG can be sideloaded via `GARMIN/APPS` where Garmin
exposes that folder; avoid duplicate Store/sideload installations.

## Automated checks

`python3 scripts/check_project.py` is a **static structural check only**. The GitHub Actions workflow runs this preflight on every push/PR. It **does not compile Monkey C or run a Garmin simulator**: a real Connect IQ SDK + Enduro 4 device definition and developer key are required. Never commit personal Garmin credentials or developer signing keys.

For Connect IQ specifics, see [Garmin SDK Getting Started](https://developer.garmin.com/connect-iq/connect-iq-basics/getting-started/) and [Background Services](https://developer.garmin.com/connect-iq/articles/core-topics/Backgrounding.html).
