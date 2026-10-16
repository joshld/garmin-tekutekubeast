# Executed v0.5 SDK evidence

These are actual Connect IQ SDK 9.2.0 runner outputs, not static preflight
results. Read [the validation record](../../V0_5_VALIDATION.md) for provenance,
memory interpretation, hardware boundaries and the issue acceptance checklist.

- `*-units.log` / `v05-unit-matrix.json`: final `27ca7f1`, 24 tests on each of
  13 independently compiled/executed profiles, including interrupted-start repair.
- `*-layout.log` / `v05-device-matrix.json`: 687 scenes per profile. Rendering
  source `059c94c`, QA `514bd97`; four representative final `27ca7f1` repeats
  are identified in the main report. Do not relabel all rows as one final binary.
- `*-glance.log` / `v05-glance-matrix.json`: 60 native-budget scenes per profile;
  Glance/App/BeastSleep source unchanged since the audited `4f22b55` checkpoint.
  `SDK_GLANCE_CAPTURE_STOPPED` means the owned resident runner was stopped after
  clean explicit audit output, not that a timeout alone counted as a pass.
- `background-*`: actual native SDK event callbacks with a populated, separately
  identified QA save; reopen output retains fixture XP, inventory and 3 sessions.
- `v05-final-background-enduro4.log`: final-source background repeat, 33,072 /
  61,344 bytes after reconciliation (not an absolute peak).
- `v05-resume-repro.log`: **intentionally failing** regression before recovery
  was implemented (23 passes / 1 assertion error). It is not a final failed run.
  `v05-resume-fixed.log` and every final unit log show the corrected 24/24 pass.

No logs establish physical-watch tone audibility, Sleep Focus agreement, battery
life, user enjoyment or watch-OS Glance launch/timeouts. Production release
screenshots and hashes are indexed separately. No signing key or QA binary is
committed or uploaded to Garmin.
