# TekuTekuBeast

A native, offline Garmin virtual-beast game. Grow through time, care and play;
real watch activity adds growth and adventure rewards. No exercise, phone,
account or internet connection is required for normal gameplay.

**0.5.2 beta:** 47 validated SDK profiles, including standard Fenix 6S Pro.
Issue #19 extracted deterministic rules without changing gameplay or saves.
Existing signed IQ packages predate that cleanup; see the validation guide.

[GitHub Issues](https://github.com/joshld/garmin-tekutekubeast/issues) is the
authoritative development backlog and acceptance tracker. Guides describe current
behavior and procedures; validation/release records preserve test evidence, not
another roadmap. Later lighting, sleep-interaction and battle source changes do
not imply those features are present in the existing signed 0.5.2 IQ packages.

## Documentation

Read the relevant current guide, not every historical specification.

| Current guide | Authority |
| --- | --- |
| [Gameplay](docs/GAMEPLAY.md) | Features, controls, care, evolution, scenery and personal Developer Mode |
| [Architecture](docs/ARCHITECTURE.md) | Boundaries, save/rule contracts, portability and deliberate remaining seams |
| [Build, test and package](docs/BUILD.md) | Current public/private commands, focused testing and safe release workflow |
| [Compatibility](docs/COMPATIBILITY.md) | Supported models, older-watch limitations and per-profile evidence |
| [Watch acceptance](docs/WATCH_ACCEPTANCE.md) | Physical-watch checklist, confirmed reports and outstanding checks |
| [Validation](docs/VALIDATION.md) | Latest source checkpoint and version-specific evidence |
| [Fenix 6S Pro installation](docs/INSTALL_FENIX_6S_PRO.md) | Mum's device-specific USB/update instructions |

[AGENTS.md](AGENTS.md) governs scope, testing and save safety. Routine development
targets Enduro 4 only; documentation-only changes need links/consistency checks,
not simulator runs. [Art notes](art/README.md) and
[portable test vectors](tests/core-vectors/README.md) are specialist references.

## Installation and save safety

Public builds exclude Developer Mode and use a separate UUID. The existing
Developer Beta retains its UUID, pet and DEV tools. Saves do not transfer
automatically. Update the matching installation; never uninstall or clear Storage
to test. Keep signing keys private.

Only the appropriate signed `.iq` goes to Garmin; device-specific `.prg` files
are for USB sideloading, not opening on a phone. Publishing requires owner
approval. SDK passes do not establish physical-watch acceptance or battery life.

## Historical reference

- [Archived specifications/plans](docs/archive/) preserve design decisions,
  not current implementation instructions.
- [Versioned release records](docs/releases/) preserve notes, hashes and evidence.
  For v0.5.2 use the [public identity record](docs/releases/v0.5.2/PUBLIC_RELEASE_0_5_2.md)
  or [private Beta record](docs/releases/v0.5.2/DEVELOPER_BETA_0_5_2.md).
  The earlier same-UUID candidate is not a new-public-listing package.
- [Raw v0.5 SDK logs](docs/validation/v0.5/README.md) and
  [compatibility results](docs/compatibility/sdk-results.csv) remain in place.
