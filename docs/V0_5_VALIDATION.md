# v0.5.0 beta candidate - implementation and acceptance

Implemented, built and SDK-tested beta candidate; physical acceptance remains
open. This record distinguishes executed checks from outstanding checks.
v0.4 simulator evidence is not automatically v0.5 evidence.

## Authority and current document map

Use this precedence: **latest v0.5 request/recent user feedback**, then latest
GitHub issue descriptions **and comments**, then latest redesign documentation,
then historical v0.4 specifications. A dated prototype workflow or old design
instruction cannot override the comprehensive v0.5 implementation request.

- Current behaviour/evidence: this document, `RELEASE_0_5_0.md`, `README.md`,
  `BUILD.md` and the source/tests. `EVOLUTION_DESIGN.md` describes the retained
  progression ledgers, not a request to restart them.
- `MINIGAME_REDESIGN.md` retains the design discussion, but its earlier
  stop-after-one-prototype workflow is superseded. Session length and rounds
  serve gameplay pacing, not a round-count compliance target. Three rewarded
  arcade sessions/day is a **reward cap**, never a round limit or play limit.
- `GAMEPLAY_V0_4.md`, `CODEX_V0_4_TASKS.md`, `V0_4_REVIEW_AMENDMENTS.md` and
  the old target tiers in `ACTIVITY_AND_GLANCE.md` are historical instructions.
  Existing DEV, native Glance and the accepted 12-profile implementation were
  reviewed/extended, not replaced with new applications.
- `V0_4_VALIDATION.md`, `RELEASE_0_4_0_VERIFICATION.md` and v0.4 release/artifact
  records remain historical evidence. They are not relabelled as v0.5 results.
- `WATCH_ACCEPTANCE.md` separates user-reported v0.4 hardware observations from
  still-unverified v0.5 hardware behaviour. System Alert Tones mute is respected.

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
  Care/play earns the same energy and discoveries as optional activity. Choices
  use encounter-specific verbs (Help, Cross, Dive, Read, Open), not generic
  Search/Detour labels everywhere. Scouting results explicitly say NO LOOT.
- Sessions: checkpoints include stage, input progress, RNG, choices and results
  in progress. BACK pauses. Suspend/restart/reopen resumes without another debit.
  Claim, reward/inventory and completed-session removal are one atomic save;
  stale/double completion cannot claim again. Only completed arcade sessions use
  the shared three-rewarded-sessions/day budget; later play is practice.
  Interrupted initial setup is recovered using the same session ID/seed,
  including empty first memory sequences and older initial adventure phases.
- Game intros/results refresh at 1Hz rather than gameplay's 4Hz, and Motion OFF
  disables decorative pose changes there. Hidden views have no running timer.
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

## Native background execution

The isolated `tests/background` fixture uses a different application ID and a
distinct **TekuBeast BG QA** name; it is not a replacement Developer Mode app.
It populates all inventory slots, 32 ledger slots, a Legendary rare form and
three paused sessions, then calls the **unchanged production service** through
the SDK's actual Background Events dialog. No Garmin steps are manufactured.

- Enduro 4: Steps Progress, Sleep Event, Wake Event and repeated Steps Progress
  completed without runtime errors. Diagnostic used memory **33,040 / 61,344**
  bytes. Reopening retained fixture XP 123,456, three pending sessions and item
  slot 7 quantity 18.
  Final-source `27ca7f1` repeat of Steps Progress also passed with the populated
  fixture, using **33,072 / 61,344** bytes at the diagnostic point.
- Forerunner 955: actual Steps Progress completed without runtime errors;
  **32,872 / 61,344** bytes at the diagnostic point. Reopening retained the same
  fixture XP, session count and inventory quantity.

These are post-reconciliation measurements, **not absolute peaks**, and fixture
XP is not real activity. Background execution is separately budgeted; a
full-app pass is not used as proof of background safety. Original Enduro and
Fenix 6X exclusions are retained rather than repeating their known RAM failures.

## Interactive simulator checkpoints

Enduro 4 normal app was opened using actual simulated watch-button controls.
The larger Pet screen was captured, DEV was enabled inside the same app, and
the bedtime scenario produced a curled beast, Z and dark virtual room. Beast
Bounce lane movement/jumping and its three-stage timeout/result/replay path
were exercised. Successful catches and complete memory/adventure reward paths
are covered by executable tests; this does not establish subjective enjoyment.

After stopping/restarting, the normal app's Details still showed **Pip,
Hatchling, 3,000 watch XP, friendship 6**, with no DEV indicator. Genuine XP was
not reset or replaced by DEV results. This is the simulator's existing save,
not the owner's physical-watch save. See `art/store/v0.5` captures.

In the first exported release checkpoint, actual simulated buttons also opened
Follow My Lead: UP and SELECT advanced the input cursor; a wrong DOWN showed
TRY AGAIN. BACK/reopen resumed round 1 on the same second attempt rather than
resetting retries. A Tiny Adventures scouting trip visibly travelled to themed
encounters. This exposed generic encounter labels, corrected in `059c94c` with
new unit assertions and an additional 25 route/choice/scout layout scenes.

The final exported release also completed a normal, non-DEV scouting trip after
an actual app stop/reopen at stop two. Its corrected result said SCOUT: NO LOOT;
Exit worked. Details retained Pip / Hatchling / watch XP 3,000 / bond 6 /
Adventure 0; Care retained meals 2 / snacks 1. This exercises actual simulator
Storage, not just the in-memory unit store. See the final capture and
[artifact verification](RELEASE_0_5_0_VERIFICATION.md).

The native Enduro 4 production Glance was visibly rendered with Pip, ASLEEP
and a growth bar. Its actual small VM was tested by the separate Glance matrix;
simply toggling preview while a full app is loaded was not counted as a budget
test. The final signed PRG ran in the actual Glance VM at about 31.8 KiB /
59.9 KiB. START in the preview did not emulate a watch Glances-list transition;
selection/OS timeout behaviour still requires hardware acceptance.

## SDK results

Enduro 4 implementation checkpoint: 24 tests passed, 0 failures/errors; 608
layout scenes passed with 0 failures. Peak audit memory 96,224 / 781,976 bytes.
This is a retained checkpoint, not the final matrix. The time-picker audit was
then expanded by 48 scenes and all route/choice/scout states by another 25.
Earlier failing layout runs caught clipped footers and overlapping game prompts;
they are not counted as passes. The SDK also stalled before one test launch
(no test output); a normal host restart without clearing data enabled the clean
rerun. Timeouts and expected failing reproductions are never accepted as passes.

Full implementation checkpoint `1365e15`: all 13 accepted profiles passed 24
tests / 662 layout scenes with no failures. A Venu 3 host launch timeout emitted
no test output; it was not counted as a pass. Its isolated rerun passed both
unit/layout audits. The adventure-wording correction passed expanded audits
with 687 scenes, including every route/node/choice and the no-loot result.

### Final accepted evidence / provenance

- **Final runtime `27ca7f1`: 24 tests pass on every one of 13 profiles**
  (312 passing test executions in this final all-profile unit run).
- **687 clean layout scenes for each profile** (8,931 latest-profile renders).
  The all-profile rendering run used runtime `059c94c` and QA `514bd97`;
  Enduro 4, Fenix 7S, vivoactive 5 and Forerunner 955 were repeated on `27ca7f1`
  after the recovery-only change. Rendering functions/assets did not change in
  that guard. Other rows retain their actual earlier layout measurement; they
  are not falsely labelled as identical-final-binary runs.
- **60 native Glance scenes on each of 13 profiles** (780 renders), zero bounds
  failures, all in the actual 61,344-byte available Glance VM. Glance/App/sleep
  source is unchanged since that audited `4f22b55` checkpoint; final production
  Enduro 4 export was additionally rendered in its actual Glance runtime.
- Actual native background callbacks and final production restart trace above.
- Development/release builds and signed **19/19 hardware-part export** succeed;
  19 SDK aliases/parts are not 19 independently tested simulator profiles.
- Static preflight and whitespace checks pass, but are not SDK evidence.

| SDK profile | Display | Final units | Layout scenes | Latest game audit bytes | Native Glance bytes |
|---|---|---:|---:|---:|---:|
| enduro4 | 280 MIP | 24 PASS | 687 PASS* | 102,744 / 781,976 | 38,176 / 61,344 |
| enduro3 | 280 MIP | 24 PASS | 687 PASS | 102,552 / 781,976 | 38,176 / 61,344 |
| fenix7x (Enduro 2 SDK alias) | 280 MIP | 24 PASS | 687 PASS | 102,392 / 781,976 | 38,016 / 61,344 |
| fenix7xpro | 280 MIP | 24 PASS | 687 PASS | 102,392 / 781,976 | 38,016 / 61,344 |
| fenix8solar51mm | 280 MIP | 24 PASS | 687 PASS | 102,552 / 781,976 | 38,176 / 61,344 |
| fenix8solar47mm | 260 MIP | 24 PASS | 687 PASS | 102,552 / 781,976 | 38,176 / 61,344 |
| fenix7 | 260 MIP | 24 PASS | 687 PASS | 102,392 / 781,976 | 38,016 / 61,344 |
| fenix7s | 240 MIP | 24 PASS | 687 PASS* | 102,584 / 781,976 | 38,016 / 61,344 |
| fr265 | 416 AMOLED | 24 PASS | 687 PASS | 102,456 / 781,976 | 38,080 / 61,344 |
| fr965 | 454 AMOLED | 24 PASS | 687 PASS | 102,456 / 781,976 | 38,080 / 61,344 |
| venu3 | 454 AMOLED | 24 PASS | 687 PASS | 102,440 / 781,976 | 38,064 / 61,344 |
| vivoactive5 | 390 AMOLED | 24 PASS | 687 PASS* | 102,632 / 781,976 | 38,064 / 61,344 |
| fr955 | 260 MIP | 24 PASS | 687 PASS* | 102,576 / 781,976 | 38,008 / 61,344 |

`*` final recovery-guard layout repeat. Game figures include the QA harness;
Glance figures include a conservative 1,600-number payload and all 15 sprites
in awake/tired/nap/night states. These are not battery or physical guarantees.
Raw passing summaries, JSON, and the intentionally failing/fixed interrupted-start
reproduction are retained under `docs/validation/v0.5`.

The interrupted-start test first reproduced **23 passed / 1 assertion error**
before the fix. The same suite then passed 24/24 and was rerun on all profiles.
No charge, claim or real activity value is reset when setup is repaired.

## Issue status and remaining limitations

| Issue | Implemented in the candidate | Still needed before closure |
|---|---|---|
| #15 | Larger trimmed sprites, roaming, no species heading, attention HUD | Physical MIP readability, circular-edge and enjoyment review |
| #12 | Shared sleep/mood priority, curled tired/sleep sprites, read-only Glance recovery | Physical stale-status/reopen regression |
| #14 | All three playable character sessions, replay/resume, atomic rewards | Owner's real-watch enjoyment, difficulty and interrupted-trip acceptance |
| #13 | Guarded watch schedule, manual/OFF fallback, virtual lights, quiet recovery | Compare watch data/events with actual Sleep Focus/weekend/timezone behaviour |
| #5 | Distinct chirps, 140ms gentle/optional expressive haptics, diagnostics | Changed v0.5 patterns, DND and audibility on hardware; no system-mute bypass |
| #10 | Existing native Glance improved; 13 native-budget profile audits | Actual Glance selection/OS timeout behaviour, especially games |
| #7 | Existing same-app isolated DEV completed with sleep/needs scenarios | Physical discard/restart and genuine-step catch-up while testing |
| #9 | Retain 12 profiles, add individually tested Forerunner 955 | More hardware/models; original Enduro/Fenix 6X stay excluded for RAM limits |

All remain open for those explicit acceptance items; #11 was not implemented.
Rare forms retain the earned crown overlay rather than separate anatomy;
Glance uses the cached family/stage small sprite, not a full rare-form atlas.
Tiredness and naps share a curled pose; nighttime is additionally dark/ASLEEP.
Adventure environments are deliberately lightweight maps, not scene atlases.
No simulator result establishes real-world battery use or user-tested fun.

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
- https://developer.garmin.com/connect-iq/api-docs/Toybox/Application/AppBase.html
- https://developer.garmin.com/connect-iq/api-docs/Toybox/WatchUi/GlanceViewDelegate.html
