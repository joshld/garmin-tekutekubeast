# Original v0.5.1 landscape layers

Generated with the built-in image-generation tool, not an external CLI/API key.
The user's two concept mockups are artistic references, not claimed screenshots.
Originals live in `art/source/v051/{forest,meadow,lakeside,garden}.png`.
`scripts/prepare_v051_world.py` performs deterministic nearest-neighbour native
size conversion, transparent-alpha thresholding and MIP-safe palette mapping.
No landscape generation or transformation runs on the watch.

## Shared production prompt

Use case: stylized-concept. Asset type: production retro pixel-art landscape
layer for TekuTekuBeast, native Garmin watch game, NOT a watch mockup or poster.
Create ONE square landscape layer. Composition: straight-on side-view 2D
virtual-pet environment, designed on a crisp 140x140 logical pixel grid for
nearest-neighbour 280x280 display. Top 35 percent and all sky must be genuinely
transparent; distant hills begin near y=42 percent; broad walkable ground from
y=57 percent to bottom. Trees may extend up along outer edges but leave
top-centre open. Reserve central x=20..80 percent y=48..78 percent as uncluttered
flat ground where a small creature will roam. Bottom central x=30..70 percent
y=80..100 percent must be quiet flat terrain for later HUD. Original charming
hand-placed-looking RPG pixel art, layered stepped silhouettes and readable leaf
clusters, restrained detail, soft muted sage/moss/cream/blue-grey daytime palette,
low contrast, no solid dark outlines, maximum about 12 solid shades. Full-bleed
square asset, no frame or circular crop. No creature, people, text, clock, icons,
sun, moon, stars, nonexistent character shadows or watermark. Real transparency,
never a painted checkerboard. Strict crisp pixels, no blur, smooth gradients or
photorealism.

## Theme-specific prompt inserts

- Forest: A woodland clearing: one beautifully shaped leafy tree along left edge,
  smaller tree at right edge, faint layered distant forest and hills, small bushes
  and a few ferns. Keep the broad central clearing empty.
- Meadow: An open meadow: faint distant hills, low bushes at outer edges, a few
  small wildflowers and tufts of dry grass, a couple subtle stones; broad empty
  central grassy clearing.
- Lakeside: A lakeside clearing: faint distant hills/vegetation behind a narrow
  lake across the middle distance, reeds only at outer sides, a gently curved
  shoreline, broad empty grassy foreground clearing.
- Garden: A small enchanted garden: shrubs, small leafy tree at left edge, a tiny
  weathered fence at outer right edge, a few flowers; broad empty central grassy
  clearing, very subtle mystical lavender accents.

The final build-time composition expands the walkable ground vertically, without
scaling any creature. Four stepped lighting palettes reuse each original scene.
