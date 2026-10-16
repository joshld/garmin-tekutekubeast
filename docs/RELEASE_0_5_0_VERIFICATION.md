# v0.5.0 beta candidate - release artifact verification

Source freeze: `27ca7f1` (runtime code and interrupted-start recovery);
`514bd97` expands the isolated QA layout harness. Documentation does not change the binary. Final builds
17 October 2026, Australia/Brisbane; earlier checkpoints are dated 16 October.
Connect IQ SDK **9.2.0**, Java **17.0.20**, Windows.

## Actual compiler results

- Enduro 4 development build: `BUILD SUCCESSFUL`.
- Enduro 4 release (`-r`) build: `BUILD SUCCESSFUL`.
- Signed release export (`-e -r`): **19 of 19** SDK hardware-part variants built,
  followed by `BUILD SUCCESSFUL`. The manifest selects **13 simulator profiles**;
  SDK aliases account for the other parts. This is not 19 independent simulator
  or physical-watch tests.
- Export is a Garmin 7-Zip container, inspected/extracted with `tar`.
- Application ID remains `54A4F9D3B6584CA4B01C232D20438E5B`.
- The exported public signing key's SHA-256 matches the retained v0.4.0 export:
  `276489F20EC9F9605CADE733D7F5D60FB04E8696C5E50FF8E431F873825FCA7C`.
  The private key is local/ignored and is not published.
- Enduro 4's installed SDK definition identifies part **006-B5169-00**. Its
  extracted PRG is byte-identical to the standalone Enduro 4 release PRG.

## SHA-256 and files

All paths below are under local `bin/` and are ignored by Git. The owner-facing
copies are placed in the Codex chat's `outputs` folder; no Store upload occurs.

| File | Bytes | SHA-256 |
|---|---:|---|
| `TekuTekuBeast-0.5.0.iq` | 4,879,028 | `396EA9300176D7D2FC79CBBB9852EC1FD9836C8B9AE79EE2BEBCCC07D0A4F7CA` |
| `TekuTekuBeast-0.5.0-dev.prg` | 4,197,340 | `94ED0600603D614820C48C876F058369020BD8D5EA10076236DD5EA836FFBB7C` |
| `TekuTekuBeast-0.5.0-release.prg` | 4,066,748 | `CD2E732AEF52C90DA72552DD03C29624BA8581DDECE03472C3FB4DAA6D96E955` |
| `export-27ca7f1/006-B5169-00/TekuTekuBeast-0.5.0.prg` | 4,066,748 | `CD2E732AEF52C90DA72552DD03C29624BA8581DDECE03472C3FB4DAA6D96E955` |

## Exact exported-program execution

The `006-B5169-00` PRG above was actually launched in the Enduro 4 simulator.
In normal mode, a non-DEV scouting expedition was paused at stop two, the app
was stopped, and the same exported PRG reopened. Selecting Tiny Adventures
resumed **stop two**, then completed stop three and showed **SCOUT: NO LOOT**.
Exit returned to normal pages. Pip remained Hatchling/day 1, watch XP **3,000**,
bond **6**, Adventure Energy **0**, meals **2**, snacks **1**. Passive growth
advanced with real elapsed time, as intended.

The same PRG was relaunched in the native Glance runtime, displaying Pip /
ASLEEP / growth at approximately **31.8 KiB of 59.9 KiB** in the SDK status bar.
START in the SDK preview did not reproduce a watch Glances-list launch, so no
selection/OS-timeout acceptance is claimed. The simulator was returned to Normal
launch mode and the app stopped without clearing its save.

## Validation boundary

[V0_5_VALIDATION.md](V0_5_VALIDATION.md) records normal-app unit/layout tests,
native Glance budgets, actual background callbacks, manual simulator controls,
save traces and still-required physical acceptance. Neither this export nor a
simulator pass verifies the owner's physical-watch save, tone audibility, Sleep
Focus agreement, battery life or real Glance session timeout behaviour.

The v0.4 release verification, signed package and validation records are retained
unchanged as historical evidence. Update the existing beta, never uninstall to
upgrade. The owner must approve a Garmin Store update separately.
