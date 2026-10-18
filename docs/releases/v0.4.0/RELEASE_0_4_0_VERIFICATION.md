# 0.4.0 signed beta verification
> Version-specific release evidence, not everyday build instructions. Start with
> [current guides](../../../README.md#documentation).

Built 16 October 2026 with SDK 9.2.0, Java 17 and the existing private signing
key. Source includes the final reaction-navigation fix `fe96ba5`; the production
manifest contains twelve accepted SDK profiles. Garmin expanded their part
numbers into eighteen signed PRG variants. No QA app is included.

The final package was extracted and its Enduro 4 PRG was byte-for-byte matched
to the release binary actually run in the simulator. The application ID remains
`54A4F9D3B6584CA4B01C232D20438E5B`.

SHA-256:

- Garmin upload package: `030F2C89D162F85C4A6900DA9DE4A3D9609C3DF8CE13D27C9178FDBDB3F298AF`
- Enduro 4 release PRG: `CB694AB3665AAF8F5D37058B9B89BAFE3C0CBB23C8211529DD19FBB2D0061261`

The simulator retained Pip, day 0, bond 6 and 3,000 lifetime watch XP after the
release upgrade. SDK Steps Progress was triggered without duplicate XP or a
reported exception. Fenix 6X's separate production callback test failed with
Out Of Memory; it was removed before this final export.

Settings/Developer and Star Catch were additionally exercised using visible
simulator watch buttons in the signed release: BACK returned from a started
game, reopening still showed REWARDS 0/3. Full gameplay and memory/layout results
are in [validation](V0_4_VALIDATION.md) and [device matrix](DEVICE_MATRIX.md).

A completed timed DEV game reached its result screen; restarting the app then
restored genuine Pip/day 0/bond 6/3,000 XP with DEV off. The production Glance
was launched separately from the final package and displayed the real cached
Pip/COZY/growth summary at approximately 24.6 KiB of 59.9 KiB SDK memory.
This is the actual production save view, not the synthetic Glance QA payload.

The tests above are simulator tests, not agent-operated physical-watch tests.
On 16 October 2026 the user reported Developer Mode visible on their watch and
confirmed that TekuTekuBeast now appears in their Enduro 4 Glances list.
Actual-user save migration, Glance selection-to-game/rendering/timeouts, real
sensor sessions, audible tones, vibration and battery life remain hardware
acceptance checks. See [the acceptance log](../../WATCH_ACCEPTANCE.md). Update the same
beta installation without uninstalling; do not replace it with an isolated QA app.

The subsequent store-art/documentation update does not change the application
binary or the hashes recorded above. Store assets and copy live in
[art/store/v0.4](../../../art/store/v0.4/README.md). The user reported a Garmin submission
error followed by the dashboard showing 0.4.0; successful saving of all listing
metadata has not been independently verified.
