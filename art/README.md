# TekuTekuBeast artwork

v0.4 uses the supplied colourful pixel-art family concept as its reference:
leafy Grove deer, Ember dragons, blue/pink-gilled Tide spirits and violet Wisp
fox spirits. The geometric higher-stage drawings have been removed.

v0.5.1 restores the exact v0.4 character pixels and padding instead of the
v0.5 enlarged canvases. `scripts/prepare_v05_art.py` retains original Pet
canvases (96px MIP; 144/192px AMOLED), adds pre-mirrored walking poses and
retains 40px curled Glance sprites. Six-pose V5Game resources use
80px MIP / 128px or 144px AMOLED canvases, keeping game jumps inside the circle.
Old V4 small resources remain for ordinary Glance poses. No affine bitmap
transformations run on the watch.
Only the current Pet's eight poses (six plus two mirrored) are loaded; the egg
shares a single bitmap. `scripts/verify_v051_art.py` checks 480 Pet variants
against historical v0.4 pixels and verifies unchanged game/Glance assets.
Issue #22 removes detached neighbouring-atlas fragments from Nimble Pet poses
only, without cropping, scaling or moving its body. The verifier checks exact
removed-pixel counts; other Pet pixels and all game/Glance images stay unchanged.
Walking uses per-pose facing metadata and the existing two mirrors, including
mixed-facing atlases; moving hops no longer swap to an unmirrored pose.
See [current source validation](../docs/VALIDATION.md) and the
[original scenery evidence](../docs/releases/v0.5.1/V0_5_1_VALIDATION.md).

Four original transparent pixel-art landscape layers are in `source/v051`.
[V0_5_1_PROMPTS.md](V0_5_1_PROMPTS.md) records generation and reference roles.
`scripts/prepare_v051_world.py` compiles restrained dawn/day/dusk/night variants
at six native display sizes from a 140px logical grid. Only one foreground
landscape is cached. Sky/celestial placement is rendered separately; scenery
does not run in Glance or background tasks. The illustrations are assets, not
evidence of simulator or hardware operation.

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
Compact game/battle sprites erase individually reviewed neighbouring-atlas
fragments at build time (`pet_art_repair.py`); body pixels, original crop/scale,
Pet sprites and Glance art stay unchanged. `verify_game_art.py` checks the repair
counts and protects every connected main-body pixel. Original atlas cells already
truncate Nimble tails in some poses; no runtime clipping or new tail redraw was
introduced. Tiny Adventures reuses existing right-facing poses without mirrors.
Foreground animation adds
wandering, hops, family-specific motion, blink/look, chewing, cleaning puffs,
sleep and evolution feedback. No animation timer survives view hiding or app
inactivity. Motion OFF/LOW/NORMAL is available in Settings.

## Store artwork and copy

[store/v0.4/README.md](store/v0.4/README.md) retains the four-family cover,
generated original/prompt and historical v0.4 captures and copy.
[store/v0.5/README.md](store/v0.5/README.md) retains historical v0.5 copy and
genuine implementation/release checkpoint captures.
[store/v0.5.1/README.md](store/v0.5.1/README.md) indexes current copy and captures.
The cover is promotional pixel art based
on the game's sprite atlases, not a gameplay screenshot. These assets are not
loaded by the watch and do not change the signed v0.4.0 binary.

## Verification

The internal `tests/art-preview` / `tests/matrix` harness renders two scenes per
callback and checks native-font bounds, overlap and truncation across species,
poses, menus, game phases, large counters and feedback. It uses an isolated QA
application ID and an in-memory model; it is not the on-watch Developer Mode.
Developer Mode is inside personal/owner builds and uses their normal screens;
public builds compile it out. See [build separation](../docs/BUILD.md).

See [current validation](../docs/VALIDATION.md) and
[compatibility evidence](../docs/COMPATIBILITY.md) for actual
results. Simulator screenshots and generated assets are not physical-watch
photographs. Battery, display appearance and sound still need hardware checks.
