# v0.5.0 beta candidate - implementation and acceptance

Work in progress: this log distinguishes executed checks from outstanding
checks. v0.4 simulator evidence is not automatically v0.5 evidence.

## Scope and save contract

Issues #15, #12, #14, #13, #5, #10, #7 and #9 are in scope. Issue #11 is excluded.
The application ID and signing key stay unchanged. Storage remains the atomic
`v4` document with its existing version/keys, legacy keys and migration snapshot
retained. v0.5 adds optional fields idempotently; it does not reset Pip, genuine
XP/day watermarks, growth, friendship, stage/family, inventory or collections.

DEV remains inside the normal app. Its deep-copied state, virtual clock, sleep
scenarios, rewards and resumable game sessions never write over the real save.
Discard/restart restore the canonical real state; genuine steps reconcile using
the existing ledger. No Garmin clock, step counter or Sleep Focus is modified.

## Implemented behaviour

- Pet: no species heading; larger native, tightly trimmed pixel resources,
  mirrored walking poses, 2-D paths/pauses, family variation, hopping/blinking,
  attention-only apple/heart icons and a fixed floor poop. Details keeps species,
  family, stage, growth, age and genuine step XP. Motion OFF/LOW/NORMAL remains.
- Sleep: one shared mood/priority policy across full app and read-only Glance.
  Actual sleep/tiredness wins over stale reactions. RESTING is a daytime nap;
  ASLEEP is scheduled bedtime. Energy restores lazily with no overnight timer.
- Watch sleep schedule: guarded UserProfile upcoming moments (API 6) when valid,
  then typical local sleep/wake durations, then configurable 22:00-07:00 fallback.
  Settings can choose WATCH/MANUAL/OFF, 30-minute bedtime/wake values and auto
  lights. Optional Lights On/Off overrides the virtual room for one hour only.
  No penalties for ignoring lights. Sleep/wake background callbacks reconcile
  silently; opening the app also reconciles if callbacks were missed.
- Watch schedule data is not verified Sleep Focus state. Source is exposed in
  Bedtime settings. Historical energy recovery uses local typical/manual windows
  rather than incorrectly applying a newly fetched upcoming pair to past hours.
- Beast Bounce: actual pet moves between three platforms with UP/DOWN and hops
  with SELECT to collect falling stars. Fifteen targets across three increasing
  difficulty stages, combos, score, results and replay; about 60 seconds normal,
  75 seconds easy. Touch picks a lane and hops; Menu cycles lanes on no-UP models.
- Follow My Lead: pet hops/smiles/looks with three matching button symbols;
  sequences grow 3/4/5, two chances per round, replay on error, scoring and replay.
  Timed SELECT scanning and touch support are retained.
- Tiny Adventures: four themed destinations, three travelled/interactive stops,
  safe/bold choices and varied seeded discoveries. One Adventure Energy is charged
  once per whole paid trip. No-energy scouting is unlimited practice without loot.
  Care/play earns the same energy and discoveries as optional activity.
- Sessions: checkpoints include stage, input progress, RNG, choices and results
  in progress. BACK pauses. Suspend/restart/reopen resumes without another debit.
  Claim, reward/inventory and completed-session removal are one atomic save;
  stale/double completion cannot claim again. Only completed arcade sessions use
  the shared three-rewarded-sessions/day budget; later play is practice.
- Feedback: distinct short tone patterns, longer gentle 140ms haptic and optional
  expressive double pulses. Independent sound/vibration toggles. Tone tests show
  system tones/DND/API/error status, log exceptions and attempt a guarded standard
  tone fallback. TONE REQUESTED does not prove audible output. Bedtime and DND
  suppress both channels; no background alerts or system-mute bypass.
- Glance: cached real creature/growth, current shared mood, curled small sprite
  for sleep/tiredness, growth track and cleanup marker. No state engine, timer,
  save writes, animation or audio in Glance. A bounded read-only care projection
  avoids stale tiredness after overnight recovery when a wake callback was missed;
  it does not advance growth or change saved values.
- DEV adds bedtime, waking, sleepy, happy-roaming and all-needs scenarios alongside
  existing stage/family/needs/items/time/game/animation/audio controls.
- Settings displays 0.5.0 beta. No Store publication is authorised or performed.

## SDK results

Enduro 4 implementation checkpoint: 24 tests passed, 0 failures/errors; 608
layout scenes passed with 0 failures. Peak audit memory 96,224 / 781,976 bytes.
This is a checkpoint, not the complete matrix/release acceptance. The time-picker
audit was then expanded by 48 scenes and will be rerun with the full matrix.
Earlier failing layout runs caught clipped footers and overlapping game prompts;
they are not counted as passes. The SDK also stalled before one test launch
(no test output); a normal host restart without clearing data enabled the clean
rerun. Final matrix/release/Glance evidence will be recorded below.

## Physical acceptance still required

The user's v0.4 evidence confirms Glance availability, visible Developer Mode,
working vibration and audible tones when Garmin Alert Tones are enabled. It does
not validate changed v0.5 behaviour. Do not close hardware-dependent issues yet.

- Upgrade same beta without uninstalling: verify actual Pip, XP/history, growth,
  friendship, snacks, inventory, collections and settings.
- Inspect Pip and advanced family forms, both directions, all motion modes,
  simultaneous needs, poop/cleaning, feeding, evolution and circular edges.
- Compare WATCH schedule/source to actual weekday/weekend Garmin schedule and
  timezone changes; verify bedtime/wake while app is closed. If inconsistent,
  use MANUAL rather than claim automatic Sleep Focus synchronisation.
- Verify Glance correct sprite/mood/cleanup/growth, open-full-game and timeout
  behaviour with all three games. Reopen interrupted trips and check one charge.
- Play/replay all games and judge enjoyment, clarity, controls and easy mode.
- DEV accelerate, force stages/families, run sleep/need/game scenarios, discard
  and restart; check real progress and genuine steps remain intact.
- Verify tone patterns with Alert Tones enabled, quiet behaviour with tones off,
  DND/nighttime silence, both vibration styles and independent toggles.
- Observe battery use during normal daily use. Simulator memory is not battery
  certification. Other profiles remain simulator-tested, not hardware-certified.

## API references

- https://developer.garmin.com/connect-iq/api-docs/Toybox/UserProfile/Profile.html
- https://developer.garmin.com/connect-iq/api-docs/Toybox/Background.html
- https://developer.garmin.com/connect-iq/api-docs/Toybox/System/ServiceDelegate.html
- https://developer.garmin.com/connect-iq/api-docs/Toybox/Attention.html
- https://developer.garmin.com/connect-iq/api-docs/Toybox/System/DeviceSettings.html
