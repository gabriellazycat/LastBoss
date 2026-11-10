"""O chefe (Lorde Sombrio) na linguagem dos monstros, em 4 partes destrutíveis com a MESMA origem e tamanho das
antigas (game/art/models.gd boss_part; posições em world_view.gd PART_OFFSETS, data/boss_lorde.json).
Coordenadas: Godot (gx, gy, gz) = Blender (-bx, bz, by); frente = -Y no Blender (-Z na Godot).
Exportadas sem recentralizar e sem mudar a escala (vat.export recenter=False, height=None)."""
import math
import bpy
from mathutils import Vector
from mk import *
from monsters import glow_eye
from chars import BLACK, WHITE, GOLD

ROBE = (0.24, 0.08, 0.34)
ROBE_D = (0.1, 0.03, 0.16)
ROBE_L = (0.38, 0.15, 0.5)
SKIN = (0.62, 0.56, 0.7)
SKIN_D = (0.36, 0.3, 0.44)
DARK = (0.08, 0.06, 0.1)
BONE = (0.93, 0.89, 0.76)
GLOW = (0.85, 0.25, 1.0)


def _gold():
    return mat("gold", GOLD, 0.28, 1.0)


def boss_core():
    """Manto em sino com bordado de ouro, cinto de crânios, gema no peito e ombreiras com espinhos (0 a ~3,9 m)."""
    P = []
    robe = fuse([sph((0, 0, 0.55), 1, (1.75, 1.6, 1.0)), sph((0, 0, 2.0), 1, (1.1, 0.95, 1.0)), sph((0, 0, 3.0), 1, (1.05, 0.7, 0.55))], "robe", 0.03, 0.6, 6)
    cut = box((0, 0, -0.5), (5, 5, 1.0), bevel=0)
    m = robe.modifiers.new("c", 'BOOLEAN'); m.object = cut; m.operation = 'DIFFERENCE'; m.solver = 'EXACT'; apply_mods(robe); bpy.data.objects.remove(cut)

    def col(p, n):
        c = mix(ROBE_D, ROBE, smoothstep(0.0, 2.6, p.z) * 0.6 + smoothstep(-0.3, 0.9, n.z) * 0.3)
        return mix(c, ROBE_L, ell_w(p, (0, -1.1, 1.3), (0.35, 0.6, 1.2)) * 0.6)   # faixa da frente
    paint(robe, col); setmat(robe, mat("robev", vcol=True, rough=0.8, bump=0.1, bump_scale=60)); P.append(robe)
    hem = torus((0, 0, 0.07), 1.47, 0.08, s=(1, 0.915, 1)); shade(hem); setmat(hem, _gold()); P.append(hem)
    belt = torus((0, 0, 1.75), 1.12, 0.09, s=(1, 0.86, 1)); shade(belt); setmat(belt, mat("leather", (0.2, 0.12, 0.08), 0.6)); P.append(belt)
    for k in range(5):   # crânios no cinto
        a = -math.pi / 2 + (k - 2) * 0.32
        x, y = math.cos(a) * 1.15, math.sin(a) * 0.98
        sk = fuse([sph((x, y, 1.78), 1, (0.17, 0.15, 0.16)), sph((x * 1.02, y * 1.02 - 0.03, 1.66), 1, (0.11, 0.1, 0.06))], "skull", 0.012)
        setmat(sk, mat("bone", BONE, 0.6)); P.append(sk)
        for sx in (-1, 1):
            e = sph((x + sx * 0.06, y - 0.14, 1.8), 0.035); setmat(e, mat("socket", DARK, 0.6)); P.append(e)
    # peitoral e gema
    plate = box((0, -0.62, 2.95), (1.4, 0.3, 0.8), (-8, 0, 0), bevel=0.08, seg=2, taper=(1.1, 1.0)); hard(plate); setmat(plate, mat("darkmetal", (0.18, 0.15, 0.22), 0.45, 0.8)); P.append(plate)
    ring = torus((0, -0.78, 2.65), 0.42, 0.06, (90, 0, 0)); shade(ring); setmat(ring, _gold()); P.append(ring)
    gem = sph((0, -0.78, 2.65), 1, (0.36, 0.2, 0.36)); setmat(gem, mat("gemp", GLOW, 0.15, emit=6.0)); P.append(gem)
    # ombreiras com espinhos de osso (silhueta larga vista de cima)
    for sx in (-1, 1):
        pad = fuse([sph((sx * 1.15, 0, 3.45), 1, (0.6, 0.55, 0.35))], "pad", 0.02); setmat(pad, mat("darkmetal", (0.18, 0.15, 0.22), 0.45, 0.8)); P.append(pad)
        trim = torus((sx * 1.15, 0, 3.3), 0.55, 0.04, s=(1, 0.95, 1)); shade(trim); setmat(trim, _gold()); P.append(trim)
        for i in range(3):
            sp = box((sx * (0.9 + i * 0.28), -0.05 + i * 0.08, 3.85), (0.16, 0.16, 0.6), (0, sx * 25, 0), bevel=0.02, taper=(0.1, 0.1)); hard(sp); setmat(sp, mat("bone", BONE, 0.6)); P.append(sp)
    collar = fuse([sph((0, 0.25, 3.6), 1, (0.75, 0.25, 0.5), (15, 0, 0))], "collar", 0.02); setmat(collar, mat("robe_l", ROBE_L, 0.8)); P.append(collar)
    return group("boss_core", P)


def boss_head():
    """Cabeça grande centrada na origem (±0,6 m): olhos acesos, sobrancelha pesada, chifres e coroa de ouro."""
    P = []
    head = fuse([sph((0, 0, 0), 1, (0.62, 0.58, 0.6)), sph((0, -0.22, -0.32), 1, (0.42, 0.32, 0.25))], "head", 0.012)
    paint(head, lambda p, n: mix(SKIN_D, SKIN, smoothstep(-0.6, 0.6, n.z) * 0.5 + 0.35)); setmat(head, mat("skinv", vcol=True, rough=0.55, sss=0.2)); P.append(head)
    for sx in (-1, 1):
        P += glow_eye((sx * 0.22, -0.52, 0.05), 0.15, (1.0, 0.35, 0.12))
        brow = box((sx * 0.22, -0.6, 0.22), (0.3, 0.1, 0.08), (0, sx * -22, 0), bevel=0.03); hard(brow); setmat(brow, mat("dark", DARK, 0.6)); P.append(brow)
        horn = tube([(sx * 0.45, 0.0, 0.35), (sx * 0.8, 0.05, 0.6), (sx * 0.85, -0.1, 1.05), (sx * 0.7, -0.2, 1.3)], 0.13, 0.12, 20)
        paint(horn, lambda p, n: mix((0.12, 0.1, 0.12), (0.5, 0.45, 0.42), smoothstep(0.4, 1.2, p.z))); setmat(horn, mat("hornv", vcol=True, rough=0.5)); P.append(horn)
        ear = sph((sx * 0.6, 0.0, 0.0), 1, (0.08, 0.06, 0.2), (0, sx * 30, 0)); shade(ear); setmat(ear, mat("skin", SKIN, 0.55)); P.append(ear)
    grin = tube([(-0.25, -0.5, -0.35), (0, -0.56, -0.42), (0.25, -0.5, -0.35)], 0.04, 1.0, 12); setmat(grin, mat("mouth", (0.15, 0.03, 0.08), 0.5)); P.append(grin)
    for k in range(5):
        t = box((-0.16 + k * 0.08, -0.56, -0.4), (0.06, 0.03, 0.1), (180 if k % 2 else 0, 0, 0), bevel=0.008, taper=(0.15, 0.5)); hard(t); setmat(t, mat("tooth", (1, 0.97, 0.88), 0.3)); P.append(t)
    crown = cyl((0, 0, 0.55), 0.52, 0.28, seg=12, bevel=0.03, r2=0.47); hard(crown); setmat(crown, _gold()); P.append(crown)
    for i in range(6):
        a = i / 6 * math.tau
        sp = box((math.cos(a) * 0.46, math.sin(a) * 0.46, 0.82), (0.12, 0.1, 0.3), (0, 0, math.degrees(a) + 90), bevel=0.01, taper=(0.1, 0.5)); hard(sp); setmat(sp, _gold()); P.append(sp)
        g = sph((math.cos(a) * 0.5, math.sin(a) * 0.5, 0.55), 0.055); setmat(g, mat("gemp", GLOW, 0.15, emit=6.0)); P.append(g)
    return group("boss_head", P)


def _arm(sx, P):
    """Braço pendurado do ombro (z = +0,9) até a mão (z ~ -1,1)."""
    sh = fuse([sph((0, 0, 0.9), 1, (0.48, 0.46, 0.42))], "shoulder", 0.015); setmat(sh, mat("darkmetal", (0.18, 0.15, 0.22), 0.45, 0.8)); P.append(sh)
    tr_ = torus((0, 0, 0.72), 0.42, 0.04); shade(tr_); setmat(tr_, _gold()); P.append(tr_)
    sleeve = fuse(capsule((0, 0, 0.6), (sx * 0.15, -0.08, -0.55), 0.28, 0.42), "sleeve", 0.015)
    paint(sleeve, lambda p, n: mix(ROBE_D, ROBE, smoothstep(-0.6, 0.6, p.z) * 0.5 + 0.3)); setmat(sleeve, mat("robev", vcol=True, rough=0.8)); P.append(sleeve)
    cuff = torus((sx * 0.16, -0.08, -0.72), 0.4, 0.05, (8, 0, 0)); shade(cuff); setmat(cuff, _gold()); P.append(cuff)
    hand = fuse([sph((sx * 0.2, -0.15, -0.98), 1, (0.22, 0.2, 0.24))], "hand", 0.012); paint(hand, lambda p, n: SKIN); setmat(hand, mat("skinv", vcol=True, rough=0.55, sss=0.2)); P.append(hand)


def boss_left_arm():
    """Braço esquerdo (x = -1,6 na Godot = +x no Blender): mão com o orbe azul."""
    P = []
    _arm(-1, P)
    orb = sph((-0.25, -0.35, -1.35), 0.4); setmat(orb, mat("orb", (0.3, 0.6, 1.0), 0.1, emit=5.0)); P.append(orb)
    for k in range(3):
        a = k / 3 * math.tau
        f = tube([(-0.2, -0.15, -1.05), (-0.25 + math.cos(a) * 0.32, -0.35 + math.sin(a) * 0.32, -1.25), (-0.25 + math.cos(a) * 0.25, -0.35 + math.sin(a) * 0.25, -1.55)], 0.05, 0.4, 10)
        paint(f, lambda p, n: SKIN_D); setmat(f, mat("skinv", vcol=True, rough=0.55)); P.append(f)
    return group("boss_left_arm", P)


def boss_right_arm():
    """Braço direito (x = +1,6 na Godot = -x no Blender): garras em brasa."""
    P = []
    _arm(1, P)
    for i in range(3):
        x = 0.35 - i * 0.18
        cl = tube([(x * 0.6, -0.15, -1.1), (x, -0.32, -1.3), (x * 1.1, -0.2, -1.6)], 0.06, 0.15, 12)
        paint(cl, lambda p, n: mix((1.0, 0.75, 0.3), (1.0, 0.3, 0.12), smoothstep(-1.2, -1.6, p.z))); setmat(cl, mat("clawv", vcol=True, rough=0.4, emit=5.0)); P.append(cl)
    return group("boss_right_arm", P)
