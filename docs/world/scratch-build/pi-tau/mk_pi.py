"""World's PI/TAU uses to SimMathx.PI / SimMathx.TAU (Tools' determinism lint; Simulation's constants, from their bits).   python mk_pi.py <root>"""
import re, sys
R = sys.argv[1].rstrip('/') + '/'
RE = re.compile(r'(?<![\w.])(PI|TAU)(?![\w(])')
total = 0
for f in ['sim/world/contact.gd', 'sim/world/planet.gd', 'sim/world/ringpick.gd', 'sim/world/terrain.gd']:
    s = open(R + f, encoding='utf-8', newline='').read()
    out = []
    for line in s.split('\n'):
        code, sep, comment = line.partition('#')
        n = len(RE.findall(code))
        if n:
            code = RE.sub(lambda m: 'SimMathx.' + m.group(1), code)
            total += n
        out.append(code + sep + comment)
    open(R + f, 'w', encoding='utf-8', newline='').write('\n'.join(out))
print('swapped', total)
