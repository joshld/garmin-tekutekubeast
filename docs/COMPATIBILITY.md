# Garmin compatibility and supported models

Current advertised set: **47 SDK profiles / 72 hardware parts**, unchanged by
Issue #19. Exact IDs are in the production manifest; per-candidate results and
exclusions are in [sdk-results.csv](compatibility/sdk-results.csv). That CSV
records the compatibility expansion, not a new run against every later commit.
See [latest source validation](VALIDATION.md) and [hardware acceptance](WATCH_ACCEPTANCE.md).

## Supported SDK products

The [manifest](../manifest.xml) is the exact advertised inventory. The CSV covers
the 34 accepted additions and rejected/held candidates, not all 13 pre-existing
profiles; earlier coverage remains in the versioned release evidence.

| Group | SDK IDs (not every retail alias) |
| --- | --- |
| Enduro (2) | `enduro3`, `enduro4` |
| Fenix (16) | `fenix6spro`, `fenix6pro`, `fenix6xpro`, `fenix7s`, `fenix7`, `fenix7x`, `fenix7spro`, `fenix7pro`, `fenix7xpro`, `fenix7pronowifi`, `fenix7xpronowifi`, `fenix8solar47mm`, `fenix8solar51mm`, `fenix843mm`, `fenix847mm`, `fenix8pro47mm` |
| Epix (4) | `epix2`, `epix2pro42mm`, `epix2pro47mm`, `epix2pro51mm` |
| Forerunner (16) | `fr165`, `fr165m`, `fr255`, `fr255m`, `fr255s`, `fr255sm`, `fr265`, `fr265s`, `fr57042mm`, `fr57047mm`, `fr745`, `fr945`, `fr945lte`, `fr955`, `fr965`, `fr970` |
| Venu (5) | `venu`, `venu3`, `venu3s`, `venu441mm`, `venu445mm` |
| vivoactive (4) | `vivoactive4`, `vivoactive4s`, `vivoactive5`, `vivoactive6` |

No Fenix 9 SDK product is advertised. Similar retail names do not establish
support; only individually validated manifest entries are supported.

The implementation/evidence below records the 17 October 2026 expansion.
v0.5.1 evidence is retained; subsequent focused Enduro 4 rule-refactor results
do not replace its per-profile counts. No Store publication is authorised here.

The later owner-approved public/Developer Beta UUID split is recorded in
[PUBLIC_RELEASE_0_5_2.md](releases/v0.5.2/PUBLIC_RELEASE_0_5_2.md). The validated 47-profile set,
gameplay, resources and compatibility evidence below remain unchanged.

## Scope and architecture

### 0.6.0 scenery packaging

All eight native scenery sizes (218–454px) include ten environments/four
palettes. On CIQ 3.x, the four newest environments use a resource-only
`SceneryPack` barrel namespace: 230 core + 24 scenery names in the application,
16 scenery names in the barrel, within the 254-name per-module limit. Generated
legacy source changes only resource references. All PNG pixels, Glance, saves,
step catch-up and public/private identities are retained; no runtime image
transforms or new timers. Always prepare through the build wrapper.

Focused Fenix 6S Pro scenery validation passed 332 simulator scenes. A separate
271-scene battle layout audit found text/sprite overlap and edge-clearance
failures on that smaller display; battle UI acceptance remains outstanding.
This limitation is not a failed scenery build or a full compatibility rerun.


Primary target: standard Fenix 6S Pro (`fenix6spro`). Garmin uses that same SDK
profile for 6S Sapphire / Pro Solar / Dual Power; it is not a Solar-only build.
Additional candidates are grouped in `scripts/compatibility_candidates.json` by
display geometry, MIP/AMOLED resource set and constrained-runtime policy.
Candidate QA entries/resource rules are NOT production support advertisements.
Products enter the production manifest only after their own SDK checks pass.

CIQ 3.x has a 254-members-per-module limit. A pruned resource catalog retains
every live sprite/scenery ID and references the original PNG files; no art is
redrawn, downsampled or removed from gameplay. Already unreachable extra egg
pose IDs are aliases of the same egg frame. Standard device catalogs stay intact.

The Fenix 6 background loader cannot load the full game engine within its 32KB
allocation. A runtime guard was tried and rejected: OOM occurred before entry.
Deferred profiles instead compile the same foreground State/Store bodies with
only their background scope markers removed. A minimal cleanup delegate handles
old registrations without opening a save. `scripts/build.ps1` generates this
scope-only variant under ignored `bin/legacy-source`; there is no second game
implementation or different application ID. Use that build wrapper for these
profiles/exports; direct IDE builds must run the preparation scripts first.

Foreground entry removes the app's step/sleep/wake registrations on deferred
profiles. Old callbacks that arrive before the next foreground launch clean up
and exit safely. Normal Enduro 4 background reconciliation remains enabled.

Steps, elapsed growth, care, naps, scheduled sleep and evolution reconcile on
foreground open using the existing rules. The original genuine step ledger,
deduplication, one-time EVOLVED announcement, DEV isolation, inventory, games,
collections, app ID and signing identity are retained. No watch activity or
clock is changed. Open daily: Garmin history is finite, so steps older than the
available device history can be missed after a prolonged absence. Past daily
activity bonuses are not promised to replay retroactively; passive growth does
not depend on that finite step history.

## Glance and persistence

Canonical `v4`/legacy saves are not replaced or renamed. A new optional
`glance.v1` cache contains only 23 display/sleep fields (including optional
Issue #17 wake/grump timing), not full inventory,
history and paused games. It is written after a successful canonical commit,
only when changed. An absent cache displays OPEN GAME until foreground open;
it never risks loading the full save into a 32KB Glance VM. A cache is not an
authoritative save and a crash between writes may leave it stale until reopen.

Glance is read-only and time-aware for sleep/tired mood. On deferred profiles,
cached species, growth and cleanup can be stale until the full app opens. It
does not project unearned evolution or step rewards. Existing watch-app Glance
support is retained on capable models. Older CIQ 3.x firmware treats Glances as
widgets; native watch-app Glance launch is not advertised there. No separate
widget/app is installed to bypass the existing identity.

## Recorded v0.5.2 compatibility evidence

Representative profiles run all 33 unit tests and all 983 rendering scenes.
Other new candidates get their own SDK compilation, 33 tests and focused
473-scene audit: every creature, menu row, Care/Details, game state, adventure
choice and all 16 theme/palette combinations. Repeated exhaustive movement/
world permutations are retained in representative coverage rather than repeated
for every equivalent SKU. This is one deliberate expansion pass, not repeated
all-supported-device matrices.

First accepted representative: Fenix 6S Pro, 33 tests / 983 scenes, zero failures;
QA peak 310,680 / 1,306,136 bytes. Native stale-registration cleanup actually ran
at 10,960 / 28,576 usable background bytes, without loading/modifying the pet.
The initial full-engine callback loader OOM is recorded as a failed attempt,
not a pass. Enduro 4 and Forerunner 265S also passed 33/983. The 218px
Forerunner 255S initially exposed clipped bottom labels; a sub-240px-only
vertical text adjustment then passed 33/983 (122,856 / 519,968 bytes).
Larger layouts are unchanged by that guarded adjustment.

Non-Pro `fenix6` passed logic tests but failed the main audit AND an isolated
release build of the actual production entry with Out Of Memory. Its 128KB
foreground budget, not the repaired background service, is the remaining limit.
The Pro profiles have a much larger 1.25MB budget. It is not advertised as working
just because an egg-only screen might fit under a reduced test.

Optional gradual typecheck level 1 did not complete within the focused build
window on Fenix 6S Pro or Enduro 4 and was stopped; no SDK root cause or successful
gradual-check result is claimed. Compatibility checks use
the real Monkey C compiler/linker at level 0 plus native tests, not structural
preflight as a substitute. Final per-profile results are recorded in
`compatibility/sdk-results.csv`; the release hash and focused public/owner checks
are in `releases/v0.5.2/RELEASE_0_5_2_VERIFICATION.md`. Raw logs stay ignored under `bin/`.

Changed commits write a canonical document plus a small changed Glance cache;
unchanged commits still write neither. This is a storage/memory trade-off, not
a measured battery gain. No claim is made about physical-watch power use.

Native Enduro 4 regression: normal background policy remained enabled; a full
fixture with XP 123456, three paused games and inventory slot 18 ran its Steps
Progress callback at 43,272 / 61,344 bytes, two necessary writes, 15ms coarse host
elapsed time. Native Glance passed 60 scenes at 33,304 / 61,344 bytes. The prior
v0.5.1 full-save-sized QA payload measured 40,336 bytes; the new payload models
the compact cache, so this is not an isolated renderer or battery benchmark.

Actual simulator START/UP/DOWN/BACK inputs on Fenix 6S Pro registered consecutive
memory moves separately, moved/jumped/caught a Bounce star (score 12), paused,
and completed a three-stop Ember adventure with a Crown discovery. The beast
and rewards were RAM-only QA data, not a player's save or fabricated Garmin
activity. A release build of the normal production entry (isolated QA ID) also
opened successfully; sampled foreground use was about 180KB within 1.25MB.
Unedited captures are in `docs/compatibility/screenshots/`; not watch photographs.

## References

- [Garmin background event removal APIs](https://developer.garmin.com/connect-iq/api-docs/Toybox/Background.html)
- [Garmin app types and older widget Glances](https://developer.garmin.com/connect-iq/articles/connect-iq-basics/App_Types.html)
- Installed SDK compiler/simulator definitions supply profile limits and aliases.

Hardware acceptance remains open; simulator success is not physical certification.

## Release selection (v0.5.2)

47 SDK profiles: the existing 13 plus 34 accepted candidates. This includes
Fenix 6S Pro, 6 Pro and 6X Pro, additional Fenix 7 Pro/8 AMOLED/Epix profiles,
Forerunner 165/255/265S/570/745/945/970 variants, Venu/Venu 3S/4 and
vívoactive 4/4S/6. The manifest and CSV give exact SDK IDs, not retail aliases.

Excluded: non-Pro Fenix 6/6S (128KB foreground memory); Fenix 5 Plus/5S Plus/
5X Plus (433 layout failures each). Venu 2/2S/2 Plus passed main unit/layout
checks but are held because native background and input acceptance is unfinished.
No further device investigations or simulator matrix runs form part of this release.

Public builds remove owner menus, mutation methods, accelerated clocks, forced
stage/family overrides, sky previews and DEV badges before compilation. Owner
builds explicitly use `-Owner`; Store export rejects that switch. See the release
record for exact commands and the same-identity owner-update caveat.
