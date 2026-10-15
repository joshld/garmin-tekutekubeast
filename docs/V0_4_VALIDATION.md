# v0.4 implementation log

Latest user requirements override older roadmap text. Work is being implemented
in the existing app ID; no separate Developer Lab application is shipped.

## First increment: save isolation, growth, navigation and care

- Canonical version-4 save is one atomic Storage document, including step
  watermarks and corresponding rewards. Original keys remain untouched and a
  migration snapshot is retained. No previous age is retroactively credited.
- Existing stage is a permanent floor. Genuine lifetime watch XP is distinct
  from passive/care growth. Replayed observations cannot award the same steps.
- Settings enables a temporary in-memory DEV branch of the same game. It uses
  a virtual clock and normal gameplay code. Discard/restart never commits it.
  Discard reloads the latest real save and reconciles ActivityMonitor history.
- DEV controls: rates, jumps, stage/family, needs, food/energy/charms, poop,
  cleaning, sleep, evolution, animations, scenario reset and balancing values.
- Zero-step meals, bounded care decay, delayed poop, clean, rest, personality
  routes, accessible adventure currency, collectible cycle and rare exceptions.
- Initial balance: 12,000 passive growth/day; 300 care growth/day; 24h egg with
  8h acceleration floor; Legendary 300,000 growth and 21-day minimum.

### Verified

SDK 9.2.0 Enduro 4 compilation succeeded. Eight Monkey C tests executed and
passed in the Enduro 4 simulator: migration/restart, DEV isolation and step
catch-up, 7/25/100-day passive growth and clock rollback, hatch floor, zero-step
care/poop/cleaning, reward caps, step/multi-metric deduplication, all zero-step
family and rare paths, and Settings/DEV navigation. Simulator normal game
preserved the existing Pip and rendered the simplified Pet/Actions screens.

### Still required

Full visual/layout audit, mini-games, final expressive art, Glance and device
matrix are subsequent increments. No physical-watch, battery or audible-tone
testing has been performed. Do not interpret source implementation as hardware
validation or upload a work-in-progress package as a public release.
