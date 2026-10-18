# v0.5.1 beta - implementation and validation record
> Version-specific release evidence, not everyday build instructions. Start with
> [current guides](../../../README.md#documentation).

Current work record. Final device/artifact tables are filled from executed SDK
runs, not inferred from the v0.5.0 record. Store publication is NOT authorised.
The owner's installed v0.5.0 feedback supersedes the old enlarged-Pet request.
Historical v0.4/v0.5 release verification files are retained unchanged.

## Implemented changes

- Exact v0.4.0 native creature pixels/canvas: 96px MIP, 144px/192px existing
  AMOLED variants, original padding and relative pose proportions. All 480 Pet
  pose variants are checked against historical commit `e9f97c5`; left poses are
  exact mirrors. v0.5 game/Glance pixels are unchanged from `eecb6c6`.
- World-space wandering destinations independent of sprite scale, with the
  sprite's full bounding square used ONLY for final circle/HUD safety. LOW
  travels more slowly, not in a smaller box. Poop no longer halves the roaming
  area. Normal foot poses, hops, turns, looks, pauses and family behaviours stay.
- Original illustrated Forest, Meadow, Lakeside and Garden landscape layers,
  built to a 140px logical grid and precompiled at all six supported resolutions.
  A broad walkable clearing replaces the unused central animation box. Only one
  landscape bitmap is cached; no runtime painting of thousands of leaf pixels.
- AUTO chooses the family theme (Grove/Forest, Ember/Meadow, Tide/Lakeside,
  Wisp/Garden). Shared stages choose a neutral daily theme. The choice is stable
  through a session and games. Settings can select all four cosmetic themes;
  no steps or mobility requirement unlocks scenery.
- Separate foreground astronomical sky and existing scheduled/manual sleep.
  Sunset does not put the pet to bed; sunrise does not override sleep. Virtual
  lights shade the landscape, not the sky's astronomical time or watch backlight.
- Attention-only food/heart needs, readable nighttime poop, numerical Care,
  compact progress, original sound/haptic preferences and all three games remain.
- Memory shows a neutral 250ms gap after EVERY cue, including identical moves;
  original 3/4/5 sequences, retries, cue duration and alternate input are retained.
- Normal Bounce stars take 4/3/2.25 seconds; Easy retains 6/5/4 seconds. Jump
  duration follows stage pace, with a forgiving normalized capture interval.
  Existing session elapsed positions are mapped once, without resetting the
  sequence, random seed, score, attempts, rewards or expedition charge.

## Location, privacy and astronomical time

Added permission: **Positioning**. No Communications permission or internet
request is added. The app never calls `Position.enableLocationEvents`, never
starts one-shot/continuous GPS, and never changes Garmin time or step counters.

On foreground entry (bounded to once per five minutes within a view instance;
a new app launch can read again), AUTO reads
`Position.getInfo()`. If a valid cached fix is unavailable, it can read an
already-cached `Weather.CurrentConditions.observationLocationPosition`; a weather
station is approximate and is labelled WEATHER CACHE. Observations older than
seven days or older than the retained fix do not replace it. Missing/denied
sources retain the last valid coordinates. Nothing requests fresh weather,
a phone connection or a network fetch.

Coordinates are rounded to 0.01 degrees and remain only on the watch. No
location is put into the pet document, Glance payload, background callback,
activity XP, logs or uploads. Settings offers AUTO, SAVED, MANUAL and explicit
FIXED modes. Approximate latitude/longitude are adjustable to 0.1 degrees;
manual coordinates are not used until confirmed. FIXED 06–18 is the clearly
labelled last resort when no selected valid location exists. Fix age is shown.
Cached coordinates can be stale after travel: inspect source/age or choose
MANUAL rather than assuming that a watch without a recent fix knows its location.

The guarded Garmin `Weather.getSunrise/getSunset` API is preferred for a supplied
location/date. Null, unsupported, implausible or wrong-date results fall back to
the offline NOAA fractional-year equation with apparent horizon 90.833 degrees.
This is an approximation, not second-level astronomical precision or a terrain
horizon forecast. Polar day/night are represented explicitly, not fabricated
rise/set times. Unit envelopes for London solstices and Brisbane summer are ten
minutes; the test also covers polar seasons, leap day and a dateline longitude.

Events are absolute UTC epochs for the WATCH'S local calendar date. A cache key
includes local date, current UTC/DST offset, selected coordinates and mode. The
previous/current/following day's events are persisted in the separate small
`world.v1` record. Date, zone or location changes invalidate the cache. Only
minute-level sky samples are recalculated while visible; sun geometry is reused
between samples. The sun follows sunrise / solar-noon / sunset progress; the moon is
explicitly a decorative night-progress crescent, NOT lunar rise/set or phase.
Dawn/dusk use restrained stepped palettes around actual rise/set.

## Persistence and battery audit

The application ID and signing identity are unchanged. `v4`, its saved version,
legacy keys, genuine XP/watermarks, inventory, collections, friendship, growth,
family, stage and resumable transactions remain. Only an additive optional
`profileZone` cache field is introduced to the pet document. Scenery preferences
and rounded locations are in `world.v1`, not the memory-limited background save.
DEV has independent deep copies; it cannot persist test scenery/location or pet
changes. Exiting/restarting restores the real data and real step reconciliation.

- Foreground timers still stop on hide/inactive; games checkpoint before exit.
  Still Pet/menu/Care/Details callbacks may sleep for 5s rather than 1s. Action
  notices/reactions return promptly to their normal cadence. Normal wandering
  and active Bounce keep their existing 250ms animation cadence.
- Pet dirty visual signatures prevent repainting an unchanged sleeping/OFF
  scene. The step footer no longer queries ActivityMonitor four times/second;
  it is display-cached to the existing reconciliation cadence. Crediting uses
  the unmodified genuine watermark, never this display cache.
- Memory redraws only when its cue/neutral/input state changes, preserving all
  visible animation. Waiting choices and still game results avoid idle redraws.
- Canonical saves compare complete structures against an independent baseline
  before cloning/writing. No probabilistic hash can miss a real change. Unchanged
  session checkpoints and the repeated commit after hide are skipped.
- Sleep profile reads are cached for 15 minutes, with forced refresh on full
  entry, Settings and native sleep/wake callbacks; offset changes invalidate it.
- Duplicate step events can bypass full reconciliation for at most 60s ONLY
  when no new genuine steps, reward threshold, care/poop boundary, date rollover
  or due profile refresh needs processing. Sleep/wake callbacks always reconcile.
  Passive growth remains exact lazy catch-up, not lost or slowed progression.
  New step credits are NEVER rate-limited. OS callback frequency is not changed.
- Glance reads once on its initial update instead of twice on show+update. It
  has no timer, animations, location/scenery load, save writes or background audio.
- Landscape profiling is QA-only: normal gameplay does not collect render timers.
  Its coarse SDK-host timings include a cached bitmap blit on each changed Pet
  frame; caching does not mean scenery has zero rendering cost. Hardware cost
  and total battery drain remain unmeasured.

Executed deterministic audit: **100 identical commits -> 0 writes**, duplicate
step preflight accepts 100/100 unchanged cases, and a new genuine step persists.
**40 unchanged Pet callbacks -> 1 redraw**; **21 memory cue ticks -> 7 redraws**.
These are executable SDK counters, not a claim about real battery-life percentage.
Changing progress, genuine activity, rewards and care still cause necessary writes.

Baseline is the actual v0.5 implementation at `eecb6c6`, not an assumed device
power reading. Its `commit()` always copied/wrote the canonical document;
Pet refresh requested an update every second even when still; `todayLabel()`
queried watch steps on every paint; `syncToday()` read the sleep profile every
reconciliation. The following are code/counter improvements, not battery claims:

| Work | v0.5 baseline | v0.5.1 |
|---|---|---|
| 100 identical canonical commits | 100 unconditional write calls | 0 writes in SDK test |
| Still Pet/menu/care/details timer | 1 second | 5 seconds; 80% fewer scheduled wakeups |
| Unchanged Pet callback test | redraw per callback | 1 request in 40 callbacks |
| Memory cue test | redraw per active tick | 7 requests in 21 ticks |
| Footer ActivityMonitor reads | once per paint, up to 4/sec | display cached to 20-second reconciliation |
| Typical sleep profile reads | each reconciliation (20 sec in foreground) | 15-minute cache; entry/settings/events force refresh |
| Glance initial save reads | show + update | update only |

No claim is made that the OS delivers fewer background events. Each event must
still read the canonical document and current watch metrics to decide whether
it is a duplicate. Only the eligible unchanged work is skipped; new steps,
care boundaries, day rollover and forced sleep/wake processing still run.

## SDK results and remaining validation

Final validation follows the latest root `AGENTS.md`: Enduro 4 only. Existing
manifest compatibility and historical wider-device evidence are retained, not
relabeled as final v0.5.1 coverage. No further backlog issues are being started.

Final runtime source freeze: `3a2c013` (earlier implementation `9132be2` and
`411e13a`). The final Enduro 4 production release build passed explicit gradual
type checking (`-Typecheck 1`) on 17 October 2026; the final development build
also returned `BUILD SUCCESSFUL`. The focused Enduro 4 QA builds use `-Typecheck 0`
and execute Garmin's compiler/linker, native VM tests and production rendering;
they are not substituted for the gradual-checked production build.

The final Enduro 4 unit run passed **32 tests, 0 failures, 0 errors**.
This includes v0.4 upgrade preservation, interrupted sessions, DEV isolation,
solar seasons/polar/date/zone fallbacks, sleep separation, dirty-save counters,
immediate navigation timer rearming and confirmed manual-location drafts.
Local log: `bin/v051-final-enduro4-tests.log`.

Final Enduro 4 rendering audit: **983 scenes, 0 failures**; sampled peak
**120,992 / 781,976 bytes**. Scenery load maximum 16ms; render excluding load
maximum 32ms on the SDK host. Log: `bin/v051-final-enduro4-layout.log`.
No other simulator profiles were run after the latest Enduro 4-only instruction.

Native Enduro 4 Glance: **60 awake/tired/nap/night scenarios, 0 failures**,
216x88 viewport, **40,336 / 61,344 bytes** sampled peak. It uses the production
read-only Glance renderer and no landscape. The bounded runner initially timed
out without flushing output despite a visible Glance; that is not counted as a
pass. A normal SDK runner plus native VM stop captured the complete audit in
`bin/v051-final-enduro4-glance-native.log`. The QA manifest was corrected to
match production's Positioning permission for its optional foreground entry;
the Glance itself does not access location. Hardware selection/timeout remains
an acceptance check, not inferred from the native rendering audit.

The exact exported Enduro 4 program (hash recorded separately) launched through
the normal SDK runner and displayed Pet scenery, Care and Details. Its native
simulator save was a fresh Mystery Egg with watch XP 0, not the historical Pip
fixture. Therefore this smoke run is NOT claimed as a real v0.5-to-v0.5.1 Pip
upgrade. Upgrade preservation is covered by the SDK regression fixtures; the
owner's actual installed save still needs the non-destructive hardware check.
Capture: `art/store/v0.5.1/captures/enduro4-final-production-export.png`.

Interactive Enduro 4 checks used the actual simulator watch buttons. Repeated
UP cues were entered separately; retry and advancement to round two worked.
The nominal 250ms neutral interval measured **234-266ms** in the clean trace
(host timer jitter), rather than claiming an exact hardware stopwatch interval.
Normal Bounce measured **3984-4016 / 2984-3000 / 2234-2266ms** per star across
its three stages. Easy measured **5985-6015 / 4985-5015 / 3985-4015ms**.
UP/DOWN movement, SELECT jumping, one Easy catch, results and Exit were observed.
This proves input/pacing execution, not physical-button comfort or gameplay fun.
Touchscreen input was not verified. Logs: `bin/v051-memory-cue-only.log` and
`bin/v051-interactive-games.log`.

Two native Steps Progress callbacks used **41,216 / 61,344 bytes**, each with
one necessary write and a 15ms coarse SDK-host elapsed time. They were more than
60 seconds apart, so they do NOT prove the native duplicate-event fast path;
that path is covered by the executable unit counters above. The isolated full
save fixture retained XP 123456, three paused sessions and inventory slot 18.
Log: `bin/v051-background-enduro4-trace.log`. These are post-reconcile memory
samples, not an instrumented peak or physical-watch CPU/power measurements.
The final trace fixture was reopened after native VM shutdown: XP 123456,
three paused sessions and inventory slot 18 remained intact
(`bin/v051-final-background-reopen-enduro4.log`). Native sleep/wake callback
delivery was not rerun in this final check; forced sleep reconciliation has SDK
unit coverage, while actual OS delivery remains a physical-watch check.

Actual Enduro 4 screenshot crops are linked from
`art/store/v0.5.1/README.md`: the exact historical v0.4/v0.5 Pip assets are
re-rendered in QA beside v0.5.1, not mislabeled historical full-app screenshots.
All 16 theme/sky combinations use the production renderer, virtual QA sky
previews and an in-memory awake pet. They show appearance, not a walking video.
Cached preview render timings were 0-16ms with roughly 114KB QA main-app use;
coarse host timings are not a physical rendering-cost benchmark.

Checkpoint: Enduro 4 passed 31 tests and 982 layout scenes before the final
cached-weather/fix-age/profiling refinements. Main audit used 118,632 / 781,976
bytes. This checkpoint is NOT relabelled as final evidence.

Measured path spans in the SDK bounds test (not sprite enlargement):

| Display / original native canvas | Horizontal travel | Vertical travel |
|---|---:|---:|
| 240 / 96 | 103px | 39px |
| 260 / 96 | 120px | 51px |
| Enduro 4: 280 / 96 | 140px | 60px |
| 390 / 144 | 190px | 76px |
| 416 / 144 | 216px | 89px |
| 454 / 192 | 195px | 65px |

All tested bounding-square corners stay inside the circular safety radius and
above the footer. The requested destinations are independent of these sizes;
larger historical AMOLED canvases necessarily have different bezel clamps.

Rejected checks are not passes: an initial procedural foliage renderer tripped
Garmin's watchdog and was replaced with compiled images. Initial new tests also
caught an overly early DEV snapshot baseline and insufficient vertical travel
on the 454px native canvas; those were corrected before accepted runs. A timed
out layout run and gradual-check diagnostics are not claimed as successes.

## Physical Enduro 4 acceptance still required

- Update the existing beta without uninstalling. Check Pip, genuine XP/history,
  evolution, friendship, inventory, collections and all three paused games.
- Check original-sized creatures across stages, broad horizontal AND vertical
  roaming, no bezel/HUD clipping, plant interactions and direct-sunlight contrast.
- Inspect all four environments and dawn/day/dusk/night. Compare settings' rise/
  set times and source/age with the actual location; try offline/SAVED/MANUAL.
- Confirm that sunset while awake does not trigger sleep, bedtime remains correct,
  morning sleep state is correct after reopening, and lights are virtual only.
- Distinguish UP / UP using the neutral gap. Judge normal Bounce and Easy pacing,
  button response, fairness, interruptions, replay and reward safety.
- Test DEV sky/time/family/care scenarios then discard; real progress/steps return.
- Confirm native Glance selection/timeout and sleep/step callbacks on hardware.
- Compare battery drain over comparable normal-use days. Simulator timing/RAM
  cannot establish physical battery use or system callback frequency.

## Primary API/method references

- https://developer.garmin.com/connect-iq/api-docs/Toybox/Weather.html
- https://developer.garmin.com/connect-iq/api-docs/Toybox/Weather/CurrentConditions.html
- https://developer.garmin.com/connect-iq/api-docs/Toybox/Position.html
- https://developer.garmin.com/connect-iq/api-docs/Toybox/Time/Gregorian.html
- https://gml.noaa.gov/grad/solcalc/solareqns.PDF
