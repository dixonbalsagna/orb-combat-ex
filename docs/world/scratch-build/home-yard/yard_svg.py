import json
d=json.load(open('pk/y33/yard_dump.json'))
W,H=1200,520
X0,X1=-2400,2400
gy=360
sx=lambda x:(x-X0)/(X1-X0)*(W-60)+30
prof=d['prof']
base0=prof[len(prof)//2][1]
sy=lambda h:gy-h*0.12   # units to px
shade={0.0:'#9a8f7e',1.0:'#7d746a',2.0:'#aaa093',3.0:'#bbb2a5'}
out=[f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" font-family="sans-serif" font-size="13">',
f'<rect width="{W}" height="{H}" fill="#f1e3c8"/>',
f'<text x="30" y="28" font-size="17" fill="#2b2218">The Breaking Yard (the Cyborg\'s home class), as generated: front-street elevation of the town on planet 5, place 12</text>',
f'<text x="30" y="48" fill="#5a4a38">{d["n"]} buildings, {d["down"]} down at the start, {int(d["pop"])} people. Solid: standing. Hatched low mounds: fallen (the heap they left). Rows: back (pale) to front street (dark).</text>']
# ground
pts=' '.join(f'{sx(x):.1f},{sy(h-base0)+0:.1f}' for x,h in prof)
out.append(f'<polygon points="{sx(prof[0][0]):.1f},{gy+90} {pts} {sx(prof[-1][0]):.1f},{gy+90}" fill="#d8c18f" stroke="#a88f5c"/>')
for row in (3.0,2.0,1.0,0.0):
    for b in sorted([b for b in d['b'] if b['row']==row],key=lambda e:-e['z']):
        x0=sx(b['x']-b['w']/2); w=b['w']/(X1-X0)*(W-60)
        gh=0
        if b['alive']:
            h=b['h']*0.12
            col=shade.get(row,'#888')
            out.append(f'<rect x="{x0:.1f}" y="{gy-h-4:.1f}" width="{w:.1f}" height="{h:.1f}" fill="{col}" stroke="#4a4036"/>')
            if b['shape']=='crane':
                out.append(f'<line x1="{x0-w*1.8:.1f}" y1="{gy-h-4:.1f}" x2="{x0+w*2.2:.1f}" y2="{gy-h-4:.1f}" stroke="#4a4036" stroke-width="3"/>')
        else:
            h=max(8,b['h']*0.035)
            out.append(f'<path d="M{x0-w*0.2:.1f},{gy-4} Q{x0+w/2:.1f},{gy-4-h*2:.1f} {x0+w*1.2:.1f},{gy-4}" fill="#b8a98f" stroke="#4a4036" stroke-dasharray="4 3"/>')
for i,fx in enumerate(d['fx']):
    out.append(f'<circle cx="{sx(fx):.1f}" cy="{gy-18}" r="8" fill="{"#2f6fb5" if i==0 else "#b53a3a"}"/>')
out.append(f'<text x="{sx(d["fx"][0])-34:.1f}" y="{gy+22}" fill="#2b2218">the fighters start here</text>')
out.append(f'<line x1="30" y1="{gy+60}" x2="{W-30}" y2="{gy+60}" stroke="#2b2218"/>')
for lab,xa,xb in [('bays + stack',-2000,-1280),('gantries',-1280,-600),('hulk field',-600,600),('gantries',600,1400),('slag end + stack',1400,2000)]:
    out.append(f'<line x1="{sx(xa):.1f}" y1="{gy+55}" x2="{sx(xa):.1f}" y2="{gy+65}" stroke="#2b2218"/>')
    out.append(f'<text x="{(sx(xa)+sx(xb))/2-40:.1f}" y="{gy+82}" fill="#2b2218">{lab}</text>')
out.append('</svg>')
open('home-yard-elevation.svg','w',encoding='utf-8').write('\n'.join(out))
print('ok')
