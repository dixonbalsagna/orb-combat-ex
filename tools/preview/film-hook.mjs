// The film variant's changes to the capture hook (render/tools/flash_capture.gd of a scratch tree; stack-preview --film): the match starts with the page's setup words, and the scene `chapel` is added:
// both fighters set down 1,500 units west of the nearest barred landmark (WorldSettle.noTarget: the hill chapel, a school, a hospital) and player one launches the AI east toward it (reel.mjs --scenario chapel).
export function patchHook(hook) {
  const T = '\t', N = '\n';
  const pairs = [
    ['{} if slots.size() < 2 else {"slots": slots})', 'main._preview_planet() if slots.size() < 2 else {"slots": slots})'],
    ['func drive(sc: String, t: int, S: SimState) -> void:\n', `func drive(sc: String, t: int, S: SimState) -> void:${N}${T}if main.args.has("nohud"):   # ?nohud=1 (film variant only): no HUD layer, no take-over prompt: a picture of the world and the fighters${N}${T}${T}main.get_node("HUD").visible = false${N}`],
    ['"launchai", "clashcity",', '"launchai", "chapel", "towers", "chase", "chargehold", "clashcity",'],
    ['"launchai": [false, true],', '"launchai": [false, true], "chapel": [false, true], "towers": [false, true], "chase": [false, true], "chargehold": [false, true],'],
    [`${T}${T}"launchai":     # player one launches the AI${N}`, `${T}${T}"chargehold":     # player one closes to within 6 body heights of the rival, holds the right stick toward him for 60 ticks and lets go (every 240 ticks): the stick's charged strike${N}${T}${T}${T}_chargehold(t, S)${N}${T}${T}"launchai":     # player one launches the AI${N}`, 'chargehold case'],
    ['func _launch_ai(t: int, S: SimState) -> void:', [
      'func _chargehold(t: int, S: SimState) -> void:',
      `${T}var dx: float = SimWrap.sdx(S.fighters[0].x, S.fighters[1].x)`,
      `${T}var u: int = t % 240`,
      `${T}if u < 120:`,
      `${T}${T}_stick(0, signf(dx) if absf(dx) > 450.0 else 0.0)`,
      `${T}${T}main.host.hub.pad_stick_right(0, 0.0, 0.0)`,
      `${T}elif u < 180:`,
      `${T}${T}_stick(0, 0.0)`,
      `${T}${T}main.host.hub.pad_stick_right(0, signf(dx), 0.0)`,
      `${T}else:`,
      `${T}${T}_stick(0, 0.0)`,
      `${T}${T}main.host.hub.pad_stick_right(0, 0.0, 0.0)`, '', '',
      'func _launch_ai(t: int, S: SimState) -> void:'].join(N), 'chargehold func'],
    [`${T}${T}"launchai":     # player one launches the AI${N}`, `${T}${T}"chase":     # player one launches the AI, then taps X at it while it is in the air (the chase tap, its hang and its carry)${N}${T}${T}${T}_launch_ai(t, S)${N}${T}${T}${T}_btn(0, "west", String(S.fighters[1].state) == "launched" and _tap(t, 6, 0))${N}${T}${T}"launchai":     # player one launches the AI${N}`, 'chase'],
    [`${T}${T}"launchai":     # player one launches the AI${N}`, `${T}${T}"towers":     # player one launches the AI east from beside the tallest tower: through the row of towers${N}${T}${T}${T}if t == 0:${N}${T}${T}${T}${T}_to_the_city(S)${N}${T}${T}${T}_launch_ai(t, S)${N}${T}${T}"launchai":     # player one launches the AI${N}`, 'towers'],
    [`${T}${T}"launchai":     # player one launches the AI${N}`, `${T}${T}"chapel":     # player one launches the AI beside the nearest barred landmark${N}${T}${T}${T}if t == 0:${N}${T}${T}${T}${T}_to_the_chapel(S)${N}${T}${T}${T}_launch_ai(t, S)${N}${T}${T}"launchai":     # player one launches the AI${N}`],
    ['func _launch_ai(t: int, S: SimState) -> void:', [
      'func _to_the_chapel(S: SimState) -> void:',
      `${T}var tgt = null`,
      `${T}for b in S.buildings:`,
      `${T}${T}if b.alive and WorldSettle.noTarget(b.landmark):`,
      `${T}${T}${T}if tgt == null or absf(SimWrap.sdx(S.fighters[0].x, b.x)) < absf(SimWrap.sdx(S.fighters[0].x, tgt.x)):`,
      `${T}${T}${T}${T}tgt = b`,
      `${T}if tgt == null:`,
      `${T}${T}return`,
      `${T}for i in range(2):`,
      `${T}${T}var fi = S.fighters[i]`,
      `${T}${T}fi.x = SimWrap.wrap(tgt.x - 1500.0 + 60.0 * float(i))`,
      `${T}${T}fi.y = WorldTerrain.groundY(S, fi.x) + 10.0`,
      `${T}${T}fi.vx = 0.0`,
      `${T}${T}fi.vy = 0.0`, '', '',
      'func _launch_ai(t: int, S: SimState) -> void:'].join(N)],
  ];
  let h = hook;
  for (const [x, y] of pairs) {
    if (h.split(x).length !== 2) throw new Error('--film: the hook changed near ' + x.slice(0, 40));
    h = h.replace(x, () => y);
  }
  return h;
}
