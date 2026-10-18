# v0.4 accepted SDK device matrix
> Version-specific release evidence, not everyday build instructions. Start with
> [current guides](../../../README.md#documentation).

This is retained v0.4 evidence. For the v0.5 regression run see
[V0_5_VALIDATION.md](../v0.5.0/V0_5_VALIDATION.md); no old pass is counted as a new pass.

Recorded 16 October 2026, Connect IQ SDK 9.2.0, Windows / Java 17.
These are individually compiled and executed simulator profiles, **not physical
watch certification**. Production app ID and signing key are unchanged.

Every enabled profile passed all **16 unit tests** and **318 layout scenes**
(192 unit executions / 3,816 scene renders across the twelve accepted profiles).
Thirteen candidates passed full-app tests, but Fenix 6X was subsequently rejected
by its actual background-step callback test. Tests cover migration,
DEV isolation, inclusive progression, care, games, deduplication, suspension and
save reload. Source was frozen at `15b7ffc` for this final normal-app matrix.
The production manifest is expanded only after those results. A final common
navigation correction (return care/evolution reactions to Pet) additionally
passed 16 tests / 318 scenes on Enduro 4, Fenix 7S and vivoactive 5. Those focused
runs add 48 unit executions / 954 scenes; their latest memory readings are below.

## Accepted profiles

Game bytes are the peak used / available reported by System.getSystemStats
through the complete artwork/layout audit, including QA code. Glance bytes
include a conservative save-sized synthetic payload and Legendary small sprite.
They are SDK memory measurements, not CPU, battery-life or hardware guarantees.

| SDK profile / model | Display | Unit / layout | Game audit bytes | Glance bytes |
|---|---|---|---:|---:|
| `enduro4` - Enduro 4 | 280px MIP | 16 / 318 PASS | 66,592 / 781,976 | 30,096 / 61,344 |
| `enduro3` - Enduro 3 | 280px MIP | 16 / 318 PASS | 66,584 / 781,976 | 30,096 / 61,344 |
| `fenix7x` - Fenix 7X / Enduro 2 SDK alias | 280px MIP | 16 / 318 PASS | 66,424 / 781,976 | 29,936 / 61,344 |
| `fenix7xpro` - Fenix 7X Pro | 280px MIP | 16 / 318 PASS | 66,424 / 781,976 | 29,936 / 61,344 |
| `fenix8solar51mm` - Fenix 8 Solar 51mm | 280px MIP | 16 / 318 PASS | 66,584 / 781,976 | 30,096 / 61,344 |
| `fenix8solar47mm` - Fenix 8 Solar 47mm | 260px MIP | 16 / 318 PASS | 66,584 / 781,976 | 30,096 / 61,344 |
| `fenix7` - Fenix 7 | 260px MIP | 16 / 318 PASS | 66,424 / 781,976 | 29,936 / 61,344 |
| `fenix7s` - Fenix 7S | 240px MIP | 16 / 318 PASS | 66,432 / 781,976 | 29,936 / 61,344 |
| `fr265` - Forerunner 265 | 416px AMOLED | 16 / 318 PASS | 66,488 / 781,976 | 30,000 / 61,344 |
| `fr965` - Forerunner 965 | 454px AMOLED | 16 / 318 PASS | 66,488 / 781,976 | 30,000 / 61,344 |
| `venu3` - Venu 3 | 454px AMOLED | 16 / 318 PASS | 66,472 / 781,976 | 29,984 / 61,344 |
| `vivoactive5` - vívoactive 5 | 390px AMOLED | 16 / 318 PASS | 66,480 / 781,976 | 29,952 / 61,344 |

Garmin's `fenix7x` definition explicitly includes Enduro 2 (and other SDK
aliases); this is one shared simulator profile, not separate physical SKU tests.
Other aliases implied by Garmin's device definitions have not been separately
hardware-tested. Native-size nearest-neighbour assets are selected for the
AMOLED profiles; no palette bitmap affine transforms are used.

## Native Glance areas and bounds

All twelve native-Glance profiles passed the text-bound checks with zero
failures. Long names wrap where space permits; 63px-high tiles abbreviate long
names with dots to retain readable mood/cleanup status and a separate meter.

| Profile | SDK Glance area |
|---|---|
| `enduro4` | 216x88 |
| `enduro3` | 217x88 |
| `fenix7x` | 191x63 |
| `fenix7xpro` | 191x63 |
| `fenix8solar51mm` | 217x88 |
| `fenix8solar47mm` | 198x81 |
| `fenix7` | 171x63 |
| `fenix7s` | 151x63 |
| `fr265` | 275x120 |
| `fr965` | 299x148 |
| `venu3` | 303x164 |
| `vivoactive5` | 260x141 |

Fenix 6X's simulator also disables native watch-app Glance launch, but the
decisive rejection is the background-step Out Of Memory failure described below.
The user confirmed on 16 October 2026 that the Glance now appears on their
physical Enduro 4, after initially being absent. Selection-to-game, actual
rendering and session timeout acceptance remain open in issue #10. This limited
user confirmation is not general hardware certification; see
[the acceptance log](../../WATCH_ACCEPTANCE.md).

## Excluded / not yet accepted

- Original `enduro`: unit logic passed, but the full artwork audit throws Out Of
  Memory while loading current species frames. It is **not** in the production
  manifest. Supporting its non-paged 128KB app budget needs a separate reduced
  resource/code strategy; no loss of artwork or saves was hidden to pass it.
- `fenix6xpro`: 16 unit tests / 318 layout scenes passed; full-app audit peak
  131,912 / 1,306,136 bytes. However, triggering the actual production SDK Steps
  Progress event throws Out Of Memory under its separate 32KB background budget.
  It is therefore excluded from the production manifest, not advertised as
  working with silently broken background steps. A leaner background engine is
  needed before retesting it. Enduro 4's corresponding production callback ran
  without errors and retained its 3,000 XP watermark.
- API 1.x models such as Fenix 3 are below the minimum API 3.2 requirement.
- Other Fenix/Forerunner/Venu/vívoactive generations are not listed merely on
  similar specifications. They need their own installed SDK profile and run.

The SDK host occasionally stalled at a device-profile handover before an app
started. Those attempts were rejected, not counted as passes. A normal host
restart (no data reset) followed by an isolated clean rerun produced the
accepted vívoactive 5 unit, layout and Glance results.

## Scope and reproduction

See [validation](V0_4_VALIDATION.md) for the interactive Enduro 4 DEV/real-step
trace, timer/resource budgets and hardware acceptance checklist. Matrix unit
fixtures exercise common input/game logic on each profile; manual simulated
watch-button navigation was additionally exercised on Enduro 4. Real-world
sensor sessions and optional hardware tones/haptics are still unverified.

Use `scripts/device-matrix.ps1` in simulator Normal launch mode; use
`scripts/glance-matrix.ps1` in Glance launch mode. Both support a `-Devices`
subset and preserve other completed local results. SDK runner output must
contain explicit passing summaries; timeouts never count as passes without
clean Glance memory and bounds output. Local raw logs/JSON are in ignored
`bin/`. No developer key, QA binary or app data is committed.
