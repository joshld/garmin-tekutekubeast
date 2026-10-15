# Codex execution plan — TekuTekuBeast v0.4

**This is the requested implementation plan, not a claim that new care/games/animation features are coded.**

## Context and contract

Work in `D:\\working\\garmin-tekutekubeast` or `joshld/garmin-tekutekubeast` on `main`. Native Garmin Enduro 4 Connect IQ (Monkey C) watch app. Read `docs/GAMEPLAY_V0_4.md` first, then current `docs/EVOLUTION_DESIGN.md` and `art/README.md`. Already built and simulator-tested according to README. Existing watch user's save should not be destroyed. Do not edit Garmin developer key or commit credentials.

### Non-negotiables
- Keep `manifest.xml` app ID identical; preserve all existing persistent Storage keys (birth, birthEpoch, birthBaseline, xp, snacks, snackRemainder, friendship, patDay, pats, schema, family and daily watermarks).
- Do not retroactively count steps, double-count steps or let mini-games create step XP.
- Do not change automatic family evolution paths (Grove/Ember/Tide/Wisp) or their existing stage thresholds without specific user approval.
- No pet death, no punishment for recovery or inactivity, no mandatory gameplay while walking/running.
- Foreground-only animations/sounds; no audible background step/poop notifications.
- Follow safe editing: run simulator tests and layout audit before pushing; note unverified items, don't claim hardware tests without hardware.

## Ordered implementation tickets

### P0 — Persistence migration + interactive Actions menu
**Primary:** `source/TekuTekuBeastState.mc`, `source/TekuTekuBeastView.mc`, `source/TekuTekuBeastInput.mc`.
1. Introduce independent `CareState` or equivalent for fullness, happiness, energy, cleanliness, meals, poop and v0.4 schema.
2. Upgrade/migrate existing Storage in place; never reset user's Egg/Pip/Nimble or XP.
3. Implement Actions overlay with SELECT open, UP/DOWN highlight, SELECT confirm, BACK close. Keep existing Pet/Care/Your Beast navigation when overlay closed.
4. Add view/subview enums or state machine to prevent conflicts with simulator's navigation.
5. Add deterministic unit/simulator test harness for preserved keys and rollover.
**Done:** Existing save persists, all actions navigable with hardware buttons, no clipping.

### P1 — Feed/Clean and daily care
1. Two free meals refresh each day, non-stackable; keep 1 earned snack/2,500 watch steps (max 12).
2. Show fullness, happiness, energy and cleanliness; introduce consistent moods.
3. Feed meal/snack animation and changes; timed poop scheduling with cap 2; Clean is one-click and restores 100 cleanliness.
4. Persist bounded timers; process on resume/step reconciliation; no repeated timer when closed.
5. Tests: no-snack feeding, double clean, >24 h absence, midnight, backwards system time, repeated step event, app restart.
**Done:** User can feed on a zero-step day, deliberately clean poop, and still see correct XP.

### P2 — Expressive sprites + animation controller
1. Refactor current 1 Hz bob into event-driven animation state machine (IDLE/LOOK/WANDER/HOP/PAT/EAT/CLEAN/SLEEP/EVOLVE).
2. Create several distinct original pixel-art frames for Pip first; maintain nearest-neighbour palette and sprite cache.
3. 2–4 Hz foreground rendering only during animation bursts; slower idle / pause; stop in `onHide()`.
4. Update `tests/art-preview` to exercise movement extremes and new action overlays, without altering live save.
5. Battery/memory smoke test: 280x280 MIP, 64 colors, 786432-byte watch-app budget.
**Done:** Pip walks, hops, looks around and reacts to interactions on real watch simulator; no clipping.

### P3 — Play menu + Star Catch
1. Implement physical-button Star Catch loop (five attempts, 10–20 seconds), happiness/friendship reward and energy drain.
2. Cap reward at 3 sessions/day; allow practice; quit using BACK at any point; deterministic/random-test seeding.
3. Render within circular-safe region; display START prompt, remaining tries and results.
4. Ensure state save/restore when exiting play; no step XP from game actions.
**Done:** One complete mini-game with real happiness feedback, button-only and safe for MIP.

### P4 — Tone & haptic feedback settings
1. Introduce `FeedbackManager.mc` with guarded `Toybox.Attention.playTone` and `vibrate`.
2. Sound OFF by default, vibration ON (gentle) by default; saved settings in independent Storage keys.
3. Short chirp patterns for pat, meal, clean, game win and evolution. No background sound.
4. Verify audio on physical Enduro 4 and simulator where feasible; test mute/settings and ensure no crashes if tone unsupported.
**Done:** Interactions produce optional beeps/taps; both toggles work independently.

### P5 — Expand content (separate release)
- Memory Steps, Trail Treasure, family personality variations.
- Distinct art sprites for Adult/Champion/Legendary Grove/Ember/Tide/Wisp (12 primary branch species).
- Sleep poses, eating/cleaning frames, special idle events.
- Optional collection/retirement, Star Charm rare form, future cosmetic badges.
- Update game design notes to reflect actual behaviour, not wishful features.

## Suggested implementation architecture

```
source/
  TekuTekuBeastApp.mc        (existing)
  TekuTekuBeastInput.mc      (route keys to current UI state)
  TekuTekuBeastState.mc      (keep saved XP/evolution stable)
  TekuTekuBeastView.mc       (render, preferably break up)
  CareState.mc               (new; time-based care, feeding, poop)
  GameState.mc               (new; game sessions and reward caps)
  AnimationController.mc     (new; foreground-only state sequencing)
  FeedbackManager.mc        (new; tones/haptics and settings)
  UiNavigation.mc           (optional: screens/menu state)
```

Split model mutation from drawing, use named constants for rates and thresholds, add save-version upgrade logic, and limit duplicated storage writes. Background step delegate remains small; do not preload all sprite atlases into background memory.

## Must-run validation for each phase

- `python scripts/check_project.py` structural preflight.
- Build with installed Garmin Connect IQ SDK 9.2.x, Enduro 4 target, developer key outside Git.
- Run `tests/art-preview` on Enduro 4 simulator to verify text within round layout for 0–100 values, long names, all menus, game prompts and feedback.
- Simulator: new save, existing save, two days' steps, repeated 1000-step event, age evolution, restart and rollover.
- Document whether actual physical Enduro 4 tests have been performed.
- Commit each P0/P1/P2/P3/P4 separately so regressions can be isolated.

## Prompt to paste to Codex

> Continue TekuTekuBeast in `D:\\working\\garmin-tekutekubeast` and `joshld/garmin-tekutekubeast`. Read `docs/GAMEPLAY_V0_4.md` and `docs/CODEX_V0_4_TASKS.md`, then implement tickets P0 and P1 first. Keep the existing Garmin application ID and saved XP/friendship keys stable. Add interactive feed and poop-clean functionality, a safe timestamp-based care model, free daily meals, and fully button-operated menus. Do not change the step-based branching evolution or fake steps. Build for Enduro 4 in Garmin SDK, test simulator navigation, save migration, rollover, and update the documentation with actual tested status. Show me screenshots before moving on to P2 animations, P3 Star Catch, and P4 tone/vibration feedback.
