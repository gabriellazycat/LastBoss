"""Criaturas do Dragão Avarento e dos comuns (lote 10/11/2026): Guarda do Tesouro, Dragão Ancião e Troll das Cavernas.
Refeitos pela carta em 27/11/2026: Guarda do Tesouro, Dragão Ancião e o Dragão do Tesouro (modelo próprio).
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
UNITS_DRAGON = {"treasure_guard": (2.0, 3000), "elder_dragon": (4.2, 3800), "cave_troll": (2.7, 3000), "hoard_dragon": (3.2, 3800)}

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

# Cores da carta (27/11/2026): armadura de placas dourada clara, penacho e saiote vermelhos, manoplas escuras,
# peitoral claro, escudo alto dourado. Elmo fechado: sem olhos.
TG_GOLD = (0.95, 0.76, 0.24); TG_GOLD_D = (0.56, 0.4, 0.1); TG_LIGHT = (0.96, 0.92, 0.78); TG_RED = (0.8, 0.15, 0.14)
TG_DARK = (0.2, 0.2, 0.25); TG_LEATHER = (0.32, 0.21, 0.13); TG_STEEL = (0.82, 0.84, 0.86)


def treasure_guard():
    P = []
    plate = mat("tgplate", vcol=True, rough=0.4, metal=0.6, bump=0.04, bump_scale=10)
    red = mat("tgred", TG_RED, 0.75, bump=0.1, bump_scale=120)
    dark = mat("tgdark", TG_DARK, 0.5)

    def gold(p, n):
        return mix(TG_GOLD_D, TG_GOLD, smoothstep(-0.6, 0.8, n.z) * 0.5 + smoothstep(0.5, -0.6, n.y) * 0.3 + 0.1)

    def gold_hi(p, n):
        return mix(TG_GOLD, (1.0, 0.86, 0.45), smoothstep(-0.2, 0.9, n.z) * 0.4 + smoothstep(0.3, -0.8, n.y) * 0.3)
    # tronco: couraça, cintura, faldas sobre o saiote vermelho
    B = []
    chest = fuse([sph((0, 0.0, 1.33), 1, (0.31, 0.22, 0.25)), sph((0, -0.02, 1.1), 1, (0.25, 0.18, 0.17)), sph((0, -0.06, 1.3), 1, (0.22, 0.2, 0.2))], "tgchest", 0.01, 0.6, 4)
    paint(chest, gold_hi); setmat(chest, plate); B.append(chest)
    gap = torus((0, 0, 1.08), 0.22, 0.05, s=(1, 0.82, 1)); shade(gap); setmat(gap, dark); B.append(gap)   # malha escura sob a couraça
    tri = box((0, -0.22, 1.36), (0.26, 0.04, 0.24), (6, 0, 0), bevel=0.01, taper=(0.15, 1.0)); hard(tri)
    setmat(tri, mat("tglight", TG_LIGHT, 0.4, 0.4)); B.append(tri)
    gorget = torus((0, -0.01, 1.55), 0.13, 0.05); shade(gorget); paint(gorget, gold); setmat(gorget, plate); B.append(gorget)
    skirt = cyl((0, 0, 0.8), 0.25, 0.22, seg=36, bevel=0.02, r2=0.3); hard(skirt); setmat(skirt, red); B.append(skirt)
    fauld = cyl((0, 0, 0.94), 0.26, 0.16, seg=36, bevel=0.02, r2=0.29); hard(fauld); paint(fauld, gold); setmat(fauld, plate); B.append(fauld)
    belt = torus((0, 0, 1.02), 0.245, 0.035, s=(1, 0.8, 1)); shade(belt); setmat(belt, mat("tgbelt", TG_LEATHER, 0.6)); B.append(belt)
    cod = box((0, -0.24, 0.84), (0.13, 0.05, 0.2), (0, 0, 0), bevel=0.02, taper=(0.6, 1.0)); hard(cod); setmat(cod, dark); B.append(cod)
    tag(B, "body"); P += B
    # elmo fechado redondo, viseira com fenda escura, penacho vermelho caindo para trás
    H = []
    helm = fuse([sph((0, 0.0, 1.73), 1, (0.16, 0.17, 0.18)), sph((0, -0.08, 1.68), 1, (0.14, 0.13, 0.14))], "tghelm", 0.008, 0.6, 4)
    paint(helm, gold); setmat(helm, plate); H.append(helm)
    slit = box((0, -0.2, 1.72), (0.22, 0.04, 0.03), bevel=0.005); hard(slit); setmat(slit, mat("shadow", SHADOW, 0.9)); H.append(slit)
    crest = box((0, 0.0, 1.86), (0.04, 0.3, 0.06), bevel=0.01); hard(crest); setmat(crest, mat("tgcrest", TG_GOLD_D, 0.4, 0.6)); H.append(crest)
    plume = fuse([tube([(0, -0.02, 1.88), (0, 0.06, 2.02), (0, 0.24, 2.02), (0.06, 0.4, 1.86), (0.12, 0.5, 1.6)], 0.085, 0.45, 18),
                  sph((0, 0.06, 1.97), 1, (0.08, 0.12, 0.08))], "tgplume", 0.01, 0.6, 4)
    paint(plume, lambda p, n: mix((0.55, 0.08, 0.08), TG_RED, smoothstep(-0.4, 0.7, n.z) * 0.7 + 0.3)); setmat(plume, mat("tgplume_m", vcol=True, rough=0.8)); H.append(plume)
    tag(H, "head"); P += H
    # braço da espada (-x, arm_r): ombreira, braço, manopla dourada, espada apontada para baixo
    for sx, bone in ((-1, "arm_r"), (1, "arm_l")):
        A = []
        pa = fuse([sph((sx * 0.36, 0.0, 1.47), 1, (0.19, 0.19, 0.13))], "tgpaul", 0.01, 0.6, 3)
        paint(pa, gold_hi); setmat(pa, plate); A.append(pa)
        pb = fuse([sph((sx * 0.42, 0.0, 1.33), 1, (0.15, 0.17, 0.09))], "tgpaul2", 0.01, 0.6, 3)
        paint(pb, gold); setmat(pb, plate); A.append(pb)
        el = sph((sx * 0.425, 0.0, 1.08), 1, (0.09, 0.09, 0.09)); shade(el); setmat(el, dark); A.append(el)
        if sx < 0:
            arm = fuse(capsule((-0.38, 0.0, 1.38), (-0.42, -0.02, 1.08), 0.085, 0.075) + capsule((-0.42, -0.02, 1.08), (-0.4, -0.14, 0.86), 0.075, 0.07) +
                       [sph((-0.4, -0.16, 0.82), 1, (0.08, 0.08, 0.08))], "tgarm", 0.01, 0.5, 3)
            paint(arm, gold); setmat(arm, plate); A.append(arm)
            grip = cyl((-0.4, -0.16, 0.86), 0.025, 0.2, seg=10, bevel=0.0); setmat(grip, mat("tgbelt", TG_LEATHER, 0.6)); A.append(grip)
            pom = sph((-0.4, -0.16, 0.98), 0.045); shade(pom); setmat(pom, mat("tgcrest", TG_GOLD_D, 0.4, 0.6)); A.append(pom)
            guard = box((-0.4, -0.16, 0.74), (0.24, 0.05, 0.05), bevel=0.01); hard(guard); setmat(guard, mat("tgcrest", TG_GOLD_D, 0.4, 0.6)); A.append(guard)
            blade = box((-0.42, -0.2, 0.4), (0.075, 0.025, 0.66), (-6, 0, 0), bevel=0.006, taper=(0.4, 1.0)); hard(blade)
            setmat(blade, mat("tgblade", TG_STEEL, 0.25, 0.9)); A.append(blade)
        else:
            # braço do escudo (+x, arm_l): manopla escura segurando o escudo alto
            arm = fuse(capsule((0.38, 0.0, 1.38), (0.43, -0.02, 1.08), 0.085, 0.075) + capsule((0.43, -0.02, 1.08), (0.45, -0.24, 1.02), 0.075, 0.07), "tgarm2", 0.01, 0.5, 3)
            paint(arm, gold); setmat(arm, plate); A.append(arm)
            gl = sph((0.46, -0.27, 1.02), 1, (0.09, 0.09, 0.09)); shade(gl); setmat(gl, dark); A.append(gl)
            fa = capsule((0.43, -0.04, 1.08), (0.45, -0.22, 1.03), 0.085, 0.08)
            fa = fuse(fa, "tggaunt", 0.01, 0.5, 3); setmat(fa, dark); A.append(fa)
            # escudo alto de ponta arredondada, curvo, levemente virado para fora
            sc = Vector((0.62, -0.32, 0.92))
            sh_parts = [box(tuple(sc), (0.07, 0.56, 1.05), bevel=0.03)]
            top = cyl(tuple(sc + Vector((0, 0, 0.5))), 0.28, 0.07, (0, 90, 0), seg=32, bevel=0.02)
            sh_parts.append(top)
            shd = fuse(sh_parts, "tgshield", 0.012, 0.4, 3)
            for v in shd.data.vertices:   # curva o escudo (bordas para trás); a malha é local ao centro do escudo
                v.co.x += 0.25 * v.co.y * v.co.y
            shd.rotation_euler = (0, 0, math.radians(-28))   # virado um pouco para fora, em torno do centro
            bpy.context.view_layer.update()
            paint(shd, lambda p, n: mix(TG_GOLD_D, TG_GOLD, smoothstep(-0.2, 0.9, -n.y * 0.5 + n.x * 0.5) * 0.6 + 0.25))
            setmat(shd, mat("tgshield_m", vcol=True, rough=0.45, metal=0.5))
            A.append(shd)
        tag(A, bone); P += A
    # pernas: coxote, joelheira, greva e solaret dourados
    for sx, bone in ((1, "leg_l"), (-1, "leg_r")):
        L = []
        leg = fuse(capsule((sx * 0.15, 0.0, 0.9), (sx * 0.17, -0.02, 0.52), 0.12, 0.1) + capsule((sx * 0.17, -0.02, 0.5), (sx * 0.17, 0.0, 0.12), 0.1, 0.085) +
                   [sph((sx * 0.17, -0.1, 0.06), 1, (0.1, 0.18, 0.07))], "tgleg", 0.01, 0.5, 3)
        paint(leg, gold); setmat(leg, plate); L.append(leg)
        kn = sph((sx * 0.17, -0.1, 0.52), 1, (0.12, 0.09, 0.11)); shade(kn); paint(kn, gold_hi); setmat(kn, plate); L.append(kn)
        bk = sph((sx * 0.17, 0.03, 0.5), 1, (0.09, 0.08, 0.08)); shade(bk); setmat(bk, dark); L.append(bk)
        tag(L, bone); P += L
    return group("treasure_guard", P)


# =============================================================== Dragão de asas grandes (antigo Dragão Ancião)

RS = (0.58, 0.12, 0.09); RSD = (0.3, 0.06, 0.07); BELLY = (0.95, 0.68, 0.28)
MEM = (0.75, 0.3, 0.12)    # membrana das asas (creatures_new.py troca no Dragão de Ossos)
EYEC = (1.0, 0.4, 0.1)
SKEL = False               # asa só de dedos, sem membrana


def _dragon_head(M=None, jaw_open=0.0, rs=None, rsd=None, belly=None, horn=None, eye=None):
    """Cabeça do dragão (origem na nuca, focinho para -Y). Devolve a lista de objetos.
    Cores: as do módulo (RS, RSD, BELLY, BONE, EYEC), ou as passadas (Dragão do Tesouro)."""
    RS = rs or globals()["RS"]; RSD = rsd or globals()["RSD"]; BELLY = belly or globals()["BELLY"]
    HORN = horn or BONE; EYEC = eye or globals()["EYEC"]
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
    hornm = mat("dhorn_%s" % str(HORN), HORN, 0.5)
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


def winged_dragon():
    """Dragão de asas grandes (o Dragão Ancião até 27/11/2026): geometria do Dragãozinho e do Dragão de Ossos."""
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
    return group("elder_dragon", P)


def elder_dragon_flames():
    """Sopro de fogo para as cartas (não faz parte do modelo do jogo)."""
    import scenes as S
    F = []
    for k, (dx, dz, h, r) in enumerate(((0.0, 0.0, 1.5, 0.3), (-0.4, 0.15, 1.1, 0.22), (0.4, -0.1, 1.1, 0.22))):
        F += S.flame((dx, -2.35 - 0.0, 3.0 + dz), h=h, r=r, lean=(0, -0.6))
    return F


# =============================================================== Dragão Ancião (27/11/2026) e Dragão do Tesouro

# Cores da carta do Ancião: vermelho, barriga creme, chifres cinzentos, membrana vinho.
ED_RS = (0.7, 0.15, 0.11); ED_RSD = (0.38, 0.07, 0.07); ED_BELLY = (0.95, 0.8, 0.55); ED_MEM = (0.5, 0.12, 0.11)
ED_HORN = (0.62, 0.6, 0.62); ED_EYE = (1.0, 0.8, 0.25)
# Cores da carta do Tesouro: ouro pálido, barriga creme, chifres escuros, ouro das moedas.
HD_RS = (1.0, 0.7, 0.2); HD_RSD = (0.72, 0.42, 0.1); HD_BELLY = (1.0, 0.92, 0.7); HD_MEM = (0.95, 0.62, 0.2)
HD_HORN = (0.24, 0.22, 0.26); HD_EYE = (0.25, 0.15, 0.12); COIN = (1.0, 0.8, 0.15); COIN_D = (0.85, 0.52, 0.06)


def _wing_at(sx, sh, el, wr, tips, root, rsd, mem, horn, arm_r=0.11):
    """Asa de dragão por pontos (ombro, cotovelo, pulso, pontas dos dedos, raiz no corpo), dados para o lado +x.
    Braço, dedos e garra numa peça só (o simplify do vat_g apaga peças pequenas soltas)."""
    import bmesh as _bm
    W = []
    V = lambda p: Vector((sx * p[0], p[1], p[2]))
    sh, el, wr, root = V(sh), V(el), V(wr), V(root)
    tips = [V(t) for t in tips]
    bonem = mat("dbone_%s" % str(rsd), rsd, 0.5)
    parts = [tube([tuple(sh), tuple(el), tuple(wr)], arm_r, 0.65, 14)]
    for t in tips:
        parts.append(tube([tuple(wr), tuple((wr + t) / 2 + Vector((0, 0.0, 0.06))), tuple(t)], arm_r * 0.55, 0.35, 10))
    for o in parts:
        setmat(o, bonem)
    hook = tube([tuple(wr), tuple(wr + Vector((sx * 0.08, -0.12, 0.3))), tuple(wr + Vector((sx * 0.02, -0.3, 0.38)))], arm_r * 0.6, 0.2, 8)
    setmat(hook, mat("dhorn_%s" % str(horn), horn, 0.5)); parts.append(hook)
    W.append(join(parts, "dwingbone"))
    # leque de membrana do pulso às pontas e à raiz, com a borda recortada (côncava) entre as pontas, como na carta
    bm = _bm.new()
    vW = bm.verts.new(tuple(wr)); vS = bm.verts.new(tuple(sh)); vE = bm.verts.new(tuple(el))
    edge = tips + [root]
    ve = [bm.verts.new(tuple(t)) for t in edge]
    for k in range(len(edge) - 1):
        a_, b_ = edge[k], edge[k + 1]
        mid = (a_ + b_) / 2
        mid = mid + (wr - mid) * 0.22
        vm = bm.verts.new(tuple(mid))
        bm.faces.new((vW, ve[k], vm)); bm.faces.new((vW, vm, ve[k + 1]))
    bm.faces.new((vS, vE, vW)); bm.faces.new((vS, vW, ve[-1]))
    me = bpy.data.meshes.new("dwing"); bm.to_mesh(me); bm.free()
    m_ = bpy.data.objects.new("dwing", me); bpy.context.scene.collection.objects.link(m_)
    sm_ = m_.modifiers.new("sub", 'SUBSURF'); sm_.levels = 1; sm_.render_levels = 1; sm_.subdivision_type = 'SIMPLE'
    so_ = m_.modifiers.new("sol", 'SOLIDIFY'); so_.thickness = 0.06
    apply_mods(m_); shade(m_)
    span = max(1e-3, max(abs(t.x) for t in tips))
    paint(m_, lambda p, n: mix(mem, mix(mem, (1, 1, 1), 0.12), smoothstep(0.3, 1.0, abs(p.x) / span) * 0.6))
    setmat(m_, mat("dmem_%s" % str(mem), vcol=True, rough=0.6)); W.append(m_)
    return W


def elder_dragon():
    """Dragão Ancião da carta: dragão vermelho enorme de quatro patas, corpo pesado, pescoço grosso, cabeça grande com
    chifres longos para trás, asas meio erguidas atrás do corpo (as pontas não passam da cabeça), cauda longa."""
    P = []
    scales = mat("edscales", vcol=True, rough=0.6, bump=0.25, bump_scale=60)
    horn = mat("edhorn", ED_HORN, 0.5)

    def col(p, n):
        c = mix(ED_RSD, ED_RS, smoothstep(-0.4, 0.8, n.z) * 0.75 + 0.2)
        # barriga e peito creme (como a carta: do peito até a barriga, por baixo)
        bel = smoothstep(-0.1, -0.75, n.z) * smoothstep(1.6, 0.2, p.y)
        bel = max(bel, ell_w(p, (0, -1.25, 1.95), (0.42, 0.45, 0.75)) * smoothstep(0.2, -0.6, n.y))
        return mix(c, ED_BELLY, min(1.0, bel) * 0.85)
    B = []
    body = fuse([sph((0, -0.55, 1.65), 1, (0.82, 0.85, 0.78)), sph((0, 0.35, 1.55), 1, (0.75, 0.9, 0.72)), sph((0, 1.15, 1.55), 1, (0.62, 0.62, 0.62)),
                 sph((0, -1.2, 2.1), 1, (0.52, 0.5, 0.55)), sph((0, -1.45, 2.55), 1, (0.42, 0.42, 0.45)), sph((0, -1.62, 2.95), 1, (0.35, 0.36, 0.36)),
                 sph((0, -1.72, 3.2), 1, (0.31, 0.32, 0.3))], "edbody", 0.025, 0.6, 6)
    paint(body, col); setmat(body, scales); B.append(body)
    spikes = []
    for k in range(11):   # placas do dorso, do pescoço ao quadril (peça única)
        t = k / 10.0
        y = -1.75 + t * 3.1
        z = 3.45 - t * 1.0 if t < 0.35 else 3.1 - (t - 0.35) * 1.6
        hgt = 0.34 - abs(t - 0.45) * 0.25
        spikes.append(box((0, y, z), (0.08, 0.26, hgt), (-25 + t * 10, 0, 0), bevel=0.01, taper=(0.15, 0.35)))
    sj = join(spikes, "edspikes"); hard(sj); setmat(sj, mat("edspike", ED_RSD, 0.55)); B.append(sj)
    tag(B, "body"); P += B
    # patas grossas (separadas para andar), garras numa peça por pata
    LEGS = {"leg_fl": (1, (0.62, -0.75, 1.45), (0.82, -0.95, 0.75), (0.8, -1.05, 0.12), 0.34, 0.24),
            "leg_fr": (-1, (0.62, -0.75, 1.45), (0.82, -0.95, 0.75), (0.8, -1.05, 0.12), 0.34, 0.24),
            "leg_bl": (1, (0.6, 0.95, 1.45), (0.82, 1.15, 0.8), (0.82, 0.85, 0.12), 0.42, 0.25),
            "leg_br": (-1, (0.6, 0.95, 1.45), (0.82, 1.15, 0.8), (0.82, 0.85, 0.12), 0.42, 0.25)}
    for bone, (sx, a, b, c, r1, r2) in LEGS.items():
        L = []
        A = Vector((sx * a[0], a[1], a[2])); Bv = Vector((sx * b[0], b[1], b[2])); C = Vector((sx * c[0], c[1], c[2]))
        leg = fuse(capsule(tuple(A), tuple(Bv), r1, r1 * 0.8) + capsule(tuple(Bv), tuple(C), r1 * 0.75, r2) +
                   [sph(tuple(C + Vector((0, -0.12, 0.0))), 1, (0.28, 0.36, 0.14))], "edleg", 0.02, 0.6, 5)
        paint(leg, lambda p, n: mix(ED_RSD, ED_RS, smoothstep(-0.4, 0.8, n.z) * 0.7 + 0.25)); setmat(leg, scales); L.append(leg)
        cl = []
        for k in (-1, 0, 1):
            x0 = C.x + k * 0.13
            cl.append(tube([(x0, C.y - 0.38, 0.12), (x0, C.y - 0.52, 0.08), (x0, C.y - 0.58, 0.0)], 0.065, 0.3, 6))
        cj = join(cl, "edclaw"); setmat(cj, horn); L.append(cj)
        tag(L, bone); P += L
    # cauda longa e grossa, pousada no chão no fim
    T = []
    tail = tube([(0, 1.45, 1.55), (0, 2.4, 1.05), (0.35, 3.3, 0.55), (0.9, 4.0, 0.35), (1.5, 4.5, 0.35)], 0.48, 0.12, 24)
    paint(tail, lambda p, n: mix(ED_RSD, ED_RS, smoothstep(-0.4, 0.8, n.z) * 0.75 + 0.2)); setmat(tail, scales); T.append(tail)
    ts = []
    for k in range(5):
        t = k / 4.0
        ts.append(box((0.35 * t * t, 1.95 + t * 1.6, 1.75 - t * 1.0), (0.06, 0.24, 0.26 - t * 0.1), (-30, 0, 0), bevel=0.01, taper=(0.15, 0.35)))
    tj = join(ts, "edtailsp"); hard(tj); setmat(tj, mat("edspike", ED_RSD, 0.55)); T.append(tj)
    tag(T, "tail"); P += T
    # cabeça grande no alto do pescoço, boca aberta (sopro), chifres longos para trás
    Hh = _dragon_head(jaw_open=0.7, rs=ED_RS, rsd=ED_RSD, belly=ED_BELLY, horn=ED_HORN, eye=ED_EYE)
    xform(Hh, Matrix.Translation((0, -1.78, 3.32)) @ Matrix.Rotation(math.radians(14), 4, 'X') @ Matrix.Scale(1.35, 4))
    tag(Hh, "head"); P += Hh
    # asas meio erguidas atrás das costas (como a carta), pontas na altura da cabeça
    for sx, bone in ((1, "wing_l"), (-1, "wing_r")):
        W = _wing_at(sx, (0.5, -0.45, 2.15), (1.25, 0.05, 3.05), (1.85, 0.55, 3.75),
                     [(2.7, 1.35, 3.25), (2.85, 1.9, 2.35), (2.3, 2.15, 1.75), (1.4, 1.75, 1.6)], (0.45, 1.0, 2.0),
                     ED_RSD, ED_MEM, ED_HORN, 0.13)
        tag(W, bone); P += W
    return group("elder_dragon", P)


def _elder_anim():
    q = anims._quad(4.2, (0.62, -0.75, 1.45), (0.6, 0.95, 1.45), (0, -1.75, 3.25), (0, 1.45, 1.55), stride=20, bob=0.012)
    shl, shr = Vector((0.5, -0.45, 2.15)), Vector((-0.5, -0.45, 2.15))
    hp = Vector((0, -1.75, 3.25))
    TAU = math.tau

    def anim(kind, t):
        d = q(kind, t)
        B = d["body"]
        if kind == "walk":
            f = math.sin(TAU * t)
            d["wing_l"] = B @ rot_about(shl, 'Y', -math.radians(14) * f)
            d["wing_r"] = B @ rot_about(shr, 'Y', math.radians(14) * f)
            return d
        e = anims.ease
        go = e(t / 0.35) if t < 0.35 else 1.0 - e((t - 0.65) / 0.35)
        d["head"] = B @ rot_about(hp, 'X', math.radians(22) * go)    # baixa a cabeça para soprar
        d["wing_l"] = B @ rot_about(shl, 'Y', -math.radians(28) * go)
        d["wing_r"] = B @ rot_about(shr, 'Y', math.radians(28) * go)
        return d
    return {"anim": anim}


def hoard_dragon():
    """Dragão do Tesouro da carta: dragão dourado empinado sobre um monte de moedas, asas abertas para cima com garra
    na ponta, barriga creme, chifres longos e escuros, cabeça baixa e boca aberta, cauda caída sobre o ouro.
    O monte vai junto do modelo (no jogo ele voa com o tesouro embaixo)."""
    P = []
    scales = mat("hdscales", vcol=True, rough=0.55, bump=0.2, bump_scale=60)

    def col(p, n):
        c = mix(HD_RSD, HD_RS, smoothstep(-0.5, 0.7, n.z) * 0.6 + smoothstep(0.6, -0.4, n.y) * 0.2 + 0.2)
        bel = ell_w(p, (0, -0.45, 1.65), (0.55, 0.5, 1.05)) * smoothstep(0.35, -0.4, n.y)
        return mix(c, HD_BELLY, min(1.0, bel * 1.4))
    B = []
    body = fuse([sph((0, 0.2, 1.05), 1, (0.7, 0.6, 0.55)), sph((0, -0.02, 1.6), 1, (0.64, 0.52, 0.66)), sph((0, -0.12, 2.15), 1, (0.52, 0.42, 0.45)),
                 sph((0, -0.25, 2.55), 1, (0.3, 0.3, 0.32)), sph((0, -0.4, 2.85), 1, (0.25, 0.26, 0.25)),
                 # coxas dobradas dos lados, pés sobre o monte
                 sph((0.55, 0.15, 0.85), 1, (0.3, 0.45, 0.4)), sph((-0.55, 0.15, 0.85), 1, (0.3, 0.45, 0.4)),
                 sph((0.62, -0.3, 0.6), 1, (0.2, 0.34, 0.12)), sph((-0.62, -0.3, 0.6), 1, (0.2, 0.34, 0.12))] +
                # braços descendo para o ouro
                capsule((0.42, -0.2, 2.0), (0.6, -0.5, 1.45), 0.16, 0.12) + capsule((-0.42, -0.2, 2.0), (-0.6, -0.5, 1.45), 0.16, 0.12) +
                capsule((0.6, -0.5, 1.45), (0.5, -0.72, 0.85), 0.12, 0.1) + capsule((-0.6, -0.5, 1.45), (-0.5, -0.72, 0.85), 0.12, 0.1) +
                [sph((0.5, -0.8, 0.8), 1, (0.14, 0.18, 0.08)), sph((-0.5, -0.8, 0.8), 1, (0.14, 0.18, 0.08))], "hdbody", 0.02, 0.6, 6)
    paint(body, col); setmat(body, scales); B.append(body)
    cl = []
    for (cx, cy, cz) in ((0.5, -0.95, 0.78), (-0.5, -0.95, 0.78), (0.62, -0.62, 0.55), (-0.62, -0.62, 0.55)):
        for k in (-1, 0, 1):
            cl.append(tube([(cx + k * 0.08, cy, cz), (cx + k * 0.09, cy - 0.1, cz - 0.04), (cx + k * 0.09, cy - 0.13, cz - 0.13)], 0.04, 0.3, 6))
    cj = join(cl, "hdclaw"); setmat(cj, mat("hdhorn", HD_HORN, 0.5)); B.append(cj)
    fr = []
    for k in range(6):   # crista lisa da nuca às costas, como a carta
        t = k / 5.0
        fr.append(box((0, -0.15 + t * 0.55, 2.75 - t * 0.9), (0.06, 0.22, 0.22 - t * 0.08), (-20, 0, 0), bevel=0.01, taper=(0.2, 0.4)))
    fj = join(fr, "hdfrill"); hard(fj); setmat(fj, mat("hdfrill_m", (0.97, 0.85, 0.6), 0.5)); B.append(fj)
    tag(B, "body"); P += B
    # monte de moedas (parado: o osso "base" não se mexe)
    G = []
    mound = fuse([sph((0, -0.15, 0.1), 1, (1.35, 1.2, 0.5)), sph((0.55, -0.7, 0.05), 1, (0.7, 0.6, 0.3)), sph((-0.6, -0.55, 0.05), 1, (0.65, 0.65, 0.28)),
                  sph((0.0, 0.6, 0.05), 1, (0.9, 0.6, 0.32))], "hdmound", 0.025, 0.7, 6)
    z0 = -mound.location.z   # malha local: o chão do mundo fica em z0
    for v in mound.data.vertices:
        if v.co.z < z0:
            v.co.z = z0
    paint(mound, lambda p, n: mix(COIN_D, COIN, smoothstep(-0.2, 0.9, n.z) * 0.8 + 0.1)); setmat(mound, mat("hdgold", vcol=True, rough=0.35, metal=0.6)); G.append(mound)
    coins = []
    import random
    rnd = random.Random(7)
    for k in range(22):
        a = rnd.uniform(0, math.tau); r = rnd.uniform(0.3, 1.25)
        x, y = math.cos(a) * r, -0.15 + math.sin(a) * r * 0.9
        z = max(0.03, 0.6 * (1 - (r / 1.35) ** 2) + 0.02)
        coins.append(cyl((x, y, z), 0.09, 0.025, (rnd.uniform(-35, 35), rnd.uniform(-35, 35), 0), seg=10, bevel=0.0))
    cj2 = join(coins, "hdcoins"); setmat(cj2, mat("hdcoin", COIN, 0.3, 0.7)); G.append(cj2)
    tag(G, "base"); P += G
    # cauda caída sobre o ouro, dando a volta pela frente
    T = []
    tail = tube([(0, 0.6, 0.95), (0.65, 0.95, 0.6), (1.2, 0.3, 0.5), (1.15, -0.6, 0.45), (0.6, -1.25, 0.4)], 0.26, 0.15, 22)
    paint(tail, lambda p, n: mix(HD_RSD, HD_RS, smoothstep(-0.5, 0.7, n.z) * 0.6 + 0.3)); setmat(tail, scales); T.append(tail)
    tag(T, "tail"); P += T
    # cabeça baixa e boca aberta, chifres escuros longos
    Hh = _dragon_head(jaw_open=0.6, rs=HD_RS, rsd=HD_RSD, belly=HD_BELLY, horn=HD_HORN, eye=HD_EYE)
    xform(Hh, Matrix.Translation((0, -0.48, 3.0)) @ Matrix.Rotation(math.radians(34), 4, 'X') @ Matrix.Scale(1.0, 4))
    tag(Hh, "head"); P += Hh
    # asas abertas para cima, como na carta
    for sx, bone in ((1, "wing_l"), (-1, "wing_r")):
        W = _wing_at(sx, (0.38, 0.25, 2.2), (1.15, 0.4, 3.0), (1.75, 0.5, 3.75),
                     [(2.7, 0.75, 3.0), (2.85, 0.85, 2.0), (2.35, 0.8, 1.2), (1.4, 0.65, 0.95)], (0.4, 0.45, 1.35),
                     HD_RSD, HD_MEM, HD_HORN, 0.1)
        tag(W, bone); P += W
    return group("hoard_dragon", P)


def _hoard_anim():
    shl, shr = Vector((0.38, 0.25, 2.2)), Vector((-0.38, 0.25, 2.2))
    hp = Vector((0, -0.45, 2.9)); tp = Vector((0, 0.6, 0.95)); mid = Vector((0, 0.0, 1.2))
    TAU = math.tau

    def anim(kind, t):
        if kind == "walk":
            ph = TAU * t; f = math.sin(ph)
            B = tr(0, 0, 0.04 * math.sin(ph + 1.0)) @ rot_about(mid, 'X', math.radians(2) * math.cos(ph))
            return {"body": B, "head": B @ rot_about(hp, 'X', math.radians(5) * math.sin(ph + 1.6)),
                    "tail": rot_about(tp, 'Z', math.radians(5) * math.sin(ph + 0.6)),
                    "wing_l": B @ rot_about(shl, 'Y', -math.radians(18) * f), "wing_r": B @ rot_about(shr, 'Y', math.radians(18) * f)}
        e = anims.ease
        go = e(t / 0.35) if t < 0.35 else 1.0 - e((t - 0.6) / 0.4)
        B = rot_about(mid, 'X', math.radians(-10) * go)
        return {"body": B, "head": B @ rot_about(hp, 'X', math.radians(24) * go), "tail": rot_about(tp, 'Z', math.radians(10) * go),
                "wing_l": B @ rot_about(shl, 'Y', -math.radians(25) * go), "wing_r": B @ rot_about(shr, 'Y', math.radians(25) * go)}
    return {"anim": anim}


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
        return _elder_anim()
    if i == "hoard_dragon":
        return _hoard_anim()
    if i == "cave_troll":
        return {"anim": anims.biped(2.6, (0.34, 0.0, 0.95), (0.75, 0.05, 1.65), (0, -0.2, 1.8), stride=22, swing=16, atk="smash", atk_arm="arm_l", bob=0.025)}
    if i == "treasure_guard":
        return {"anim": anims.biped(2.0, (0.16, 0.0, 0.92), (0.38, 0.0, 1.42), (0, -0.02, 1.58), stride=22, swing=12, atk="smash", atk_arm="arm_r", bob=0.03)}
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
