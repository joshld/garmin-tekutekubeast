# Current source validation checkpoint

Latest source change: Issue #17 sleep interactions, after Issue #21 `2d411b1`.

## Issue #17 - sleep interactions

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
