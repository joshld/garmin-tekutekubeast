# v0.5.0 beta candidate - release artifact verification

Source freeze: `059c94c` (runtime code); `514bd97` expands only the isolated QA
layout harness. Documentation commits do not change the binary. Final builds
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
| `TekuTekuBeast-0.5.0.iq` | 4,873,764 | `B286BA0EBC16D6390138E5814A87609188328D5B01ED1DCFB7E2638A55A48C8A` |
| `TekuTekuBeast-0.5.0-dev.prg` | 4,196,956 | `1707803E644C006F40303CBA0F2050782898E90F59E9316B89831E740E1021EF` |
| `TekuTekuBeast-0.5.0-release.prg` | 4,066,572 | `F9402BE63C2B85EAA1340172705E3774BF5BC6F3DFA5AB84CEDB0F40A5544140` |
| `export-059c94c/006-B5169-00/TekuTekuBeast-0.5.0.prg` | 4,066,572 | `F9402BE63C2B85EAA1340172705E3774BF5BC6F3DFA5AB84CEDB0F40A5544140` |

## Validation boundary

[V0_5_VALIDATION.md](V0_5_VALIDATION.md) records normal-app unit/layout tests,
native Glance budgets, actual background callbacks, manual simulator controls,
save traces and still-required physical acceptance. Neither this export nor a
simulator pass verifies the owner's physical-watch save, tone audibility, Sleep
Focus agreement, battery life or real Glance session timeout behaviour.

The v0.4 release verification, signed package and validation records are retained
unchanged as historical evidence. Update the existing beta, never uninstall to
upgrade. The owner must approve a Garmin Store update separately.
