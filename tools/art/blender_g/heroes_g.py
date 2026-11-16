"""Heróis da rodada "miniaturas pintadas": Escudeiro e Mago. Volumes grandes e simples, sem rosto (humanos nas cartas
não têm olhos: o rosto fica na sombra do elmo / capuz), 1,75 m, ossos rígidos (body, head, arm_l, arm_r, leg_l, leg_r).
Blender: Z para cima, frente = -Y; o lado +x é a esquerda do herói (escudo)."""
import math
from mk import *
from vat import tag
from anims import biped, ss

STEEL = (0.50, 0.57, 0.70)
STEEL_D = (0.30, 0.35, 0.47)
RED = (0.70, 0.17, 0.19)
GOLD = (0.95, 0.72, 0.30)
LEATHER = (0.36, 0.22, 0.14)
DARK = (0.07, 0.06, 0.09)
ROBE = (0.30, 0.34, 0.62)
ROBE_D = (0.20, 0.22, 0.45)
CREAM = (0.92, 0.86, 0.72)
ORB = (0.55, 0.85, 1.0)
WOOD = (0.42, 0.27, 0.15)


def _m(o, color, rough=0.6, metal=0.0, emit=0.0):
    setmat(o, mat("g_%s" % "".join("%02x" % int(c * 255) for c in color), color, rough, metal, emit=emit))
    return o


def escudeiro():
    P = []
    # pernas e botas
    for sx, b in ((1, "leg_l"), (-1, "leg_r")):
        L = capsule((sx * 0.12, 0, 0.82), (sx * 0.12, 0, 0.14), 0.115, 0.1, seg=16)
        for o in L:
            shade(o); _m(o, STEEL_D, 0.55)
        boot = box((sx * 0.12, -0.05, 0.07), (0.2, 0.34, 0.15), bevel=0.04); hard(boot); _m(boot, LEATHER, 0.8)
        P += tag(L + [boot], b)
    # tronco: peitoral de aço com tabardo vermelho
    torso = box((0, 0, 1.12), (0.58, 0.36, 0.62), bevel=0.09, taper=(0.82, 0.9)); hard(torso); _m(torso, STEEL, 0.5, 0.2)
    tab = box((0, -0.19, 0.98), (0.34, 0.06, 0.62), bevel=0.03); hard(tab); _m(tab, RED, 0.8)
    belt = box((0, 0, 0.82), (0.6, 0.38, 0.1), bevel=0.03); hard(belt); _m(belt, LEATHER, 0.8)
    cape = box((0, 0.24, 1.05), (0.5, 0.07, 0.8), bevel=0.03); hard(cape); _m(cape, RED, 0.85)
    P += tag([torso, tab, belt, cape], "body")
    # cabeça: elmo liso com fresta escura (sem olhos) e crista
    helm = sph((0, 0, 1.6), 0.22, (1, 1, 1.08), seg=20); shade(helm); _m(helm, STEEL, 0.4, 0.3)
    slit = box((0, -0.19, 1.6), (0.3, 0.06, 0.07), bevel=0.012); hard(slit); _m(slit, DARK, 0.9)
    crest = box((0, 0, 1.83), (0.06, 0.3, 0.1), bevel=0.02); hard(crest); _m(crest, RED, 0.8)
    neck = cyl((0, 0, 1.42), 0.1, 0.12, seg=16); shade(neck); _m(neck, STEEL_D, 0.6)
    P += tag([helm, slit, crest, neck], "head")
    # braço esquerdo (+x) com o escudo redondo; direito (-x) com a espada
    A = capsule((0.36, 0, 1.38), (0.38, -0.12, 0.98), 0.1, 0.085, seg=16)
    pad = sph((0.36, 0, 1.4), 0.15, (1, 1, 0.9), seg=16); shade(pad); _m(pad, STEEL, 0.45, 0.3)
    for o in A:
        shade(o); _m(o, STEEL_D, 0.55)
    shield = cyl((0.5, -0.2, 1.05), 0.3, 0.06, rot=(0, 90, 0), seg=24, bevel=0.02); hard(shield); _m(shield, STEEL, 0.5, 0.25)
    boss = sph((0.54, -0.2, 1.05), 0.08, (0.6, 1, 1), seg=12); shade(boss); _m(boss, GOLD, 0.4, 0.4)
    stripe = box((0.535, -0.2, 1.05), (0.025, 0.58, 0.1), bevel=0.01); hard(stripe); _m(stripe, RED, 0.7)
    P += tag(A + [pad, shield, boss, stripe], "arm_l")
    B = capsule((-0.36, 0, 1.38), (-0.38, -0.12, 0.98), 0.1, 0.085, seg=16)
    pad2 = sph((-0.36, 0, 1.4), 0.15, (1, 1, 0.9), seg=16); shade(pad2); _m(pad2, STEEL, 0.45, 0.3)
    for o in B:
        shade(o); _m(o, STEEL_D, 0.55)
    blade = box((-0.4, -0.38, 1.0), (0.09, 0.6, 0.04), bevel=0.012); hard(blade); _m(blade, (0.86, 0.88, 0.92), 0.3, 0.5)
    guard = box((-0.4, -0.12, 1.0), (0.26, 0.06, 0.06), bevel=0.015); hard(guard); _m(guard, GOLD, 0.4, 0.4)
    P += tag(B + [pad2, blade, guard], "arm_r")
    return group("escudeiro", P)


def mago():
    P = []
    for sx, b in ((1, "leg_l"), (-1, "leg_r")):
        boot = box((sx * 0.11, -0.06, 0.07), (0.18, 0.3, 0.14), bevel=0.04); hard(boot); _m(boot, LEATHER, 0.8)
        P += tag([boot], b)
    # túnica: sino largo até o chão, com faixa e gola
    robe = cyl((0, 0, 0.62), 0.34, 1.1, r2=0.2, seg=24, bevel=0.02); shade(robe); _m(robe, ROBE, 0.8)
    hem = cyl((0, 0, 0.1), 0.36, 0.1, seg=24, bevel=0.01); shade(hem); _m(hem, GOLD, 0.5, 0.3)
    sash = cyl((0, 0, 0.88), 0.215, 0.1, seg=20, bevel=0.01); shade(sash); _m(sash, RED, 0.8)
    chest = sph((0, 0, 1.22), 0.27, (1, 0.8, 0.9), seg=20); shade(chest); _m(chest, ROBE, 0.8)
    collar = cyl((0, 0, 1.42), 0.17, 0.1, seg=20, bevel=0.01); shade(collar); _m(collar, CREAM, 0.8)
    P += tag([robe, hem, sash, chest, collar], "body")
    # cabeça: capuz fundo com rosto na sombra (sem olhos) e chapéu de ponta
    hood = sph((0, 0, 1.58), 0.22, (1, 1, 1.05), seg=20); shade(hood); _m(hood, ROBE_D, 0.8)
    face = sph((0, -0.13, 1.56), 0.15, (0.9, 0.6, 1), seg=16); shade(face); _m(face, DARK, 0.9)
    hat = cyl((0, 0, 1.92), 0.2, 0.48, r2=0.0, seg=20, bevel=0.0); shade(hat); _m(hat, ROBE, 0.8)
    brim = cyl((0, 0, 1.72), 0.34, 0.04, seg=24, bevel=0.01); shade(brim); _m(brim, ROBE_D, 0.8)
    band = cyl((0, 0, 1.76), 0.235, 0.07, seg=20, bevel=0.0); shade(band); _m(band, GOLD, 0.5)
    P += tag([hood, face, hat, brim, band], "head")
    # braços de manga larga; o direito (-x) leva o cajado com a esfera acesa
    A = capsule((0.3, 0, 1.36), (0.34, -0.12, 0.98), 0.1, 0.12, seg=16)
    for o in A:
        shade(o); _m(o, ROBE, 0.8)
    P += tag(A, "arm_l")
    B = capsule((-0.3, 0, 1.36), (-0.34, -0.12, 0.98), 0.1, 0.12, seg=16)
    for o in B:
        shade(o); _m(o, ROBE, 0.8)
    staff = cyl((-0.38, -0.15, 1.0), 0.035, 1.75, rot=(0, 0, 0), seg=10, bevel=0.0); shade(staff); _m(staff, WOOD, 0.8)
    orb = sph((-0.38, -0.15, 1.95), 0.12, seg=14); shade(orb); _m(orb, ORB, 0.3, emit=5.0)
    claw = torus((-0.38, -0.15, 1.9), 0.13, 0.025, rot=(90, 0, 0)); shade(claw); _m(claw, GOLD, 0.4, 0.4)
    P += tag(B + [staff, orb, claw], "arm_r")
    return group("mago", P)


def arqueira():
    GREEN = (0.28, 0.40, 0.26)
    GREEN_D = (0.18, 0.27, 0.19)
    P = []
    for sx, b in ((1, "leg_l"), (-1, "leg_r")):
        L = capsule((sx * 0.1, 0, 0.8), (sx * 0.1, 0, 0.14), 0.1, 0.085, seg=16)
        for o in L:
            shade(o); _m(o, GREEN_D, 0.8)
        boot = box((sx * 0.1, -0.05, 0.07), (0.17, 0.3, 0.14), bevel=0.04); hard(boot); _m(boot, LEATHER, 0.8)
        P += tag(L + [boot], b)
    torso = box((0, 0, 1.1), (0.44, 0.3, 0.58), bevel=0.09, taper=(0.8, 0.9)); hard(torso); _m(torso, GREEN, 0.8)
    belt = box((0, 0, 0.82), (0.46, 0.32, 0.08), bevel=0.03); hard(belt); _m(belt, LEATHER, 0.8)
    cloak = cyl((0, 0.06, 0.95), 0.3, 0.9, r2=0.2, seg=20, bevel=0.0); shade(cloak); _m(cloak, GREEN_D, 0.85)
    quiver = cyl((0.1, 0.2, 1.3), 0.07, 0.5, rot=(15, 0, 10), seg=12, bevel=0.0); shade(quiver); _m(quiver, LEATHER, 0.8)
    P += tag([torso, belt, cloak, quiver], "body")
    hood = sph((0, 0, 1.58), 0.22, (1, 1.05, 1.05), seg=20); shade(hood); _m(hood, GREEN, 0.8)
    face = sph((0, -0.14, 1.55), 0.14, (0.9, 0.6, 1), seg=16); shade(face); _m(face, DARK, 0.9)
    tip = cyl((0, 0.18, 1.7), 0.1, 0.2, r2=0.0, rot=(-70, 0, 0), seg=12, bevel=0.0); shade(tip); _m(tip, GREEN, 0.8)
    P += tag([hood, face, tip], "head")
    A = capsule((0.3, 0, 1.34), (0.33, -0.14, 1.05), 0.085, 0.075, seg=16)
    for o in A:
        shade(o); _m(o, GREEN, 0.8)
    bow = torus((0.4, -0.2, 1.1), 0.42, 0.025, rot=(0, 90, 0)); shade(bow); _m(bow, WOOD, 0.7)
    P += tag(A + [bow], "arm_l")
    B = capsule((-0.3, 0, 1.34), (-0.33, -0.14, 1.05), 0.085, 0.075, seg=16)
    for o in B:
        shade(o); _m(o, GREEN, 0.8)
    P += tag(B, "arm_r")
    return group("arqueira", P)


def cleriga():
    WHITE = (0.93, 0.9, 0.82)
    P = []
    for sx, b in ((1, "leg_l"), (-1, "leg_r")):
        boot = box((sx * 0.11, -0.06, 0.07), (0.17, 0.3, 0.14), bevel=0.04); hard(boot); _m(boot, LEATHER, 0.8)
        P += tag([boot], b)
    robe = cyl((0, 0, 0.62), 0.34, 1.1, r2=0.2, seg=24, bevel=0.02); shade(robe); _m(robe, WHITE, 0.8)
    hem = cyl((0, 0, 0.1), 0.36, 0.1, seg=24, bevel=0.01); shade(hem); _m(hem, GOLD, 0.5, 0.3)
    sash = cyl((0, 0, 0.88), 0.215, 0.1, seg=20, bevel=0.01); shade(sash); _m(sash, GOLD, 0.5, 0.3)
    chest = sph((0, 0, 1.22), 0.27, (1, 0.8, 0.9), seg=20); shade(chest); _m(chest, WHITE, 0.8)
    stole = box((0, -0.2, 1.0), (0.16, 0.05, 0.8), bevel=0.02); hard(stole); _m(stole, RED, 0.8)
    P += tag([robe, hem, sash, chest, stole], "body")
    hood = sph((0, 0, 1.58), 0.22, (1, 1, 1.05), seg=20); shade(hood); _m(hood, WHITE, 0.8)
    face = sph((0, -0.13, 1.56), 0.15, (0.9, 0.6, 1), seg=16); shade(face); _m(face, DARK, 0.9)
    halo = torus((0, 0.02, 1.86), 0.22, 0.03); shade(halo); _m(halo, GOLD, 0.3, emit=3.0)
    P += tag([hood, face, halo], "head")
    A = capsule((0.3, 0, 1.36), (0.34, -0.12, 0.98), 0.1, 0.12, seg=16)
    for o in A:
        shade(o); _m(o, WHITE, 0.8)
    P += tag(A, "arm_l")
    B = capsule((-0.3, 0, 1.36), (-0.34, -0.12, 0.98), 0.1, 0.12, seg=16)
    for o in B:
        shade(o); _m(o, WHITE, 0.8)
    shaft = cyl((-0.38, -0.15, 1.0), 0.035, 1.5, seg=10, bevel=0.0); shade(shaft); _m(shaft, WOOD, 0.8)
    top = sph((-0.38, -0.15, 1.78), 0.12, seg=14); shade(top); _m(top, GOLD, 0.35, 0.4)
    P += tag(B + [shaft, top], "arm_r")
    return group("cleriga", P)


BUILD = {"escudeiro": escudeiro, "mago": mago, "arqueira": arqueira, "cleriga": cleriga}


def cfg(i):
    """Animação: o mesmo andar e golpe dos bípedes do v2 (ossos rígidos)."""
    if i == "escudeiro":
        return {"anim": biped(1.75, (0.12, 0.0, 0.82), (0.36, 0.0, 1.38), (0, 0, 1.5), stride=30, swing=24, atk="thrust", atk_arm="arm_r")}
    if i == "arqueira":
        return {"anim": biped(1.75, (0.1, 0.0, 0.8), (0.3, 0.0, 1.34), (0, 0, 1.5), stride=32, swing=20, atk="cast", atk_arm="arm_r", bob=0.03)}
    return {"anim": biped(1.75, (0.11, 0.0, 0.8), (0.3, 0.0, 1.36), (0, 0, 1.5), stride=20, swing=16, atk="cast", atk_arm="arm_r", bob=0.02)}
