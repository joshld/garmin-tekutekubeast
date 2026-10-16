# v0.4 design review — on-watch Developer Mode, inclusive progression, fast testing and clean UI

**Status: implemented v0.4 development beta; physical-watch acceptance pending.**
See [validation](V0_4_VALIDATION.md). These requirements supersede older proposals
for a separate Developer Lab, step-dependent evolution or ~100-day passive growth.

## 1. Primary product rule: full experience even at zero steps

TekuTekuBeast must be a complete and satisfying Tamagotchi-style game for someone who does not or cannot move, now or indefinitely. A player with **zero steps** still hatches eggs, feeds/cleans/plays, evolves to any of Grove/Ember/Tide/Wisp, unlocks rare creatures and collects rewards and mastery. No family or action is permanently locked behind walking. Inactivity must not lead to death, loss of progress or dramatically slower evolution.

**Physical activity is a bonus.** Watch-recorded steps remain an accurate separate tally; they can grant extra growth XP, snacks, treats, cosmetics, collectibles, achievement progress and exploration rewards. They never become mandatory. Activities may have added bonuses based on reliably available watch data, but do not assume all Garmin models can infer workout type.

### Preliminary progression to calibrate in simulator (NOT FINAL)

Use existing growth thresholds and minimum-age stage gates as a starting point. Separate:
- `realWatchSteps` (or compatible existing `xp`): credited only from the real ActivityMonitor, deduplicated and immutable by games/developer cheats.
- `baseGrowthXp`: accrue from **normal elapsed wall-clock time**, whether app is open, closed, or the user has 0 steps.
- `activityGrowthXp`: additional progression from real steps.
- `careGrowthXp`: optional small rewards from play/care.
- `growthXp = baseGrowthXp + activityGrowthXp + careGrowthXp` (with migration credit for existing progress).

For initial simulator tuning, propose **12,000 passive growth XP per real day**, **+1 growth XP per eligible real watch step**, and a small optional care budget (~300/day), while retaining a **minimum Legendary age of 21 days**. At 300,000 XP, passive-only reaches Legendary in about **25 days**; an active player could qualify by ~21 days owing to age gate. Adjust after hands-on tests; **do not ship unreviewed balancing numbers**. Neither food nor mini-game participation is required for basic growth.

The prior proposal of 3,000 passive XP/day with 100 days to Legendary is **rejected**. A limited few days' advantage for consistent movement is acceptable, with most fitness value being *additional rewards*. After Legendary, allow mastery growth without watch steps too (previous step-only mastery rule must be updated), while activity adds bonuses.

Calculate passive growth lazily using a durable timestamp and overflow-safe arithmetic: credit full elapsed time even if the app has not opened for months. Do NOT reuse care-decay 24-hour cap for positive growth. Handle clock rollback, day changes, persist-before/after interruptions and repeated reads without doubling. Preserve previous pet and all existing `Storage` keys. Progress/stage should never regress. If the user uninstalls the app, Garmin Storage retention is a separate platform concern; do not promise preservation across uninstall.

**Evolution families:** mostly automatic, activity **and** nonactivity care/play/temperament paths. At zero steps, all four outcomes must remain possible across multiple pets, including a deterministic seeded tie-break for completely unplayed/inactive pets rather than always making Wisp. Rare exceptions must be earned through *either* activity or equivalent nonactivity achievements.

## 2. Single installed watch app with on-watch Developer Mode

**The user explicitly does NOT want a separate Developer Lab application or a separate watch installation.**

Developer Mode must be a toggle within **the normal TekuTekuBeast watch app**, reachable entirely on watch: Actions → Settings → Developer Mode → ON/OFF. Expose in developer builds, optionally compile out/hide for the public Connect IQ Store release; it must be available on the user's real Enduro 4 test build. Preserve app ID and navigation. No PC or simulator needed to use it.

While Developer Mode is ON, the SAME pet/game screens operate normally, with a subtle `DEV` indicator and one added Actions → Dev Tools screen:
- Game time speed: 1×, 5×, 20×, 100×.
- Jump game time: +1 hour, +1 day, +7 days (and optionally set specific virtual pet age).
- Force evolution stage: Egg/Pip/Nimble/Adult/Champion/Legendary, and choose Grove/Ember/Tide/Wisp for test.
- Set fullness, happiness, energy, cleanliness, friendship, meals and snacks; spawn/clear poop; test feeding, mini-game rewards, rare evolutions, and each animation/sound.
- Step-test injection is synthetic *in the dev preview state only*. The real watch-recorded daily step display and genuine `ActivityMonitor` watermark are NEVER forged.
- Reset dev scenario without resetting the real pet.
- Apply speed multiplier to **game simulation time**, not Garmin's system clock or ActivityMonitor. Stop extra animation/timer activity when app exits.

**Save safety, critical:** On enabling Dev Mode, make a snapshot of the actual pet and enter a **temporary dev test branch within the same app and identical UI**, not a second application. Developer changes do not overwrite real steps or regular pet state. On switching OFF, offer **Discard test changes** (default), restoring actual pet and catching up any genuine watch steps accrued during testing. If an explicit **Keep eligible changes** option is implemented, it may merge only non-fabricated legitimate care actions and must never merge synthetic time/steps or forced evolution without an explicit irreversible warning. Simpler safe v0.4: Discard-only. Clarify visually that DEV scenarios are temporary.

Implement through injectable GameClock / StepSource / StateStore interfaces or equivalent to ensure production game uses real time and real steps, while developer tools use the same gameplay logic with accelerated virtual game clock and dev-only state namespace. This is *internal isolation*, not a separate app or fake daily-step display. Dev testing must be usable entirely with physical Enduro buttons.

## 3. Egg hatch pacing

Current 2,000-step-only trigger hatches the egg too quickly. Proposed new eggs naturally hatch around **24 hours** after creation even with 0 steps. Interaction and activity can accelerate to **no less than 8 hours**; tune in the real watch UI. Eggs also display reactions, incubation progress and available care without requiring motion.

Already evolved pets (e.g. Pip at 5,974 real steps) must **never revert** when v0.4 is installed.

## 4. Simplified watch screens

- **Pet:** remove the repeated 'TEKUTEKU BEAST' header; place species name (e.g. Pip) at top, small optional heart/meal/poop status icons, generous animated creature in centre, growth bar and a tiny today's-steps readout at bottom.
- **Care:** concise icon-led food/fullness/happiness/energy/cleanliness and easy access to Feed/Clean/Play; avoid repeated instructional sentences.
- **Details:** species, stage, days, growth-to-next/mastery and the actual real step tally. Label growth and watch steps differently to avoid misleading users.
- Contextual names/tooltips for unfamiliar icons when first used; physical-button-only navigation, readable contrast and safe circular bounding box are required.

## 5. Broad Garmin compatibility

Current manifest targets `enduro4` only. Target other suitable Connect IQ watches only after checking each model's SDK support, screen, memory, touch/buttons, steps APIs, audio, vibrate and battery. Do not assert all Garmin watches compatible or enable untested devices in manifest.

## 6. Implementation order and acceptance

1. Build Developer Mode **inside the existing app** with safe dev snapshot and accelerated game-clock hooks, maintain real saved state.
2. Refactor growth so an entirely inactive user follows the same ~3–4 week full experience; steps give bonus rewards, and all four evolution families stay attainable without movement.
3. Adjust egg hatch age rules, retrofit existing save migration and update mastery to support passive growth.
4. Simplify Pet/Care/Details screens while retaining pixel-art and UI layout audits.
5. Implement feeding, cleaning/poop, expressive sprite animation, games, optional short sound/vibrations.
6. Expand Garmin model support with an explicit tested-device matrix.

**Acceptance examples**
- At 0 steps, Pip/Adult/Legendary are reachable; all families possible across subsequent pets, and meals/games/cleaning work normally.
- At 10k steps/day the player gets extra rewards and possibly a modest speed-up, NOT a dramatically different basic experience.
- With DEV ON on the real watch, 100× life clock and +7-day advances are usable without simulator or a second installation; stage/needs can be forced on screen.
- Turning DEV OFF discards simulated time, forced creatures/poop and synthetic steps, keeps legitimate real step totals, and never corrupts existing Pip progress.
- No dev unlocks/forced time or synthetic XP can leak into production save.
- Current Pip remains Pip on upgrade; egg hatch no longer happens instantly after 2k steps.
- Repeated app launches, background events and system clock adjustments cannot double-credit steps or elapsed-time XP.

Related: [v0.4 gameplay](GAMEPLAY_V0_4.md), [Codex roadmap](CODEX_V0_4_TASKS.md), [evolution tree](EVOLUTION_DESIGN.md). No actual source features changed in this documentation commit.
