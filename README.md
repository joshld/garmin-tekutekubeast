# TekuTekuBeast (テクテクビースト) — step-powered virtual pet for Garmin Enduro 4

**Project formerly known as StepPal.** The Connect IQ application identifier remains unchanged to preserve existing watch save data when upgrading. The internal storage keys also remain unchanged.

**Source prototype — not yet compiled, simulator-tested or installed on an Enduro 4.**

TekuTekuBeast is a *native Garmin Connect IQ watch app*, coded in Monkey C. It reads **step counts measured by the watch itself**, even when you have not started an activity. Garmin background 1,000-step milestones plus on-opening reconciliation help update progress without running a permanent foreground app. No phone app, cloud or account is required.

## What the prototype is designed to do
- Egg → Pip → Nimble → Adult → Champion → Legendary using **steps and elapsed days**.
- Four automatic evolution families based on recent activity: **Grove**, **Ember**, **Tide** and **Wisp**.
- 1 XP per newly counted step, saved persistently with per-day step watermarks to avoid double credit.
- Earn one snack per 2,500 new steps (max 12), feed your creature or pat it to increase friendship.
- No permanent pet death, no XP penalties for resting.
- Unlimited post-Legendary Mastery levels: one extra level per 25,000 steps after 300,000.
- Three app screens: Pet / Care / Stats. UP/DOWN navigates; SELECT pats or feeds.

See [evolution design](docs/EVOLUTION_DESIGN.md) for stage numbers, complete species trees, rare forms, Star Charms, retirement and collection roadmap.

## Build target and setup

Garmin **Enduro 4**: `enduro4`, 280×280 MIP. Native `watch-app`, not a watch face.

1. Install [Garmin Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/) and its VS Code Monkey C extension.
2. Open the repository and select the Enduro 4 device in the SDK.
3. Create/select a developer key, compile and run in the Enduro 4 simulator.
4. Verify history reconciliation, daily rollover, background events, save-state migration, controls and battery before sideloading to the watch.

**Status:** experimental. The visual creature is drawn with native canvas primitives as a placeholder. Unique pixel-art creature sprites, rare evolutions, museum/retirement, collections and animations are planned but not yet implemented. The Garmin SDK is not available here for compilation.

## Important caveats
- Only steps recorded on the Enduro 4 itself are reliably included by its step event.
- Background step callbacks are periodic at each 1,000-step milestone; foreground app reads the precise current count.
- Garmin history can recover only up to seven recent days; missing events beyond that may lead to lost credit.
- On installation, steps already taken that day become the initial baseline.
- Physical Enduro 4 behaviour needs verification against Garmin Connect IQ SDK.

Sources: [Background services](https://developer.garmin.com/connect-iq/articles/core-topics/Backgrounding.html), [ActivityMonitor](https://developer.garmin.com/connect-iq/api-docs/Toybox/ActivityMonitor.html).

## Repository rename

The GitHub repository's `garmin-steppal` slug should be renamed to `garmin-tekutekubeast` using **Settings → General → Repository name → Rename** on GitHub. This renames the remote without changing commit history. After changing it, update your local Git remote via:

```sh
git remote set-url origin https://github.com/joshld/garmin-tekutekubeast.git
```
