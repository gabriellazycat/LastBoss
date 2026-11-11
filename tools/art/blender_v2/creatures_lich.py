"""Criaturas do Lich e do Titã da Ruína (rodada dos vilões, 10/11/2026), no kit de mk.py.
O mesmo modelo serve à carta (tools/art/card_ink/scenes_lich.py) e ao jogo (export_lich.py).
Partes marcadas por osso (vat.tag): body, head, arm_l (+x), arm_r (-x), leg_l, leg_r. Frente = -Y, Z para cima."""
import math
import bpy
from mathutils import Matrix, Vector
from mk import *
from vat import tag
import monsters
from monsters import glow_eye, BONE, BONE_D, IRON, RUST, xform

PUR = (0.72, 0.4, 1.0)          # brilho arcano
GRN = (0.55, 1.0, 0.45)         # brilho de alma
DARK = (0.17, 0.16, 0.24)
DARK2 = (0.1, 0.09, 0.15)
TRIM = (0.46, 0.26, 0.7)
STONE = (0.56, 0.54, 0.5)
STONE_D = (0.36, 0.34, 0.33)
MOSS = (0.35, 0.5, 0.2)
LAVA = (1.0, 0.5, 0.12)


def _bone_mat():
    return mat("bone", BONE, 0.6, bump=0.15, bump_scale=40)


def _glow(name, c, e=8.0):
    return mat(name, c, 0.4, emit=e)


def _limb(P, bone, a, b, c, r1, r2, r3, m, joint=None):
    """Braço ou perna em dois segmentos com junta redonda."""
    parts = capsule(a, b, r1, r2) + capsule(b, c, r2, r3) + [sph(b, r2 * 1.15)]
    for o in parts:
        setmat(o, m)
    tag(parts, bone)
    P += parts


def _skull(P, loc, s, bone, eye=PUR, jaw=True):
    x, y, z = loc
    sk = fuse([sph((x, y, z), 1, (0.3 * s, 0.28 * s, 0.27 * s)), sph((x, y - 0.08 * s, z - 0.14 * s), 1, (0.22 * s, 0.2 * s, 0.14 * s))], "skull", 0.01 * s + 0.004)
    setmat(sk, mat("bone", BONE, 0.6, bump=0.15, bump_scale=40)); P.append(sk)
    parts = [sk]
    for sx in (-1, 1):
        parts += glow_eye((x + sx * 0.11 * s, y - 0.24 * s, z - 0.01 * s), 0.085 * s, eye)
    nose = box((x, y - 0.29 * s, z - 0.11 * s), (0.05 * s, 0.03 * s, 0.05 * s), (0, 45, 0), bevel=0.01); hard(nose)
    setmat(nose, mat("socket", (0.05, 0.03, 0.06), 0.6)); parts.append(nose)
    if jaw:
        j = fuse([sph((x, y - 0.12 * s, z - 0.24 * s), 1, (0.16 * s, 0.13 * s, 0.06 * s))], "jaw", 0.008 * s + 0.003); setmat(j, mat("bone", BONE, 0.6)); parts.append(j)
        for k in range(5):
            t = box((x - 0.1 * s + k * 0.05 * s, y - 0.245 * s, z - 0.19 * s), (0.035 * s, 0.02 * s, 0.045 * s), bevel=0.006); hard(t)
            setmat(t, mat("tooth", (1, 0.97, 0.88), 0.3)); parts.append(t)
    return parts


# ------------------------------------------------------------------ Cavaleiro da Morte (altura ~2.0)

def death_knight():
    P = []
    ar = mat("dkarmor", DARK, 0.45, 0.7, bump=0.1, bump_scale=60)
    ar2 = mat("dkarmor2", DARK2, 0.5, 0.7)
    trim = mat("dktrim", TRIM, 0.35, 0.8)
    cloth = mat("dkcloth", (0.25, 0.08, 0.3), 0.9, bump=0.2, bump_scale=60)
    bm = _bone_mat()
    # pernas
    for sx in (-1, 1):
        L = []
        thigh = capsule((sx * 0.14, 0.02, 0.98), (sx * 0.15, -0.03, 0.55), 0.1, 0.085)
        shin = capsule((sx * 0.15, -0.03, 0.55), (sx * 0.15, 0.0, 0.1), 0.085, 0.075)
        for o in thigh + shin + [sph((sx * 0.15, -0.05, 0.55), 0.11)]:
            setmat(o, ar); L.append(o)
        knee = box((sx * 0.15, -0.12, 0.55), (0.14, 0.08, 0.14), bevel=0.02, taper=(0.4, 0.5)); hard(knee); setmat(knee, trim); L.append(knee)
        boot = box((sx * 0.16, -0.08, 0.06), (0.2, 0.4, 0.14), bevel=0.04, taper=(0.8, 0.7)); hard(boot); setmat(boot, ar2); L.append(boot)
        tag(L, "leg_l" if sx > 0 else "leg_r"); P += L
    # tronco: couraça, cintura, saiote, capa
    B = []
    chest = box((0, 0, 1.38), (0.7, 0.46, 0.55), bevel=0.07, seg=3, taper=(1.25, 1.1)); hard(chest); setmat(chest, ar); B.append(chest)
    waist = box((0, 0.01, 1.04), (0.46, 0.34, 0.3), bevel=0.05, taper=(1.2, 1.1)); hard(waist); setmat(waist, ar2); B.append(waist)
    crest = box((0, -0.24, 1.4), (0.08, 0.05, 0.4), bevel=0.015, taper=(0.4, 1)); hard(crest); setmat(crest, trim); B.append(crest)
    core = sph((0, -0.26, 1.42), 1, (0.09, 0.04, 0.09)); setmat(core, _glow("dkcore", PUR)); B.append(core)
    for z in (1.12, 1.0, 0.9):
        pl = box((0, -0.16, z), (0.5 - (1.12 - z) * 0.3, 0.1, 0.07), (0, 0, 0), bevel=0.015); hard(pl); setmat(pl, ar); B.append(pl)
    tab = box((0, -0.14, 0.82), (0.3, 0.05, 0.3), bevel=0.02, taper=(0.5, 1)); tab.rotation_euler[0] = math.radians(180); hard(tab); setmat(tab, cloth); B.append(tab)
    cape = fuse([sph((0, 0.26, 1.2), 1, (0.38, 0.07, 0.62), (8, 0, 0)), sph((0, 0.33, 0.7), 1, (0.32, 0.05, 0.3), (14, 0, 0)),
                 sph((-0.2, 0.36, 0.45), 1, (0.1, 0.04, 0.2), (14, 0, 0)), sph((0.2, 0.36, 0.45), 1, (0.1, 0.04, 0.2), (14, 0, 0))], "dkcape", 0.015, 0.5, 4)
    setmat(cape, cloth); B.append(cape)
    tag(B, "body"); P += B
    # braços: ombreiras com espinhos, manoplas
    for sx in (-1, 1):
        A = []
        sp = sph((sx * 0.42, 0.0, 1.55), 1, (0.2, 0.2, 0.15)); setmat(sp, ar); A.append(sp)
        for k, a in enumerate((0, 40, -40)):
            s = box((sx * (0.5 + 0.02 * k), 0.0, 1.66 + 0.02 * k), (0.06, 0.06, 0.2), (a * 0.3, sx * (30 + a * 0.4), 0), bevel=0.01, taper=(0.05, 0.05)); hard(s); setmat(s, trim); A.append(s)
        if sx > 0:
            hand_at = (0.55, -0.2, 0.92)
        else:
            hand_at = (-0.55, -0.34, 1.02)
        up = capsule((sx * 0.42, 0.0, 1.5), (sx * 0.55, -0.04, 1.2), 0.085, 0.07) + capsule((sx * 0.55, -0.04, 1.2), hand_at, 0.07, 0.065) + [sph((sx * 0.55, -0.04, 1.2), 0.08)]
        for o in up: setmat(o, ar)
        A += up
        fist = fuse([sph(hand_at, 0.09, (1, 1, 0.9))], "dkfist", 0.01); setmat(fist, ar2); A.append(fist)
        if sx < 0:   # espada longa de lâmina rúnica na mão direita (-x), ponta para cima
            blade = box((0, 0, 0.62), (0.1, 0.035, 1.16), bevel=0.012, taper=(0.35, 1)); hard(blade); setmat(blade, mat("dkblade", (0.35, 0.34, 0.42), 0.35, 0.9))
            fuller = box((0, -0.02, 0.5), (0.025, 0.02, 0.8), bevel=0.004); setmat(fuller, _glow("dkrune", PUR, 5.0))
            guard = box((0, 0, 0.02), (0.34, 0.06, 0.06), bevel=0.015); hard(guard); setmat(guard, trim)
            grip = cyl((0, 0, -0.12), 0.03, 0.22, seg=8, bevel=0.004); hard(grip); setmat(grip, mat("leather", (0.2, 0.12, 0.2), 0.6))
            pom = sph((0, 0, -0.25), 0.05); setmat(pom, trim)
            W = xform([blade, fuller, guard, grip, pom], Matrix.Translation(hand_at) @ Matrix.Rotation(math.radians(-12), 4, 'X'))
            A += W
        else:        # escudo esburacado com caveira
            shd = box((0.0, 0, 0), (0.62, 0.06, 0.78), bevel=0.04, taper=(0.9, 1)); hard(shd); setmat(shd, ar)
            rim = box((0, -0.035, 0), (0.46, 0.03, 0.62), bevel=0.02); hard(rim); setmat(rim, ar2)
            em = sph((0, -0.06, 0.04), 1, (0.1, 0.03, 0.1)); setmat(em, _glow("dkcore", PUR))
            S = xform([shd, rim, em], Matrix.Translation((0.62, -0.28, 0.98)) @ Matrix.Rotation(math.radians(-20), 4, 'Z'))
            A += S
        tag(A, "arm_l" if sx > 0 else "arm_r"); P += A
    # cabeça: caveira sob elmo com chifres
    H = _skull([], (0, -0.02, 1.88), 0.85, "head", PUR)
    helm = fuse([sph((0, 0.04, 1.97), 1, (0.29, 0.28, 0.22))], "dkhelm", 0.012)
    cut = box((0, -0.05, 1.75), (0.9, 0.9, 0.3), bevel=0)
    m = helm.modifiers.new("c", 'BOOLEAN'); m.object = cut; m.operation = 'DIFFERENCE'; m.solver = 'EXACT'; apply_mods(helm); bpy.data.objects.remove(cut)
    shade(helm); setmat(helm, ar); H.append(helm)
    for sx in (-1, 1):
        h = tube([(sx * 0.24, 0.04, 1.98), (sx * 0.4, 0.02, 2.04), (sx * 0.42, -0.04, 2.24)], 0.045, 0.1, 12); setmat(h, mat("dkhorn", BONE_D, 0.5)); H.append(h)
    crest = box((0, 0.04, 2.2), (0.04, 0.34, 0.1), bevel=0.01, taper=(1, 0.2)); hard(crest); setmat(crest, trim); H.append(crest)
    tag(H, "head"); P += H
    return group("death_knight", P)


# ------------------------------------------------------------------ Colosso de Ossos (altura ~3.2)

def _bone(a, b, r):
    """Osso longo com nós nas pontas."""
    a, b = Vector(a), Vector(b)
    ps = capsule(a, b, r, r * 0.8) + [sph(a + (b - a).normalized() * -0.01, r * 1.7), sph(b, r * 1.5)]
    for o in ps: setmat(o, _bone_mat())
    return ps


def bone_colossus():
    P = []
    bm = _bone_mat()
    bd = mat("bone_d", BONE_D, 0.7)
    glow = _glow("colglow", GRN)
    # pernas: fêmures grossos, joelhos de crânio, pés largos
    for sx in (-1, 1):
        L = []
        L += _bone((sx * 0.38, 0.0, 1.45), (sx * 0.4, -0.08, 0.82), 0.13)
        L += _bone((sx * 0.4, -0.08, 0.82), (sx * 0.4, 0.0, 0.14), 0.11)
        L += _skull([], (sx * 0.4, -0.22, 0.86), 0.38, "leg", GRN, jaw=False)
        foot = fuse([sph((sx * 0.4, -0.12, 0.08), 1, (0.2, 0.3, 0.1))] + [sph((sx * 0.4 + k * 0.1, -0.4, 0.06), 1, (0.05, 0.12, 0.04)) for k in (-1, 0, 1)], "foot", 0.015)
        setmat(foot, bm); L.append(foot)
        tag(L, "leg_l" if sx > 0 else "leg_r"); P += L
    # tronco: bacia, coluna, caixa torácica enorme com núcleo de almas
    B = []
    pelvis = fuse([sph((0, 0.05, 1.55), 1, (0.5, 0.28, 0.2)), sph((0.3, 0.0, 1.58), 1, (0.2, 0.2, 0.2)), sph((-0.3, 0.0, 1.58), 1, (0.2, 0.2, 0.2))], "pelvis", 0.02); setmat(pelvis, bm); B.append(pelvis)
    spine = tube([(0, 0.18, 1.5), (0, 0.24, 1.9), (0, 0.2, 2.35)], 0.09, 0.9, 14); setmat(spine, bd); B.append(spine)
    for k in range(6):
        z = 1.78 + k * 0.13; w = 0.62 - abs(k - 2.3) * 0.07
        rib = torus((0, 0.0, z), w, 0.05, (0, 0, 0), s=(1, 0.62, 0.55)); shade(rib); setmat(rib, bm); B.append(rib)
    stern = box((0, -0.34, 2.12), (0.12, 0.06, 0.62), bevel=0.02); hard(stern); setmat(stern, bm); B.append(stern)
    soul = sph((0, -0.04, 2.1), 1, (0.22, 0.2, 0.26)); setmat(soul, glow); B.append(soul)
    for k in range(4):
        a = k * 1.7
        w = sph((math.cos(a) * 0.3, -0.04 + math.sin(a) * 0.12, 2.0 + 0.1 * k), 0.07, (1, 1, 1.4)); setmat(w, glow); B.append(w)
    # caveiras e ossos engolidos presos na caixa (absorve mortos)
    for (x, y, z, s) in ((0.42, -0.3, 1.85, 0.38), (-0.48, -0.26, 2.25, 0.34), (0.1, 0.34, 2.0, 0.4)):
        B += _skull([], (x, y, z), s, "body", GRN, jaw=False)
    tag(B, "body"); P += B
    # braços compridos que arrastam; mãos de ossos empilhados
    for sx in (-1, 1):
        A = []
        sh = (sx * 0.78, 0.04, 2.35)
        A += [sph(sh, 0.28, (1, 1, 0.8))]
        A += _bone(sh, (sx * 1.0, -0.1, 1.7), 0.12) + _bone((sx * 1.0, -0.1, 1.7), (sx * 0.95, -0.4, 1.05), 0.1)
        fist = fuse([sph((sx * 0.95, -0.45, 0.95), 1, (0.28, 0.26, 0.26))] + [sph((sx * 0.95 + k * 0.14, -0.62, 0.86), 1, (0.06, 0.1, 0.06)) for k in (-1.5, -0.5, 0.5, 1.5)], "fist", 0.018)
        A.append(fist)
        for o in A: setmat(o, bm)
        A += _skull([], (sx * 1.05, -0.3, 1.3), 0.34, "arm", GRN, jaw=False)
        tag(A, "arm_l" if sx > 0 else "arm_r"); P += A
    # cabeça: crânio imenso de mandíbula travada e presas, nas costas curvadas
    H = _skull([], (0, -0.22, 2.78), 1.55, "head", GRN)
    for sx in (-1, 1):
        t = tube([(sx * 0.2, -0.62, 2.45), (sx * 0.26, -0.7, 2.28), (sx * 0.22, -0.66, 2.05)], 0.04, 0.2, 10); setmat(t, mat("tooth", (1, 0.97, 0.85), 0.3)); H.append(t)
        hn = tube([(sx * 0.3, -0.1, 3.02), (sx * 0.5, -0.1, 3.18), (sx * 0.52, -0.16, 3.42)], 0.05, 0.1, 12); setmat(hn, bd); H.append(hn)
    tag(H, "head"); P += H
    return group("bone_colossus", P)


# ------------------------------------------------------------------ Titã da Ruína (altura ~3.2)

def ruin_titan():
    P = []
    st = mat("ruinstone", STONE, 0.9, bump=0.5, bump_scale=14)
    std = mat("ruinstone_d", STONE_D, 0.9, bump=0.5, bump_scale=14)
    moss = mat("ruinmoss", MOSS, 0.95, bump=0.6, bump_scale=30)
    lava = _glow("ruinlava", LAVA, 6.0)
    # pernas: colunas quebradas sobre blocos
    for sx in (-1, 1):
        L = []
        col = cyl((sx * 0.36, 0.0, 0.7), 0.24, 1.4, seg=14, bevel=0.02, r2=0.2); hard(col); setmat(col, st); L.append(col)
        for z in (0.35, 0.95):
            ring = cyl((sx * 0.36, 0.0, z), 0.27, 0.07, seg=14, bevel=0.015); hard(ring); setmat(ring, std); L.append(ring)
        foot = box((sx * 0.38, -0.1, 0.1), (0.62, 0.8, 0.22), (0, 0, sx * -6), bevel=0.05); hard(foot); setmat(foot, std); L.append(foot)
        cr = box((sx * 0.36, -0.2, 0.9), (0.04, 0.03, 0.6), (0, 0, sx * 12), bevel=0.0); setmat(cr, lava); L.append(cr)
        tag(L, "leg_l" if sx > 0 else "leg_r"); P += L
    # tronco: blocos empilhados com argamassa de musgo, núcleo de brasa, arco quebrado nas costas
    B = []
    belly = box((0, 0.02, 1.55), (1.0, 0.76, 0.7), bevel=0.08, seg=2); hard(belly); setmat(belly, std); B.append(belly)
    chest = box((0, 0, 2.2), (1.5, 0.95, 0.9), (0, 0, 3), bevel=0.09, seg=2, taper=(1.1, 1.0)); hard(chest); setmat(chest, st); B.append(chest)
    for (x, z, w, h_) in ((-0.5, 2.0, 0.5, 0.35), (0.45, 2.45, 0.55, 0.3), (0.0, 1.9, 0.4, 0.3)):
        blk = box((x, -0.48, z), (w, 0.1, h_), (0, 0, 4), bevel=0.03); hard(blk); setmat(blk, std); B.append(blk)
    core = sph((0, -0.5, 2.15), 1, (0.2, 0.06, 0.22)); setmat(core, lava); B.append(core)
    for (x, z, ln, a) in ((0.2, 2.15, 0.7, 30), (-0.25, 2.1, 0.6, -40), (0.0, 1.5, 0.5, 5)):
        c = box((x, -0.5, z), (0.035, 0.03, ln), (0, a, 0), bevel=0.0); setmat(c, lava); B.append(c)
    arch = torus((0, 0.4, 2.55), 0.7, 0.12, (90, 0, 0), s=(1, 1, 1)); shade(arch); setmat(arch, std); B.append(arch)
    mo = fuse([sph((x, y, z), 1, (0.35, 0.25, 0.1)) for (x, y, z) in ((-0.5, -0.1, 2.68), (0.4, 0.0, 2.7), (0.0, -0.3, 1.9))], "moss", 0.03, 0.6, 3); setmat(mo, moss); B.append(mo)
    tag(B, "body"); P += B
    # braços: colunas enormes terminando em blocos-punho
    for sx in (-1, 1):
        A = []
        shd = sph((sx * 0.95, 0.0, 2.45), 1, (0.4, 0.38, 0.32)); setmat(shd, std); A.append(shd)
        up = cyl((sx * 1.1, -0.05, 1.8), 0.22, 1.1, (0, sx * 8, 0), seg=14, bevel=0.02, r2=0.2); hard(up); setmat(up, st); A.append(up)
        rg = cyl((sx * 1.12, -0.06, 1.6), 0.25, 0.08, (0, sx * 8, 0), seg=14, bevel=0.015); hard(rg); setmat(rg, std); A.append(rg)
        fist = box((sx * 1.2, -0.1, 0.95), (0.62, 0.6, 0.55), (0, 0, sx * 8), bevel=0.09, seg=2); hard(fist); setmat(fist, std); A.append(fist)
        for k in (-1, 0, 1):
            kn = box((sx * 1.2 + k * 0.17, -0.42, 0.98), (0.14, 0.1, 0.2), bevel=0.03); hard(kn); setmat(kn, st); A.append(kn)
        tag(A, "arm_l" if sx > 0 else "arm_r"); P += A
    # cabeça: bloco com cara esculpida, olhos de brasa, coroa de pedra quebrada e musgo
    H = []
    hd = box((0, -0.12, 3.0), (0.62, 0.55, 0.5), bevel=0.07, taper=(0.9, 0.95)); hard(hd); setmat(hd, st); H.append(hd)
    brow = box((0, -0.4, 3.1), (0.6, 0.12, 0.1), bevel=0.02); hard(brow); setmat(brow, std); H.append(brow)
    for sx in (-1, 1):
        e = sph((sx * 0.15, -0.4, 3.0), 1, (0.08, 0.04, 0.05)); setmat(e, lava); H.append(e)
    mouth = box((0, -0.4, 2.82), (0.32, 0.05, 0.05), bevel=0.01); setmat(mouth, mat("shadow", (0.03, 0.02, 0.03), 0.9)); H.append(mouth)
    for k, (x, h_, a) in enumerate(((-0.22, 0.28, -12), (0.0, 0.4, 3), (0.22, 0.24, 14))):
        sp = box((x, -0.1, 3.3 + h_ * 0.4), (0.14, 0.14, h_), (0, a, 0), bevel=0.02, taper=(0.5, 0.5)); hard(sp); setmat(sp, std); H.append(sp)
    mo = fuse([sph((0.1, 0.0, 3.27), 1, (0.3, 0.25, 0.08))], "moss", 0.02); setmat(mo, moss); H.append(mo)
    tag(H, "head"); P += H
    return group("ruin_titan", P)


# ------------------------------------------------------------------ Lich (retrato; altura ~2.4)

def lich():
    P = []
    robe = mat("lichrobe", (0.2, 0.1, 0.34), 0.85, bump=0.15, bump_scale=70)
    robe_d = mat("lichrobe_d", (0.1, 0.05, 0.2), 0.9)
    gold = mat("gold", (1.0, 0.72, 0.28), 0.28, 1.0)
    bm = _bone_mat()
    glow = _glow("lichglow", PUR)
    body = fuse([sph((0, 0.02, 0.62), 1, (0.5, 0.42, 0.62)), sph((0, 0.0, 1.3), 1, (0.4, 0.3, 0.4)), sph((0, 0.04, 0.12), 1, (0.58, 0.5, 0.16))], "lichbody", 0.02, 0.6, 5)
    setmat(body, robe); P.append(body)
    hem = torus((0, 0.04, 0.08), 0.57, 0.04, s=(1, 0.9, 1)); shade(hem); setmat(hem, gold); P.append(hem)
    # caixa torácica à mostra no peito aberto, com chama de alma
    for k in range(3):
        rib = torus((0, -0.26, 1.35 - k * 0.12), 0.2 - k * 0.025, 0.025, (90, 0, 0), s=(1, 1, 0.55)); shade(rib); setmat(rib, bm); P.append(rib)
    sl = sph((0, -0.32, 1.28), 1, (0.09, 0.05, 0.12)); setmat(sl, glow); P.append(sl)
    # capa de colarinho alto e manto
    for sx in (-1, 1):
        col = box((sx * 0.3, 0.0, 1.62), (0.34, 0.07, 0.4), (15, sx * -22, sx * -10), bevel=0.03, taper=(1.0, 1.0)); hard(col); setmat(col, robe_d); P.append(col)
        sh = sph((sx * 0.48, 0.0, 1.5), 1, (0.2, 0.2, 0.16)); setmat(sh, robe_d); P.append(sh)
    # braços: mangas largas, mãos de osso; uma segura o cajado, a outra ergue uma chama
    A = capsule((0.48, 0.0, 1.45), (0.62, -0.22, 1.05), 0.12, 0.17)
    for o in A: setmat(o, robe)
    P += A
    hnd = fuse([sph((0.64, -0.3, 0.98), 0.07)] + [sph((0.64 + k * 0.045, -0.38, 0.93), 0.03, (1, 2.2, 1)) for k in (-1, 0, 1)], "hand", 0.008); setmat(hnd, bm); P.append(hnd)
    staff = tube([(0.66, -0.3, -0.05), (0.67, -0.3, 1.0), (0.66, -0.3, 2.0)], 0.04, 1.0, 12); setmat(staff, mat("woodd", (0.25, 0.17, 0.12), 0.8, bump=0.4, bump_scale=14)); P.append(staff)
    for k in range(3):
        a = k * 2.1
        pr = tube([(0.66, -0.3, 1.95), (0.66 + math.cos(a) * 0.1, -0.3 + math.sin(a) * 0.1, 2.1), (0.66 + math.cos(a) * 0.07, -0.3 + math.sin(a) * 0.07, 2.28)], 0.02, 0.4, 10); setmat(pr, mat("woodd", (0.25, 0.17, 0.12), 0.8)); P.append(pr)
    orb = sph((0.66, -0.3, 2.16), 0.11); setmat(orb, glow); P.append(orb)
    A2 = capsule((-0.48, 0.0, 1.45), (-0.64, -0.26, 1.12), 0.12, 0.17)
    for o in A2: setmat(o, robe)
    P += A2
    h2 = fuse([sph((-0.66, -0.34, 1.12), 0.07)] + [sph((-0.66 + k * 0.045, -0.42, 1.15), 0.03, (1, 2.2, 1)) for k in (-1, 0, 1)], "hand", 0.008); setmat(h2, bm); P.append(h2)
    fl = sph((-0.66, -0.42, 1.38), 1, (0.14, 0.14, 0.2)); setmat(fl, _glow("lichflame", GRN)); P.append(fl)
    ft = sph((-0.66, -0.42, 1.58), 1, (0.07, 0.07, 0.12)); setmat(ft, _glow("lichflame", GRN)); P.append(ft)
    # crânio coroado
    P += _skull([], (0, -0.04, 1.95), 1.0, "head", PUR)
    cr = cyl((0, -0.02, 2.2), 0.27, 0.12, seg=24, bevel=0.01, r2=0.3); hard(cr); setmat(cr, gold); P.append(cr)
    for k in range(7):
        a = k / 7 * math.tau
        sp = box((math.cos(a) * 0.29, -0.02 + math.sin(a) * 0.29, 2.34), (0.07, 0.07, 0.2), bevel=0.01, taper=(0.1, 0.1)); hard(sp); setmat(sp, gold); P.append(sp)
        if k % 2 == 0:
            g = sph((math.cos(a) * 0.3, -0.02 + math.sin(a) * 0.3, 2.2), 0.035); setmat(g, glow); P.append(g)
    # orbes arcanos e páginas flutuando
    for (x, z, r) in ((-1.0, 1.9, 0.08), (1.25, 1.2, 0.06), (-1.15, 0.7, 0.05)):
        o = sph((x, -0.1, z), r); setmat(o, glow); P.append(o)
    for (x, z, a) in ((-0.95, 1.4, 20), (1.1, 1.85, -15), (-1.2, 0.2, 35)):
        pg = box((x, -0.1, z), (0.22, 0.015, 0.3), (10, a, 20), bevel=0.004); hard(pg); setmat(pg, mat("page", (0.92, 0.86, 0.68), 0.8)); P.append(pg)
    return group("lich", P)
