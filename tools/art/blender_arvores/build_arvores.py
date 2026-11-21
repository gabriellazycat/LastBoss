"""Árvores refeitas à mão (rodada do cenário com propósito, 21/11/2026): três estilos para o usuário escolher, cada um
com duas silhuetas ("tree" e "tree_round") e três atos (0 primavera, 1 outono, 2 terra amaldiçoada).
  1 tufos redondos (livro ilustrado): copa de 4-7 tufos grandes fundidos, tronco curto e grosso com raízes aparentes;
  2 alta/oval + pinheiro: "tree" = pinheiro de 3-4 saias largas e caídas, "tree_round" = árvore alta de copa oval;
  3 carvalho largo e torto: tronco torto que abre em 2-3 galhos grossos, copa larga e achatada em massas.
Regras do usuário: guache das cartas (formas grandes, cor chapada com variação suave, nada menor que ~5% da altura,
sem preto puro), silhueta legível da câmera alta (~50°); origem no pé do tronco, frente -Y; no máximo ~1200
triângulos por malha (centenas de instâncias num MultiMesh sem LOD); atlas de 512 px.

"C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --factory-startup -P tools/art/blender_arvores/build_arvores.py -- <saída> --estilo=N [--sheet=<png>]
Saída: <saída>/n/<id>_a<ato>.lbm e <saída>/tex/m2/<id>_a<ato>.png (como o build_m2). Depois:
  godot --headless --path . -s res://tools/art/import_g.gd -- --src=<saída> --m2 --out=res://assets/models/_arv_tmp/
  e mover _arv_tmp/m2_a/<x>.res e _arv_tmp/g_tex/m2/<x>.png para assets/models/arv<N>/ (ver tools/art/blender_arvores/fazer.sh).
--sheet: prancha das 6 malhas (lidas de volta do .lbm, com o atlas e as faces de trás escondidas) vistas de cima (~50°)
e de lado. No jogo: game/art/arvores.gd (--arvores=N)."""
import os, sys, math, random, json, traceback
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "blender_v2"))
sys.path.insert(0, os.path.join(HERE, "..", "blender_g"))
import bpy, bmesh
import numpy as np
from mathutils import Vector, noise
import mk
from mk import sph, setmat, paint, mix, smoothstep, apply_mods, shade, group, _sel
import vat, vat_g, treat

BUDGET = 1200
ATLAS = 512
# Graduação do cenário como a do build_m2 (MODELOS_GUACHE).
PULL, SAT, GAIN = 0.25, 1.45, 0.6
COOL = (0.30, 0.32, 0.42)


def L(c):
    """sRGB -> linear."""
    return tuple((x / 12.92) if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in c)


# Paletas por ato (sRGB). "tufts": uma cor por tufo (o tufo lê como mancha própria de cima).
PAL = {
    0: {"tufts": [(0.32, 0.54, 0.22), (0.48, 0.67, 0.26), (0.26, 0.48, 0.30), (0.54, 0.69, 0.27)],
        "light": (0.64, 0.80, 0.36), "dark": (0.20, 0.36, 0.22),
        "bark": (0.46, 0.31, 0.21), "bark_l": (0.60, 0.44, 0.30), "bark_d": (0.32, 0.22, 0.17)},
    1: {"tufts": [(0.90, 0.50, 0.18), (0.84, 0.64, 0.24), (0.72, 0.28, 0.17), (0.92, 0.60, 0.22)],
        "light": (0.98, 0.80, 0.42), "dark": (0.48, 0.22, 0.14),
        "bark": (0.44, 0.30, 0.21), "bark_l": (0.58, 0.42, 0.29), "bark_d": (0.30, 0.21, 0.16)},
    2: {"tufts": [(0.46, 0.36, 0.56), (0.56, 0.52, 0.62), (0.40, 0.32, 0.50), (0.52, 0.42, 0.60)],
        "light": (0.72, 0.64, 0.80), "dark": (0.28, 0.23, 0.36),
        "bark": (0.40, 0.35, 0.42), "bark_l": (0.56, 0.51, 0.58), "bark_d": (0.27, 0.23, 0.30)},
}
FLOWER, FLOWER_L = (0.95, 0.46, 0.60), (0.98, 0.72, 0.80)


# ------------------------------------------------------------------ ferramentas

def V(name):
    return mk.mat(name, vcol=True, rough=0.8)


def tris_of(o):
    return sum(len(p.vertices) - 2 for p in o.data.polygons)


def dec(o, target):
    apply_mods(o)
    t = tris_of(o)
    if t > target:
        m = o.modifiers.new("dec", 'DECIMATE')
        m.decimate_type = 'COLLAPSE'
        m.ratio = max(0.02, target / t)
        m.use_collapse_triangulate = True
        apply_mods(o)
    return o


def _new_obj(bm, name):
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(o)
    return o


def limb(pts, radii, seg=6, tip=True, flare=0.0, lobes=4, name="limb", twist=0.0):
    """Galho/tronco de poucos lados: anéis ao longo dos pontos (transporte paralelo, sem torção), ponta fechada.
    flare: o primeiro anel ganha `lobes` saliências (raízes aparentes) de amplitude flare*raio. Base aberta
    (fica enterrada ou dentro de outro galho)."""
    pts = [Vector(p) for p in pts]
    n = len(pts)
    bm = bmesh.new()
    rings = []
    u = None
    for i, p in enumerate(pts):
        t = (pts[min(i + 1, n - 1)] - pts[max(i - 1, 0)]).normalized()
        if u is None:
            ref = Vector((0, 0, 1)) if abs(t.z) < 0.9 else Vector((1, 0, 0))
            u = t.cross(ref).normalized()
        else:
            u = (u - t * u.dot(t)).normalized()
        v = t.cross(u)
        ring = []
        for k in range(seg):
            a = k / seg * math.tau + i * twist
            r = radii[i]
            if i == 0 and flare:
                r *= 1 + flare * max(0.0, math.cos(a * lobes)) ** 2
            ring.append(bm.verts.new(p + (u * math.cos(a) + v * math.sin(a)) * r))
        rings.append(ring)
    for i in range(n - 1):
        a, b = rings[i], rings[i + 1]
        for k in range(seg):
            bm.faces.new([a[k], a[(k + 1) % seg], b[(k + 1) % seg], b[k]])
    if tip:
        d = (pts[-1] - pts[-2]).normalized()
        tv = bm.verts.new(pts[-1] + d * radii[-1] * 0.9)
        top = rings[-1]
        for k in range(seg):
            bm.faces.new([top[k], top[(k + 1) % seg], tv])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    o = _new_obj(bm, name)
    shade(o, True)
    return o


def bark(o, P, seed=0):
    off = Vector((seed * 2.3, seed * 1.1, 0))
    b, bl, bd = L(P["bark"]), L(P["bark_l"]), L(P["bark_d"])

    def f(p, n):
        c = mix(bd, b, smoothstep(-0.6, 0.3, n.x * 0.6 - n.y * 0.5 + n.z * 0.4))
        c = mix(c, bl, smoothstep(0.35, 0.9, n.x * 0.6 - n.y * 0.5 + n.z * 0.4) * 0.8)
        k = noise.noise(p * 1.3 + off) * 0.5 + 0.5
        return mix(c, bd, smoothstep(0.55, 0.85, k) * 0.35)
    paint(o, f)
    setmat(o, V("v_bark_%s" % o.name))
    return o


def crown(blobs, P, target, voxel=0.14, seed=0, name="crown", lit=0.5, crease=0.45):
    """Copa: elipsoides (centro, raios, índice da cor) fundidos por voxel e reduzidos ao orçamento. Cada tufo leva
    a sua cor da paleta (mancha larga de cima), topo claro, baixo escuro frio."""
    o = mk.fuse([sph(c, 1, s, seg=16) for c, s, _ in blobs], name, voxel, smooth=0.5, iters=3)
    dec(o, target)
    shade(o, True)
    cols = [L(P["tufts"][ci % len(P["tufts"])]) for _, _, ci in blobs]
    light, dark = L(P["light"]), L(P["dark"])
    off = Vector((seed * 3.1, seed * 1.7, seed * 0.9))

    def f(p, n):
        ws, acc, wl = 0.0, [0.0, 0.0, 0.0], []
        for (c, s, _), col in zip(blobs, cols):
            d = math.sqrt(sum(((p[i] - c[i]) / s[i]) ** 2 for i in range(3)))
            w = math.exp(-6.0 * d * d)
            wl.append(w)
            ws += w
            for i in range(3):
                acc[i] += w * col[i]
        base = tuple(x / max(ws, 1e-9) for x in acc)
        if len(wl) > 1:  # vinco entre dois tufos: mais escuro, para cada tufo ler como mancha própria
            wl.sort(reverse=True)
            base = mix(base, dark, smoothstep(0.3, 0.85, wl[1] / max(wl[0], 1e-9)) * crease)
        k = noise.noise(p * 0.9 + off) * 0.5 + 0.5
        base = mix(base, light, (k - 0.5) * 0.35) if k > 0.5 else mix(base, dark, (0.5 - k) * 0.4)
        c = mix(base, light, smoothstep(0.35, 0.95, n.z) * lit)
        return mix(c, dark, smoothstep(0.05, -0.75, n.z) * 0.65)
    paint(o, f)
    setmat(o, V("v_%s" % name))
    return o


def flowers(spots, r=0.3, name="flower"):
    """Flores grandes (rosa, uma mais clara), achatadas e deitadas na copa: pontos de cor, nada fino."""
    out = []
    for k, (p, nrm) in enumerate(spots):
        o = sph(p, r, (1, 1, 0.45), seg=7)
        o.rotation_euler = Vector(nrm).to_track_quat('Z', 'Y').to_euler()
        _sel(o)
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
        shade(o, True)
        c = L(FLOWER_L if k % 3 == 2 else FLOWER)
        paint(o, lambda p_, n_, c=c: mix(mix(c, (0.0, 0.0, 0.0), 0.0), L((1.0, 0.9, 0.92)), smoothstep(0.6, 1.0, n_.z) * 0.25))
        setmat(o, V("v_%s%d" % (name, k)))
        out.append(o)
    return out


def on_blob(blob, az, el, push=0.92):
    """Ponto na superfície do elipsoide `blob` (direção az/el em graus) e a normal ali."""
    c, s, _ = blob
    a, e = math.radians(az), math.radians(el)
    d = Vector((math.cos(a) * math.cos(e), math.sin(a) * math.cos(e), math.sin(e)))
    p = Vector(c) + Vector((d.x * s[0], d.y * s[1], d.z * s[2])) * push
    nrm = Vector((d.x / s[0], d.y / s[1], d.z / s[2])).normalized()
    return p, nrm


def roots(n, r0, reach, z=0.35, seed=0, rot=0.0):
    rr = random.Random(seed)
    out = []
    for k in range(n):
        a = rot + k / n * math.tau + rr.uniform(-0.3, 0.3)
        d = Vector((math.cos(a), math.sin(a), 0))
        ln = reach * rr.uniform(0.85, 1.15)
        out.append(limb([d * r0 * 0.3 + Vector((0, 0, z)), d * (r0 * 0.6 + ln * 0.45) + Vector((0, 0, z * 0.35)),
                         d * (r0 * 0.6 + ln) + Vector((0, 0, -0.06))],
                        [r0 * 0.42, r0 * 0.3, r0 * 0.16], seg=5, tip=True, name="root"))
    return out


def wobble(pts, amp, seed, freq=1.3):
    """Desloca pontos de um galho de lado (torto), mantendo o primeiro."""
    out = [Vector(pts[0])]
    for i, p in enumerate(pts[1:], 1):
        p = Vector(p)
        out.append(p + Vector((noise.noise(p * freq + Vector((seed, 0, 0))), noise.noise(p * freq + Vector((0, seed, 0))), 0)) * amp)
    return out


# ------------------------------------------------------------------ estilo 1: tufos redondos (livro ilustrado)

def s1_tree(act, P):
    """Torre de tufos (brócolis de livro): 4 tufos em baixo, 2 em cima, tronco curto e grosso com raízes."""
    T = [limb([(0, 0, -0.08), (0.06, 0, 0.8), (0.0, 0.05, 1.6), (0.0, 0, 2.6)], [0.54, 0.44, 0.38, 0.3], seg=7,
              flare=0.45, lobes=4, tip=True, name="trunk")]
    T += roots(4, 0.54, 0.55, seed=act + 1, rot=0.4)
    blobs = [((0.0, 0.0, 3.85), (1.05, 1.0, 0.9), 0),
             ((0.9, 0.35, 2.95), (0.95, 0.9, 0.82), 1), ((-0.85, 0.45, 3.0), (0.9, 0.88, 0.8), 2),
             ((-0.35, -0.85, 2.9), (0.92, 0.9, 0.8), 3), ((0.6, -0.65, 3.4), (0.8, 0.78, 0.72), 2),
             ((-0.55, 0.1, 4.25), (0.7, 0.68, 0.6), 1)]
    if act == 1:  # mais rala: um tufo a menos, os outros menores, um galho aparece
        blobs = [(c, tuple(x * 0.9 for x in s), ci) for c, s, ci in blobs if ci != 3] + [((-0.4, -0.75, 2.85), (0.62, 0.6, 0.55), 3)]
        T.append(limb([(0, 0, 2.2), (-0.55, -0.6, 2.7), (-0.75, -1.05, 3.0)], [0.17, 0.13, 0.09], seg=5, name="br"))
    if act == 2:
        return s1_cursed(P, T, tall=True)
    tgt = BUDGET - sum(tris_of(t) for t in T) - (120 if act == 0 else 0)
    C = crown(blobs, P, tgt, voxel=0.15, seed=act * 7 + 1)
    parts = T + [C]
    if act == 0:
        parts += flowers([on_blob(blobs[0], 30, 55), on_blob(blobs[1], 10, 35), on_blob(blobs[3], 250, 40),
                          on_blob(blobs[2], 150, 45), on_blob(blobs[5], 200, 60)])
    return group("tree", parts)


def s1_round(act, P):
    """Monte largo e baixo de 5 tufos em volta de um maior, tronco curto com raízes aparentes."""
    T = [limb([(0, 0, -0.08), (-0.05, 0, 0.7), (0.05, 0.0, 1.4), (0.0, 0, 2.0)], [0.58, 0.47, 0.4, 0.32], seg=7,
              flare=0.5, lobes=5, tip=True, name="trunk")]
    T += roots(5, 0.58, 0.6, seed=act + 11, rot=1.0)
    blobs = [((0.0, 0.0, 3.05), (1.3, 1.25, 1.05), 0),
             ((1.15, 0.2, 2.55), (0.85, 0.82, 0.75), 1), ((-1.05, 0.55, 2.6), (0.88, 0.85, 0.75), 3),
             ((0.35, 1.1, 2.6), (0.8, 0.8, 0.72), 2), ((-0.5, -1.05, 2.5), (0.85, 0.82, 0.72), 1),
             ((0.75, -0.85, 2.75), (0.72, 0.7, 0.66), 2)]
    if act == 1:
        blobs = [(c, tuple(x * 0.9 for x in s), ci) for k, (c, s, ci) in enumerate(blobs) if k != 3]
        T.append(limb([(0, 0, 1.7), (0.35, 0.8, 2.3), (0.5, 1.2, 2.55)], [0.17, 0.13, 0.09], seg=5, name="br"))
    if act == 2:
        return s1_cursed(P, T, tall=False)
    tgt = BUDGET - sum(tris_of(t) for t in T) - (120 if act == 0 else 0)
    C = crown(blobs, P, tgt, voxel=0.15, seed=act * 7 + 2)
    parts = T + [C]
    if act == 0:
        parts += flowers([on_blob(blobs[0], 60, 50), on_blob(blobs[1], 340, 40), on_blob(blobs[2], 170, 40),
                          on_blob(blobs[4], 260, 45), on_blob(blobs[0], 220, 65)])
    return group("tree_round", parts)


def s1_cursed(P, T, tall):
    """Terra amaldiçoada. tree: o tronco sobe e abre em 3 galhos grossos e tortos, cada um com uma massa roxa achatada
    (duas bolas fundidas, de tamanhos diferentes). tree_round: a cúpula de antes, rasgada: 3 massas baixas com
    buracos entre elas e um galho seco espetado para cima."""
    blobs = []
    if tall:
        z0 = 2.0
        ends = [((1.3, 0.3, 3.75), 0.72), ((-1.15, 0.7, 3.95), 0.6), ((0.1, -1.15, 4.25), 0.5)]
        for k, (e, sz) in enumerate(ends):
            e = Vector(e)
            mid = Vector((e.x * 0.45, e.y * 0.45, z0 + (e.z - z0) * 0.45)) + Vector((0.15, -0.1, 0.25)) * (1 if k % 2 else -1)
            T.append(limb([Vector((0, 0, z0 - 0.4)), mid, e], [0.24, 0.18, 0.13], seg=6, tip=True, name="br%d" % k))
            sp = mid + (e - mid) * 0.4
            T.append(limb([sp, sp + Vector((-e.y, e.x, 0)).normalized() * 0.5 + Vector((0, 0, 0.45))], [0.12, 0.08], seg=5, name="sp%d" % k))
            d = Vector((e.x, e.y, 0)).normalized()
            blobs.append(((e.x + d.x * 0.15, e.y + d.y * 0.15, e.z + 0.22), (sz * 1.1, sz, sz * 0.82), k))
            blobs.append(((e.x - d.y * sz * 0.6, e.y + d.x * sz * 0.6, e.z + 0.02), (sz * 0.72, sz * 0.68, sz * 0.62), k + 1))
    else:
        z0 = 1.7
        ends = [((1.35, 0.25, 2.75), 0.85), ((-1.05, 0.85, 2.85), 0.75), ((-0.35, -1.2, 2.7), 0.7)]
        for k, (e, sz) in enumerate(ends):
            e = Vector(e)
            mid = Vector((e.x * 0.5, e.y * 0.5, z0 + 0.5))
            T.append(limb([Vector((0, 0, z0 - 0.4)), mid, e], [0.26, 0.2, 0.15], seg=6, tip=True, name="br%d" % k))
            blobs.append(((e.x, e.y, e.z + 0.25), (sz * 1.2, sz * 1.05, sz * 0.6), k))
            blobs.append(((e.x * 0.6, e.y * 0.6, e.z + 0.55), (sz * 0.75, sz * 0.7, sz * 0.5), k + 1))
        # galho seco espetado no meio da cúpula rasgada
        T.append(limb([Vector((0, 0, z0 - 0.3)), Vector((0.25, -0.1, 2.9)), Vector((0.15, 0.1, 3.75))], [0.22, 0.15, 0.1], seg=6, name="sp0"))
        T.append(limb([Vector((0.22, -0.08, 3.0)), Vector((0.75, -0.2, 3.55))], [0.11, 0.08], seg=5, name="sp1"))
    tgt = BUDGET - sum(tris_of(t) for t in T)
    C = crown(blobs, P, tgt, voxel=0.13, seed=31, crease=0.3)
    return group("tree" if tall else "tree_round", T + [C])


# ------------------------------------------------------------------ estilo 2: pinheiro em camadas + árvore alta oval

def skirt(apex, R, h, P, ci, seg=18, lobes=6, ragged=0.08, droop=0.25, name="skirt", seed=0):
    """Saia do pinheiro: cone largo e caído, borda em lóbulos que pendem; por baixo, um fundo raso até o tronco."""
    rr = random.Random(seed)
    ax, ay, az = apex
    bm = bmesh.new()
    top = bm.verts.new((ax, ay, az))
    prof = [(0.33, 0.0), (0.68, 0.0), (1.0, 0.0)]
    rings = []
    jit = [rr.uniform(-1, 1) for _ in range(lobes)]
    for t, _ in prof:
        ring = []
        for k in range(seg):
            a = k / seg * math.tau + seed
            lob = math.cos(a * lobes) * 0.5 + 0.5
            li = int(round(k / seg * lobes)) % lobes
            r = R * t * (1 + (ragged * (lob - 0.5) * 2 + ragged * 0.6 * jit[li]) * t)
            z = az - h * (0.3 * t + 0.7 * t * t) - droop * h * lob * t ** 3
            ring.append(bm.verts.new((ax + math.cos(a) * r, ay + math.sin(a) * r, z)))
        rings.append(ring)
    # lábio e fundo
    rim = rings[-1]
    lip = [bm.verts.new((ax + (v.co.x - ax) * 0.9, ay + (v.co.y - ay) * 0.9, v.co.z - 0.06)) for v in rim]
    under = [bm.verts.new((ax + (v.co.x - ax) * 0.3, ay + (v.co.y - ay) * 0.3, az - h * 0.55)) for v in rim]
    for k in range(seg):
        bm.faces.new([top, rings[0][k], rings[0][(k + 1) % seg]])
    allr = rings + [lip, under]
    for i in range(len(allr) - 1):
        a, b = allr[i], allr[i + 1]
        for k in range(seg):
            bm.faces.new([a[k], b[k], b[(k + 1) % seg], a[(k + 1) % seg]])
    cv = bm.verts.new((ax, ay, az - h * 0.5))
    for k in range(seg):
        bm.faces.new([under[k], cv, under[(k + 1) % seg]])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    o = _new_obj(bm, name)
    shade(o, True)
    col = L(P["tufts"][ci % len(P["tufts"])])
    light, dark = L(P["light"]), L(P["dark"])

    def f(p, n):
        c = mix(col, light, smoothstep(0.3, 0.95, n.z) * 0.45)
        c = mix(c, dark, smoothstep(0.0, -0.7, n.z) * 0.7)
        k = noise.noise(p * 1.1 + Vector((seed, 0, 0))) * 0.5 + 0.5
        return mix(c, light, smoothstep(0.62, 0.85, k) * 0.2)
    paint(o, f)
    setmat(o, V("v_%s" % name))
    return o


def s2_tree(act, P):
    """Pinheiro estilizado: 4 saias largas e caídas (3 no outono, 3 rasgadas na terra amaldiçoada)."""
    T = [limb([(0, 0, -0.08), (0, 0, 1.2), (0, 0, 2.6), (0.0, 0, 4.3)], [0.30, 0.25, 0.19, 0.12], seg=6, flare=0.3,
              lobes=3, tip=True, name="trunk")]
    if act == 0:
        L_ = [((0, 0, 2.55), 2.0, 1.55, 0), ((0, 0, 3.45), 1.6, 1.25, 1), ((0, 0, 4.3), 1.18, 1.05, 0), ((0, 0, 5.1), 0.72, 0.95, 3)]
        S = [skirt(a, R, h, P, ci, ragged=0.07, droop=0.22, name="sk%d" % i, seed=i * 1.3) for i, (a, R, h, ci) in enumerate(L_)]
    elif act == 1:  # lariço de outono: 3 saias, mais espaçadas e recortadas (mais rala)
        L_ = [((0, 0, 2.5), 1.9, 1.3, 0), ((0, 0, 3.6), 1.45, 1.1, 1), ((0, 0, 4.75), 0.95, 1.05, 2)]
        S = [skirt(a, R, h, P, ci, ragged=0.16, droop=0.3, name="sk%d" % i, seed=i * 1.7 + 2) for i, (a, R, h, ci) in enumerate(L_)]
        T.append(limb([(0, 0, 1.0), (0.55, -0.3, 1.25), (0.85, -0.45, 1.25)], [0.12, 0.09, 0.07], seg=5, name="stub"))
    else:  # amaldiçoado: 3 saias rasgadas e caídas, sem a de baixo (o tronco e dois tocos aparecem), ponta seca
        L_ = [((0, 0, 3.0), 1.65, 1.35, 0), ((0, 0, 3.95), 1.25, 1.15, 1), ((0, 0, 4.75), 0.8, 0.95, 2)]
        S = [skirt(a, R, h, P, ci, seg=16, lobes=5, ragged=0.3, droop=0.45, name="sk%d" % i, seed=i * 2.1 + 5)
             for i, (a, R, h, ci) in enumerate(L_)]
        T.append(limb([(0, 0, 1.2), (0.6, 0.2, 1.65), (1.0, 0.35, 2.2)], [0.13, 0.1, 0.08], seg=5, name="stub1"))
        T.append(limb([(0, 0, 1.0), (-0.55, -0.35, 1.3), (-1.0, -0.5, 1.6)], [0.13, 0.1, 0.08], seg=5, name="stub2"))
        T.append(limb([(0, 0, 4.5), (0.08, 0.05, 4.95), (0.2, 0.0, 5.25)], [0.12, 0.09, 0.07], seg=5, name="spike"))
    for t in T:
        bark(t, P, 3)
    return group("tree", T + S)


def s2_round(act, P):
    """Árvore alta de copa oval (álamo/cipreste largo): um oval lombudo sobre um tronco curto."""
    T = [limb([(0, 0, -0.08), (0, 0, 0.9), (0.0, 0, 2.2)], [0.30, 0.25, 0.2], seg=6, flare=0.35, lobes=4, tip=True, name="trunk")]
    if act == 2:
        # o oval rachou: o tronco abre em V, cada metade leva uma chama roxa alongada (alturas diferentes) e a
        # ponta de uma delas fica seca, espetada para cima
        T.append(limb([(0, 0, 1.6), (0.55, 0.1, 2.5), (0.9, 0.15, 3.3), (0.95, 0.1, 3.9)], [0.2, 0.16, 0.12, 0.09], seg=6, name="b1"))
        T.append(limb([(0, 0, 1.6), (-0.5, -0.1, 2.4), (-0.75, -0.15, 3.4), (-0.7, -0.05, 5.0)], [0.2, 0.16, 0.12, 0.09], seg=6, name="b2"))
        T.append(limb([(-0.73, -0.13, 3.9), (-1.15, -0.2, 4.35)], [0.1, 0.08], seg=5, name="b3"))
        blobs = [((1.0, 0.12, 3.45), (0.55, 0.52, 1.05), 0), ((1.15, 0.35, 2.85), (0.38, 0.36, 0.45), 1),
                 ((-0.78, -0.12, 2.85), (0.48, 0.46, 0.75), 3), ((-0.95, -0.35, 2.55), (0.34, 0.32, 0.4), 1)]
    else:
        # oval lombudo: um núcleo mais estreito e lombos grandes saindo da superfície (cada um lê como pincelada)
        blobs = [((0, 0, 3.2), (1.0, 0.98, 1.95), 0),
                 ((0.75, 0.2, 2.25), (0.78, 0.72, 0.85), 1), ((-0.7, -0.35, 2.55), (0.75, 0.72, 0.9), 2),
                 ((0.2, 0.78, 2.9), (0.68, 0.62, 0.85), 3), ((0.45, -0.65, 3.35), (0.65, 0.6, 0.85), 2),
                 ((-0.55, 0.45, 3.85), (0.62, 0.6, 0.8), 1), ((0.15, -0.1, 4.5), (0.62, 0.6, 0.7), 3)]
        if act == 1:  # outono: dourado, mais estreito, um lombo a menos
            blobs = [((0, 0, 3.15), (0.92, 0.9, 1.9), 0),
                     ((0.72, 0.25, 2.15), (0.68, 0.64, 0.8), 1), ((-0.65, -0.35, 2.7), (0.66, 0.64, 0.85), 2),
                     ((0.4, -0.6, 3.45), (0.58, 0.55, 0.8), 3), ((-0.45, 0.45, 3.95), (0.56, 0.55, 0.75), 1),
                     ((0.1, -0.05, 4.45), (0.55, 0.52, 0.62), 2)]
    tgt = BUDGET - sum(tris_of(t) for t in T)
    C = crown(blobs, P, tgt, voxel=0.13, seed=act * 5 + 9, lit=0.4, crease=0.6)
    for t in T:
        bark(t, P, 4)
    return group("tree_round", T + [C])


# ------------------------------------------------------------------ estilo 3: carvalho largo e torto

def s3_build(P, act, trunk_pts, trunk_r, branches, masses, name, seed, dead_forks=False):
    T = [limb(trunk_pts, trunk_r, seg=7, flare=0.35, lobes=4, tip=True, name="trunk")]
    T += roots(4, trunk_r[0], 0.45, seed=seed, rot=0.7)
    split = Vector(trunk_pts[-2])
    for k, (mid, end, r) in enumerate(branches):
        T.append(limb([split, Vector(mid), Vector(end)], [r, r * 0.75, r * 0.55], seg=6, tip=True, name="br%d" % k))
        if dead_forks and not any((Vector(c) - Vector(end)).length < 0.9 for c, _, _ in masses):  # galho seco: um garfo curto e grosso na ponta, virado para cima
            e, m = Vector(end), Vector(mid)
            d = (e - m).normalized()
            side = Vector((-d.y, d.x, 0)).normalized()
            for sgn in (1, -1):
                T.append(limb([e - d * 0.25, e + side * 0.45 * sgn + d * 0.3 + Vector((0, 0, 0.45))],
                              [r * 0.5, r * 0.32], seg=5, name="fk"))
    tgt = BUDGET - sum(tris_of(t) for t in T)
    parts = list(T)
    if masses:
        parts.append(crown(masses, P, tgt, voxel=0.15, seed=seed * 3, lit=0.55))
    for t in T:
        bark(t, P, seed)
    return group(name, parts)


def s3_tree(act, P):
    """Carvalho largo e achatado: tronco torto que abre em 3 galhos grossos; copa de 4-5 massas chatas."""
    tr = [(0, 0, -0.08), (0.25, 0.05, 0.7), (0.0, 0.1, 1.35), (0.15, 0.05, 1.75)]
    rr = [0.46, 0.38, 0.34, 0.3]
    br = [((0.95, 0.25, 2.3), (1.75, 0.35, 2.85), 0.24), ((-0.75, 0.45, 2.4), (-1.65, 0.55, 2.9), 0.23),
          ((0.2, -0.75, 2.45), (0.15, -1.5, 3.05), 0.22)]
    ms = [((1.65, 0.35, 3.3), (1.35, 1.2, 0.72), 0), ((-1.55, 0.6, 3.35), (1.3, 1.2, 0.72), 1),
          ((0.15, -1.35, 3.45), (1.25, 1.05, 0.68), 2), ((0.1, 0.35, 3.75), (1.35, 1.3, 0.72), 3),
          ((0.75, 1.25, 3.4), (0.95, 0.85, 0.6), 2)]
    if act == 1:
        ms = [(c, (s[0] * 0.9, s[1] * 0.9, s[2] * 0.9), ci) for k, (c, s, ci) in enumerate(ms) if k != 4]
        return s3_build(P, act, tr, rr, br, ms, "tree", 21)
    if act == 2:
        br = [((0.95, 0.2, 2.25), (1.7, 0.4, 3.0), 0.24), ((-0.8, 0.45, 2.35), (-1.6, 0.6, 3.1), 0.23),
              ((0.25, -0.75, 2.5), (0.1, -1.45, 3.25), 0.22)]
        ms = [((-1.7, 0.65, 3.4), (0.78, 0.68, 0.48), 0), ((-1.2, 0.95, 3.25), (0.5, 0.46, 0.38), 1),
              ((1.75, 0.45, 3.3), (0.62, 0.58, 0.42), 1), ((2.05, 0.15, 3.2), (0.4, 0.38, 0.32), 0)]
        return s3_build(P, act, tr, rr, br, ms, "tree", 23, dead_forks=True)
    return s3_build(P, act, tr, rr, br, ms, "tree", 20)


def s3_round(act, P):
    """Carvalho torto e inclinado: o tronco pende para um lado e abre em 2 galhos; copa em 3 massas amontoadas."""
    tr = [(0, 0, -0.08), (-0.2, 0.0, 0.7), (0.15, 0.05, 1.3), (0.45, 0.0, 1.85)]
    rr = [0.44, 0.36, 0.32, 0.28]
    br = [((1.25, 0.15, 2.55), (1.45, 0.25, 3.25), 0.23), ((-0.1, 0.35, 2.75), (-0.75, 0.45, 3.4), 0.22)]
    ms = [((1.25, 0.2, 3.55), (1.3, 1.25, 0.95), 0), ((-0.75, 0.35, 3.75), (1.2, 1.15, 0.9), 1),
          ((0.3, -0.25, 4.25), (1.05, 1.0, 0.75), 3)]
    if act == 1:
        ms = [((1.25, 0.2, 3.5), (1.12, 1.05, 0.85), 0), ((-0.75, 0.35, 3.7), (1.05, 1.0, 0.8), 2),
              ((0.35, -0.3, 4.15), (0.85, 0.8, 0.62), 1)]
        return s3_build(P, act, tr, rr, br, ms, "tree_round", 31)
    if act == 2:
        br = [((1.2, 0.1, 2.5), (1.55, 0.25, 3.35), 0.23), ((-0.1, 0.35, 2.7), (-0.85, 0.5, 3.45), 0.22)]
        ms = [((1.6, 0.3, 3.6), (0.8, 0.7, 0.5), 0), ((1.95, 0.0, 3.45), (0.5, 0.46, 0.38), 1)]
        return s3_build(P, act, tr, rr, br, ms, "tree_round", 33, dead_forks=True)
    return s3_build(P, act, tr, rr, br, ms, "tree_round", 30)


def _with_bark(fn):
    """Estilo 1: o tronco e as raízes ganham a cor da casca depois de montados."""
    def g(act, P):
        root = fn(act, P)
        for o in vat.descendants(root):
            nm = o.name.split(".")[0]
            if o.type == 'MESH' and nm in ("trunk", "root", "br", "sp0", "sp1", "sp2", "br0", "br1", "br2"):
                bark(o, P, 1)
        return root
    return g


STYLES = {
    1: {"tree": _with_bark(s1_tree), "tree_round": _with_bark(s1_round)},
    2: {"tree": s2_tree, "tree_round": s2_round},
    3: {"tree": s3_tree, "tree_round": s3_round},
}


# ------------------------------------------------------------------ exportação

def one(style, i, act, out):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    mk._MATS.clear()
    root = STYLES[style][i](act, PAL[act])
    objs = vat_g.prepare(root, BUDGET)
    grade = treat.make_grade("scenery", pull=PULL, lift=0.04, sat=SAT, gain=GAIN)
    os.makedirs(os.path.join(out, "n"), exist_ok=True)
    name = "%s_a%d" % (i, act)
    d = vat_g.export(root, os.path.join(out, "n", name + ".lbm"), None, objs, grade, None, None, None, recenter=False)
    C, Pp, N, Mk = treat.raster(d, ATLAS)
    img = treat.treat("dry", C, Pp, N, d["height"], COOL)
    td = os.path.join(out, "tex", "m2")
    os.makedirs(td, exist_ok=True)
    treat.save_png(img, os.path.join(td, name + ".png"))
    w = max(d["pos"][:, 0].max() - d["pos"][:, 0].min(), d["pos"][:, 2].max() - d["pos"][:, 2].min())
    print("ARV estilo%d %s: %d tris, altura %.2f m, largura %.2f m" % (style, name, len(d["idx"]), d["height"], w))
    return name, len(d["idx"]), d["height"], w


# ------------------------------------------------------------------ prancha (lida de volta do .lbm)

def read_lbm(path, png, loc):
    with open(path, "rb") as f:
        hdr = json.loads(f.readline())
        nv, ni = hdr["nv"], hdr["ni"]
        P = np.frombuffer(f.read(nv * 12), "<f4").reshape(-1, 3)
        N = np.frombuffer(f.read(nv * 12), "<f4").reshape(-1, 3)
        f.read(nv * 16)
        UV = np.frombuffer(f.read(nv * 8), "<f4").reshape(-1, 2)
        I = np.frombuffer(f.read(ni * 4), "<i4").reshape(-1, 3)
    # Godot (x, y, z) = (-bx, bz, by)  ->  Blender (bx, by, bz) = (-gx, gz, gy)
    vb = [(-p[0] + loc[0], p[2] + loc[1], p[1]) for p in P]
    me = bpy.data.meshes.new(os.path.basename(path))
    me.from_pydata(vb, [], [tuple(int(x) for x in t) for t in I])
    me.update()
    uvl = me.uv_layers.new(name="UVMap")
    for poly in me.polygons:
        poly.use_smooth = True
        for li in poly.loop_indices:
            vi = me.loops[li].vertex_index
            uvl.data[li].uv = (float(UV[vi][0]), float(UV[vi][1]))
    try:
        me.normals_split_custom_set_from_vertices([(-n[0], n[2], n[1]) for n in N])
    except Exception:
        pass
    o = bpy.data.objects.new(os.path.basename(path), me)
    bpy.context.scene.collection.objects.link(o)
    m = bpy.data.materials.new("m_" + os.path.basename(png))
    m.use_nodes = True
    m.use_backface_culling = True  # winding invertido apareceria como buraco
    nt = m.node_tree
    p = next(n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED')
    tx = nt.nodes.new('ShaderNodeTexImage')
    tx.image = bpy.data.images.load(png)
    tx.image.colorspace_settings.name = 'sRGB'
    nt.links.new(tx.outputs[0], p.inputs['Base Color'])
    p.inputs['Roughness'].default_value = 0.95
    me.materials.append(m)
    return o


def sheet(out, names, path, style):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    for eng in ('BLENDER_EEVEE', 'BLENDER_EEVEE_NEXT'):
        try:
            sc.render.engine = eng
            break
        except TypeError:
            pass
    sc.view_settings.view_transform = 'Standard'
    w = bpy.data.worlds.new("W")
    sc.world = w
    w.use_nodes = True
    bg = next(n for n in w.node_tree.nodes if n.type == 'BACKGROUND')
    bg.inputs[0].default_value = (0.55, 0.6, 0.62, 1)
    bg.inputs[1].default_value = 0.8
    sun = bpy.data.lights.new("Sun", 'SUN')
    sun.energy = 3.4
    so = bpy.data.objects.new("Sun", sun)
    sc.collection.objects.link(so)
    so.rotation_euler = (math.radians(38), math.radians(8), math.radians(-35))
    sp = 6.2
    xs = [(k - (len(names) - 1) / 2) * sp for k in range(len(names))]
    for x, nm in zip(xs, names):
        read_lbm(os.path.join(out, "n", nm + ".lbm"), os.path.join(out, "tex", "m2", nm + ".png"), (x, 0))
        cu = bpy.data.curves.new("t", 'FONT')
        cu.body = nm
        cu.size = 0.55
        cu.align_x = 'CENTER'
        t = bpy.data.objects.new("t", cu)
        sc.collection.objects.link(t)
        t.location = (x, -3.0, 0.02)
        tm = bpy.data.materials.new("tm")
        tm.use_nodes = True
        next(n for n in tm.node_tree.nodes if n.type == 'BSDF_PRINCIPLED').inputs['Base Color'].default_value = (0.95, 0.92, 0.8, 1)
        cu.materials.append(tm)
    gd = bpy.data.meshes.new("ground")
    bm = bmesh.new()
    bmesh.ops.create_grid(bm, x_segments=1, y_segments=1, size=120)
    bm.to_mesh(gd)
    bm.free()
    g = bpy.data.objects.new("ground", gd)
    sc.collection.objects.link(g)
    gm = bpy.data.materials.new("gm")
    gm.use_nodes = True
    next(n for n in gm.node_tree.nodes if n.type == 'BSDF_PRINCIPLED').inputs['Base Color'].default_value = (*L((0.45, 0.5, 0.25)), 1)
    gd.materials.append(gm)
    cd = bpy.data.cameras.new("C")
    cd.type = 'ORTHO'
    cam = bpy.data.objects.new("C", cd)
    sc.collection.objects.link(cam)
    sc.camera = cam
    W = len(names) * sp
    shots = []
    for el, zc, hpx in ((50, 1.6, 760), (8, 2.6, 640)):
        sc.render.resolution_x, sc.render.resolution_y = 2400, hpx
        cd.ortho_scale = W
        e = math.radians(el)
        ctr = Vector((0, 0, zc))
        cam.location = ctr + Vector((0, -math.cos(e), math.sin(e))) * 60
        cam.rotation_euler = (ctr - cam.location).to_track_quat('-Z', 'Y').to_euler()
        fp = path[:-4] + "_%d.png" % el
        sc.render.filepath = fp
        bpy.ops.render.render(write_still=True)
        shots.append(fp)
    ims = [bpy.data.images.load(fp) for fp in shots]
    arrs = [np.array(im.pixels[:], dtype=np.float32).reshape(im.size[1], im.size[0], 4) for im in ims]
    full = np.concatenate([arrs[1], arrs[0]], axis=0)  # pixels de baixo para cima: lado em baixo, cima no alto
    out_im = bpy.data.images.new("sheet", full.shape[1], full.shape[0], alpha=False)
    out_im.pixels.foreach_set(full.ravel())
    out_im.filepath_raw = path
    out_im.file_format = 'PNG'
    out_im.save()
    for fp in shots:
        os.remove(fp)
    print("PRANCHA", path)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:]
    out = os.path.abspath(argv[0])
    style = int(next(a.split("=", 1)[1] for a in argv if a.startswith("--estilo=")))
    sh = next((os.path.abspath(a.split("=", 1)[1]) for a in argv if a.startswith("--sheet=")), None)
    names, rep = [], []
    for i in ("tree", "tree_round"):
        for act in (0, 1, 2):
            try:
                r = one(style, i, act, out)
                names.append(r[0])
                rep.append(r)
            except Exception:
                print("FALHOU", i, act)
                traceback.print_exc()
    with open(os.path.join(out, "relatorio_estilo%d.txt" % style), "w") as f:
        for r in rep:
            f.write("%s\t%d tris\t%.2f m alt\t%.2f m larg\n" % r)
    if sh:
        os.makedirs(os.path.dirname(sh), exist_ok=True)
        sheet(out, names, sh, style)


main()
