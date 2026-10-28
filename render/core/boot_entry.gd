extends Node
## The game's own entry on a screen (the project's main scene; Performance's start-block profile,
## docs/perf/boot-start-block-2026-10-27.md): the start block was one long first frame, mostly GDScript compiling main's
## whole script graph (the sim's, UI's, the render's) before anything drew. Here the boot's line is up at once, the heavy
## graphs are loaded one a frame (each load() compiles what it pulls in and is not yet loaded), so the page draws between
## them, and then main takes over, with its own boot behind the same line (render/core/boot.gd). The total is the same.
## A tool, the capture hook, a bench, a scripted run, Animation's study scene or a headless run goes to main at once.
## This scene loads nothing heavy itself: the line is RenderBoot's (render/core/boot.gd and RenderLook pull in four small
## scripts, outside the sim's).

const MAIN: String = "res://render/main.tscn"
## The loads, one a drawn frame, in this order, leaves first: each compiles its script graph less what is loaded
## already, so each is about a tenth of main's (Rendering's measure of the class graph, 2026-10-27). The first is the
## sim's: its 77 scripts reference each other in one cycle, so they compile together whatever loads first. A path that
## is gone is passed over (main loads whatever is left).
const STEPS: Array = [
	"res://sim/core/act.gd",               # the sim (sim/core, sim/world, sim/director, sim/input: one cycle)
	"res://sim/core/campaign.gd",          # the campaign and the rest of the sim's core
	"res://sim/input/hub.gd",              # the input layer
	"res://audio/audio_bank.gd",           # Audio's bank and synth
	"res://render/anim/render_anim.gd",    # Animation's
	"res://render/vfx/vfx_hub.gd",         # VFX's
	"res://render/core/fighter_view.gd",   # the fighters' views
	"res://render/core/sim_host.gd",       # the host (and Audio's cues)
	"res://ui/core/ui_event_hub.gd",       # UI's core
	"res://ui/widgets/ui_howto.gd",        # ... its larger widgets
	"res://ui/widgets/ui_settings.gd",
	"res://ui/widgets/ui_feedback.gd",
	"res://ui/hud/ui_hud.tscn",            # ... and the HUD
	"res://render/camera/split_rig.gd",    # Camera's
	"res://render/core/planet_view.gd",    # the planet
	"res://render/core/pane_world.gd",     # the pane
]
## What starts main at once, as before: main's own switches for a run that is not the game on a screen
## (main.gd _boot_staged and the page's URL args), and Animation's study scene.
const DIRECT: Array = ["flashcap", "bench", "frames", "shot", "nobootstage", "study"]

var _next: int = 0
var _shown: bool = false   # a frame has been drawn since the last load (frame_post_draw)


func _ready() -> void:
	if _direct():
		_main.call_deferred()
		return
	add_child(RenderBoot.line(RenderLook.BOOT_WORDS, get_viewport().get_visible_rect().size, RenderBoot.dp())[0])   # main's boot takes over the same line
	RenderingServer.frame_post_draw.connect(_drawn)


## A frame has been drawn: the next frame may load (it is presented when this frame's work returns to the browser).
func _drawn() -> void:
	if not _shown and _next == 0:
		_say("first_frame")
		Engine.set_meta("ocx_first_frame", true)   # main's breadcrumbs go on from here (main.gd _crumb)
	_shown = true


## One load a frame, and only once the frame before it is on the screen: the line is up before the first.
func _process(_delta: float) -> void:
	if not _shown:
		return
	_shown = false
	while _next < STEPS.size() and not ResourceLoader.exists(STEPS[_next]):
		_next += 1
	if _next < STEPS.size():
		if _next == 0:
			_say("scripts")
		load(STEPS[_next])   # one graph this frame; the page draws before the next
		_next += 1
		return
	set_process(false)
	RenderingServer.frame_post_draw.disconnect(_drawn)
	_main()


func _main() -> void:
	get_tree().change_scene_to_file(MAIN)


## A run that is not the game on a screen: headless, or one of main's switches on the command line or in the page's URL.
func _direct() -> bool:
	if DisplayServer.get_name() == "headless":
		return true
	for a in OS.get_cmdline_user_args():
		for d in DIRECT:
			if a == "--" + d or a.begins_with("--" + d + "="):
				return true
	if OS.has_feature("web"):
		var q: String = str(JavaScriptBridge.eval("location.search", true))
		for d in DIRECT:
			if q.find(d + "=") >= 0:
				return true
	return false


## Performance's breadcrumbs (main.gd _crumb): the first frame is up, then the scripts load; main goes on from there.
func _say(stage: String) -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.__ocx && window.__ocx.crumbs && window.__ocx.crumbs.stage && window.__ocx.crumbs.stage('%s')" % stage, true)
