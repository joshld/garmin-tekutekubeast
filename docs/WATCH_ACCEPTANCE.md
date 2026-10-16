# User-reported watch acceptance

## Latest v0.4 hardware feedback / v0.5 boundary

The user subsequently confirmed that vibration works but feels very short, and
sound works when Garmin system Alert Tones are enabled and is blocked when those
tones are disabled. These are v0.4 physical Enduro 4 findings, not v0.5 tests.
The v0.5 changes respect that restriction; they do not bypass system tones or DND.
New UI, sleep behaviour, games, feedback patterns and save upgrades still require
the [v0.5 hardware checklist](V0_5_VALIDATION.md#physical-acceptance-still-required).

## Enduro 4 - v0.4 beta - 16 October 2026

Evidence in this section is the user's report from their physical watch, not
agent-operated testing. The exact installed binary hash and watch firmware
version have not been read from the watch.

Confirmed by the user:

- Developer Mode is visible in the installed TekuTekuBeast app.
- TekuTekuBeast now appears in the watch's Glances list. It initially did not.

The user was offered open/exit, sync and normal power-cycle checks, but did not
report which actions they took. Do not claim that a particular action fixed
registration or that a reproducible registration defect has been diagnosed.

Still unverified on physical hardware:

- Glance sprite/name/mood/growth/cleanup rendering, selection into the full game,
  and inactivity/session behaviour including mini-games (issue #10).
- Exact Pip/history/XP/friendship/inventory/settings preservation after upgrade.
- DEV acceleration, scenario reset, discard/restart isolation and genuine-step
  catch-up on the watch (issue #7).
- Actual walking, running, supported minutes/pushes and duplicate prevention.
- The changed v0.5 tone/vibration patterns and DND behaviour (issue #5); basic
  v0.4 sound/vibration and the Alert Tones restriction were subsequently confirmed.
- Long-running battery use and resource behaviour.

Continue updating the existing installation. Do not uninstall, clear Storage or
reset the watch to test the Glance. No save reset or application-ID change is
required by the documented implementation.

## Store submission observation

The user encountered Garmin's generic server-communication submission error,
cancelled, and then reported the dashboard's latest version as 0.4.0. This does
not prove that all description, release-note and image changes were saved.
No agent-operated Garmin upload or completed metadata-submission verification
has occurred. The separate cover and copy changes do not require a new binary.

See [release verification](RELEASE_0_4_0_VERIFICATION.md) for the unchanged signed
package hashes and [simulator validation](V0_4_VALIDATION.md) for executed tests.
