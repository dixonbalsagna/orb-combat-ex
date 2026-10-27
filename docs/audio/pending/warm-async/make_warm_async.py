"""Make the time-sliced twins of the audio synths (docs/audio/pending/warm-async).

Reads the synth sources from a tree (default the repo's audio/synth) and writes, into an output tree:
  * synth/slice.gd      AudioSlice (hand-written text below)
  * synth/dsp_a.gd      AudioDspA: the coroutine twins of the AudioDsp loops
  * the synth files with every function that loops (or calls one) turned into a coroutine NAME_a, and the public ones kept as thin sync
    wrappers (so every caller is unchanged and nothing is duplicated): a wrapper runs the coroutine with slicing off, so it never suspends.
The arithmetic is not touched; only `await` and a yield check are added, so the output is bit-identical to the unsliced render.
"""
import os, re, sys

SRC = sys.argv[1]            # a directory holding the original synth/*.gd
OUT = sys.argv[2]            # where to write
os.makedirs(OUT, exist_ok=True)

DSP_FUNCS = ["noise", "filter", "saturate", "peak", "rms", "normalize", "dc_block", "fade", "mix_into", "to_wav"]
CHECK = "if (%s & 255) == 0 and AudioSlice.due():\n%sawait AudioSlice.next_frame()\n"

# per file: the functions to turn into coroutines (public ones also keep a sync wrapper), and the class
CONFIG = {
    "impact_synth.gd": {"cls": "ImpactSynth", "funcs": ["render", "_layer", "_tone", "_noise", "_rumble", "_envelope", "_grains"], "public": ["render"]},
    "grunt_synth.gd": {"cls": "GruntSynth", "funcs": ["render"], "public": ["render"]},
    "flash_synth.gd": {"cls": "FlashSynth", "funcs": ["render", "_pulse", "_note", "_tick", "_breath", "_thump", "_growl"], "public": ["render"]},
    "babble_synth.gd": {"cls": "BabbleSynth", "funcs": ["render", "syllable", "laugh", "_crush", "blip", "_chorus", "_comb"], "public": ["render", "syllable", "laugh", "blip"]},
    "drone_synth.gd": {"cls": "DroneSynth", "funcs": ["render"], "public": ["render"]},
    "ambience_synth.gd": {"cls": "AmbienceSynth", "funcs": ["render", "_round_filter", "_curve", "_gust", "_flutter", "_hum", "_pulses"], "public": ["render"]},
}
# calls into other synth classes: class.func -> converted
CROSS = {"GruntSynth": ["render"], "ImpactSynth": ["render"], "FlashSynth": ["render"], "BabbleSynth": ["render", "syllable", "laugh", "blip"]}

SLICE = '''class_name AudioSlice
extends RefCounted
## Time-slicing for the audio bank's warm-up (docs/audio/warm-async.md). The synths' long loops are written as coroutines that call
## due() now and then and, when the frame's budget is spent, `await next_frame()`. With `on` false (every ordinary call, headless, the tools,
## a sound played un-warmed) due() is always false, so a coroutine never suspends and the sync wrappers (ImpactSynth.render and the others)
## give the same answer as ever, bit for bit. The warm-up driver (AudioBank) sets `on` while it runs.

static var on: bool = false           # slicing active: a warm-up is running across frames
static var budget_us: int = 6000      # microseconds of synthesis a frame may take (a knob: the warm-up takes about 1.8 s of CPU on a desktop)
static var max_slice_us: int = 0      # the longest single run between two yields seen (for the checks and the probe)
static var yields: int = 0
static var _t0: int = 0


static func due() -> bool:
	return on and Time.get_ticks_usec() - _t0 > budget_us


static func start_frame() -> void:
	_t0 = Time.get_ticks_usec()


## Give the frame back; continue in the next one with a fresh budget.
static func next_frame() -> void:
	max_slice_us = maxi(max_slice_us, Time.get_ticks_usec() - _t0)
	yields += 1
	await Engine.get_main_loop().process_frame
	_t0 = Time.get_ticks_usec()


## Run a coroutine to the end as an ordinary call: slicing is switched off for it, so it never suspends (and any slicing run that is
## suspended elsewhere is untouched and resumes with `on` as it was).
static func run_sync(c: Callable, args: Array):
	var keep: bool = on
	on = false
	var r = c.callv(args)
	on = keep
	return r
'''


def params_of(sig: str):
    inner = sig[sig.index("(") + 1: sig.rindex(")")]
    names = []
    depth = 0
    cur = ""
    parts = []
    for ch in inner:
        if ch in "([{":
            depth += 1
        elif ch in ")]}":
            depth -= 1
        if ch == "," and depth == 0:
            parts.append(cur)
            cur = ""
        else:
            cur += ch
    if cur.strip():
        parts.append(cur)
    for p in parts:
        names.append(p.strip().split(":")[0].split("=")[0].strip())
    return names


_loop_no = [0]


def _top_split(arg):
    """Split a range() argument list at top-level commas."""
    parts, depth, cur = [], 0, ""
    for ch in arg:
        if ch in "([{":
            depth += 1
        elif ch in ")]}":
            depth -= 1
        if ch == "," and depth == 0:
            parts.append(cur.strip())
            cur = ""
        else:
            cur += ch
    parts.append(cur.strip())
    return parts


def instrument(lines, in_func):
    """Add yield checks to the long loops of a converted function; returns the new lines. A long sample loop  becomes
    chunks of 1024 iterations with one check between them (the body and its order are untouched), so the check costs next to nothing."""
    out = []
    k = 0
    while k < len(lines):
        ln = lines[k]
        m = re.match(r"^(	+)for (\w+) in range\((.+)\):\s*$", ln)
        if m and in_func:
            ind, var, arg = m.group(1), m.group(2), m.group(3)
            parts = _top_split(arg)
            literal = re.fullmatch(r"\d+", arg) or arg.startswith("mini(3")
            if var in ("i", "j") and not literal and len(parts) in (1, 2):
                # the loop's body: the following lines indented deeper (blank lines belong to it when more body follows)
                body = []
                q = k + 1
                while q < len(lines) and (lines[q].strip() == "" or lines[q].startswith(ind + "	")):
                    body.append(lines[q])
                    q += 1
                while body and body[-1].strip() == "":
                    q -= 1
                    body.pop()
                assert not any(re.search(r"break", b) for b in body), "a break in a chunked loop"
                body = instrument(body, in_func)
                _loop_no[0] += 1
                c, e = "_c%d" % _loop_no[0], "_e%d" % _loop_no[0]
                lo, hi = ("0", parts[0]) if len(parts) == 1 else (parts[0], parts[1])
                out.append("%svar %s: int = %s" % (ind, c, lo))
                out.append("%svar %s: int = %s" % (ind, e, hi))
                out.append("%swhile %s < %s:" % (ind, c, e))
                out.append("%s	for %s in range(%s, mini(%s + 1024, %s)):" % (ind, var, c, c, e))
                out.extend(("	" + b) if b.strip() != "" else b for b in body)
                out.append("%s	%s += 1024" % (ind, c))
                out.append("%s	if AudioSlice.due():" % ind)
                out.append("%s		await AudioSlice.next_frame()" % ind)
                k = q
                continue
        out.append(ln)
        m2 = re.match(r"^(	+)while (.+):\s*$", ln)
        if m2 and in_func and "start < n" in m2.group(2):
            out.append(m2.group(1) + chr(9) + "if AudioSlice.due():")
            out.append(m2.group(1) + chr(9) + chr(9) + "await AudioSlice.next_frame()")
        m3 = re.match(r"^(	+)for L in (def|recipe)\.layers:\s*$", ln)
        if m3 and in_func:
            out.append(m3.group(1) + chr(9) + "if AudioSlice.due():")
            out.append(m3.group(1) + chr(9) + chr(9) + "await AudioSlice.next_frame()")
        k += 1
    return out


def convert_calls(line, local_funcs, cls):
    # AudioDsp.<loop helper>( -> await AudioDspA.<helper>(
    for f in DSP_FUNCS:
        line = re.sub(r"(?<![\w.])AudioDsp\.%s\(" % f, "await AudioDspA.%s(" % f, line)
    # other synth classes
    for c, fs in CROSS.items():
        for f in fs:
            line = re.sub(r"(?<![\w.])%s\.%s\(" % (c, f), "await %s.%s_a(" % (c, f), line)
    # local functions of this class
    for f in local_funcs:
        line = re.sub(r"(?<![\w.])%s\(" % re.escape(f), "await %s_a(" % f, line)
    return line


def split_funcs(text):
    """Yield (kind, lines): kind 'func' with the func name, or 'other'."""
    lines = text.split("\n")
    blocks = []
    cur = []
    cur_name = None
    for ln in lines:
        m = re.match(r"^static func (\w+)\(", ln)
        if m:
            blocks.append((cur_name, cur))
            cur = [ln]
            cur_name = m.group(1)
        else:
            cur.append(ln)
    blocks.append((cur_name, cur))
    return blocks


def convert_file(name, cfg):
    text = open(os.path.join(SRC, name), encoding="utf-8", newline="").read().replace("\r\n", "\n")
    cls = cfg["cls"]
    funcs = cfg["funcs"]
    blocks = split_funcs(text)
    out = []
    for fname, lines in blocks:
        if fname is None or fname not in funcs:
            # leading comments of the next function stay with this block; a converted function's doc comment sits at the tail of the previous block
            out.extend(lines)
            continue
        # the doc comment lines at the tail of `out` belong to this function: keep them before the wrapper
        sig = lines[0]
        body = lines[1:]
        body = instrument(body, True)
        body = [convert_calls(b, funcs, cls) for b in body]
        newsig = re.sub(r"^static func %s\(" % re.escape(fname), "static func %s_a(" % fname, sig)
        if fname in cfg["public"]:
            names = params_of(sig)
            ret = ""
            m = re.search(r"\)\s*(->\s*[^:]+):\s*$", sig)
            if m:
                ret = " " + m.group(1)
            wrapper = [sig, "\treturn AudioSlice.run_sync(Callable(%s, \"%s_a\"), [%s])" % (cls, fname, ", ".join(names)), "", ""]
            # place the wrapper where the original was, and the coroutine after it
            out.extend(wrapper)
        out.append(newsig)
        out.extend(body)
    return "\n".join(out)


def make_dsp_a():
    text = open(os.path.join(SRC, "dsp.gd"), encoding="utf-8", newline="").read().replace("\r\n", "\n")
    blocks = split_funcs(text)
    out = ["class_name AudioDspA", "extends RefCounted",
           "## The coroutine twins of AudioDsp's loops (docs/audio/warm-async.md): the same arithmetic, in the same order, with a yield check in every",
           "## long loop (AudioSlice). Only the synths' async paths call these; AudioDsp itself is unchanged for every other caller.", "", ""]
    for fname, lines in blocks:
        if fname not in DSP_FUNCS:
            continue
        body = instrument(lines[1:], True)
        body = [convert_calls(b, [], "AudioDspA") for b in body]
        body = [re.sub(r"(?<![\w.])BLOCK\b", "AudioDsp.BLOCK", b) for b in body]
        body = [re.sub(r"(?<![\w.])state_of\(", "AudioDsp.state_of(", b) for b in body]
        body = [re.sub(r"(?<![\w.])LN60\b", "AudioDsp.LN60", b) for b in body]
        # calls between the twins: peak() inside normalize()
        body = [re.sub(r"(?<![\w.])peak\(", "await peak(", b) if "var p: float = peak(" in b else b for b in body]
        out.append(lines[0])
        out.extend(body)
        while out and out[-1] == "":
            out.pop()
        out.extend(["", ""])
    while out and out[-1] == "":
        out.pop()
    return "\n".join(out) + "\n"


open(os.path.join(OUT, "slice.gd"), "w", encoding="utf-8", newline="").write(SLICE)
open(os.path.join(OUT, "dsp_a.gd"), "w", encoding="utf-8", newline="").write(make_dsp_a())
for name, cfg in CONFIG.items():
    open(os.path.join(OUT, name), "w", encoding="utf-8", newline="").write(convert_file(name, cfg))
print("wrote", sorted(os.listdir(OUT)))
