# TekuTekuBeast

A native, offline Garmin virtual-beast game. Grow through time, care and play;
genuine watch activity adds growth and extra adventure opportunities. No phone,
internet connection, exercise requirement, death or recovery-day punishment.

**v0.5.1 signed beta candidate; focused Enduro 4 checks passed.** Exact v0.4 creature pixels,
broader two-dimensional roaming, four outdoor environments, offline local
sunrise/sunset skies, clearer memory cues and livelier Bounce timing are
implemented. Battery work skips unchanged saves/redraws without changing real
activity or growth. See [current validation](docs/V0_5_1_VALIDATION.md) and
[release/update instructions](docs/RELEASE_0_5_1.md).
Physical-watch acceptance remains open; this candidate has not been published.
Previous [v0.5 evidence](docs/V0_5_VALIDATION.md),
[v0.5 signed hashes](docs/RELEASE_0_5_0_VERIFICATION.md),
[v0.4 evidence](docs/V0_4_VALIDATION.md) and [device matrix](docs/DEVICE_MATRIX.md)
remain historical records, not automatic v0.5.1 passes.

## Play

- Pet / Care / Details: UP and DOWN change pages; SELECT opens Actions.
- Actions: Feed, Clean, Play, Pat, Rest, Collection and Settings. BACK returns.
- Two free daily meals, earned snacks, fullness, joy, energy, cleanliness, poop
  and friendship. Feeding schedules poop; Clean clears it directly.
- Beast Bounce: move UP/DOWN between platforms and SELECT to hop into falling
  stars; fifteen targets, three increasing stages, combos and scores.
- Follow My Lead: copy the beast's hop/smile/look, progressive 3/4/5 sequences,
  two chances per round, button/touch/timed-SELECT input.
- Tiny Adventures: choose a destination, travel three stops, make careful/bold
  choices and discover treasure. One Adventure Energy pays for the whole trip.
  No-energy scouting is unlimited practice without loot; care/play earns energy.
- Results offer Play Again / Exit. BACK pauses; checkpoints resume after restart
  or watch inactivity without repeated energy deductions or rewards.
- Three rewarded games/day, then unlimited practice. Games never create steps.
- Collect food, toys and cosmetics; register normal and rare family Legendaries.
  Keep a favourite forever with mastery, or explicitly archive and start an egg.
- Touch swipes navigate where available; Memory also supports a timed SELECT
  choice on watches without UP. Dedicated app Menu input can advance selection
  on touch-first models; five-button system shortcuts are not intercepted.

## Growth and activity

Genuine watch steps remain a separate lifetime ledger. Default growth is 12,000
per elapsed day, optional care growth (300/day), plus genuine step growth.
Passive-only Legendary is about 25 days; active play can reach the 21-day age
floor. Egg naturally hatches around 24 hours; care or activity can accelerate it,
but never before eight hours. Existing evolved pets never revert to eggs.

Grove, Ember, Tide and Wisp have nonactivity personality paths. Step milestones,
supported active minutes and wheelchair pushes grant additional Adventure Energy
and growth bonuses (default 1,000 growth per milestone, capped at five/day);
overlapping physical metrics are not credited separately. Care and games earn
the same exploration currency and access to the same discoveries. Activity type
identification is not assumed for an unrelated Connect IQ watch app.

See [evolution rules](docs/EVOLUTION_DESIGN.md) for the actual implemented tree.

## Developer Mode — same installed app

Actions > Settings > Developer > Enable temporary test. The normal screens
remain, with a small DEV indicator and Dev Tools:

- 1× / 5× / 20× / 100× virtual clock; +1 hour / +1 day / +7 days.
- Force stage/family; set needs; grant test stock; spawn/clean poop; sleep/evolve.
- Preview poses, games, sound and vibration; change test balancing values.
- Bedtime, waking, sleepy, happy-roaming and all-needs scenarios.
- Reset to the real-pet copy, a fresh egg, a hungry/messy pet or a Legendary.

DEV is an in-memory test branch. Discard is the default and only way back to real
play; app restart also discards it. Real time, Garmin counters and real storage
are never fabricated. Exiting reloads the genuine save and reconciles watch
steps recorded during testing. There is no second Developer Lab app to install.

## Artwork, Glance and feedback

All 15 normal species have concept-inspired pixel art and six poses, plus
wandering, hopping, blinking, looking, eating, sleeping, cleaning and evolution
reactions. See [art assets and prompts](art/README.md). Only current frames are
cached; Pet resources restore exact v0.4 pixels and padding, retain mirrored
walking poses and native nearest-neighbour sizes on MIP and AMOLED. Species names
remain on Details, not the Pet page. Apple/heart needs appear only for attention;
poop sits on the floor. Sleeping/tired creatures stay curled instead of wandering.

The same watch app implements a read-only native Glance: current sprite/name,
mood, growth and cleanup status. No Glance-owned animation timer, save mutation
or audio. The user confirmed v0.4 availability on their physical Enduro 4 on
16 October 2026; selection-to-game and timeout behaviour remain unverified.
See the [hardware acceptance log](docs/WATCH_ACCEPTANCE.md) for the exact scope.

Sound defaults OFF; gentle vibration ON, with an optional expressive pattern.
Settings are independent and respect supported system mute/vibration/DND flags.
Feedback test shows watch-tones, DND, unsupported and error status; Garmin Alert
Tones must be enabled for sound. The user verified v0.4 sound/vibration, not the
new patterns. No background or bedtime alerts. Motion OFF/LOW/NORMAL is retained.

Settings > Bedtime follows guarded watch upcoming/typical schedule values, with
a configurable local fallback (22:00-07:00), MANUAL/OFF options and auto lights.
Sleep restores energy lazily. Lights On/Off overrides only the virtual world for
one hour; it never changes Garmin backlight or Sleep Focus. Watch schedule/API
agreement still needs hardware testing; choose MANUAL if the reported source
does not match the watch's actual schedule.

Settings > Outdoor world selects Forest, Meadow, Lakeside or Garden, or AUTO
for a stable family-based choice. Sun / location uses retained watch/weather
cache or confirmed approximate coordinates; Positioning permission never starts
GPS. Native sunrise/sunset with offline calculation fallback is independent of
bedtime. No location is transmitted. FIXED 06-18 is the labelled last resort;
the moon arc is decorative, not a lunar ephemeris. No Pet-screen clock is added.

See the [v0.5.1 release notes](docs/RELEASE_0_5_1.md) and
[v0.5.1 artwork/captures](art/store/v0.5.1/README.md).
The retained v0.4 500px family-art cover is promotional artwork, not a screenshot.
These files are not evidence of a Garmin submission.

## Build and test (Windows)

Accepted profiles cover Enduro 4/3, Enduro 2 via Garmin's Fenix 7X definition,
Fenix 7/7S/7X/7X Pro, Fenix 8 Solar 47/51mm, Forerunner 265/955/965,
Venu 3 and vivoactive 5. These are simulator-tested profiles, not physical-watch
certification. Original Enduro is excluded for artwork RAM exhaustion; Fenix
6X is excluded because its 32KB background budget crashes step reconciliation.
See [current v0.5.1 evidence](docs/V0_5_1_VALIDATION.md), including memory;
the [v0.4 matrix](docs/DEVICE_MATRIX.md) retains historical tests and SDK aliases.

Install Garmin Connect IQ SDK/device profiles and Java 17. Keep `developer_key`
local and out of Git. With the SDK simulator open:

```powershell
./scripts/build.ps1
./scripts/run-simulator.ps1
./scripts/build.ps1 -Tests -Output bin/v051-tests.prg
./scripts/run-simulator.ps1 -Tests -Program bin/v051-tests.prg
./scripts/device-matrix.ps1 -EvidencePrefix v051
./scripts/unit-matrix.ps1 -EvidencePrefix v051
./scripts/build.ps1 -Release -Output bin/v051-release.prg
./scripts/build.ps1 -Export -Output bin/TekuTekuBeast-0.5.1.iq
```

`scripts/check_project.py` is structural preflight, not a compiler. The internal
visual/matrix QA harness uses a separate test ID and in-memory model; it is not
the user's Developer Mode and must never be uploaded to the Store.

## Save and platform limits

The application ID is unchanged: `54A4F9D3B6584CA4B01C232D20438E5B`.
Versioned storage keeps genuine XP, rewards and their day watermarks in one
record, retains legacy keys and a migration snapshot, and never merges DEV
state. Upgrade the existing app; uninstalling may remove Garmin Storage.

Garmin history normally covers seven recent days. If background events fail and
the game is not opened longer than that, older missing steps cannot be recovered.
Positive elapsed growth still catches up over long absences; care decay is
bounded. Optional retirement retains the last full archived pet and collection
registrations; it is never automatic.
