import json
from PIL import Image, ImageDraw, ImageFont
d=json.load(open('pk/f13/far_dump.json'))
n=d['n']; depths=d['depths']
col={0:(60,110,170),1:(120,170,90),2:(50,110,60),3:(215,190,110),4:(140,135,130),5:(235,240,245),6:(200,220,235)}
W,H=1200,230*3+60
im=Image.new('RGB',(W,H),(250,250,248)); dr=ImageDraw.Draw(im)
f=ImageFont.load_default()
allh=[v for k in ('exact','coarse','map') for v in d[k]['h']]
lo,hi=min(allh),max(allh)
def y(v,top): return top+150-int((v-lo)/(hi-lo)*130)
dr.text((10,6),"The far land beside a Half ring, 300 columns at three depths: exact read (black), cached map (blue), coarse read (red). Strips: biome of each, same order.",fill=(20,20,20),font=f)
for di,z in enumerate(depths):
    top=30+di*230
    dr.text((10,top),"depth %+.0f units" % z,fill=(20,20,20),font=f)
    def line(k,color,w):
        pts=[(60+int(ci*(W-80)/n), y(d[k]['h'][di*n+ci],top)) for ci in range(n)]
        dr.line(pts,fill=color,width=w)
    line('coarse',(205,60,60),1); line('map',(50,100,210),2); line('exact',(10,10,10),1)
    for si,k in enumerate(('exact','map','coarse')):
        for ci in range(n):
            x0=60+int(ci*(W-80)/n); x1=60+int((ci+1)*(W-80)/n)
            dr.rectangle([x0,top+165+si*18,x1,top+165+si*18+14],fill=col.get(d[k]['b'][di*n+ci],(255,0,255)))
    dr.text((8,top+168),"exact",fill=(0,0,0),font=f); dr.text((8,top+186),"map",fill=(0,0,0),font=f); dr.text((8,top+204),"coarse",fill=(0,0,0),font=f)
im.save('far_compare.png')
print(im.size, lo, hi)
