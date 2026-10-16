# TekuTekuBeast artwork

v0.4 uses the supplied colourful pixel-art family concept as its reference:
leafy Grove deer, Ember dragons, blue/pink-gilled Tide spirits and violet Wisp
fox spirits. The geometric higher-stage drawings have been removed.

v0.5 retains those character pixels rather than replacing them with unrelated
cover art. `scripts/prepare_v05_art.py` trims existing sprite alpha padding,
exports larger Pet canvases (128/144px MIP; 200/232px AMOLED), adds pre-mirrored
walking poses and 40px curled Glance sprites. Six-pose V5Game resources use
80px MIP / 128px or 144px AMOLED canvases, keeping game jumps inside the circle.
Old V4 small resources remain for ordinary Glance poses. No affine bitmap
transformations run on the watch.
Only the current Pet's eight poses (six plus two mirrored) are loaded; the egg
shares a single bitmap. See [v0.5 evidence](../docs/V0_5_VALIDATION.md).

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

Only the current creature's frames are cached (eight Pet / six game poses).
Foreground animation adds
wandering, hops, family-specific motion, blink/look, chewing, cleaning puffs,
sleep and evolution feedback. No animation timer survives view hiding or app
inactivity. Motion OFF/LOW/NORMAL is available in Settings.

## Store artwork and copy

[store/v0.4/README.md](store/v0.4/README.md) retains the four-family cover,
generated original/prompt and historical v0.4 captures and copy.
[store/v0.5/README.md](store/v0.5/README.md) indexes current candidate copy and
genuine implementation/release checkpoint captures. The cover is promotional pixel art based
on the game's sprite atlases, not a gameplay screenshot. These assets are not
loaded by the watch and do not change the signed v0.4.0 binary.

## Verification

The internal `tests/art-preview` / `tests/matrix` harness renders one scene per
callback and checks native-font bounds, overlap and truncation across species,
poses, menus, game phases, large counters and feedback. It uses an isolated QA
application ID and an in-memory model; it is not the on-watch Developer Mode.
Developer Mode is inside the production app and uses its normal screens.

See [v0.5 validation](../docs/V0_5_VALIDATION.md) and the device matrix for actual
results. Simulator screenshots and generated assets are not physical-watch
photographs. Battery, display appearance and sound still need hardware checks.
