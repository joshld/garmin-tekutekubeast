# Issue #22 gameplay sprite regression

Enduro 4 only; use `scripts/build.ps1 -Owner -Device enduro4 -Jungle
tests/game-art/monkey.jungle -Output bin/matrix-gameart22-enduro4.prg`, then
`scripts/run-simulator.ps1 -Device enduro4 -Program bin/matrix-gameart22-enduro4.prg`.
The isolated QA identity and RAM pet never write either real pet's progress.

The audit renders 168 game scenes (14 forms: Bounce intro/hop/results, Follow
My Lead cues/neutral/results, Adventure travel/choices/results) and 42 battle
idle/exchange/victory scenes. It checks native text bounds, sprite circle bounds
and actual Adventure pose selection. Main-body/fragment correctness is checked
separately against source art by `scripts/verify_game_art.py`; rendering alone
cannot distinguish intentional detached artwork from atlas contamination.

Executed 2026-10-19, SDK 9.2: **210 scenes, zero failures**; sampled QA heap
145,480 / 781,976 bytes (not an allocator-wide peak or battery measurement).
**70 native tests passed** including Adventure direction, existing game sessions,
sleep, save/DEV isolation and battle rules. Public Enduro 4 compilation passes
with DEV excluded. Logs: `bin/gameart22-{build,layout-final,native,public-build}.log`.
`verify_v051_art.py` passes 480 historical Pet comparisons, allows only reviewed
game alpha erasures, and protects unchanged games/Glance. `verify_game_art.py`
passes 66 source poses with independent removal counts and retained body pixels.

Root cause: compact `V5Game*` art used by all three games and both battle fighters
was generated before the Pet-only repair. Fixed-grid source extraction captured
adjacent tails and neighbouring-row antler/foot tips. Reviewed masks erase only
those pixels before resizing into the **original** crop bounds and game scale.
Food crumbs, flame details and unrelated art remain intact. There are no extra
assets, runtime image transforms, buffers, caches, timers or storage changes.
Games still cache six poses; battles retain three compact poses per fighter.

Adventure travel moves right but previously used left-facing native walks.
`BeastArt.trailFrame` reuses the existing right-facing look pose when the stride
is left-facing, retaining native right-facing strides and the original hop timing.
No mirrored sheets or changes to movement, rewards or session transactions.

Nimble tail investigation: original 2172×724 shared atlas cells are 362px wide;
the native tail crosses the right crop in poses 0–4 (102/159/73/79/120 opaque edge
pixels). This predates the Pet fix. Current Pet canvases have transparent side
margins in every pose/mirror; the repaired pixels do not intersect the retained
body. Recovering original off-cell anatomy would change the historical crop/
size/position contract, so no anatomy reconstruction was attempted here.

The separate, unchanged 192-scene Pet-roaming fixture compiled but its fresh
runner timed out without a scene summary (`bin/gameart22-roaming.log`); this is
not a new pass. Reuse the prior `bin/roaming22-audit.log` evidence, supported by
fresh byte/pixel comparisons showing no Pet asset or Pet renderer changes.
The final game audit completed after inspecting/reopening the stalled simulator
with the computer-use skill; its earlier 210-scene run also passed. No simulator
storage was reset. `bin/gameart22-layout-final.log` is the final successful run.

Owner Enduro 4 acceptance remains open in #22, alongside #15: game/results and
battle fragments, Adventure facing, suspected tail shape, normal Pet transitions
and the previously fixed moon/horizon cutout. No new physical-watch validation,
device matrix, Store package, installation or publication is claimed.
