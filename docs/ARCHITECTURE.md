# Gameplay boundaries (Issue #19)

This is the current code map, not a new platform implementation. Existing
release validation records remain historical evidence.
See [gameplay](GAMEPLAY.md) for behavior, [build/test](BUILD.md) for commands
and [validation](VALIDATION.md) for the latest executed checks. Read archived
designs only when a specific historical decision is relevant.

| Boundary | Responsibility |
| --- | --- |
| `BeastProgression` | Growth, hatch/stage/mastery calculations and read-only family selection. Explicit save document and epoch-seconds inputs; no Garmin imports. |
| `BeastCareRules` | Portable difficulty rates, fractional elapsed needs, capped activity modifiers and compact delayed digestion. Explicit epoch/day inputs; no Garmin APIs, storage or timers. Read-only projections serve Glance. |
| `BeastAffinity` | Portable family tendencies, stable innate temperament, actual-leader tie resolution and per-family daily caps. No activity, care-growth or platform dependencies. State preserves adult locks and old battle personality. |
| `BeastActivityRules` | Deterministic step ledger, baseline/watermark and activity reward mutations; explicit local day and optional cumulative counters. No clock, watch or storage access. |
| `GarminActivity` | Single normalization point for Garmin snapshots, history, optional active minutes and pushes. No new polling or storage. |
| `BeastGameRules` | Pure mini-game timing, cue selection, seed transitions and loot choice. Views keep session transitions/buttons/drawing; State keeps atomic claims and inventory changes. |
| `BeastBattleData` / `BeastBattleMoves` / `BeastBattleRules` | Issue #20 deterministic engine: generated shared definitions, 72 fixed named techniques, temporary combat snapshots, AI, effects and bounded progression calculations. No platform imports or pet-save mutation. |
| `BeastStateCore` | Background-safe orchestration: migration, clocks, genuine activity, lazy care/growth, sleep and atomic commits. No game sessions, care actions or DEV controls. |
| `TekuTekuBeastState` | Foreground subclass retaining the existing API: care actions, session claims, collections and isolated Developer Mode. |
| `BeastStore` | Garmin persistence, dirty detection and compact Glance cache; injectable RAM backend for tests. |
| Views/delegates | Drawing, artwork, input, timers and feedback. Glance uses its existing compact read-only cache. |
| `BeastSleep` / `BeastSky` | Existing sleep/calendar and astronomy helpers. Sleep still depends on Garmin calendar/time APIs. |

Lighting mode/expiry is read-only in `BeastSleep`, using the existing `lights`,
`lightsUntil` and `autoLights` keys; State owns explicit setting commits. The
view displays mode versus applied state; Scenery draws only a local light pool.
Sprite tint options are cached per view and capability-guarded. Neither lighting
rules nor rendering mutate `BeastWorld` astronomy caches or sleep settings.

Issue #17 keeps sleep decisions in `BeastSleep` and deliberate wake transactions
in State. Optional `awakeAt`/`awakeUntil`/`awakeZone` fields suppress only the
current sleep window; `grumpAt`/`grumpLevel` apply a read-only, reversible happiness
overlay. Existing nap history remains available for lazy energy sampling. State
guards care/reward entry points; views provide the quiet notice and checkpoint
games before pausing. These additive defaults preserve the canonical `v4` save,
DEV isolation and compact read-only Glance cache. Expiry needs no timer or write.
Garmin's [bitmap tint API](https://developer.garmin.com/connect-iq/api-docs/Toybox/Graphics/Dc.html#drawBitmap2-instance_function)
is guarded by `has`; unsupported renderers keep the native sprite. No alpha
framebuffer or GPU-only blending is required.

Care extends canonical `v4` additively: `careDifficulty` (0/1/2),
`careAt`, `foodRemainder`/`joyRemainder` (need-seconds modulo 86,400),
`careStepDay`/`careStepUnits` (2k-step high-water, maximum five),
`digestion` (four due-epoch/unit pairs), `digestRemainder` (0-2),
`digestDay`/`digestWaste` (daily food-waste cap). Existing `poop`, `poopDue`,
`lastPoop`, `poopSlots` and `lastCleanReward` retain their units and upgrade
values. The care marker initializes new food batches; `poopDue`/`lastPoop`
then own the natural-waste clock, retaining the legacy pending-meal deadline
for its first event. Food deadlines live in `digestion`, independently.
State owns defaults, genuine ledger observation and atomic commits; rules use
bounded arithmetic (four batches/five slots), never loops through absent days.
Whole-hour care settlement avoids extra sub-hour Glance writes; mode changes
settle remaining fractions. Glance adds only difficulty, care epoch/remainders
and cleanliness, never digestion/affinity/inventory/history. Constrained legacy
profiles exclude care/affinity orchestration from background scope and retain
foreground catch-up. No extra timer, service, sensor, bitmap cache or save
namespace. Old battle personality and new family affinity remain separate;
difficulty never enters family selection, evolution or step XP.

The measured care stress case required splitting foreground actions from the
background core; no persistent key, field unit or gameplay API changed. Mini-game
rules are foreground-only. `BeastStore.savePet` releases the obsolete dirty
baseline before a write and builds its independent replacement after Garmin
serialization. Real Storage values need no extra working-document clone; the
RAM backend retains deep isolation. Failed writes retain the previous disk
save; failed post-write snapshots leave a null baseline for an idempotent retry.
Identity comparisons skip traversing already-shared immutable values. Energy
sampling stops once saturated at 100, preserving the same recovery result.

`BeastWorld` keeps optional `dailyRotation` in its existing foreground `world.v1`
preferences. Calendar-derived cycling needs no saved random choice or daily write;
`beginVisit` invalidates only the selected theme, never astronomy. Existing IDs
0–4 are retained, Autumn/Countryside append as 5/6 and Bamboo/Coast/Japanese/Winter
as 7–10. Manual/family AUTO selection turns daily cycling off. Scenery still
caches exactly one terrain layer; daily selection uses the current theme count.

## Rule contracts

- Epochs are integer Unix seconds; calendar days remain local `YYYYMMDD` keys.
  Rule modules must receive these values, not read the clock themselves.
- The existing `v4` document is the canonical schema. No renamed keys or changed
  units; later care/affinity defaults are additive, as described above.
- `BeastProgression.advance` mutates only passive-growth fields; calculations
  and family selection do not write storage. State owns all commits and DEV guards.
- Genuine step XP is distinct from growth and must never be synthesized by ports.
- Activity input is cumulative steps plus nullable moderate+vigorous minutes
  and nullable pushes. `null` means unavailable, not zero. Observe before granting
  rewards. State owns day rollover, DEV/skip-watch guards and atomic commit;
  rules never sample calendars or persist intermediate watermarks separately.
- `tests/core-vectors/*.json` contains reviewed language-neutral golden inputs
  and outputs. `scripts/prepare_rule_vectors.py` generates only test literals,
  not a second gameplay implementation. Future ports can consume the same JSON.
- Run `python scripts/prepare_rule_vectors.py --check` to detect fixture drift.
  Native `-Tests` builds refresh the test-only literals automatically. Public
  compilation inputs exclude both native owner tests and generated vectors.

## Portable battle protocol v1

The canonical [battle definitions](../data/battle-v1.json) contain stable forms,
move IDs/names, stats and effects. `scripts/prepare_battle_data.py` generates
`BeastBattleData` literals consumed by the native rules: no runtime JSON loading,
additional watch resources or duplicate hand-maintained roster. Future ports
consume these same definitions; never reorder IDs or silently change v1 rules.

Battle state uses plain dictionaries/arrays: `v`, `id`, `seed`, `turn`,
`status` (0 active, 1 victory, 2 defeat, 3 draw), two `actors`, latest `events`
and four player move-use counters. Form IDs 0/1 are Pip/Nimble; family groups
contain adult/champion/legendary/earned rare. Move ID = form * 4 + slot; never
reorder these IDs. Eggs have no moves. The [state schema](../data/battle-state-v1.schema.json)
defines the serialized shape. `exportState`/`importState` exchange independent,
JSON-compatible objects, not encoded bytes; actual JSON encoding belongs at the
platform boundary. Imports reject unknown versions and malformed snapshots with
`null`, never reinterpret or reset them. Preserve the original saved record on
rejection. JSON object-key order and whitespace have no gameplay meaning.

Expected JavaScript and C/C++ implementations are small direct translations of
`BeastBattleRules`, not watch adapters or new compatibility frameworks:

- Use integer values with truncation toward zero after each division. JavaScript
  uses `Math.trunc`, not implicit floating division or bitwise coercion; C/C++ uses
  checked signed integer types, not unsigned underflow or implementation-defined
  casts. Valid bounded combat arithmetic fits signed 32-bit; persisted match IDs
  must retain their schema range exactly and must not be narrowed through bitwise
  operations. Reject nonfinite, fractional and out-of-range imported numbers.
- Seeds are 0–65520. The recurrence is `((seed % 65521) * 17 + 11) % 65521`;
  no platform random source, clock, signed-wrap PRNG or alternative rounding.
  AI peeks at the next seed without consuming it. Each damaging action consumes
  one seed, player first, then the surviving opponent. Guard/buff consume none.
- AI chooses from the pre-turn state. An accepted own action first decrements
  its cooldown; a signature sets it to two, requiring two intervening own actions.
  Guard remains until the next damaging hit; buff counts future damaging actions,
  not elapsed turns. Preserve effect order and integer truncation before minimum
  damage. Personality ties use the first index. KO takes precedence over the
  20-turn draw limit. Invalid/cooling moves leave an independent unchanged copy.
- Do not derive gameplay from UI animation timing, JSON property ordering,
  floating-point approximations or platform-specific random functions. Match
  replay needs only the validated starting snapshot and ordered move slots.
- `rewardEligible` takes explicit outcome, completed-turn count, practice flag
  and already-rewarded daily count; no calendar or save reads. Its cap and the
  mastery cap come from shared definitions. Each platform must still commit the
  claim and ledger update atomically, exactly once; pure reward queries do not
  authorize a second claim or a reset of the daily counter.

The shared [roster/probes](../tests/core-vectors/battle.json) and
[full replay vectors](../tests/core-vectors/battle_replay.json) are the portability
acceptance contract. Execute each input/command sequence against native rules
and future ports; compare AI choices, every complete output snapshot (including
seed, events, HP, guard, buff, cooldown and uses), XP and mastery increments.
Replay across export/JSON encode/decode/import boundaries and reject invalid or
unknown versions. Fixtures cover RNG, moves, damage, effects and rewards; changing
expected values requires an intentional rule/version review, not merely updating
tests to match a new port. No phone app or ESP32 firmware is implemented. The
foreground ANT adapter below is separate from this portable rules contract.

`BeastBattle` is the foreground transaction owner. Its separate atomic
`battle.v1` document contains queue, watermarks, active snapshot, reward claim,
Battle XP, 72 mastery values and wild-journal mask. These are never added to the
canonical `v4` document or read in background/Glance. Discovery observes already
reconciled genuine XP and adventure/care counters; it never grants steps or
evolution growth. Match IDs are allocated at match start so older queued offers
cannot be blocked by newer practice claims. Turns and final rewards commit in
the same battle document; transient snapshot metadata stays outside pure rules.
State's `battleData` is only a foreground cache, not a saved pet field. DEV uses
an independent copy and never writes the real battle document. The battle view
owns compact cached poses, button/touch input and short animation bursts only.

## Direct friend protocol v1

`BeastFriendWire` and `BeastFriendLink` are pure rules/session modules; injected
monotonic milliseconds drive deadlines. `BeastFriendModel` reads a detached beast
snapshot, never constructs the solo transaction owner, and allocates only a
separate `friend.serial.v1` counter. `BeastFriendAnt` owns one foreground public
ANT master/slave channel. `BeastFriendView` reuses battle HP, move, pose and event
rendering, rotating the joiner's display so YOU always identifies its own beast.
Neither radio nor session classes enter background/Glance scope.

Every packet is eight unsigned bytes: `[0xB1, op, sidLow, sidMid, sidHigh, seq,
a, b]`. The 24-bit host session counter never wraps; join supplies a fresh 16-bit
challenge. Ordered reliable sequence numbers 1–240 do not wrap. Ops: ACK=0,
beacon=1, hello=2, welcome=3, snapshot chunks=4–9, ready=10, start=11, move=12,
result chunks=13–18, confirm=19, go=20, final=21, cancel=22, heartbeat=23.
Beacon/heartbeat use sequence zero. ACK echoes sequence and original op. A
stop-and-wait sender retries at 750ms, at most 12 attempts; ACKs have priority.
Duplicate previous frames are re-ACKed, not reapplied. Out-of-order/foreign
sessions are ignored. Cancellation explicitly ends the matching session even
when an earlier packet was lost. Phase/no-input timeout is 90s, initial discovery 45s, receive
silence 12s, overall cap 10min. These are safety bounds, not gameplay timers.

A snapshot is 12 bytes: form, friendship, temperament, training level, then four
little-endian 16-bit mastery values. Stats are reconstructed and range checked;
remote HP/stats are never trusted. Six result chunks encode turn, both slots,
HP, seed, outcome, guard/buff/cooldowns and digest. The joiner recomputes
`pairedTurn` and validates the complete result before committing. CONFIRM/GO
synchronize presentation; FINAL/ACK confirms terminal outcomes. No result is
claimed after unconfirmed loss. An eight-second result grace drains retries;
OS termination can still break a link and never awards anything.

The engine tag is the first two SHA-256 bytes of sorted compact ASCII JSON
`data/battle-v1.json` (currently 0x60C5), checked during discovery. An intentional
rules/ordering change must also revise protocol compatibility, not just the data
hash. Existing portable battle goldens still apply; `pairedTurn(state, hostSlot,
joinSlot)` replaces AI selection only. Preserve host-first ordering, RNG and
integer truncation in future JavaScript/C++ ports. Wire golden examples are in
`tests/friend/source/FriendWireTests.mc`; mock two-peer fault and lifecycle tests
live beside them. No transport abstraction framework or multiplayer rewards.

ANT uses public network (no ANT+ private key), device type 117, transmission 1,
RF 66, period 8192 (4Hz), low-priority search 30s and high-priority search disabled.
The four-digit channel code is convenient pairing, **not encryption or identity
authentication**. Only anonymous battle stats are exchanged. Both applications
request `Ant`; UUIDs/signing do not identify radio peers. The adapter is explicitly
released on hide/stop/cancel/timeout. One 250ms foreground timer pumps protocol;
redraws occur only for visible changes or bounded existing event presentations.

[Garmin GenericChannel](https://developer.garmin.com/connect-iq/api-docs/Toybox/Ant/GenericChannel.html)
supports the required direct link. The installed SDK exposes it on all 47 current
profiles; that capability audit is not physical connectivity testing. Garmin's
[BLE API](https://developer.garmin.com/connect-iq/api-docs/Toybox/BluetoothLowEnergy.html)
is central/GATTC, without the peer peripheral server role. Communications/Wi-Fi
has no documented direct peer socket/server alternative. Simulator ANT needs a
USB radio for actual RF; two-peer mock execution requires none. The watches need
no external hardware. Physical pairing must be tested before release acceptance.
## Deliberately not rewritten

Mini-game periods, cue durations, gaps and jumps use 250 ms logical ticks (not
wall-clock milliseconds). Seeds use the existing modulo-65521 transitions and
are owned by durable sessions. A loot calculation cannot consume energy, claim
a reward or update inventory. Preserve integer division/truncation in future
language implementations; do not substitute their default floating division.

State is still the transaction/application boundary, not a portable engine.
View inheritance, menu/render coupling and exact-span public-source exclusion
remain follow-up hotspots. Avoid broad controller/framework rewrites until a
concrete consumer requires them. No PWA or ESP32 implementation exists here.
