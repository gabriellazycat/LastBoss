"""Exportação da rodada "miniaturas pintadas" (15/11/2026): como tools/art/blender_v2/vat.py, mais:
  - simplify(): tira do modelo o que é miúdo demais para a câmera do jogo (a regra: nada de detalhe pequeno);
  - prepare(): aplica os modificadores, reduz para o orçamento, opcionalmente deixa facetado, e desdobra a UV
    de todas as partes juntas num atlas só;
  - export(): grava o .lbm com UV, e devolve os dados que o atlas (treat.py) precisa.
Formato do .lbm: o do v2, com "uv": 1 no cabeçalho e, depois das cores, 2 floats de UV por vértice."""
import bpy, json, math, struct
import numpy as np
from mathutils import Vector, Matrix
import mk, vat
from vat import _mat_info, _srgb, descendants, _weights, _pose, _to_godot, WALK_FRAMES, ATK_FRAMES


def _world_bbox(o):
    pts = [o.matrix_world @ Vector(c) for c in o.bound_box]
    lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    return lo, hi


def simplify(root, small=0.055, human=False, keep=()):
    """Apaga o que mede menos que `small` da maior dimensão do modelo: reflexos dos olhos, sobrancelhas, dentes,
    bigodes, fivelas. Os olhos das criaturas ficam (estilizados, como nas cartas); humanos não têm olhos."""
    bpy.context.view_layer.update()
    objs = [o for o in descendants(root) if o.type == 'MESH']
    los, his = [], []
    for o in objs:
        lo, hi = _world_bbox(o)
        los.append(lo)
        his.append(hi)
    if not objs:
        return 0
    big = max(max(h.x - l.x, h.y - l.y, h.z - l.z) for l, h in zip(los, his))
    # altura total do modelo, não da maior peça: a régua é o modelo inteiro
    gl = Vector((min(l.x for l in los), min(l.y for l in los), min(l.z for l in los)))
    gh = Vector((max(h.x for h in his), max(h.y for h in his), max(h.z for h in his)))
    size = max(gh.x - gl.x, gh.y - gl.y, gh.z - gl.z, 1e-6)
    gone = 0
    for o, lo, hi in zip(objs, los, his):
        mats = [m.name for m in o.data.materials if m]
        info = [_mat_info(m) for m in o.data.materials if m]
        is_eye = any(n.startswith("eye") or n.startswith("yel") or "iris" in n or "pupil" in n for n in mats)
        is_hl = any(n in ("hl", "hl2") for n in mats)
        glow = any(i[2] > 0 for i in info)
        m = max(hi.x - lo.x, hi.y - lo.y, hi.z - lo.z)
        kill = False
        if is_hl:
            kill = True
        elif is_eye and human:
            kill = True
        elif m < small * size and not is_eye and not glow and o.name.split('.')[0] not in keep:
            kill = True
        if kill:
            bpy.data.objects.remove(o, do_unlink=True)
            gone += 1
    return gone


def flatten_eyes(root, color=(0.10, 0.085, 0.11)):
    """Olhos como nas cartas: uma cor só, sem pupila, sem reflexo, sem órbita. A pupila some (só a que fica sobre um
    olho: o nariz também usa o material "pupil"), a esfera do olho vira de `color`, o brilho dos olhos de esqueleto fica
    (uma cor só, sem órbita) e maior, para ler como olho."""
    objs = [o for o in descendants(root) if o.type == 'MESH']
    def names(o):
        return [m.name for m in o.data.materials if m]
    eyes = [o for o in objs if any(n.startswith("eyey") or n == "eye" for n in names(o))]
    def ctr(o):
        lo, hi = _world_bbox(o)
        return (lo + hi) / 2, max(hi.x - lo.x, hi.y - lo.y, hi.z - lo.z)
    ec = [ctr(o) for o in eyes if any(n.startswith("eyey") for n in names(o))]
    flat = mk.mat("eyeflat_%s" % str(color), color, 0.35)
    for o in objs:
        n = names(o)
        if any(x in ("hl", "hl2") or x.startswith("socket") for x in n):
            bpy.data.objects.remove(o, do_unlink=True)
        elif "pupil" in n:
            c, r = ctr(o)
            if any((c - e).length < e_r * 1.3 for e, e_r in ec):
                bpy.data.objects.remove(o, do_unlink=True)
        elif any(x.startswith("pupil_glow") for x in n):
            o.scale = o.scale * 1.9
    for o in eyes:
        mk.setmat(o, flat)


def prepare(root, budget, flat=False, small=24):
    """Modificadores aplicados, redução, normais (macias ou facetadas) e UV desdobrada junta."""
    objs = [o for o in descendants(root) if o.type in ('MESH', 'CURVE') and not o.hide_render]
    for o in objs:
        if o.type == 'CURVE':
            mk._sel(o)
            bpy.ops.object.convert(target='MESH')
    objs = [o for o in descendants(root) if o.type == 'MESH' and not o.hide_render]
    for o in objs:
        mk.apply_mods(o)
    counts = {o.name: sum(len(p.vertices) - 2 for p in o.data.polygons) for o in objs}
    total = max(1, sum(counts.values()))
    ratio = min(1.0, budget / total)
    for o in objs:
        tris = counts[o.name]
        tgt = max(small, int(tris * ratio))
        if tris > tgt:
            m = o.modifiers.new("dec", 'DECIMATE')
            m.decimate_type = 'COLLAPSE'
            m.ratio = max(0.02, tgt / tris)
            m.use_collapse_triangulate = True
            mk.apply_mods(o)
    for o in objs:
        if flat:
            mk._sel(o)
            try:
                bpy.ops.mesh.customdata_custom_splitnormals_clear()
            except Exception:
                pass
            for p in o.data.polygons:
                p.use_smooth = False
        if not o.data.uv_layers:
            o.data.uv_layers.new(name="UVMap")
    for x in bpy.context.selected_objects:
        x.select_set(False)
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    try:
        bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=0.012)
    except TypeError:
        bpy.ops.uv.smart_project()
    try:
        bpy.ops.uv.pack_islands(margin=0.012)
    except TypeError:
        bpy.ops.uv.pack_islands()
    bpy.ops.object.mode_set(mode='OBJECT')
    return objs


def extract(objs, grade):
    """Como vat.bake_parts depois da preparação: vértices (com UV), normais, cores graduadas e índices por parte."""
    dg = bpy.context.evaluated_depsgraph_get()
    parts = []
    for o in objs:
        ev = o.evaluated_get(dg)
        me = ev.to_mesh()
        me.calc_loop_triangles()
        try:
            cn = me.corner_normals
            loop_n = [Vector(cn[i].vector) for i in range(len(me.loops))]
        except AttributeError:
            loop_n = [Vector(l.normal) for l in me.loops]
        ca = me.color_attributes.get("Col")
        uvl = me.uv_layers.active
        mats = [_mat_info(m) for m in (me.materials or [None])]
        verts, nrms, cols, uvs, idx = [], [], [], [], []
        key = {}
        for tri in me.loop_triangles:
            info = mats[min(tri.material_index, len(mats) - 1)]
            for li in tri.loops:
                vi = me.loops[li].vertex_index
                n = loop_n[li] if tri.use_smooth else Vector(tri.normal)
                uv = uvl.data[li].uv if uvl else (0.0, 0.0)
                k = (vi, round(n.x, 3), round(n.y, 3), round(n.z, 3), tri.material_index, round(uv[0], 4), round(uv[1], 4))
                if k not in key:
                    key[k] = len(verts)
                    verts.append(Vector(me.vertices[vi].co))
                    nrms.append(n.normalized())
                    uvs.append((uv[0], uv[1]))
                    c, vc, glow, bump = info
                    if vc and ca is not None:
                        d = ca.data[vi].color if ca.domain == 'POINT' else ca.data[li].color
                        c = (d[0], d[1], d[2])
                    g = grade((_srgb(c[0]), _srgb(c[1]), _srgb(c[2])))
                    cols.append((g[0], g[1], g[2], 1.0 - glow))
                idx.append(key[k])
        parts.append({"obj": o, "bone": o.get("bone", "body"), "verts": verts, "nrms": nrms, "cols": cols, "uvs": uvs,
                      "idx": idx, "mw": o.matrix_world.copy()})
        ev.to_mesh_clear()
    return parts


def export(root, path, height, objs, grade, anim=None, deform=None, rig=None, recenter=True):
    """Igual a vat.export, sobre as partes já preparadas. Devolve {pos, nrm, col, uv, idx, scale} (em coordenadas
    do jogo, altura = `height`) para o atlas."""
    parts = extract(objs, grade)
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

    cols, uvs, idx = [], [], []
    for p in parts:
        base = len(cols)
        cols += p["cols"]
        uvs += p["uvs"]
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
           "frames": len(frames), "uv": 1}
    with open(path, "wb") as f:
        f.write((json.dumps(hdr) + "\n").encode())
        f.write(struct.pack("<%df" % (len(pos) * 3), *[x for v in pos for x in v]))
        f.write(struct.pack("<%df" % (len(nrm) * 3), *[x for v in nrm for x in v]))
        f.write(struct.pack("<%df" % (len(cols) * 4), *[x for c4 in cols for x in c4]))
        f.write(struct.pack("<%df" % (len(uvs) * 2), *[x for u in uvs for x in u]))
        f.write(struct.pack("<%di" % len(idx), *idx))
        for P, N in frames:
            f.write(struct.pack("<%df" % (len(P) * 3), *[x for v in P for x in v]))
            f.write(struct.pack("<%df" % (len(N) * 3), *[x for v in N for x in v]))
    print("lbm %s: %d vértices, %d tris, %d quadros" % (path, len(pos), len(idx) // 3, len(frames)))
    return {"pos": np.array(pos), "nrm": np.array(nrm), "col": np.array(cols), "uv": np.array(uvs),
            "idx": np.array(idx).reshape(-1, 3), "height": (hi.z - lo.z) * s}
