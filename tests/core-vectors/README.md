# Cross-platform characterization inputs

These are data, not a second engine. Native `StateTests.mc` runs the same JSON
through the extracted production rules. Future PWA/ESP32 tests can reuse them;
neither platform is implemented by this cleanup.

- `progression.json`: overlay `data` on the existing new-pet defaults, set now
  to birth epoch + `ageSeconds`, then read stage/hatch duration/growth. Relevant
  defaults: passive/care/activity growth and XP 0, stage floor 0, XP baseline 0,
  hatch 24h/minimum 8h, care cap 300, Legendary age 21 days.
- `activity.json`: overlay initial `data`; process samples in order without
  day rollover. Observe non-null steps first, then rewards. Defaults: 32 zero
  day/count slots; XP/snacks/remainder/milestone/adventure/bonus 0, optional
  counter baselines -1, target 2000, activity-unit growth 1000. Expected array:
  `[xp, snacks, snackRemainder, milestone, adventure, activityBonus]`.
- `games.json`: all inputs explicit. Read next random seed and treasure choice
  without claiming a reward. Native tests additionally characterize normal/Easy
  timing, repeated-move blank intervals and non-mutation.

No test writes physical Garmin steps or production saves. The native fixture
uses RAM storage and a fixed epoch, 1792108800. Run `scripts/build.ps1 -Tests`
to refresh generated test literals, or `python scripts/prepare_rule_vectors.py
--check` to verify they match. Generated `RuleVectors.mc` is test-only and absent
from public compilation inputs.
