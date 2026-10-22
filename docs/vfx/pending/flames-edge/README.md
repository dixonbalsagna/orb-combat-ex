# Parked: the flame tongues at a landing do not stand over a fighter (VFX, 2026-10-22, on HEAD 3b5c657e)

The EP (item 4): the flame tongues at a point-blank landing still stand over a fighter's body (homework/dust-puffs/3-closeup, right). One file, render/vfx/explode.gd, no grants.

On a body (surface "fighter") the flames now spring from his two edges (38 to 52 units either side of the contact, instead of within 30 units of its centre), stand behind his plane (14 units back), and are a little lower and smaller (vy x0.55, size x0.7): the contact stays flame, sparks and light, but no tongue stands over his chest or head. Ground and air bursts are as they were. The later waves (the jobs) carry the same edge and depth.

`git apply --check` clean; effects_check passes; validate 0 errors. Side by side before and after on the AI match at tick 1672 (ticks 1650 to 1710), GIF in homework/flames-edge/ (private).

Honest limit: in a clinch the two fighters' edges are close, so the tongues still rise near the pair's head line, behind them; they no longer cover a body. Not a Legal clearance; flash readings not re-run.
