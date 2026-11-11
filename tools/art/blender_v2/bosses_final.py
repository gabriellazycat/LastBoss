"""Os 3 chefes finais (Rainha da Praga, Dragão Avarento, Lich) a partir do blockout aprovado (bosses_v3.py):
mesma silhueta e mesma divisão em 4 partes, refinados no kit do blender_v2 (massas fundidas por voxel com cor
pintada nos vértices, peças duras chanfradas, brilhos) e exportados como .lbm para o jogo.

Cada parte é gravada com a SUA origem (PART_OFFSETS abaixo, em coordenadas do blockout antes do FIT): a malha
fica relativa a esse ponto, para poder ser movida, escondida ou destruída sozinha. game/art/boss_models.gd monta
as partes de volta com os mesmos offsets (convertidos para a Godot: (x, y, z) do Blender -> (-x, z, y)).

Uso (Blender 5.2, headless):
  blender -b --factory-startup -P tools/art/blender_v2/bosses_final.py -- --out=<pasta dos .lbm> [--only=plague,dragon,lich]
  godot --headless --path . -s res://tools/art/import_v2.gd -- --src=<pasta dos .lbm>
    -> assets/models/v2/boss_<chefe>_{core,head,left_arm,right_arm}.res (+ boss_lich_circle.res, cenário)
"""
import os, sys, math, random
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import bpy, bmesh
from mathutils import Vector, Euler, Matrix
import mk, vat
from mk import mat, setmat, capsule, box, cyl, torus, tube, join, shade, apply_mods, fuse, mix, smoothstep, ell_w
from bosses_v3 import cone, rot_about, FIT, BONE, BRASS

# Origem de cada parte (coordenadas do blockout, antes do FIT): ombro dos braços, pescoço da cabeça, chão do núcleo.
PART_OFFSETS = {
    "plague": {"core": (0, 0, 0), "head": (0, -0.1, 4.3), "left": (1.4, 0, 3.1), "right": (-1.4, 0, 3.1)},
    "dragon": {"core": (0, 0, 0), "head": (0, -1.0, 4.4), "left": (0.9, 0.6, 2.6), "right": (-1.0, -0.2, 2.3)},
    "lich": {"core": (0, 0, 0), "head": (0, -0.05, 4.4), "left": (1.2, 0, 3.4), "right": (-1.2, 0, 3.4)},
}
BUDGET = {"core": 6000, "head": 3000, "left": 2500, "right": 2500, "circle": 1500}
FILE = {"core": "core", "head": "head", "left": "left_arm", "right": "right_arm", "circle": "circle"}
TAU = math.tau


# ------------------------------------------------------------------ ajudantes
def sp(loc, r=1.0, s=(1, 1, 1), rot=(0, 0, 0)):
    """Esfera com segmentos de acordo com o tamanho (as pequenas não gastam o orçamento)."""
    size = r * max(s)
    seg = int(max(10, min(32, 8 + size * 22)))
    seg += seg % 2
    return mk.sph(loc, r, s, rot, seg)


def S(color, rough=0.85, **kw):
    return mat("f_%s_%s_%s" % (str(color), rough, kw.get("metal", 0)), color, rough, **kw)


def G(color, e=6.0):
    return mat("g_%s_%s" % (str(color), e), color, 0.4, emit=e)


def M(o, m, flat=False):
    if isinstance(o, list):
        for x in o:
            M(x, m, flat)
        return o
    setmat(o, m)
    if flat:
        o["flat"] = 1
    return o


def blob(objs, name, voxel, fn, rough=0.8, **kw):
    """Massa orgânica: une por voxel, suaviza e pinta a cor nos vértices (fn(p, n) -> rgb)."""
    o = fuse(objs, name, voxel, 0.55, 5)
    mk.paint(o, fn)
    setmat(o, mat("v_" + name, vcol=True, rough=rough, **kw))
    return o


def vpaint(o, fn, name, rough=0.6, **kw):
    """Peça (não fundida) com degradê pintado."""
    if isinstance(o, list):
        for x in o:
            vpaint(x, fn, name, rough, **kw)
        return o
    if o.type != 'MESH':
        mk._sel(o); bpy.ops.object.convert(target='MESH'); o = bpy.context.active_object
    mk.paint(o, fn)
    setmat(o, mat("v_" + name, vcol=True, rough=rough, **kw))
    return o


def ring(c, axis, R, r):
    eul = Vector(axis).to_track_quat('Z', 'Y').to_euler()
    return torus(c, R, r, rot=[math.degrees(a) for a in eul])


def finish(name, objs):
    flat = []
    for o in objs:
        flat += o if isinstance(o, list) else [o]
    out = []
    for o in flat:
        if o.type != 'MESH':
            mk._sel(o); bpy.ops.object.convert(target='MESH'); o = bpy.context.active_object
        if o.modifiers:
            apply_mods(o)
        shade(o, not o.get("flat"))
        out.append(o)
    o = join(out, name)
    o.data.transform(o.matrix_world)
    o.matrix_world = Matrix()
    return o


def membrane(polys, m, thick=0.05):
    bm = bmesh.new()
    for pl in polys:
        bm.faces.new([bm.verts.new(p) for p in pl])
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-4)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bmesh.ops.subdivide_edges(bm, edges=bm.edges, cuts=2, use_grid_fill=True)
    me = bpy.data.meshes.new("mem"); bm.to_mesh(me); bm.free()
    o = mk._link(bpy.data.objects.new("mem", me))
    s = o.modifiers.new("so", 'SOLIDIFY'); s.thickness = thick; s.offset = 0.0
    setmat(o, m)
    return o


def lathe(profile, seg, hem, cap=True):
    """Superfície de revolução: profile = [(z, r)] de baixo para cima; hem(a) -> (dz, dr) da borda de baixo,
    que se dissolve até o 3º anel. Tampa no topo; a borda de baixo fica aberta (com espessura)."""
    bm = bmesh.new()
    rows = []
    for j, (z, r) in enumerate(profile):
        w = max(0.0, 1.0 - j / 2.0)
        row = []
        for i in range(seg):
            a = i / seg * TAU
            dz, dr = hem(a)
            row.append(bm.verts.new((math.cos(a) * (r + dr * w), math.sin(a) * (r + dr * w), z + dz * w)))
        rows.append(row)
    for j in range(len(rows) - 1):
        for i in range(seg):
            i2 = (i + 1) % seg
            bm.faces.new([rows[j][i], rows[j][i2], rows[j + 1][i2], rows[j + 1][i]])
    if cap:
        c = bm.verts.new((0, 0, profile[-1][0] + 0.05))
        top = rows[-1]
        for i in range(seg):
            bm.faces.new([top[i], top[(i + 1) % seg], c])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new("lathe"); bm.to_mesh(me); bm.free()
    o = mk._link(bpy.data.objects.new("lathe", me))
    s = o.modifiers.new("so", 'SOLIDIFY'); s.thickness = 0.05; s.offset = -1.0
    return o


def noise3(p, f=1.0):
    return (math.sin(p[0] * 3.1 * f + p[1] * 1.7 * f) * math.cos(p[1] * 2.3 * f - p[2] * 2.9 * f)
            + 0.5 * math.sin(p[2] * 5.3 * f + p[0] * 4.1 * f))


# ------------------------------------------------------------------ 1. RAINHA DA PRAGA
def plague():
    FUR, FURD, FURL = (0.3, 0.38, 0.22), (0.15, 0.2, 0.12), (0.44, 0.52, 0.32)
    BELLY, PINK, SKIN = (0.66, 0.54, 0.44), (0.82, 0.48, 0.5), (0.62, 0.42, 0.42)
    RAG, RAGD = (0.34, 0.13, 0.17), (0.18, 0.06, 0.1)
    EYE = (1.0, 0.85, 0.05)
    mbone, mbrass, mpink, mdark = S(BONE, 0.6), S(BRASS, 0.3, metal=1.0), S(PINK, 0.6), S((0.03, 0.02, 0.02), 0.5)
    mrag, mragd = S(RAG, 0.95), S(RAGD, 0.95)
    rnd = random.Random(7)

    def fur(p, n):
        c = mix(FURD, FUR, smoothstep(0.6, 3.6, p[2]) * 0.75 + smoothstep(-0.3, 0.9, n[2]) * 0.3)
        c = mix(c, FURL, smoothstep(0.55, 1.0, n[2]) * 0.25)
        return mix(c, FURD, max(0.0, noise3(p, 2.0)) * 0.25)

    # ---------------- núcleo
    C = []
    nest = [sp((0, 0.1, 0.5), 1, (2.0, 1.8, 0.55))]
    for i in range(16):
        a = i / 16 * TAU + rnd.uniform(-0.15, 0.15)
        nest.append(sp((math.cos(a) * 1.8, 0.1 + math.sin(a) * 1.6, 0.6 + rnd.uniform(-0.05, 0.15)), rnd.uniform(0.32, 0.48), (1.4, 1, 0.75), rot=(0, 0, math.degrees(a))))

    def nest_col(p, n):
        c = mix((0.1, 0.07, 0.05), (0.27, 0.17, 0.1), smoothstep(0.1, 1.0, p[2]))
        return mix(c, RAG, smoothstep(0.3, 0.8, noise3(p, 1.3)) * 0.8)
    C.append(blob(nest, "pl_nest", 0.06, nest_col, 0.95))
    for i in range(12):   # ossos jogados no ninho
        a = i / 12 * TAU + rnd.uniform(-0.2, 0.2)
        c = Vector((math.cos(a) * 1.7, 0.1 + math.sin(a) * 1.5, 0.95 + rnd.uniform(0, 0.1)))
        d = Euler((0, 0, a + rnd.uniform(0.6, 2.4))).to_matrix() @ Vector((0.32, 0, rnd.uniform(-0.05, 0.08)))
        C.append(M(capsule(c - d, c + d, 0.05, seg=10), mbone))
        C.append(M([sp(c - d, 0.08), sp(c + d, 0.08)], mbone))
    for (x, y) in [(1.3, -1.25), (-1.0, -1.4), (0.2, -1.65)]:   # caveirinhas
        C.append(M(sp((x, y, 0.95), 0.2, (1, 1.05, 0.9)), mbone))
        for sx in (-1, 1):
            C.append(M(sp((x + sx * 0.07, y - 0.17, 0.97), 0.05), mdark))
    C.append(vpaint(tube([(-0.9, 1.3, 0.75), (-1.8, 1.4, 0.5), (-2.2, 0.6, 0.22), (-2.0, -0.3, 0.12), (-1.6, -0.6, 0.12)], 0.16, 0.2),
                    lambda p, n: mix(SKIN, PINK, smoothstep(-1.0, -2.0, p[0])), "pl_tail", 0.6))
    # trono de costelas
    for i in range(9):
        a = math.radians(-70 + i * 17.5)
        tip = (2.6 * math.sin(a), 1.0, 2.4 + 2.9 * math.cos(a))
        rib = cone((tip[0] * 0.3, 0.9, 0.9), tip, 0.28, 0.07, 12)
        C.append(vpaint(rib, lambda p, n: mix((0.5, 0.43, 0.3), BONE, smoothstep(1.0, 4.5, p[2])), "pl_rib", 0.6))
        C.append(M(sp(tip, 0.14), mbone))
        C.append(M(ring((tip[0] * 0.55, 0.95, 0.9 + (tip[2] - 0.9) * 0.55), Vector(tip) - Vector((tip[0] * 0.3, 0.9, 0.9)), 0.2, 0.04), mbrass))
    # corpo: ventre, peito, ombros, pescoço
    body = [sp((0, -0.15, 1.75), 1.35, (1, 0.95, 0.9)), sp((0, 0.05, 2.95), 1, (1.05, 0.85, 0.9)),
            sp((1.2, 0, 3.35), 0.5), sp((-1.2, 0, 3.35), 0.5), capsule((0, -0.1, 3.2), (0, -0.25, 3.8), 0.5, seg=20)]
    C.append(blob(body, "pl_body", 0.05, lambda p, n: mix(fur(p, n), BELLY, ell_w(p, (0, -1.1, 1.9), (1.2, 0.9, 1.45)) * 0.85), 0.85, bump=0.1))
    for sx in (-1, 1):   # tufos de pelo nos ombros
        for j in range(5):
            b = Vector((sx * (0.95 + j * 0.13), 0.1 - j * 0.05, 3.7 - j * 0.12))
            C.append(M(cone(b, b + Vector((sx * 0.35, 0.15, 0.3 - j * 0.07)), 0.12, 0.01, 8), S(FURD)))
    B0 = Vector((0, -0.15, 1.75))
    for (a, b) in [(-0.9, 0.05), (-0.45, 0.45), (0.0, 0.1), (0.45, 0.5), (0.9, 0.0), (-0.5, -0.45), (0.5, -0.4), (0.0, -0.6)]:
        u = Vector((math.sin(a) * math.cos(b), -math.cos(a) * math.cos(b), math.sin(b)))
        c = B0 + Vector((u.x * 1.38, u.y * 1.3, u.z * 1.25))
        g = rnd.uniform(0.18, 0.32)
        mr = S((g, g * 0.95, g * 0.85))
        C.append(M(sp(c, 0.27, (1.0, 1.0, 0.9)), mr))
        C.append(M(sp(c + Vector((0, -0.26, -0.03)), 0.15, (0.8, 1.2, 0.8)), mr))
        C.append(M(sp(c + Vector((0, -0.42, -0.05)), 0.05), mpink))
        for sx in (-1, 1):
            C.append(M(sp(c + Vector((sx * 0.17, -0.02, 0.2)), 0.11, (0.5, 0.3, 1)), mpink))
            C.append(M(sp(c + Vector((sx * 0.09, -0.3, 0.1)), 0.045), G(EYE, 6)))
    # capa esfarrapada e gola de trapos
    C.append(M(sp((0, 0.5, 3.0), 1, (1.7, 0.7, 1.2)), mrag))
    for i in range(9):
        x = -1.45 + i * 0.36
        y = 0.5 + 0.7 * math.sqrt(max(0.0, 1 - (x / 1.75) ** 2)) * 0.8
        C.append(M(box((x, y, 2.25 + rnd.uniform(-0.1, 0.1)), (0.34, 0.07, 1.1 + rnd.uniform(-0.15, 0.25)), rot=(rnd.uniform(-10, 4), 0, rnd.uniform(-8, 8)), bevel=0.02), mragd if i % 2 else mrag, True))
    C.append(M(torus((0, -0.12, 3.55), 0.56, 0.15, s=(1, 0.9, 1)), mragd))

    # ---------------- cabeça
    H = []
    sk = [sp((0, 0, 4.5), 0.7, (1, 1, 0.95)), cone((0, -0.3, 4.45), (0, -1.4, 4.2), 0.5, 0.17, 16),
          sp((0, -0.55, 3.95), 0.4, (1, 1.1, 0.5)), sp((0, -0.45, 4.85), 0.45, (1.1, 0.8, 0.4))]

    def head_col(p, n):
        c = fur(p, n)
        c = mix(c, (0.5, 0.48, 0.36), smoothstep(-0.4, -0.95, n[2]) * 0.5)
        return mix(c, SKIN, smoothstep(-0.95, -1.35, p[1]))
    H.append(blob(sk, "pl_head", 0.025, head_col, 0.8, bump=0.08))
    H.append(M(sp((0, -1.42, 4.2), 0.17), mpink))
    for sx in (-1, 1):
        H.append(M(box((sx * 0.065, -1.12, 3.95), (0.11, 0.06, 0.26), bevel=0.02), S((0.95, 0.85, 0.55), 0.4), True))
        H.append(M(sp((sx * 0.85, 0.15, 5.15), 1, (0.6, 0.14, 0.72), rot=(0, sx * -20, sx * -18)), S(FURD)))
        H.append(M(sp((sx * 0.84, 0.06, 5.12), 1, (0.44, 0.08, 0.55), rot=(0, sx * -20, sx * -18)), mpink))
        H.append(M(sp((sx * 0.3, -0.6, 4.75), 0.17), G(EYE, 6)))
        H.append(M(sp((sx * 0.3, -0.75, 4.76), 0.07), mdark))
        H.append(M(box((sx * 0.3, -0.72, 4.98), (0.32, 0.09, 0.07), rot=(0, sx * 18, 0), bevel=0.02), S(FURD), True))
        for j in range(3):
            H.append(M(tube([(sx * 0.15, -1.1, 4.2 + j * 0.04), (sx * 0.7, -1.3, 4.25 + j * 0.12), (sx * 1.3, -1.25, 4.3 + j * 0.25)], 0.018, 0.6, 10), mbone))
        for j in range(3):
            b = Vector((sx * 0.55, -0.35 - j * 0.12, 4.25 - j * 0.1))
            H.append(M(cone(b, b + Vector((sx * 0.35, 0.18, -0.12)), 0.1, 0.01, 8), S(FUR)))
    tilt = (12, 0, -14); cc = (0, 0.0, 5.2)
    H.append(M(cyl(cc, 0.58, 0.3, rot=tilt, seg=16, bevel=0.02, r2=0.52), mbrass, True))
    H.append(M(torus(rot_about((0, 0, 5.08), cc, tilt), 0.585, 0.04, rot=tilt), S((0.55, 0.36, 0.12), 0.4, metal=1.0)))
    for i in range(6):
        a = i / 6 * TAU
        b = rot_about((math.cos(a) * 0.55, math.sin(a) * 0.55, 5.3), cc, tilt)
        t = rot_about((math.cos(a) * 0.58, math.sin(a) * 0.58, 5.85 + (0.2 if i % 2 else 0)), cc, tilt)
        H.append(M(cone(b, t, 0.1, 0.02, 8), mbrass))
        H.append(M(sp(t, 0.06), G((1, 0.2, 0.2), 6)))
        H.append(M(sp(rot_about((math.cos(a + 0.5) * 0.6, math.sin(a + 0.5) * 0.6, 5.2), cc, tilt), 0.06), G((0.3, 1.0, 0.3), 5)))

    # ---------------- esquerdo (+X): pata com cetro
    L = []
    arm = [capsule((1.4, 0, 3.1), (2.0, -0.9, 2.4), 0.4, 0.33, 20), capsule((2.0, -0.9, 2.4), (2.3, -1.45, 1.95), 0.33, 0.3, 20), sp((2.3, -1.55, 1.85), 0.38)]
    L.append(blob(arm, "pl_larm", 0.035, lambda p, n: mix(fur(p, n), SKIN, ell_w(p, (2.3, -1.6, 1.8), (0.55, 0.55, 0.55))), 0.8, bump=0.08))
    for i in range(4):
        L.append(M(cone((2.3 + (i - 1.5) * 0.15, -1.8, 1.8), (2.3 + (i - 1.5) * 0.19, -2.15, 1.55), 0.06, 0.01, 8), mbone))
    L.append(vpaint(cone((2.35, -1.25, 0.3), (2.35, -1.25, 4.45), 0.11, 0.07, 10), lambda p, n: mix((0.45, 0.38, 0.26), BONE, smoothstep(0.3, 4.4, p[2])), "pl_staff"))
    for z in (1.3, 3.7, 4.4):
        L.append(M(torus((2.35, -1.25, z), 0.14, 0.04), mbrass))
    L.append(M(sp((2.35, -1.25, 4.75), 0.3, (1, 1.1, 0.9)), mbone))
    L.append(M(cone((2.35, -1.45, 4.72), (2.35, -1.85, 4.6), 0.17, 0.06, 10), mbone))
    for sx in (-1, 1):
        L.append(M(sp((2.35 + sx * 0.12, -1.47, 4.84), 0.08), mdark))
        L.append(M(sp((2.35 + sx * 0.12, -1.52, 4.84), 0.045), G(EYE, 7)))
        L.append(M(cone((2.35 + sx * 0.2, -1.25, 4.9), (2.35 + sx * 0.45, -1.2, 5.2), 0.07, 0.01, 8), mbone))
    for k in range(3):   # amuletos pendurados
        a = k / 3 * TAU
        p0 = Vector((2.35 + math.cos(a) * 0.13, -1.25 + math.sin(a) * 0.13, 4.38))
        p1 = p0 + Vector((math.cos(a) * 0.12, math.sin(a) * 0.12, -0.45))
        L.append(M(tube([p0, (p0 + p1) / 2 + Vector((0, 0, -0.05)), p1], 0.015, 1.0, 8), mragd))
        L.append(M(sp(p1, 0.06), mbone))

    # ---------------- direito (-X): garra enorme
    R = []
    arm = [sp((-1.4, 0, 3.25), 0.75), capsule((-1.4, 0, 3.1), (-1.9, -0.9, 2.2), 0.55, 0.5, 20),
           capsule((-1.9, -0.9, 2.2), (-2.0, -1.4, 1.35), 0.5, 0.55, 20), sp((-2.0, -1.5, 1.1), 0.75, (1, 1.1, 0.7))]
    R.append(blob(arm, "pl_rarm", 0.045, lambda p, n: mix(fur(p, n), SKIN, ell_w(p, (-2.0, -1.7, 1.0), (0.8, 0.6, 0.6)) * 0.8), 0.8, bump=0.08))
    for j in range(5):
        b = Vector((-1.75 - j * 0.07, -0.55 - j * 0.2, 2.75 - j * 0.3))
        R.append(M(cone(b, b + Vector((-0.4, 0.3, 0.15)), 0.13, 0.01, 8), S(FURD)))
    claw = lambda p, n: mix((0.25, 0.18, 0.12), BONE, smoothstep(0.3, 1.1, p[2]))
    for i in range(4):
        x = -2.0 + (i - 1.5) * 0.34
        R.append(vpaint(cone((x, -1.95, 1.1), (x * 1.04, -2.6, 0.25), 0.15, 0.02, 10), claw, "pl_claw", 0.4))
    R.append(vpaint(cone((-1.45, -1.8, 1.15), (-1.15, -2.35, 0.55), 0.13, 0.02, 10), claw, "pl_claw", 0.4))
    return {"core": finish("plague_core", C), "head": finish("plague_head", H), "left": finish("plague_left", L), "right": finish("plague_right", R)}


# ------------------------------------------------------------------ 2. DRAGÃO AVARENTO
def dragon():
    SC, SCD, SCL, BEL = (0.55, 0.2, 0.1), (0.28, 0.09, 0.06), (0.72, 0.27, 0.13), (0.88, 0.62, 0.32)
    HORN, EMB = (0.85, 0.78, 0.6), (1.0, 0.22, 0.02)
    mscd, mhorn = S(SCD, 0.5), S(HORN, 0.5)
    mgold = S((0.78, 0.48, 0.1), 0.35, metal=0.85)
    mgold2 = S((0.9, 0.64, 0.22), 0.3, metal=0.9)
    rnd = random.Random(11)

    def scales(p, n):
        c = mix(SCD, SC, smoothstep(-0.4, 0.7, n[2]) * 0.45 + smoothstep(0.3, 3.2, p[2]) * 0.4 + 0.15)
        c = mix(c, SCL, smoothstep(0.4, 0.9, noise3(p, 2.5)) * 0.35)
        w = smoothstep(-0.25, -0.8, n[1]) * (1 - smoothstep(0.45, 0.85, abs(p[0]))) * smoothstep(1.3, 1.9, p[2])
        b = mix(BEL, (0.66, 0.4, 0.2), 1.0 if math.sin(p[2] * 13) > 0.55 else 0.0)
        return mix(c, b, w)

    def horn(p, n, base=4.9, top=5.8):
        return mix((0.25, 0.18, 0.12), HORN, smoothstep(base, top, p[2]))

    # ---------------- núcleo
    C = []
    pile = [sp((0, 0, 0.35), 1, (2.1, 1.95, 1.0))]
    for i in range(14):
        th, ph = rnd.uniform(0.5, 1.3), rnd.uniform(0, TAU)
        pile.append(sp((2.0 * math.sin(th) * math.cos(ph), 1.85 * math.sin(th) * math.sin(ph), 0.35 + 0.9 * math.cos(th)), rnd.uniform(0.35, 0.6), (1, 1, 0.6)))
    C.append(blob(pile, "dr_pile", 0.06, lambda p, n: mix((0.5, 0.28, 0.04), (0.85, 0.58, 0.16), 0.5 + 0.4 * noise3(p, 3.0)), 0.35, metal=0.85))
    for i in range(80):
        th, ph = rnd.uniform(0.1, 1.3), rnd.uniform(0, TAU)
        p = (2.08 * math.sin(th) * math.cos(ph), 1.93 * math.sin(th) * math.sin(ph), 0.35 + 1.0 * math.cos(th))
        C.append(M(cyl(p, rnd.uniform(0.22, 0.3), 0.06, rot=(rnd.uniform(-35, 35), rnd.uniform(-35, 35), rnd.uniform(0, 90)), seg=12, bevel=0), mgold2 if i % 3 == 0 else mgold, True))
    for i, col in enumerate([(1, 0.1, 0.15), (0.2, 1, 0.4), (0.25, 0.5, 1), (1, 0.1, 0.15), (0.6, 0.2, 1), (0.2, 1, 0.4)]):
        a = i / 6 * TAU + 0.4
        C.append(M(sp((math.cos(a) * 1.75, math.sin(a) * 1.6, 0.62), 0.12, (1, 1, 0.8)), G(col, 4)))
    # baú meio enterrado e cálice
    ch = Euler((math.radians(4), 0, math.radians(28))).to_matrix()
    cc = Vector((1.55, -1.15, 0.55))
    C.append(M(box(cc, (0.8, 0.5, 0.42), rot=(4, 0, 28), bevel=0.03), S((0.32, 0.18, 0.08), 0.8), True))
    C.append(M(box(cc + ch @ Vector((0, 0.32, 0.36)), (0.82, 0.12, 0.5), rot=(-30, 0, 28), bevel=0.03), S((0.32, 0.18, 0.08), 0.8), True))
    for dx in (-0.3, 0.3):
        C.append(M(box(cc + ch @ Vector((dx, 0, 0)), (0.07, 0.53, 0.45), rot=(4, 0, 28), bevel=0.01), mgold, True))
    C.append(M(sp(cc + ch @ Vector((0, 0, 0.22)), 0.33, (1.1, 0.6, 0.3)), G((1.0, 0.75, 0.25), 3)))
    C.append(M([cyl((-0.65, -1.65, 0.62), 0.14, 0.22, seg=12, bevel=0, r2=0.06), cyl((-0.65, -1.65, 0.48), 0.04, 0.2, seg=8, bevel=0),
                cyl((-0.65, -1.65, 0.38), 0.1, 0.03, seg=12, bevel=0)], mgold2))
    # corpo: tronco, peito, pescoço, cauda, ancas
    body = [sp((0, 0.4, 1.8), 1, (1.45, 1.9, 1.1)), sp((0, -0.7, 2.25), 1, (1.15, 0.95, 1.05)),
            tube([(0, 0.5, 2.5), (0, -0.2, 3.3), (0, -0.95, 4.0)], 0.55, 0.9, 12),
            tube([(0, 1.5, 1.5), (0.7, 1.7, 1.0), (1.7, 1.4, 0.6), (2.1, 0.4, 0.4), (1.9, -1.0, 0.35)], 0.5, 0.3, 16)]
    for sx in (-1, 1):
        body += [sp((sx * 1.2, 0.55, 1.3), 0.62, (1, 1.2, 1)), capsule((sx * 1.4, 0.25, 0.95), (sx * 1.55, -0.3, 0.5), 0.33, 0.26, 16),
                 sp((sx * 1.6, -0.45, 0.45), 0.33, (1, 1.3, 0.6))]
    C.append(blob(body, "dr_body", 0.045, scales, 0.55))
    for sx in (-1, 1):
        for i in range(3):
            x = sx * 1.6 + (i - 1) * 0.15
            C.append(M(cone((x, -0.78, 0.45), (x * 1.02, -1.05, 0.25), 0.07, 0.01, 8), mhorn))
    C.append(M(cone((1.9, -1.0, 0.35), (1.85, -1.7, 0.3), 0.32, 0.01, 4), mscd))   # ponta da cauda
    for i in range(7):   # espinhos nas costas
        y = 1.8 - i * 0.5
        C.append(M(cone((0, y, 2.55 - 0.1 * i), (0, y - 0.15, 3.2 - 0.1 * i), 0.22, 0.02, 8), mscd))
    for t in (0.15, 0.35, 0.55, 0.75):   # e na cauda
        pts = [Vector(p) for p in [(0.7, 1.7, 1.0), (1.7, 1.4, 0.6), (2.1, 0.4, 0.4), (1.9, -1.0, 0.35)]]
        f = t * 3; k = min(2, int(f)); q = pts[k].lerp(pts[k + 1], f - k)
        C.append(M(cone(q + Vector((0, 0, 0.2)), q + Vector((0, 0, 0.6 - t * 0.3)), 0.14, 0.01, 8), mscd))
    C.append(M(torus((0, -1.15, 2.95), 0.66, 0.13, rot=(50, 0, 0)), mscd))
    C.append(M(sp((0, -1.25, 2.95), 0.58), G(EMB, 4)))
    C.append(M(sp((0, -1.55, 2.98), 0.3, (1, 0.6, 1)), G((1.0, 0.75, 0.2), 6)))

    # ---------------- cabeça (o blockout aumentava a cabeça 1,3x em torno do pescoço)
    H = []
    H.append(blob([sp((0, -1.0, 4.45), 0.6, (1, 1.15, 0.9)), cone((0, -1.4, 4.45), (0, -2.3, 4.25), 0.46, 0.3, 16),
                   sp((0, -1.55, 4.72), 0.4, (1.2, 0.8, 0.35))], "dr_head", 0.025, scales, 0.55))
    H.append(blob([capsule((0, -1.3, 3.95), (0, -2.2, 3.78), 0.27, 0.2, 16)], "dr_jaw", 0.025,
                  lambda p, n: mix(SCL, BEL, smoothstep(0.0, -0.8, n[2])), 0.6))
    H.append(M(sp((0, -1.9, 4.02), 0.3, (0.85, 1.3, 0.55)), G(EMB, 5)))
    H.append(M(sp((0, -1.75, 4.02), 0.18, (0.8, 1.5, 0.5)), G((1.0, 0.8, 0.2), 6)))
    for sx in (-1, 1):
        H.append(M(box((sx * 0.25, -1.62, 4.82), (0.34, 0.22, 0.11), rot=(0, sx * -14, sx * 10), bevel=0.03), mscd, True))
        H.append(M(sp((sx * 0.36, -1.72, 4.68), 0.12, (1, 0.7, 0.8)), G((1, 0.9, 0.1), 7)))
        H.append(M(sp((sx * 0.36, -1.8, 4.68), 0.04, (0.4, 1, 1.4)), S((0.05, 0.02, 0.01), 0.4)))
        H.append(vpaint(tube([(sx * 0.35, -0.7, 4.9), (sx * 0.8, -0.2, 5.35), (sx * 1.0, 0.45, 5.7)], 0.14, 0.2, 12), horn, "dr_horn", 0.5))
        H.append(vpaint(tube([(sx * 0.42, -0.85, 4.6), (sx * 0.75, -0.55, 4.6), (sx * 0.95, -0.15, 4.75)], 0.07, 0.2, 10), lambda p, n: horn(p, n, 4.4, 4.9), "dr_horn2", 0.5))
        H.append(M(sp((sx * 0.14, -2.3, 4.32), 0.06), G(EMB, 6)))
        for j in range(4):
            y = -2.15 + j * 0.24
            H.append(M(cone((sx * 0.24, y, 4.08), (sx * 0.24, y, 3.86), 0.05, 0.01, 6), mhorn))
            H.append(M(cone((sx * 0.18, y + 0.05, 3.9), (sx * 0.18, y + 0.05, 4.06), 0.04, 0.01, 6), mhorn))
        for j in range(2):
            b = Vector((sx * 0.45, -0.95 + j * 0.15, 4.25 - j * 0.12))
            H.append(M(cone(b, b + Vector((sx * 0.4, 0.45, -0.1)), 0.09, 0.01, 8), mscd))
    for j in range(4):
        H.append(M(cone((0, -0.55 + j * 0.25, 5.0 - j * 0.05), (0, -0.42 + j * 0.25, 5.5 - j * 0.1), 0.12, 0.02, 8), mscd))
    hd = finish("dragon_head", H)
    hd.data.transform(Matrix.Translation((0, -1.0, 4.4)) @ Matrix.Scale(1.3, 4) @ Matrix.Translation((0, 1.0, -4.4)))

    # ---------------- esquerdo (+X): asa
    wp = (0.9, 0.6, 2.6); wr = (2.3, 0.2, 5.2)
    F = [(2.5, 0.5, 3.4), (2.2, 0.9, 2.5), (1.3, 1.1, 2.1)]
    L = [vpaint(tube([wp, (1.7, 0.5, 4.0), wr], 0.17, 0.55, 14), scales, "dr_wingarm", 0.55),
         blob([sp(wp, 0.38)], "dr_wsh", 0.03, scales, 0.55), M(sp(wr, 0.13), mscd)]
    for f in F:
        L.append(M(tube([wr, ((wr[0] + f[0]) / 2 + 0.05, (wr[1] + f[1]) / 2, (wr[2] + f[2]) / 2), f], 0.075, 0.4, 12), mscd))
        L.append(M(cone(f, Vector(f) + (Vector(f) - Vector(wr)).normalized() * 0.25, 0.05, 0.01, 6), mhorn))

    def sag(a, b, k=0.18):
        m = (Vector(a) + Vector(b)) / 2
        return tuple(m + (Vector(wr) - m) * k)
    polys = [[wr, F[0], sag(F[0], F[1]), F[1]], [wr, F[1], sag(F[1], F[2]), F[2]], [wr, F[2], sag(F[2], wp, 0.1), wp], [wr, wp, (1.7, 0.5, 4.0)]]
    L.append(membrane(polys, S((0.78, 0.26, 0.1), 0.7)))
    for f in F[:2]:   # nervuras
        L.append(M(tube([wr, sag(wr, f, 0.0), Vector(f).lerp(Vector(wr), 0.15)], 0.025, 0.5, 8), S((0.5, 0.15, 0.07), 0.7)))
    L.append(M(cone(wr, (wr[0] + 0.15, wr[1] - 0.1, wr[2] + 0.55), 0.1, 0.01, 8), mhorn))

    # ---------------- direito (-X): garra sobre o ouro
    R = [blob([sp((-1.0, -0.2, 2.3), 0.62), capsule((-1.0, -0.2, 2.2), (-1.65, -1.2, 1.5), 0.46, 0.4, 16),
               capsule((-1.65, -1.0, 1.5), (-1.5, -1.4, 0.9), 0.4, 0.38, 16), sp((-1.5, -1.5, 0.85), 0.55, (1, 1.2, 0.6))], "dr_rarm", 0.035, scales, 0.55)]
    for i in range(4):
        x = -1.5 + (i - 1.5) * 0.28
        R.append(vpaint(cone((x, -1.9, 0.8), (x * 1.03, -2.4, 0.4), 0.1, 0.01, 8), lambda p, n: horn(p, n, 0.4, 0.9), "dr_claw", 0.4))
    R.append(vpaint(cone((-1.05, -1.75, 0.95), (-0.8, -2.1, 0.55), 0.09, 0.01, 8), lambda p, n: horn(p, n, 0.5, 1.0), "dr_claw", 0.4))
    for j in range(3):   # espinhos no antebraço
        b = Vector((-1.25 - j * 0.15, -0.55 - j * 0.25, 2.15 - j * 0.2))
        R.append(M(cone(b, b + Vector((-0.25, 0.3, 0.3)), 0.09, 0.01, 8), mscd))
    for i in range(5):
        R.append(M(cyl((-1.85 + i * 0.22, -1.9 + (i % 2) * 0.25, 0.55), 0.24, 0.06, rot=(rnd.uniform(-30, 30), rnd.uniform(-30, 30), 0), seg=12, bevel=0), mgold, True))
    return {"core": finish("dragon_core", C), "head": hd, "left": finish("dragon_left", L), "right": finish("dragon_right", R)}


# ------------------------------------------------------------------ 3. LICH
def lich():
    ROBE, ROBED, ROBEL, GRN = (0.13, 0.05, 0.22), (0.05, 0.02, 0.09), (0.28, 0.12, 0.4), (0.04, 1.0, 0.2)
    mrobed, mbone = S(ROBED, 0.9), S(BONE, 0.6)
    mgold = S((0.62, 0.5, 0.22), 0.35, metal=1.0)
    mdark = S((0.03, 0.02, 0.04), 0.6)

    def robe(p, n):
        c = mix(ROBED, ROBE, smoothstep(0.2, 2.6, p[2]))
        c = mix(c, ROBEL, (1 - smoothstep(0.12, 0.22, abs(p[0]))) * smoothstep(-0.2, -0.6, n[1]) * 0.8)
        return mix(c, (0.3, 0.6, 0.25), (1 - smoothstep(0.25, 0.75, p[2])) * 0.35)

    def bone(p, n, lo=3.8, hi=4.9):
        return mix((0.5, 0.43, 0.32), BONE, smoothstep(lo, hi, p[2]) * 0.7 + smoothstep(-0.2, 0.8, n[2]) * 0.3)

    # ---------------- núcleo
    C = []
    N = 12

    def hem(a):
        t = (a * N / TAU + 0.5) % 1.0
        return (abs(t - 0.5) * 2 * 0.45 - 0.05, 0.12 * (1 - abs(t - 0.5) * 2))
    C.append(vpaint(lathe([(0.25, 1.42), (0.7, 1.38), (1.2, 1.3), (1.8, 1.14), (2.3, 1.0), (2.6, 0.95)], 72, hem), robe, "li_robe", 0.9))
    C.append(M(cone((0, 0, 1.2), (0, 0, 0.3), 1.0, 0.05, 20), mrobed))
    for i in range(N):   # chamas fantasmas que descem do manto até o chão
        a = (i + 0.5) / N * TAU
        C.append(M(cone((math.cos(a) * 1.35, math.sin(a) * 1.35, 0.4), (math.cos(a) * 1.5, math.sin(a) * 1.5, 0.02), 0.1, 0.01, 8), G(GRN, 2.5)))
    C.append(M(sp((0, 0.3, 3.3), 1, (1.5, 0.7, 0.9)), mrobed))
    C.append(M(torus((0, 0, 2.5), 0.98, 0.06), mgold))
    C.append(vpaint(capsule((0, 0.25, 2.2), (0, 0.25, 3.7), 0.12, seg=12), lambda p, n: bone(p, n, 2.0, 3.8), "li_spine"))
    for i in range(5):
        z = 2.5 + i * 0.25
        Rr = 0.7 - 0.05 * abs(i - 2) ** 1.3
        for sx in (-1, 1):
            pts = [(sx * math.cos(math.radians(a)) * Rr, math.sin(math.radians(a)) * Rr * 0.75 + 0.1, z - (90 - a) * 0.0018) for a in (90, 40, -10, -55)]
            C.append(vpaint(tube(pts, 0.05, 0.55, 10), lambda p, n: bone(p, n, 2.2, 3.6), "li_rib"))
    C.append(M(sp((0, -0.3, 2.9), 1, (0.3, 0.3, 0.42)), G(GRN, 5)))
    C.append(M(mk.sph((0, -0.3, 2.9), 1, (0.16, 0.16, 0.24), seg=8), G((0.7, 1.0, 0.6), 7)))
    C.append(M(torus((0, -0.3, 2.9), 0.46, 0.035, rot=(90, 0, 0)), mgold))
    C.append(M(torus((0, -0.3, 2.9), 0.46, 0.035, rot=(0, 90, 0)), mgold))
    for sx in (-1, 1):
        C.append(M(sp((sx * 1.15, 0.0, 3.5), 0.5, (1, 0.9, 0.6)), mrobed))
        C.append(M(torus((sx * 1.15, 0.0, 3.33), 0.47, 0.04, s=(1, 0.9, 1)), mgold))
        for j in range(3):
            C.append(vpaint(cone((sx * (0.95 + j * 0.25), -0.05, 3.7), (sx * (1.05 + j * 0.3), -0.05, 4.25 - j * 0.05), 0.1, 0.01, 8), lambda p, n: bone(p, n, 3.7, 4.2), "li_spike"))
    for k in range(7):   # gola alta atrás da cabeça
        a = math.radians(-66 + k * 22)
        b = Vector((math.sin(a) * 0.5, 0.42 + math.cos(a) * 0.05, 3.7))
        t = Vector((math.sin(a) * 1.0, 0.8, 4.95 - abs(a) * 0.55))
        C.append(M(cone(b, t, 0.2, 0.02, 6), mrobed))
        C.append(M(sp(t, 0.05), G(GRN, 4)))

    # ---------------- cabeça
    H = [blob([sp((0, -0.05, 4.5), 0.55, (1, 1, 1.05)), sp((0, -0.3, 4.0), 0.36, (1, 0.8, 0.7)), sp((0.3, -0.38, 4.28), 0.15), sp((-0.3, -0.38, 4.28), 0.15)],
              "li_skull", 0.02, bone, 0.6),
         M(sp((0, -0.52, 4.33), 0.07, (1, 0.6, 1.3)), mdark)]
    for sx in (-1, 1):
        H.append(M(sp((sx * 0.2, -0.47, 4.6), 0.17, (1, 0.7, 1.1)), mdark))
        H.append(M(sp((sx * 0.2, -0.56, 4.6), 0.08), G(GRN, 8)))
    for j in range(6):
        H.append(M(box(((j - 2.5) * 0.085, -0.6, 4.0), (0.065, 0.06, 0.15), bevel=0.01), mbone, True))
    H.append(M(cyl((0, -0.02, 5.07), 0.6, 0.24, seg=16, bevel=0.02, r2=0.55), mgold, True))
    for i in range(7):
        a = i / 7 * TAU
        H.append(M(cone((math.cos(a) * 0.55, math.sin(a) * 0.55, 5.15), (math.cos(a) * 0.6, math.sin(a) * 0.6, 5.65), 0.09, 0.01, 6), mgold))
        H.append(M(sp((math.cos(a + 0.45) * 0.6, math.sin(a + 0.45) * 0.6, 5.06), 0.05), G(GRN, 6)))
    for (x, y, h) in [(0, 0, 0.95), (-0.35, 0.1, 0.65), (0.35, 0.1, 0.65), (0, 0.35, 0.55), (-0.2, -0.25, 0.45), (0.22, -0.22, 0.4)]:
        H.append(M(cone((x, y, 5.2), (x * 1.15, y + 0.08, 5.2 + h * 0.95), 0.2, 0.01, 10), G(GRN, 3)))
        H.append(M(cone((x, y - 0.03, 5.2), (x * 1.1, y + 0.05, 5.2 + h * 0.6), 0.1, 0.01, 8), G((0.75, 1.0, 0.6), 6)))

    # ---------------- esquerdo (+X): mão com o grimório
    L = [vpaint(cone((1.2, 0, 3.4), (1.75, -0.95, 2.45), 0.38, 0.55, 18), robe, "li_sleeve", 0.9),
         M(ring((1.75, -0.95, 2.45), Vector((0.55, -0.95, -0.95)), 0.53, 0.05), mgold),
         M(sp((1.8, -1.0, 2.35), 0.2), mbone)]
    for i in range(4):
        L.append(M(tube([(1.8, -1.0, 2.4), (1.8 + (i - 1.5) * 0.12, -1.25, 2.55), (1.8 + (i - 1.5) * 0.18, -1.45, 2.62)], 0.035, 0.6, 8), mbone))
    bc = (1.6, -1.15, 3.0)
    for sx in (-1, 1):
        L.append(M(box((bc[0] + sx * 0.33, bc[1], bc[2] - 0.04), (0.62, 0.8, 0.07), rot=(0, sx * 22, 0), bevel=0.01), S((0.4, 0.06, 0.08), 0.6), True))
        L.append(M(box((bc[0] + sx * 0.33, bc[1], bc[2]), (0.56, 0.74, 0.05), rot=(0, sx * 22, 0), bevel=0.005), S((0.92, 0.88, 0.72), 0.7), True))
        L.append(M(box((bc[0] + sx * 0.33, bc[1], bc[2] + 0.05), (0.3, 0.4, 0.01), rot=(0, sx * 22, 0), bevel=0), G(GRN, 3), True))
        for dy in (-0.33, 0.33):
            L.append(M(box((bc[0] + sx * 0.58, bc[1] + dy, bc[2] + sx * 0.0 + 0.06), (0.1, 0.1, 0.1), rot=(0, sx * 22, 0), bevel=0.01), mgold, True))
    L.append(M(cyl((bc[0], bc[1], bc[2] - 0.12), 0.08, 0.8, rot=(90, 0, 0), seg=10, bevel=0), S((0.3, 0.05, 0.06), 0.6)))
    for k in range(5):
        L.append(M(sp((bc[0] + (k - 2) * 0.2, bc[1] - 0.05 + (k % 2) * 0.12, bc[2] + 0.45 + (k % 3) * 0.13), 0.065), G(GRN, 6)))

    # ---------------- direito (-X): mão com a foice
    R = [vpaint(cone((-1.2, 0, 3.4), (-1.65, -0.95, 2.5), 0.38, 0.55, 18), robe, "li_sleeve", 0.9),
         M(ring((-1.65, -0.95, 2.5), Vector((-0.45, -0.95, -0.9)), 0.53, 0.05), mgold),
         M(sp((-1.7, -1.0, 2.4), 0.2), mbone)]
    for i in range(4):
        R.append(M(tube([(-1.7, -1.0, 2.5), (-1.7 + (i - 1.5) * 0.1, -1.2, 2.6), (-1.7 + (i - 1.5) * 0.12, -1.0, 2.7)], 0.035, 0.6, 8), mbone))
    R.append(M(cone((-1.7, -1.0, 0.15), (-1.7, -1.0, 5.3), 0.09, 0.07, 10), S((0.25, 0.17, 0.12), 0.7)))
    for z in (1.6, 3.4, 4.9):
        R.append(M(torus((-1.7, -1.0, z), 0.11, 0.035), S((0.12, 0.07, 0.05), 0.7)))
    blade = tube([(-1.7, -1.0, 5.35), (-2.05, -1.0, 5.6), (-2.4, -1.0, 5.4), (-2.55, -1.0, 4.9)], 0.17, 0.12, 20)
    blade.data.transform(Matrix.Translation((0, -1.0, 0)) @ Matrix.Diagonal((1, 0.25, 1, 1)) @ Matrix.Translation((0, 1.0, 0)))
    R.append(vpaint(blade, lambda p, n: mix((0.45, 0.5, 0.58), (0.85, 0.92, 1.0), smoothstep(5.2, 5.6, p[2]) * 0.6 + 0.3), "li_blade", 0.25, metal=1.0))
    R.append(M(sp((-1.7, -1.0, 5.35), 0.15, (1, 1, 1.1)), mbone))
    for sx in (-1, 1):
        R.append(M(sp((-1.7 + sx * 0.05, -1.13, 5.37), 0.04), G(GRN, 7)))
    R.append(M(sp((-1.7, -1.0, 5.1), 0.1), G(GRN, 5)))
    parts = {"core": finish("lich_core", C), "head": finish("lich_head", H), "left": finish("lich_left", L), "right": finish("lich_right", R)}
    # círculo ritual: cenário, NÃO é parte (exportado à parte)
    D = [M(cyl((0, 0, 0.03), 2.7, 0.06, seg=48, bevel=0), S((0.12, 0.1, 0.14), 0.9))]
    for rr, w in [(2.55, 0.05), (1.85, 0.04)]:
        D.append(M(torus((0, 0, 0.08), rr, w), G(GRN, 4)))
    for k in range(5):
        a1, a2 = k / 5 * TAU, ((k + 2) % 5) / 5 * TAU
        p1, p2 = Vector((math.cos(a1), math.sin(a1), 0)) * 2.5, Vector((math.cos(a2), math.sin(a2), 0)) * 2.5
        m = (p1 + p2) / 2
        D.append(M(box((m.x, m.y, 0.08), ((p2 - p1).length, 0.08, 0.03), rot=(0, 0, math.degrees(math.atan2(p2.y - p1.y, p2.x - p1.x))), bevel=0), G(GRN, 4), True))
    parts["circle"] = finish("lich_circle", D)
    return parts


BUILD = {"plague": plague, "dragon": dragon, "lich": lich}


def godot_offsets(v):
    k = FIT[v]
    return {key: (-o[0] * k, o[2] * k, o[1] * k) for key, o in PART_OFFSETS[v].items()}


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    out = next((a.split("=", 1)[1] for a in argv if a.startswith("--out=")), None)
    if not out:
        raise SystemExit("faltou --out=<pasta>")
    os.makedirs(out, exist_ok=True)
    only = next((a.split("=", 1)[1].split(",") for a in argv if a.startswith("--only=")), list(BUILD))
    for v in only:
        bpy.ops.wm.read_factory_settings(use_empty=True)
        mk._MATS.clear()
        parts = BUILD[v]()
        k = FIT[v]
        lo = Vector((1e9,) * 3); hi = Vector((-1e9,) * 3)
        for key, o in parts.items():
            o.data.transform(Matrix.Scale(k, 4))
            if key != "circle":
                for vt in o.data.vertices:
                    lo = Vector(map(min, lo, vt.co)); hi = Vector(map(max, hi, vt.co))
        print("MEDIDAS %s: largura %.2f profundidade %.2f altura %.2f (z %.2f..%.2f)" % (v, hi.x - lo.x, hi.y - lo.y, hi.z - lo.z, lo.z, hi.z))
        for key, o in parts.items():
            off = Vector(PART_OFFSETS[v].get(key, (0, 0, 0))) * k
            o.data.transform(Matrix.Translation(-off))
            root = mk.group("root_" + key, [o])
            vat.export(root, os.path.join(out, "boss_%s_%s.lbm" % (v, FILE[key])), None, BUDGET[key], recenter=False)
        print("OFFSETS_GODOT %s %s" % (v, {key: tuple(round(x, 3) for x in g) for key, g in godot_offsets(v).items()}))


if __name__ == "__main__":
    main()
