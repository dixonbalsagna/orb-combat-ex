import sys,re,json
t=sys.argv[1]
def flip(path,keys):
    p=t+'/'+path; text=open(p,'rb').read().decode('utf-8'); want=json.loads(text); o=want
    for k in keys: o=o[k]
    if o.get('enabled') is True:
        print('already on',path,keys); return
    o['enabled']=True
    for m in re.compile(r'"enabled"\s*:\s*false').finditer(text):
        c=text[:m.start()]+'"enabled": true'+text[m.end():]
        if json.loads(c)==want:
            open(p,'wb').write(c.encode('utf-8')); print('flipped',path,keys); return
    raise Exception((path,keys))
# QA's floor-on overlay (docs/qa/cloud-reports/2026-10-30-lake-floor.md)
I='data/director/interrupts.json'
flip(I,['brawl','launcher','anywhere'])
flip(I,['brawl','launcher','anywhere','answer'])
flip(I,['water'])
flip(I,['rally'])
flip('data/combat/launch_biome.json',['biome'])
flip('data/biomes/water.json',['surface'])
flip('data/biomes/water.json',['floor'])
