# Physical-watch acceptance and user reports

## Current Enduro 4 acceptance - v0.7.0 development

Use this section for current development; historical artifacts below are not
current test inputs. [GitHub Issues](https://github.com/joshld/garmin-tekutekubeast/issues)
owns acceptance status. Record physical results there; SDK passes do not establish
watch save retention, battery life or operating-system behavior.

### Choose and update the matching installation

- Verify the signed Enduro 4 build's recorded source includes storage/resource
  work through [f702d71](https://github.com/joshld/garmin-tekutekubeast/commit/f702d713f2c7d75cb1baad465eed8d24531ea366)
  and generation/reward recovery through [4d334b0](https://github.com/joshld/garmin-tekutekubeast/commit/4d334b098b23244126f0659333636fa75055f07b).
  Settings may still say **0.7.0 beta**; version/filename alone does not prove source.
  The verified IQs from ac49e39 predate these changes; see
  [package provenance](VALIDATION.md#final-v070-packages---source-ac49e39).
- Reuse a verified matching device build if available; otherwise request only
  that device build using [current build instructions](BUILD.md#everyday-enduro-4-development).
  A new IQ export or Store publication is not required for local acceptance.
  This guide does not claim a current private artifact has been prepared.
- Developer Beta uses -Owner and UUID
  54A4F9D3B6584CA4B01C232D20438E5B; its DEV tools and original pet remain.
  Public uses the default build and UUID
  53C660EBC4454BCF9292E5591EEC18DA; DEV is excluded and its pet is separate.
  Both retain the existing signing key; see the
  [identity table](BUILD.md#environment-and-safe-inputs).
- Photograph pet/stage, XP/growth, friendship, inventory, collections, settings
  and saved sessions before updating. A photograph is not a recoverable backup.
  Follow [safe installation](BUILD.md#installation-and-publication): update only
  the positively identified matching installation. Never uninstall, clear
  Storage, copy saves or create a duplicate USB installation to work around doubt.
  Do not install isolated QA/test fixtures over either real app.
- Reopen and compare before testing. Stop on an unexpected new egg, lost progress,
  duplicate app or changed identity. Care, elapsed growth and genuine new steps
  may legitimately update values.

### Focused checks for #27 and #29

| Check | Expected result / failure condition |
| --- | --- |
| [Storage/resource efficiency #27](https://github.com/joshld/garmin-tekutekubeast/issues/27): leave Pet idle for several minutes, then close/reopen and restart the watch normally. | Growth continues and elapsed progress recovers without duplication. Glance growth may lag up to one minute during quiet foreground use. Fail on missing/doubled progress, errors or persistent stale needs. All creature, game, battle, launcher and Glance artwork must remain present. |
| #27: walk with the app open and closed; reopen twice; perform care, save a game, interrupt with an alert and return. | Real XP is credited once; actions, inventory and sessions persist. Fail on lost actions, duplicated rewards or incorrect step credits. Observe responsiveness and compare similar-use battery days; physical testing does not directly measure Storage write counts. |
| [Generation isolation #29](https://github.com/joshld/garmin-tekutekubeast/issues/29): pause each game and a wild/practice battle, then deliberately Archive/start egg. | Unfinished sessions retire without loot or Energy refunds. Old sessions must not resume or affect the egg. Queued encounters, inventory, collections, lifetime XP, Battle XP/mastery and daily limits carry forward. |
| #29: leave a completed battle result unclaimed, deliberately archive, then reopen/restart and revisit battles. | Earned XP/mastery and the claim persist exactly once; no old combat snapshot resumes. Fail on missing/repeated rewards, reset daily caps or loss of retained progress. Injected write-failure/retry cases are SDK-tested, not physically proven. |

Try generation interactions first in isolated Developer Mode; never archive the
real pet just to simplify a test. DEV discard preserves the real pet but cannot
prove durable generation persistence. For that check use an owner-approved
separate test installation, or an explicitly intended real-pet archive; do not
transfer real saves. Keep physical #27/#29 acceptance open until reported.

Record model/firmware, app identity, source/hash, date, steps and observed result.
The [shared procedure](#physical-acceptance-procedure) covers existing gameplay;
[validation](VALIDATION.md) separates SDK evidence from pending physical checks.

## Physical acceptance procedure

[GitHub Issues](https://github.com/joshld/garmin-tekutekubeast/issues) owns
acceptance status and outstanding tasks. The checks below are a reusable test
procedure, not a second backlog. Record results against the relevant issue:
[UI/lighting contrast #15](https://github.com/joshld/garmin-tekutekubeast/issues/15),
[Nimble/facing/crescent #22](https://github.com/joshld/garmin-tekutekubeast/issues/22),
[sleep appearance #12](https://github.com/joshld/garmin-tekutekubeast/issues/12),
[schedule #13](https://github.com/joshld/garmin-tekutekubeast/issues/13),
[Wake Up #17](https://github.com/joshld/garmin-tekutekubeast/issues/17),
[games #14](https://github.com/joshld/garmin-tekutekubeast/issues/14),
[battles #20](https://github.com/joshld/garmin-tekutekubeast/issues/20),
[Glance #10](https://github.com/joshld/garmin-tekutekubeast/issues/10),
[DEV #7](https://github.com/joshld/garmin-tekutekubeast/issues/7),
[feedback #5](https://github.com/joshld/garmin-tekutekubeast/issues/5),
[device/battery #9](https://github.com/joshld/garmin-tekutekubeast/issues/9) and
[release/dual installation #18](https://github.com/joshld/garmin-tekutekubeast/issues/18).
Issue #21's focused implementation acceptance is complete; its real-watch visual
and battery checks are tracked in #15/#9, with sleep scheduling owned by #13.

Simulator evidence is in [Validation](VALIDATION.md); it is not physical-watch
acceptance. Keep completed reports below with app version/build hash, watch
model/firmware, date, action and result where available. Do not turn an unreported
check into a pass. Physical checks remain open unless explicitly confirmed.

- **Safe update:** note pet/stage, genuine XP/history, friendship, inventory,
  collections and settings before updating the matching app. Keep the existing
  Developer Beta installed; public starts a separate pet. Never uninstall/reset
  Storage or copy saves. Check both identities independently if dual-installed.
- **Care and UI:** feed on a zero-step day, wait for poop, clean, pet/rest and
  reopen. Check original-sized creatures, broad horizontal/vertical roaming,
  circular boundaries, attention-only icons and direct-sunlight contrast.
- **Scenery and sleep:** inspect ten environments and real dawn/day/dusk/night;
  check location source/age, saved/manual/offline fallback and watch time-zone
  changes. Sunset must not force bedtime. Verify scheduled sleep/wake, morning
  reopening and virtual lights without changing the hardware backlight.
- **Issue #21 lighting:** compare ON/OFF at night in each theme; beast, needs and
  menus must remain readable in real MIP lighting. Check AUTO/selected/applied
  labels, one-hour countdown, reopen persistence and expiry back to bedtime
  behavior. ON must not wake a sleeping pet; OFF must not force sleep. Sun/moon
  positions and the real sky must not change. No physical Issue #21 pass yet.
- **Games and recovery:** distinguish repeated UP cues; judge normal/Easy Bounce
  fairness and button/touch response. Complete a three-stop adventure. Pause,
  suspend, reopen and replay without duplicate energy charges or rewards.
- **Issue #17 sleep:** during naps and scheduled night sleep, Feed/Pat/Play/Clean
  must stay visible, show `Beast is asleep.` quietly and consume nothing. Wake Up
  must allow care without confirmation or immediate scheduled re-sleep. Compare
  nap wakes at 5/15/20/30 minutes, brief grumpy recovery, natural waking and next
  night's schedule. Reopen during an override; pause a game at bedtime and resume
  after waking with no duplicate energy/reward. Repeated Wake Up/Rest must not
  earn extra Rest bonuses. Confirm real-watch posture, buttons, silence, time-zone
  handling and Glance agreement; no physical Issue #17 pass yet.
- **Real activity:** walk, reopen and reopen again; XP must increase once only.
  Check daily rollover and relevant native sleep/wake/step callbacks. On deferred
  profiles open daily for foreground catch-up; do not expect native watch-app
  Glance launch on older CIQ 3.x. See [compatibility](COMPATIBILITY.md).
- **Issue #20 battles:** check four complete move names on the 2x2 grid, button/
  touch choice, protection/boost/signature reactions, comfortable short pacing,
  pause/reopen, sleep/Wake Up and one-time rewards. Verify step encounters arrive
  silently after catch-up, and daily/care/adventure routes work at zero steps.
  Check original pet progress, DEV discard, real memory and battery; no physical
  battle acceptance or wider-device runtime validation is claimed yet.
- **Personal DEV only:** accelerate/test scenarios, discard/restart, and confirm
  original progress plus genuine steps recorded during testing are restored.
  Public Settings must not expose DEV controls.
- **Glance and feedback:** verify sprite/name/mood/growth/poop, selection into the
  game and inactivity timeout where supported. Check independent sound/haptic
  settings, Alert Tones, DND and bedtime silence; system mute is not bypassed.
- **Battery:** compare similar normal-use days and record app use/settings.
  SDK timing/RAM does not establish real battery drain or OS event frequency.

[Fenix 6S Pro installation](INSTALL_FENIX_6S_PRO.md) adds device-specific checks.
Outstanding hardware checks belong to their respective features; they are not
essential unfinished code-cleanup work in Issue #19.

## First two-watch friend test (Issue #20)

Use current matching-identity builds from the instructions above and the
[Fenix guide](INSTALL_FENIX_6S_PRO.md). The old 0.6.1 artifact paths are retained
below as history, not current installation inputs.

1. Photograph both pets, XP, inventory and any saved solo battle. Ensure both
   beasts are hatched and awake; check the new Battle a friend row is present.
   On a separate new Beta test pet, Developer Mode can temporarily select a
   hatched form; do not reset or transfer the existing public pet.
2. Keep the watches nearby and both apps in the foreground. No phone, GPS, Wi-Fi
   or internet is required. The build requests ANT permission; no ANT+ sensor or
   external radio is needed. If firmware disables ANT, enable its normal radio
   setting; report the exact firmware/error rather than changing sensor pairing.
3. On one: Play > Wild battles > Battle a friend > Host. On the other choose
   Join; enter the host's four-digit code with UP/DOWN and SELECT for each digit.
4. Check the displayed opponent's species, YOU/FRIEND and HP; both press SELECT
   to Ready. Pick named techniques with UP/DOWN and SELECT. Verify guard, buff,
   signature cooldown, moves, damage and HP match on both watches. Mash SELECT
   once to confirm it does not submit an extra turn. Complete victory/defeat,
   then a guard-heavy draw if convenient. There must be no XP/items/Energy changes.
5. Test BACK during pairing and mid-match; the other watch should report the
   cancellation/loss. Briefly separate the watches and return to test retries;
   longer loss, an alert/app hide or restarting one watch must end safely, never
   award a result or resume a stale session. Reconnect for a new match.
6. Swap Host/Join and test Developer Beta against public. Confirm original pet
   progress, real-step catch-up and saved wild battle/rewards still work. Check
   radio/timers stop after leaving and note responsiveness/battery concerns.

For diagnostics, create an empty `GARMIN/APPS/LOGS/<installed-program-name>.TXT`
matching the actual PRG basename before reproducing. Collect that file and
`GARMIN/APPS/LOGS/CIQ_LOG.YML` if present, plus watch model/firmware, app identity,
Host/Join, code, time and exact screen/error. `FRIEND_ANT` lines identify radio
configuration/send/release failures; do not post signing credentials or pet saves.
Record physical results on [Issue #20](https://github.com/joshld/garmin-tekutekubeast/issues/20).
All real RF pairing, coexistence with sensors and radio battery impact remain
unverified until this procedure is performed on both watches.
## Historical v0.6.1 friend-battle test artifacts

Retained preparation/installation record, not current build guidance or evidence
of physical acceptance. Do not upload/install these old artifacts for current
v0.7.0 acceptance; use the matching-source instructions above.

Use the matching identity; never uninstall, reset Storage or install the public
build over the Developer Beta. No watch has been installed automatically.

- Enduro 4 existing Developer Beta: `bin/friend-acceptance/TekuTekuBeast-Dev-Enduro4.prg`.
- Fenix 6S Pro separate Developer Beta test: `bin/friend-acceptance/TekuTekuBeast-Dev-Fenix6SPro.prg`.
- Fenix 6S Pro public identity: `bin/friend-acceptance/TekuTekuBeast-Public-Fenix6SPro.prg` (matching approved update only).
- Enduro 4 existing public app, if preferred: `bin/friend-acceptance/TekuTekuBeast-Public-Enduro4.prg`.

These were signed device builds from the then-current source, version 0.6.1 beta,
not Store IQ packages. Follow [safe USB installation](BUILD.md#installation-and-publication)
and the [Fenix guide](INSTALL_FENIX_6S_PRO.md). For an existing Store install, do not add a duplicate USB copy: use an approved
update of that installation. For the first radio test, a separate Developer Beta
on the Fenix keeps its public pet untouched. Copy only the matching device/app
`.prg` to `GARMIN/APPS`, safely eject, and retain existing installation/data.
If unsure which app identity is installed, stop rather than uninstalling it.

## Historical Enduro 4 acceptance build - v0.5.2 source 118bdff

Retained milestone record only; the artifact and owner-operated instructions
below are superseded by current v0.7.0 guidance above.

Source `118bdff64a389efff41b9c2276a5236111751d96`, including the Nimble,
walk-facing and crescent fixes plus earlier offline battles/sleep/lighting.
Private Developer Beta only, not a v0.6.0 release or Store upload:
`D:\working\garmin-tekutekubeast\bin\TekuTekuBeast-Dev-Enduro4-acceptance-118bdff.prg`.
Settings still displays **0.5.2 beta**; the filename/hash identifies this newer
source. SHA256: `E6870E3903568545BCCCE5855A8A2C7C23D8CF59225BDF73F40825AFC9A83562`.
The original Beta UUID/key are retained; public UUID and QA code are absent.

For this historical acceptance milestone, the owner requested a **private
Developer Beta IQ** for Connect IQ delivery. This older package is superseded;
use [current install guidance](BUILD.md#installation-and-publication) for updates.
Its retained output location is
`D:\working\garmin-tekutekubeast\bin\private-acceptance-118bdff\TekuTekuBeast-Dev-0.5.2.iq`;
see [verification](VALIDATION.md#private-developer-beta-acceptance-iq-historical).
Use a computer to upload that file as an update of the **existing Developer
Beta listing only**, retaining its Beta visibility. After Garmin makes the
update available, update/sync that same installed Beta through Connect IQ.
Opening the IQ file on a phone does not install it. Do not uninstall, create a
new listing, update the public app or copy saves. Codex has not uploaded or
installed anything; physical retention/acceptance is still pending.

### Owner-operated update, only after identity/filename confirmation

1. Photograph the real pet's name/stage, XP/growth, friendship, inventory and
   settings first. Record watch firmware. This is a comparison record, not a
   recoverable save backup. Exit the game and connect Enduro 4 by USB data cable.
2. Positively identify the **existing Developer Beta** program and its on-watch
   filename using installed-app metadata/UUID
   `54A4F9D3B6584CA4B01C232D20438E5B`. Do not guess a random PRG filename, select
   the public UUID, or create a second installation. If the Store-managed file
   cannot be identified/accessed unambiguously, **stop before copying**. Request
   a read-only mapping check or use the private-Beta Store update route above
   instead, after the owner uploads it. Do not mix installation methods blindly.
3. For a confirmed accessible in-place USB update, use a PC copy of this PRG
   bearing the **same existing Beta filename**, and replace only that program.
   Garmin's [USB sideload procedure](https://developer.garmin.com/connect-iq/connect-iq-basics/your-first-app/)
   uses `GARMIN/APPS`; it does not establish save retention for every Store/USB
   transition. Do not delete/uninstall anything, edit/copy DATA or SETTINGS, or
   touch the public installation. If the expected file is not exposed there,
   stop rather than inventing another target directory or reset workaround.
4. Safely disconnect and open the existing Beta. Compare progress before trying
   gameplay; stop and report any new egg, duplicate app or unexpected regression.
   Normal care, elapsed time and genuine new steps may legitimately update values.
   Test forced forms only in isolated Developer Mode, then discard it.

Owner acceptance is still pending: confirm Nimble's clean frame edges and facing
through turns/hops, smaller Pip transitions, and the low moon without a dark
horizon cutout. Check Pet layout/contrast/attention icons; play and interrupt
wild battles with named moves and one-time rewards; verify reopen/step catch-up,
DEV discard, responsiveness and ordinary-use battery. Record results in
[#24 release readiness](https://github.com/joshld/garmin-tekutekubeast/issues/24),
with feature-specific confirmation in #22/#15/#20/#18. No installation or
physical acceptance is performed by preparing this file.

## Historical v0.5.0 feedback / v0.5.1 boundary

The owner reports installing v0.5.0 on their physical Enduro 4. The enlarged
creature was too big: restore the exact v0.4 pixels while expanding roaming
independently. They also report that consecutive identical memory cues look
continuous and normal Bounce stars feel slow. These observations drive the
v0.5.1 changes; they are not physical verification of the resulting candidate.

The [v0.5.1 validation and physical checklist](releases/v0.5.1/V0_5_1_VALIDATION.md) records
version-specific SDK evidence and still-required watch checks, including cached-location
astronomy, sleep independence, progress preservation and comparable-day battery
use. No agent-operated physical v0.5.1 test or Store submission is claimed.

The records below remain historical reports, not superseding specifications.

## Historical v0.4 hardware feedback / v0.5 boundary

The user subsequently confirmed that vibration works but feels very short, and
sound works when Garmin system Alert Tones are enabled and is blocked when those
tones are disabled. These are v0.4 physical Enduro 4 findings, not v0.5 tests.
The v0.5 changes respect that restriction; they do not bypass system tones or DND.
New UI, sleep behaviour, games, feedback patterns and save upgrades still require
the [v0.5 hardware checklist](releases/v0.5.0/V0_5_VALIDATION.md#physical-acceptance-still-required).

## Enduro 4 - v0.4 beta - 16 October 2026

Evidence in this section is the user's report from their physical watch, not
agent-operated testing. The exact installed binary hash and watch firmware
version have not been read from the watch.

Confirmed by the user:

- Developer Mode is visible in the installed TekuTekuBeast app.
- TekuTekuBeast now appears in the watch's Glances list. It initially did not.

The user was offered open/exit, sync and normal power-cycle checks, but did not
report which actions they took. Do not claim that a particular action fixed
registration or that a reproducible registration defect has been diagnosed.

Still unverified on physical hardware:

- Glance sprite/name/mood/growth/cleanup rendering, selection into the full game,
  and inactivity/session behaviour including mini-games (issue #10).
- Exact Pip/history/XP/friendship/inventory/settings preservation after upgrade.
- DEV acceleration, scenario reset, discard/restart isolation and genuine-step
  catch-up on the watch (issue #7).
- Actual walking, running, supported minutes/pushes and duplicate prevention.
- The changed v0.5 tone/vibration patterns and DND behaviour (issue #5); basic
  v0.4 sound/vibration and the Alert Tones restriction were subsequently confirmed.
- Long-running battery use and resource behaviour.

Continue updating the existing installation. Do not uninstall, clear Storage or
reset the watch to test the Glance. No save reset or application-ID change is
required by the documented implementation.

## Store submission observation

The user encountered Garmin's generic server-communication submission error,
cancelled, and then reported the dashboard's latest version as 0.4.0. This does
not prove that all description, release-note and image changes were saved.
No agent-operated Garmin upload or completed metadata-submission verification
has occurred. The separate cover and copy changes do not require a new binary.

See [release verification](releases/v0.4.0/RELEASE_0_4_0_VERIFICATION.md) for the unchanged signed
package hashes and [simulator validation](releases/v0.4.0/V0_4_VALIDATION.md) for executed tests.
