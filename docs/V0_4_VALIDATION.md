# v0.4 implementation and validation

## Current beta - 16 October 2026

SDK 9.2.0 / Java 17 / Windows. App ID and signing key unchanged. No separate
Developer Lab ships. This is implemented code, not physical-watch certification.
Earlier eight-test checkpoints were superseded by the final regression below.

### Completed implementation

- Same-app temporary DEV: 1/5/20/100x, +1h/+1d/+7d, stage/family/needs/stock,
  scenario resets and normal care/game/animation/audio screens. Discard-only
  return reloads the real save and reconciles genuine steps; restart discards.
- Atomic canonical v4 save with reward watermarks; retained legacy keys and
  migration snapshot. Existing stage floor and early date-only age recovery.
- Separate lifetime watch XP, passive, care/game and activity growth. Default
  Legendary ~25 zero-step days / 21 active minimum; egg 24h / 8h floor; mastery.
  Long absence growth, bounded care decay, daily rollback protection, no death.
- Zero-step meals, earned snacks, care attributes/mood/personality, pet/rest,
  delayed poop and direct Clean. All family/rare paths and discovery types
  accessible through care/play; shared step/minute/push milestones, not sum.
- Playable Star Catch, Memory Steps and Trail Treasure. Buttons/touch and SELECT
  scanning fallback; three rewarded sessions/day then unlimited practice.
- Fifteen concept-inspired species with six poses, wandering/hopping, blink/
  look, chew, curled sleep, happy/clean/evolve effects. Rare forms currently use
  an earned crown overlay, not separate anatomy atlases.
- Simplified round UI, no persistent app heading; native-sized AMOLED assets.
- Native cached read-only Glance without timer, migration, save writes or audio.
- Independent sound OFF / gentle haptics ON defaults; foreground-only guarded
  Attention APIs, supported system mute/DND checks and rate limiting.

### Executed Enduro 4 tests

**16 unit tests passed, 0 failed, 0 errors** in the actual SDK simulator:
migration/restart (legacy 5,974 XP, snacks, friendship, watermarks); DEV nested
copy/discard/real catch-up; zero-step 7/25/100 days and rollback; 8/24h hatch;
care/poop/clean; daily budgets; overlapping activity deduplication; every
zero-step family/rare; Settings/DEV navigation; Star/Memory/scan/timeouts/replay;
21-day active balance/archive preserving XP; early save age; fresh-egg DEV;
non-step bonuses/discovery permanence; one-time foreground evolution reveal;
foreground/inactive/game timer lifecycle and genuine save reload after a
mini-game suspension (including externally reconciled watch XP).

**318 Enduro 4 layout scenes, 0 failures:** every normal species on all three
pages, eight poses, menu selections, large counters, game phases, toast and rare
names. Native-font boxes checked for circle boundaries, overlaps and truncation.
This caught and fixed the long Moonwater Kirin name (now wraps).

Interactive simulator trace, normal application and visible watch buttons:

1. Genuine Pip: watch XP 2,000, friendship 6, day 0.
2. Enable DEV; 100x; +7 days: temporary Adult, genuine XP unchanged.
3. SDK simulated ActivityMonitor steps 0 to 1,000 while DEV is active.
4. Discard: genuine Pip/day 0/friendship 6 restored, XP becomes 3,000.

Actual ActivityMonitor integration was exercised, not only injected fixtures.
No physical Garmin counter was changed. This is not physical-watch testing.

See [device matrix](DEVICE_MATRIX.md) for final per-profile results and Glance
memory. Internal QA IDs/models are isolated and must not be uploaded. Glance
audit includes conservative save-sized padding and a Legendary small sprite.
The SDK Glance host is resident: wrapper captures an explicit memory result,
then stops only its own SDK connection. Timeout without clean evidence fails.
Production Glance has no test payload, System.exit or timer.

### Resource budget and remaining hardware acceptance

Pet requests at most four foreground frames/second, static pages/menus one/sec,
watch reconciliation about every 20 active seconds. Hidden/inactive timers stop.
Motion settings are available; only current frames are held, identical egg
frames share one bitmap. Glance loads one 40px sprite without the game engine.
The final Enduro 4 audit measured 66,592 peak used bytes of 781,976 available, including
the QA harness. These are SDK measurements and implementation budgets, not
physical-watch CPU/battery-life claims.

- No physical watch, audible-tone, vibration, battery or actual-user upgrade
  testing. Hardware acceptance remains open in issues #5/#7/#10.
- On Enduro 4, add the existing app to Glances, select it, verify full-game and
  mini-game session timeouts. Simulator preview is not the watch's Glances list.
- Upgrade without uninstalling; check the user's actual Pip/history/settings.
  Fixtures and simulator Pip are not a backup of the user's watch Storage.
- On hardware toggle DEV, advance/reset, record activity, discard and reopen.
  Verify optional sounds/haptics. No actual walk/run/push session occurred here.
- Running/workout type is not guessed from step data. Supported active minutes
  and pushes are guarded; recent history cannot recover arbitrarily old steps.
- Original Enduro exhausts RAM during artwork audit and is excluded; legacy API
  1.x is below the API 3.2 minimum. Fenix 6X passed full-app tests but its actual
  SDK Steps Progress callback exhausts the 32KB background budget, so it too is
  excluded. Enduro 4's callback completed without errors or duplicate watch XP.
  Untested watches remain unlisted.
- Compass is currently cosmetic, not the future cross-family Compass exception.
  Earned same-family rare evolution is implemented and zero-step tested.

### Reproduce

Run structural preflight, then `scripts/device-matrix.ps1` in simulator Normal
launch mode. Switch Settings > Glance Launch Mode to Glance for
`scripts/glance-matrix.ps1`; restore Normal before gameplay tests. Local logs
and JSON are in ignored `bin/`; accepted results are recorded in DEVICE_MATRIX.
