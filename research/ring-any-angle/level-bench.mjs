// Each quality level of proto v2 on this PC's GPUs: wall clock of a batch of draws ended by a one-pixel readPixels, best of 5 batches, in three poses. Through Tools' launcher.
// A real GPU reading of a bare spike, not of the game: no sim, no real shaders. It ranks the levels and shows what scales.
//   node research/ring-any-angle/level-bench.mjs [--igpu]
import { launchBrowser, browserExe, Cdp } from '../../tools/machine/browser.mjs';
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
import { pathToFileURL } from 'node:url';
import { resolve } from 'node:path';
const igpu = process.argv.includes('--igpu'), url = pathToFileURL(resolve('research/ring-any-angle/proto-v2.html')).href;
const W = 1280, H = 720;
const b = await launchBrowser({ exe: browserExe('chrome'), session: 'research', purpose: 'levelbench', timeoutS: 560, cpuPercent: 0, priority: 'belownormal', headless: false, log: () => {},
  flags: ['--disable-gpu-vsync', '--disable-frame-rate-limit', '--disable-background-timer-throttling', '--disable-renderer-backgrounding', '--disable-backgrounding-occluded-windows', `--window-size=${W + 20},${H + 140}`, '--window-position=0,0', ...(igpu ? ['--force_low_power_gpu'] : [])] });
let code = 0;
try {
  const page = await Cdp.open(b.target.webSocketDebuggerUrl);
  await page.send('Page.enable'); await page.send('Runtime.enable');
  await page.send('Emulation.setDeviceMetricsOverride', { width: W, height: H, deviceScaleFactor: 1, mobile: false });
  await page.send('Page.navigate', { url });
  for (let i = 0; i < 60; i++) { await sleep(1000); if (await page.eval('window.__ok>=1').catch(() => false)) break; }
  const js = `(function(){if(window.__err)return 'ERR '+window.__err;window.__hold=1;var gl=RT.gl,P=RT.P,K=RT.keys,e=gl.getExtension('WEBGL_debug_renderer_info'),out={gpu:e?gl.getParameter(e.UNMASKED_RENDERER_WEBGL):'?',levels:[]};RT.human(true);var px=new Uint8Array(4);
    function batch(n){var best=1e9;for(var r=0;r<5;r++){var t=performance.now();for(var i=0;i<n;i++){RT.draw();gl.readPixels(0,0,1,1,gl.RGBA,gl.UNSIGNED_BYTE,px);}best=Math.min(best,(performance.now()-t)/n);}return +best.toFixed(2);}
    for(var L=0;L<5;L++){RT.setLevel(L);P.fps30=0;P.jolts=0;P.quiet=9999;P.fires='manual';RT.reset();RT.step(40);var row={name:RT.LEVELS[L].name,rest:batch(6),tiles:RT.tiles(),trees:RT.trees()*P.trees};K.KeyD=true;K.ShiftLeft=true;RT.step(300);row.flat=batch(6);row.tilesFlat=RT.tiles();K.KeyD=false;K.ShiftLeft=false;RT.step(120);var t1=performance.now();RT.step(600);row.stepUs=+((performance.now()-t1)/600*1000).toFixed(1);RT.draw();row.w=gl.drawingBufferWidth;row.h=gl.drawingBufferHeight;out.levels.push(row);}
    // one feature at a time, from Standard at a fixed 1280x720, in the same pose
    out.features={};function pose(){RT.setLevel(2);P.fps30=0;P.jolts=0;P.quiet=9999;P.fires='manual';P.scale=1;}
    var F={base:{},noPaint:{detail:0},noTrees:{trees:0},noWindows:{windows:0},noClouds:{clouds:0},noCloudShadow:{cshadow:0},noSea:{sea:0},near64:{view:64},near256:{view:256},near512:{view:512},mesh150:{tmax:3},mesh37:{tmax:5},mesh19:{tmax:6},far128:{far:128},relief1:{gen:1},relief2:{gen:2},relief2mesh19:{gen:2,tmax:6},shadow8:{tshadow:8},shadow16:{tshadow:16},trees96:{trees:96,treeR:16000},trees320:{trees:320,treeR:22000},scale075:{scale:.75},scale15:{scale:1.5},scale2:{scale:2}};
    function med(a){a=a.slice().sort(function(x,y){return x-y;});return a[a.length>>1];}function one(k){pose();for(var q in F[k])P[q]=F[k][q];RT.buildMap();RT.reset();RT.step(40);return batch(4);}Object.keys(F).forEach(function(k){if(k==='base')return;var ds=[],ms=[],bs=[];for(var pass=0;pass<3;pass++){var b0=one('base'),m=one(k),b1=one('base');bs.push((b0+b1)/2);ms.push(m);ds.push(m-(b0+b1)/2);}out.features[k]={ms:+med(ms).toFixed(2),base:+med(bs).toFixed(2),delta:+med(ds).toFixed(2),spread:+(Math.max.apply(0,ds)-Math.min.apply(0,ds)).toFixed(2)};});
    out.err=gl.getError();return JSON.stringify(out);})()`;
  console.log(await page.eval(js));
} catch (e) { console.error(String(e)); code = 1; } finally { await b.close(); }
process.exit(code);
