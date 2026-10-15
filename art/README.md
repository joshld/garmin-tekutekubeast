# TekuTekuBeast artwork

The supplied concept moodboard is the visual reference: expressive pixel-art beasts with distinct silhouettes, a restrained green watch interface, compact care icons, and readable information inside the circular screen. The family chart guides future silhouettes and colors, not changes to the current game rules.

## Implemented first pass

- Mystery Egg, Pip hatchling, and Nimble juvenile have original bitmap sprites.
- Each compiled sprite is 112x112, using a 56x56 logical canvas scaled 2x with nearest-neighbor sampling. Transparency is binary; colors use exact ARGB2222 device RGB values.
- The view loads only its current stage bitmap, outside the draw callback.
- A foreground-only 1 Hz timer adds a two-pixel idle bob. Step sync still runs once per 20 seconds; the timer stops when the view hides. This is not yet a set of separate blink/happy/sleep animation frames.
- Text fits the width of an eight-pixel-inset circle at its actual vertical position, using the device's native font metrics. Pet keeps one bottom text row; evolution details live on Your Beast. SELECT gives brief care-action feedback; UP/DOWN changes pages.
- The launcher is a 40x40 version of Pip.

## Still to do

Adult, Champion, and Legendary family sprites still use the earlier primitive rendering. Distinct Grove, Ember, Tide, and Wisp silhouettes, expressions, and sleep poses are the next art pass. Rare forms and collections remain roadmap features.

## Rebuilding the bitmaps

Install Pillow in your Python environment, then run `python scripts/prepare_art.py`. The committed PNGs are ready to compile and do not require Pillow during ordinary Monkey C builds. Source images and generation prompts are retained for iteration.

## Safe visual preview

Build `tests/art-preview/monkey.jungle` for `enduro4`. Its separate application ID and in-memory model cannot change the real game's progress. It first checks 55 scenes using real device font metrics: all three pages across 15 normal stage/family combinations and two large-counter cases, then four feedback messages. Text-box corners must be within the eight-pixel-inset circle, text rows must not overlap, and current labels must not be truncated. After the summary, SELECT enters preview and cycles the cases; UP/DOWN changes pages. This checks text geometry and is supplemented by visual simulator checks; physical-watch verification is still needed. Do not upload the preview executable to the store.

The production manifest, storage schema and step-credit model are unchanged by this artwork pass. Physical-watch display, battery and usability checks are still needed.
