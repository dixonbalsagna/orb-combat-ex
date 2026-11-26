# The pump: a merged zoom-out run at the cap followed within 0.6 s by a zoom-in run (opening/split). usage: python zj_pump.py <log>...
import re,sys,collections
for f in sys.argv[1:]:
    ev=collections.defaultdict(list)
    for l in open(f,encoding='utf-8',errors='replace'):
        m=re.match(r'ZJ real match (\d+) .* t=([\d.]+) pane (\d) dz (-?[\d.]+) ddz ([\d.]+) z ([\d.]+) mode (\S+)',l)
        if m: ev[m.group(1)].append((float(m.group(2)),int(m.group(3)),float(m.group(4)),float(m.group(6)),m.group(7)))
    tot_cap=0; pumps=[]; secs=0
    for seed,L in ev.items():
        p0=[e for e in L if e[1]==0]
        tot_cap+=sum(1 for e in L if abs(e[2])>=0.039)
        secs=max(secs,0)
        # runs of zoom-out (dz<0) in merged, then zoom-in (dz>0) within 0.6 s
        i=0
        while i<len(p0):
            if p0[i][2]<-0.015 and p0[i][4]=='merged':
                j=i
                while j+1<len(p0) and p0[j+1][2]<-0.015 and p0[j+1][0]-p0[j][0]<0.05: j+=1
                zfrom,zto=p0[i][3]/__import__('math').exp(p0[i][2]),p0[j][3]
                k=j+1
                while k<len(p0) and p0[k][0]-p0[j][0]<0.6 and p0[k][2]<=0.015: k+=1
                if k<len(p0) and p0[k][0]-p0[j][0]<0.6 and p0[k][2]>0.015:
                    m=k
                    while m+1<len(p0) and p0[m+1][2]>0.015 and p0[m+1][0]-p0[m][0]<0.05: m+=1
                    pumps.append((seed,round(p0[i][0],2),round(zfrom,2),round(zto,2),round(p0[m][3],2),p0[k][4]))
                    i=m
                else:
                    i=j
            i+=1
    print(f, 'cap ticks', tot_cap, 'pumps', len(pumps))
    big=[p for p in pumps if p[2]/p[3]>=1.5]
    print('  pumps with a zoom-out of 1.5x or more:', len(big), big[:8])
