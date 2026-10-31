# ADR 0012: The arena swings, and the game scales from a performance mode to maximum graphics

- Status: accepted (Orb, 2026-10-31). The route is not yet chosen; see docs/world/ring-any-angle/research.md.
- Context: Orb asked for the fight's bearing on the planet to change dynamically. After playing research/ring-any-angle/proto.html they picked the turntable, where the world visibly swings round the fighters. After playing proto v2, including at 30 fps and on the coarse planet map, they said not to tie the whole game to old laptops. Their words are in docs/ep/vision.md.

## Decision

1. **The arena swings.** The choreographer and camera decide when, from everything happening in the fight, with variety. The ribbon stays only as a fallback.
2. **Old laptops are the bottom of a range, not the ceiling.** This replaces ADR 0011's item 3 as the budget rule. The game must play on an old laptop in a performance mode, and that mode doesn't set the look for anyone else. Settings are granular, up to a maximum graphics version.
3. **The sim is shared.** A setting may change what is drawn, never what the sim computes, so players on different settings can still play each other and replays stay valid.
4. **Mobile stays parked.** ADR 0011's other items stand.

## Consequences

- Performance's budgets become one set per quality level.
- The planet map, the near ground and the renderer are each researched as a range.
- A look change at any level still goes through the look gate (ADR 0010).
