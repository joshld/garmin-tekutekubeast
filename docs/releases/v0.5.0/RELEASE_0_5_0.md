# TekuTekuBeast 0.5.0 beta candidate
> Version-specific release evidence, not everyday build instructions. Start with
> [current guides](../../../README.md#documentation).

## What's new

- A bigger beast with room to roam, mirrored walking poses, hops, blinks and
  clearer eating, cleaning and evolution reactions. The Pet screen prioritises
  your beast; species and evolution details are on Details.
- Attention-only food and heart icons, with visible poop to clean. Full
  numerical needs remain on Care. Motion OFF, LOW and NORMAL are retained.
- Scheduled bedtime, curled sleeping/tired poses, automatic virtual lights-out,
  optional manual lights and a configurable schedule fallback. Daytime resting
  and nighttime sleep are distinct. No overnight sound or vibration.
- Beast Bounce: fifteen falling-star targets, three stages, jumping, platforms,
  combos, scores, easy mode and replay.
- Follow My Lead: copy your beast through three growing sequences, with retries,
  character reactions, button/touch controls and timed SELECT alternatives.
- Tiny Adventures: four destinations, travelled maps, three encounters, choices,
  treasure and replay. One Adventure Energy pays for the whole expedition.
- Paused games resume safely. Rounds do not consume separate daily rewards.
  Completed arcade sessions share three rewarded plays per day, then unlimited
  practice. No-energy scouting remains available without loot.
- Longer gentle vibration, optional expressive pulses, distinct short sound
  patterns and diagnostics for Garmin tones, Do Not Disturb and API failures.
- Glance sleep/mood consistency and new Developer Mode bedtime/wake/needs tests.

Your genuine steps, existing pet, growth, friendship, snacks, inventory,
collections and activity history are retained. Games never manufacture Garmin
steps. Time, care and play remain complete alternatives to exercise.

## Installation safety

Update the existing installation; **do not uninstall it first**. Keep the same
application ID and signing key. SDK-only test programs must not be installed as
the game. This candidate has not been published to the Garmin Store.

For the Store route, the owner must explicitly approve uploading the signed
`TekuTekuBeast-0.5.0.iq` to the **existing beta listing**, set version `0.5.0`,
then update that installation through Connect IQ and sync. A sideloaded PRG can
be mistaken for a separate Store installation, so do not replace/rename a
Store-managed app file without an app-data backup and a verified mapping.

After updating, open Actions > Settings > Version and confirm `0.5.0 beta`.
Check Details and Collection before entering Developer Mode. For safe previews,
enable Settings > Developer > temporary test, use Dev Tools, then Discard.

### Exact owner installation sequence

1. Before updating, photograph the current watch's Details, Care and Collection
   screens so genuine XP, stage/family, bond, snacks and items can be compared.
2. Once approved, open the existing TekuTekuBeast entry in the Garmin developer
   dashboard and upload the signed `.iq` above as an update, **not a new app**.
   Set display version `0.5.0`, keep the beta/testing setting, and use the plain
   description/What's New files under `art/store/v0.5`. The `.iq` is for the
   dashboard; it is not a file to copy directly to the watch.
3. After Garmin accepts/makes the beta available, use the existing TekuTekuBeast
   installation's Update action in Connect IQ and sync the Enduro 4. Do not
   uninstall, clear app data, reset the watch or create a duplicate sideload.
4. Open the watch app, confirm Settings shows `Version 0.5.0 beta`, then compare
   the real pet's Details/Care/Collection with the photographs. Time-based growth
   may legitimately advance, but genuine XP/inventory must not reset or regress.
5. Open the existing native Glance from the watch's Glances list and select it
   to launch the game. Check its creature/mood against the full app.

### Short physical Enduro 4 acceptance checklist

- Save upgrade: same pet, earned stage/family, genuine XP, bond, snacks, items
  and discoveries; actual steps reconcile once, including after DEV testing.
- Pet: crisp readable sprite, clear needs/poop, all motion modes, no circular
  clipping or HUD overlap. Test advanced forms in temporary DEV, not the real save.
- Sleep: correct schedule/source, manual fallback, bedtime/wake while closed,
  daytime Rest and optional virtual lights; no overnight cues or lost growth.
- Games: repeated sessions feel understandable and fun; test UP/DOWN/START/BACK,
  replay, interruption/reopen, one expedition charge and no duplicate items.
- Glance/feedback/battery: correct preview and full-game launch, game timeout
  resume, Alert Tones/DND settings, independent haptics and normal daily battery.

If progress unexpectedly regresses, stop and report the version and screenshots;
do not uninstall or reset as a troubleshooting step.

## Acceptance and limitations

[V0_5_VALIDATION.md](V0_5_VALIDATION.md) records the actual SDK tests and remaining
hardware checks. A simulator pass is not a physical Enduro 4 pass or a battery
measurement. Watch schedule values are not assumed to be Garmin Sleep Focus
events; MANUAL/OFF are available. Audio obeys Garmin Alert Tones and DND.

Rare forms still use an earned crown overlay rather than separate full sprite
sets. Adventure environments are lightweight pixel maps, not full-screen scene
atlases. Game enjoyment and difficulty need the owner's real-watch feedback.
