"""The street grid (cheap half): cross streets every 10 to 14 fighter heights in downtown and mid-rise, so a fight sees several intersections of the
front and back streets in a frame; blocks are one or two buildings wide.  python mk_grid.py <root> [block_lo block_hi avenue_lo avenue_hi]"""
import sys, json
R = sys.argv[1].rstrip('/') + '/'
blo, bhi, alo, ahi = (float(v) for v in sys.argv[2:6]) if len(sys.argv) >= 6 else (10.0, 14.0, 5.0, 6.0)
p = R + 'data/biomes/settlements.json'
t = open(p, encoding='utf-8', newline='').read()
nl = '\r\n' if '\r\n' in t else '\n'
d = json.loads(t)
for s_ in d['settlements']:
    for x in s_['districts']:
        if x['name'] == 'downtown':
            x['block_bh'] = [blo, bhi]
            x['avenue_bh'] = [alo, ahi]
            x['width_bh'] = [6, 9]
        if x['look'] == 'mid_rise':
            x['block_bh'] = [blo - 1, bhi - 1]
            x['avenue_bh'] = [alo, ahi]
            x['width_bh'] = [5, 8]
for lm in d['landmarks']:
    if lm['key'] == 'bell_tower':
        lm['width_bh'] = 9
    if lm['key'] in ('ledger_hall', 'crown_tower'):
        lm['width_bh'] = 9
out = json.dumps(d, indent=2, ensure_ascii=False) + '\n'
open(p, 'w', encoding='utf-8', newline='').write(out.replace('\n', nl))
print('grid applied: blocks %g to %g, avenues %g to %g' % (blo, bhi, alo, ahi))
