# Gameplay boundaries (Issue #19)

This is the current code map, not a new platform implementation. Existing
release validation records remain historical evidence.
See [gameplay](GAMEPLAY.md) for behavior, [build/test](BUILD.md) for commands
and [validation](VALIDATION.md) for the latest executed checks. Read archived
designs only when a specific historical decision is relevant.

| Boundary | Responsibility |
| --- | --- |
| `BeastProgression` | Growth, hatch/stage/mastery calculations and read-only family selection. Explicit save document and epoch-seconds inputs; no Garmin imports. |
| `BeastActivityRules` | Deterministic step ledger, baseline/watermark and activity reward mutations; explicit local day and optional cumulative counters. No clock, watch or storage access. |
| `GarminActivity` | Single normalization point for Garmin snapshots, history, optional active minutes and pushes. No new polling or storage. |
| `BeastGameRules` | Pure mini-game timing, cue selection, seed transitions and loot choice. Views keep session transitions/buttons/drawing; State keeps atomic claims and inventory changes. |
| `BeastBattleMoves` / `BeastBattleRules` | Issue #20 deterministic engine: 72 fixed named techniques, temporary combat snapshots, AI, effects and bounded progression calculations. No platform imports or pet-save mutation. |
| `TekuTekuBeastState` | Application orchestration: migrations, clock/day sampling, care, transaction ownership, Developer Mode and save commits. |
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

## Rule contracts

- Epochs are integer Unix seconds; calendar days remain local `YYYYMMDD` keys.
  Rule modules must receive these values, not read the clock themselves.
- The existing `v4` document is the canonical schema. No renamed keys, changed
  units or new migration is required for these extractions.
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

## Deliberately not rewritten

Battle protocol v1 uses plain dictionaries/arrays: `v`, `id`, `seed`, `turn`,
`status` (0 active, 1 victory, 2 defeat, 3 draw), two `actors`, latest `events`
and four player move-use counters. Form IDs 0/1 are Pip/Nimble; family groups
contain adult/champion/legendary/earned rare. Move ID = form * 4 + slot; never
reorder these IDs. Eggs have no moves. `turn` returns an independent snapshot;
invalid/cooling moves are no-ops. Seed recurrence is `(seed * 17 + 11) % 65521`:
AI peeks at the next seed, then each damaging action consumes one seed, player
first. Guard/buff actions consume none. Match results stop at 20 turns. These
contracts and the JSON roster/probes are reusable by future ports; no ANT, BLE,
ESP-NOW or multiplayer transport is implemented.

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

Mini-game periods, cue durations, gaps and jumps use 250 ms logical ticks (not
wall-clock milliseconds). Seeds use the existing modulo-65521 transitions and
are owned by durable sessions. A loot calculation cannot consume energy, claim
a reward or update inventory. Preserve integer division/truncation in future
language implementations; do not substitute their default floating division.

State is still the transaction/application boundary, not a portable engine.
View inheritance, menu/render coupling and exact-span public-source exclusion
remain follow-up hotspots. Avoid broad controller/framework rewrites until a
concrete consumer requires them. No PWA or ESP32 implementation exists here.
