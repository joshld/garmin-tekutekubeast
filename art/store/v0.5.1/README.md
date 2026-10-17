# v0.5.1 candidate artwork and copy

`whats-new.txt` and `description.txt` are plain copy for the existing Garmin beta listing. Publication
requires the owner's approval; preparing these files does not submit an update.

Original landscape source artwork and generation provenance are recorded in
[V0_5_1_PROMPTS.md](../../V0_5_1_PROMPTS.md). These are production bitmap assets,
not simulator screenshots or physical-watch photographs.

The world-preview harness uses the production scenery/Pet renderer with an
in-memory QA beast and isolated application ID. Its sky preview changes only
virtual rendering; neither the Garmin clock nor actual location is modified.
Historical v0.4/v0.5 comparison scenes re-render the exact historical Pip assets
on the same plain background/floor. They demonstrate pixel scale, not the entire
historical release UI. The inspected Enduro 4 captures are in `captures/`.
`size-comparison.png` uses identical 280px display crops without rescaling;
`worlds-contact-sheet.png` shows all four themes at dawn/day/dusk/night.
These are actual SDK captures of the production renderer, not watch photographs.
Their QA sky overrides and in-memory pet do not modify real location or time.

No clock is added to Pet. Generated mockups are not used as test evidence.
Historical v0.4/v0.5 screenshots and verification records remain unchanged.
