# Mini-game redesign — multi-round play and understandable exploration

**Status:** Approved direction for next gameplay improvement, **NOT IMPLEMENTED** as of v0.4.0. Current source to refactor: `source/BeastGameView.mc` and `source/TekuTekuBeastState.mc`. Maintain current app ID and persisted genuine pet data.

## Why

Physical Enduro 4 user testing reports Star Catch, Memory Steps and Trail Treasure feel too primitive, end too quickly, and Trail Treasure is confusing. Source audit:
- Star Catch: exactly 5 catches (automatic misses every 4s), then results; SELECT exits instead of another round.
- Memory Steps: single 3–5-button sequence; first mistake ends it, correct answer ends it; SELECT exits.
- Trail Treasure: four themed selectors, SELECT immediately calls `explore(choice)` to spend one Adventure Energy and award item `(encounters + choice) % 8`. No traversal, story or interaction. Repeated SELECT repeats one-item result until energy exhausted.
- The current **three rewarded games/day** limit is a *reward cap*, not a three-round game structure; it does not prohibit practice. This distinction is poorly surfaced.

## Product goal

Each title must be an understandable game with a beginning, multiple stages/turns, a satisfying end, feedback and a clear **Play Again / Leave** decision. Three options should remain quick enough for a smartwatch (typical session ~45–90 seconds, optionally shorter through Quit). Include friendly tutorials and different levels/choices. Avoid long text paragraphs: one-line hints + expressive animation, icons, and small score widgets. Everything physical-button playable on 280×280 MIP, with touch optional; test 240px MIP and AMOLED profiles too. Save/restore must handle automatic watch-face return and Glance launch timeout without corrupting pet rewards. Zero-step users must have access to every game and reward path.

## Game A: Star Catch 2.0

- **Session = 3 increasingly challenging rounds**. Each round has 4–5 falling/passing stars (up to 15 total): 45–75 seconds target length.
- Difficulty progression: round 1 wide timing zone/slower star, round 2 normal, round 3 narrower zone/faster star. Expose an easy/normal preference if the later round cannot be played at accessible input speeds.
- Reaction gameplay: press SELECT when the moving star overlaps the visible goal; green hit marker and tiny pet celebration. A miss briefly signals retry; **never end the session on the first miss**.
- Show `ROUND 1/3`, `STARS 3/5`, `TOTAL 7`. Short result between rounds, auto-advance or SELECT to continue. Clear final score based on correct hits/combo.
- End screen: **Play Again** (selected by default) and **Back**; SELECT never unexpectedly exits.
- During replay, bonus rewards accrue only within the daily cap. Extra plays always allowed.
- Single outcome cue / mild haptic, respecting device tone controls.

## Game B: Memory Steps 2.0

- **Session = 3 rounds**: show 3, then 4, then 5 symbols (or adjustable difficulty). Each round previews the sequence then asks for input.
- Give **two chances per round**. One mistake shows a brief wrong-indicator and replays that round's sequence; don't immediately kill the entire game. After second miss advance with fewer points or end gently with a progress result (choose stable behaviour).
- Show clearly which symbols to press: Up = ↑, Select = ●, Down = ↓. Build on existing timed-SELECT scanning mode for watches without UP and direct touch areas. The introduction includes a single interactive example.
- Display `ROUND 2/3`, `INPUT 3/4`, and meaningful success/fail hints. Avoid ambiguous current `NICE MEMORY!` when user loses.
- End: score + pet response, **Play Again** / **Back** and optional speed/difficulty selector. No fake watch steps.

## Game C: Trail Treasure 2.0 — turn item vending into an expedition

- Replace current `GROVE PATH / SELECT TO EXPLORE / PLAY OR MOVE` menu with a simple mini-adventure:
  1. **Choose destination** (Grove/Ember/Tide/Wisp), with concise one-line description and themed visual.
  2. **Spend exactly 1 Adventure Energy** to begin a whole expedition. The UI shows `1 energy = 1 adventure`, current balance and `Earn energy: activity OR care/games`. Do not charge separately for individual path choices.
  3. **Explore 3 successive nodes** (e.g. bridge, clearing, cave), each with two meaningful choices: `Search / Continue`, `Take left / Take right`, `Help creature / Open chest`, tailored by route. Show tiny map with progress 1/3 → 3/3, character walking/hopping to next node, simple surprise encounters, and short text that explains effect of each choice.
  4. An event node can be a small one-button timing or memory challenge, with a visible success/fail and different fun/cosmetic effect; support skip for accessibility.
  5. **End screen** clearly reveals item(s) found, where it was found, pet reaction and `Another trip` / `Back to beast` choices.
- Every paid expedition returns at least one common item, with chance for uncommon finds or cosmetic unlocks; deeper/different choices affect probabilities or encounter outcomes, not merely a guaranteed arithmetic rotation. Must respect current collection/discovery semantics, rewards, inventory limits and rare-form parity.
- **Adventure Energy must be earnable with no physical activity** through petting/feeding/care/mini-games, in addition to optional extra activity rewards. Never lock one route or the best items behind walking.
- Screen clarity: `ENERGY 2`, `COST 1`, `MAP 2/3`, `FOUND SHELL` rather than opaque `PLAY OR MOVE`; explain where items go (Collection → Discoveries/Toys).
- Avoid excessive CPU: static map/icons with little movement, foreground-only animation bursts.

## Session/reward architecture and safe migration

1. Separate **game round**, **game session**, **rewarded session** and **expedition node** in model and UI. A game can have multiple rounds but count as a single rewarded play for the existing per-day budget.
2. Reward **only once at the conclusion** of a Star/Memory session, not once per attempt or per round; no XP/steps minted. Any changes to the 3/day reward limit must be explicit and balanced; practice remains unlimited.
3. Trail energy debited **once at expedition start**. Persist an active expedition session so that exit/watch timeout/restart can resume (or make a clear safe cancellation/refund policy) and never permit duplicate rewards on re-entry.
4. Handle app timer lifecycle and long Glance launch inactivity limits. When the game exits unexpectedly, the user can return with session state intact or a documented safe rollback; no accidental second charge.
5. No destructive save migration. Keep v4 keys, current Pip/family/XP/collections. Use versioned optional game state keys with idempotent defaults.
6. Provide tests for no-activity play, difficulty, easy mode, missed taps, retry, physical buttons, touch, scan input, pause/resume, reward cap, path choice variation, loot integrity, multiple expeditions, out-of-energy explanation, midnight rollover, and 280/240/AMOLED layout.
7. Validate on SDK simulator and real Enduro 4. Don't claim implementation or hardware test without evidence.

## Suggested implementation order

1. Fix result screen replay, improve Star Catch to 3 rounds.
2. Add multi-round Memory Steps and a forgiving retry path.
3. Build Trail Treasure as real three-node expedition with onboarding, saved session and clear energy/item feedback.
4. Balance and polish rewards/pet sprites, run regression and hardware QA.

Companion docs: [current v0.4 gameplay](GAMEPLAY_V0_4.md), [SDK validations](V0_4_VALIDATION.md), [Codex roadmap](CODEX_V0_4_TASKS.md).
