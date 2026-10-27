# Time the Direct3D shader compiler (d3dcompiler_47.dll, the FXC that ANGLE calls on Chrome for Windows) on the HLSL ANGLE
# made of a shader: hlsl.mjs's .hlsl files, ANGLE's "initial HLSL" with its link-time placeholders. They are filled the
# way ANGLE's DynamicHLSL does it in outline: the varyings come in as TEXCOORDs, the fragment's position and facing as
# system values, out_frag_color goes out as SV_Target0. Fragment shaders that write out_frag_color only.
# Offline: no browser, no Godot. Windows only. Python 3 standard library (ctypes). Owner: Rendering and Technical Art.
# Long batches at below-normal priority, like any long run (the rule of 2026-10-12).
#   python -I docs/rendering/tools/fxc_time.py <runs> <flags> <file.hlsl> [file.hlsl ...]
#   flags: l0, l1 (FXC's default), l2, l3 (optimization levels), skip (no optimization); a trailing f (l1f) defines
#   ANGLE_ENABLE_LOOP_FLATTEN, so ANGLE's FLATTEN and LOOP marks take effect. Prints the best time of <runs> per file.
import ctypes, re, sys, time
from ctypes import c_void_p, c_char_p, c_size_t, c_uint, POINTER, byref

d3d = ctypes.WinDLL('d3dcompiler_47.dll')
D3DCompile = d3d.D3DCompile
D3DCompile.argtypes = [c_void_p, c_size_t, c_char_p, c_void_p, c_void_p, c_char_p, c_char_p, c_uint, c_uint, POINTER(c_void_p), POINTER(c_void_p)]
D3DCompile.restype = ctypes.c_long
FLAGS = {'l0': 1 << 14, 'l1': 0, 'l2': (1 << 14) | (1 << 15), 'l3': 1 << 15, 'skip': 1 << 2}


def blob_text(p):
    if not p:
        return ''
    vt = ctypes.cast(ctypes.cast(p, POINTER(c_void_p))[0], POINTER(c_void_p))
    getptr = ctypes.WINFUNCTYPE(c_void_p, c_void_p)(vt[3])
    getsize = ctypes.WINFUNCTYPE(c_size_t, c_void_p)(vt[4])
    return ctypes.string_at(getptr(p), getsize(p)).decode('utf-8', 'replace')


def release(p):
    if p:
        vt = ctypes.cast(ctypes.cast(p, POINTER(c_void_p))[0], POINTER(c_void_p))
        ctypes.WINFUNCTYPE(c_uint, c_void_p)(vt[2])(p)


def fill(src):
    a = src.index('// INITIAL HLSL BEGIN')
    b = src.index('// INITIAL HLSL END')
    s = src[a:b]
    vb = s.index('// Varyings\n')
    ve = s.index('\n\n', vb)
    vars_ = re.findall(r'static\s+(\w+)\s+(\w+)\s*=', s[vb:ve])
    fields = ['    float4 dx_Position : SV_Position;'] + ['    %s v%d : TEXCOORD%d;' % (t, i, i) for i, (t, n) in enumerate(vars_)]
    out = 'struct PS_INPUT\n{\n%s\n};\nstruct PS_OUTPUT\n{\n    float4 gl_Color0 : SV_Target0;\n};\nPS_OUTPUT generateOutput()\n{\n    PS_OUTPUT o;\n    o.gl_Color0 = out_frag_color;\n    return o;\n}\n' % '\n'.join(fields)
    pro = 'gl_FragCoord = input.dx_Position;\ngl_FrontFacing = isFrontFace;\n' + ''.join('%s = input.v%d;\n' % (n, i) for i, (t, n) in enumerate(vars_))
    if FLATTEN_ON:
        s = '#define ANGLE_ENABLE_LOOP_FLATTEN' + chr(10) + s
    s = s.replace("@@ PIXEL OUTPUT @@", out).replace('@@ PIXEL MAIN PARAMETERS @@', 'PS_INPUT input, bool isFrontFace : SV_IsFrontFace').replace('@@ MAIN PROLOGUE @@', pro)
    left = re.findall(r'@@[^@]*@@', s)
    return s, left


FLATTEN_ON = sys.argv[2].endswith('f')
runs = int(sys.argv[1])
flags = FLAGS[sys.argv[2].rstrip('f')]
for f in sys.argv[3:]:
    s, left = fill(open(f, encoding='utf-8').read())
    data = s.encode('utf-8')
    best = None
    err = ''
    size = 0
    for r in range(runs):
        code = c_void_p()
        errs = c_void_p()
        t0 = time.perf_counter()
        hr = D3DCompile(data, len(data), b'shader', None, None, b'main', b'ps_5_0', flags, 0, byref(code), byref(errs))
        dt = time.perf_counter() - t0
        if hr != 0:
            err = blob_text(errs.value)[:600]
        elif code.value:
            vt = ctypes.cast(ctypes.cast(code.value, POINTER(c_void_p))[0], POINTER(c_void_p))
            size = ctypes.WINFUNCTYPE(c_size_t, c_void_p)(vt[4])(code.value)
        release(code.value)
        release(errs.value)
        best = dt if best is None else min(best, dt)
        if hr != 0:
            break
    print('%-28s %7.0f ms  %s%s' % (__import__('os').path.basename(f), best * 1000, ('bytecode %d' % size) if not err else 'ERROR ' + err.replace('\n', ' | '), (' left ' + str(left)) if left else ''))
    sys.stdout.flush()
