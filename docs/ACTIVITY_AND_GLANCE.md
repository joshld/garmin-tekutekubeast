# TekuTekuBeast — Garmin targets, activity rewards and glance design

**Status: design & development backlog; not implemented**. Reference: the current manifest enables only `enduro4`. Full virtual-pet experience with zero steps remains a non-negotiable requirement. See `docs/V0_4_REVIEW_AMENDMENTS.md` for the on-watch Developer Mode and ~3–4 week progression target.

## 1. Watch compatibility plan

Compatibility is per specific Garmin device definition, NOT all devices named as one family. Enabling a device in the manifest is not proof that it works.

| Tier | Representative models | Display | Work |
|---|---|---|---|
| Current | Enduro 4 | 280×280, 64-colour MIP | Existing build, glance not yet implemented |
| A | Enduro 3, Enduro 2, Fenix 7X / 7X Pro, Fenix 8 Solar 51mm | 280×280, 64-colour MIP | Run API, resources, memory, UI, button and step-history tests per device |
| B | Enduro original, Fenix 6X, Fenix 7 / 7S, Fenix 8 Solar 47mm | 240–280 MIP | Check API & background memory; adaptive UI and input |
| C | Fenix 8/9 AMOLED, Forerunner 265/965/970, Venu, vívoactive | Varying AMOLED and MIP | Display resolution, color conversion, touch/button and performance variants |
| Not targeted initially | Fenix 3 and other legacy API 1.x watches | Legacy | Current app's minimum API 3.2.0 excludes these; full rework required |

Garmin's official device list: https://developer.garmin.com/connect-iq/compatible-devices/ .
Enduro 4 details: https://developer.garmin.com/connect-iq/device-reference/enduro4/ .

**Acceptance per added watch:** simulator build and run, manifest/device resources, memory headroom (app, background and glance), persisted step correctness, timer/battery budget, layout/test frames, physical controls, optional audio/haptic API guards. Add devices gradually.

## 2. Activity enriches gameplay without excluding anyone

**Core experience:** Every pet hatches, eats, plays, has moods and poop, and can reach *every* common and rare family evolution, museum completion and ongoing mastery through normal elapsed time, care and mini-games **with zero movement or watch step count**. No death or prolonged punishments. Base growth about 25 days to Legendary (provisional), real activity can accelerate toward minimum age 21 days. All numbers are test targets, not final balance.

**Bonus adventure system:** Real activity is one rewarding way to earn additional **Adventure Energy**. Spending energy leads to encounters, exploring an in-game map, cosmetic accessories, toy unlocks, quicker collectible progress and occasional extra rewards. These are *extra experiences*, not missing pet-care functionality. A nonactive player can earn the same adventure energy by longer/alternative in-game care and games; no exclusive evolutionary species or rare collection should require walking.

Suggested first balancing pass, intentionally configurable:
- Up to one Adventure Energy for a small personally-scaled milestone (example 2,000 steps OR 10 active minutes on supported devices OR corresponding wheelchair pushes OR several short minigame completions).
- Further meaningful milestones can give extra exploration attempts, food stock, surprise treasures and cosmetic variations, subject to a noncompulsive daily cap.
- Use **personal selectable activity target levels** (gentle/moderate/ambitious) rather than enforcing a one-size-fits-all step goal. No shaming/no streak punishment.
- Reaching a milestone by more than one physical metric grants it **once**, not separately for steps plus active minutes for the same effort.
- Standalone games and care always provide a path to the same content, albeit with a different effort mix.
- Bonus step rewards already earned by prior versions must be migrated/preserved.
- Walking steps from `ActivityMonitor.getInfo().steps`, active minutes from `ActivityMonitor.getInfo().activeMinutesDay`, wheelchair pushes from `ActivityMonitor.Info.pushes` if available (CIQ 4.2.3+). These measurements may be null/not available; guard all access and validate behavior. Do not assume every workout type is available to an unrelated Connect IQ watch app. Intensity minutes (total) may count vigorous activity double; avoid treating this as literal elapsed time.

Important: The visual theme can become more lively as the player earns adventure energy (new scenery, rare idle actions, accessories), while the pet's health, baseline evolution and family access are never withheld. Activity's advantage is more encounters/rewards, not merely 4 days saved at Legendary.

## 3. Native TekuTekuBeast Glance in the same installed app

**Enduro 4: YES, feasible.** Modern Garmin Connect IQ watch apps can implement `Application.AppBase.getGlanceView()` returning a `WatchUi.GlanceView`. The app keeps `type="watch-app"` and its existing application ID. No separate widget/app install. The user's Enduro 4 glance implementation has a **65,536-byte Glance memory limit** (app has larger budget); design accordingly.

**Minimal glance UI:** left: tiny static or very lightly animated current creature sprite; right: "Pip" / happiness heart / growth-to-next percent or bar; optionally one small poop/needs-attention icon. Keep legible and compact, no long title/app name clutter. Use cached saved summary, avoid rendering large sprite atlases or running care timers in the glance. Never punish a user for not opening the glance. A glance should not emit audio or vibration.

**Interaction:** from watch face, swipe up or press DOWN to access Glances; select TekuTekuBeast entry to launch its **full original Pet/Care/Play app**. Garmin may apply an inactivity timeout when launching through the glance, so test whether longer mini-games should ask the user to open the normal app instead. The glance is a shortcut and preview, not an independently running game.

**Enduro 4 on-watch user steps (after feature is implemented and app updated):**
1. From watch face press DOWN (lower-left) to show the glances list.
2. Choose `Edit`, then `Add` and pick `TekuTekuBeast`.
3. Scroll through the glance list, select TekuTekuBeast, and open the full pet game.
Garmin manual: https://www8.garmin.com/manuals/webhelp/GUID-25EFCCBC-D0EB-4E1B-AE9F-B4B900891C20/EN-US/GUID-BBD01FB4-CFD0-4D5F-8B03-C013380FB47A.html

**Tests:** getGlanceView in `source/TekuTekuBeastApp.mc` and new `TekuTekuBeastGlanceView.mc`; verify glance memory, saved game snapshot, 0 steps, needs-clean icon, correct simulator glance launch, timeout/no background timer, click-to-open gameplay, real device glance adding. The glance must not modify step or care save when merely appearing. No compatibility promises for older CIQ 3.x until verified.

Sources:
- https://developer.garmin.com/connect-iq/api-docs/Toybox/Application/AppBase.html
- https://developer.garmin.com/connect-iq/articles/user-experience-guidelines/Entry_Points.html
- https://developer.garmin.com/connect-iq/api-docs/Toybox/ActivityMonitor/Info.html
- https://developer.garmin.com/connect-iq/api-docs/Toybox/ActivityMonitor/History.html
