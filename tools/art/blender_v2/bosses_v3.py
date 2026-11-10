"""Blockout dos 3 chefes novos (Rainha da Praga, Dragão Avarento, Lich) no kit do blender_v2.
Cada chefe = 4 objetos separados: <id>_left, <id>_right, <id>_head, <id>_core (+ extras de cenário que NÃO são partes,
ex. lich_circle). Coordenadas do Blender: Z para cima, frente = -Y, esquerdo do chefe = +X (como boss.py).
As peças ficam em coordenadas do chefe (origem no chão, no centro); ao exportar para o jogo cada uma recebe a origem
de PART_OFFSETS (world_view.gd), como no boss.py.

Uso (Blender 5.2, headless):
  blender -b --factory-startup -P tools/art/blender_v2/bosses_v3.py -- --out=<pasta> [--only=plague,dragon,lich] [--sheet]
    sem --only/--sheet faz tudo: <pasta>/<chefe>/frente.png e jogo.png, mais chefes_raw.png e chefes_partes_raw.png.
  python tools/art/blender_v2/bosses_v3_labels.py <pasta>      # põe nomes e legenda -> chefes.png e chefes_partes.png
"""
import os, sys, math, random
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import bpy, bmesh
from mathutils import Vector, Euler, Matrix
import mk
from mk import mat, setmat, sph, capsule, box, cyl, torus, tube, join, shade, apply_mods

BONE = (0.78, 0.7, 0.52)
BRASS = (0.82, 0.58, 0.2)
GOLD = (1.0, 0.72, 0.28)
PART_COL = {"left": (0.12, 0.32, 0.95), "right": (0.92, 0.12, 0.1), "head": (0.98, 0.85, 0.08), "core": (0.15, 0.78, 0.25)}
PARTS = ("left", "right", "head", "core")


# ------------------------------------------------------------------ ajudantes
def glow(color, e=6.0):
    return mat("glow_%s_%s" % (str(color), e), color, 0.4, emit=e)


def cone(a, b, r1, r2=0.02, seg=14):
    """Cone de a (raio r1) até b (raio r2), sem esferas."""
    a, b = Vector(a), Vector(b)
    d = b - a
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=seg, radius1=r1, radius2=r2, depth=d.length)
    me = bpy.data.meshes.new("k"); bm.to_mesh(me); bm.free()
    o = mk._link(bpy.data.objects.new("k", me))
    o.location = (a + b) / 2
    o.rotation_euler = d.to_track_quat('Z', 'Y').to_euler()
    return o


def membrane(polys, m):
    """Malha de triângulos/quads soltos (asa): polys = lista de listas de pontos."""
    bm = bmesh.new()
    for pl in polys:
        vs = [bm.verts.new(p) for p in pl]
        bm.faces.new(vs)
    me = bpy.data.meshes.new("mem"); bm.to_mesh(me); bm.free()
    o = mk._link(bpy.data.objects.new("mem", me))
    setmat(o, m)
    return o


def rot_about(p, c, euler_deg):
    return Vector(c) + Euler([math.radians(a) for a in euler_deg]).to_matrix() @ (Vector(p) - Vector(c))


def finish(name, objs):
    """Junta tudo numa peça só, suave, com a origem no centro do mundo."""
    flat = []
    for o in objs:
        flat += o if isinstance(o, list) else [o]
    for o in flat:
        if o.modifiers:
            apply_mods(o)
    o = join(flat, name)
    shade(o)
    o.data.transform(o.matrix_world)
    o.matrix_world = Matrix()
    return o


def S(color, rough=0.85, **kw):
    return mat("m_%s_%s" % (str(color), rough), color, rough, **kw)


def paint(o, m):
    if isinstance(o, list):
        for x in o:
            setmat(x, m)
        return o
    return setmat(o, m)


# ------------------------------------------------------------------ 1. RAINHA DA PRAGA
def plague():
    FUR, FURD = (0.3, 0.38, 0.22), (0.17, 0.22, 0.13)
    BELLY, PINK, RAG = (0.62, 0.5, 0.42), (0.8, 0.5, 0.5), (0.32, 0.14, 0.18)
    EYE = (1.0, 0.85, 0.05)
    mf, mfd, mb, mp, mr = S(FUR), S(FURD), S(BELLY, 0.7, sss=0.2), S(PINK, 0.6), S(RAG, 0.95)
    mbone, mbrass = S(BONE, 0.6), S(BRASS, 0.3, metal=1.0)
    rnd = random.Random(7)
    # --- núcleo: ninho de ossos e trapos, ventre cheio de ratos, peito, capa e leque de costelas (o "trono")
    C = [paint(sph((0, 0.1, 0.55), 1, (2.0, 1.8, 0.6)), S((0.2, 0.12, 0.08), 0.95))]
    for i in range(9):   # costelas do trono atrás
        a = math.radians(-70 + i * 17.5)
        tip = (2.6 * math.sin(a), 1.0, 2.4 + 2.9 * math.cos(a))
        C.append(paint(cone((tip[0] * 0.3, 0.9, 0.9), tip, 0.28, 0.07), mbone))
        C.append(paint(sph(tip, 0.13), mbone))
    C.append(paint(sph((0, -0.15, 1.75), 1.35, (1, 0.95, 0.9)), mb))
    B0 = Vector((0, -0.15, 1.75))
    for (a, b) in [(-0.9, 0.05), (-0.45, 0.45), (0.0, 0.1), (0.45, 0.5), (0.9, 0.0), (-0.5, -0.45), (0.5, -0.4), (0.0, -0.6)]:
        u = Vector((math.sin(a) * math.cos(b), -math.cos(a) * math.cos(b), math.sin(b)))
        c = B0 + Vector((u.x * 1.38, u.y * 1.3, u.z * 1.25))
        C.append(paint(sph(c, 0.27, (1.0, 1.0, 0.9)), S((0.25, 0.24, 0.22))))
        C.append(paint(sph(c + Vector((0, -0.26, -0.03)), 0.15, (0.8, 1.2, 0.8)), S((0.3, 0.29, 0.26))))
        C.append(paint(sph(c + Vector((0, -0.42, -0.05)), 0.05), mp))
        for sx in (-1, 1):
            C.append(paint(sph(c + Vector((sx * 0.17, 0.0, 0.2)), 0.11, (0.5, 0.3, 1)), mp))
            C.append(paint(sph(c + Vector((sx * 0.09, -0.3, 0.1)), 0.04), glow(EYE, 2.5)))
    C.append(paint(sph((0, 0.05, 2.95), 1, (1.05, 0.85, 0.9)), mf))
    C.append(paint(sph((0, 0.5, 3.0), 1, (1.7, 0.7, 1.2)), mr))                       # capa esfarrapada
    for sx in (-1, 1):
        C.append(paint(sph((sx * 1.2, 0.0, 3.35), 0.5), mf))
    C.append(paint(capsule((0, -0.1, 3.2), (0, -0.25, 3.8), 0.5), mf))
    # --- cabeça: focinho de rato, orelhas enormes, coroa torta
    H = [paint(sph((0, 0, 4.5), 0.7, (1, 1, 0.95)), mf),
         paint(cone((0, -0.3, 4.45), (0, -1.4, 4.2), 0.5, 0.17), mf),
         paint(sph((0, -1.42, 4.2), 0.17), mp),
         paint(sph((0, -0.55, 3.95), 0.4, (1, 1.1, 0.5)), mfd),
         paint(box((0, -1.1, 3.93), (0.24, 0.07, 0.3), bevel=0.02), mbone)]
    for sx in (-1, 1):
        H.append(paint(sph((sx * 0.95, 0.1, 5.1), 1, (0.14, 0.6, 0.7), rot=(0, sx * 30, 0)), mfd))
        H.append(paint(sph((sx * 0.9, 0.0, 5.1), 1, (0.1, 0.45, 0.55), rot=(0, sx * 30, 0)), mp))
        H.append(paint(sph((sx * 0.3, -0.6, 4.75), 0.17), glow(EYE, 2.5)))
        H.append(paint(sph((sx * 0.3, -0.76, 4.75), 0.07), S((0.02, 0.02, 0.02))))
        for j in range(3):
            H.append(paint(tube([(sx * 0.15, -1.1, 4.2 + j * 0.04), (sx * 0.7, -1.3, 4.25 + j * 0.12), (sx * 1.3, -1.25, 4.3 + j * 0.25)], 0.018, 0.6), mbone))
    tilt = (12, 0, -14); cc = (0, 0.0, 5.2)
    cr = cyl(cc, 0.58, 0.3, rot=tilt, seg=14, bevel=0, r2=0.52); H.append(paint(cr, mbrass))
    for i in range(6):
        a = i / 6 * math.tau
        b = rot_about((math.cos(a) * 0.55, math.sin(a) * 0.55, 5.3), cc, tilt)
        t = rot_about((math.cos(a) * 0.58, math.sin(a) * 0.58, 5.85 + (0.2 if i % 2 else 0)), cc, tilt)
        H.append(paint(cone(b, t, 0.1, 0.02), mbrass))
        H.append(paint(sph(t, 0.06), glow((1, 0.2, 0.2), 2.5)))
    # --- membro esquerdo (+X): pata com cetro de osso
    L = [paint(capsule((1.4, 0, 3.1), (2.0, -0.9, 2.4), 0.4, 0.33), mf), paint(capsule((2.0, -0.9, 2.4), (2.3, -1.45, 1.95), 0.33, 0.3), mf),
         paint(sph((2.3, -1.55, 1.85), 0.38), mfd)]
    for i in range(3):
        L.append(paint(cone((2.3 + (i - 1) * 0.16, -1.8, 1.8), (2.3 + (i - 1) * 0.2, -2.15, 1.55), 0.06, 0.01), mbone))
    L.append(paint(cone((2.35, -1.25, 0.6), (2.35, -1.25, 4.45), 0.11, 0.07), mbone))
    L.append(paint(sph((2.35, -1.25, 4.75), 0.32), mbone))
    L.append(paint(torus((2.35, -1.25, 4.4), 0.2, 0.05), mbrass))
    L.append(paint(sph((2.35, -1.57, 4.75), 0.1), glow(EYE, 3)))
    for sx in (-1, 1):
        L.append(paint(cone((2.35 + sx * 0.2, -1.25, 4.9), (2.35 + sx * 0.45, -1.25, 5.15), 0.07, 0.01), mbone))
    # --- membro direito (-X): garra enorme
    R = [paint(sph((-1.4, 0, 3.25), 0.75), mf), paint(capsule((-1.4, 0, 3.1), (-1.9, -0.9, 2.2), 0.55, 0.5), mf),
         paint(capsule((-1.9, -0.9, 2.2), (-2.0, -1.4, 1.35), 0.5, 0.55), mf), paint(sph((-2.0, -1.5, 1.1), 0.75, (1, 1.1, 0.7)), mfd)]
    for i in range(4):
        x = -2.0 + (i - 1.5) * 0.34
        R.append(paint(cone((x, -1.95, 1.1), (x * 1.04, -2.6, 0.25), 0.15, 0.02), mbone))
    return {"core": finish("plague_core", C), "head": finish("plague_head", H), "left": finish("plague_left", L), "right": finish("plague_right", R)}


# ------------------------------------------------------------------ 2. DRAGÃO AVARENTO
def dragon():
    SC, SCD, SCL = (0.55, 0.2, 0.1), (0.3, 0.1, 0.07), (0.72, 0.27, 0.13)
    HORN, EMB = (0.85, 0.78, 0.6), (1.0, 0.22, 0.02)
    msc, mscd, mscl = S(SC, 0.55), S(SCD, 0.5), S(SCL, 0.7)
    mgold, mhorn = S((0.95, 0.6, 0.12), 0.35, metal=0.85), S(HORN, 0.5)
    rnd = random.Random(11)
    # --- núcleo: monte de moedas, corpo deitado, cauda, pescoço e coração-brasa exposto no peito
    C = [paint(sph((0, 0, 0.35), 1, (2.1, 1.95, 1.0)), mgold)]
    for i in range(70):
        th, ph = rnd.uniform(0.1, 1.25), rnd.uniform(0, math.tau)
        p = (2.05 * math.sin(th) * math.cos(ph), 1.9 * math.sin(th) * math.sin(ph), 0.35 + 0.98 * math.cos(th))
        C.append(paint(cyl(p, 0.3, 0.07, rot=(rnd.uniform(-35, 35), rnd.uniform(-35, 35), rnd.uniform(0, 90)), seg=14, bevel=0), mgold))
    C.append(paint(sph((0, 0.4, 1.8), 1, (1.45, 1.9, 1.1)), msc))
    C.append(paint(sph((0, -0.7, 2.25), 1, (1.15, 0.95, 1.05)), mscl))
    C.append(paint(tube([(0, 1.5, 1.5), (0.7, 1.7, 1.0), (1.7, 1.4, 0.6), (2.1, 0.4, 0.4), (1.9, -1.0, 0.35)], 0.5, 0.15), msc))
    C.append(paint(tube([(0, 0.5, 2.5), (0, -0.2, 3.3), (0, -0.95, 4.0)], 0.55, 0.9), msc))
    for i in range(6):   # espinhos nas costas
        y = 1.7 - i * 0.55
        C.append(paint(cone((0, y, 2.5 - 0.12 * i), (0, y - 0.1, 3.1 - 0.12 * i), 0.2, 0.02), mscd))
    C.append(paint(torus((0, -1.15, 2.95), 0.66, 0.13, rot=(50, 0, 0)), mscd))
    C.append(paint(sph((0, -1.25, 2.95), 0.58), glow(EMB, 2.0)))
    # --- cabeça: chifres, focinho comprido, fornalha na boca
    H = [paint(sph((0, -1.0, 4.45), 0.6, (1, 1.15, 0.9)), msc),
         paint(cone((0, -1.4, 4.45), (0, -2.3, 4.25), 0.46, 0.3), msc),
         paint(capsule((0, -1.3, 3.95), (0, -2.2, 3.75), 0.27, 0.2), mscl),
         paint(sph((0, -1.9, 4.0), 0.3, (0.85, 1.3, 0.55)), glow(EMB, 3.5)),
         paint(box((0, -1.55, 4.8), (0.85, 0.3, 0.18), bevel=0.03), mscd)]
    for sx in (-1, 1):
        H.append(paint(sph((sx * 0.38, -1.7, 4.68), 0.13), glow((1, 0.9, 0.1), 3)))
        H.append(paint(tube([(sx * 0.35, -0.7, 4.9), (sx * 0.8, -0.2, 5.35), (sx * 1.0, 0.45, 5.7)], 0.14, 0.25), mhorn))
        H.append(paint(sph((sx * 0.14, -2.3, 4.3), 0.06), glow(EMB, 3.5)))
        for j in range(3):
            H.append(paint(cone((sx * 0.22, -2.1 + j * 0.3, 4.05 - j * 0.04), (sx * 0.22, -2.1 + j * 0.3, 3.8 - j * 0.04), 0.05, 0.01), mhorn))
    for j in range(3):
        H.append(paint(cone((0, -0.5 + j * 0.25, 5.0 - j * 0.03), (0, -0.4 + j * 0.25, 5.55 - j * 0.08), 0.12, 0.02), mscd))
    # --- membro esquerdo (+X): asa
    wp = (0.9, 0.6, 2.6); wr = (2.3, 0.2, 5.2)
    F = [(2.5, 0.5, 3.4), (2.2, 0.9, 2.5), (1.3, 1.1, 2.1)]
    L = [paint(tube([wp, (1.7, 0.5, 4.0), wr], 0.17, 0.55), mscd), paint(sph(wp, 0.35), msc)]
    for f in F:
        L.append(paint(tube([wr, ((wr[0] + f[0]) / 2, (wr[1] + f[1]) / 2, (wr[2] + f[2]) / 2), f], 0.08, 0.4), mscd))
    L.append(membrane([[wr, F[0], F[1]], [wr, F[1], F[2]], [wr, F[2], wp]], S((0.8, 0.28, 0.1), 0.7, emit=0.0)))
    L.append(paint(cone(wr, (wr[0] + 0.15, wr[1] - 0.1, wr[2] + 0.55), 0.1, 0.01), mhorn))
    # --- membro direito (-X): garra sobre o ouro
    R = [paint(sph((-1.0, -0.2, 2.3), 0.62), msc), paint(capsule((-1.0, -0.2, 2.2), (-1.65, -1.2, 1.5), 0.46, 0.4), msc),
         paint(capsule((-1.65, -1.0, 1.5), (-1.5, -1.4, 0.9), 0.4, 0.38), msc), paint(sph((-1.5, -1.5, 0.85), 0.55, (1, 1.2, 0.6)), mscl)]
    for i in range(4):
        x = -1.5 + (i - 1.5) * 0.28
        R.append(paint(cone((x, -1.9, 0.8), (x * 1.03, -2.4, 0.4), 0.1, 0.01), mhorn))
    for i in range(4):
        R.append(paint(cyl((-1.8 + i * 0.25, -1.9 + (i % 2) * 0.25, 0.55), 0.24, 0.06, rot=(rnd.uniform(-30, 30), rnd.uniform(-30, 30), 0), seg=14, bevel=0), mgold))
    hd = finish("dragon_head", H)
    hd.data.transform(Matrix.Translation((0, -1.0, 4.4)) @ Matrix.Scale(1.3, 4) @ Matrix.Translation((0, 1.0, -4.4)))
    return {"core": finish("dragon_core", C), "head": hd, "left": finish("dragon_left", L), "right": finish("dragon_right", R)}


# ------------------------------------------------------------------ 3. LICH
def lich():
    ROBE, ROBED, GRN = (0.13, 0.05, 0.22), (0.06, 0.02, 0.1), (0.04, 1.0, 0.2)
    mrobe, mrobed, mbone = S(ROBE, 0.9), S(ROBED, 0.9), S(BONE, 0.6)
    mgold = S((0.62, 0.5, 0.22), 0.35, metal=1.0)
    # --- núcleo: manto flutuando, caixa torácica aberta com o filactério brilhante, ombreiras
    C = [paint(cyl((0, 0, 1.7), 1.35, 1.6, seg=24, bevel=0, r2=0.95), mrobe), paint(cone((0, 0, 1.0), (0, 0, 0.35), 0.8, 0.05, 20), mrobed)]
    for i in range(14):
        a = i / 14 * math.tau
        C.append(paint(cone((math.cos(a) * 1.15, math.sin(a) * 1.15, 1.05), (math.cos(a) * 1.3, math.sin(a) * 1.3, 0.55), 0.22, 0.02, 8), mrobed))
    C.append(paint(sph((0, 0.3, 3.3), 1, (1.5, 0.7, 0.9)), mrobed))
    C.append(paint(capsule((0, 0.25, 2.2), (0, 0.25, 3.7), 0.12), mbone))
    for i in range(5):
        C.append(paint(torus((0, 0.0, 2.45 + i * 0.26), 0.7 - 0.05 * abs(i - 2) ** 1.3, 0.055, s=(1, 0.75, 1)), mbone))
    C.append(paint(sph((0, -0.3, 2.9), 0.4), glow(GRN, 2.2)))
    C.append(paint(torus((0, -0.3, 2.9), 0.52, 0.04, rot=(90, 0, 0)), mgold))
    for sx in (-1, 1):
        C.append(paint(sph((sx * 1.15, 0.0, 3.5), 0.5, (1, 0.9, 0.6)), mrobed))
        for j in range(3):
            C.append(paint(cone((sx * (0.95 + j * 0.25), -0.05, 3.7), (sx * (1.05 + j * 0.3), -0.05, 4.2), 0.1, 0.01), mbone))
    # --- cabeça: caveira coroada, chamas espectrais
    H = [paint(sph((0, -0.05, 4.5), 0.55, (1, 1, 1.05)), mbone), paint(sph((0, -0.3, 4.0), 0.36, (1, 0.8, 0.7)), mbone),
         paint(sph((0, -0.52, 4.35), 0.07, (1, 0.6, 1.3)), S((0.03, 0.02, 0.03)))]
    for sx in (-1, 1):
        H.append(paint(sph((sx * 0.2, -0.5, 4.6), 0.16, (1, 0.7, 1.1)), S((0.03, 0.02, 0.04))))
        H.append(paint(sph((sx * 0.2, -0.58, 4.6), 0.08), glow(GRN, 4)))
    for j in range(5):
        H.append(paint(box(((j - 2) * 0.1, -0.62, 3.98), (0.07, 0.06, 0.16), bevel=0.01), mbone))
    H.append(paint(cyl((0, -0.02, 5.07), 0.6, 0.24, seg=14, bevel=0, r2=0.55), mgold))
    for i in range(7):
        a = i / 7 * math.tau
        H.append(paint(cone((math.cos(a) * 0.55, math.sin(a) * 0.55, 5.15), (math.cos(a) * 0.6, math.sin(a) * 0.6, 5.65), 0.09, 0.01), mgold))
    for (x, y, h) in [(0, 0, 0.95), (-0.35, 0.1, 0.65), (0.35, 0.1, 0.65), (0, 0.35, 0.55)]:
        H.append(paint(cone((x, y, 5.25), (x, y, 5.25 + h * 0.95), 0.2, 0.01, 10), glow(GRN, 2.0)))
    # --- membro esquerdo (+X): mão com o grimório aberto
    L = [paint(cone((1.2, 0, 3.4), (1.75, -0.95, 2.45), 0.38, 0.55), mrobe),
         paint(sph((1.8, -1.0, 2.35), 0.2), mbone)]
    for i in range(4):
        L.append(paint(tube([(1.8, -1.0, 2.4), (1.8 + (i - 1.5) * 0.12, -1.25, 2.55), (1.8 + (i - 1.5) * 0.18, -1.45, 2.6)], 0.035, 0.6), mbone))
    bc = (1.6, -1.15, 3.0)
    for sx in (-1, 1):
        L.append(paint(box((bc[0] + sx * 0.33, bc[1], bc[2] - 0.04), (0.62, 0.8, 0.07), rot=(0, sx * 22, 0), bevel=0.01), S((0.4, 0.06, 0.08), 0.6)))
        L.append(paint(box((bc[0] + sx * 0.33, bc[1], bc[2]), (0.56, 0.74, 0.04), rot=(0, sx * 22, 0), bevel=0.005), S((0.92, 0.88, 0.72), 0.7)))
    for k in range(4):
        L.append(paint(sph((bc[0] + (k - 1.5) * 0.22, bc[1] - 0.05 + (k % 2) * 0.12, bc[2] + 0.45 + (k % 3) * 0.12), 0.07), glow(GRN, 3.5)))
    # --- membro direito (-X): mão com a foice
    R = [paint(cone((-1.2, 0, 3.4), (-1.65, -0.95, 2.5), 0.38, 0.55), mrobe), paint(sph((-1.7, -1.0, 2.4), 0.2), mbone)]
    for i in range(4):
        R.append(paint(tube([(-1.7, -1.0, 2.5), (-1.7 + (i - 1.5) * 0.1, -1.2, 2.6), (-1.7 + (i - 1.5) * 0.12, -1.0, 2.7)], 0.035, 0.6), mbone))
    R.append(paint(cone((-1.7, -1.0, 0.5), (-1.7, -1.0, 5.3), 0.09, 0.07), S((0.25, 0.17, 0.12), 0.7)))
    R.append(paint(tube([(-1.7, -1.0, 5.35), (-2.05, -1.0, 5.6), (-2.4, -1.0, 5.4), (-2.55, -1.0, 4.9)], 0.17, 0.12), S((0.72, 0.78, 0.85), 0.25, metal=1.0)))
    R.append(paint(sph((-1.7, -1.0, 5.4), 0.13), glow(GRN, 3.5)))
    parts = {"core": finish("lich_core", C), "head": finish("lich_head", H), "left": finish("lich_left", L), "right": finish("lich_right", R)}
    # círculo ritual: cenário, NÃO é parte
    D = [paint(cyl((0, 0, 0.03), 2.7, 0.06, seg=48, bevel=0), S((0.12, 0.1, 0.14), 0.9))]
    for rr, w in [(2.55, 0.05), (1.85, 0.04)]:
        D.append(paint(torus((0, 0, 0.08), rr, w), glow(GRN, 4)))
    for k in range(5):
        a1, a2 = k / 5 * math.tau, ((k + 2) % 5) / 5 * math.tau
        p1, p2 = Vector((math.cos(a1), math.sin(a1), 0)) * 2.5, Vector((math.cos(a2), math.sin(a2), 0)) * 2.5
        m = (p1 + p2) / 2
        D.append(paint(box((m.x, m.y, 0.08), ((p2 - p1).length, 0.08, 0.03), rot=(0, 0, math.degrees(math.atan2(p2.y - p1.y, p2.x - p1.x))), bevel=0), glow(GRN, 4)))
    parts["circle"] = finish("lich_circle", D)
    return parts


FIT = {"plague": 0.88, "dragon": 0.85, "lich": 0.95}   # escala uniforme final p/ o porte do chefe atual (5,6 x 4,2 x 3,2 m)


def _fit(fn, k):
    def run():
        parts = fn()
        for o in parts.values():
            o.data.transform(Matrix.Scale(k, 4))
        return parts
    return run


BUILD = {"plague": _fit(plague, FIT["plague"]), "dragon": _fit(dragon, FIT["dragon"]), "lich": _fit(lich, FIT["lich"])}
TITLES = {"plague": "Rainha da Praga", "dragon": "Dragão Avarento", "lich": "Lich", "cur": "Lorde das Trevas (atual)"}


def current_boss():
    """O chefe atual (boss.py) nas posições de PART_OFFSETS (Godot -> Blender: x invertido, y vira z)."""
    import boss as B
    offs = {"core": (0, 0, 0), "head": (0, 0, 4.3), "left": (1.6, 0, 2.4), "right": (-1.6, 0, 2.4)}
    fn = {"core": B.boss_core, "head": B.boss_head, "left": B.boss_left_arm, "right": B.boss_right_arm}
    out = {}
    for k in PARTS:
        root = fn[k]()
        kids = [o for o in root.children_recursive if o.type == 'MESH']
        for o in kids:
            if o.modifiers:
                apply_mods(o)
        for o in kids:
            o.parent = None
        bpy.data.objects.remove(root)
        o = join(kids, "cur_" + k)
        o.data.transform(o.matrix_world); o.matrix_world = Matrix()
        o.location = offs[k]
        out[k] = o
    return out


# ------------------------------------------------------------------ cena e renders
def new_scene(w, h, ground=None):
    ground = ground or 150
    bpy.ops.wm.read_factory_settings(use_empty=True)
    mk._MATS.clear()
    sc = bpy.context.scene
    items = [i.identifier for i in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items]
    sc.render.engine = next((e for e in ("BLENDER_EEVEE_NEXT", "BLENDER_EEVEE") if e in items), items[0])
    try:
        sc.eevee.taa_render_samples = 48
    except Exception:
        pass
    sc.render.resolution_x, sc.render.resolution_y = w, h
    sc.view_settings.view_transform = 'AgX'
    try:
        sc.view_settings.look = 'AgX - Punchy'
    except Exception:
        pass
    wd = bpy.data.worlds.new("W"); sc.world = wd; wd.use_nodes = True
    bg = next(n for n in wd.node_tree.nodes if n.type == 'BACKGROUND'); bg.inputs[0].default_value = (0.6, 0.7, 0.85, 1); bg.inputs[1].default_value = 0.45
    sun = bpy.data.lights.new("Sun", 'SUN'); sun.energy = 3.4; sun.angle = math.radians(8)
    so = bpy.data.objects.new("Sun", sun); sc.collection.objects.link(so); so.rotation_euler = (math.radians(50), 0, math.radians(-30))
    fill = bpy.data.lights.new("Fill", 'SUN'); fill.energy = 1.2; fill.color = (0.8, 0.85, 1.0)
    fo = bpy.data.objects.new("Fill", fill); sc.collection.objects.link(fo); fo.rotation_euler = (math.radians(60), 0, math.radians(150))
    g = cyl((0, 0, -0.06), ground, 0.12, seg=64, bevel=0)
    setmat(g, S((0.2, 0.19, 0.17), 0.95)); shade(g)
    return sc


def camera(sc, loc, look, lens=50):
    cd = bpy.data.cameras.new("Cam"); cd.lens = lens; cd.clip_end = 300
    c = bpy.data.objects.new("Cam", cd); sc.collection.objects.link(c)
    c.location = loc
    c.rotation_euler = (Vector(look) - Vector(loc)).to_track_quat('-Z', 'Y').to_euler()
    sc.camera = c
    return c


def render(sc, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    sc.render.filepath = path
    bpy.ops.render.render(write_still=True)


def flat_parts(parts):
    for k in PARTS:
        c = PART_COL[k]
        m = bpy.data.materials.new("flat_" + k); m.use_nodes = True
        p = next(n for n in m.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
        p.inputs['Base Color'].default_value = (*c, 1); p.inputs['Roughness'].default_value = 0.8
        p.inputs['Emission Color'].default_value = (*c, 1); p.inputs['Emission Strength'].default_value = 0.45
        setmat(parts[k], m)
    if "circle" in parts:
        setmat(parts["circle"], S((0.5, 0.5, 0.5), 0.9))


def bbox(parts):
    bpy.context.view_layer.update()
    lo = Vector((1e9,) * 3); hi = Vector((-1e9,) * 3)
    for o in parts.values():
        for c in o.bound_box:
            p = o.matrix_world @ Vector(c); lo = Vector(map(min, lo, p)); hi = Vector(map(max, hi, p))
    return lo, hi


def shoot_one(name, out):
    sc = new_scene(1200, 900, ground=4.4)
    parts = BUILD[name]()
    lo, hi = bbox({k: v for k, v in parts.items() if k != "circle"})
    print("MEDIDAS %s: largura %.2f profundidade %.2f altura %.2f (x %.2f..%.2f)" % (name, hi.x - lo.x, hi.y - lo.y, hi.z, lo.x, hi.x))
    tgt = (0, 0, 2.8)
    camera(sc, (5.6, -12.5, 5.2), tgt)
    render(sc, os.path.join(out, name, "frente.png"))
    a = math.radians(55)
    camera(sc, (0, -math.cos(a) * 15, 2.5 + math.sin(a) * 15), (0, 0, 2.5))
    render(sc, os.path.join(out, name, "jogo.png"))


def shoot_sheet(out):
    sc = new_scene(2400, 760)
    xs = {"cur": -9.75, "plague": -3.25, "dragon": 3.25, "lich": 9.75}
    built = {"cur": current_boss()}
    for n in BUILD:
        built[n] = BUILD[n]()
    for n, parts in built.items():
        if n == "cur":
            lo, hi = bbox(parts)
            print("MEDIDAS atual: largura %.2f profundidade %.2f altura %.2f" % (hi.x - lo.x, hi.y - lo.y, hi.z))
        for o in parts.values():
            o.location.x += xs[n]
    camera(sc, (0, -42, 11.5), (0, 0, 3.0), 50)
    render(sc, os.path.join(out, "chefes_raw.png"))
    for parts in built.values():
        flat_parts(parts)
    render(sc, os.path.join(out, "chefes_partes_raw.png"))


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    out = next((a.split("=", 1)[1] for a in argv if a.startswith("--out=")), os.path.join(HERE, "..", "..", "..", "docs", "decisoes_2026-11-10", "chefes"))
    out = os.path.abspath(out)
    only = next((a.split("=", 1)[1].split(",") for a in argv if a.startswith("--only=")), None)
    sheet = "--sheet" in argv
    if only is None and not sheet:
        only, sheet = list(BUILD), True
    for n in (only or []):
        shoot_one(n, out)
    if sheet:
        shoot_sheet(out)


main()
