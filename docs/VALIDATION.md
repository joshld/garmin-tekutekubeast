# Current source validation checkpoint

## Care rebalance - 2026-10-31 (Issues #25/#26)

- Actual SDK 9.2 native execution: **110 Enduro 4 tests passed**; **11 focused
  Fenix 6S Pro care/storage tests passed**. Includes migration, difficulty/time
  switching, 1/3/7/14-day absences, caps, digestion, cleaning, rollback/reopening,
  sleep, family neutrality and existing progression/battle/session regressions.
- Final care-menu navigation after visiting scenery settings was rechecked
  separately: one selected native test passed.
- Real SDK Storage tests verify independent deserialization, write failure,
  post-write snapshot failure, retry, snapshot isolation and unchanged-save skips.
- Actual Enduro 4 renderer: **972 scenes, zero failures**, covering ten themes,
  four palettes, both lighting modes, Pip/Nimble and all waste counts 0-5, plus
  environment menu labels. Sampled foreground heap **163,240 / 781,976 bytes**;
  this is a sample, not allocator-wide peak. Original poop dimensions/slots remain.
- Background stress initially reproduced serialization OOM. Foreground actions
  now extend the smaller background core; unused game rules stay foreground.
  Storage avoids a third working copy and snapshots after serialization. No save
  format/identity change; sleep energy stops sampling when already saturated.
- Actual background VM (isolated QA temporal trigger calling production reconcile):
  three paused games, 24-hour catch-up, six mature food units, natural waste and
  initial energy zero passed at **48,352 / 61,344 bytes sampled**, two writes,
  SDK timer **15 ms**. XP 123456, three games and inventory 18 preserved; three
  poops/two food-waste events committed. Previous full-energy case also passed
  (48,656 bytes, with extra QA instrumentation). Timings are simulator samples,
  not physical CPU/battery measurements. No new production timer/registration.
- Signed release-mode owner Enduro 4 and public Enduro 4/Fenix 6S Pro device
  builds pass; public DEV/test exclusion remains enforced. UUIDs, signing setup,
  47-profile manifest, artwork and existing Store packages unchanged. No Store export,
  physical installation, publication or full device matrix.
- Glance compiles; care projection/mood priority have native coverage. Its live
  launch/memory recheck remains **unverified**: computer control failed to start
  (missing kernel-assets path), and the CLI Glance attempt produced no audit.
  Physical upgrade, mode pacing, sunlight/night visibility, Glance and battery
  acceptance remain open; no physical-watch testing was performed.

### Balance scenarios (14 simulated days)

Each visit uses available free meals, up to three daily pats, and one Clean per
poop. No mini-games/snacks/toys rescue these scenarios. Steps are simulated inputs
to the genuine-ledger API, never changes to Garmin's actual counter.

| Scenario | Lowest food / joy | After final care |
| --- | --- | --- |
| Normal, inactive, visits every two days | 35 / 41 | 75 / 65 |
| Normal, 5,000 steps/day, daily | 53 / 54 | 100 / 100 |
| Normal, 10,000 steps/day, daily | 50 / 55 | 100 / 100 |
| Normal, runner 20,000-40,000/day | 50 / 55 | 100 / 100 |
| High Maintenance, inactive, twice daily | 60 / 55 | 100 / 100 |
| Normal, returns once/week | 10 / 17 | 50 / 41 |

Requested food/joy decay rates are retained exactly. The 72-hour absence cap and
recoverable floors bound neglect; returning players can use existing games and
toys to recover further. Smaller food/joy gains and bounded toy rewards retain
meaningful care without increasing progression thresholds or requiring activity.

Evidence: `bin/care-{build,native,focused-native,fenix6spro-native,background-final,
scenery-native,preflight}.log` and `bin/care-*-build.log` (ignored local logs).
Reproducers: `tests/care/source`, `tests/care/background/monkey.jungle`,
`tests/family/source`, `tests/scenery/monkey.jungle`; normal build guidance is in
[BUILD.md](BUILD.md). Existing historical evidence below is preserved.

## Family variety - 2026-10-31 (Issue #25)

- Seven activity-neutral affinity tests plus existing Enduro 4 native regressions:
  **99 passed, 0 failed/errors**, actual SDK 9.2 simulator native execution.
- Seven-day production care/game/session routines reached all four families with
  0/6,000/40,000 simulated steps/day and both care/play orders; duplicate claims,
  fair partial ties, additive migration, save/reopen and adult locks passed.
- Logs: `bin/affinity-build.log`, `bin/affinity-native.log` (local, ignored).
  No real pet access, physical-watch testing, package export or Store changes.

## Signed public 0.6.1 package (2026-10-30)

Source milestone `95c428043d62fa5378247b16904d8323cab83c30` exported with SDK 9.2:
**72/72 hardware parts / BUILD SUCCESSFUL**, existing 47 advertised SDK profiles.
Public UUID `53C660EBC4454BCF9292E5591EEC18DA`, original pinned signing key,
RSA-SHA256 manifest signature, complete archive extraction, exact part coverage,
embedded `0.6.1 beta` and absence of DEV/QA controls in every program's symbol
table verified. SDK per-part signatures present; raw PRG signatures were not
independently checked. Both identities and prior artifacts remain unchanged.

Artifact: `D:\working\garmin-tekutekubeast\bin\TekuTekuBeast-Public-0.6.1.iq`,
22,128,331 bytes; SHA256 `B229DDB6D834E21954757D254803E81BF291AF2586DE29ADD2D5A378EFE8C78A`.
Workspace download/evidence: `outputs/public-0.6.1-20261030/` contains the matching
IQ, `BUILD_INFO.txt`, `WHATS_NEW.txt`, verifier and extracted metadata/programs.
Build log: `bin/public-061-export.log`. Representative 1,626 layout scenes and
five public native tests below passed; no full simulator matrix or additional
physical testing is implied.

**Not uploaded/published.** Owner authorized deployment, but browser control
fails to initialize even after reset (kernel-assets OS error 3). Public listing
queued in Codex for manual handoff; upload this package to that existing public app,
version `0.6.1`, without uninstalling or touching the separate Developer Beta.

## Public 0.6.1 representative validation (2026-10-30)

Owner authorized representative checks/fixes followed by public deployment,
and reports the app looks good on Enduro 4. This is not blanket acceptance of
all watch cases. Original app identities/key and saved-state contracts retained.
0.6.1 distinguishes the compatibility patch from historical 0.6.0 packages.

Actual SDK 9.2 battle rendering: **271 scenes each / zero failures**:
FR255S 218px, Fenix 6S Pro 240px, Enduro 4 280px, FR265S 360px,
original Venu 390px and FR965 454px (**1,626 representative scenes**).
Final logs: `bin/ship-final-{fr265s,fr965,fenix6spro,enduro4}-{build,layout}.log`;
`bin/ship-{fr255s,venu}-{build,layout}.log` reused for unaffected rendering
branches (Venu's already-fitting help line is shortened). Not a full matrix.
Sampled QA heap/total: FR255S 162,608/519,968; Fenix 227,568/1,306,136;
Enduro 163,104/781,976; FR265S and FR965 163,008/781,976;
Venu 290,376/1,043,992 bytes. Not production peak/battery measurements.

Demonstrated fixes: 218px uses full HP bars without numeric/duplicate-phase
rows, inset ownership labels, wider feedback and a safe move-counter position.
Native result rows use actual font heights. Vector HP rows use label metrics,
existing move-font fallback and inline HP where needed. No new artwork, image
transforms, resource caches, buffers or timers. No battle-rule, move, reward,
input-mapping, save or step-ledger changes.

**5/5 public native Enduro 4 tests PASS**: DEV excluded, battle claim once,
legacy/v4 additive upgrade and genuine catch-up, care/game recovery.
Logs: `bin/public061-release-tests{-build,}.log`. Structural preflight and
whitespace checks pass; existing unchanged scenery/Glance/background evidence
retained, not rerun. Full public IQ export is the next packaging step.

Browser control failed before listing access with "failed to write kernel
assets ... (os error 3)"; one runtime reset/retry also failed. No manual GUI
inspection or Garmin upload/publication is claimed. Physical checks on other
models remain disclosed beta coverage gaps, not simulated acceptance.

## Fenix 6S Pro battle layout correction (2026-10-30)

The native-font fallback used 19px text on a 240px screen: ownership labels
exceeded the circular safe area, HP text overlapped the 80px sprite frames,
and stacked feedback collided with action headings. Corrected fallback only:
inline HP bars/numbers, lower unchanged-size sprites, inward ownership labels,
a bounded active-turn underline, MOVE/RESULT (or REPLAY) header and complete
named moves. Each timed result still appears beneath its affected fighter;
only the latest per fighter remains on compact native-font displays. Vector-font
Enduro 4 grid/presentation, battle rules, 72 move definitions, controls, timing,
saves, app identities, signing key and all existing IQ packages are unchanged.

Actual SDK 9.2 simulator renderer checks:
- **Fenix 6S Pro: 271 scenes / zero failures** (previously 1,218 warnings).
  Sampled QA heap 226,848 / 1,306,136 bytes. Earlier warning-array allocations
  make baseline heap incomparable; this is not a production peak improvement.
- **Enduro 4: 271 scenes / zero failures**, sampled QA heap 162,536 / 781,976.
- Audit covers all 72 names, forms, identical fighters, guard/buff/damage,
  signature feedback, replay, terminal/results, pause and readiness states.
  New checks include actual HP bar bounds/minimum width and active-turn marker.
- Logs: `bin/battle-{fenix,enduro}-fit-{build,layout}.log`.
  Signed public release-mode device programs: `bin/TekuTekuBeast-Public-0.6.0-{fenix6spro,enduro4}-battlefit.prg`;
  build logs `bin/battle-fit-{fenix,enduro}-public-build.log`.
- Structural preflight and diff checks pass; unchanged rules/save/claim native
  evidence from the public candidate below is reused, not rerun.

No new assets, runtime image transforms, buffers, caches or timers. Computer-use
helper failed to initialize; no manual visual inspection, button interaction or
physical acceptance is claimed. Owner checks remain in #20/#24. No full matrix,
new IQ export, installation or Garmin upload/publication performed. Existing
public 0.6.0 IQ must be regenerated to include this source correction.

## Public 0.6.0 candidate packaging (2026-10-30)

Signed SDK 9.2 public export **72/72 hardware parts / BUILD SUCCESSFUL**,
covering the existing 47 SDK profiles including Enduro 4 and Fenix 6S Pro.
Public UUID `53C660EBC4454BCF9292E5591EEC18DA`, original pinned signing key,
RSA-SHA256 manifest signature, archive extraction, exact hardware-part coverage,
embedded `0.6.0 beta` and absence of owner/QA controls in all 72 symbol tables
verified. Per-part signature fields are present; raw PRG signatures were not
independently verified (manifest signatures use a different signing payload).
`D:\working\garmin-tekutekubeast\bin\TekuTekuBeast-Public-0.6.0.iq`,
22,093,303 bytes; SHA256 `20C96A9CB7BF4D8950113BC98AFA975CD060C018CD14B3E410A7CE765D54ED70`.
Workspace download copy: `outputs/public-0.6.0-20261030/`.

Required packaging corrections: generate all ten themes at 218/360px too;
move the four newest themes into a resource-only barrel on CIQ 3.x to avoid
270 drawable names exceeding its 254-name limit. No original artwork, gameplay,
saves, app IDs, signing key, timers or Glance behavior changed. Build/test
resource paths and preparation tools aligned; original release records retained.

Executed/reused evidence:
- **5/5 public native Enduro 4 SDK simulator tests PASS**: DEV absent, additive
  v4 migration/catch-up, game recovery/care and one-time battle claims.
  Logs: `bin/public060-release-tests-build.log`, `bin/public060-release-tests.log`.
- Fenix 6S Pro production build passes. **332/332 scenery/menu simulator scenes
  pass**, sampled QA heap 301,560 / 1,306,136 bytes (not production peak).
  Workspace logs: `outputs/public060-qa/{build,simulator}.log`.
- **271-scene Fenix battle audit FAILS** with 1,218 bounding-box overlap/edge
  warnings; sampled heap 290,584 / 1,306,136 bytes. These include sprite-frame
  bounds and require visual review; not 1,218 confirmed visible defects.
  Logs: `outputs/public060-qa/battle/{build,simulator}.log`. Smaller-display
  battle layout remains an acceptance limitation; no battle rules/UI changed.
- Structural preflight, 192 scenery asset checks, legacy namespace/pixel-identity
  checks, guide-file links and diff whitespace checks pass. Earlier unchanged
  Enduro 4 gameplay/scenery evidence reused; no full simulator matrix rerun.

Candidate package only. Physical acceptance, the Fenix battle-layout findings
and remaining issue #24 release gates are not satisfied by a signed export.
No installation, Garmin upload/publication or replacement of old IQs performed.

## 0.6.0 beta version and private Enduro 4 package (2026-10-30)

Updated the in-app version, build identity version, export filename guards and
current build guidance to 0.6.0 beta. UUIDs, signing key, saves and gameplay are
unchanged. Signed SDK 9.2 export: **1/1 Enduro 4 hardware part / BUILD SUCCESSFUL**.
Archive extraction, original Beta UUID, pinned public-key fingerprint,
RSA-SHA256 manifest signature, DEV/scenery symbols and embedded `0.6.0 beta`
verified. Workspace artifact: `outputs/dev-enduro4-0.6.0-20261030/TekuTekuBeast-Dev-0.6.0.iq`
(290,110 bytes); SHA256 `8E3CE7E03B94507F210F86DBFE66B1EFFC92411672B2282951BC5B612E09AA5F`.
Structural preflight and 31 changed-guide local file links pass; build scripts
parse successfully. Reused unchanged gameplay's 92 native tests and 332 simulator
scenes below; these were not rerun for the version-only update. Existing 0.5.2
artifacts remain historical. No full-device export, installation, public package,
physical acceptance or Garmin upload performed.

## Ten environments and private Enduro 4 IQ (2026-10-30)

Added Bamboo Grove, Coastal Beach, Japanese Garden and Winter Woodland to the
existing six environments. New IDs 7–10 append without renumbering saved manual
choices; family AUTO remains unchanged and daily AUTO now cycles all ten.
No pet/save-schema, gameplay/reward, GPS, sky/sleep, background/Glance or timer
changes. One cached terrain layer retained. Four built-in-generated transparent
sources compile into 96 new palette/size resources; previous PNGs are unchanged.

Enduro 4 / SDK 9.2 executed:
- **92/92 native tests PASS**, including all new manual selections/reopen,
  ten-day rotation coverage, old IDs, invalid-selection guards and existing
  care/poop/activity/battle/sleep/DEV regressions.
- **332 actual SDK simulator scenes / zero failures**: ten themes × four sky
  phases × ON/OFF × Pip/Nimble × zero/five poops (320 scenes), plus all 12
  Environment menu selections with untruncated selected labels. Renderer checks
  retain the same terrain handle on cached redraws and keep waste clear of the
  beast/bar. Instrumented sample 155,816 / 781,976 bytes, not production peak
  or physical battery usage. Set `autoExit=false` for interactive QA afterward.
- Structural preflight and **144 read-only expansion-asset checks PASS**.
  Other native resource sizes are generated/checked, not other-device runtime
  certification. Sixteen added Enduro PNGs total 84,964 compressed bytes.
- Signed private production IQ: one Enduro 4 hardware part (`006-B5169-00`),
  original Beta UUID/pinned public-key fingerprint, RSA-SHA256 manifest signature
  verified, archive extraction integrity, version 0.5.2 beta and DEV retained.
  Debug symbols include all four new scenes. No production manifest/key changes.

Manual UI automation was unavailable: its helper failed to write kernel assets
even after one reset/retry. SDK-native tests and production rendering executed
successfully in the actual simulator; no manual visual walkthrough or physical
watch acceptance is claimed for this build. Initial disconnected-simulator run
was retried after starting the installed SDK simulator, not counted as a pass.
Logs: `bin/ten-worlds-{unit-build,native,qa-build,layout}.log`.

Requested acceptance artifact (not a public/all-device release):
`C:\Users\jldon\Documents\Codex\2026-10-15\referenced-chatgpt-conversation-this-is-an\outputs\dev-enduro4-ten-worlds-20261030\TekuTekuBeast-Dev-0.5.2.iq`
(290,077 bytes), SHA256
`69BEE3A17D1EB5EA428CC700D650B54245FA869E1B51BFA35B089A2A45FD471E`.
Package uses an isolated temporary Enduro-only export manifest, not a tracked
application-ID/version change. Update the existing private Developer Beta only;
do not uninstall, use the public listing or infer old IQs contain these changes.
No multi-device export/matrix, installation, Garmin upload or publication.

## Scenery prototype and daily AUTO (2026-10-24)

First approved scenery milestone: Autumn Woodland and Countryside, alongside
the four original themes. Original terrain PNGs are unchanged. Two new generated
transparent sources compile to four time palettes at six native sizes; the
48 asset checks pass (dimensions, supported RGB/15-colour limit, binary alpha,
transparent sky and opaque waste slots). Enduro 4's eight added PNGs total
42,771 bytes compressed; this is package input, not decoded RAM.

Optional `AUTO: change daily` cycles six scenes by local calendar date; family
AUTO/manual choices keep their original meaning and existing saves default to
rotation off. Selection stays fixed while playing, including midnight, and
updates when Pet is shown again on a different date. One additive `world.v1`
preference, no daily write/timer/GPS or pet-save change. Manual choice turns
rotation off. Sky, sleep, lights and Glance/background logic are unchanged.

Enduro 4 SDK native **91/91 PASS**, including date/reopen stability, month
boundary, manual override, old IDs, menu selection, pet-state purity and DEV
isolation. Production-renderer QA **192 scenes / zero failures** covers six
themes x four phases x ON/OFF x Pip/Nimble x zero/five poops; cached redraw
retains the same terrain handle and five slots clear the beast/growth bar.
Final audit sampled 154,408 / 781,976 bytes; not a production peak/battery test.
Actual simulator watch buttons selected Autumn, Countryside and AUTO DAILY.
Warm-scene waste uses darker brown for visibility; original four themes retain
their previous waste colours. Existing one-layer cache/lifecycle cadence retained.

Reproduce with `tests/scenery/monkey.jungle` (`-Owner -Device enduro4`): isolated
QA identity/RAM DEV state. After audit, normal Environment menu; BACK on Pet
reopens it, Pet UP cycles sky, DOWN toggles virtual lighting. Asset check:
`tests/scenery/verify_assets.py`. Logs: `bin/world-expansion-native.log`,
`world-expansion-unit-build.log`, `scenery-expansion-{qa-build,live,final}.log`,
`scenery-{owner,public}-build.log`. Follow-up visual/build verification uses the
final darker waste ink; signed Owner/public builds and public DEV exclusion pass.
No claim of other-device runtime or physical testing.

Bamboo, Coastal Beach, Japanese Garden and Winter are later prototypes, not
implemented in this milestone. New weather effects are also deferred. Owner
approved committing/pushing scenery and poop together; no IQ, release,
installation or publication. Physical MIP contrast/comfort/battery
acceptance remains open; art mockups are not native-display guarantees.

## Five-poop care refinement (2026-10-24)

Implemented in `2383141`; no release/version/identity changes. Existing
meal-triggered single due event, two-count limit/one drawn icon and clear-all
action are extended in place: five persisted slots, recurring four-hour lazy
catch-up, one-poop cleanup and four-hour reward watermark. `v4` remains the
atomic document; only `poopSlots`/`lastCleanReward` are additive fields. Legacy
counts/pending timers survive; missing timers start on upgrade without backlog.

**Enduro 4 / SDK 9.2 executed:**

- **89/89 native tests PASS**, including five new waste tests for no-food/time
  catch-up, 30-day/capacity/rollback boundaries, no hidden refill, one-at-a-time
  cleaning and cleanliness, reward/reopen/daily-rollover safety, legacy saves,
  occupied-slot persistence, DEV isolation, dirty-write suppression and geometry.
  An existing sleep-energy fixture now holds its unrelated poop timer constant;
  the initial 88/89 run exposed fixture coupling, not a changed sleep rule.
- **96 production-renderer QA scenes / zero failures**: counts 0–5, Pip/Nimble,
  all four themes and day/night. Poops clear the full beast bounds, each other,
  circular edge and growth bar. Sampled instrumented heap 154,088 bytes of
  781,976; not a production peak or battery measurement.
- **Actual simulator buttons:** five visible icons; Clean gives 5→4→3, masks
  31→30→28, cleanliness 25→40→55. Care growth/friendship stay at 30/3 after the
  second cleanup. Full QA VM restart restores those three slots and reconciles
  a controlled four-hour gap to four poops/mask 29 (remaining slots do not move).
  Additional four-hour button advances produce five/mask 31, then remain five.
- Signed Owner/public Enduro 4 builds PASS; public DEV exclusion PASS. Original
  UUIDs/signing configuration unchanged. No new assets, bitmap cache, production
  timer, background registration, GPS or per-poop objects. Rendering reuses one
  cached icon mask; catch-up work is capped at five slot checks.

Reproduction: `tests/poop/monkey.jungle`, `-Owner -Device enduro4`. This isolated
QA identity uses `qa.poop24.*` Storage, never the real pet. It runs the layout
audit then opens normal Pet/Actions; Pet DOWN advances the QA clock four hours,
and each QA relaunch adds a controlled four-hour offline gap. Those clock controls
are test-only; real system time/steps are untouched. Native persistence tests
also verify same-time reopening without an extra arrival.
Logs: `bin/poop-native.log`, `poop-{unit,qa,owner,public}-build.log`,
`poop-qa-live.log`, `poop-qa-reopen.log`. No device matrix, physical-watch test,
IQ export, installation or publication. Physical appearance/button comfort and
ordinary-use battery remain unverified. Owner approved commit/push with scenery.

## Latest validation summary

Latest source/package milestone: [ten environments and private IQ](#ten-environments-and-private-enduro-4-iq-2026-10-30),
**92 native / 332 simulator scenes / 144 asset checks**, Enduro 4 only.

Hygiene review (2026-10-29): structural preflight passes with world-catalog IDs
derived from the renderer's definitions; four malformed-catalog negative checks
and 95 local documentation links/anchors pass. No SDK
builds or simulator tests repeated for this tooling/documentation-only cleanup.

Latest combined milestone (2026-10-24): [scenery/daily AUTO](#scenery-prototype-and-daily-auto-2026-10-24)
and [five-poop care](#five-poop-care-refinement-2026-10-24): **91/91 native**,
**192 scenery scenes**, **96 poop scenes**, **48 asset checks**, signed Enduro 4
Owner/public builds and actual simulator controls/persistence checks passed.
Physical acceptance remains pending; no other-device runtime validation claimed.

Previous source checkpoint: [`cd24933`](https://github.com/joshld/garmin-tekutekubeast/commit/cd24933)
(2026-10-19). Enduro 4: **84/84 native tests**, signed Owner/public builds and
public DEV exclusion passed. Actual simulator button tests verified Memory
replay, saved battle state, Adventure Energy/rewards and the corrected stale
Resume label. Earlier 73 game/271 battle layout passes were reused, not rerun.
The owner subsequently reported the Bounce countdown looked correct on-watch;
that is not full mini-game or notification acceptance. Battle restart/abandon
edge cases remain native-tested only; physical alerts and battery remain open.

Recent evidence (historical records below remain unchanged):

- [Live simulator regression and coverage limits](#issues-1420---live-enduro-4-resume-regression-2026-10-19)
- [Resume countdown, Memory replay and saved-session corrections](#issues-1420---physical-feedback-resume-corrections-2026-10-19)
- [Pause-menu transaction and layout checks](#issues-1420---consistent-pause-menus-2026-10-19)
- [Registered inputs and interruption safety](#issue-14---registered-inputs-and-interruption-safety-2026-10-19)
- [Physical-watch acceptance](WATCH_ACCEPTANCE.md) and [build/package guidance](BUILD.md)

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

## Issues #14/#20 - physical-feedback resume corrections (2026-10-19)

Enduro 4 SDK 9.2: **83/83 native tests PASS**, **73 mini-game scenes** and
**271 battle scenes**, zero layout failures; signed Owner/public release-mode
foreground builds PASS with public DEV exclusion. No matrix or IQ export.
Initial run passed all 83 real tests but also auto-invoked a top-level test helper;
moving that helper into a test-only module fixed registration for the final run.

The former 500ms READY gate was not a visible numerical countdown. It is now a
shared monotonic-clock 3-2-1 gate: no elapsed gameplay, turns, jumps, travel,
timeout, input or rewards advance during it; queued callbacks cannot shorten it.
Memory then demonstrates the existing sequence before accepting more input,
preserving cursor/round/difficulty/remaining response time/retries/seed/score.
Replaying or interrupting a replay does not regenerate or reward a sequence.

Fresh-battle Resume root cause: the parent menu created a match before opening
the view, which interpreted it as a resumed save. Entry now distinguishes fresh
matches from valid unfinished saves; only the latter pause on entry. Claimed or
claim-watermarked stale records clear, terminal results settle once and clear,
and terminal/claimed state cannot submit another turn. Versioned combat rules,
72 moves, progression and identity/signing formats are unchanged.

Exit now checkpoints and returns directly to the existing Pet view (page 0,
no menu); reopening restores the same session without extra Energy/encounter
charges. Separate confirmed Abandon defaults to Cancel, retires the old ID and
grants no reward/refund. New Game/Restart Battle labels and additional-resource
confirmation remain. No save-schema changes, new assets or background tasks.
Existing timers are reused; countdown redraws only when its number changes and
Memory replay redraws at cue/gap boundaries rather than every timer tick.

New/updated assertions cover clock boundaries/queued callbacks, partially
completed Memory and interrupted replay, real parent-view navigation state,
saved Exit/reopen, confirmed/cancelled Abandon, fresh versus resumed battles,
victory/defeat/claimed cleanup, duplicate claims and existing reward/DEV/save
regressions. Sampled QA heaps: games **161,968 / 781,976**, battles
**160,328 / 781,976** bytes (not production peaks or battery measurements).
Evidence: `bin/resume-native.log`, `resume-{games,battle}-layout.log`,
`resume-{unit,games,battle,owner,public}-build.log`.

Owner Enduro 4 acceptance remains: countdown readability/frozen play, Memory
continuation clarity, fresh-match entry, Exit-to-Pet and Abandon confirmation,
alerts/reopen and battery. No physical-watch testing, release or publication claimed.

## Issues #14/#20 - live Enduro 4 resume regression (2026-10-19)

Actual SDK 9.2 Enduro 4 GUI execution against `7281654`, using physical-button
key mappings and the production views/delegates/rules. An isolated QA identity
and `qa.reg728.*` Storage namespace held a fixture pet; no production saves,
steps, identities or release packages were changed. A read-only observer logged
session IDs, HP, seeds, ticks, readiness and reward counters.

- **PASS, live:** visible READY 3/2/1 in Memory, battles and Adventures. Memory
  elapsed=34/cursor=1 and battle turn=1/HP=29:36 remained frozen throughout.
- **PASS, live:** Memory DOWN/UP/DOWN, one correct input, pause/Exit to Pet/reopen,
  same session/seed/round/partial cursor, full sequence replay before input;
  New Game created a fresh session; confirmed Abandon gave no reward.
- **PASS, live:** fresh wild encounter opened without Resume; saved battle
  restored opponent/seed/turn and YOU 29/46, WILD 36/46. Victory awarded 12 XP
  once; a second battle ended in defeat for 5 consolation XP (total 17).
- **FAIL then fixed/retested PASS, live:** after a completed match, the parent
  menu retained cached `Resume battle` text. Refresh its rows on returning to
  Wild battles; the retest showed `Meet: 0 waiting`. Add a native regression for
  completed-session cleanup, menu refresh and unchanged XP after repeated show.
- **PASS, live:** Adventure stop 2/3, ID/seed/ticks and Energy=2 survived Exit and
  a full QA VM restart. Resume cost nothing. New Game displayed `COST: 1 MORE
  ENERGY`, confirmation deducted exactly one, and the new expedition awarded
  one shell. Reopen showed START/Energy=1, not a stale expedition or extra loot.
- **NOT TESTED live:** Bounce countdown/input, battle Restart/Abandon confirmation
  edge cases, forced termination mid-write and actual OS notification delivery.
  Existing native regressions cover these game/session transaction paths; those
  assertions are not manual simulator or physical-watch acceptance.

The focused native suite passed **84/84**; signed Enduro 4 Owner/public builds
passed, including public DEV exclusion. Existing 73 game/271 battle layout
passes are reused: only parent-menu refresh changed; no geometry, timing,
combat rules or resources changed. No device matrix or IQ export.
Local GUI logs: workspace `outputs/regression-7281654/manual{,-fixed}.log`;
native/build logs: repository `bin/live728-*.log`. Physical Enduro 4 alert,
button-comfort and battery acceptance remains open.
