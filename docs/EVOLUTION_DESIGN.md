# TekuTekuBeast (テクテクビースト) evolution design (v0.3)

This is the game-design specification; not all ideas are implemented in the present watch-app prototype.

## Device and gameplay
Native Garmin Enduro 4 Connect IQ watch app. Only steps counted **by the watch** are credited. No companion mobile app and no manually recording workouts. A Garmin background steps event occurs at multiples of 1,000 and the foreground app uses ActivityMonitor history to reconcile missing intermediate steps. No punishment for recovering, resting, or taking a day off.

## Evolution stages (both steps and minimum age required)

| Stage | Total credited steps | Minimum age |
|---|---:|---:|
| Egg | 0 | 0 days |
| Pip / hatchling | 2,000 | 0 days |
| Nimble / juvenile | 20,000 | 2 days |
| Adult | 70,000 | 7 days |
| Champion | 150,000 | 14 days |
| Legendary | 300,000 | 21 days |

After reaching Legendary, the pet keeps the same species, earning one **Mastery level every additional 25,000 credited steps** indefinitely.

## Automatic branching
Family is calculated from up to seven recent days of device step history when Adult is reached; the family stays locked:
1. **Ember**: two days with >= 18,000 new steps each.
2. **Grove**: otherwise, five days with >= 6,000 new steps each.
3. **Tide**: otherwise, three days >= 3,000 and one easy day < 3,000.
4. **Wisp**: any other activity pattern.

No branching choices for ordinary evolution. Branch timing and tie-break priority can be tuned.

## Species tree
- Grove: Mossbit → Thornbuck → Verdant Elder; rare Lumenhart.
- Ember: Cindercub → Pyrolynx → Solflare Dragon; rare Ashen Phoenix.
- Tide: Puddlefin → Currentail → Deepwater Leviathan; rare Moonwater Kirin.
- Wisp: Flicklet → Nocturne → Starweaver; rare Eclipse Eidolon.
- Shared hatchling Pip, shared juvenile Nimble, and Egg.

Each final species will eventually have unique hand-drawn pixel-art silhouettes, idle / happy / sleeping animation frames.

## Rare exceptions (future)
Earn a **Star Charm** by registering your first standard Legendary in a future collection. At least 70 friendship lets you spend one to make a same-family rare Legendary once that future pet is eligible; it is optional and not random monetisation. Collecting all four normal family Legendaries can eventually unlock a single-use Wanderer's Compass permitting one unusual family change on a future pet.

## Lifespan and replayability
- **No permanent death** by default. Rest days do not drain XP or de-evolve pets.
- Keep your favorite Legendary forever; mastery progression has no fixed final level.
- Planned: optional retirement into a collection/museum after Legendary, then start a new Egg with separate per-pet XP and lifetime achievements.
- Pets must not pressure users to exceed safe activity or compromise recovery.

## Daily care
- Every 2,500 new credited steps earns one snack (max 12 held).
- SELECT on Pet adds +2 friendship, up to 3 times per day.
- SELECT on Care consumes a snack to add +5 friendship.
- Friendship max 100; mood is cosmetic, never fatal.

## Limitations & tests
Garmin daily step history includes up to seven days. If background events fail and the app does not open for longer, older steps may not be recovered. Initial current-day steps are treated as baseline. Device testing, battery validation, storage migration, week/date edge cases, and simulator testing are required. This is an uncompiled proof-of-concept.
