#!/usr/bin/env node
// How long a page of the web build waits on each shader program's link, which is where the graphics driver's compile blocks,
// and what each program is. Before the page's scripts run it wraps attachShader (a program's shaders), linkProgram (when)
// and getProgramParameter(LINK_STATUS) (the wait). For each program it keeps the wait in ms, when it came, the first of
// the markers its fragment (or vertex) GLSL holds, and Godot's pass defines (MODE_RENDER_DEPTH, USE_INSTANCING,
// DISABLE_FOG ...), so the engine's default specializations can be told from what the game draws (docs/rendering/boot.md,
// "Where the rest of the compile goes").
// Headless Chrome only through Tools' guarded launcher (tools/machine/browser.mjs: below-normal priority, a core mask, a time limit,
// a profile named for the session, MERIDIAN_SESSION or 'rendering'); never start a browser another way. One capture at a time. Node 24
// built-ins only. Owner: Rendering and Technical Art. No Godot window.
//
//   node docs/rendering/tools/linktime.mjs <site dir (holds play/)> <out.json> [seconds 90] [marker,marker] [cpu throttle 1]
//   prints the total wait and every program over 150 ms, longest first
import { writeFileSync } from 'node:fs';
import { pathToFileURL, fileURLToPath } from 'node:url';
import { join } from 'node:path';
const [site, out, secS, mk, thrS] = process.argv.slice(2);
const repo = fileURLToPath(new URL('../../../', import.meta.url));   // the project root (this file is docs/rendering/tools/)

const SECS = Number(secS || 90), THR = Number(thrS || 1);
const MARKERS = (mk || 'win_hash,fore_cap3').split(',');
const { Cdp, launchBrowser, serve, browserExe } = await import(pathToFileURL(join(repo, 'tools/machine/browser.mjs')).href);
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const server = await serve(site);
const url = `http://127.0.0.1:${server.address().port}/play/index.html`;
let b = null;
const res = { url, markers: MARKERS, throttle: THR };
try {
  b = await launchBrowser({ exe: browserExe(), session: process.env.MERIDIAN_SESSION || 'rendering', purpose: 'linktime', timeoutS: SECS + 120, log: () => {},
    flags: ['--window-size=1280,720', '--disable-background-timer-throttling', '--disable-renderer-backgrounding', '--disable-backgrounding-occluded-windows'] });
  const page = await Cdp.open(b.target.webSocketDebuggerUrl);
  await page.send('Page.enable');
  await page.send('Emulation.setDeviceMetricsOverride', { width: 1280, height: 720, deviceScaleFactor: 1, mobile: false });
  if (THR > 1) await page.send('Emulation.setCPUThrottlingRate', { rate: THR });
  await page.send('Page.addScriptToEvaluateOnNewDocument', { source: `(function(){ window.__lt = []; var M = ${JSON.stringify(MARKERS)};
    var D = ['MODE_RENDER_DEPTH','MODE_UNSHADED','USE_INSTANCING','BASE_PASS','DISABLE_FOG','APPLY_TONEMAPPING','USE_SHADOW','LIGHT_USE_PSSM','ADDITIVE_OMNI','ADDITIVE_SPOT','USE_MULTIVIEW','RENDER_SHADOWS','USE_LIGHTMAP'];
    function sig(g) { var m = M.filter(function(x){ return g.indexOf(x) >= 0; })[0] || ''; var d = D.filter(function(x){ return g.indexOf('#define ' + x) >= 0; }); var u = (g.match(/uniform [^;]*;/g) || []).length; return { marker: m, defs: d.join(' '), len: g.length }; }
    function wrap(P) { if (!P) return; var pr = P.prototype; var at = pr.attachShader, lk = pr.linkProgram, gp = pr.getProgramParameter;
      pr.attachShader = function(p, s) { try { (p.__sh = p.__sh || []).push(s); } catch (e) {} return at.call(this, p, s); };
      pr.linkProgram = function(p) { try { p.__lt = performance.now(); } catch (e) {} return lk.call(this, p); };
      pr.getProgramParameter = function(p, n) { if (n !== this.LINK_STATUS || p.__done) return gp.call(this, p, n);
        var t0 = performance.now(); var r = gp.call(this, p, n); var dt = performance.now() - t0; p.__done = true;
        try { var fs = null, vs = null; (p.__sh || []).forEach(function(s){ var g = this.getShaderSource(s) || ''; if (this.getShaderParameter(s, this.SHADER_TYPE) === this.FRAGMENT_SHADER) fs = g; else vs = g; }, this);
          var f = sig(fs || ''), v = sig(vs || ''); window.__lt.push([Math.round(t0), Math.round(dt), Math.round(t0 - (p.__lt || t0)), f.marker || v.marker, f.defs, f.len, v.len]); } catch (e) { window.__lt.push([Math.round(t0), Math.round(dt), 0, 'ERR ' + e]); }
        return r; }; }
    wrap(window.WebGL2RenderingContext); wrap(window.WebGLRenderingContext); })();` });
  await page.send('Page.navigate', { url });
  await sleep(SECS * 1000);
  res.links = JSON.parse(await page.eval('JSON.stringify(window.__lt)'));
  res.bootlog = JSON.parse(await page.eval('JSON.stringify(window.__bootlog || null)').catch(() => 'null'));
} catch (e) { res.error = String(e); }
finally { if (b) await b.close().catch(() => {}); server.close(); }
writeFileSync(out, JSON.stringify(res, null, 1));
const L = res.links || [];
const tot = L.reduce((a, l) => a + l[1], 0);
console.log(`programs linked: ${L.length}; waited ${Math.round(tot)} ms in all; over 200 ms: ${L.filter((l) => l[1] > 200).length}; ${res.error || ''}`);
for (const l of L.filter((l) => l[1] > 150).sort((a, c) => c[1] - a[1]).slice(0, 30)) console.log(`  ${String(l[1]).padStart(6)} ms at ${l[0]}  ${l[3] || '-'}  [${l[4]}] fs ${l[5]} vs ${l[6]}`);
