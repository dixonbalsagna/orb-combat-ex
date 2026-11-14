// How close Orb's LT presses and face presses are (docs/controls/lt-take-back-claw.md): from black box files, the offset from each LT (dodge) edge to every face edge (light, heavy, sig, context) in the replay, against the chance rate. node docs/controls/clips/read-orb-lt-face.cjs <file.json> [more files]. Counts only; the files stay private.
const fs=require("fs");
const files=process.argv.slice(2);
const names={dodge:25,light:30,heavy:31,sig:32,context:33};
const bit=(r,b)=>{const p=BigInt(r[2])+(BigInt(r[3])<<32n);return Number((p>>BigInt(b))&1n)};
let LT=0,totalTicks=0,facesN=0;const all={};const first={};const hit={};
for(const f of files){
 const d=JSON.parse(fs.readFileSync(f,"utf8"));const R=d.replay.inputs.filter(r=>r[1]===0);
 const ev={};for(const k in names)ev[k]=[];const prev={};for(const k in names)prev[k]=0;
 for(const r of R){for(const k in names){const b=bit(r,names[k]);if(b&&!prev[k])ev[k].push(r[0]);prev[k]=b}}
 const faces=[...ev.light,...ev.heavy,...ev.sig,...ev.context].sort((a,b)=>a-b);
 totalTicks+=d.replay.ticks;facesN+=faces.length;
 for(const t of ev.dodge){LT++;
  let nextAfter=null;
  for(const ft of faces){const o=ft-t;if(o>=-12&&o<=40){all[o]=(all[o]||0)+1}
   if(o>=0&&nextAfter===null)nextAfter=o;}
  if(nextAfter!==null)first[nextAfter]=(first[nextAfter]||0)+1;
 }
}
const rate=facesN/totalTicks;
console.log("LT edges",LT,"face edges",facesN,"ticks",totalTicks,"face edges per tick",rate.toFixed(4));
// baseline from offsets 20..40
let base=0;for(let o=20;o<=40;o++)base+=(all[o]||0);const bpt=base/21/LT;
console.log("baseline faces per LT per offset tick (offsets 20..40):",bpt.toFixed(3),"(overall rate",rate.toFixed(3),")");
console.log("offset: faces per LT edge at that offset (baseline "+bpt.toFixed(3)+")");
let line="";for(let o=-8;o<=12;o++){line+=o+":"+((all[o]||0)/LT).toFixed(2)+" "}console.log(line);
// cumulative converted share for LT-first windows: share of LT edges with a face edge in [0,W]
for(const W of [0,1,2,3,4,6,8]){let n=0;for(const k in first)if(+k<=W)n+=first[k];const exp=1-Math.exp(-bpt*(W+1));console.log("W="+W+": LT taps with a face press in 0.."+W+" ticks after: "+n+" of "+LT+" ("+(100*n/LT).toFixed(0)+"%); chance expectation "+(100*exp).toFixed(0)+"%")}
