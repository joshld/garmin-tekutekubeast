# Current gameplay and features

Implemented behavior through v0.5.2, the Issue #19 refactor, Issue #21 lighting
Issue #17 sleep interactions and Issue #20 battles (source changes, not a new Store release).
This is the current gameplay guide, not an implementation wishlist. Normal play
is native and offline; activity is optional, with no death, lost XP, de-evolution
or recovery-day punishment. See [current validation](VALIDATION.md) for tested
scope and [physical acceptance](WATCH_ACCEPTANCE.md) for hardware limitations.

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

Normal Bounce stages use 4 / 3 / 2.25 seconds per star; Easy Mode is slower.
Memory demonstrations include a neutral 250 ms gap between all cues, including
repeated moves. Rounds do not consume separate daily rewarded-session slots.

## Wild battles

Actions > Play > Wild battles offers queued encounters, practice, Later and
Decline next. Eggs must hatch first; a sleeping beast must explicitly Wake Up.
UP/DOWN chooses among four actual named techniques; SELECT uses one and BACK
pauses. Touching a move chooses/uses it. Each turn saves before its short visual
reaction, so closing/reopening resumes the same opponent, HP, seed and turn.
Older renderers without compact vector fonts show a full-width named-move
selector instead of the 2x2 grid; UP/DOWN still selects all four techniques.
HP is temporary: defeat never injures, kills, de-evolves or spends the real pet's
energy, friendship, items or growth. No fast reactions or exercise are required.

All 18 battle-capable forms have four distinct named techniques (72 stable move
IDs). Pip/Nimble remain neutral; rare techniques require an already-earned rare
form. Techniques cover damage, protection, two-hit boosts and signatures with
two-action cooldowns. Family affinities, evolution, personality, friendship and
technique experience affect small combat bonuses. Opponents match evolution
stage; no real pet is used as an opponent. Matches usually take a handful of
turns, aiming at 30-60 seconds without a time limit; 20 turns settles a draw.

One free encounter is offered each new local day. Care growth milestones (100,
200, 300), completed reward-bearing Tiny Adventures and genuine lifetime-step
milestones (2,500, maximum two step offers/day) add opportunities. The queue holds
four; excess discoveries are consumed rather than accumulating an unbounded
backlog. Historical pre-feature steps/trails are baselined, not replayed. Opening
the app reconciles discoveries without interrupting activities or adding any GPS,
background work or notifications. Declining/postponing never costs anything.

The first five completed wild matches/day grant separate Battle XP (12 victory,
5 defeat, 7 draw) and up to three mastery points per used technique. The wild
journal records encountered forms. Practice is unlimited without XP/mastery or
journal rewards. Techniques and Wild journal in the battle menu show progress.
Battle progression does not alter the existing evolution/step-XP ledgers or
mini-game reward slots. Reopening cannot claim a match twice. The separate
`battle.v1` save is isolated in Developer Mode and independent of the canonical
pet save. There is no multiplayer or watch-to-watch communication yet.

## Separate ledgers

- `xp`: genuine lifetime watch-recorded steps, deduplicated by local day.
- `baseGrowth`: elapsed time since v0.4 migration / the current pet's creation.
- `careGrowth`: bounded care and mini-game growth, never Garmin steps.
- `activityBonus`: additional growth from shared physical milestones, including
  active minutes and wheelchair pushes; it never changes watch XP.
- Current-pet growth combines passive/care/activity growth and genuine steps above its
  per-pet baseline. Retiring a Legendary never resets lifetime watch XP.

Legacy keys remain intact. Migration retains an already-earned stage as a
floor, recovers calendar age for early saves without `birthEpoch`, and retains
the existing family, snacks, friendship and watermarks. No passive growth is
retroactively credited before migration. Existing app identities stay fixed; public and Developer Beta saves are separate.
See [build/save safeguards](BUILD.md).

## Default balance (provisional, testable in Dev Tools)

12,000 passive growth/day, up to 300 care growth/day, plus one growth per newly
eligible genuine step. Positive elapsed growth is not capped to one day;
negative clock movement earns nothing. Care decay alone is bounded to 24h.

| Stage | Growth | Minimum age |
|---|---:|---:|
| Egg | 0 | — |
| Pip | Natural hatch at about 24h | Acceleration floor 8h |
| Nimble | 20,000 | 2 days |
| Adult | 70,000 | 7 days |
| Champion | 150,000 | 14 days |
| Legendary | 300,000 | 21 days |

Egg acceleration uses genuine activity / interaction, not an instant 2,000-step
hatch. An existing Pip never reverts. The legacy growth gate is retained: care alone
at eight hours does not hatch an egg below that gate. The golden tests preserve
this behavior; accelerated duration alone is not sufficient. Zero-step passive-only Legendary takes
about 25 days; consistent activity can reach the 21-day age floor. Mastery then
advances every 25,000 additional growth, including passive/care growth.

Step/minute/push rewards share a daily milestone watermark: default 1,000 bonus
growth per milestone, at most five/day. Activity types are not inferred for an
unrelated watch app, and games never fabricate Garmin activity.

## Automatic families

Adult family selection combines activity pattern bonuses and care personality.
Patting/feeding favours Grove; Beast Bounce favours Ember; cleaning/rest favours
Tide; Follow My Lead favours Wisp. Trail choices and toys also influence scores.
Activity can add Grove/Ember/Tide biases but never locks out a nonactivity path.
Ties use a durable birth/serial seed, not an unconditional Wisp fallback. The
family then stays locked except explicit temporary developer previews.

| Family | Adult | Champion | Legendary | Rare variant |
|---|---|---|---|---|
| Grove | Mossbit | Thornbuck | Verdant Elder | Lumenhart |
| Ember | Cindercub | Pyrolynx | Solflare | Ashen Phoenix |
| Tide | Puddlefin | Currentail | Leviathan | Moonwater Kirin |
| Wisp | Flicklet | Nocturne | Starweaver | Eclipse Eidolon |

## Earned exceptions and collection

The first standard Legendary in each family registers in the museum and earns
a Star Charm. A Legendary with friendship 70 can spend a Charm on its same-family
rare variant. Every requirement is attainable without activity. Rare artwork
currently uses an earned crown overlay, not a separate full sprite atlas.

Keep a favourite forever with ongoing mastery, or explicitly confirm Archive
and start egg after Legendary. The last archived pet's full snapshot is retained;
normal/rare family registrations and inventory remain. This is never automatic.
The trail Compass is currently a cosmetic collectible; a future cross-family
Wanderer's Compass exception is not implemented.

## Activity rewards and limitations

Real steps, supported active minutes and wheelchair pushes can grant additional
Adventure Energy. Overlapping metrics share one daily milestone watermark.
Care/games grant the same energy and access to the same eight discovery types.
Activity targets are selectable; no streak loss or exercise prompts.

Garmin history only exposes a recent window (normally seven days). Missed
background events beyond that cannot be reconstructed. Uninstalling may remove
Garmin Storage: upgrade the same app, do not uninstall to update.

See [current validation](VALIDATION.md) for actual simulator/hardware status.

## Developer Mode - personal builds only

Build explicitly with `-Owner` to retain these tools on the personal Enduro 4.
Public `.iq` exports exclude them at compilation and now use a separate public
UUID. The existing Developer Beta keeps its original UUID and pet; both apps
can coexist with separate saves. Public starts a new pet, with no automatic
copy or migration of the developer pet. See [build identities and safe packaging](BUILD.md).

Personal build: Actions > Settings > Developer > Enable temporary test. The normal screens
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
reactions. See [art assets and prompts](../art/README.md). Only current frames are
cached; Pet resources restore exact v0.4 pixels and padding, retain mirrored
walking poses and native nearest-neighbour sizes on MIP and AMOLED. Species names
remain on Details, not the Pet page. Apple/heart needs appear only for attention;
poop sits on the floor. Sleeping creatures curl up; awake tired creatures use
quiet looking/blinking poses, without wandering or pretending to be asleep.

The same watch app implements a read-only native Glance: current sprite/name,
mood, growth and cleanup status. No Glance-owned animation timer, save mutation
or audio. See [watch acceptance](WATCH_ACCEPTANCE.md) for confirmed physical reports and
[compatibility](COMPATIBILITY.md) for older-profile Glance limitations.

Sound defaults OFF; gentle vibration ON, with an optional expressive pattern.
Settings are independent and respect supported system mute/vibration/DND flags.
Feedback test shows watch-tones, DND, unsupported and error status; Garmin Alert
Tones must be enabled for sound. No background or bedtime alerts. Motion OFF/LOW/NORMAL is retained.

Settings > Bedtime follows guarded watch upcoming/typical schedule values, with
a configurable local fallback (22:00-07:00), MANUAL/OFF options and auto lights.
Sleep restores energy lazily. Actions > Lights shows the selected AUTO / ON / OFF
mode, not an inverted suggestion based on current darkness. AUTO follows the
existing Bedtime dim preference (renamed from Auto lights); disabling that
preference leaves AUTO lighting on. ON and OFF are temporary one-hour overrides;
the Lighting menu marks the selected mode and shows the applied state and minutes
until AUTO. Choosing AUTO cancels an override immediately. Overrides survive
closing/reopening and expire at their saved absolute deadline, without a timer
or save write just for expiry. A clock rollback outside the one-hour window
falls back to AUTO rather than extending the override indefinitely.

At night ON keeps the native creature bright over a soft local pool; OFF removes
the pool and dims the creature on tint-capable renderers, keeping needs/menus
readable. Older renderers retain the original sprite with the same local-light
distinction. No artwork is replaced. In daylight OFF dims foreground terrain,
not the actual sky. Neither lighting mode changes sunrise/sunset, sun/moon
positions, scheduled sleep, Garmin backlight or Sleep Focus. Watch schedule/API
agreement still needs hardware testing; choose MANUAL if the reported source
does not match the watch's actual schedule.

While asleep, Feed, Pat, Play and Clean remain visible but show the silent
notice `Beast is asleep.` without spending items/energy or granting rewards.
An in-progress game checkpoints and pauses at bedtime; wake explicitly before
resuming it. Actions > Wake Up appears only while sleeping, needs no confirmation
and keeps the beast awake through the current nap/night window. Later nights
retain the normal schedule. Rest deliberately starts a new one-hour nap, but its
existing energy/care bonus remains once daily; repeating Wake Up/Rest earns no
extra bonus and does not reset other care or game limits.

Waking a nap before five minutes or after thirty minutes causes no grumpiness;
the small bell-shaped response peaks around 15-20 minutes. Effective happiness
temporarily falls by at most two points, recovering within five minutes. Night
waking causes at most one point for two minutes, with no effect near bedtime or
scheduled waking. Natural waking has no penalty. Saved base happiness and family
personality are never reduced by waking. Reopening retains the bounded wake/grump
window; clock rollback before waking or a time-zone change invalidates the wake
override. Lighting and the astronomical sky remain independent: waking does not
cancel AUTO bedtime dimming, change the sky or generate sound/vibration alerts.

Settings > Outdoor world selects Forest, Meadow, Lakeside or Garden, or AUTO
for a stable family-based choice. Sun / location uses retained watch/weather
cache or confirmed approximate coordinates; Positioning permission never starts
GPS. Native sunrise/sunset with offline calculation fallback is independent of
bedtime. No location is transmitted. FIXED 06-18 is the labelled last resort;
the moon arc is decorative, not a lunar ephemeris. No Pet-screen clock is added.

See the [v0.5.1 release notes](releases/v0.5.1/RELEASE_0_5_1.md) and
[v0.5.1 artwork/captures](../art/store/v0.5.1/README.md).
The retained v0.4 500px family-art cover is promotional artwork, not a screenshot.
These files are not evidence of a Garmin submission.
