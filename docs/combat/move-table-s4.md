# Spike S4: the move table, counted and priced

Combat, 2026-11-14, sprint A1 wave 2 (A-COMBAT-04 sizing; supports A-CONTROLS-06). **A spike: nothing lands.** Orb's answer: "FULL TABLE ON BETA, KEEP ITERATING WHAT WE HAVE." The Alpha bar: no dead cell; the martial and energy rows complete and distinct for each fighter; the LB, LT and RT rows may share where the design says so, written down.

## What I tried

- **Controls' coverage probe on the build Orb played,** the kept 9 November build (commit 6a30b4c9), on a copy of its tree. My run reproduces Controls' reading line for line: per fighter, 101 cells; 52 or 53 own outcomes, 32 repeats, 11 or 12 the same move with a side effect, 2 refused, 3 silent.
- **Two more readings.** With the fighter's energy full: no cell changed, so energy isn't hiding anything. At 100 units: invalid, as the match opens in a clinch.
- **15 cells the file lacked,** read the same way: A, LT and LB in reach (a brawl started first), the air, charging, the dodge and the snare.
- **Every cell marked** in `pending/move-table/coverage_cells.json`: own outcome, by design (a design page already says so: the probe prints it), proposed (a share I'd write down, which Game Design has to rule on), a gap before Alpha, or a probe gap. Cell by cell with the reading: `move-table-s4-6a30b4c9.txt`.

## The count, per fighter

| | Of Controls' 101 | Of my 15 |
| :--- | ---: | ---: |
| Own outcome | 52 (53 for Grist) | 7 |
| By design, written | 23 | |
| Proposed share, for Game Design to write | 16 | 4 |
| **Gap before Alpha** | **9 (8 for Grist)** | 4 |
| Probe can't read it yet | 1 | |

**The only dead cells are LB + A,** silent all three ways and in reach too. The design's LB + A is the reversal after a block and the deflect at range, so with nothing coming it does nothing and says nothing.

**The repeats are mostly fine.** The LB, LT and RT rows repeat the plain row, and the design pages already say that for most of them. The 16 proposed shares fill the rest (LB + B as the push, LT + B and LT + A as plain, X + Y as Y), so they only need writing down.

## What Alpha needs

| | Work | Whose | Size |
| :--- | :--- | :--- | ---: |
| A1 | **LB + A, the counter stance:** he sets for half a second, and a blow in it is reversed. An outcome every time, using the reversal that exists | Encounter, Animation (the reversal's pose), Controls (cue) | 1.5M |
| A2 | Loupe's held Y: his charged medium has no pieces of its own | Combat (data; needs a grant on `data/combat/`) | 0.25M |
| A3 | Held A in reach: the snatch throw. The catch turns straight into the grapple's throw, aimed by the stick | Encounter | 1M |
| A4 | RB + held X: the stream, as the energy design says. Today it fires one bolt | Encounter, VFX | 1.2M |
| A5 | RB + mashed B: a Driver every 24 ticks, as designed. Check first: it may be its reload | Encounter | 0.25M |
| A6 | RB + held A: the held mine aims where you push | Encounter | 1M |
| A7 | LT + X and LT + Y in reach: the step strike and the circle. Both are built, but off in Orb's build | Encounter, Combat (the stance looks) | 1.5M |
| A8 | The 20 proposed shares written into the design page | Game Design, Combat | 0.25M |
| A9 | The probe: the four in-reach and air layers, landing the fighter first, a CI step | Controls, Tools | 0.5M |
| | QA's re-reads (the masher row, the worth band) | QA | 1M |
| | **Total, at about 1M a session with checks** | | **8.5M; 11M with a 30% margin** |

RT + right stick, the signature (2 cells, refused today), is A3's signature input and counted on that row, not here.

## The price

| | Tokens | Size class |
| :--- | ---: | :--- |
| **The smaller table, for Alpha** | About 8.5M, 11M with margin | **XL,** not the L the resize hoped for: most of the gaps are mechanics in the director, not data. Still under the 13M the plan carries |
| **The full table, at Beta** (55 cells a fighter, two fighters) | About 58M, range 45M to 70M | **Far past XL.** At the plan's 35M a week, about a week and a half on its own |

**Where the full table's tokens go,** for both fighters:
- each fighter's three specials and ultimate on RT, about 16M;
- the energy kits (the grab thrown and held, the mines, trap and snare), about 14M;
- LT's piloted moves, tackle and terrain art, about 11M;
- LB's parry, deflect and counter art, about 9M;
- A's pick-up and dive grab, the stance looks, and QA, about 9M.

That's content: new pieces, effects and checks for each move.

## For the probe (Controls, through the EP)

- **The fighter starts above the floor,** so the grounded down flick is never read. Both down cells read the air version.
- **The probe joins with A,** which opens a taunt in every match before the press. The baseline hides it, but a button that does nothing would be cleaner.
- **`by_design` only prints on an empty cell.** All 23 of mine are repeats, so the probe should print it on repeat lines too, or X-03 can't count them.
- **Range decides half the table.** The grab, the step strike and the circle only happen in reach. My four layers (`brawl`, `brawlLT`, `brawlLB`, `air`) are one line in the probe's baseline list.

## The question for Orb

**LB + A does nothing today: hold guard and press A, and nothing happens. My pick: it sets a counter. If he hits you in the next half second, you throw him off; if not, you've wasted a moment. Is that what you'd want from that button?**

My brief has no amendments section; I read it to its end.
