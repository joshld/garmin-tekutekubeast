# v0.5.1 signed beta candidate verification
> Version-specific release evidence, not everyday build instructions. Start with
> [current guides](../../../README.md#documentation).

17 October 2026. Runtime source: `3a2c013`; subsequent changes only affect QA,
captures, records and merging the owner's root instructions. Not published.
Historical v0.4/v0.5 verification records remain unchanged.

## Identity and package

- Existing application ID: `54A4F9D3B6584CA4B01C232D20438E5B`.
- Signing public-key SHA256 remains
  `276489F20EC9F9605CADE733D7F5D60FB04E8696C5E50FF8E431F873825FCA7C`.
- SDK 9.2.0, Java 17.0.20. Release gradual typecheck level 1 and development
  builds returned `BUILD SUCCESSFUL`. Existing export built all 19 hardware
  parts successfully; hardware parts are NOT 19 simulator-validated profiles.
- `bin/TekuTekuBeast-0.5.1.iq`: 4,507,148 bytes; SHA256
  `C865E88C95626734D58BC5FA0DE70DEE3EA150E91F0EE84B303C33E17FA6EF5C`.
- `bin/TekuTekuBeast-0.5.1-release.prg`: 3,989,948 bytes; SHA256
  `AD3F835B4C39BA41FF8403E1A39DE03A590CEB0412B909AD03C2F8C72F8C2337`.
- Exported Enduro 4 part `006-B5169-00/TekuTekuBeast-0.5.1.prg` is byte-identical
  to that strict standalone release. Identity/hash checks actually executed in
  `scripts/verify_v051_release.ps1`; log `bin/v051-artifact-verification.log`.
- That exact exported part subsequently launched successfully in the Enduro 4
  simulator. Pet/scenery, Care and Details were inspected. It had a fresh native
  simulator save; this was not a physical-watch or existing-Pip upgrade test.

## Focused final validation

- Enduro 4: 32 unit tests passed; 983 layout scenes, zero failures.
- Main rendering QA sampled peak: 120,992 / 781,976 bytes.
- Native Glance: 60 scenarios, zero failures; 40,336 / 61,344 bytes sampled peak.
- Two native Steps Progress callbacks: 41,216 / 61,344 bytes post-reconciliation.
- Art check: 480 exact historical v0.4 pose canvases/mirrors; existing game and
  Glance pixels unchanged. Actual SDK theme/sky captures and comparison sheets
  are under `art/store/v0.5.1/`, with their QA provenance disclosed.
- Actual button tests and pacing, save/DEV/solar/battery counter regressions,
  and remaining native/hardware limitations are in `V0_5_1_VALIDATION.md`.
- Latest root `AGENTS.md` read and merged from remote. Only focused Enduro 4
  checks were run after that instruction; wider prior work is not final coverage.

Verbose local logs remain ignored under `bin/`. No real watch was reset,
uninstalled, modified or claimed tested. No Garmin Store upload was performed.
Use `RELEASE_0_5_1.md` for an update of the existing beta, not a new installation.
