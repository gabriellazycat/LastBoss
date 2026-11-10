"""Arte de carta em "render 3D com traço de nanquim" (rodada dos vilões, 10/11/2026).
Renderiza a cena em 3 passes no EEVEE (traço + hachura, cor chapada, luz) e compõe 3 variações de estilo:
  v1 nanquim  — só tinta (linha + hachura), transparente, na cor de tinta do tipo da carta;
  v2 aguada   — a mesma tinta sobre uma aguada com as cores do modelo, dessaturadas;
  v3 duas     — tinta + uma cor chapada (a do tipo) nas sombras, como impressão em duas tintas.
Usado por render_cards.py. Blender 5.2, -b."""
import bpy, math, os
import numpy as np
from mathutils import Vector

W, H = 1040, 800
# tinta por tipo de carta (as mesmas famílias de cor do Diário)
INKS = {
    "monster": (0.29, 0.07, 0.04), "swarm": (0.36, 0.14, 0.03), "spell": (0.23, 0.145, 0.50),
    "structure": (0.33, 0.24, 0.05), "route": (0.07, 0.17, 0.36), "lair": (0.13, 0.22, 0.10), "ink": (0.12, 0.095, 0.075),
}
PAPER = (0.93, 0.89, 0.76)


def setup_scene():
    sc = bpy.context.scene
    try:
        sc.render.engine = 'BLENDER_EEVEE_NEXT'
    except TypeError:
        sc.render.engine = 'BLENDER_EEVEE'
    sc.render.resolution_x, sc.render.resolution_y = W, H
    sc.render.resolution_percentage = 100
    sc.render.film_transparent = True
    sc.render.image_settings.file_format = 'PNG'
    sc.render.image_settings.color_mode = 'RGBA'
    sc.view_settings.view_transform = 'Standard'
    try:
        sc.view_settings.look = 'None'
    except TypeError:
        pass
    w = bpy.data.worlds.new("W"); sc.world = w; w.use_nodes = True
    bg = next(n for n in w.node_tree.nodes if n.type == 'BACKGROUND')
    bg.inputs[0].default_value = (1, 1, 1, 1); bg.inputs[1].default_value = 0.10
    sun = bpy.data.lights.new("Key", 'SUN'); sun.energy = 1.7; sun.angle = math.radians(1.5)
    so = bpy.data.objects.new("Key", sun); sc.collection.objects.link(so)
    so.rotation_euler = (math.radians(52), 0, math.radians(-48))
    return sc


def meshes():
    return [o for o in bpy.context.scene.objects if o.type == 'MESH']


def frame_camera(direction=(0.5, -1.0, 0.38), lens=85, margin=1.12, look_dz=0.0):
    sc = bpy.context.scene
    bpy.context.view_layer.update()
    lo = Vector((1e9,) * 3); hi = Vector((-1e9,) * 3)
    for o in meshes():
        for c in o.bound_box:
            p = o.matrix_world @ Vector(c); lo = Vector(map(min, lo, p)); hi = Vector(map(max, hi, p))
    ctr = (lo + hi) / 2 + Vector((0, 0, look_dz))
    cd = bpy.data.cameras.new("C"); cd.lens = lens
    c = bpy.data.objects.new("C", cd); sc.collection.objects.link(c); sc.camera = c
    d = Vector(direction).normalized()
    c.rotation_euler = (-d).to_track_quat('-Z', 'Y').to_euler()
    c.location = ctr + d * 10.0
    bpy.context.view_layer.update()
    # afasta até caber: projeta os cantos da caixa no plano da câmera
    inv = c.matrix_world.inverted()
    sw = cd.sensor_width; asp = W / H
    need = 0.0
    for x in (lo.x, hi.x):
        for y in (lo.y, hi.y):
            for z in (lo.z, hi.z):
                p = inv @ Vector((x, y, z))
                tx = abs(p.x) * lens / (sw / 2); ty = abs(p.y) * lens / (sw / 2 / asp)
                need = max(need, max(tx, ty) - (-p.z - 10.0))
    c.location = ctr + d * (need * margin)
    return c


# ---------------------------------------------------------------- materiais por passe

def _src(m):
    """Fonte da cor base de um material do kit: (soquete ligado | None, cor, emissivo)."""
    nt = m.node_tree
    p = next((n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED'), None)
    if p is None:
        return None, (0.5, 0.5, 0.5, 1), False
    b = p.inputs['Base Color']
    emis = p.inputs['Emission Strength'].default_value > 0.2
    col = tuple(p.inputs['Emission Color'].default_value) if emis else tuple(b.default_value)
    return (b.links[0].from_socket if b.is_linked else None), col, emis


def _math(nt, op, a, b=None, clamp=True):
    n = nt.nodes.new('ShaderNodeMath'); n.operation = op; n.use_clamp = clamp
    for i, v in enumerate((a, b)):
        if v is None:
            continue
        if isinstance(v, (int, float)):
            n.inputs[i].default_value = v
        else:
            nt.links.new(v, n.inputs[i])
    return n.outputs[0]


def _hatch(nt, angle, scale, duty):
    tc = nt.nodes.new('ShaderNodeTexCoord')
    mp = nt.nodes.new('ShaderNodeMapping')
    mp.inputs['Rotation'].default_value = (0, 0, math.radians(angle))
    mp.inputs['Scale'].default_value = (W / H, 1, 1)
    nt.links.new(tc.outputs['Window'], mp.inputs['Vector'])
    wv = nt.nodes.new('ShaderNodeTexWave'); wv.wave_type = 'BANDS'; wv.bands_direction = 'X'
    wv.inputs['Scale'].default_value = scale; wv.inputs['Distortion'].default_value = 0.6
    wv.inputs['Detail'].default_value = 1.0; wv.inputs['Detail Scale'].default_value = 0.6
    nt.links.new(mp.outputs[0], wv.inputs['Vector'])
    return _math(nt, 'GREATER_THAN', wv.outputs[1], 1.0 - duty)


def build_passes(hatch_scale=26.0):
    """Para cada material cria 3 emissões (ink, flat, light) e guarda as saídas em m['_passes']."""
    done = {}
    for o in meshes():
        for s in o.material_slots:
            m = s.material
            if m is None or m.name in done:
                continue
            nt = m.node_tree
            base, col, emis = _src(m)
            out = next(n for n in nt.nodes if n.type == 'OUTPUT_MATERIAL')
            # luz: difuso branco -> RGB -> cinza
            df = nt.nodes.new('ShaderNodeBsdfDiffuse'); df.inputs[0].default_value = (1, 1, 1, 1)
            s2 = nt.nodes.new('ShaderNodeShaderToRGB'); nt.links.new(df.outputs[0], s2.inputs[0])
            bw = nt.nodes.new('ShaderNodeRGBToBW'); nt.links.new(s2.outputs[0], bw.inputs[0])
            L = bw.outputs[0]
            # escuridão da própria cor (pupilas, bocas, buracos viram tinta cheia)
            if base is not None:
                cb = nt.nodes.new('ShaderNodeRGBToBW'); nt.links.new(base, cb.inputs[0]); lum = cb.outputs[0]
                dark_col = _math(nt, 'LESS_THAN', lum, 0.07)
            else:
                lumv = 0.2126 * col[0] + 0.7152 * col[1] + 0.0722 * col[2]
                dark_col = 1.0 if (lumv < 0.07 and not emis) else 0.0
            h1 = _hatch(nt, 38, hatch_scale, 0.42)
            h2 = _hatch(nt, -52, hatch_scale * 0.92, 0.40)
            mid = _math(nt, 'LESS_THAN', L, 0.58)
            drk = _math(nt, 'LESS_THAN', L, 0.24)
            blk = _math(nt, 'LESS_THAN', L, 0.035)
            ink = _math(nt, 'MULTIPLY', mid, h1)
            ink = _math(nt, 'MAXIMUM', ink, _math(nt, 'MULTIPLY', drk, h2))
            ink = _math(nt, 'MAXIMUM', ink, blk)
            ink = _math(nt, 'MAXIMUM', ink, dark_col)
            if emis:
                ink = 0.0
            g = _math(nt, 'SUBTRACT', 1.0, ink)
            e_ink = nt.nodes.new('ShaderNodeEmission')
            if isinstance(g, float):
                e_ink.inputs[0].default_value = (g, g, g, 1)
            else:
                nt.links.new(g, e_ink.inputs[0])
            e_flat = nt.nodes.new('ShaderNodeEmission')
            if base is not None and not emis:
                nt.links.new(base, e_flat.inputs[0])
            else:
                e_flat.inputs[0].default_value = (col[0], col[1], col[2], 1)
            e_light = nt.nodes.new('ShaderNodeEmission')
            if emis:
                e_light.inputs[0].default_value = (1, 0, 0, 1)   # emissivo: vermelho puro, para a composição reconhecer
            else:
                nt.links.new(L, e_light.inputs[0])
            done[m.name] = (m, out, {"ink": e_ink, "flat": e_flat, "light": e_light})
    return done


def set_pass(passes, name):
    for m, out, e in passes.values():
        m.node_tree.links.new(e[name].outputs[0], out.inputs['Surface'])


def freestyle(on, thickness=2.1):
    sc = bpy.context.scene
    sc.render.use_freestyle = on
    if not on:
        return
    sc.render.line_thickness_mode = 'ABSOLUTE'; sc.render.line_thickness = thickness
    fs = bpy.context.view_layer.freestyle_settings
    fs.crease_angle = math.radians(128)
    while len(fs.linesets) > 0:
        fs.linesets.remove(fs.linesets[0])
    ls = fs.linesets.new("ink")
    ls.select_silhouette = True; ls.select_border = True; ls.select_crease = True
    ls.select_material_boundary = True; ls.select_external_contour = True
    st = ls.linestyle
    st.color = (0, 0, 0); st.thickness = thickness
    # traço que engrossa e afina ao longo da linha, como pena
    mod = st.thickness_modifiers.new("along", 'ALONG_STROKE')
    mod.value_min = thickness * 0.45; mod.value_max = thickness * 1.25
    try:
        mod.mapping = 'CURVE'
    except Exception:
        pass


def _render(path):
    bpy.context.scene.render.filepath = path
    bpy.ops.render.render(write_still=True)


def _load(path):
    im = bpy.data.images.load(path, check_existing=False)
    a = np.empty(im.size[0] * im.size[1] * 4, dtype=np.float32); im.pixels.foreach_get(a)
    w, h = im.size
    bpy.data.images.remove(im)
    return a.reshape(h, w, 4)


def _save(arr, path):
    h, w, _ = arr.shape
    im = bpy.data.images.new("out", w, h, alpha=True)
    im.pixels.foreach_set(np.clip(arr, 0, 1).astype(np.float32).ravel())
    im.filepath_raw = path; im.file_format = 'PNG'; im.save()
    bpy.data.images.remove(im)


def _trim(arr, pad=0.04):
    a = arr[..., 3] > 0.03
    ys = np.where(a.any(axis=1))[0]; xs = np.where(a.any(axis=0))[0]
    if len(ys) == 0:
        return arr
    h, w = a.shape
    py = int(h * pad); px = int(w * pad)
    return arr[max(0, ys[0] - py):min(h, ys[-1] + py + 1), max(0, xs[0] - px):min(w, xs[-1] + px + 1)]


def render_card(out_dir, cid, kind="monster", hatch_scale=26.0, tmp=None):
    """Renderiza a cena atual e grava <cid>_v1.png, _v2.png, _v3.png em out_dir."""
    tmp = tmp or os.path.join(out_dir, "_tmp")
    os.makedirs(tmp, exist_ok=True); os.makedirs(out_dir, exist_ok=True)
    passes = build_passes(hatch_scale)
    p = {}
    for name in ("ink", "flat", "light"):
        set_pass(passes, name)
        freestyle(name == "ink")
        p[name] = os.path.join(tmp, "%s_%s.png" % (cid, name))
        _render(p[name])
    ink = _load(p["ink"]); flat = _load(p["flat"]); light = _load(p["light"])
    # tinta: cinza do passe composto sobre branco; a linha do Freestyle entra pelo alfa
    g = ink[..., 0] * ink[..., 3] + (1.0 - ink[..., 3]) if False else None
    a_obj = flat[..., 3]
    gray = np.where(ink[..., 3] > 0, ink[..., 0], 1.0)
    a_ink = np.clip((1.0 - gray) * np.maximum(ink[..., 3], 0.0), 0, 1)
    # a linha desenhada fora do objeto (contorno) tem alfa próprio e cinza 0
    a_ink = np.maximum(a_ink, np.clip(ink[..., 3] - a_obj, 0, 1) * (1.0 - gray))
    hot = ((light[..., 0] - light[..., 1]) > 0.5).astype(np.float32) * (light[..., 3] > 0.5)
    L = np.where(light[..., 3] > 0, light[..., 1], 1.0)
    L = np.where(hot > 0, 1.0, L)
    tint = np.array(INKS.get(kind, INKS["ink"]), dtype=np.float32)
    paper = np.array(PAPER, dtype=np.float32)

    # v1 — nanquim puro
    v1 = np.zeros_like(ink); v1[..., :3] = tint; v1[..., 3] = a_ink
    # v2 — aguada: cor do modelo dessaturada, clareada para o papel, modulada pela luz
    c = flat[..., :3]
    lum = (c * np.array([0.2126, 0.7152, 0.0722], dtype=np.float32)).sum(-1, keepdims=True)
    wash = c * 0.62 + lum * 0.38
    wash = wash * 0.70 + paper * 0.30
    wash = wash * (0.78 + 0.22 * np.clip(L, 0, 1))[..., None]
    wash = wash * (1 - hot[..., None]) + (c * 0.9 + paper * 0.1) * hot[..., None]   # fogo e brilho mantêm a cor viva
    aw = a_obj * 0.92
    v2 = np.zeros_like(ink)
    ai = a_ink[..., None]
    v2[..., :3] = wash * (1 - ai) + tint * 0.55 * ai
    v2[..., 3] = np.maximum(aw, a_ink)
    # v3 — duas tintas: preto-sépia + a cor do tipo chapada nas sombras, papel claro nas luzes
    ink3 = np.array(INKS["ink"], dtype=np.float32)
    shade = (L < 0.58).astype(np.float32)
    fill = paper * 1.04 * (1 - shade[..., None]) + (tint * 0.55 + paper * 0.45) * shade[..., None]
    # áreas emissivas (chama, olhos) recebem a cor quente de destaque
    fill = fill * (1 - hot[..., None]) + (c * 0.85 + paper * 0.15) * hot[..., None]
    v3 = np.zeros_like(ink)
    v3[..., :3] = fill * (1 - ai) + ink3 * ai
    v3[..., 3] = np.maximum(a_obj * 0.96, a_ink)
    for k, v in (("v1", v1), ("v2", v2), ("v3", v3)):
        _save(_trim(v), os.path.join(out_dir, "%s_%s.png" % (cid, k)))
