"""Runs Controls' Python model of the right-stick recognizer (docs/controls/right-stick-model.py) over recorded traces.
Used by tools/capture/right-stick-analyse.mjs (--engine python); a GDScript runner speaks the same two JSON files when the recognizer exists in the game.

  python right-stick-run.py <in.json> <out.json> [--model <path to right-stick-model.py>]

in.json   { "traces": [ { "id": "...", "ticks": [[x, y], ...] }, ... ], "rises": [2, 3, 4, 5] }   x right, y UP, one pair per 1/60 s tick, already rescaled to -1..1
out.json  { "model": {...constants...}, "results": [ { "id": "...", "rise": 3, "events": [ [name, detail, tick], ... ] }, ... ] }
          name is "flick" or "hold" (detail: the sector 0..7, 0 = right, anticlockwise) or "pattern" (detail: "pump", "zigzag", "quarter", "half" or "full")
"""
import importlib.util, json, os, sys

args = sys.argv[1:]
model_path = None
if '--model' in args:
    i = args.index('--model')
    model_path = args[i + 1]
    del args[i:i + 2]
if len(args) != 2:
    sys.exit(__doc__)
if model_path is None:
    model_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'docs', 'controls', 'right-stick-model.py')
spec = importlib.util.spec_from_file_location('right_stick_model', model_path)
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)

data = json.load(open(args[0], encoding='utf-8'))
rises = data.get('rises') or [m.FLICK_RISE]
results = []
for tr in data['traces']:
    for rise in rises:
        rec = m.Rec(True)
        rec.flick_rise = rise
        events = []
        tick = 0
        for x, y in tr['ticks']:
            for e in rec.step(float(x), float(y)):
                events.append([e[0], e[1], tick])
            tick += 1
        for _ in range(14):        # the model's own tail: let a pattern close
            for e in rec.step(0.0, 0.0):
                events.append([e[0], e[1], tick])
            tick += 1
        results.append({'id': tr['id'], 'rise': rise, 'events': events})
out = {'model': {'DZ': m.DZ, 'ON': m.ON, 'OFF': m.OFF, 'FLICK_RISE': m.FLICK_RISE, 'HOLD_T': m.HOLD_T, 'GAP': m.GAP, 'REST_CLOSE': m.REST_CLOSE}, 'results': results}
json.dump(out, open(args[1], 'w', encoding='utf-8'))
