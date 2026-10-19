# Current source validation checkpoint

Latest source work: Issues #14/#20 consistent pause menus and safe abandonment.

## Physical acceptance preparation - source 118bdff

Rebuilt the signed Enduro 4 owner program with `-Owner -Release -Device enduro4`
from clean `118bdff64a389efff41b9c2276a5236111751d96`, without exporting an IQ,
connecting to the watch or running any app against its saves. Artifact:
`D:\working\garmin-tekutekubeast\bin\TekuTekuBeast-Dev-Enduro4-acceptance-118bdff.prg`
(4,016,732 bytes), SHA256
`E6870E3903568545BCCCE5855A8A2C7C23D8CF59225BDF73F40825AFC9A83562`.
It is byte-identical to `bin/roaming22-owner-enduro4.prg`; reuse the existing
69 native tests, 192 roaming scenes, 480 asset comparisons and #20 battle
playthrough/layout evidence below. No simulator matrix was repeated.

Verified original Beta UUID in the PRG, public UUID absent, expected DEV methods
present and QA/test symbols absent. Derived public-key fingerprint matches pinned
`276489F20EC9F9605CADE733D7F5D60FB04E8696C5E50FF8E431F873825FCA7C`;
the SDK used the existing key, never regenerated it. Build log:
`bin/acceptance-enduro4-118bdff-build.log`. Settings remains **0.5.2 beta**;
this is a newer source acceptance program, not a relabelled/final v0.6.0 release.

Safe conditional installation and the physical procedure are in
[watch acceptance](WATCH_ACCEPTANCE.md#current-enduro-4-acceptance-build).
[#24](https://github.com/joshld/garmin-tekutekubeast/issues/24) owns proposed
v0.6.0 release gates: owner acceptance, balance disposition, targeted constrained
renderer checks and subsequently approved versioning/all-part packaging.
No physical result, migration, installation or publication is claimed. Existing
public/private IQs, app IDs, gameplay, source resources and save format are unchanged.

## Issue #22 - Nimble frames, facing and night crescent

SDK 9.2 / Enduro 4 only. The clean starting tree was `17b6a3f`.
The RAM-only roaming fixture reproduced Nimble's detached edge fragment and
reversed facing. Fixed-grid atlas extraction captured neighbouring tail pixels
in Nimble poses 1-5: 60/220/24/36/132 opaque pixels on the 96px canvases.
Only those detached components and the corresponding mirrored walk were removed
from generated Pet images. Body RGBA, native canvas, position, scale, source
atlases and V4 historical evidence remain intact. No global component filter:
other creatures can legitimately have detached hooves/effects. Other atlases
would need individual review if similar fragments are reported.

Pip/Nimble native walks face left, unlike the old selection assumption. Other
atlases have mixed-facing poses. Small per-pose facing metadata selects existing
mirrors; moving hops retain directional poses and first-leg direction uses its
actual origin. World destinations, timing, circle constraints and creature size
are unchanged. Native tests cover both poses/directions for all 14 non-egg forms.

The upper-left night object is consistent with the decorative night-progress
crescent, partly occluded by scenery. Its old sky-colour cutout painted a dark
rectangle over the lighter horizon. Drawing only the same illuminated pixels
removes that cutout; moon placement, sky, terrain and lighting rules stay intact.
The owner's exact photographs are not attached to the issue; confirmation that
this resolves the physical observation remains with #22 / #15.

New evidence: **69 native tests pass**, including 20 theme/moon-progress cases;
**192 Enduro 4 rendering scenes pass** with zero circle/footer/direction failures
(Pip/Nimble, all eight destinations, walk/hop/pause/blink transitions, LOW/NORMAL,
day/night and four themes). Manual simulator button previews inspected the
Nimble repair/right-facing walk, Pip left walk/idle/blink/look and four night
layers. The initial fixture used an incorrect 1-based scenery index and crashed;
this QA-only error was corrected. Long interactive previews exceeded the bridge
timeout, so the final audit exits automatically and records its complete result.

`scripts/verify_v051_art.py` passes 480 historical-body/canvas comparisons with
explicit Nimble removal counts at each size; all game/Glance images and other
Pet pixels remain unchanged. Signed public/owner Enduro builds pass; public
symbol checks exclude DEV and QA, owner retains DEV. Existing public-input tests,
Glance and background-specific evidence are reused: those paths/data/assets did
not change. No device matrix, physical-watch run or Store export was performed.

Resource implications: still eight cached Pet poses and one terrain layer, no
new runtime transforms, per-frame arrays, resources or timers; moon draws three
blocks instead of four. Enduro Nimble PNGs shrink by 222 bytes (compressed file
size, not a RAM saving). Instrumented audit sampled 145,104 / 781,976 bytes;
this is not a matched baseline comparison, allocator-wide peak or battery test.
Both identities/configuration, saves, gameplay and existing Store IQ hashes are
unchanged. Hardware visual acceptance and physical battery measurements remain
unverified.

Evidence: `tests/roaming/monkey.jungle` (set `autoExit=false` for interactive
previews), `bin/roaming22-audit.log`, `roaming22-final-unit-enduro4.log`,
`roaming22-public-build.log`, `roaming22-owner-build.log`. Earlier baseline and
interactive preview logs contain timeout markers, not automated passes.

## Issue #23 - resource efficiency and simplicity

Baseline `b6c3d6c`, Enduro 4 / SDK 9.2 only. The isolated, RAM-only runtime
audit uses production render/commit/refresh paths; one transaction per callback
avoids measuring an unrealistic batch under the UI watchdog. Initial QA batching
tripped that watchdog, not a production path. Five scenes render twelve times
each; all retain their sprite references. Heap samples include instrumentation
and are lower bounds, not allocator-wide peaks or physical power measurements.

| Matched QA work | Baseline | Improved |
| --- | ---: | ---: |
| 30 changed battle commits: root deep copies | 60 | 30 |
| Deep-copied dictionaries/arrays | 660 | 330 |
| Necessary battle save writes | 30 | 30 |
| Sampled transaction peak, bytes | 141,896 | 139,760 |
| 100 unchanged commits: copies / writes | 0 / 0 | 0 / 0 |
| Bounce / Memory idle redraws per 30 callbacks | 30 / 30 | 20 / 20 |
| Trail idle redraws per 30 callbacks | 30 | 25 |
| Battle renderer sampled peak, bytes | 150,208 | 150,224 |
| Public-input compiled code / data, bytes | 67,466 / 27,976 | 67,475 / 27,976 |

Battle commits now use one independent snapshot for Storage and comparison;
mutable live data remains separate. Failure retains the previous baseline and
disk record for retry. Mini-game start dirty keys follow actual pose/caption
changes; timer cadence (1s), elapsed ticks, all animations, active games and
results stay unchanged. No generic cache/framework, save schema or rule change.

Pet/game renderer samples are effectively flat (+16 bytes): Pet 145,184 ->
145,200; game starts 142,856 -> 142,872, of 781,976 usable bytes. Coarse changed
commit work totaled 207 -> 106 ms in these SDK-host samples; render timings
varied in both directions. Neither is a physical-watch CPU/battery benchmark.
SDK Active Memory, separate public-input production-entry QA runs: observed
foreground peak 131.5 -> 131.7 KiB, peak objects 334 -> 340, and zero new resource
allocations on the last steady Pet update in both. These live saved-pet runs
have different time/GC histories, not controlled whole-app peak comparisons.
The compiled code/data rows above are exact SDK report values; `.prg` file size
also includes assets and is not runtime RAM. No overall heap reduction claimed.

Final checks: **67 native tests + 5 public tests pass**, including snapshot
nested isolation, failed-write retry, unchanged commits, exact idle pose/caption
transitions, reward/step integrity, save migrations, DEV and battle-v1 goldens.
Signed public/owner foreground builds pass; public symbols exclude DEV, native
tests/vectors and resource harnesses, while owner retains DEV. Fixture/data drift
checks pass. Prior layout, Glance and background evidence is reused: rendering,
geometry, resources and those VM scopes are unchanged. No Fenix 6S Pro rerun was
warranted by these two foreground call-site changes; no matrix was run.

Review found existing timer hide/inactive stops, dirty saves, one-layer scenery,
sprite caches, minute/date/location astronomy cache and no-GPS policy sensible.
Portable rule/data boundaries remain intact; no broad refactor was justified.
Deferred, not assumed defects: hidden-parent sprite-handle retention, occasional
full ID-catalog arrays, redundant Pet clear and maintenance-sensitive fail-closed
public source transforms. Pet rendering / Issue #22 was not modified. Physical
battery/callback frequency remains unmeasured (hardware acceptance in Issue #9).

Logs: `bin/resource23-baseline.log`, `resource23-improved.log`,
`resource23-final-unit-enduro4.log`, `resource23-public-tests.log`,
`resource23-public-build.log`, `resource23-owner-build.log`. Compiled/peak/object
figures were inspected in SDK Active Memory for the public-input QA programs.
Both UUIDs/key configuration, all 72 names, v1 definitions/replay vectors, pet
saves and existing public/private Store IQ hashes are unchanged. No release
export, upload, publication, multiplayer or phone/firmware work occurred.

## Issue #20 - offline playtesting and polish

Completed on Enduro 4 / SDK 9.2 only; no full compatibility matrix. Reused the
already-passing 100-scene battle audit after interruption (zero clipping/overlap,
150,320 / 781,976 bytes peak audit heap), rather than rerunning it.

Six complete sessions used actual production battle screens and simulator watch
button mappings (SELECT/UP/DOWN/BACK), under the isolated QA matrix identity:

| Player | Turns | Result | Battle XP |
| --- | ---: | --- | ---: |
| Pip | 4 | Victory | 12 |
| Nimble | 4 | Defeat | 5 |
| Adult Grove / Mossbit | 4 | Victory | 12 |
| Champion Ember / Pyrolynx | 4 | Victory | 12 |
| Legendary Tide / Leviathan | 4 | Victory | 12 |
| Legendary Wisp / Starweaver | 4 | Victory | 12 |

Reviewed each form's four named moves, HP bars, wrapped names, reactions and
results. Nimble exercised guard, buff and signature recovery; BACK then a full
QA VM exit/relaunch resumed turn one with both fighters exactly 29/46 HP before
finishing. The QA harness retains only isolated per-fixture battle records;
pet fixtures stay in RAM. It supplies encounters for playtesting, not proof of
natural discovery. Four-turn samples are short/bounded; automation delays are
not a trustworthy 30-60-second human pacing or enjoyment measurement.

- Fixed confusing signature recovery: keep the move grid visible and show
  remaining own moves. Compact-grid hints explain hit/protection/two-hit boost.
- Existing views now discover opportunities after fresh foreground step catch-up.
  A match claimed across midnight refreshes daily rewards, rolling care first
  so yesterday's care cannot generate new-day encounters. Claimed results remain
  no-op/idempotent, including on later days. No new timer or background work.
- Final native suite: **65 passed**, including new hint/resumed-discovery,
  midnight/care/cap/rollback, terminal-before-claim reload and balance-survey
  tests, plus existing queue/step/reward/sleep/DEV/migration/golden regressions.
  Public-input suite: **5 passed**. Signed owner/public Enduro 4 foreground
  release-mode builds passed; public absence tests retain DEV separation.
- Survey: 18 forms x 8 seeds x 3 strategies = **432 native-engine matches**.
  Direct: 125 wins/19 losses, 4-6 turns; signature-cycle: 141/3, 3-5 turns;
  buff-cycle: 35/109, 4-6 turns; no draws. Identical matchups compare strategies,
  not population win rates. Signatures dominate repeated buff setup; record as
  a beta balance concern, not proof every buff use is wrong. Versioned v1
  definitions, RNG, golden outcomes, rewards and evolution/step balance unchanged.
- Logs: `bin/battle20-playtest-session1.log`, `battle20-playtest-session2.log`,
  `battle20-polish-layout.log`, `battle20-polish-final-native.log`,
  `battle20-polish-final-public.log`, `battle20-polish-owner-build.log`,
  `battle20-polish-public-build.log`. Detailed output remains ignored locally.

Both application/signing identities, pet schemas and existing public/private
Store IQ SHA256 hashes are unchanged. No package export/upload/publication or
physical-watch test occurred. Existing Glance/background evidence is reused;
these foreground-only changes do not newly validate those VMs or older devices.
Offline battles are an owner-playtest beta candidate, not a final balance/fun
sign-off. Issue #20 retains physical pacing/readability/interruption/battery,
older-renderer release checks and unresolved future multiplayer acceptance.

## Issue #20 - portable foundation follow-up

- Canonical platform-neutral `data/battle-v1.json` now supplies the native roster,
  IDs, effects and numeric constants through a small build-time generator. Builds
  and structural CI fail on drift. No runtime JSON loading or second rules engine.
- Pure snapshot import/export plus `data/battle-state-v1.schema.json` define the
  versioned serialization boundary; unknown versions, malformed values and
  inconsistent state are rejected without mutation or silent seed repair.
  JSON codecs remain platform-owned; the kernel uses only language/container
  primitives, no Garmin hardware, UI, storage, clock or communications APIs.
- Enduro 4 / SDK 9.2: 61 native tests passed (56 existing plus five portability
  tests). Four full-state replay scenarios cover nine commands, AI, all four move
  roles, cooldown rejection, RNG consumption, affinity/bond/training, damage
  truncation, victory/defeat/draw and XP/mastery. Four stat fixtures include egg
  rejection, personality ties and training/level bounds. Every intermediate
  replay snapshot crosses export/import before the next command.
  Eight reward-policy vectors cover practice, incomplete matches and the daily
  cap; the Garmin transaction owner consumes the same pure eligibility rule.
- Five public-input tests passed on the final source, including battle claims.
  Signed owner/public Enduro 4 foreground builds passed with public DEV exclusion
  and owner DEV retention. IDs, save formats, version and old Store IQs unchanged.
- Final evidence: `bin/battle20-portable-complete-final-unit-enduro4.log`,
  `battle20-portable-public-tests.log`, `battle20-portable-owner-build.log`,
  `battle20-portable-release-build.log`. Prior 100-scene rendering evidence below
  is reused: UI/assets are unchanged, not claimed as a new layout run.
- JavaScript/C/C++ arithmetic, state, effect and RNG parity rules are in the
  [architecture contract](ARCHITECTURE.md#portable-battle-protocol-v1). No JS/C++
  engine, phone app, firmware or networking was built; those future implementations
  must pass these same vectors before parity can be claimed. No physical-watch
  test, full-device matrix, Store export/upload or publication.

## Issue #20 - playable integration (milestones 2-4)

- Actions > Play > Wild battles: named-move combat, temporary HP, queued daily/
  care/adventure/genuine-step encounters, practice, postpone/decline, Battle XP,
  technique mastery and wild journal. Separate atomic `battle.v1` owns turns and
  claims; canonical pet data, existing reward slots and evolution are unchanged.
  DEV uses an isolated copy. No new background work, GPS, alerts or networking.
- Enduro 4 / SDK 9.2: all 56 native tests passed, including the original 45,
  five deterministic-engine, five transaction/encounter and one view-lifecycle
  tests. Coverage includes baseline/catch-up/dedup, zero-step routes, bounded queue/
  rewards, clock rollback, atomic claims, practice, reopen, sleep and DEV isolation.
- Actual production-renderer QA: 100 scenes, zero clipping/overlap failures,
  all 18 forms/four choices, techniques, outcomes and sleep/motion states.
  Peak audit heap 146,896 / 781,976 bytes (not a full-stack/battery benchmark).
  Cached 16px vector move text enables a readable 2x2 grid; unsupported vector
  renderers use a full-width named-move selector rather than clipping long words.
- Computer-use skill: visually inspected the grid, button selection, signature,
  normal damage/opponent turns and victory with +12 Battle XP in the RAM-only
  fixture. No physical-watch validation. Pause/reopen/claims are native transaction
  tests, not an agent-operated physical-watch pause/reopen claim.
- Signed Enduro 4 owner/public release-mode foreground builds passed. Public DEV/
  test symbols are absent and owner DEV retained. IDs, signing configuration,
  version, manifest/resources and both recorded Store IQ hashes are unchanged.
  New local programs: `bin/battle20-owner-enduro4.prg` and
  `bin/battle20-public-enduro4.prg`; these are not Store packages.
- All five public-input native tests passed, including a new battle save/claim
  test with DEV absent and canonical pet data unchanged.
- Evidence: `bin/battle20-final-final-unit-enduro4.log`,
  `battle20-layout-verified.log`, `battle20-owner-build.log`,
  `battle20-public-release.log`, `battle20-public-tests.log`.
  Earlier Long/index and layout/QA-counter failures were corrected; their local
  logs remain, not counted as passes. Structural/vector and 176 doc-link checks
  passed. Background/Glance renderer/rules are unchanged; their prior checks are
  reused, not rerun. The battle document is never loaded by either entry point.
- Physical controls, text size/MIP readability, fun/pacing and battery remain
  owner acceptance items. Other profiles/vector-font fallback were not runtime
  tested in this Enduro-only scope. No full matrix, export, upload or publication.

## Issue #20 - milestone 1: deterministic engine

- Exact 18-form/72-name roster and stable IDs, no egg battles; copy-pure seeded
  turns, AI, temporary HP, guard/buff/cooldown, family/personality/friendship and
  technique/XP modifiers. Results and reward calculations are bounded and do not
  touch pet growth or genuine step XP. No networking or live UI hook in this
  milestone; it is an engine checkpoint, not a playable Store update.
- Enduro 4 / SDK 9.2: build and all 50 native tests passed (45 prior + five
  engine tests). JSON roster/damage probes cover replay, resume, purity, effects,
  cooldown rejection, AI bounds, no eggs, rare gating and progression limits.
  Evidence: `bin/battle20-m1-final-unit-enduro4.log`.
- Existing application IDs, signing/version, Store packages and canonical save
  remain unchanged. No physical-watch test or full-device matrix.

## Prior Issue #17 - sleep interactions

- Visible-but-blocked care/play actions give the exact silent notice; explicit
  Wake Up overrides only the current nap/night. Temporary 0-2-point happiness
  overlay follows the tested nap bell without changing saved base joy/personality.
  Natural waking, next-night schedule, clock/zone changes, save/reopen, DEV
  isolation, game checkpoints and once-daily Rest limits have native coverage.
- Enduro 4 / SDK 9.2 only: 45 native tests, four public-input tests, 62 focused
  production-renderer scenes (zero layout failures), signed owner/public
  release-mode foreground builds. Final results/logs below cover the save-memory
  correction too; no full device matrix was run.
- Using the computer-use skill, observed the sleeping pose, blocked Clean notice,
  visible Wake Up row and immediate unconfirmed wake/reaction in the simulator.
  Sky stayed nighttime and poop was not silently cleaned by the blocked action.
  QA used isolated fixture identities/RAM, never a real pet.
- Native Glance: 60 awake/tired/nap/night scenes, zero layout failures,
  37,272 / 61,344 bytes. Foreground sleep-layout peak: 132,216 / 781,976 bytes.
- The native background sleep stress check exposed serialization OOM with three
  paused games. The store now releases its obsolete comparison snapshot before
  serializing a changed atomic save; a failed write keeps disk data intact and
  leaves a null baseline so retry is not suppressed.
  Corrected native sleep callback: 48,048 / 61,344 bytes, two writes, SDK timing
  0 ms (timer resolution, not zero execution cost). Fixture XP 123456, three
  pending games and inventory 18 remained intact. The background service itself
  is unchanged; real OS event frequency and battery cost are not measured.
- Sleep/grump expiry is read-only; no new timers, resources, GPS or background
  alerts. Tired idle retains the five-second cadence; brief wake/grump reactions
  use one second with motion enabled. Hidden-view timer shutdown is unchanged.
- Public symbols exclude DEV/test controls; owner retains them. Both UUIDs,
  signing identity, version, production manifests/assets and the recorded
  public/private Store IQ hashes are unchanged. No export, upload or publication.
- Ignored evidence: `bin/sleep17-verified-final-unit-enduro4.log`,
  `sleep17-layout.log`, `sleep17-glance-initial.log`, `sleep17-background-final.log`,
  `sleep17-public-tests.log`, `sleep17-owner-build.log`, `sleep17-release-build.log`.
  Structural preflight, JSON-vector consistency and 176 local Markdown links
  passed. Earlier failed runs are retained locally, not misreported as passes.
- Physical Enduro 4 buttons/postures, watch schedule/time-zone behavior, real
  sleep/wake callbacks and battery still require owner acceptance; see the
  [sleep checklist](WATCH_ACCEPTANCE.md). Other device checks were not rerun.

## Prior Issue #21 - night lighting

- Explicit AUTO / ON / OFF, selected/applied labels, remaining minutes and silent
  one-hour manual overrides. Existing save keys and bedtime preference retain
  their meanings; no migration, fake activity or sleep-state mutation.
- Native sprite dimming is capability-guarded; ON adds three local drawing
  primitives. No new assets/buffers/resource loads for night ON/OFF, background
  work, GPS, astronomy invalidations or timers. Cached tint options avoid
  per-frame option allocation. Normal motion/lifecycle redraw cadence is retained.
- Enduro 4 SDK 9.2: 39 native tests passed, including exact expiry, reopen, legacy
  settings, clock rollback, no-op reads, DEV isolation and day/night independence.
- Focused production-renderer QA: 70 scenes, zero layout failures; 32 cover all
  four environments x four sky phases x ON/OFF, plus 38 menu rows. Sun/moon
  coordinates stay unchanged and night toggles retain the terrain resource.
  Peak foreground heap 124,384 / 781,976 bytes. Recorded scenery-pass timing
  max 31 ms excludes local-light/sprite drawing; not a full-frame/battery benchmark.
- Visually inspected actual simulator ON/OFF in all four nighttime environments
  using the computer-use skill. Creature tint, unchanged sky and readable needs/
  cleanup indicators were observed, not inferred from structural checks alone.
- Structural preflight passed after correcting its stale pre-Issue-19 activity
  lookups to the extracted modules. No runtime behavior changed for that repair.
- Four public-input tests and signed Enduro 4 owner/public release-mode builds
  passed. Symbol inspection confirms public DEV/test exclusion and retained
  personal DEV. New local foreground programs are `bin/lighting21-owner-enduro4.prg`
  and `bin/lighting21-public-enduro4.prg`; these are not Store exports.
- Logs: `bin/lighting21-final-final-unit-enduro4.log`,
  `lighting21-audit-final.log`, `lighting21-public-tests.log`,
  `lighting21-owner-build.log`, `lighting21-release-build.log`.
- Public/private UUIDs, key, version, manifest and both existing Store IQs are
  unchanged; both recorded IQ SHA256 hashes were rechecked. No export, upload,
  physical-watch test or other-device matrix.
  Real-watch contrast and battery behavior still need owner acceptance; older
  rendering fallback is guarded but was not simulator-tested in this scope.

## Prior Issue #19 source checkpoint

Architectural milestones `3e75e22`, `6554747`, `386379b`:
Enduro 4 only: 37 native tests, four public tests, 473 layout scenes and signed
foreground builds passed; native background callback results are below.
These are prior executed checks, not reruns for documentation consolidation.

Release artifacts and per-device evidence are separate from current source:

- [Compatibility guide and CSV](COMPATIBILITY.md): recorded 47-profile expansion.
- [Public v0.5.2 artifact/identity](releases/v0.5.2/PUBLIC_RELEASE_0_5_2.md) and
  [private Developer Beta export](releases/v0.5.2/DEVELOPER_BETA_0_5_2.md): exact hashes.
- Earlier [v0.5.1](releases/v0.5.1/V0_5_1_VALIDATION.md),
  [v0.5.0](releases/v0.5.0/V0_5_VALIDATION.md),
  [v0.4.0](releases/v0.4.0/V0_4_VALIDATION.md) and
  [raw v0.5 logs](validation/v0.5/README.md): historical evidence only.
- [Watch acceptance](WATCH_ACCEPTANCE.md): user reports and unresolved hardware checks.

Scope: behavior-preserving portability preparation after v0.5.2. No release,
new devices, Store upload or work on #21/#17/#20. See [code map](ARCHITECTURE.md).

## Milestone 1 — progression boundary

Committed/pushed as `3e75e22`.

- Extracted deterministic growth, evolution, mastery and family selection;
  State retains migrations, DEV overrides, calendar/time reads and transactions.
- Added 15 JSON golden cases and native purity/passive-growth tests. Preserved
  the existing care-only egg gate (care alone at eight hours does not hatch an
  egg below the original growth gate); this cleanup does not rebalance it.
- Enduro 4 / SDK 9.2: 35 native tests, 473 layout scenes, four public-build tests
  passed. Tests cover existing migration, DEV isolation, rewards and step catch-up.
- Native Steps Progress callback with stress fixture: 44,032 / 61,344 bytes,
  two writes, 15 ms SDK timing; XP 123456, three pending games, inventory 18.
  Prior release callback used 43,272 bytes; extraction costs 760 bytes, within
  budget. This is not a physical-watch battery measurement.
- Ignored detailed logs: `bin/cleanup-m1-device-matrix.json`,
  `cleanup-m1-enduro4-tests.log`, `cleanup-m1-enduro4-layout.log`,
  `cleanup-m1-public-tests.log`, `cleanup-m1-background.log`.
  Initial new characterization assertion was corrected to match the unchanged
  care-only gate; all 33 pre-existing tests passed on the initial run too.

## Milestone 2 — activity boundary

Committed/pushed as `6554747`.

- `GarminActivity` normalizes optional fields once per background callback;
  `BeastActivityRules` owns deterministic ledger/reward calculations. State keeps
  lazy catch-up, day rollover, DEV guards and atomic saves.
- Enduro 4: 36 native tests and four public tests passed. JSON traces cover
  baselines, duplicate/rolled-back totals, unavailable counters and reward caps.
- Actual Steps Progress stress callback: 44,800 / 61,344 bytes, one write and
  one unchanged-cache skip, 15 ms coarse SDK timing. No new polling/allocating
  activity snapshot containers. Legacy generator excludes both helpers from
  constrained background scope; no other-device simulator pass is claimed.
- Logs: `bin/cleanup-m2-pass-final-unit-enduro4.log`,
  `cleanup-m2-public-tests.log`, `cleanup-m2-background.log`.
  New test assertions were corrected for Monkey C Long/Number equality and null
  handling; production rules did not need changes to satisfy the golden traces.
- M1 layout evidence reused: this milestone changes no rendering or geometry.

## Milestone 3 — mini-game calculation boundary

Committed/pushed as `386379b`.

- Extracted timing, cue selection, seeded random/trail transitions and loot
  selection into `BeastGameRules`. Input, rendering, durable sessions, energy
  deductions, inventory updates and duplicate-claim prevention retain their
  original owners and behavior.
- Enduro 4: all 37 native tests and four public tests passed. Nine JSON game
  vectors plus repeated-move/timing/purity assertions exercise the production
  module. Existing migration, interrupted-session, reward, DEV, care and
  reconciliation tests pass unchanged.
- Final production-renderer audit: 473 scenes, zero failures; foreground peak
  124,808 / 781,976 bytes, scenery render maximum 31 ms (coarse SDK measurement).
  The first layout launch returned only the SDK prompt; reran the already-built
  program, not the successful units or a device matrix.
- Signed Enduro 4 owner and public release-mode programs compile. Debug-symbol
  inspection confirms owner DEV remains, while public owner controls and test
  vectors are absent. New local outputs: `bin/cleanup-final-owner-enduro4.prg`
  and `bin/cleanup-final-public-enduro4.prg`; not exported Store packages.
- Final native Steps Progress stress callback: 45,344 / 61,344 bytes,
  one save write, one unchanged-cache skip, 16 ms coarse SDK timing. This is
  2,072 bytes above the pre-cleanup callback, leaving 16,000 bytes headroom.
  Existing fixture XP/inventory/three paused sessions remain intact. The
  computer-use skill triggered native events in an isolated QA application;
  production storage was not cleared or modified.
- Logs: `bin/cleanup-final-pass-enduro4-tests.log`,
  `cleanup-final-layout-retry.log`, `cleanup-final-public-tests.log`,
  `cleanup-final-owner-build.log`, `cleanup-final-release-build.log`,
  `cleanup-final-background.log`. New test fixture compile-name collision was
  corrected before the passing run; no gameplay changes were needed.

## Scope left deliberately intact

The portable boundaries and shared test data are preparation, not a PWA/ESP32
port. Care/day/session orchestration still lives in State, and view inheritance
and build-time DEV source-span removal remain documented hotspots. Further
extraction should be driven by a concrete consumer, not a speculative framework.
Glance source, cache contract, resources and launch scopes are unchanged; prior
native Glance evidence is reused, not reported as a new run.

Both UUIDs, key, save schema, 47-profile manifest, version and signed v0.5.2
release artifacts remain unchanged (both IQ SHA256 hashes rechecked). No
physical-watch tests claimed. Other
devices retain prior evidence; they were not rerun for this Enduro-only cleanup.

## Documentation consolidation (Issue #19 final milestone)

README/AGENTS route everyday work to seven current guides. Superseded plans
are in `archive/`; versioned release/validation records are in `releases/`.
Gameplay combines the former evolution guide and README feature detail;
physical checklists now have one current owner. Historical hashes, raw logs,
screenshots and compatibility CSV are preserved. All 175 local Markdown links/
anchors passed; the guide inventory matches all 47 manifest profiles. Historical
hashes/recorded numbers and the Markdown-only diff were checked; no SDK build,
simulator, matrix, artifact export or watch/Store change was performed.
Issue #19 has no essential remaining cleanup work; deliberate future seams
and physical acceptance remain separate from this completed scope.

## Issue #20 - physical battle UI feedback (2026-10-19)

Enduro 4 / SDK 9.2 only. Persistent YOU/WILD labels identify identical fighters.
Committed turns are presented as YOU MOVE → YOU RESULT → WILD MOVE → WILD
RESULT, using unchanged actual move names. Damage remains below its recipient;
guard/buff results stay below the actor, with two rows when results share a side.
HP bars reveal each saved event at its result stage instead of jumping together.
Action/result dwell is 800/1200ms; Motion OFF disables movement, not readability.
SELECT/tap repeats neither advance the sequence nor restart its timer. BACK/
hide stops timers; reopen visually replays the last unclaimed committed exchange
with REPLAY. No recalculated turns, new save fields or presentation save writes.

**73 native tests pass**, including all four move roles, staged HP, repeated
input/timer reuse, interrupted replay, exact lethal HP and single reward claims.
**258 simulator layout scenes pass**: all 72 named selections/action/results,
identical art/stats, guards/buffs, both actors, Motion OFF/LOW/NORMAL, replay,
KO, results, sleep and defensive healing/miss display fixtures. The v1 engine
still has no healing/miss mechanics; only their rendering fallback is tested.
Public Enduro 4 compilation passes with DEV excluded. No device matrix/export.

Computer-use simulator button observations: identical Nimble fighters, six-turn
victory ending YOU 9/46, WILD 0/46 and +12 Battle XP. Exercised Brave Bounce,
Whirlwind Dash, Quick Pounce and Swift Dodge. Observed signature damage -18 HP
under WILD before its named Quick Pounce and -15 HP under YOU; guard and its
following -3 HP remain stacked under YOU. Long names, bars and all four moves
were readable. The manual bridge exceeded its 180-second bound during tool-
driven interaction; its timeout is **not** an automated pass or a measured watch
battle duration. The separate native/layout logs contain complete passing results.
Stopped the isolated QA app afterwards; no real pet/watch storage was accessed.

Resource impact: same three compact poses per fighter, cached font, no new
bitmaps/buffers or background work. One Timer is reused for four one-shot
transitions per normal exchange (previous NORMAL animation used eight callbacks),
then the existing 5-second idle sleep check. HP reconstruction visits at most
two committed events; no snapshot copies per frame. The move-list allocation is
skipped during feedback. QA sampled heap 153,000 / 781,976 bytes; the expanded
harness is not a matched baseline, allocator-wide peak or hardware battery test.
Rules, 72 names/data/goldens, AI, rewards, storage schema, identities, signing
and existing Store packages are unchanged. Prior physical persistence acceptance
was reported by the owner; this new UI still needs owner readability/pacing and
battery acceptance. Multiplayer and balance decisions remain open in #20.

Evidence: `bin/battleui20-native.log`, `battleui20-layout.log`,
`battleui20-{unit,layout,manual,public}-build.log`; `battleui20-manual.log` is
timeout-marked visual observation, not an automated pass. Reproduce with
`tests/battle/monkey.jungle`; SELECT during audit enters the RAM-only Nimble
scenario, while an untouched run exits after all 258 scenes.

## Issue #14 - registered inputs and interruption safety (2026-10-19)

Enduro 4 SDK 9.2 native suite: **76/76 PASS**. New tests exercise the actual
UP/SELECT/DOWN delegate mappings, repeated UP cues, expected/received failures,
old sessions without feedback fields, all three games' inactive/active/hide/stop
paths, stalled timers, saved timing/seed/cursor, consumed resume input and the
500 ms frozen readiness gate. Repeated callbacks do not deduct energy or award
rewards again. Existing rules, save upgrades, step reconciliation and sleep
tests remain passing. No game-rule or pet-save version change.

Focused rendering audit: **44 scenes, zero failures**, including all expected /
received input combinations, timeout, repeated cues, legacy sessions and all
three pause/readiness screens. Sampled audit heap: **156,472 / 781,976 bytes**
(not a production peak measurement). An initial pause-footer truncation was
fixed before the final passing run. Signed public Enduro 4 compile passed with
Developer Mode excluded. No device matrix, IQ export or release change.

Manual simulator observation confirmed BEAST versus YOU phases, two UP presses
advancing separately to 1/3 and 2/3 with dark UP highlights, and an incorrect
DOWN displaying NEED: SELECT / GOT: DOWN beside the actual DOWN highlight.
The manual runner timed out while navigating simulator interruption controls;
it is visual evidence only, not an automated interruption pass. Lifecycle,
reopen and timer-stall assertions above ran natively in the simulator. Real
notifications, calls, alarms, dismissal-button behaviour and watch readability
still require physical Enduro 4 acceptance.

Garmin documents lifecycle/activity callbacks, but no universal alert-suppression
API. Timers stop while hidden/paused, and restored sessions require SELECT;
overlays that leave activity and timer delivery unchanged cannot reliably be
detected. See [gameplay/API limitations](GAMEPLAY.md#alerts-and-mini-game-resume).
No DND writes, new sensors, bitmaps, background work or independent timers.
Brief input/readiness feedback reuses the existing 250 ms foreground timer;
unchanged visuals avoid redraws. Three optional memory-feedback fields use
backward-compatible session defaults. Hardware battery impact is unmeasured.

Evidence: `bin/game14-native.log`, `game14-layout.log`,
`game14-{unit,layout,public}-build.log`; `game14-manual.log` is timeout-marked.
Reproduce the RAM-only visual/button fixture using
`tests/game-feedback/monkey.jungle` as described in [BUILD.md](BUILD.md).

## Issues #14/#20 - consistent pause menus (2026-10-19)

Enduro 4 SDK 9.2: **80/80 native tests PASS**, **55 mini-game layout scenes**
and **266 battle scenes**, both zero failures. Signed Owner release-mode and
public release-mode foreground builds PASS; public exclusion guard confirms
DEV absent. Initial 79/80 run exposed an uncommitted test fixture's Energy
setup being correctly reloaded away on reopen; fixture fixed, final 80/80 above.

Shared lightweight UP/DOWN/SELECT choices default to Resume; all timers stop
while paused. Resume retains gameplay state and a frozen 500ms readiness gate.
BACK opens the menu; explicit Exit now abandons rather than postpones. New Game
invalidates the old session without a reward/refund; Tiny Adventures confirms
the additional Energy (or no-loot scouting). Battle restart confirms/spends
the next encounter, refusing when none is available; practice stays reward-free.
An ongoing abandonment gives no consolation XP, mastery or result. A committed
terminal battle settles its existing normal reward once before removal.

New native checks cover navigation/cancel, restart/exit, hidden/repeated input,
old-ID rejection, additional/no Energy, no spare encounter, no free retries,
practice, saved reopen, frozen turn/feedback and terminal claim deduplication.
Existing rule/golden, save, sleep, step-ledger and DEV-isolation tests also pass.
No battle rules/72 moves, save schema, IDs/key, assets, DND or Store IQ changes.
Sampled QA heap: games 159,776 / 781,976; battles 158,544 / 781,976 bytes (not
production peaks or matched before/after battery measurements). No new bitmap
cache/timer or background task; battle readiness reuses its bounded timer.

Evidence: `bin/pause-native.log`, `pause-games-layout.log`,
`pause-battle-layout.log`, `pause-{unit,games,battle,owner,public}-build.log`.
These are native SDK/simulator assertions/render checks, not physical input or
notification delivery acceptance. Owner still needs to check pause navigation,
restart cost/exit clarity and alert dismissal on Enduro 4; cold battle reopen
replays committed feedback without executing turns, while same-view interruption
retains its feedback position. No full matrix, IQ export or publication.
