# Compares planet.mjs's points with the GDScript twins'. Usage: python cmp.py <dir>
import struct, sys
d = sys.argv[1]
def load(name):
    pts, sl = {}, None
    for line in open(d + '/' + name, encoding='utf-8'):
        f = line.split()
        if not f: continue
        if f[0] == 'slice': sl = f[1]; continue
        if f[0] == 'slice32': sl = (sl or '') + '/' + f[1]; continue
        pts[(int(f[0]), int(f[1]))] = ([struct.unpack('<d', bytes.fromhex(x))[0] for x in f[2:6]], int(f[6]), f[2:6])
    return pts, sl
js, sj = load('js.txt'); g64, sg = load('gd64.txt'); v3, _ = load('gdv3.txt')
assert len(js) == len(g64) == len(v3) == 1000, (len(js), len(g64), len(v3))
same_bits = sum(1 for k in js if js[k][2] == g64[k][2] and js[k][1] == g64[k][1])
print(f"JS against GDScript, float64 scalars: {same_bits} of {len(js)} points bit-identical (point and elevation bits, biome); full 4,800-column slice hash (float64 / stored as float32) JS {sj}, GDScript {sg}: {'same' if sj == sg else 'DIFFERENT'}")
dp = max(max(abs(a - b) for a, b in zip(js[k][0][:3], v3[k][0][:3])) for k in js)
dh = [abs(js[k][0][3] - v3[k][0][3]) for k in js]
nb = sum(1 for k in js if js[k][1] != v3[k][1])
nh = sum(1 for x in dh if x != 0.0)
R = 153600.0 / (2 * 3.141592653589793)
print(f"World's prototype as it is (Vector3) against float64: {nh} of 1000 elevations differ, the largest by {max(dh):.6f} units (mean {sum(dh)/len(dh):.6f}); the point differs by up to {dp:.3e} of the radius ({dp*R:.6f} units); {nb} biomes differ")
# how near the biome thresholds the 1,000 float64 points come (the margins any error must stay under)
m0 = min(abs(js[k][0][3]) for k in js)
m1 = min(abs(js[k][0][3] - 3200.0) for k in js)
print(f"closest elevation to the sea threshold (0): {m0:.6f} units; to the mountain threshold (3200): {m1:.6f} units")
