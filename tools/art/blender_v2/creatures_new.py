"""Criaturas novas (17/11/2026): modelos que as cartas pediam e usavam emprestados (salamandra = ogro, dragãozinho =
morcego, urso = ogro, víbora = rato, fênix = dragão, dragão de ossos = dragão vermelho, golem de magma = golem de sucata).
Mesmo kit de mk.py; quadrúpedes com as partes marcadas por osso (anims._quad já anima).
Exportar: "C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --factory-startup -P tools/art/blender_g/build_g_all.py -- new <saída> [ids]
Blender: Z para cima, frente = -Y; +x = lado "l" dos ossos."""
import os, sys, math, traceback
HERE = os.path.dirname(os.path.abspath(__file__))
if HERE not in sys.path:
    sys.path.insert(0, HERE)
import bpy
from mathutils import Matrix, Vector
from mk import *
from vat import tag, rot_about, tr
import mk, vat, anims
from monsters import xform
from monsters2 import yellow_eye
from chars import BLACK, WHITE
import creatures_plague as CP
import creatures_dragon as CD

# id -> (altura em metros no jogo, orçamento de triângulos)
UNITS_NEW = {
    "ash_salamander": (0.8, 2600), "drakeling": (1.9, 3000), "brown_bear": (1.7, 3000), "spitting_viper": (1.1, 2200),
    "ash_phoenix": (3.0, 3200), "bone_dragon": (3.2, 3400), "magma_golem": (2.9, 3400),
    "crow_flock": (0.32, 1600),
}
TOOTH = (1, 0.97, 0.86)
EMBER = (1.0, 0.5, 0.12)


def _fur(col):
    return mat("nfur_%s" % str(col), vcol=True, rough=0.85, bump=0.3, bump_scale=110)


# =============================================================== Salamandra de Cinzas

def ash_salamander():
    SK = (0.13, 0.12, 0.15); SKD = (0.06, 0.05, 0.07); OR = (0.95, 0.42, 0.08); BEL = (0.34, 0.2, 0.2)
    P = []

    def col(p, n):
        c = mix(SKD, SK, smoothstep(-0.2, 0.9, n.z) * 0.7 + 0.2)
        for (x, y) in ((0.18, -0.35), (-0.2, -0.05), (0.2, 0.3), (-0.17, 0.6), (0.1, 0.95), (-0.08, 1.3)):   # manchas de brasa
            c = mix(c, OR, ell_w(p, (x, y, 0.32), (0.13, 0.17, 0.3)) * 0.95)
        return mix(c, BEL, smoothstep(0.1, -0.6, n.z) * 0.8)
    body = fuse([sph((0, -0.35, 0.3), 1, (0.42, 0.5, 0.26)), sph((0, 0.15, 0.28), 1, (0.38, 0.5, 0.24)), sph((0, 0.65, 0.26), 1, (0.28, 0.4, 0.2)),
                 sph((0, -0.78, 0.28), 1, (0.3, 0.3, 0.2))], "salbody", 0.014, 0.6, 5)
    paint(body, col); setmat(body, mat("salskin", vcol=True, rough=0.55, bump=0.25, bump_scale=80)); P.append(body)
    tag(P, "body")
    H = []
    head = fuse([sph((0, -1.0, 0.27), 1, (0.32, 0.34, 0.16)), sph((0, -1.3, 0.24), 1, (0.22, 0.22, 0.11))], "salhead", 0.012, 0.6, 5)
    paint(head, lambda p, n: mix(SKD, SK, smoothstep(-0.2, 0.9, n.z) * 0.7 + 0.2)); setmat(head, mat("salskin", vcol=True, rough=0.55, bump=0.25, bump_scale=80)); H.append(head)
    for sx in (-1, 1):
        e = sph((sx * 0.21, -1.12, 0.4), 1, (0.07, 0.07, 0.07)); setmat(e, mat("salglow", EMBER, 0.4, emit=5.0)); H.append(e)
        for k in range(2):   # branquias de brasa atrás da cabeça
            g = box((sx * (0.34 + k * 0.06), -0.78, 0.32 + k * 0.07), (0.16, 0.04, 0.05), (0, 0, sx * (25 + k * 20)), bevel=0.01, taper=(0.3, 0.5)); hard(g)
            setmat(g, mat("salglow", EMBER, 0.4, emit=3.0)); H.append(g)
    tag(H, "head"); P += H
    # patas abertas para os lados, de lagarto
    for key in ("fl", "fr", "bl", "br"):
        sx = 1 if key[1] == "l" else -1
        front = key[0] == "f"
        y = -0.5 if front else 0.5
        a = (sx * 0.34, y, 0.3); b = (sx * 0.62, y - 0.05, 0.17); c = (sx * 0.72, y - 0.18, 0.04)
        leg = fuse(capsule(a, b, 0.1, 0.075) + capsule(b, c, 0.075, 0.06) + [sph((c[0], c[1] - 0.06, 0.03), 1, (0.14, 0.17, 0.04))], "salleg", 0.012, 0.6, 4)
        paint(leg, lambda p, n: mix(SK, SKD, smoothstep(0.3, 0.05, p.z)) if True else SK); setmat(leg, mat("salskin", vcol=True, rough=0.55))
        L = [leg]
        tag(L, "leg_" + key); P += L
    # cauda comprida com a ponta em chama
    tail = tube([(0, 0.85, 0.26), (0.15, 1.35, 0.2), (-0.1, 1.85, 0.16), (0.1, 2.25, 0.2)], 0.2, 0.2, 20)
    paint(tail, lambda p, n: mix(mix(SKD, SK, 0.6), OR, smoothstep(1.7, 2.3, p.y) * 0.9)); setmat(tail, mat("salskin", vcol=True, rough=0.55))
    fl = cone_flame((0.1, 2.35, 0.3), 0.14, 0.42)
    tag([tail] + fl, "tail"); P += [tail] + fl
    return group("ash_salamander", P)


def cone_flame(loc, r, h):
    """Chama pequena emissiva (cone achatado + núcleo claro)."""
    out = []
    c = cyl((loc[0], loc[1], loc[2] + h / 2), r, h, seg=10, bevel=0.0, r2=0.01); setmat(c, mat("flame", (1.0, 0.45, 0.1), 0.4, emit=6.0)); out.append(c)
    k = cyl((loc[0], loc[1], loc[2] + h * 0.35), r * 0.5, h * 0.7, seg=10, bevel=0.0, r2=0.01); setmat(k, mat("flamek", (1.0, 0.85, 0.35), 0.4, emit=8.0)); out.append(k)
    return out


# =============================================================== Urso Pardo

def brown_bear():
    FUR = (0.42, 0.26, 0.16); FURD = (0.2, 0.12, 0.09); BEL = (0.56, 0.4, 0.27); SN = (0.62, 0.48, 0.34)
    P = []
    body = fuse([sph((0, -0.38, 0.92), 1, (0.46, 0.5, 0.5)), sph((0, 0.1, 0.8), 1, (0.44, 0.5, 0.42)), sph((0, 0.55, 0.7), 1, (0.44, 0.4, 0.4)),
                 sph((0, -0.5, 1.12), 1, (0.38, 0.4, 0.32))], "bearbody", 0.016, 0.6, 6)
    paint(body, lambda p, n: mix(mix(FUR, FURD, smoothstep(0.2, 0.9, n.z) * 0.5), BEL, smoothstep(0.1, -0.6, n.z) * 0.6))
    setmat(body, _fur(FUR)); P.append(body)
    tag(P, "body")
    H = []
    hd = fuse([sph((0, -0.95, 0.98), 1, (0.3, 0.3, 0.28)), sph((0, -1.2, 0.9), 1, (0.17, 0.2, 0.14))], "bearhead", 0.012, 0.6, 5)
    paint(hd, lambda p, n: mix(FUR, SN, smoothstep(-1.05, -1.3, p.y)) if p.y < -1.05 else mix(FUR, FURD, smoothstep(0.1, 0.9, n.z) * 0.4))
    setmat(hd, _fur(FUR)); H.append(hd)
    nose = sph((0, -1.39, 0.93), 1, (0.07, 0.05, 0.05)); setmat(nose, mat("pupil", BLACK, 0.2)); H.append(nose)
    for sx in (-1, 1):
        ear = sph((sx * 0.22, -0.82, 1.24), 1, (0.1, 0.06, 0.1)); setmat(ear, mat("bearear", FURD, 0.85)); H.append(ear)
        H += yellow_eye((sx * 0.13, -1.17, 1.05), 0.05, 20, sx, (0.9, 0.55, 0.2), FURD)
        f = box((sx * 0.07, -1.28, 0.79), (0.03, 0.03, 0.08), bevel=0.005, taper=(0.15, 0.4)); f.rotation_euler[0] = math.radians(180); hard(f); setmat(f, mat("tooth", TOOTH, 0.3)); H.append(f)
    tag(H, "head"); P += H
    for key in ("fl", "fr", "bl", "br"):
        sx = 1 if key[1] == "l" else -1
        front = key[0] == "f"
        if front:
            L = CP._leg(sx, True, (0.3, -0.45, 0.78), (0.31, -0.42, 0.4), (0.3, -0.5, 0.06), 0.17, FUR, FURD)
        else:
            L = CP._leg(sx, False, (0.3, 0.52, 0.75), (0.32, 0.62, 0.4), (0.3, 0.52, 0.06), 0.18, FUR, FURD)
        tag(L, "leg_" + key); P += L
    tl = sph((0, 0.98, 0.72), 1, (0.12, 0.12, 0.12)); setmat(tl, _fur(FURD)); tag([tl], "tail"); P.append(tl)
    return group("brown_bear", P)


# =============================================================== Víbora Cuspidora

def spitting_viper():
    G = (0.5, 0.58, 0.22); GD = (0.22, 0.3, 0.12); BEL = (0.85, 0.82, 0.55)
    pts = []
    for i in range(18):   # espiral de duas voltas subindo, depois o pescoço em S
        a = i / 17.0 * math.tau * 1.6
        r = 0.5 - i * 0.012
        pts.append((math.cos(a) * r, math.sin(a) * r, 0.1 + i * 0.012))
    last = pts[-1]
    pts += [(last[0] * 0.8, last[1] * 0.8, 0.45), (last[0] * 0.4, last[1] * 0.4 - 0.1, 0.8), (0.0, -0.18, 1.05), (0.0, -0.3, 1.3)]
    sn = tube(pts, 0.14, 0.45, 12)
    paint(sn, lambda p, n: mix(mix(GD, G, 0.55 + 0.45 * math.sin(p.z * 22 + math.atan2(p.y, p.x) * 3)), BEL, smoothstep(-0.2, -0.85, n.z) * 0.9))
    setmat(sn, mat("viperskin", vcol=True, rough=0.4, bump=0.2, bump_scale=140))
    P = [sn]
    hd = fuse([sph((0, -0.38, 1.37), 1, (0.17, 0.26, 0.1), (-18, 0, 0)), sph((0, -0.3, 1.34), 1, (0.2, 0.17, 0.1))], "vhead", 0.01, 0.6, 5)
    paint(hd, lambda p, n: mix(GD, G, smoothstep(-0.2, 0.9, n.z) * 0.8 + 0.1)); setmat(hd, mat("viperskin", vcol=True, rough=0.4)); P.append(hd)
    for sx in (-1, 1):
        P += yellow_eye((sx * 0.14, -0.38, 1.4), 0.05, 26, sx, (0.95, 0.9, 0.2), GD)
        fg = box((sx * 0.05, -0.55, 1.28), (0.02, 0.02, 0.13), bevel=0.004, taper=(0.1, 0.3)); fg.rotation_euler[0] = math.radians(180); hard(fg); setmat(fg, mat("tooth", TOOTH, 0.3)); P.append(fg)
    tg = tube([(0, -0.57, 1.3), (0, -0.7, 1.29), (0.04, -0.8, 1.29)], 0.012, 1.0, 6); setmat(tg, mat("tongue", (0.85, 0.2, 0.3), 0.5)); P.append(tg)
    sp = sph((0, -0.6, 1.2), 1, (0.05, 0.05, 0.08)); setmat(sp, mat("venom", (0.6, 1.0, 0.2), 0.4, emit=4.0)); P.append(sp)   # gota de veneno
    tag(P, "body")
    return group("spitting_viper", P)


def _viper_deform(p, n, bone, t):
    TAU = math.tau
    h = smoothstep(0.35, 1.3, p.z)
    if t <= 1.0:   # balança a cabeça
        q = Vector((p.x + 0.07 * math.sin(TAU * t + p.z * 2.0) * h, p.y, p.z))
        return q, n
    u = t - 1.0
    st = anims.ease(u / 0.35) if u < 0.35 else 1.0 - anims.ease((u - 0.6) / 0.4)
    q = Vector((p.x, p.y - 0.55 * st * h, p.z - 0.45 * st * h))   # bote: o pescoço desce para a frente
    return q, n


# =============================================================== Golem de Magma

def magma_golem():
    ROCK = (0.2, 0.19, 0.22); ROCKD = (0.1, 0.09, 0.11); LAVA = (1.0, 0.42, 0.08)
    rk = lambda c: mat("rock_%s" % str(c), c, 0.8, 0.05, bump=0.5, bump_scale=40)
    lava = mat("lava", LAVA, 0.4, emit=7.0)
    P = []
    B = []
    chest = box((0, 0, 1.45), (1.3, 0.9, 0.95), (0, 0, 0), bevel=0.14, seg=3, taper=(1.1, 1.0)); hard(chest); setmat(chest, rk(ROCK)); B.append(chest)
    belly = box((0, 0.02, 0.9), (0.9, 0.7, 0.5), bevel=0.1); hard(belly); setmat(belly, rk(ROCKD)); B.append(belly)
    hip = box((0, 0.02, 0.62), (1.0, 0.65, 0.24), bevel=0.08); hard(hip); setmat(hip, rk(ROCK)); B.append(hip)
    # fendas de lava na barriga e no peito
    for (x, z, w, h_) in ((0, 1.5, 0.05, 0.7), (-0.3, 1.35, 0.04, 0.4), (0.3, 1.2, 0.04, 0.45), (0, 0.9, 0.04, 0.4)):
        c = box((x, -0.46, z), (w, 0.04, h_), (0, 0, (x * 30)), bevel=0.006); hard(c); setmat(c, lava); B.append(c)
    core = sph((0, -0.45, 1.5), 1, (0.22, 0.06, 0.22)); setmat(core, lava); B.append(core)
    tag(B, "body"); P += B
    Hd = []
    head = box((0, -0.08, 2.08), (0.5, 0.46, 0.34), bevel=0.08, taper=(0.8, 0.85)); hard(head); setmat(head, rk(ROCKD)); Hd.append(head)
    for sx in (-1, 1):
        e = box((sx * 0.12, -0.31, 2.1), (0.12, 0.03, 0.045), (0, 0, sx * 10), bevel=0.005); hard(e); setmat(e, lava); Hd.append(e)
    tag(Hd, "head"); P += Hd
    for sx in (-1, 1):
        A = []
        sh = sph((sx * 0.82, 0.0, 1.75), 1, (0.34, 0.32, 0.28)); setmat(sh, rk(ROCK)); A.append(sh)
        up = box((sx * 0.9, -0.02, 1.25), (0.36, 0.34, 0.62), (0, sx * -8, 0), bevel=0.08); hard(up); setmat(up, rk(ROCKD)); A.append(up)
        fist = box((sx * 0.98, -0.1, 0.62), (0.58, 0.55, 0.55), (0, 0, sx * 10), bevel=0.1, seg=2); hard(fist); setmat(fist, rk(ROCK)); A.append(fist)
        c = box((sx * 0.9, -0.1, 1.2), (0.05, 0.38, 0.05), bevel=0.006); hard(c); setmat(c, lava); A.append(c)
        d = tube([(sx * 0.98, -0.1, 0.35), (sx * 0.98, -0.1, 0.15), (sx * 0.98, -0.1, 0.02)], 0.03, 0.4, 6); setmat(d, lava); A.append(d)   # gotas
        tag(A, "arm_l" if sx > 0 else "arm_r"); P += A
        L = []
        leg = box((sx * 0.3, 0.02, 0.32), (0.4, 0.4, 0.55), bevel=0.08); hard(leg); setmat(leg, rk(ROCK)); L.append(leg)
        ft = box((sx * 0.32, -0.07, 0.08), (0.46, 0.58, 0.16), bevel=0.06); hard(ft); setmat(ft, rk(ROCKD)); L.append(ft)
        kn = box((sx * 0.3, -0.2, 0.45), (0.05, 0.05, 0.3), bevel=0.006); hard(kn); setmat(kn, lava); L.append(kn)
        tag(L, "leg_l" if sx > 0 else "leg_r"); P += L
    return group("magma_golem", P)


# =============================================================== Fênix das Cinzas

def ash_phoenix():
    RED = (0.85, 0.2, 0.06); ORA = (1.0, 0.5, 0.1); GOLD = (1.0, 0.8, 0.25); DARK = (0.4, 0.08, 0.05)
    fm = lambda n, c, e=3.0: mat(n, c, 0.5, emit=e)
    P = []
    B = []
    body = fuse([sph((0, 0, 1.3), 1, (0.36, 0.6, 0.38)), sph((0, -0.45, 1.55), 1, (0.28, 0.32, 0.3)), sph((0, 0.45, 1.15), 1, (0.26, 0.4, 0.26)),
                 sph((0, -0.6, 1.85), 1, (0.17, 0.2, 0.22))], "phbody", 0.016, 0.6, 5)
    paint(body, lambda p, n: mix(mix(DARK, RED, smoothstep(-0.2, 0.9, n.z) * 0.8 + 0.1), GOLD, smoothstep(0.0, -0.9, n.z) * 0.8 + ell_w(p, (0, -0.4, 1.5), (0.3, 0.3, 0.3)) * 0.5))
    setmat(body, mat("phfeather", vcol=True, rough=0.5, emit=0.0)); B.append(body)
    for sx in (-1, 1):   # garras
        for k in (-1, 0, 1):
            c = tube([(sx * 0.15 + k * 0.04, -0.1, 0.98), (sx * 0.15 + k * 0.05, -0.22, 0.88), (sx * 0.15 + k * 0.05, -0.3, 0.8)], 0.025, 0.5, 6); setmat(c, mat("claw", (0.2, 0.15, 0.1), 0.4)); B.append(c)
    tag(B, "body"); P += B
    Hd = []
    head = fuse([sph((0, -0.7, 2.0), 1, (0.2, 0.24, 0.2))], "phhead", 0.01, 0.6, 5)
    paint(head, lambda p, n: mix(RED, ORA, smoothstep(-0.2, 0.9, n.z))); setmat(head, mat("phfeather", vcol=True, rough=0.5)); Hd.append(head)
    bk = cyl((0, -0.98, 1.95), 0.09, 0.3, (90, 0, 0), seg=14, bevel=0.0, r2=0.015); setmat(bk, mat("beak", (1.0, 0.75, 0.25), 0.35)); Hd.append(bk)
    for sx in (-1, 1):
        e = sph((sx * 0.13, -0.78, 2.06), 1, (0.05, 0.05, 0.05)); setmat(e, mat("phglow", (1.0, 0.92, 0.5), 0.4, emit=6.0)); Hd.append(e)
    for k in range(4):   # crista de chamas
        cf = box((0, -0.55 + k * 0.1, 2.2 + 0.04 * (k % 2)), (0.05, 0.1, 0.42 - k * 0.05), (-25 - k * 8, 0, 0), bevel=0.01, taper=(0.1, 0.3)); hard(cf); setmat(cf, fm("phflame", ORA, 4.0)); Hd.append(cf)
    tag(Hd, "head"); P += Hd
    # cauda: cinco penas longas, em leque para trás e para baixo
    T = []
    for k, ang in enumerate((-30, -15, 0, 15, 30)):
        L = 1.9 - abs(k - 2) * 0.25
        a = math.radians(ang)
        pf = box((math.sin(a) * 0.8 * L / 1.9 * 0.5, 0.6 + L * 0.5 * math.cos(a), 1.05 - L * 0.2), (0.14, L, 0.05), (14, 0, -ang * 0.6), bevel=0.01, taper=(0.3, 1.0)); hard(pf)
        paint(pf, lambda p, n: mix(RED, GOLD, smoothstep(0.8, 2.4, p.y))); setmat(pf, mat("phfeather", vcol=True, rough=0.5, emit=0.0)); T.append(pf)
    tag(T, "tail"); P += T
    # asas: leque de penas de cada lado, ombro em (±0.32, 0, 1.55)
    for sx, bone in ((1, "wing_l"), (-1, "wing_r")):
        W = []
        for k in range(8):
            t = k / 7.0
            ang = math.radians(-20 + t * 95)    # da frente (alto) para trás (baixo)
            L = 2.0 + 0.4 * math.sin(t * 3.0) - t * 0.5
            cx = sx * (0.32 + math.cos(ang) * L * 0.5); cz = 1.55 + math.sin(ang * 0.0 + (0.35 - t * 0.9)) * L * 0.5
            pf = box((cx, 0.0 + t * 0.55, cz), (L, 0.2 + t * 0.07, 0.04), (0, 0, sx * (20 - t * 55)), bevel=0.008, taper=(1.0, 0.3)); hard(pf)
            paint(pf, lambda p, n, t=t: mix(mix(RED, ORA, t), GOLD, smoothstep(2.0, 3.2, abs(p.x)) * 0.8)); setmat(pf, mat("phfeather", vcol=True, rough=0.5)); W.append(pf)
        arm = tube([(sx * 0.3, 0.0, 1.55), (sx * 1.0, 0.0, 1.8), (sx * 1.9, 0.05, 1.95)], 0.07, 0.5, 12); setmat(arm, mat("phbone", DARK, 0.6)); W.append(arm)
        tag(W, bone); P += W
    return group("ash_phoenix", P)


def _phoenix_anim():
    shl, shr = Vector((0.32, 0.0, 1.55)), Vector((-0.32, 0.0, 1.55))
    hp = Vector((0, -0.45, 1.6)); tp = Vector((0, 0.45, 1.15)); mid = Vector((0, 0.0, 1.3))
    TAU = math.tau

    def anim(kind, t):
        if kind == "walk":
            ph = TAU * t; f = math.sin(ph)
            B = tr(0, 0, 0.12 * math.sin(ph + 1.0)) @ rot_about(mid, 'X', math.radians(3) * math.cos(ph))
            return {"body": B, "head": B @ rot_about(hp, 'X', math.radians(5) * math.sin(ph + 1.6)),
                    "tail": B @ rot_about(tp, 'X', math.radians(8) * math.sin(ph + 0.6)),
                    "wing_l": B @ rot_about(shl, 'Y', -math.radians(34) * f), "wing_r": B @ rot_about(shr, 'Y', math.radians(34) * f)}
        e = anims.ease
        go = e(t / 0.35) if t < 0.35 else 1.0 - e((t - 0.6) / 0.4)
        B = tr(0, -0.25 * go, 0.0) @ rot_about(mid, 'X', math.radians(-8) * go)
        return {"body": B, "head": B @ rot_about(hp, 'X', math.radians(26) * go), "tail": B @ rot_about(tp, 'X', math.radians(14) * go),
                "wing_l": B @ rot_about(shl, 'Y', -math.radians(40) * (1 - go) + math.radians(24) * go),
                "wing_r": B @ rot_about(shr, 'Y', math.radians(40) * (1 - go) - math.radians(24) * go)}
    return {"anim": anim}


# =============================================================== Dragão de Ossos e Dragãozinho (geometria do antigo Dragão Ancião)

def _elder_with(rs, rsd, belly, mem, eye, skel=False, name="elder_dragon"):
    old = (CD.RS, CD.RSD, CD.BELLY, CD.MEM, CD.EYEC, CD.SKEL)
    CD.RS, CD.RSD, CD.BELLY, CD.MEM, CD.EYEC, CD.SKEL = rs, rsd, belly, mem, eye, skel
    try:
        root = CD.winged_dragon()
    finally:
        CD.RS, CD.RSD, CD.BELLY, CD.MEM, CD.EYEC, CD.SKEL = old
    root.name = name
    return root


def bone_dragon():
    return _elder_with((0.86, 0.82, 0.7), (0.5, 0.46, 0.4), (0.9, 0.86, 0.72), (0.5, 0.55, 0.5), (0.4, 1.0, 0.85), True, "bone_dragon")


def drakeling():
    return _elder_with((0.8, 0.16, 0.1), (0.42, 0.07, 0.08), (0.96, 0.78, 0.5), (0.9, 0.35, 0.14), (1.0, 0.8, 0.2), False, "drakeling")


# =============================================================== Revoada de Corvos (27/11/2026)

# Cores da carta: corvos cinza-ardósia escuros, penas das pontas mais claras, bico cinza.
CR = (0.13, 0.13, 0.15); CR_D = (0.05, 0.05, 0.07); CR_L = (0.24, 0.24, 0.27); BEAK = (0.26, 0.26, 0.28)
CR_SH = (0.12, -0.1, 0.6)   # ombro do lado +x


def crow_flock():
    """Um corvo de asas abertas (o enxame põe vários): corpo e cabeça escuros, bico grosso, asas largas com as penas
    das pontas separadas como dedos, cauda em leque. Penas de cada asa numa peça só (o simplify apaga as soltas)."""
    P = []
    feather = mat("crfeather", vcol=True, rough=0.7, bump=0.15, bump_scale=90)

    def col(p, n):
        return mix(CR_D, CR, smoothstep(-0.6, 0.8, n.z) * 0.75 + 0.15)
    B = []
    body = fuse([sph((0, 0.0, 0.56), 1, (0.17, 0.26, 0.16), (-6, 0, 0)), sph((0, -0.28, 0.64), 1, (0.16, 0.17, 0.16)),
                 sph((0, 0.2, 0.53), 1, (0.1, 0.14, 0.08))], "crbody", 0.008, 0.6, 5)
    paint(body, col); setmat(body, feather); B.append(body)
    beak = fuse([box((0, -0.5, 0.61), (0.09, 0.26, 0.1), (8, 0, 0), bevel=0.01, taper=(0.15, 0.5)),
                 sph((0, -0.42, 0.63), 1, (0.06, 0.08, 0.06))], "crbeak", 0.006, 0.4, 2)
    setmat(beak, mat("crbeak_m", BEAK, 0.45)); B.append(beak)
    for sx in (-1, 1):
        B += yellow_eye((sx * 0.1, -0.37, 0.69), 0.032, 10, sx, (0.2, 0.2, 0.25), CR_D)
    tail = []
    for k in range(5):   # cauda em leque
        a = (k - 2) * 14
        tail.append(box((math.sin(math.radians(a)) * 0.12, 0.42 + math.cos(math.radians(a)) * 0.08, 0.5), (0.07, 0.28, 0.02), (4, 0, -a), bevel=0.005, taper=(1.0, 0.7)))
    tj = join(tail, "crtail"); paint(tj, lambda p, n: mix(CR_D, CR, 0.5)); setmat(tj, feather); B.append(tj)
    tag(B, "body"); P += B
    # asas abertas, um pouco erguidas (diedro), penas primárias separadas nas pontas
    for sx, bone in ((1, "wing_l"), (-1, "wing_r")):
        sh = Vector((sx * CR_SH[0], CR_SH[1], CR_SH[2]))
        parts = [sph((sx * 0.32, 0.02, 0.64), 1, (0.25, 0.22, 0.03), (0, sx * -10, 0)),
                 sph((sx * 0.58, 0.04, 0.7), 1, (0.2, 0.19, 0.025), (0, sx * -12, 0))]
        inner = fuse(parts, "crwing", 0.008, 0.5, 3)
        prim = []
        for k in range(6):   # primárias: lâminas em leque na ponta
            a = -20 + k * 14
            ca, sa = math.cos(math.radians(a)), math.sin(math.radians(a))
            L = 0.34 - abs(k - 2) * 0.02
            cx = sx * (0.72 + ca * L * 0.5); cy = 0.02 + sa * L * 0.5
            prim.append(box((cx, cy, 0.73 + (0.02 if k < 3 else 0.0)), (L, 0.075, 0.015), (0, sx * -12, sx * a), bevel=0.004, taper=(1.0, 0.55)))
        for k in range(4):   # secundárias: borda de trás da asa
            prim.append(box((sx * (0.22 + k * 0.13), 0.25, 0.64 + k * 0.02), (0.12, 0.26, 0.015), (0, sx * -10, sx * (8 - k * 4)), bevel=0.004, taper=(1.0, 0.6)))
        w = join([inner] + prim, "crwing")
        paint(w, lambda p, n, sx=sx: mix(mix(CR_D, CR, smoothstep(-0.5, 0.8, n.z) * 0.7 + 0.2), CR_L, smoothstep(0.55, 0.95, abs(p.x)) * 0.5))
        setmat(w, feather)
        tag([w], bone); P.append(w)
    return group("crow_flock", P)


def _crow_anim():
    shl, shr = Vector(CR_SH), Vector((-CR_SH[0], CR_SH[1], CR_SH[2]))
    TAU = math.tau

    def anim(kind, t):
        if kind == "walk":
            ph = TAU * t
            f = math.sin(ph)
            B = tr(0, 0, 0.05 * math.sin(ph + 1.2))
            return {"body": B, "wing_l": B @ rot_about(shl, 'Y', -math.radians(28) * f),
                    "wing_r": B @ rot_about(shr, 'Y', math.radians(28) * f)}
        e = anims.ease
        go = e(t / 0.35) if t < 0.35 else 1.0 - e((t - 0.6) / 0.4)   # mergulho de bico para a frente
        B = tr(0, -0.35 * go, -0.12 * go) @ rot_about(Vector((0, 0, 0.6)), 'X', math.radians(22 * go))
        return {"body": B, "wing_l": B @ rot_about(shl, 'Y', -math.radians(55) * (1 - go) + math.radians(25) * go),
                "wing_r": B @ rot_about(shr, 'Y', math.radians(55) * (1 - go) - math.radians(25) * go)}
    return {"anim": anim}


# =============================================================== exportação

def _cfg(i):
    if i == "ash_salamander":
        return {"anim": anims._quad(1.0, (0.34, -0.5, 0.3), (0.34, 0.5, 0.3), (0, -0.75, 0.3), (0, 0.85, 0.26), stride=34, bob=0.03)}
    if i == "brown_bear":
        return {"anim": anims._quad(1.0, (0.3, -0.45, 0.78), (0.3, 0.52, 0.75), (0, -0.8, 1.0), (0, 0.95, 0.72), stride=26, bob=0.03)}
    if i == "spitting_viper":
        return {"deform": _viper_deform}
    if i == "magma_golem":
        return {"anim": anims.biped(2.2, (0.3, 0.02, 0.6), (0.82, 0.0, 1.75), (0, 0, 1.95), stride=18, swing=14, atk="smash", atk_arm="arm_l", bob=0.02, lean=8)}
    if i == "ash_phoenix":
        return _phoenix_anim()
    if i == "crow_flock":
        return _crow_anim()
    if i in ("bone_dragon", "drakeling"):
        return CD._dragon_anim()
    return {}


def main():
    argv = sys.argv[sys.argv.index("--") + 1:]
    out = os.path.abspath(argv[0])
    os.makedirs(out, exist_ok=True)
    ids = argv[1].split(",") if len(argv) > 1 else list(UNITS_NEW)
    for i in ids:
        try:
            bpy.ops.wm.read_factory_settings(use_empty=True)
            mk._MATS.clear()
            root = globals()[i]()
            h, b = UNITS_NEW[i]
            a = _cfg(i)
            vat.export(root, os.path.join(out, i + ".lbm"), h, b, a.get("anim"), a.get("deform"), a.get("rig"))
            print("OK", i)
        except Exception:
            print("FALHOU", i)
            traceback.print_exc()


if __name__ == "__main__":
    main()
