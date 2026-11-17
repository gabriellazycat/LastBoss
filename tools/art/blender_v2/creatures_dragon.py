"""Criaturas do Dragão Avarento e dos comuns (lote 10/11/2026): Guarda do Tesouro, Dragão Ancião e Troll das Cavernas.
Mesmo kit de mk.py. O modelo da carta é o do jogo (scenes_dragon.py chama estas funções).
Exportar (cada um com sua animação em VAT, como build.py faz com UNITS):
"C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --factory-startup -P tools/art/blender_v2/creatures_dragon.py -- <pasta de saída> [ids,separados]
Depois: godot --headless --path . -s res://tools/art/import_v2.gd -- --src=<pasta de saída>
Blender: Z para cima, frente = -Y; +x = lado "l" dos ossos (como no ogro)."""
import os, sys, math, traceback
HERE = os.path.dirname(os.path.abspath(__file__))
if HERE not in sys.path:
    sys.path.insert(0, HERE)
import bpy
from mathutils import Matrix, Vector
from mk import *
from vat import tag, rot_about, tr
import mk, vat, anims
import monsters2
from monsters2 import yellow_eye
from monsters import xform
from chars import GOLD, LEATHER, WOOD, BLACK

# id -> (altura em metros no jogo, orçamento de triângulos)
UNITS_DRAGON = {"treasure_guard": (2.0, 3000), "elder_dragon": (4.2, 3400), "cave_troll": (2.7, 3000)}

BONE = (0.93, 0.89, 0.76)
SHADOW = (0.03, 0.02, 0.03)


def _ellip_chain(pts, rs, name, vox=0.02, mat_=None):
    """Cadeia de elipsoides fundidos ao longo de pontos (r = (rx, ry, rz) em cada um)."""
    return fuse([sph(p, 1, r) for p, r in zip(pts, rs)], name, vox, 0.6, 5)


# =============================================================== Troll das Cavernas

def cave_troll():
    P = []
    SK = (0.43, 0.52, 0.55); SKD = (0.24, 0.3, 0.36); MOSS = (0.36, 0.5, 0.24)
    sk = mat("trollskin", vcol=True, rough=0.7, bump=0.25, bump_scale=40)

    def col(p, n):
        c = mix(SKD, SK, smoothstep(-0.2, 0.9, n.z) * 0.55 + 0.25)
        c = mix(c, (0.62, 0.62, 0.55), ell_w(p, (0, -0.4, 1.0), (0.4, 0.25, 0.4)) * 0.5)   # barriga clara
        c = mix(c, MOSS, ell_w(p, (0.45, 0.2, 1.75), (0.35, 0.3, 0.2)) * 0.7)             # musgo nos ombros
        c = mix(c, MOSS, ell_w(p, (-0.4, 0.3, 1.7), (0.3, 0.3, 0.2)) * 0.6)
        return c
    # tronco curvado, ombros enormes
    B = []
    body = fuse([sph((0, 0.05, 1.18), 1, (0.55, 0.42, 0.5)), sph((0, 0.15, 1.62), 1, (0.78, 0.46, 0.34)), sph((0, -0.12, 0.92), 1, (0.52, 0.42, 0.38)),
                 sph((0, 0.3, 1.78), 1, (0.38, 0.3, 0.22))], "troll_body", 0.02, 0.6, 6)
    paint(body, col); setmat(body, sk); B.append(body)
    loin = cyl((0, 0, 0.88), 0.55, 0.3, seg=40, bevel=0.03, r2=0.5); hard(loin); setmat(loin, mat("fur", (0.42, 0.28, 0.16), 0.9, bump=0.4, bump_scale=90)); B.append(loin)
    belt = torus((0, 0, 1.0), 0.53, 0.045, s=(1, 0.86, 1)); shade(belt); setmat(belt, mat("leather", LEATHER, 0.55)); B.append(belt)
    sku = sph((0, -0.46, 1.0), 0.09, (1, 0.8, 1.1)); shade(sku); setmat(sku, mat("bone", BONE, 0.6)); B.append(sku)
    for (x, y, z, r) in ((0.3, -0.35, 1.5, 0.045), (-0.25, -0.38, 1.35, 0.04), (0.1, -0.45, 1.2, 0.035), (-0.5, 0.0, 1.8, 0.05)):   # verrugas
        w = sph((x, y, z), r); shade(w); setmat(w, mat("wart", (0.55, 0.6, 0.45), 0.7)); B.append(w)
    tag(B, "body"); P += B
    # cabeça pequena, queixo enorme, presas
    H = []
    head = fuse([sph((0, -0.32, 2.0), 1, (0.3, 0.3, 0.27)), sph((0, -0.52, 1.84), 1, (0.27, 0.22, 0.14)), sph((0, -0.6, 2.0), 1, (0.08, 0.08, 0.07)),
                 sph((0, -0.42, 2.18), 1, (0.24, 0.13, 0.07))], "troll_head", 0.01, 0.6, 5)
    paint(head, lambda p, n: mix(SKD, SK, smoothstep(-0.2, 0.9, n.z) * 0.5 + 0.3)); setmat(head, sk); H.append(head)
    for sx in (-1, 1):
        H += yellow_eye((sx * 0.13, -0.6, 2.06), 0.06, 28, sx)
        tu = box((sx * 0.14, -0.68, 1.86), (0.06, 0.05, 0.2), (0, sx * 8, 0), bevel=0.015, taper=(0.2, 0.3)); hard(tu, 1); setmat(tu, mat("tusk", (0.95, 0.9, 0.75), 0.4)); H.append(tu)
        ear = sph((sx * 0.36, -0.2, 2.05), 1, (0.22, 0.04, 0.1), (0, 0, sx * -15)); shade(ear); setmat(ear, mat("trollear", SK, 0.7)); H.append(ear)
    mo = sph((0, -0.7, 1.8), 1, (0.17, 0.06, 0.05)); setmat(mo, mat("shadow", SHADOW, 0.9)); H.append(mo)
    hr = mat("trollhair", (0.18, 0.2, 0.15), 0.9, bump=0.6, bump_scale=80)
    for k in range(5):
        tf = sph((-0.2 + k * 0.1, -0.22, 2.3 - abs(k - 2) * 0.04), 1, (0.05, 0.05, 0.14), (-10, 0, (k - 2) * 15)); shade(tf); setmat(tf, hr); H.append(tf)
    tag(H, "head"); P += H
    # braços compridos e punhos enormes (arm_l = +x, segura a clava)
    for sx, bone in ((1, "arm_l"), (-1, "arm_r")):
        A = []
        arm = fuse(capsule((sx * 0.72, 0.1, 1.65), (sx * 0.95, -0.05, 1.15), 0.2, 0.17) + capsule((sx * 0.95, -0.05, 1.15), (sx * 0.9, -0.3, 0.68), 0.17, 0.15)
                   + [sph((sx * 0.9, -0.36, 0.58), 0.2)], "troll_arm", 0.015, 0.6, 5)
        paint(arm, col); setmat(arm, sk); A.append(arm)
        for k in (-1, 0, 1):
            c = sph((sx * 0.9 + k * 0.09, -0.52, 0.52), 1, (0.045, 0.07, 0.04)); shade(c); setmat(c, mat("claw", (0.15, 0.13, 0.1), 0.4)); A.append(c)
        if sx == 1:   # clava: tronco com pedra presa
            club = fuse(capsule((0.9, -0.36, 0.5), (1.15, -0.55, 1.9), 0.09, 0.22), "club", 0.015, 0.5, 3); setmat(club, mat("wood", WOOD, 0.7, bump=0.4, bump_scale=20)); A.append(club)
            for k in range(6):
                a = k * 1.1
                st = box((1.1 + math.cos(a) * 0.2, -0.5 + math.sin(a) * 0.2, 1.4 + (k % 3) * 0.17), (0.07, 0.07, 0.15), (0, 0, 0), bevel=0.01, taper=(0.15, 0.15))
                st.rotation_euler = Vector((0, 0, 1)).rotation_difference(Vector((math.cos(a), math.sin(a), 0.2))).to_euler()
                hard(st); setmat(st, mat("stone", (0.5, 0.5, 0.52), 0.8)); A.append(st)
        tag(A, bone); P += A
    # pernas curtas e grossas
    for sx, bone in ((1, "leg_l"), (-1, "leg_r")):
        L = []
        leg = fuse(capsule((sx * 0.32, 0.0, 1.0), (sx * 0.36, -0.08, 0.45), 0.24, 0.19), "troll_leg", 0.015, 0.6, 5)
        leg2 = fuse([sph((sx * 0.37, -0.2, 0.08), 1, (0.22, 0.34, 0.1))], "troll_foot", 0.012, 0.6, 3)
        for o in (leg, leg2):
            paint(o, lambda p, n: mix(SKD, SK, smoothstep(0.0, 1.0, n.z) * 0.5 + 0.2)); setmat(o, sk); L.append(o)
        tag(L, bone); P += L
    return group("cave_troll", P)


# =============================================================== Guarda do Tesouro

def treasure_guard():
    P = []
    steel = mat("gsteel", (0.5, 0.52, 0.58), 0.4, 0.85, bump=0.05, bump_scale=10)
    steel_d = mat("gsteel_d", (0.3, 0.31, 0.36), 0.45, 0.85)
    gold = mat("ggold", (1.0, 0.62, 0.1), 0.25, 1.0)
    red = mat("gred", (0.62, 0.1, 0.1), 0.75, bump=0.1, bump_scale=120)
    leather = mat("gleather", LEATHER, 0.55, bump=0.1, bump_scale=60)
    B = []
    chest = fuse([sph((0, 0, 1.12), 1, (0.44, 0.33, 0.36)), sph((0, -0.02, 0.9), 1, (0.38, 0.29, 0.22))], "gchest", 0.012, 0.6, 4); setmat(chest, steel); B.append(chest)
    skirt = cyl((0, 0, 0.62), 0.42, 0.34, seg=40, bevel=0.03, r2=0.34); hard(skirt); setmat(skirt, red); B.append(skirt)
    tab = box((0, -0.34, 0.8), (0.3, 0.03, 0.6), (-4, 0, 0), bevel=0.01, taper=(0.5, 1)); hard(tab); setmat(tab, red); B.append(tab)
    mark = box((0, -0.36, 0.95), (0.14, 0.02, 0.2), (0, 0, 0), bevel=0.01, taper=(0.5, 1)); hard(mark); setmat(mark, gold); B.append(mark)   # emblema: gota/garra dourada
    belt = torus((0, 0, 0.8), 0.37, 0.045, s=(1, 0.88, 1)); shade(belt); setmat(belt, leather); B.append(belt)
    bk = box((0, -0.37, 0.8), (0.12, 0.03, 0.1), bevel=0.01); hard(bk); setmat(bk, gold); B.append(bk)
    gorget = torus((0, -0.02, 1.4), 0.2, 0.06); shade(gorget); setmat(gorget, steel); B.append(gorget)
    cape = fuse([sph((0, 0.3, 0.9), 1, (0.4, 0.05, 0.55), (6, 0, 0))] + [sph((x, 0.33, 0.45), 1, (0.09, 0.05, 0.2)) for x in (-0.28, -0.1, 0.1, 0.28)], "gcape", 0.012, 0.6, 3)
    setmat(cape, red); B.append(cape)
    tag(B, "body"); P += B
    # elmo com chifres de dragão e viseira com olhos de brasa
    H = []
    helm = fuse([sph((0, -0.02, 1.7), 1, (0.38, 0.36, 0.36)), sph((0, -0.2, 1.58), 1, (0.3, 0.22, 0.2))], "ghelm", 0.01, 0.6, 4); setmat(helm, steel); H.append(helm)
    vis = box((0, -0.4, 1.66), (0.42, 0.05, 0.08), (0, 0, 0), bevel=0.01); setmat(vis, mat("shadow", SHADOW, 0.9)); hard(vis); H.append(vis)
    for sx in (-1, 1):
        e = sph((sx * 0.12, -0.43, 1.66), 1, (0.05, 0.02, 0.025)); setmat(e, mat("emberyes", (1.0, 0.45, 0.1), 0.4, emit=6.0)); H.append(e)
        hn = tube([(sx * 0.3, 0.0, 1.82), (sx * 0.5, 0.0, 2.0), (sx * 0.48, -0.06, 2.3)], 0.07, 0.15, 12); setmat(hn, mat("ghorn", BONE, 0.5)); H.append(hn)
    cr = box((0, -0.0, 2.0), (0.05, 0.5, 0.18), (0, 0, 0), bevel=0.02); hard(cr, 1); setmat(cr, gold); H.append(cr)
    grill = box((0, -0.41, 1.5), (0.26, 0.04, 0.16), bevel=0.01); hard(grill); setmat(grill, steel_d); H.append(grill)
    tag(H, "head"); P += H
    # ombreiras grandes e braços; lança no lado +x (arm_l), escudo-torre no lado -x (arm_r)
    A = []
    paul = fuse([sph((0.5, 0.0, 1.38), 1, (0.22, 0.22, 0.14)), sph((0.55, 0.0, 1.46), 1, (0.17, 0.17, 0.1))], "paul", 0.01, 0.5, 3); setmat(paul, steel); A.append(paul)
    arm = fuse(capsule((0.52, 0.0, 1.3), (0.62, -0.2, 1.0), 0.1, 0.085) + capsule((0.62, -0.2, 1.0), (0.5, -0.45, 1.0), 0.085, 0.075) + [sph((0.48, -0.5, 1.0), 0.1)], "garm", 0.01, 0.5, 3)
    setmat(arm, steel_d); A.append(arm)
    sp = tube([(0.5, 0.1, 0.0), (0.5, -0.45, 1.0), (0.5, -0.95, 2.2)], 0.025, 1.0, 14); setmat(sp, mat("wood", WOOD, 0.7)); A.append(sp)
    pt = box((0.5, -0.97, 2.4), (0.1, 0.03, 0.38), (0, 0, 0), bevel=0.01, taper=(0.1, 0.5)); hard(pt); setmat(pt, mat("blade", (0.85, 0.88, 0.93), 0.18, 1.0)); A.append(pt)
    pg = box((0.5, -0.97, 2.18), (0.2, 0.04, 0.04), bevel=0.01); hard(pg); setmat(pg, gold); A.append(pg)
    tag(A, "arm_l"); P += A
    S = []
    paul2 = fuse([sph((-0.5, 0.0, 1.38), 1, (0.22, 0.22, 0.14)), sph((-0.55, 0.0, 1.46), 1, (0.17, 0.17, 0.1))], "paul2", 0.01, 0.5, 3); setmat(paul2, steel); S.append(paul2)
    arm2 = fuse(capsule((-0.52, 0.0, 1.3), (-0.62, -0.15, 1.0), 0.1, 0.085) + capsule((-0.62, -0.15, 1.0), (-0.58, -0.4, 1.1), 0.085, 0.075), "garm2", 0.01, 0.5, 3); setmat(arm2, steel_d); S.append(arm2)
    sc = (-0.74, -0.42, 0.85)
    shd = box(sc, (0.1, 0.62, 1.1), (0, 0, 0), bevel=0.03, taper=(1, 1)); hard(shd); setmat(shd, red); S.append(shd)
    for (dz, dy) in ((0.52, 0.0), (-0.52, 0.0)):
        rm = box((sc[0] - 0.01, sc[1], sc[2] + dz), (0.13, 0.66, 0.06), bevel=0.01); hard(rm); setmat(rm, gold); S.append(rm)
    for dy in (-0.31, 0.31):
        rm = box((sc[0] - 0.01, sc[1] + dy, sc[2]), (0.13, 0.06, 1.12), bevel=0.01); hard(rm); setmat(rm, gold); S.append(rm)
    cl = fuse([sph((sc[0] - 0.08, sc[1], sc[2] + 0.05), 1, (0.05, 0.16, 0.2)), sph((sc[0] - 0.08, sc[1] - 0.1, sc[2] + 0.2), 1, (0.05, 0.06, 0.09))], "claw", 0.008, 0.4, 2); setmat(cl, gold); S.append(cl)
    ey = sph((sc[0] - 0.13, sc[1] - 0.04, sc[2] + 0.12), 1, (0.02, 0.04, 0.03)); setmat(ey, mat("emberyes", (1.0, 0.45, 0.1), 0.4, emit=6.0)); S.append(ey)
    tag(S, "arm_r"); P += S
    # pernas com grevas
    for sx, bone in ((1, "leg_l"), (-1, "leg_r")):
        L = []
        leg = fuse(capsule((sx * 0.2, 0.0, 0.62), (sx * 0.22, -0.04, 0.3), 0.12, 0.1) + [sph((sx * 0.22, -0.14, 0.06), 1, (0.14, 0.24, 0.08))], "gleg", 0.01, 0.5, 3); setmat(leg, steel_d); L.append(leg)
        gr = cyl((sx * 0.22, -0.06, 0.34), 0.13, 0.32, seg=18, bevel=0.015, r2=0.1); hard(gr); setmat(gr, steel); L.append(gr)
        kn = sph((sx * 0.21, -0.12, 0.5), 1, (0.12, 0.1, 0.09)); shade(kn); setmat(kn, gold); L.append(kn)
        tag(L, bone); P += L
    return group("treasure_guard", P)


# =============================================================== Dragão Ancião

RS = (0.58, 0.12, 0.09); RSD = (0.3, 0.06, 0.07); BELLY = (0.95, 0.68, 0.28)
MEM = (0.75, 0.3, 0.12)    # membrana das asas (creatures_new.py troca no Dragão de Ossos)
EYEC = (1.0, 0.4, 0.1)
SKEL = False               # asa só de dedos, sem membrana


def _dragon_head(M=None, jaw_open=0.0):
    """Cabeça do dragão (origem na nuca, focinho para -Y). Devolve a lista de objetos."""
    H = []
    scales = mat("dscales", vcol=True, rough=0.6, bump=0.25, bump_scale=60)
    sk = fuse([sph((0, -0.28, 0.0), 1, (0.3, 0.42, 0.26)), sph((0, -0.78, -0.05), 1, (0.2, 0.42, 0.14)), sph((0, -1.12, -0.07), 1, (0.14, 0.22, 0.1)),
               sph((0, -0.35, 0.2), 1, (0.22, 0.25, 0.1)), sph((0.28, -0.3, -0.08), 1, (0.1, 0.18, 0.12)), sph((-0.28, -0.3, -0.08), 1, (0.1, 0.18, 0.12))], "dskull", 0.014, 0.6, 5)
    paint(sk, lambda p, n: mix(RSD, RS, smoothstep(-0.3, 0.9, n.z) * 0.7 + 0.15)); setmat(sk, scales); H.append(sk)
    jw = fuse([sph((0, -0.62, -0.3 - jaw_open * 0.3), 1, (0.17, 0.42, 0.07)), sph((0, -0.98, -0.3 - jaw_open * 0.38), 1, (0.1, 0.16, 0.05))], "djaw", 0.01, 0.5, 3)
    paint(jw, lambda p, n: mix(RSD, BELLY, smoothstep(0.4, -0.8, n.z) * 0.6)); setmat(jw, scales); H.append(jw)
    cav = sph((0, -0.66, -0.2 - jaw_open * 0.12), 1, (0.14, 0.38, 0.07 + jaw_open * 0.07)); setmat(cav, mat("shadow", SHADOW, 0.9)); H.append(cav)
    tg = sph((0, -0.6, -0.27 - jaw_open * 0.2), 1, (0.08, 0.3, 0.03)); setmat(tg, mat("tongue", (0.85, 0.25, 0.3), 0.5)); H.append(tg)
    glow = sph((0, -0.35, -0.18), 1, (0.09, 0.1, 0.06)); setmat(glow, mat("throat", (1.0, 0.5, 0.1), 0.4, emit=6.0)); H.append(glow)
    toothm = mat("tooth", (1, 0.97, 0.85), 0.3)
    for k in range(5):
        for sx in (-1, 1):
            t = box((sx * (0.12 - k * 0.004), -0.5 - k * 0.12, -0.14), (0.03, 0.03, 0.09), (0, 0, 0), bevel=0.004, taper=(0.1, 0.2)); t.rotation_euler[0] = math.radians(180)
            hard(t); setmat(t, toothm); H.append(t)
            u = box((sx * (0.1 - k * 0.003), -0.55 - k * 0.1, -0.24 - jaw_open * 0.3), (0.025, 0.025, 0.07), bevel=0.004, taper=(0.1, 0.2)); hard(u); setmat(u, toothm); H.append(u)
    hornm = mat("dhorn", BONE, 0.5)
    for sx in (-1, 1):
        H += yellow_eye((sx * 0.2, -0.42, 0.17), 0.075, 28, sx, EYEC, RS)
        hn = tube([(sx * 0.17, 0.0, 0.18), (sx * 0.33, 0.35, 0.34), (sx * 0.42, 0.8, 0.5), (sx * 0.36, 1.1, 0.42)], 0.08, 0.1, 18); setmat(hn, hornm); H.append(hn)
        hn2 = tube([(sx * 0.3, -0.1, 0.0), (sx * 0.5, 0.05, 0.05), (sx * 0.58, 0.28, 0.12)], 0.05, 0.1, 10); setmat(hn2, hornm); H.append(hn2)
        nr = sph((sx * 0.06, -1.27, -0.02), 0.03); setmat(nr, mat("shadow", SHADOW, 0.9)); H.append(nr)
        br = sph((sx * 0.17, -0.42, 0.3), 1, (0.12, 0.16, 0.05), (0, 0, sx * -20)); shade(br); setmat(br, mat("dbrow", RSD, 0.6)); H.append(br)
    for k in range(4):   # crista de espinhos na nuca
        sp = box((0, 0.1 + k * 0.17, 0.25 - k * 0.03), (0.04, 0.12, 0.2), (-15, 0, 0), bevel=0.006, taper=(0.1, 0.2)); hard(sp); setmat(sp, hornm); H.append(sp)
    return H


def _wing(sx, spread=1.0):
    """Asa de morcego/dragão: braço, quatro dedos e membrana. Ombro em (sx*0.4, 0.15, 1.55)."""
    W = []
    bonem = mat("dbone", RSD, 0.5)
    sh = Vector((sx * 0.4, 0.15, 1.55)); el = Vector((sx * 1.5, 0.35, 2.7)); wr = Vector((sx * 2.6, 0.2, 2.9))
    a = tube([tuple(sh), tuple(el), tuple(wr)], 0.09, 0.7, 14); setmat(a, bonem); W.append(a)
    tips = [Vector((sx * 4.3, 0.5, 3.4)), Vector((sx * 4.0, 0.7, 2.4)), Vector((sx * 3.2, 0.8, 1.6)), Vector((sx * 2.0, 0.8, 1.1))]
    for t in tips:
        f = tube([tuple(wr), tuple((wr + t) / 2 + Vector((0, 0.0, 0.05))), tuple(t)], 0.05, 0.35, 10); setmat(f, bonem); W.append(f)
    cl = tube([tuple(wr), tuple(wr + Vector((sx * 0.1, -0.2, 0.18)))], 0.04, 0.3, 4); setmat(cl, mat("dhorn", BONE, 0.5)); W.append(cl)
    if SKEL:
        return W
    import bmesh as _bm
    root_ = sh + Vector((0, 0.3, -0.5))
    pts_ = [sh, el, wr] + tips + [root_]
    bm = _bm.new()
    vs = {i: bm.verts.new(tuple(p_)) for i, p_ in enumerate(pts_)}
    # leque de membrana: cotovelo-pulso-dedos-raiz (escalopado entre os dedos)
    seq = [3, 4, 5, 6, 7]
    for a_, b_ in zip(seq[:-1], seq[1:]):
        bm.faces.new((vs[2], vs[a_], vs[b_]))
        if a_ >= 3 and b_ <= 6:   # recorte côncavo entre as pontas dos dedos
            pass
    bm.faces.new((vs[0], vs[1], vs[2])); bm.faces.new((vs[0], vs[2], vs[7]))
    me = bpy.data.meshes.new("dwing"); bm.to_mesh(me); bm.free()
    mem = bpy.data.objects.new("dwing", me); bpy.context.scene.collection.objects.link(mem)
    sm_ = mem.modifiers.new("sub", 'SUBSURF'); sm_.levels = 1; sm_.render_levels = 1
    so_ = mem.modifiers.new("sol", 'SOLIDIFY'); so_.thickness = 0.05
    apply_mods(mem); shade(mem)
    paint(mem, lambda p, n: mix(RSD, MEM, smoothstep(0.0, 4.0, abs(p.x)) * 0.5)); setmat(mem, mat("dmem", vcol=True, rough=0.6)); W.append(mem)
    return W


def elder_dragon():
    P = []
    scales = mat("dscales", vcol=True, rough=0.6, bump=0.25, bump_scale=60)

    def col(p, n):
        c = mix(RSD, RS, smoothstep(-0.3, 0.9, n.z) * 0.8 + 0.1)
        return mix(c, BELLY, smoothstep(0.2, -0.8, n.z) * smoothstep(1.0, 0.6, p.z * 0.0 + 0.3) * 0.0 + smoothstep(-0.2, -0.85, n.z) * 0.65)
    # tronco, pescoço em S, quadril
    B = []
    neck_pts = [(0, -0.5, 1.5), (0, -0.85, 1.85), (0, -1.1, 2.3), (0, -1.0, 2.75), (0, -1.15, 3.1)]
    neck_r = [(0.5, 0.5, 0.4), (0.38, 0.38, 0.34), (0.3, 0.3, 0.3), (0.27, 0.27, 0.27), (0.24, 0.24, 0.24)]
    body = fuse([sph((0, 0.0, 1.4), 1, (0.58, 0.9, 0.5)), sph((0, 0.85, 1.35), 1, (0.48, 0.7, 0.42))] +
                [sph(p, 1, r) for p, r in zip(neck_pts, neck_r)] +
                [sph((0.5, -0.5, 1.15), 1, (0.2, 0.25, 0.22)), sph((-0.5, -0.5, 1.15), 1, (0.2, 0.25, 0.22))] +
                capsule((0.46, -0.45, 1.2), (0.58, -0.85, 0.8), 0.14, 0.1) + capsule((-0.46, -0.45, 1.2), (-0.58, -0.85, 0.8), 0.14, 0.1) +
                capsule((0.42, 0.85, 1.1), (0.55, 0.5, 0.65), 0.2, 0.12) + capsule((-0.42, 0.85, 1.1), (-0.55, 0.5, 0.65), 0.2, 0.12) +
                [sph((0.58, 0.4, 0.58), 1, (0.17, 0.26, 0.09)), sph((-0.58, 0.4, 0.58), 1, (0.17, 0.26, 0.09)),
                 sph((0.6, -0.95, 0.76), 1, (0.14, 0.2, 0.08)), sph((-0.6, -0.95, 0.76), 1, (0.14, 0.2, 0.08))], "dbody", 0.025, 0.6, 5)
    paint(body, col); setmat(body, scales); B.append(body)
    hornm = mat("dhorn", BONE, 0.5)
    for sx in (-1, 1):   # garras
        for (cx, cy, cz) in ((sx * 0.6, -1.15, 0.72), (sx * 0.62, 0.15, 0.55)):
            for k in (-1, 0, 1):
                c = tube([(cx + k * 0.07, cy, cz), (cx + k * 0.08, cy - 0.12, cz - 0.02), (cx + k * 0.08, cy - 0.2, cz - 0.1)], 0.028, 0.15, 6); setmat(c, hornm); B.append(c)
    for k in range(9):   # espinhos dorsais
        t = k / 8.0
        z = 1.95 - t * 0.35 if t < 0.5 else 1.75 - (t - 0.5) * 0.7
        y = -0.9 + t * 2.0
        sp = box((0, y, 1.85 - 0.1 * math.sin(t * 3) - t * 0.35 + 0.0), (0.05, 0.14, 0.2 - t * 0.06), (-10, 0, 0), bevel=0.008, taper=(0.1, 0.3)); hard(sp); setmat(sp, hornm); B.append(sp)
    # placas da barriga douradas
    for k in range(8):
        y = -0.9 + k * 0.28
        pl = box((0, y, 0.93 + (0.08 if k > 5 else 0.0)), (0.55 - k * 0.03, 0.2, 0.05), (0, 0, 0), bevel=0.01); hard(pl); setmat(pl, mat("dbelly", BELLY, 0.45, 0.5)); B.append(pl)
    tag(B, "body"); P += B
    # cauda longa terminando em ponta de lança
    T = []
    tail = tube([(0, 1.0, 1.3), (0, 1.9, 1.15), (0.2, 2.8, 1.0), (0.1, 3.7, 1.25), (-0.3, 4.4, 1.7)], 0.38, 0.12, 24)
    paint(tail, lambda p, n: mix(RSD, RS, smoothstep(-0.3, 0.9, n.z) * 0.8 + 0.1)); setmat(tail, scales); T.append(tail)
    tp = box((-0.3, 4.55, 1.85), (0.2, 0.05, 0.4), (-30, 0, 0), bevel=0.01, taper=(0.1, 0.5)); hard(tp); setmat(tp, hornm); T.append(tp)
    for k in range(4):
        sp = box((0.05 * k, 1.6 + k * 0.7, 1.55 - k * 0.12 + k * 0.1), (0.04, 0.13, 0.18 - k * 0.03), (-10, 0, 0), bevel=0.008, taper=(0.1, 0.3)); hard(sp); setmat(sp, hornm); T.append(sp)
    tag(T, "tail"); P += T
    # cabeça no topo do pescoço, mandíbula entreaberta
    Hh = _dragon_head(jaw_open=0.55)
    xform(Hh, Matrix.Translation((0, -1.15, 3.2)) @ Matrix.Rotation(math.radians(8), 4, 'X'))
    tag(Hh, "head"); P += Hh
    # asas
    for sx, bone in ((1, "wing_l"), (-1, "wing_r")):
        W = _wing(sx)
        tag(W, bone); P += W
    # baforada de fogo saindo da boca (sopro em cone)
    return group("elder_dragon", P)


def elder_dragon_flames():
    """Sopro de fogo para as cartas (não faz parte do modelo do jogo)."""
    import scenes as S
    F = []
    for k, (dx, dz, h, r) in enumerate(((0.0, 0.0, 1.5, 0.3), (-0.4, 0.15, 1.1, 0.22), (0.4, -0.1, 1.1, 0.22))):
        F += S.flame((dx, -2.35 - 0.0, 3.0 + dz), h=h, r=r, lean=(0, -0.6))
    return F


# =============================================================== exportação (mesmo caminho do build.py)

def _dragon_anim():
    shl, shr = Vector((0.4, 0.15, 1.55)), Vector((-0.4, 0.15, 1.55))
    hp = Vector((0, -0.5, 1.6)); tp = Vector((0, 1.0, 1.3)); mid = Vector((0, 0.0, 1.4))
    TAU = math.tau

    def anim(kind, t):
        if kind == "walk":
            ph = TAU * t; f = math.sin(ph)
            B = tr(0, 0, 0.14 * math.sin(ph + 1.0)) @ rot_about(mid, 'X', math.radians(3) * math.cos(ph))
            return {"body": B, "head": B @ rot_about(hp, 'X', math.radians(5) * math.sin(ph + 1.6)),
                    "tail": B @ rot_about(tp, 'Z', math.radians(12) * math.sin(ph + 0.6)),
                    "wing_l": B @ rot_about(shl, 'Y', -math.radians(32) * f), "wing_r": B @ rot_about(shr, 'Y', math.radians(32) * f)}
        e = anims.ease
        go = e(t / 0.35) if t < 0.35 else 1.0 - e((t - 0.6) / 0.4)
        B = tr(0, -0.2 * go, 0.0) @ rot_about(mid, 'X', math.radians(-8) * go)
        return {"body": B, "head": B @ rot_about(hp, 'X', math.radians(28) * go), "tail": B @ rot_about(tp, 'Z', math.radians(18) * go),
                "wing_l": B @ rot_about(shl, 'Y', -math.radians(40) * (1 - go) + math.radians(20) * go),
                "wing_r": B @ rot_about(shr, 'Y', math.radians(40) * (1 - go) - math.radians(20) * go)}
    return {"anim": anim}


def _cfg(i):
    if i == "elder_dragon":
        return _dragon_anim()
    if i == "cave_troll":
        return {"anim": anims.biped(2.6, (0.34, 0.0, 0.95), (0.75, 0.05, 1.65), (0, -0.2, 1.8), stride=22, swing=16, atk="smash", atk_arm="arm_l", bob=0.025)}
    if i == "treasure_guard":
        return {"anim": anims.biped(2.0, (0.2, 0.0, 0.62), (0.52, 0.0, 1.35), (0, -0.05, 1.45), stride=22, swing=14, atk="thrust", atk_arm="arm_l", bob=0.03)}
    return {}


def main():
    argv = sys.argv[sys.argv.index("--") + 1:]
    out = os.path.abspath(argv[0])
    os.makedirs(out, exist_ok=True)
    ids = argv[1].split(",") if len(argv) > 1 else list(UNITS_DRAGON)
    for i in ids:
        try:
            bpy.ops.wm.read_factory_settings(use_empty=True)
            mk._MATS.clear()
            root = globals()[i]()
            h, b = UNITS_DRAGON[i]
            a = _cfg(i)
            vat.export(root, os.path.join(out, i + ".lbm"), h, b, a.get("anim"), a.get("deform"), a.get("rig"))
            print("OK", i)
        except Exception:
            print("FALHOU", i)
            traceback.print_exc()


if __name__ == "__main__":
    main()
