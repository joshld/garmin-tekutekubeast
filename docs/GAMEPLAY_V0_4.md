# TekuTekuBeast — v0.4 Care, Play, Animation & Sound Specification

**Important newer review:** [Inclusive growth, on-watch Developer Mode, evolution pacing and simplified UI](V0_4_REVIEW_AMENDMENTS.md) overrides earlier step-only progression assumptions. Numbers remain provisional.

**Status:** Implemented v0.4 development beta. This preserves the historical
design; [validation](V0_4_VALIDATION.md) and [evolution](EVOLUTION_DESIGN.md)
record the actual implementation, final tuning and pending hardware acceptance.
**Target:** Garmin Enduro 4 (Connect IQ native Monkey C watch-app, round 280 x 280 MIP / 64 colours).
**Goal:** Provide the full virtual-pet experience at zero steps, while rewarding additional real watch activity with bonus items and some growth acceleration, plus care and games.
**Design policy:** Rest/recovery friendly, non-punitive, no permanent death, no fake steps, no pay-to-win, optional audio, no intrusive background prompts.

## Existing implementation to preserve

The main branch already has Egg, Pip and Nimble pixel-art sprites, three watch screens (Pet/Care/Your Beast), watch-based ActivityMonitor step XP, background milestone reconciliation, pets that do not die, current friendship and snack counters, stage progression and family branching. It has been compiled and exercised in the Enduro 4 simulator per README. Preserve the app ID and existing Storage keys so the user keeps their current Pip and 5,974+ XP.

The existing step-only family criteria in `docs/EVOLUTION_DESIGN.md` will be adapted so all four families can also evolve through nonstep care/play/temperament patterns. Ordinary family selection stays mostly automatic, with earned rare exceptions; consult the newer v0.4 review before implementation.

## 1. Care attributes (0..100) and clock handling

All values are clamped 0..100. Derived tick-on-read/tick-on-foreground-resume, not a permanent timer running while the app is closed. Time intervals and rates are tuning defaults.

| Attribute | Initial | Changes | Recovery & floor |
| --- | ---: | --- | --- |
| Fullness | 75 | -3 each 6 h elapsed (max 24 h accounted per sync), +30 regular meal, +10 snack | Minimum 30 when inactive; never fatal |
| Happiness | 65 | -2 each 8 h elapsed (max 24 h accounted), +8 pat, +15 game win, +6 feed, +10 clean | Floor 40; rest days do not directly lower happiness |
| Energy | 80 | -10 per minigame, +5 per 4 h elapsed, +20 Rest action once per day | Rest always available; 0 energy merely disables games until replenished |
| Cleanliness | 100 | -15 when one poop is created, +35 for cleaning one, up to 100 | Never fatal; at most 2 visible poops |
| Friendship | Existing 0..100 | Keep current pat/feed values (+2 per pat, +5 per feed), +2 for game, +3 clean | Does not decay; cap existing pat 3/day |

Design detail: The passage of time is processed from a persisted last-update timestamp, with negative deltas clamped to 0 and positive deltas capped at 24 h per evaluation. Persist the new timestamp after applying a bounded update. This prevents clock changes and long absences from causing large penalties. A day without steps has no additional penalty. No death, de-evolution, level loss or hard punishment.

**Initial data migration:** Existing users may already have friends, XP, snacks and pat counts. Only initialise new v0.4 keys on first v0.4 run; do not call existing `start()` as a destructive reset. Set new `careSchema=2` after successful init. Use an idempotent migration.

## 2. Feeding & poop

- **Regular meals**: 2 free meal servings refresh each local day, non-stackable (so feeding always works on rest days). This is separate from earned snacks; show both counts.
- **Snacks**: current 1 snack per 2,500 new device steps, cap 12; feeding a snack increases fullness by 10, happiness by 6 and friendship by 5.
- **Meal**: fullness +30, happiness +6, friendship +5.
- Pet may refuse when full (e.g., fullness >=95), with a short cute animation; do not waste an item.
- Feeding schedules a poop event approximately 2–4 hours later using a deterministic due timestamp. It is processed on the next foreground or step-event state sync. No persistent wakeups solely for poop.
- Minimum 4 hours between poop creation events; max 2 visible. New poop is deferred when full. Persist pending due timestamp/count safely.
- **Clean** action removes one poop (or all visible poop as a single action; choose one consistently in implementation). Proposal: remove all visible poops and set cleanliness to 100 immediately, with a two-second clean animation.
- When poop count is zero, **Clean** offers 'ALL CLEAN!' visual feedback with no penalty.
- Poop should appear visually beside the creature (small tasteful 8x8 pixel icon). Cleanliness is a light mood modifier, not a life-threatening need.
- Show a tiny poo icon on the main Pet screen only if there's poop to clean. If present, the Care Actions menu puts Clean first.

## 3. Games: quick, watch-native, and no fake XP

**Game A — Star Catch** (v0.4 minimum viable):
- START begins a round; moving star and target zone show on a circular-safe screen.
- START when star overlaps target. Up to 5 attempts, about 10–20 seconds total.
- Hit = +15 happiness, +2 friendship; miss = friendly retry animation, no XP loss.
- Energy -10 per session; max 3 **rewarded** sessions per calendar day. Unlimited practice after that; no additional reward. Never grants step XP.
- Outcome sound/haptic optional and only with the app in foreground.

**Game B — Memory Steps** (next increment):
- Display 3–5 symbols, using UP/DOWN/START inputs. Player repeats.
- +10 happiness, +2 friendship for success. 20–40 seconds. Shares the 3/day total rewarded-session budget.
- BACK quits without penalty; no timed auto-start.

**Game C — Trail Treasure** (later, step-powered):
- Walking contributes to a separate expedition-distance counter using already-creditable, deduplicated new watch steps, not manual tapping. Periodically unlock tiny map branches/collectibles.
- Game includes quick menu choices but never demands watch interaction while the user is moving.
- Does not change core XP or automatic evolution; adds collectibles and possible earned rare items later.

## 4. Mood and personality

Suggested on-screen moods: HUNGRY, PLAYFUL, CONTENT, SLEEPY, MESSY, EXCITED, COZY. Priority: short-lived celebration/action state > needs-cleaning > sleepy > hungry > playful/excited > content/cozy. A rest day must not automatically produce the "sad" or neglected visual simply due to inactivity. Use different idle personalities by family:
- Grove: calm sways, gentle ear/leaf movement.
- Ember: energetic hops, tail flicks and sparks.
- Tide: floating/swaying, blinking and bubbles.
- Wisp: drifting, small flashes and playful disappear/reappear.
- Pip: frequently looks around, jumps, blinks and wags. Nimble: bigger bounces and steps.
- One memorable rare happy/excited animation per family later.

## 5. Animation and hardware budget

Current 1 Hz two-pixel bob is not enough. Implement an animation state machine and ~2–4 Hz screen updates **only while the watch app is in the foreground**. Prefer keyframed x/y offsets with several distinct sprite frames rather than only moving a static sprite:
- IDLE: blink, look left/right; some slow stationary intervals.
- WANDER: x +/- 12..18 px, 3–5 steps, stay entirely within circular-safe area.
- HAPPY: 2–3 noticeable hops, tail movement.
- EATING: 3–4 chewing frames.
- CLEANING: squish reaction + wipe puff.
- SLEEP: curled sprite/closed eyes and a few Zs, not a forced sleep mode.
- EVOLVE: transition effect and new form reveal.
- For Pip, target e.g. 4–6 individual frames to start; more for family-specific variants later.
- Use sprite atlases or individual small assets optimised for 64-colour MIP; cache the current creature bitmap(s), don't load each frame in `onUpdate()`.
- No background animations, sounds or repeated timer activity when the view is hidden.
- Add animation intensity setting OFF / LOW / NORMAL (default NORMAL). Reduced motion slows or disables wandering and jumps.
- Test actual watch CPU usage, battery and MIP readability, and don't assume a stable 4 FPS without validation.

## 6. Exact navigation (proposed)

Use all five Enduro 4 buttons as supported, but avoid hijacking system-reserved long presses. Touch is optional convenience, not a requirement.

| Context | START/SELECT (enter) | UP / DOWN | BACK/ESC | MENU long press |
| --- | --- | --- | --- | --- |
| Main Pet | Open Actions | Previous/next top-level page | Default app back/exit | Do not override system shortcuts |
| Care page | Open Actions focused on Feed/Clean | Previous/next page | Return Pet | Do not override |
| Your Beast page | Open detail/collection later | Previous/next page | Return Pet | Do not override |
| Actions overlay | Confirm highlighted Feed / Clean / Pat / Play / Rest / Settings | Change highlighted item | Close overlay | Leave system control |
| Food selector | Give highlighted Meal or Snack | Select item | Return Actions | Leave system control |
| Play menu | Open Star Catch (or other unlocked game) | Choose game | Return Actions | Leave system control |
| Mini-game | Confirm/perform game action | Required game inputs | Quit game to Play menu | Leave system control |
| Settings | Toggle selected Sound/Vibration/Motion | Choose setting | Return Actions | Leave system control |

Touch: large central hit areas and native buttons both work. Never require swiping to perform a critical action.

Proposed Action priority: **Clean** (when poop exists), **Feed**, **Play**, **Pat**, **Rest**, **Settings**. Show friendly confirmation toast and animation after action. The Care page can directly show fullness/happiness/energy/cleanliness bars and two food counts without densely packing the Pet screen.

## 7. Sounds and haptics

Garmin lists Enduro 4 support for `Toybox.Attention.playTone()`, `Attention.ToneProfile` and `Attention.vibrate()`. The app should use short tone-generator chirps and vibration profiles, NOT promise arbitrary WAV/MP3 or speaking/animal voice clips. Compile/test with Garmin SDK 9.2.x and confirm physical device behaviour.

| Event | Tone design | Haptic |
| --- | --- | --- |
| Pat | optional quick chirp | one very short pulse |
| Meal | two short rising notes | short pulse |
| Clean | short soft descending or sparkling notes | one pulse |
| Game correct | brief two-note success cue | gentle double pulse |
| Game miss | very soft low cue (optional) | none |
| Evolution | 3–5 note jingle | short celebratory pattern |
| Background steps event | **NONE** | **NONE** |

Settings: **Sound OFF by default; Haptics ON (gentle) by default**, each separately switchable in-game. Never generate unsolicited hourly sounds/poop alerts. Only play interaction events while the user is inside the app. Never bypass system-level do-not-disturb/mute settings; behaviour needs real-watch verification. Rate-limit cues, avoid long sustained buzzing, and guard APIs for device availability where possible. Keep effects short and non-repetitive.

Example API shape (not necessarily copy/paste valid on all SDK builds):
```monkeyc
using Toybox.Attention;
if (Attention has :playTone) {
    Attention.playTone(Attention.TONE_KEY);
}
if (Attention has :vibrate) {
    Attention.vibrate([new Attention.VibeProfile(40, 100)]);
}
```

## 8. Acceptance criteria and validation

1. Existing save (Pip, current XP, previous friendship and snack counters) survives update unmodified in baseline values.
2. User with 0 steps on a rest day can feed a free meal; snacks remain a step reward.
3. Feeding schedules at most 2 poop; leaving the game closed and reopening processes deferred poop safely; Clean clears, no persistent notification.
4. Star Catch is playable entirely via physical buttons, 3 rewarded sessions per day; games do not mint step XP.
5. Idle creature visibly looks around, jumps and moves beyond 2-pixel bob; still readable on round 280x280 display and no clipping.
6. Sound OFF generates no tones; haptics independently controlled; no background alert spam; actual Enduro 4 supports audible tones after testing.
7. Step events still deduplicate and preserve the existing evolution path and lifetime mastery.
8. Restart app, power cycle watch, simulated midnight, and clock rollback/forward maintain valid state.
9. Physical device battery and touch/button tests completed before a public store build.

## 9. Scope

The documentation here **does not implement these gameplay changes**. Start with navigation/actions and care state; then animation and first mini-game; then audio polish; finally advanced game, sprites and rare/collection content.

Companion docs: `docs/CODEX_V0_4_TASKS.md`, `docs/EVOLUTION_DESIGN.md`.
Sources:
- https://developer.garmin.com/connect-iq/device-reference/enduro4/
- https://developer.garmin.com/connect-iq/api-docs/Toybox/Attention.html
- https://developer.garmin.com/connect-iq/articles/core-topics/Backgrounding.html
