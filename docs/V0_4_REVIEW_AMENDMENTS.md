# v0.4 design review amendments — accessibility, testing, evolution pacing, UI and Garmin support

**Status: PRODUCT DECISIONS / PROPOSALS FOR REVIEW — NOT YET IMPLEMENTED.** These amendments are newer than `docs/GAMEPLAY_V0_4.md` and `docs/EVOLUTION_DESIGN.md`. Where the earlier docs assume that step XP is the sole growth source, this document **supersedes that assumption**.

## 1. Garmin compatibility

The current `manifest.xml` targets only `enduro4`. Do NOT claim support on every Garmin watch. Long-term goal is as many appropriate Connect IQ wearables as practical. Start by adding and testing similar 280×280 MIP models (Enduro 3, compatible Fenix 7X / Fenix 8 Solar 51mm), then consider varying resolutions and AMOLED devices. Each device must be opted into the manifest only after API, RAM, bitmap resources, input mapping, display area, tone/vibration support and simulator testing. Some older watches cannot support this application unchanged. Maintain a device test matrix and avoid indiscriminately selecting all devices.

## 2. Inactive-friendly growth, not step-gated

**Nonnegotiable:** Users must be able to hatch, raise, play with and fully evolve a beast with **zero watch steps**. Steps and workouts **accelerate** growth but are never a prerequisite. Rest, disability, temporary injury and sedentary days cannot kill the creature or permanently lock species/forms. All four families should ultimately be reachable through nonwalking patterns as well, using care/play/personality tendencies. Do not require recorded workouts.

**Provisional balance for testing:** Preserve `stepXp` as an accurate, deduplicated counter of watch-recorded steps and `careXp`/`passiveXp` separately. Evolve based on `growthXp = stepXp + passiveXp + careXp`. Suggested starting passive rate **3,000 growth XP per elapsed day**; care/game award budget up to **300 growth XP per day**; step rate **1 growth XP per newly credited real watch step**. Exact numbers are tuning parameters, not finalized. At current 300k Legendary threshold, passive-only ~100 days; 10k steps/day + passive ~24 days (excluding care). Keep minimum-age gates; preserve prior progress and show watch steps separately from growth progress. Earned step snacks remain a bonus, not the only food; v0.4 already proposes two daily free meals.

Advance passive growth based on elapsed timestamps upon next app opening or state sync, not continuous background wakeups. It must continue across weeks without opening the app; use safe bounded arithmetic and a durable accrual watermark rather than forfeiting days after a 24h cap (the **care decay** cap is a different, deliberately non-punitive rule). Clamp negative time and defend against clock changes. Do not double credit time on repeated opens or reset upgrades.

**Family selection amendment:** The current Ember/Grove/Tide/Wisp step pattern is an activity influence, not the only possible path. Add optional parallel care/game/play tendency scoring for each family, which works at 0 steps. Mostly automatic evolutions and earned rare exceptions still apply. Avoid defaulting all sedentary users to Wisp.

## 3. Egg hatch pacing

Current implementation hatches immediately at 2,000 credited steps (no minimum age), explaining the fast first evolution. **Proposed replacement for newly hatched eggs:** passive hatching around 24 hours; real steps/activities and care can accelerate incubation to a hard floor of roughly 8 hours. Eggs must hatch without motion; do not allow 2,000 early steps to hatch instantly. Values subject to simulator feel testing.

For old saves, never revert current Pip/Nimble stage into an egg. Existing unlocked stage is grandfathered (or stage monotonicity preserved). Don't change the application ID, current Storage keys or old accumulated XP.

## 4. Developer Lab / QA sandbox

Before adding more production systems, implement rapid-testing capability. Reuse the existing `tests/art-preview` precedent (separate application identifier, in-memory model). Prefer **separate isolated Developer Lab app** with a deterministic fake clock, isolated fake step provider and isolated game Storage. It can instantly:
- Set Egg/Pip/Nimble/Adult/Champion/Legendary and Grove/Ember/Tide/Wisp.
- Advance virtual time by hours/weeks/months without changing device/system time.
- Inject synthetic step sequences **only into the QA model**, never the live ActivityMonitor counter.
- Adjust fullness/happiness/cleanliness/energy/friendship; trigger poop, meals, games, sleep, rare forms and animations.
- Switch 0-step, daily walk, run-heavy, neglected-but-safe and mixed-care scenario presets.
- Reset QA data without touching real pet's save.
- Run menu/layout clip checks and multi-device snapshots.

Do not expose QA cheats in release, production menus, signed store exports, or normal on-watch storage. Distinct app ID is required. Ideally place a `tests/dev-lab/` second app using shared game model and view assets; common interfaces (Clock, StepProvider, StorageAdapter) facilitate test injection. Do not use live fake step credits or shared Storage keys.

## 5. Minimal round-watch UI

**General rule:** Show the pet and high-utility icons, not multiple redundant text labels. Keep text readable; never use unlabeled cryptic controls without onboarding or accessible labels in an expanded/details screen.

**Pet:** remove persistent 'TEKUTEKU BEAST' title. Top: **PIP** (or active creature name). Tiny status row: hearts, food count, poop alert only if needed. Centre: large animated pet, with adequate safe margins. Bottom: progress bar and a single compact daily-step line; page dots optional. Hide care explanations here.

**Care:** simple icon-led gauges for fullness/happiness/energy/cleanliness, food inventory icons and a prominent action selection. Remove duplicate titles and long instructional labels; show button hints contextually/first use.

**Stats:** species + stage, growth-to-next and small real-step count, age/mastery; avoid repeating 'YOUR BEAST', 'TOTAL STEP XP', 'TO NEXT' on every screen. Use concise labels only where they prevent ambiguity. Pacing/XP exact figures and full descriptions live in detail view.

**Accessibility:** preserve physical button access, at least one understandable label for new icons (via tooltip/detail/onboarding), contrast in 64-colour MIP, and safe text within 280×280 circle; later responsive layouts for smaller MIP and AMOLED sizes.

## 6. Revised order for implementation

1. Capture these decisions in code architecture and tests; do **not** immediately rewrite user saves.
2. Add Developer Lab isolated sandbox (can be done in parallel with P0).
3. Refactor growth engine (passive/care/real watch steps separated, old stage preserved), hatch pacing and inactivity-friendly family selection. Test using the QA sandbox.
4. Redesign simplified Pet/Care/Stats UI and menu controls.
5. Implement v0.4 food/cleaning/poop, expressive animation, mini-games and short optional sounds per existing task list.
6. Expand compatibility via a device matrix and per-device simulator tests.

## Acceptance examples

- With no steps for 7, 30 and 100 elapsed days, pet progresses, can eat free meals and play, and may reach Legendary.
- 10k watch steps/day beats passive-only growth, but recorded step count remains exact.
- Existing Pip with 5,974 step XP never regresses after upgrading the growth model.
- Debug 'advance 100 days / force Legendary / trigger poop' works only inside the separate Developer Lab.
- Hatching new eggs is not instant after 2k steps, but eventually occurs with 0 steps.
- App header isn't redundantly displayed on Pet page; round-screen controls are readable on tested device profiles.

Official reference: https://developer.garmin.com/connect-iq/compatible-devices/
