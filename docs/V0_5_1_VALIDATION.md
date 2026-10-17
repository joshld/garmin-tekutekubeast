# v0.5.1 beta — implementation and validation record

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

On foreground entry (bounded to once per five minutes), AUTO reads
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

Final all-profile matrix, native Glance/background budgets, interactive timing
trace, artifact hashes and screenshots are recorded below when completed.

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
