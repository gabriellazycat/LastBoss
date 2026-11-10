"""Exporta um modelo do kit (um grupo de objetos do Blender) para o jogo, no formato .lbm:
uma malha só, com a cor do material gravada nos vértices (alfa < 1 = brilho) e, se houver animação,
a posição e a normal de cada vértice em cada quadro (andar + ataque). tools/art/import_v2.gd lê o .lbm e
grava o ArrayMesh com a textura de animação (VAT) que game/art/look5.gdshader já toca.

Animação por partes rígidas: cada objeto tem o["bone"] (body, head, arm_l, arm_r, leg_l, leg_r, wing_l,
wing_r, tail, lid, weapon...) e a função de animação devolve, para cada quadro, a matriz de cada osso
(no espaço do Blender). Deformações macias (gosma, fantasma) vêm de um deform(p, ossos, t).

Eixos: Blender Z para cima e frente -Y  ->  Godot Y para cima e frente -Z: (x, y, z) -> (-x, z, y).
"""
import bpy, bmesh, json, math, random, struct
from mathutils import Matrix, Vector

WALK_FRAMES = 12
ATK_FRAMES = 8


def descendants(root):
    out = []
    q = [root]
    while q:
        x = q.pop()
        for o in x.children:
            out.append(o)
            q.append(o)
    return out


def _mat_info(m):
    """(cor base, usa cor do vértice, brilho 0..1, rugosidade do relevo) de um material do kit."""
    if m is None or not m.use_nodes:
        return (0.8, 0.8, 0.8), False, 0.0, 0.0
    nt = m.node_tree
    p = next((n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED'), None)
    if p is None:
        return (0.8, 0.8, 0.8), False, 0.0, 0.0
    vc = p.inputs['Base Color'].is_linked
    c = tuple(p.inputs['Base Color'].default_value[:3])
    e = p.inputs['Emission Strength'].default_value
    glow = min(1.0, e / 6.0) if e > 0 else 0.0
    if 0 < e < 1.0:
        glow = 0.12  # brilho dos olhos: só um ponto vivo
    met = p.inputs['Metallic'].default_value
    bump = 0.0
    if p.inputs['Normal'].is_linked:
        bump = 1.0
    # Metal sem reflexo de ambiente fica cinza chapado: clareia e satura um pouco o metal.
    if met > 0.5:
        c = tuple(min(1.0, x * 1.18 + 0.03) for x in c)
    return c, vc, glow, bump


def _srgb(x):
    x = max(0.0, min(1.0, x))
    return x * 12.92 if x <= 0.0031308 else 1.055 * x ** (1 / 2.4) - 0.055


# Correção de cor para a luz do jogo: a D tem sol forte (2.1) e tonemap filmic; as cores do kit, pensadas
# para o Cycles com AgX, saíam pastel. Escurece um pouco e satura (os CC0 da KayKit têm cor mais densa).
GRADE_GAIN = 0.8
GRADE_SAT = 1.3


def grade(c):
    l = 0.3 * c[0] + 0.59 * c[1] + 0.11 * c[2]
    return tuple(max(0.0, min(1.0, (l + (x - l) * GRADE_SAT) * GRADE_GAIN)) for x in c)


def _decimate(o, target):
    tris = sum(len(p.vertices) - 2 for p in o.data.polygons)
    if tris <= target:
        return
    m = o.modifiers.new("dec", 'DECIMATE')
    m.decimate_type = 'COLLAPSE'
    m.ratio = max(0.02, target / tris)
    m.use_collapse_triangulate = True


def bake_parts(root, budget, small=40):
    """Prepara as partes: aplica modificadores, reduz para o orçamento de triângulos, triangula.
    Devolve uma lista de partes: {obj, bone, verts(local), nrms(local), cols, idx}."""
    objs = [o for o in descendants(root) if o.type in ('MESH', 'CURVE') and not o.hide_render]
    for o in objs:
        if o.type == 'CURVE':
            bpy.context.view_layer.objects.active = o
            for x in bpy.context.selected_objects:
                x.select_set(False)
            o.select_set(True)
            bpy.ops.object.convert(target='MESH')
    objs = [o for o in descendants(root) if o.type == 'MESH' and not o.hide_render]
    dg = bpy.context.evaluated_depsgraph_get()
    # triângulos depois dos modificadores, para repartir o orçamento
    counts = {}
    for o in objs:
        me = o.evaluated_get(dg).to_mesh()
        counts[o.name] = sum(len(p.vertices) - 2 for p in me.polygons)
        o.evaluated_get(dg).to_mesh_clear()
    total = max(1, sum(counts.values()))
    ratio = min(1.0, budget / total)
    for o in objs:
        _decimate(o, max(small, int(counts[o.name] * ratio)))
    dg = bpy.context.evaluated_depsgraph_get()
    rng = random.Random(7)
    parts = []
    for o in objs:
        ev = o.evaluated_get(dg)
        me = ev.to_mesh()
        me.calc_loop_triangles()
        try:
            cn = me.corner_normals
            loop_n = [Vector(cn[i].vector) for i in range(len(me.loops))]
        except AttributeError:
            me.calc_normals_split()
            loop_n = [Vector(l.normal) for l in me.loops]
        ca = me.color_attributes.get("Col")
        mats = [_mat_info(m) for m in (me.materials or [None])]
        verts, nrms, cols, idx = [], [], [], []
        key = {}
        for tri in me.loop_triangles:
            info = mats[min(tri.material_index, len(mats) - 1)]
            for li in tri.loops:
                vi = me.loops[li].vertex_index
                n = loop_n[li] if tri.use_smooth else Vector(tri.normal)
                k = (vi, round(n.x, 3), round(n.y, 3), round(n.z, 3), tri.material_index)
                if k not in key:
                    key[k] = len(verts)
                    verts.append(Vector(me.vertices[vi].co))
                    nrms.append(n.normalized())
                    c, vc, glow, bump = info
                    if vc and ca is not None:
                        d = ca.data[vi].color if ca.domain == 'POINT' else ca.data[li].color
                        c = (d[0], d[1], d[2])
                    if bump:
                        j = 1.0 + (rng.random() - 0.5) * 0.08
                        c = tuple(x * j for x in c)
                    g = grade((_srgb(c[0]), _srgb(c[1]), _srgb(c[2])))
                    cols.append((g[0], g[1], g[2], 1.0 - glow))
                idx.append(key[k])
        parts.append({"obj": o, "bone": o.get("bone", "body"), "verts": verts, "nrms": nrms, "cols": cols, "idx": idx,
                      "mw": o.matrix_world.copy()})
        ev.to_mesh_clear()
    return parts


def _weights(parts, rig):
    """Pesos por vértice: rig(p_mundo, osso_da_parte) -> [(osso, peso)], ou o osso da parte com peso 1.
    Serve para corpos fundidos (o rato tem as patas no mesmo bloco do corpo).
    Devolve (V, N, bones, Wm, part_bone): posições e normais de repouso no mundo, a lista de ossos e a matriz
    de pesos (vértices x ossos), em numpy."""
    import numpy as np
    V, N, rows, pb = [], [], [], []
    for p in parts:
        mw = p["mw"]
        nm = mw.to_3x3().inverted().transposed()
        for v, n in zip(p["verts"], p["nrms"]):
            w0 = mw @ v
            V.append(tuple(w0))
            N.append(tuple((nm @ n).normalized()))
            if rig:
                r = rig(w0, p["bone"])
                tot = sum(w for _, w in r) or 1.0
                rows.append([(b, w / tot) for b, w in r if w > 1e-4])
            else:
                rows.append([(p["bone"], 1.0)])
            pb.append(p["bone"])
    bones = sorted({b for r in rows for b, _ in r})
    bi = {b: i for i, b in enumerate(bones)}
    Wm = np.zeros((len(rows), len(bones)), dtype=np.float64)
    for i, r in enumerate(rows):
        for b, w in r:
            Wm[i, bi[b]] += w
    return np.array(V, dtype=np.float64), np.array(N, dtype=np.float64), bones, Wm, pb


def _pose(parts, bones_m, deform=None, t=0.0, W=None):
    import numpy as np
    V, N, bones, Wm, pb = W
    P = np.zeros_like(V)
    NN = np.zeros_like(N)
    for i, b in enumerate(bones):
        col = Wm[:, i]
        if not col.any():
            continue
        M = bones_m.get(b, Matrix.Identity(4))
        R = np.array(M.to_3x3(), dtype=np.float64)
        T = np.array(M.translation, dtype=np.float64)
        P += col[:, None] * (V @ R.T + T)
        NN += col[:, None] * (N @ R.T)
    NN /= np.maximum(np.linalg.norm(NN, axis=1, keepdims=True), 1e-9)
    Pv = [Vector(x) for x in P]
    Nv = [Vector(x) for x in NN]
    if deform:
        for k in range(len(Pv)):
            Pv[k], Nv[k] = deform(Pv[k], Nv[k], pb[k], t)
    return Pv, Nv


def _to_godot(v):
    return (-v.x, v.z, v.y)


def export(root, path, height, budget=2500, anim=None, deform=None, rig=None, recenter=True):
    """anim(kind, t) -> {bone: Matrix} com kind em ('walk', 'atk') e t em 0..1; None = modelo parado.
    height: altura alvo em metros (como em import_cc0.gd); None = mantém a escala do Blender (1 m = 1 m)."""
    parts = bake_parts(root, budget)
    if deform and not anim:
        anim = lambda kind, t: {}
    W = _weights(parts, rig)
    rest, rest_n = _pose(parts, anim("walk", 0.0) if anim else {}, deform, 0.0, W)
    lo = Vector((min(v.x for v in rest), min(v.y for v in rest), min(v.z for v in rest)))
    hi = Vector((max(v.x for v in rest), max(v.y for v in rest), max(v.z for v in rest)))
    s = 1.0 if height is None else height / max(1e-6, hi.z - lo.z)
    c = Vector(((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, lo.z)) if recenter else Vector((0, 0, 0))

    def norm(v):
        return _to_godot((v - c) * s)

    cols, idx = [], []
    for p in parts:
        base = len(cols)
        cols += p["cols"]
        idx += [base + i for i in p["idx"]]
    frames = []
    if anim:
        for kind, nf in (("walk", WALK_FRAMES), ("atk", ATK_FRAMES)):
            for f in range(nf):
                t = f / nf if kind == "walk" else f / (nf - 1)
                P, N = _pose(parts, anim(kind, t), deform, t if kind == "walk" else 1.0 + t, W)
                frames.append(([norm(v) for v in P], [_to_godot(n) for n in N]))
    pos = [norm(v) for v in rest]
    nrm = [_to_godot(n) for n in rest_n]
    hdr = {"nv": len(pos), "ni": len(idx), "walk": WALK_FRAMES if anim else 0, "atk": ATK_FRAMES if anim else 0,
           "frames": len(frames)}
    with open(path, "wb") as f:
        f.write((json.dumps(hdr) + "\n").encode())
        f.write(struct.pack("<%df" % (len(pos) * 3), *[x for v in pos for x in v]))
        f.write(struct.pack("<%df" % (len(nrm) * 3), *[x for v in nrm for x in v]))
        f.write(struct.pack("<%df" % (len(cols) * 4), *[x for c4 in cols for x in c4]))
        f.write(struct.pack("<%di" % len(idx), *idx))
        for P, N in frames:
            f.write(struct.pack("<%df" % (len(P) * 3), *[x for v in P for x in v]))
            f.write(struct.pack("<%df" % (len(N) * 3), *[x for v in N for x in v]))
    print("lbm %s: %d vértices, %d tris, %d quadros" % (path, len(pos), len(idx) // 3, len(frames)))
    return hdr


# ---------------------------------------------------------------- ossos

def rot_about(pivot, axis, ang):
    """Matriz que gira ang (rad) em torno do eixo 'X'/'Y'/'Z' passando por pivot."""
    pv = Vector(pivot)
    return Matrix.Translation(pv) @ Matrix.Rotation(ang, 4, axis) @ Matrix.Translation(-pv)


def tr(x, y, z):
    return Matrix.Translation((x, y, z))


def tag(objs, bone):
    for o in objs:
        o["bone"] = bone
    return objs
