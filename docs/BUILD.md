# Build and simulator instructions

This is a native Garmin Connect IQ **watch app** targeting **Enduro 4**. Steps come from the watch's `Toybox.ActivityMonitor` and background steps event; no mobile companion or FIT import is needed.

## Development environment

1. Download the official [Garmin Connect IQ SDK Manager](https://developer.garmin.com/connect-iq/sdk/) for Windows/Linux/macOS; read and accept Garmin's own SDK terms during setup.
2. Install Connect IQ SDK **9.2.x** and **Enduro 4** device support, including simulator files/fonts.
3. Install the official **Monkey C** VS Code extension. Run `Monkey C: Verify Installation`.
4. Use `Monkey C: Generate a Developer Key`. **Keep the key private**, backed up, and outside this repository. The same key is needed for future updates to a published app.

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
- Hatching at 2,000 steps, minimum-age gates, and family locking after adulthood.
- Feeding spends one earned snack, petting is capped at 3/day, and state persists after app restart.
- Legendary mastery keeps increasing every 25,000 credited steps without death.

You can also test the watch UI with the Enduro 4 five-button navigation.

## Real watch installation

After successful simulator tests and build, connect the Enduro 4 over USB and copy the signed PRG to the watch's `GARMIN/APPS` directory (when exposed via USB). Disconnect safely and run it from the watch's apps list. Do not install an untested build expecting full reliability.

## Automated checks

`python3 scripts/check_project.py` is a **static structural check only**. The GitHub Actions workflow runs this preflight on every push/PR. It **does not compile Monkey C or run a Garmin simulator**: a real Connect IQ SDK + Enduro 4 device definition and developer key are required. Never commit personal Garmin credentials or developer signing keys.

For Connect IQ specifics, see [Garmin SDK Getting Started](https://developer.garmin.com/connect-iq/connect-iq-basics/getting-started/) and [Background Services](https://developer.garmin.com/connect-iq/articles/core-topics/Backgrounding.html).
