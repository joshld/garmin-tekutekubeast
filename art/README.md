# TekuTekuBeast artwork

v0.4 uses the supplied colourful pixel-art family concept as its reference:
leafy Grove deer, Ember dragons, blue/pink-gilled Tide spirits and violet Wisp
fox spirits. The geometric higher-stage drawings have been removed.

## Assets

All 15 normal species have six poses: idle, walking, eating, curled sleep,
blink and looking back. Egg uses repeated egg frames. Rare forms currently
use the family's Legendary sprite with an earned golden-crown overlay; they
do not yet have entirely separate illustrated anatomy.

- `source/v04/*-expressive.png`: selected original generated atlases.
- `source/v04/*.png`: retained first-pass originals.
- [V0_4_PROMPTS.md](V0_4_PROMPTS.md): complete prompts and reference roles.
- `../resources/drawables/v04`: 96px native sprites and 40px glance sprites.
- `../resources-native144` / `../resources-native192`: pre-sized AMOLED assets.

Generated with the built-in image tool. `scripts/prepare_v04_art.py` only crops,
thresholds alpha, snaps colours to supported 0/85/170/255 RGB levels and resizes
with nearest-neighbour. Source artwork is not loaded by the watch. Native-size
variants avoid an SDK restriction on affine-transforming palette bitmaps.

Only the current creature's six frames are cached. Foreground animation adds
wandering, hops, family-specific motion, blink/look, chewing, cleaning puffs,
sleep and evolution feedback. No animation timer survives view hiding or app
inactivity. Motion OFF/LOW/NORMAL is available in Settings.

## Store artwork and copy

[store/v0.4/README.md](store/v0.4/README.md) indexes the new four-family cover,
retained generated original and prompt, current simulator captures, and
copy-ready description/release notes. The cover is promotional pixel art based
on the game's sprite atlases, not a gameplay screenshot. These assets are not
loaded by the watch and do not change the signed v0.4.0 binary.

## Verification

The internal `tests/art-preview` / `tests/matrix` harness renders one scene per
callback and checks native-font bounds, overlap and truncation across species,
poses, menus, game phases, large counters and feedback. It uses an isolated QA
application ID and an in-memory model; it is not the on-watch Developer Mode.
Developer Mode is inside the production app and uses its normal screens.

See [validation](../docs/V0_4_VALIDATION.md) and the device matrix for actual
results. Simulator screenshots and generated assets are not physical-watch
photographs. Battery, display appearance and sound still need hardware checks.
