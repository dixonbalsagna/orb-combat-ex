import sys,re,json
t=sys.argv[1]
p=t+'/data/combat/launch_biome.json'; text=open(p,'rb').read().decode('utf-8'); want=json.loads(text); want['biome']['enabled']=True
for m in re.compile(r'"enabled"\s*:\s*false').finditer(text):
    c=text[:m.start()]+'"enabled": true'+text[m.end():]
    if json.loads(c)==want:
        open(p,'wb').write(c.encode('utf-8')); print('biome on'); break
else:
    raise Exception('biome')
