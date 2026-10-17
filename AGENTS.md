# TekuTekuBeast — Codex project instructions

## 1. Scope and delivery
- Define the requested deliverable and minimum acceptance criteria; make the smallest coherent change that fully meets them.
- Finish the requested work before exploring optional devices, features, refactors or repository-wide audits. Record worthwhile unrelated ideas as follow-up issues instead.
- Once acceptance criteria pass, prioritise necessary validation, a safe commit/push and the requested artifact or exact path. Stop optional investigation.
- Ask before starting substantial out-of-scope work. If blocked by an external service, make a reasonable diagnostic attempt, then report the blocker rather than retrying indefinitely.
- Do not trade correctness, security, saved progress or meaningful testing for token savings.

## 2. Device testing and compatibility
- **Default: Enduro 4 (`enduro4`) only** for routine changes. Run focused builds, unit/layout tests and simulator checks relevant to the changed functionality.
- Do **not** routinely invoke `scripts/device-matrix.ps1`, `scripts/glance-matrix.ps1` or equivalent full multi-device suites.
- For Fenix 6-generation changes, test `fenix6spro` (or the actually affected SDK profile) plus `enduro4`. For touch/input, display, API, memory or background risks, add only relevant representative affected profiles.
- Before adding each newly advertised watch SDK product/profile to `manifest.xml`, validate its build, memory, controls, layout and background behavior as applicable. Never advertise an unvalidated model or claim unexecuted tests passed.
- Reuse previously passing SDK/simulator evidence when relevant implementation, SDK, dependencies and configuration have not changed. Rerun tests when those inputs change or regression risk justifies it. Keep essential coverage; disclose untested areas.
- **Always ask the owner before running a full cross-device simulator/test matrix**, even for major changes or releases. Explain the risk and proposed scope first. Keep all existing compatibility scripts, manifest entries and historical evidence; skipping tests does not revoke support.

## 3. Release and validation
- For a public/minor release, export the signed Store package for **every advertised hardware part**, verify application identity, signing and artifact integrity, and run targeted risk-based regressions. Compiling all parts is **not** the same as running the complete simulator matrix.
- Preserve the full release-validation tooling for explicitly approved use, without making an exhaustive suite the automatic release gate.
- Simulators and SDK counters do not establish physical-watch acceptance, battery life or OS behavior; identify real-hardware gaps accurately.
- Never upload or publish to Garmin Connect IQ without explicit owner approval.

## 4. Efficient investigation and implementation
- Inspect directly relevant files first; prefer targeted searches over dumping full source files. Expand only when evidence warrants it.
- Do not reread unchanged files, rediscover documented build commands or repeat successful investigations without reason.
- Reuse existing helpers, artwork, scripts and conventions. Avoid unrelated refactoring or rewriting working code without a concrete need.
- Resolve routine implementation details independently; ask about material ambiguity or player-data risk.
- Only capture screenshots and perform specialized Glance, background or migration tests when relevant.

## 5. Milestones and interrupted sessions
- Split large tasks into reviewable, independently useful milestones. Commit/push **validated and coherent** milestones rather than accumulating large uncommitted changes.
- Never push broken or unvalidated intermediate work to `main`; keep incomplete changes local or use an appropriate feature branch.
- Keep a short checkpoint of completed changes, evidence/log paths, unfinished checks and blockers.
- After interruption, inspect Git status, recent commits, existing outputs, checkpoints and logs **before** restarting work. Reuse valid passing results.
- As session limits approach, prioritize a safe checkpoint, essential validation and deliverables over optional polish.

## 6. Documentation and reporting
- Update documentation only where behavior or workflow actually changes; reserve extensive release notes, screenshots, matrices and evidence bundles for release preparation.
- Keep verbose build/test logs in ignored local files. Avoid repetitive transcripts, duplicate screenshots and overlapping reports.
- Give progress updates at meaningful milestones or blockers. Completion summary: changed behavior/files, test scope/outcome, exact artifact path, commit SHA and remaining limitations.
- Maintain one concise current validation record referencing existing detailed evidence; distinguish new results from reused results.

## 7. Application and player-data safety
- **Never change either application UUID or the signing identity** without explicit approval. The existing Developer Beta is `54A4F9D3B6584CA4B01C232D20438E5B` (root manifest, real existing pet); the owner-approved separate public application is `53C660EBC4454BCF9292E5591EEC18DA` (generated public manifest). Fixed identities are in `config/build-identities.json`.
- Public exports must use `TekuTekuBeast-Public-0.5.2.iq`, compile out DEV, and retain the validated profile set. `-Owner` uses the original Developer Beta UUID and retains DEV. Saves do not transfer automatically between these applications; never reset/uninstall or copy data between them without approval.
- Preserve real saves, migration compatibility, genuine step-XP and watermarks, evolution, inventory, rewards, collections and native Glance.
- Keep Developer Mode test changes isolated from the real pet; public-release DEV exclusion is a separate required acceptance item (see issue #18).
- Never uninstall/reset the production app or clear Garmin Storage to simplify testing.
- Current compatibility and public-release priorities are tracked in GitHub issues #9 and #18; do not interrupt ongoing local Codex work solely to apply these instructions.
