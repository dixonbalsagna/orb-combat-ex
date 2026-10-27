#!/usr/bin/env node
// The HLSL that ANGLE (Chrome's WebGL on Direct3D 11) makes of the game's shaders, for timing the driver's compile offline
// with fxc_time.py. Before the page's scripts run it wraps compileShader; for each shader whose GLSL holds one of the
// markers it keeps the GLSL and WEBGL_debug_shaders' translated source (ANGLE's "initial HLSL", with its link-time
// placeholders). It waits <seconds>, or until a boot probe build's window.__bootlog appears, then writes
// <outdir>/NN-<marker>-<vs|fs>.glsl and .hlsl, and index.json.
// Headless Chrome only through Tools' guarded launcher (tools/machine/browser.mjs: below-normal priority, a core mask, a time limit,
// a profile named for the session, MERIDIAN_SESSION or 'rendering'); never start a browser another way. One capture at a time. Node 24
// built-ins only. Owner: Rendering and Technical Art. No Godot window.
//
//   node docs/rendering/tools/hlsl.mjs <site dir (holds play/)> <outdir> [seconds 240] [marker,marker]
import { writeFileSync, mkdirSync } from 'node:fs';
import { pathToFileURL, fileURLToPath } from 'node:url';
import { join } from 'node:path';
const [site, outdir, secS, mk] = process.argv.slice(2);
const repo = fileURLToPath(new URL('../../../', import.meta.url));   // the project root (this file is docs/rendering/tools/)

const SECS = Number(secS || 240);
const MARKERS = (mk || 'win_hash,fore_cap3').split(',');
const { Cdp, launchBrowser, serve, browserExe } = await import(pathToFileURL(join(repo, 'tools/machine/browser.mjs')).href);
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
mkdirSync(outdir, { recursive: true });
const server = await serve(site);
const url = `http://127.0.0.1:${server.address().port}/play/index.html`;
let b = null;
const res = { url, markers: MARKERS, shaders: [] };
try {
  b = await launchBrowser({ exe: browserExe(), session: process.env.MERIDIAN_SESSION || 'rendering', purpose: 'hlsl', timeoutS: SECS + 120, log: () => {},
    flags: ['--window-size=1280,720', '--disable-background-timer-throttling', '--disable-renderer-backgrounding', '--disable-backgrounding-occluded-windows'] });
  const page = await Cdp.open(b.target.webSocketDebuggerUrl);
  await page.send('Page.enable');
  await page.send('Emulation.setDeviceMetricsOverride', { width: 1280, height: 720, deviceScaleFactor: 1, mobile: false });
  await page.send('Page.addScriptToEvaluateOnNewDocument', { source: `(function(){ window.__hl = []; var M = ${JSON.stringify(MARKERS)};
    function wrap(P) { if (!P) return; var c = P.prototype.compileShader; P.prototype.compileShader = function(sh) {
      var r = c.call(this, sh); try { var g = this.getShaderSource(sh) || ''; var m = M.filter(function(x){ return g.indexOf(x) >= 0; });
        if (m.length) { var e = this.getExtension('WEBGL_debug_shaders'); var vs = this.getShaderParameter(sh, this.SHADER_TYPE) === this.VERTEX_SHADER;
          window.__hl.push({ marker: m[0], stage: vs ? 'vs' : 'fs', glsl: g, hlsl: e ? e.getTranslatedShaderSource(sh) : null }); } } catch (x) { window.__hl.push({ error: String(x) }); }
      return r; }; }
    wrap(window.WebGL2RenderingContext); wrap(window.WebGLRenderingContext); })();` });
  await page.send('Page.navigate', { url });
  const t0 = Date.now();
  while (Date.now() - t0 < SECS * 1000) {
    await sleep(3000);
    const done = await page.eval('!!window.__bootlog').catch(() => false);
    if (done) { await sleep(2000); break; }
  }
  const n = Number(await page.eval('window.__hl.length').catch(() => 0));
  for (let i = 0; i < n; i++) {
    const s = JSON.parse(await page.eval(`JSON.stringify(window.__hl[${i}])`));
    if (s.error) { res.shaders.push(s); continue; }
    const base = `${String(i).padStart(2, '0')}-${s.marker}-${s.stage}`;
    writeFileSync(join(outdir, base + '.glsl'), s.glsl);
    if (s.hlsl) writeFileSync(join(outdir, base + '.hlsl'), s.hlsl);
    res.shaders.push({ i, marker: s.marker, stage: s.stage, glsl: s.glsl.length, hlsl: s.hlsl ? s.hlsl.length : null, file: base });
  }
  res.seconds = (Date.now() - t0) / 1000;
} catch (e) { res.error = String(e); }
finally { if (b) await b.close().catch(() => {}); server.close(); }
writeFileSync(join(outdir, 'index.json'), JSON.stringify(res, null, 1));
console.log(`shaders kept: ${res.shaders.length}; with HLSL: ${res.shaders.filter((s) => s.hlsl).length}; ${res.error || ''}`);
