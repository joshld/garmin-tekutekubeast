# Current gameplay and features

Current source behavior includes offline battles, family tendencies and care
difficulty. The latest family/care changes are not yet a Store release.
This is the current gameplay guide, not an implementation wishlist. Normal play
is native and offline; activity is optional, with no death, lost XP, de-evolution
or recovery-day punishment. See [current validation](VALIDATION.md) for tested
scope and [physical acceptance](WATCH_ACCEPTANCE.md) for hardware limitations.

## Play

- Pet / Care / Details: UP and DOWN change pages; SELECT opens Actions.
- Actions: Feed, Clean, Play, Pat, Rest, Collection and Settings. BACK returns.
- Two free daily meals, earned snacks, fullness, joy, energy, cleanliness, poop
  and friendship. Up to five poops accumulate; each Clean removes exactly one.
- Beast Bounce: move UP/DOWN between platforms and SELECT to hop into falling
  stars; fifteen targets, three increasing stages, combos and scores.
- Follow My Lead: copy the beast's hop/smile/look, progressive 3/4/5 sequences,
  two chances per round, button/touch/timed-SELECT input. BEAST marks the demo;
  YOU marks responses. Dark highlights show registered UP/SELECT/DOWN input,
  with progress counting repeated presses. Mistakes show NEED versus GOT.
- Tiny Adventures: choose a destination, travel three stops, make careful/bold
  choices and discover treasure. One Adventure Energy pays for the whole trip.
  No-energy scouting is unlimited practice without loot; care/play earns energy.
  - Results offer Play Again / Exit. BACK pauses; checkpoints resume after reopening
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

### Alerts and mini-game resume

All three games checkpoint and stop their timer when hidden/inactive or stopped.
BACK or reopening shows PAUSED with Resume (default), New Game, Exit and Abandon.
UP/DOWN selects; SELECT confirms. Resume shows a frozen **3, 2, 1** readiness
countdown, measured by the monotonic clock rather than callback counts. Queued
callbacks cannot shorten it. That confirmation/repeated dismissal input cannot count as
a move, jump or adventure choice. Remaining ticks, sequence position, jump/lane,
travel, seed and reward/energy transaction are retained. Detected inactive state
or a timer delivery gap exceeding its expected period by more than one second
also pauses without advancing the game. No system notification settings change.
Follow My Lead then replays the current sequence, including neutral gaps,
before accepting input. Round, difficulty, correct-input cursor, remaining
response time, retries, score and seed are preserved with no penalty. Interrupted
replays can be shown again; they never regenerate the sequence or award progress.

New Game discards the old session without a reward, defeat or refund. Tiny
Adventures asks for confirmation: a new paid expedition costs one additional
Energy; with no Energy it is a no-loot scout. Exit **saves** the session and returns
directly to the main Pet screen. Reopening resumes that same ID without another
Energy charge. The separate Abandon action defaults to Cancel, requires explicit
confirmation, discards the saved session without reward/refund and returns to Pet.
Only New Game/Abandon invalidates the old session ID and its callbacks.

Connect IQ exposes [app lifecycle callbacks](https://developer.garmin.com/connect-iq/api-docs/Toybox/Application/AppBase.html)
and [view visibility callbacks](https://developer.garmin.com/connect-iq/api-docs/Toybox/WatchUi/View.html),
but they are not a promise that every OS banner/alert will report lost activity.
An overlay leaving both app activity and timer delivery unchanged is not
reliably detectable. [Notifications](https://developer.garmin.com/connect-iq/api-docs/Toybox/Notifications.html)
posts/manages the app's own notifications; no supported all-alert suppression
or global DND setter was identified. This applies regardless of alert source.

Optional owner-controlled quieting on Enduro 4: from the watch face, hold MENU,
then Watch Settings > System > Do Not Disturb; turn it back off yourself after
playing if desired. See Garmin's [Enduro 4 System Settings](https://www8.garmin.com/manuals/webhelp/GUID-25EFCCBC-D0EB-4E1B-AE9F-B4B900891C20/EN-US/GUID-DB1A9D65-27AA-4762-84B4-2A9C52C75D12.html).
Actual phone messages/calls, native alarms and other overlays still require
owner hardware testing; simulator lifecycle tests cannot prove universal coverage.

## Poop and cleaning

Settings > Care Difficulty saves Low Maintenance, Normal (default), or High
Maintenance. Switching settles elapsed care at the old rate first; it never
resets progress, needs, rewards or pending food/natural-waste deadlines.

| Mode | Food/day | Joy/day | Natural waste | Digestion delay | Extra food waste/day |
| --- | ---: | ---: | --- | --- | ---: |
| Low Maintenance | -6 | -4 | Every 24 hours | 4 hours | At most 1 |
| Normal | -20 | -12 | Every 16 hours | 3 hours | At most 2 |
| High Maintenance | -30 | -20 | Every 12 hours | 2 hours | At most 3 |

- Care settles hourly with exact fractional remainders; switching settles partial
  hours too. A single absence charges at most 72 hours of decay, then advances
  the high-water clock through the entire absence. Food bottoms at 10, joy at
  15; no death or permanent damage. Reopening/rollback cannot replay decay.
- Each newly credited 2,000 genuine steps costs one food in Low/Normal, two in
  High. At most five units/day; food caps 3/5/8, energy caps 2/4/5. Every second unit gives one
  joy (maximum two/day). Beyond 10,000 steps there is no further care demand.
  Existing credited steps on upgrade are not charged again; historical XP
  catch-up remains intact. Mode switches never replay previously charged units.
- Two free daily meals each restore 20 food. Snacks/berries restore six. Food
  gives three joy, pats five, rewarded game wins eight (losses three), cleaning
  three at most once/four hours. Friendship, care-growth and session reward
  limits remain. Toys give three joy only while the daily care-growth budget
  has room; repeated tapping cannot farm unlimited happiness. Existing rest
  and scheduled-sleep energy recovery remains.
- Natural waste needs no feeding or steps. Meals add two digestion units,
  snacks/berries one; three matured units produce one extra poop. Four compact
  pending batches/eight units maximum survive reopening. Excess feeding adds
  no hidden waste backlog. Deadlines retain their original mode; subsequent
  meals/natural intervals use the selected mode. No immediate poop per meal.
- Five fixed grass slots persist as a bit mask. Every arrival lowers cleanliness
  by 15. Each Clean removes only the leftmost occupied slot, restoring 15 up to
  the remaining-waste ceiling; the final Clean restores 100. Other poops stay
  put. Events due at capacity/daily cap are consumed, preventing hidden refills.
- Mood priority: sleep, temporary grumpiness, tiredness, severe hunger,
  waste/poor cleanliness, hunger, low joy. Poor needs slow wandering and add
  subdued looks. Existing feeding/cleaning/rest/new-poop reactions remain;
  sleeping actions stay blocked until deliberate waking.
- Poop retains its 7x6 silhouette, scale and positions, with a black internal
  outline, brown fill and restrained highlights. No ring, label or bitmap cache.
- Additive canonical v4 migration defaults existing pets to Normal, preserving
  needs, waste slots/timer, progress, inventory and identities. New care time
  starts at upgrade; no invented old decay or meals. Developer Mode is isolated.
  No new timer, GPS, polling or background registration; Glance projects the
  same food/joy rules without loading digestion/history or writing saves.

## Wild battles

Actions > Play > Wild battles offers queued encounters, practice, Later and
Decline next. Eggs must hatch first; a sleeping beast must explicitly Wake Up.
UP/DOWN chooses among four actual named techniques; SELECT uses one and BACK
pauses. Touching a move chooses/uses it. Each turn saves before its short visual
reaction, so closing/reopening resumes the same opponent, HP, seed and turn.
YOU/WILD labels remain above the HP bars, including identical creatures. Each
committed exchange shows your named move/result, then the wild move/result:
800ms action and 1200ms result per actor, independent of Motion setting. Damage
stays below its recipient; guard/buff feedback stays below the acting creature.
Repeated SELECT/touch input cannot skip feedback or submit extra turns; BACK
still pauses. Reopening an unclaimed turn visually replays its saved events with
a REPLAY marker, without applying damage or rewards again. No new save fields.
On the compact move grid, the selected technique has a short effect hint.

Battle pause uses the same UP/DOWN/SELECT menu: Resume (default), Restart Battle,
Exit and Abandon. Resume includes the frozen 3-2-1 countdown. Restart confirms use of
the next queued encounter (not a free retry); with no spare encounter the current
match remains paused. Practice restarts stay reward-free. Exit saves the current
match and returns directly to Pet; no second encounter is consumed on return.
Abandon explicitly confirms discard and returns to Pet. Abandoning an ongoing match grants
no consolation XP, mastery, win/loss or encounter refund, and spends no care
Energy. Already committed victories/defeats/draws settle their normal reward
once before removal; an unclaimed sleeping result must wait for Wake Up.
Same-view interruptions retain the current feedback position; a cold reopen
replays only committed events as before, without rerunning a combat turn.
Freshly created matches start normally, not at a Resume prompt. Resume is offered
only for valid unfinished matches. Terminal unclaimed results are shown/settled
instead; claimed results and abandoned records are cleared while retaining the
claim watermark, XP and mastery so no stale result can be replayed for rewards.
Recovering signatures show the remaining own moves without hiding other options.
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

Egg, Pip and Nimble are shared early forms; branching happens automatically at
Adult (at least seven days). Details shows a short tendency hint before then.
Steps affect growth/rewards, never family. Feeding, pats, rest and cleaning are
family-neutral. Each egg has a small stable innate temperament (two points).
Completed Beast Bounce favours Ember; Follow My Lead favours Wisp; Tiny
Adventures/scouting favours its chosen destination's family (Forest/Grove,
Meadow/Ember, Lakeside/Tide, Garden/Wisp). Kite/Shell/Crystal favour Ember/Tide/Wisp.
Completion earns two tendency points (one for a failed game), toys one; at most
six points per family/day, independently of growth/reward caps. No-step practice
and scouting can influence family without loot or additional rewards.
Ties select only among actual leaders using the durable birth/serial seed.
Existing adult branches remain locked; upgrades never reroll them. Old battle
personality values retain their meaning; new tendency scores are separate.

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
scheduled waking. Natural waking has no penalty. Saved base happiness and battle
personality are never reduced by waking. Reopening retains the bounded wake/grump
window; clock rollback before waking or a time-zone change invalidates the wake
override. Lighting and the astronomical sky remain independent: waking does not
cancel AUTO bedtime dimming, change the sky or generate sound/vibration alerts.

Settings > Outdoor world selects Forest, Meadow, Lakeside, Garden, Autumn
Woodland, Countryside, Bamboo Grove, Coastal Beach, Japanese Garden or Winter
Woodland. Family / neutral AUTO preserves the existing choice.
Optional **AUTO: change daily** cycles all ten by local calendar date, stable
across reopening on the same day. It changes only when the Pet view is shown
again on another date, not during active roaming or a game. Manual selection
disables daily rotation. Existing saved environment numbers retain their meaning;
daily rotation defaults off. No new timers, location reads or pet-save fields.
Sun / location uses retained watch/weather
cache or confirmed approximate coordinates; Positioning permission never starts
GPS. Native sunrise/sunset with offline calculation fallback is independent of
bedtime. No location is transmitted. FIXED 06-18 is the labelled last resort;
the moon arc is decorative, not a lunar ephemeris. No Pet-screen clock is added.

See the [v0.5.1 release notes](releases/v0.5.1/RELEASE_0_5_1.md) and
[v0.5.1 artwork/captures](../art/store/v0.5.1/README.md).
The retained v0.4 500px family-art cover is promotional artwork, not a screenshot.
These files are not evidence of a Garmin submission.
