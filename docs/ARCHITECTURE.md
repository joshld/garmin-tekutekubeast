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
| `TekuTekuBeastState` | Application orchestration: migrations, clock/day sampling, care, transaction ownership, Developer Mode and save commits. |
| `BeastStore` | Garmin persistence, dirty detection and compact Glance cache; injectable RAM backend for tests. |
| Views/delegates | Drawing, artwork, input, timers and feedback. Glance uses its existing compact read-only cache. |
| `BeastSleep` / `BeastSky` | Existing sleep/calendar and astronomy helpers. Sleep still depends on Garmin calendar/time APIs. |

Lighting mode/expiry is read-only in `BeastSleep`, using the existing `lights`,
`lightsUntil` and `autoLights` keys; State owns explicit setting commits. The
view displays mode versus applied state; Scenery draws only a local light pool.
Sprite tint options are cached per view and capability-guarded. Neither lighting
rules nor rendering mutate `BeastWorld` astronomy caches or sleep settings.
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

Mini-game periods, cue durations, gaps and jumps use 250 ms logical ticks (not
wall-clock milliseconds). Seeds use the existing modulo-65521 transitions and
are owned by durable sessions. A loot calculation cannot consume energy, claim
a reward or update inventory. Preserve integer division/truncation in future
language implementations; do not substitute their default floating division.

State is still the transaction/application boundary, not a portable engine.
View inheritance, menu/render coupling and exact-span public-source exclusion
remain follow-up hotspots. Avoid broad controller/framework rewrites until a
concrete consumer requires them. No PWA or ESP32 implementation exists here.
