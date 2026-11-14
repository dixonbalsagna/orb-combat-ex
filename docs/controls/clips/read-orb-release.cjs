// Reads a black-box first-play file for pump speed, pass-throughs of the centre and the direction of a release (docs/controls/stoke-and-chin.md).
// node docs/controls/clips/read-orb-release.cjs <file.json>. Prints counts only (nothing of the samples is written); the file stays private. Reads the file as the cwd-relative path given.
const fs=require("fs");
const d=JSON.parse(fs.readFileSync(process.argv[2],"utf8"));
const S0=d.rawRightStick.samples;
const mag=a=>Math.hypot(a[2],a[3]);const ang=a=>Math.atan2(-a[3],a[2])*180/Math.PI;const wrap=x=>((x+540)%360)-180;
const q=(a,p)=>{a=a.filter(v=>v!=null).sort((x,y)=>x-y);return a.length?a[Math.min(a.length-1,Math.floor(p*a.length))]:null};
const cmean=arr=>{let sx=0,sy=0;for(const a of arr){sx+=Math.cos(a*Math.PI/180);sy+=Math.sin(a*Math.PI/180)}return Math.atan2(sy,sx)*180/Math.PI};
const quad=a=>{const x=Math.cos(a*Math.PI/180),y=Math.sin(a*Math.PI/180);return Math.abs(y)>=Math.abs(x)?(y>0?"U":"D"):(x>0?"R":"L")};
// per-tick samples
const S=[];for(const a of S0){if(S.length&&S[S.length-1][0]===a[0])S[S.length-1]=a;else S.push(a)}
function holdsOf(S){const H=[];let cur=null,down=false;for(let i=0;i<S.length;i++){const a=S[i],m=mag(a);const was=down;if(!down&&m>=0.70)down=true;else if(down&&m<0.51)down=false;
 if(down&&!was)cur={pts:[a],i0:i};else if(down&&cur)cur.pts.push(a);else if(!down&&was&&cur){cur.after=a;cur.i1=i;H.push(cur);cur=null}}return H}
const H=holdsOf(S);console.log("holds (per-tick samples)",H.length);
// reversal and pump numbers
const hs=holdsOf(S0);
const periods=[],gaps=[],revgaps=[];for(let i=1;i<hs.length;i++){const a=hs[i-1],b=hs[i];periods.push(b.pts[0][1]-a.pts[0][1]);const g=b.pts[0][1]-a.after[1];gaps.push(g);const da=Math.abs(wrap(ang(b.pts[0])-ang(a.pts[a.pts.length-1])));if(da>100)revgaps.push([g,da.toFixed(0)])}
console.log("start-to-start period ms of consecutive holds: min",Math.min(...periods),"p10",q(periods,.1),"p50",q(periods,.5));
console.log("gaps hold-end to next start ms: min",Math.min(...gaps),"p10",q(gaps,.1),"; reversals >100deg:",JSON.stringify(revgaps));
// runs of holds with period<400ms
let runs=[],run=1;for(let i=0;i<periods.length;i++){if(periods[i]<400)run++;else{if(run>=2)runs.push(run);run=1}}if(run>=2)runs.push(run);console.log("runs of pushes each <400 ms apart (lengths):",JSON.stringify(runs));
// jumps without passing under OFF: consecutive samples, both mag>=0.5, angle change >120
let jumps=0,jumps2=0;for(let i=1;i<S0.length;i++){const a=S0[i-1],b=S0[i];if(b[1]-a[1]<40&&mag(a)>=0.5&&mag(b)>=0.5&&Math.abs(wrap(ang(b)-ang(a)))>120)jumps++}
console.log("sample pairs that flip >120deg while both above 0.5 (a pass through the centre between frames):",jumps);
// per-sample dwell: time from hold end to next start for the single reversal
// === release direction ===
const rows=[];for(const h of H){const rim=q(h.pts.map(mag),.8);const idx=h.pts.map((a,i)=>mag(a)>=.85*rim?i:-1).filter(i=>i>=2);if(idx.length<5)continue;
 const ref=cmean(idx.map(i=>ang(h.pts[i])));
 const last1=ang(h.pts[idx[idx.length-1]]);const last3=cmean(idx.slice(-3).map(i=>ang(h.pts[i])));
 const lastDown=ang(h.pts[h.pts.length-1]);const underOff=ang(h.after);
 // direction change over the last 4 rim ticks vs the 4 before
 const tailA=cmean(idx.slice(-4).map(i=>ang(h.pts[i])));const tailB=idx.length>=8?cmean(idx.slice(-8,-4).map(i=>ang(h.pts[i]))):null;
 // magnitude fall profile: last 3 down samples' magnitudes and angle error
 const tail=h.pts.slice(-3).map(a=>[mag(a).toFixed(2),Math.abs(wrap(ang(a)-ref)).toFixed(0)]);
 rows.push({ref,e:{last1:Math.abs(wrap(last1-ref)),last3:Math.abs(wrap(last3-ref)),lastDown:Math.abs(wrap(lastDown-ref)),underOff:Math.abs(wrap(underOff-ref))},q:{last1:quad(last1)!==quad(ref),last3:quad(last3)!==quad(ref),lastDown:quad(lastDown)!==quad(ref),underOff:quad(underOff)!==quad(ref)},late:tailB==null?null:Math.abs(wrap(tailA-tailB)),tail,diag:(()=>{const a=((ref%360)+360)%360;const m=a%90;return Math.min(Math.abs(m-45))})()});}
console.log("holds with a rim:",rows.length);
for(const k of["last1","last3","lastDown","underOff"]){const es=rows.map(r=>r.e[k]);console.log(k.padEnd(9),"error vs rim mean deg p50/p90/max",[.5,.9,1].map(p=>q(es,p).toFixed(1)).join("/")," | lands in a different 90deg quadrant:",rows.filter(r=>r.q[k]).length,"of",rows.length)}
const late=rows.map(r=>r.late).filter(v=>v!=null);console.log("direction change, last 4 rim ticks vs the 4 before, deg p50/p90/max:",[.5,.9,1].map(p=>q(late,p).toFixed(1)).join("/"),"; holds with a change >20deg:",late.filter(v=>v>20).length,"of",late.length,">45:",late.filter(v=>v>45).length);
// distance of the rim direction from the nearest quadrant boundary (diagonal), degrees
const dg=rows.map(r=>r.diag);console.log("distance of the rim direction from the nearest 45deg boundary: min",Math.min(...dg).toFixed(1),"holds within 10deg of a boundary:",dg.filter(v=>v<10).length,"within 20:",dg.filter(v=>v<20).length);
// the worst last-down cases
rows.filter(r=>r.e.lastDown>30).forEach(r=>console.log("  last-down error",r.e.lastDown.toFixed(0),"tail [mag,err]:",JSON.stringify(r.tail)));
// the magnitude fall: how many samples between rim and under OFF
const fall=H.map(h=>{const rim=q(h.pts.map(mag),.8);let k=0;for(let i=h.pts.length-1;i>=0;i--){if(mag(h.pts[i])>=.85*rim)break;k++}return k});
const fh=Array(5).fill(0);fall.forEach(v=>fh[Math.min(4,v)]++);console.log("ticks between the last rim tick and the fall under OFF, counts for 0/1/2/3/4+:",fh.join(" "));
