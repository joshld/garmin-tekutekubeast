# TekuTekuBeast v0.5.1 beta

Signed candidate prepared; final hashes and executed Enduro 4 test coverage
are in `V0_5_1_VALIDATION.md` and `RELEASE_0_5_1_VERIFICATION.md`.
No Garmin Store submission is performed without the owner's approval.

## What's changed

- Restored the exact v0.4.0 creature scale rather than guessing a percentage.
  Kept the expressive poses, mirrored walking and reactions.
- A much larger world-space route, both horizontally and vertically, with
  circular safety bounds and a broader clearing. Stops, looking, feeding and
  cleaning hold the animal's position rather than teleporting to the centre.
- Original Forest, Meadow, Lakeside and Garden pixel-art environments. AUTO
  favours the beast's family; all four can be selected in Settings.
- Real local sunrise/sunset skies, a subtle sun arc and decorative nighttime
  moon/stars. Cached watch/weather location or confirmed approximate coordinates
  work offline; the last resort is explicitly labelled FIXED 06–18.
- Astronomical day/night is independent of sleep and virtual lights. No watch
  brightness, system clock, GPS recording or genuine steps are modified.
- Clear neutral gaps between every memory cue, including repeated directions.
- Faster normal Bounce pacing (4/3/2.25s), unchanged slower Easy timing and safe
  conversion of paused v0.5 sessions.
- Dirty-save detection, duplicate-step fast path, cached sleep-profile reads,
  fewer unchanged redraws and still-screen timer wakeups. Existing game rewards,
  progress, activity credits, Glance and isolated in-app Developer Mode remain.

## Installing without losing your beast

1. Keep the current installation on the Enduro 4. **Do not uninstall or reset.**
2. Once ready to submit, open
   https://apps-developer.garmin.com/developer/dashboard in a desktop browser.
3. Open the existing TekuTekuBeast beta listing. Choose its new-version upload,
   not Upload a New App. Select the signed production `TekuTekuBeast-0.5.1.iq`.
4. Set version **0.5.1**, retain beta/testing status, and paste the prepared
   What's New text. Review the additional Positioning permission: it is used for
   cached/approximate solar location only, with no GPS activation or transmission.
   Review the listing's privacy disclosure too: rounded coordinates are now
   retained locally on the watch. Prepared copy is in `art/store/v0.5.1/`.
5. Submit only when the owner approves. After Garmin makes the beta update
   available, update the existing app through Connect IQ and sync the watch.
6. Open it and check Settings > Version 0.5.1 beta, your pet/evolution, lifetime
   watch XP, friendship, snacks, inventory, collections and any paused sessions.
7. Settings > Outdoor world > Sun / location shows the source, rise/set, engine
   and fix age. If FIXED is shown, try Read watch cache, retain a SAVED location,
   or set BOTH approximate latitude and longitude and confirm Use this location.
8. Keep the system Alert Tones setting enabled only if audible feedback is
   wanted. In-app sound remains off by default; DND/system mute is respected.

Normal gameplay, cached-location astronomy and saved progress require no phone
or internet once installed. Location availability differs by watch/firmware.

## Short physical-watch acceptance checklist

- Existing progress survives the update; genuine steps catch up without doubles.
- Small original-sized beast roams broadly, fits the circle and stays readable
  outdoors; check Egg, Pip and later forms with Motion OFF/LOW/NORMAL.
- All four worlds, actual sunrise/midday/sunset/night and lights/sleep behave as
  separate systems. Try offline/no-location/manual fallback.
- UP / UP is visibly two cues. Normal Bounce is lively but fair; Easy remains
  forgiving. Try pause/resume/replay and check rewards/energy only apply once.
- Glance opens the game correctly; OS timeout/inactive transitions retain games
  and stop animations. DEV test changes discard while real progress returns.
- Observe comparable daily battery use. SDK execution counters are not physical
  power measurements.
