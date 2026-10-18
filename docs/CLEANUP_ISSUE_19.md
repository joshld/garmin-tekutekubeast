# Issue #19: incremental cleanup checkpoint

Scope: behavior-preserving portability preparation after v0.5.2. No release,
new devices, Store upload or work on #21/#17/#20. See [code map](ARCHITECTURE.md).

## Milestone 1 — progression boundary

- Extracted deterministic growth, evolution, mastery and family selection;
  State retains migrations, DEV overrides, calendar/time reads and transactions.
- Added 15 JSON golden cases and native purity/passive-growth tests. Preserved
  the existing care-only egg gate (care alone at eight hours does not hatch an
  egg below the original growth gate); this cleanup does not rebalance it.
- Enduro 4 / SDK 9.2: 35 native tests, 473 layout scenes, four public-build tests
  passed. Tests cover existing migration, DEV isolation, rewards and step catch-up.
- Native Steps Progress callback with stress fixture: 44,032 / 61,344 bytes,
  two writes, 15 ms SDK timing; XP 123456, three pending games, inventory 18.
  Prior release callback used 43,272 bytes; extraction costs 760 bytes, within
  budget. This is not a physical-watch battery measurement.
- Ignored detailed logs: `bin/cleanup-m1-device-matrix.json`,
  `cleanup-m1-enduro4-tests.log`, `cleanup-m1-enduro4-layout.log`,
  `cleanup-m1-public-tests.log`, `cleanup-m1-background.log`.
  Initial new characterization assertion was corrected to match the unchanged
  care-only gate; all 33 pre-existing tests passed on the initial run too.

## Milestone 2 — activity boundary

- `GarminActivity` normalizes optional fields once per background callback;
  `BeastActivityRules` owns deterministic ledger/reward calculations. State keeps
  lazy catch-up, day rollover, DEV guards and atomic saves.
- Enduro 4: 36 native tests and four public tests passed. JSON traces cover
  baselines, duplicate/rolled-back totals, unavailable counters and reward caps.
- Actual Steps Progress stress callback: 44,800 / 61,344 bytes, one write and
  one unchanged-cache skip, 15 ms coarse SDK timing. No new polling/allocating
  activity snapshot containers. Legacy generator excludes both helpers from
  constrained background scope; no other-device simulator pass is claimed.
- Logs: `bin/cleanup-m2-pass-final-unit-enduro4.log`,
  `cleanup-m2-public-tests.log`, `cleanup-m2-background.log`.
  New test assertions were corrected for Monkey C Long/Number equality and null
  handling; production rules did not need changes to satisfy the golden traces.
- M1 layout evidence reused: this milestone changes no rendering or geometry.

## Remaining milestone

3. Extract mini-game timing/seed/loot calculations; finish boundary documentation.

Both UUIDs, key, save schema, 47-profile manifest, version and signed v0.5.2
release artifacts remain unchanged. No physical-watch tests claimed. Other
devices retain prior evidence; they were not rerun for this Enduro-only cleanup.
