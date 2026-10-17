# TekuTekuBeast for Mum's standard Fenix 6S Pro

Compatibility beta candidate: **0.5.2**. Not yet published to Garmin.
Use the `fenix6spro` program, not `fenix6s` (non-Pro), not an Enduro program.
Garmin's 6S Pro profile also covers Sapphire/Pro Solar variants; the standard
6S Pro is the primary tested simulator target. Physical-watch acceptance remains.

## Private USB test - no Store publication required

Check Settings > System > About first. The installed SDK's standard 6S Pro
part targets firmware 27.00 or newer; update through Garmin if the watch is older.

These steps assume TekuTekuBeast is **not already installed** on Mum's watch.
If it is installed through the Store, do not uninstall or create a second copy:
use an update of that existing installation once the owner approves publication.

1. Connect the Fenix 6S Pro to a Windows computer with its USB data cable.
2. Open the watch in File Explorer and find its `GARMIN/APPS` folder. If the
   folder isn't exposed, check the watch's USB/MTP mode or use Garmin's normal
   USB support; do not format/reset the watch.
3. Copy only the verified signed **TekuTekuBeast-Public-0.5.2-fenix6spro.prg** into
   `GARMIN/APPS`. Do not copy the `.iq`, QA programs or signing key.
4. Safely disconnect. On the watch press START and find TekuTekuBeast in the
   activity/app list; add it to favourites if desired.
5. Open once to establish the starting step baseline. Existing steps before
   that first open are not retroactively turned into XP for a brand-new beast.

The separate-UUID public `.iq` is intended for a new public listing; it does not
update the existing Developer Beta. See `PUBLIC_RELEASE_0_5_2.md`. If the older
same-UUID candidate was installed, its saved pet stays in that older app; the new
public app starts a separate pet. Do not uninstall expecting progress to transfer.
Do not mix a USB copy and Store copy or uninstall to switch methods if there is
progress to retain; ask for a safe transition check first.

## Buttons

- UP / DOWN: change Pet, Care and Details pages; move through menus.
- START / SELECT: Actions, confirm choices; jump in Beast Bounce.
- BACK: return or pause a game.
- Beast Bounce: UP/DOWN move between platforms; SELECT jumps.
- Follow My Lead: repeat the demonstrated UP / SELECT / DOWN sequence.
- Tiny Adventures: choose a destination, then choose at each encounter.

## What differs on this older watch

Open the game daily. Step XP, growth, care and sleep catch up when the full app
opens instead of running the large game engine in the 32KB background service.
Your beast still grows through elapsed time without walking or keeping the app
open. Very old steps may be unavailable after a prolonged absence because
Garmin's activity history is finite. No background pet notifications are lost.

CIQ 3.x uses widget Glances; native watch-app Glance launch is not advertised
for this profile. Open TekuTekuBeast from START/apps. Existing Glance support on
newer capable watches is retained, with cached stage/progress refreshed on open
where activity is deferred. GPS is never continuously enabled for scenery.

## First-watch check

- Settings shows 0.5.2 beta; Pet, Care and Details fit the round display.
- All buttons and three games work; BACK pauses and reopening resumes safely.
- Feed, clean, rest and reopen; inventory/progress remain.
- Walk normally, reopen, note XP; reopen again and verify no duplicate credit.
- Leave overnight, reopen, check sleep/wake and elapsed growth.
- Public Settings has no Developer Mode entry.
- Check direct-sunlight contrast, optional sound/haptics and normal battery use.

Do not reset/uninstall the app as a troubleshooting shortcut. Report the exact
watch software version and symptom if a check fails.
