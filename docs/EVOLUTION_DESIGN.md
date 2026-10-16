# TekuTekuBeast evolution — v0.4

The v0.5 overhaul retains these ledgers, thresholds, families and earned rare
rules. Beast Bounce replaces Star Catch and Follow My Lead replaces Memory Steps
without changing their Ember/Wisp care-personality roles. See
[v0.5 validation](V0_5_VALIDATION.md) for additive migration and regression tests.

Native, offline Connect IQ watch app. Activity is a bonus, not a requirement.
There is no death, XP loss, de-evolution or recovery-day punishment.

## Separate ledgers

- `xp`: genuine lifetime watch-recorded steps, deduplicated by local day.
- `baseGrowth`: elapsed time since v0.4 migration / the current pet's creation.
- `careGrowth`: bounded care and mini-game growth, never Garmin steps.
- `activityBonus`: additional growth from shared physical milestones, including
  active minutes and wheelchair pushes; it never changes watch XP.
- Current-pet growth combines passive/care/activity growth and genuine steps above its
  per-pet baseline. Retiring a Legendary never resets lifetime watch XP.

Legacy keys remain intact. Migration retains an already-earned stage as a
floor, recovers calendar age for early saves without `birthEpoch`, and retains
the existing family, snacks, friendship and watermarks. No passive growth is
retroactively credited before migration. Original app ID stays unchanged.

## Default balance (provisional, testable in Dev Tools)

12,000 passive growth/day, up to 300 care growth/day, plus one growth per newly
eligible genuine step. Positive elapsed growth is not capped to one day;
negative clock movement earns nothing. Care decay alone is bounded to 24h.

| Stage | Growth | Minimum age |
|---|---:|---:|
| Egg | 0 | — |
| Pip | Natural hatch at about 24h | Acceleration floor 8h |
| Nimble | 20,000 | 2 days |
| Adult | 70,000 | 7 days |
| Champion | 150,000 | 14 days |
| Legendary | 300,000 | 21 days |

Egg acceleration uses genuine activity / interaction, not an instant 2,000-step
hatch. An existing Pip never reverts. Zero-step passive-only Legendary takes
about 25 days; consistent activity can reach the 21-day age floor. Mastery then
advances every 25,000 additional growth, including passive/care growth.

## Automatic families

Adult family selection combines activity pattern bonuses and care personality.
Patting/feeding favours Grove; Star Catch favours Ember; cleaning/rest favours
Tide; Memory Steps favours Wisp. Trail choices and toys also influence scores.
Activity can add Grove/Ember/Tide biases but never locks out a nonactivity path.
Ties use a durable birth/serial seed, not an unconditional Wisp fallback. The
family then stays locked except explicit temporary developer previews.

| Family | Adult | Champion | Legendary | Rare variant |
|---|---|---|---|---|
| Grove | Mossbit | Thornbuck | Verdant Elder | Lumenhart |
| Ember | Cindercub | Pyrolynx | Solflare | Ashen Phoenix |
| Tide | Puddlefin | Currentail | Leviathan | Moonwater Kirin |
| Wisp | Flicklet | Nocturne | Starweaver | Eclipse Eidolon |

## Earned exceptions and collection

The first standard Legendary in each family registers in the museum and earns
a Star Charm. A Legendary with friendship 70 can spend a Charm on its same-family
rare variant. Every requirement is attainable without activity. Rare artwork
currently uses an earned crown overlay, not a separate full sprite atlas.

Keep a favourite forever with ongoing mastery, or explicitly confirm Archive
and start egg after Legendary. The last archived pet's full snapshot is retained;
normal/rare family registrations and inventory remain. This is never automatic.
The trail Compass is currently a cosmetic collectible; a future cross-family
Wanderer's Compass exception is not implemented.

## Activity rewards and limitations

Real steps, supported active minutes and wheelchair pushes can grant additional
Adventure Energy. Overlapping metrics share one daily milestone watermark.
Care/games grant the same energy and access to the same eight discovery types.
Activity targets are selectable; no streak loss or exercise prompts.

Garmin history only exposes a recent window (normally seven days). Missed
background events beyond that cannot be reconstructed. Uninstalling may remove
Garmin Storage: upgrade the same app, do not uninstall to update.

See [validation](V0_4_VALIDATION.md) for actual simulator / hardware status.
