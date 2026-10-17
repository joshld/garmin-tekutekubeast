# TekuTekuBeast — Codex project instructions

## Default testing: Enduro 4 only
- Treat `enduro4` as the **only default device** for routine development, bug fixes, artwork, animation, gameplay and small updates.
- Use focused Enduro 4 builds, unit tests, layout tests and simulator checks relevant to changed code.
- **Do not run multi-device matrices by default.** In particular, do not invoke `scripts/device-matrix.ps1`, `scripts/glance-matrix.ps1` or any equivalent all-profile test in ordinary Codex tasks.
- Keep full compatibility tooling, existing device entries in `manifest.xml`, and historical validation evidence intact. Not testing other profiles in a routine task does not revoke their compatibility.

## Exceptions: broaden tests deliberately
- Run additional profiles when explicitly asked to test compatibility, when adding a device, when fixing a device-specific defect, or when a concrete high-risk API/display/memory change requires a targeted extra check.
- Reserve the **full supported-device matrix** for an explicitly approved major/public release validation or a dedicated compatibility expansion.
- Explain the reason and scope *before* an expensive multi-device run; seek user approval before the full matrix.
- Do not claim devices were revalidated unless they actually passed the relevant tests.

## Conserve Codex time and context
- Prefer the smallest meaningful test set; don't repeat already-passing tests when their relevant inputs have not changed.
- Keep verbose compiler/simulator output in local ignored log files; report a concise summary (command, profile, pass/fail, meaningful errors).
- Avoid huge repetitive matrix transcripts in responses.
- Tests must not be skipped entirely: run focused Enduro 4 checks where feasible and report unverified areas.

## Efficient repository exploration
- Begin with files directly relevant to the request; use targeted searches instead of dumping whole large files.
- Avoid rereading unchanged files or rediscovering documented commands during the same task.
- Broaden investigation only when evidence indicates a wider impact.

## Efficient implementation
- Make the smallest coherent change that completely addresses the request; avoid unrelated refactors or features.
- Reuse existing helpers, artwork, scripts and conventions when appropriate.
- Do not rewrite working solutions without a specific correctness or design reason.
- Resolve routine details independently; ask only about material ambiguity, safety, or player-data impact.

## Focused validation
- Run only relevant unit, layout and simulator checks for changed functionality, defaulting to Enduro 4.
- Run unrelated Glance, background or migration suites only if changes could plausibly affect them.
- Rerun passed tests only when relevant code, inputs or environment changed.
- Generate screenshots when the change requires visual review, not routinely.
- Preserve important regression coverage; explicitly identify what was not tested.

## Documentation and communication
- Update documentation that actually changes; reserve exhaustive release notes, device matrices and evidence bundles for release preparation.
- Keep final reports short: changed behaviour/files, focused test outcome, and remaining risks.
- Store verbose logs in ignored local files; include only meaningful failures and concise pass/fail results.
- Keep the requested scope first; record unrelated improvement ideas as future issues, not surprise implementation.
- Never trade correctness, persistence integrity or necessary testing for token savings.

## Protect existing players
- Never change production application ID `54A4F9D3B6584CA4B01C232D20438E5B` or signing identity without explicit approval.
- Preserve real saves, genuine step-XP ledger, evolution, inventory, rewards and collections; keep Developer Mode state isolated.
- Never uninstall/reset the production app or clear a player's Garmin Storage as a test shortcut.
- Never publish/upload to Garmin Connect IQ without explicit user approval.
- Simulator tests do not prove physical-watch battery life, OS behaviour or hardware acceptance.

## Current workflow
- Do not derail an in-progress v0.5.1 implementation merely to apply this policy. Use these instructions for subsequent tasks.
- See GitHub issue #9 for the broader compatibility roadmap and release test strategy.
