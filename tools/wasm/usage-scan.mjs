// Which engine classes does the game actually use? (docs/tools/web-template-size.md: the evidence for a custom Web export template that leaves modules out.)
// Reads the engine's own class list (Godot --dump-extension-api, saved as JSON) and looks for every engine class in the project's own text (scripts, scenes, resources, project.godot, import
// settings), then groups the answer by the engine module or build option that provides the class. A class named in a script only inside a comment still counts (this is an over-count, which
// is the safe side for deciding what may be left out). Nothing is built or downloaded: the dump comes from the Godot executable already on the PC.
//   node tools/wasm/usage-scan.mjs --api <extension_api.json> [--root <project>] [--json out.json] [--md out.md]
//   "$GODOT" --headless --dump-extension-api      (writes extension_api.json into the working folder)
import { existsSync, readFileSync, readdirSync, statSync, writeFileSync } from 'node:fs';
import { dirname, join, relative, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
// What provides a class: [family, module or build option, what to look at, a test on the class name]. First match wins. These are the engine's own groupings, from its source layout
// (modules/<name>, servers, scene/3d and so on); a class that matches none is "core, scene or servers" and stays in the template whatever we do.
export const FAMILIES = [
  ['3D physics', 'disable_3d / modules godot_physics_3d, jolt_physics', (n) => /(^|3D)(Physics|Rigid|Static|Character|Kinematic|Vehicle|Soft)?Body3D$|^Area3D$|^Collision(Shape|Object|Polygon)3D$|Joint3D$|^PhysicsServer3D|^PhysicsDirect(Body|Space)State3D|^PhysicsMaterial$|^PhysicsPointQueryParameters3D|^PhysicsRayQueryParameters3D|^PhysicsShapeQueryParameters3D|^PhysicalBone3D|^SeparationRayShape3D|^ShapeCast3D|^RayCast3D|Shape3D$|^JoltPhysics|^ConvexPolygonShape3D/.test(n)],
  ['2D physics', 'disable_physics_2d / module godot_physics_2d', (n) => /Body2D$|^Area2D$|^Collision(Shape|Object|Polygon)2D$|Joint2D$|^PhysicsServer2D|^PhysicsDirect(Body|Space)State2D|^PhysicsPointQueryParameters2D|^PhysicsRayQueryParameters2D|^PhysicsShapeQueryParameters2D|^ShapeCast2D|^RayCast2D|Shape2D$/.test(n)],
  ['Navigation', 'disable_navigation_2d / disable_navigation_3d / modules navigation_2d, navigation_3d', (n) => /^Navigation|^NavigationServer/.test(n)],
  ['XR and OpenXR', 'disable_xr / module openxr, webxr', (n) => /^XR|^OpenXR|^WebXR|^MobileVRInterface/.test(n)],
  ['Networking', 'modules enet, websocket, webrtc, upnp, mbedtls, multiplayer, jsonrpc', (n) => /^ENet|^WebSocket|^WebRTC|^UPNP|^HTTPClient|^HTTPRequest|^StreamPeerTLS|^PacketPeerDTLS|^DTLSServer|^TLSOptions|^MultiplayerAPI|^MultiplayerPeer|^SceneMultiplayer|^MultiplayerSpawner|^MultiplayerSynchronizer|^OfflineMultiplayerPeer|^JSONRPC|^UDPServer|^TCPServer|^PacketPeerUDP|^StreamPeerTCP/.test(n)],
  ['Advanced text shaping', 'module text_server_adv (ICU, HarfBuzz, Graphite) against text_server_fb', (n) => /^TextServer(Advanced|Fallback|Extension)?$|^TextParagraph|^TextLine/.test(n)],
  ['Fonts', 'modules freetype, msdfgen', (n) => /^Font|^SystemFont|^Label3D|^TextMesh/.test(n)],
  ['SVG', 'module svg (ThorVG)', (n) => /^SVG/.test(n)],
  ['Image formats', 'modules webp, tga, bmp, dds, hdr, tinyexr, ktx, basis_universal, jpg, astcenc, etcpak, cvtt', (n) => /^ImageTexture|^CompressedTexture|^Texture(Cube|3D|Layered|2DArray)|^PortableCompressedTexture2D$|^CompressedCubemap|^CompressedTexture3D/.test(n)],
  ['Audio formats', 'modules ogg, vorbis, minimp3, interactive_music', (n) => /^AudioStream(OggVorbis|MP3|Interactive|Playlist|Synchronized|Randomizer|Polyphonic|WAV|Generator|Microphone|Player|Playback)/.test(n)],
  ['Video', 'module theora', (n) => /^VideoStream|^VideoStreamPlayer/.test(n)],
  ['3D rendering', 'disable_3d', (n) => /3D$|^Mesh|^MultiMesh|^Environment|^Sky|^Camera3D|^World3D|^Node3D|^Light|^Decal|^Fog|^Occluder|^Voxel|^Reflection|^Skeleton3D|^Skin|^Particles3D|^GPUParticles3D|^CPUParticles3D|^Standard|^ORMMaterial3D|^BaseMaterial3D|^ProceduralSky|^PanoramaSky|^PhysicalSky|^Gradient|^ArrayMesh|^ImmediateMesh|^PrimitiveMesh|^BoxMesh|^SphereMesh|^PlaneMesh|^QuadMesh/.test(n)],
  ['CSG and GridMap', 'modules csg, gridmap', (n) => /^CSG|^GridMap/.test(n)],
  ['Lightmapping and baking', 'modules lightmapper_rd, raycast (Embree)', (n) => /^Lightmap|^OccluderInstance3D|^Occluder3D/.test(n)],
  ['Model import at run time', 'modules gltf, fbx', (n) => /^GLTF|^FBX/.test(n)],
  ['Noise', 'module noise (FastNoiseLite)', (n) => /^Noise|^FastNoiseLite|^NoiseTexture/.test(n)],
  ['Regular expressions', 'module regex', (n) => /^RegEx/.test(n)],
  ['Camera input', 'module camera', (n) => /^Camera(Server|Feed|Texture)/.test(n)],
  ['Zip files', 'module zip / minizip', (n) => /^ZIP|^ZipPacker/.test(n)],
  ['Advanced GUI', 'disable_advanced_gui', (n) => /^(Tree|TreeItem|ItemList|TabBar|TabContainer|GraphEdit|GraphNode|GraphElement|CodeEdit|TextEdit|RichTextLabel|FileDialog|ColorPicker|ColorPickerButton|MenuBar|PopupMenu|MenuButton|OptionButton|SpinBox|Window|AcceptDialog|ConfirmationDialog|SplitContainer|HSplitContainer|VSplitContainer|ScrollContainer|SubViewportContainer|FoldableContainer|GridContainer|FlowContainer|ReferenceRect|LineEdit|Slider|HSlider|VSlider|ScrollBar|VScrollBar|HScrollBar|SpinBox|LinkButton|CheckBox|CheckButton|ColorRect|TextureRect|NinePatchRect|Range|ProgressBar|TextureProgressBar|BoxContainer|VBoxContainer|HBoxContainer|CenterContainer|MarginContainer|PanelContainer|AspectRatioContainer)$/.test(n)],
];

/** Does the text mention the class as a whole word? */
export const mentions = (text, name) => new RegExp(`(^|[^A-Za-z0-9_])${name}([^A-Za-z0-9_]|$)`).test(text);

export function scan(api, root) {
  const classes = api.classes.filter((c) => c.api_type === 'core').map((c) => c.name);
  const files = [];
  const SKIP = new Set(['.git', '.godot', 'node_modules', 'docs', 'art', 'qa', 'research', 'prototype', 'homework', 'build', 'tools', 'tmp']);
  const walk = (d) => {
    for (const e of readdirSync(d, { withFileTypes: true })) {
      const p = join(d, e.name);
      if (e.isDirectory()) { if (!SKIP.has(e.name) && !existsSync(join(p, '.gdignore'))) walk(p); }
      else if (/\.(gd|tscn|tres|godot|cfg|import|gdshader|json)$/.test(e.name) && statSync(p).size < 6e6) files.push(p);
    }
  };
  walk(root);
  const inTools = (p) => /(^|\/)(tools|test|tests|mock)(\/|$)/.test(relative(root, p).split(sep).join('/'));
  const shipped = files.filter((p) => !inTools(p) && /\.(gd|tscn|tres|godot|cfg|gdshader)$/.test(p));
  const texts = shipped.map((p) => [relative(root, p).split(sep).join('/'), readFileSync(p, 'utf8')]);
  const usedBy = new Map();
  for (const name of classes) {
    for (const [p, t] of texts) if (t.includes(name) && mentions(t, name)) { if (!usedBy.has(name)) usedBy.set(name, []); usedBy.get(name).push(p); }
  }
  const byFamily = new Map();
  for (const name of classes) {
    const fam = FAMILIES.find((f) => f[2](name));
    if (!fam) continue;
    const row = byFamily.get(fam[0]) || { family: fam[0], provides: fam[1], classes: 0, used: [], usedFiles: new Set() };
    row.classes++;
    if (usedBy.has(name)) { row.used.push(name); for (const f of usedBy.get(name)) row.usedFiles.add(f); }
    byFamily.set(fam[0], row);
  }
  return { files: shipped.length, classes: classes.length, usedClasses: usedBy.size, families: [...byFamily.values()].map((r) => ({ ...r, usedFiles: [...r.usedFiles].slice(0, 6) })), used: [...usedBy.keys()].sort() };
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const args = process.argv.slice(2);
  const opt = (n, d) => { const i = args.indexOf(n); return i >= 0 ? args[i + 1] : d; };
  const apiFile = opt('--api');
  if (!apiFile || !existsSync(apiFile)) { console.error('usage: node tools/wasm/usage-scan.mjs --api <extension_api.json> [--root <project>] [--json out.json] [--md out.md]'); process.exit(2); }
  const root = resolve(opt('--root', join(HERE, '..', '..')));
  const r = scan(JSON.parse(readFileSync(apiFile, 'utf8')), root);
  const lines = [`${r.files} shipped project files scanned; ${r.usedClasses} of ${r.classes} engine classes are named in them.`, '', '| Family | Provided by | Classes | Used by the game | Where |', '| :--- | :--- | ---: | :--- | :--- |'];
  for (const f of r.families) lines.push(`| ${f.family} | ${f.provides} | ${f.classes} | ${f.used.length ? f.used.join(', ') : '**none**'} | ${f.usedFiles.join(', ')} |`);
  console.log(lines.join('\n'));
  if (opt('--json')) writeFileSync(opt('--json'), JSON.stringify(r, null, 1));
  if (opt('--md')) writeFileSync(opt('--md'), lines.join('\n') + '\n');
}
