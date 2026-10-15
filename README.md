# TekuTekuBeast (テクテクビースト) — step-powered virtual pet for Garmin Enduro 4

The Connect IQ application identifier and internal storage keys remain stable to preserve existing watch save data when upgrading.

**Development build — compiled with Connect IQ SDK 9.2.0 and exercised in the Enduro 4 simulator profile (firmware 6.0.3). It has not yet been installed on physical Enduro 4 hardware.**

TekuTekuBeast is a *native Garmin Connect IQ watch app*, coded in Monkey C. It reads **step counts measured by the watch itself**, even when you have not started an activity. Garmin background 1,000-step milestones plus on-opening reconciliation help update progress without running a permanent foreground app. No phone app, cloud or account is required.

## What the prototype is designed to do
- Egg → Pip → Nimble → Adult → Champion → Legendary using **steps and elapsed days**.
- Four automatic evolution families based on recent activity: **Grove**, **Ember**, **Tide** and **Wisp**.
- 1 XP per newly counted step, saved persistently with per-day step watermarks to avoid double credit.
- Earn one snack per 2,500 new steps (max 12), feed your creature or pat it to increase friendship.
- No permanent pet death, no XP penalties for resting.
- Unlimited post-Legendary Mastery levels: one extra level per 25,000 steps after 300,000.
- Three app screens: Pet / Care / Stats. UP/DOWN navigates; SELECT pats or feeds.

**Device & glance roadmap:** [Watch compatibility, activity bonuses and on-watch Glance](docs/ACTIVITY_AND_GLANCE.md) — design only, not yet in current app.

**Review amendments (newest requirements):** [Inclusive ~3–4-week progression, on-watch Developer Mode, hatch pacing, cleaner UI and more Garmin watches](docs/V0_4_REVIEW_AMENDMENTS.md). Proposed only; no gameplay code changed.

**New v0.4 proposal (not yet implemented):** [Care, games, poop, animation and sound specification](docs/GAMEPLAY_V0_4.md) · [Prioritised Codex implementation plan](docs/CODEX_V0_4_TASKS.md). These proposed features are not part of the current build.

See [evolution design](docs/EVOLUTION_DESIGN.md) for stage numbers, complete species trees, rare forms, Star Charms, retirement and collection roadmap.

## Build target and setup

Garmin **Enduro 4**: `enduro4`, 280×280 MIP. Native `watch-app`, not a watch face.

1. Install [Garmin Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/) and its VS Code Monkey C extension.
2. Open the repository and select the Enduro 4 device in the SDK.
3. Create/select a developer key, compile and run in the Enduro 4 simulator.
4. Verify history reconciliation, daily rollover, background events, save-state migration, controls and battery before sideloading to the watch.

**Status:** experimental. The first artwork pass adds concept-inspired pixel-art sprites for Egg, Pip and Nimble, compact watch layouts, a foreground idle bob and care-action feedback. Adult/Champion/Legendary family sprites still use the previous primitive drawings; rare evolutions, museum/retirement, collections and expression animations remain planned. See the [artwork notes](art/README.md) for scope and the isolated simulator preview. Simulator validation covered first-launch baselining, step credit, duplicate background-event protection and persistence across an app restart; physical-watch behaviour still needs verification.

## Important caveats
- Only steps recorded on the Enduro 4 itself are reliably included by its step event.
- Background step callbacks are periodic at each 1,000-step milestone; foreground app reads the precise current count.
- Garmin history can recover only up to seven recent days; missing events beyond that may lead to lost credit.
- On installation, steps already taken that day become the initial baseline.
- Physical Enduro 4 behaviour needs verification against Garmin Connect IQ SDK.

Sources: [Background services](https://developer.garmin.com/connect-iq/articles/core-topics/Backgrounding.html), [ActivityMonitor](https://developer.garmin.com/connect-iq/api-docs/Toybox/ActivityMonitor.html).
