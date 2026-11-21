# Parked: the beam struggle's end as an event, for the shockwave and the crater

Encounter, 2026-11-02, for Orb's beam-clash note: the biggest shockwave, and a crater at the meeting point. VFX draws it (`docs/vfx/clash-shockwave.md`) and World digs it, both from this event. **Behind `data/director/interrupts.json` `beamStruggle.endEvent`, off.** Off, nothing new is emitted.

**Apply on the stack after `../ratchet-roster/`** (it's cut with one line of context, so it doesn't depend on the 2v2 parks): `git -c core.autocrlf=false -c core.eol=lf apply clash-end.diff`.

**`Clash.mid` is on main already.** The beam struggle landed: `DirBeam` writes `S.game.clash.mid` as the struggle starts and on every surge. VFX's notes that it's "parked" are out of date.

## The event: the cue `beam_clash_end`, once a struggle, as it resolves

| Field | |
| :--- | :--- |
| `text` | The outcome: **`win`** (the point reached the loser, or the struggle ran out on his side), **`break`** (he let go), **`draw`** (they detonated in the middle) |
| `x`, `y`, `z` | **The meeting point in the world:** along the line from A's hands to D's, at the point |
| `amount` | The point itself, 0 at A's hands to 1 at D's |
| `energy` | The clash's energy: both beams' damage at the pair's mean power tier, `2 × 260 × sigDamageMul × (A.tier + D.tier) / 2`. A magnitude for the shockwave's size and the crater's |
| `winner`, `loser` | Their slots; -1 at a draw |
| `n` | The surges it took, both sides |
| `source` | The ending as `beam_end` names it: `time`, `overwhelmed`, `letgo` or `detonate` (World's numbers tell time from overwhelm) |

**World's struggle-meeting-point call goes in the same hook,** `DirBeam._clashEnd`, ahead of this switch so it runs on its own: one line, `WorldCraters.struggleMeet(S, mid, how, [A.tier, D.tier])`. The hook runs once for any ending.
| `actor` | The winner, or A at a draw |

It comes on the same tick as the struggle's own `beam_end` cue, which is unchanged.

## Read

`struggle_read --mode=ai`, 3 matches, with it on: 6 struggles, **4 `win` and 2 `draw`, one for one with `beam_end`'s 4 `time` and 2 `detonate`.** A sample: the point at x 97,012, height 302, energy 312, 16 surges, winner slot 0.

## Grants

| Whose | What |
| :--- | :--- |
| Tools' | the switch: `{ id: 'clashEnd', file: 'data/director/interrupts.json', path: ['beamStruggle', 'endEvent'], from: false, to: true, needs: [], optional: true }` |
| VFX's and World's | reading the cue: VFX's shockwave and World's crater, at `x, y, z`, scaled by `energy` |
