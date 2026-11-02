# ADR 0013: No target machine during development. Minimum specs are set before launch

- Status: accepted (Orb, 2026-11-01). Replaces ADR 0012's item 2 and ADR 0011's item 3.
- Context: Orb's first answers listed "old laptops" as minimum hardware (2026-09-28). The team turned that into a budget machine. No such laptop is owned or tested: the "old laptop" figures are Orb's PC slowed by a multiplier. On 2026-10-31 Orb said not to tie the game to old laptops. ADR 0012 still required the game to play on one, and reports kept naming it as unmeasured. On 2026-11-01 Orb asked that development stop being held to it. Orb's words are in docs/ep/vision.md.

## Decision

1. **No machine is a target or a gate during development.** Nothing is cut, delayed or reported as failing against an old laptop or a slowed-down stand-in for one.
2. **Orb's PC and the GTX 1080 PC are the real machines we read.** A slowdown multiplier may help find a hot spot, but its number isn't a verdict.
3. **Minimum specs are measured and set before launch,** from what the game then needs. Whether an old laptop fits is answered then.
4. **Settings stay.** The range from a performance mode to maximum graphics stands, as does ADR 0012's rule that a setting changes only what is drawn.
5. **World sizes are the intended way down** for weak machines (Orb: a tiny world would give the least powerful laptop a way to play), once they exist.

## Consequences

- Performance's budgets stop naming an old laptop; frame spikes Orb can feel stay real work.
- Earlier documents keep their figures as history, read as "Orb's PC, slowed".
