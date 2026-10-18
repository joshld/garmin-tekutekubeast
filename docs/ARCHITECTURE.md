# Gameplay boundaries (Issue #19)

This is the current code map, not a new platform implementation. Existing
release validation records remain historical evidence.

| Boundary | Responsibility |
| --- | --- |
| `BeastProgression` | Growth, hatch/stage/mastery calculations and read-only family selection. Explicit save document and epoch-seconds inputs; no Garmin imports. |
| `TekuTekuBeastState` | Application orchestration: migrations, clock/day sampling, care, transaction ownership, Developer Mode and save commits. |
| `BeastStore` | Garmin persistence, dirty detection and compact Glance cache; injectable RAM backend for tests. |
| Views/delegates | Drawing, artwork, input, timers and feedback. Glance uses its existing compact read-only cache. |
| `BeastSleep` / `BeastSky` | Existing sleep/calendar and astronomy helpers. Sleep still depends on Garmin calendar/time APIs. |

## Rule contracts

- Epochs are integer Unix seconds; calendar days remain local `YYYYMMDD` keys.
  Rule modules must receive these values, not read the clock themselves.
- The existing `v4` document is the canonical schema. No renamed keys, changed
  units or new migration is required for these extractions.
- `BeastProgression.advance` mutates only passive-growth fields; calculations
  and family selection do not write storage. State owns all commits and DEV guards.
- Genuine step XP is distinct from growth and must never be synthesized by ports.
- `tests/core-vectors/*.json` contains reviewed language-neutral golden inputs
  and outputs. `scripts/prepare_rule_vectors.py` generates only test literals,
  not a second gameplay implementation. Future ports can consume the same JSON.
- Run `python scripts/prepare_rule_vectors.py --check` to detect fixture drift.
  Native `-Tests` builds refresh the test-only literals automatically. Public
  compilation inputs exclude both native owner tests and generated vectors.

## Deliberately not rewritten

State is still the transaction/application boundary, not a portable engine.
View inheritance, menu/render coupling and exact-span public-source exclusion
remain follow-up hotspots. Avoid broad controller/framework rewrites until a
concrete consumer requires them. No PWA or ESP32 implementation exists here.
