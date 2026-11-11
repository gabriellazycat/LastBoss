"""Cenas das cartas da Rainha da Praga (lote 10/11/2026): mesmo método de scenes.py (kit de blender_v2, contorno + hachura),
cada carta com a sua cena. rat_burrow e plague_queen ficam em scenes.py (amostras aprovadas, copiadas à parte).
Uso: CARD_SCENES=scenes_plague CARD_SCENES_VAR=SCENES_PLAGUE blender -b --factory-startup -P render_cards.py -- <saída> [ids]"""
import math
import bpy, bmesh
from mathutils import Matrix, Vector
from mk import *
import chars, monsters, monsters2, chars2
import creatures_plague as cp
from scenes import place, flame, DIRT, DIRT_D, STONE, BONE

GREEN = (0.5, 0.72, 0.22)
GREEN_D = (0.22, 0.4, 0.14)
GLOW_G = (0.55, 1.0, 0.3)
SHADOW = (0.03, 0.02, 0.03)
WOOD_C = (0.45, 0.27, 0.13)
CHEESE = (0.98, 0.78, 0.22)


# ------------------------------------------------------------------ peças comuns

_RAT_CACHE = {}


def _alive(o):
    try:
        return o.name in bpy.data.objects
    except ReferenceError:
        return False


def _rat_copy(g):
    """Cópia de um rato já modelado (malhas e materiais compartilhados): modelar cada rato é o que custa."""
    n = g.copy(); bpy.context.scene.collection.objects.link(n)
    n.location = (0, 0, 0); n.rotation_euler = (0, 0, 0); n.scale = (1, 1, 1)
    for ch in g.children:
        c = ch.copy(); bpy.context.scene.collection.objects.link(c)
        c.parent = n; c.matrix_parent_inverse = ch.matrix_parent_inverse.copy()
    return n


def R(loc=(0, 0, 0), rz=0.0, s=0.6, rx=0.0, fur=None, eyes=None, sc=None):
    """Um rato (chars.rat) na posição/escala dadas; fur = (pelo, pelo escuro, barriga); eyes = cor de brilho (raiva)."""
    key = (fur, eyes)
    try:
        g = _rat_copy(_RAT_CACHE[key])
    except (KeyError, ReferenceError):
        if _RAT_CACHE and any(not _alive(v) for v in _RAT_CACHE.values()):
            _RAT_CACHE.clear()     # sobrou de outra cena (a cena é recriada a cada carta)
        old = (chars.FUR, chars.FUR_D, chars.BELLY)
        if fur:
            chars.FUR, chars.FUR_D, chars.BELLY = fur
        try:
            g = chars.rat()
        finally:
            chars.FUR, chars.FUR_D, chars.BELLY = old
        if eyes:
            for sx in (-1, 1):
                e = sph((sx * 0.115, -0.726, 0.67), 1, (0.052, 0.03, 0.06)); setmat(e, mat("rage_%s" % str(eyes), eyes, 0.4, emit=7.0)); e.parent = g
        _RAT_CACHE[key] = _rat_copy(g)     # molde limpo, só com o que veio do modelo
        for o in [_RAT_CACHE[key]] + list(_RAT_CACHE[key].children):
            bpy.context.scene.collection.objects.unlink(o)     # molde fora da cena (não entra no enquadramento)
    g.location = loc; g.rotation_euler = (math.radians(rx), 0, math.radians(rz))
    g.scale = tuple(sc) if sc else (s,) * 3
    return g


def streaks(items, color=(0.03, 0.02, 0.03), r=0.012):
    """Riscos de movimento: items = [(a, b), ...] pontos 3D."""
    out = []
    m = mat("speed_%s" % str(color), color, 0.9)
    for a, b in items:
        t = tube([a, b], r, 0.25, 6); setmat(t, m); out.append(t)
    group("streaks", out)


def goo_cloud(blobs, color=GREEN, name="miasma"):
    """Névoa de peste: esferas fundidas num bloco macio. blobs = [(x, y, z, r)]."""
    o = fuse([sph((x, y, z), 1, (r, r * 0.9, r * 0.8)) for x, y, z, r in blobs], name, 0.02, 0.7, 6)
    setmat(o, mat("miasma_%s" % str(color), color, 0.6, bump=0.3, bump_scale=14))
    return o


def sicks(pts, r=0.045):
    """Bubões (caroços arroxeados e verdes)."""
    out = []
    for i, (x, y, z) in enumerate(pts):
        s = sph((x, y, z), r * (0.8 + 0.4 * (i % 3) / 2)); shade(s)
        setmat(s, mat("bubo%d" % (i % 2), (0.55, 0.78, 0.3) if i % 2 else (0.5, 0.25, 0.45), 0.35, coat=0.8)); out.append(s)
    return out


def ground_rocks(pts, name="rocks"):
    P = []
    for (x, y, r) in pts:
        s = sph((x, y, r * 0.55), r, (1, 0.9, 0.65)); shade(s); setmat(s, mat("stone", STONE, 0.9)); P.append(s)
    return group(name, P)


# ------------------------------------------------------------------ Horda de Ratos

def rat_horde():
    rows = [((-1.1, 0.0), 14, 0.55), ((-0.35, 0.1), -10, 0.6), ((0.45, -0.05), 18, 0.58), ((1.2, 0.05), -20, 0.55),
            ((-0.8, 0.95), 6, 0.55), ((0.0, 1.0), -14, 0.57), ((0.85, 0.95), 20, 0.55),
            ((-0.35, 1.8), -4, 0.5), ((0.5, 1.8), 12, 0.5)]
    for i, ((x, y), rz, s) in enumerate(rows):
        R((x, y, 0.0), rz, s, rx=-6 if i % 2 else 4)
    streaks([((x, y + 1.0, z), (x, y + 1.5, z)) for (x, y, z) in ((-1.1, 0.1, 0.18), (0.45, 0.2, 0.22), (1.2, 0.2, 0.15), (-0.35, 0.3, 0.12))])
    return {"kind": "swarm", "dir": (0.36, -1.0, 0.34)}


# ------------------------------------------------------------------ Ratos Raivosos

def rabid_rats():
    RED = (1.0, 0.18, 0.12)
    FUR = ((0.42, 0.3, 0.26), (0.2, 0.12, 0.12), (0.74, 0.56, 0.5))
    R((0.0, -0.1, 0.0), 8, 0.95, rx=-10, fur=FUR, eyes=RED)
    R((-1.15, 0.45, 0.0), -30, 0.78, rx=-6, fur=FUR, eyes=RED)
    R((1.1, 0.4, 0.0), 40, 0.75, rx=-12, fur=FUR, eyes=RED)
    R((-0.5, 1.2, 0.0), -10, 0.6, fur=FUR, eyes=RED)
    R((0.6, 1.25, 0.0), 24, 0.6, fur=FUR, eyes=RED)
    # espuma na boca e riscos de fúria
    P = []
    for (x, y, z, r) in ((0.0, -1.0, 0.45, 0.05), (0.07, -1.05, 0.4, 0.035), (-0.06, -1.02, 0.38, 0.03), (-1.0, -0.2, 0.4, 0.04), (1.1, -0.4, 0.38, 0.04)):
        b = sph((x, y, z), r); shade(b); setmat(b, mat("foam", (0.97, 0.97, 0.95), 0.3)); P.append(b)
    group("foam", P)
    streaks([((x, -1.3, z), (x + dx, -1.5, z + dz)) for (x, z, dx, dz) in ((-0.6, 1.2, -0.3, 0.3), (0.55, 1.3, 0.3, 0.3), (0.0, 1.55, 0.0, 0.35), (-1.1, 0.7, -0.35, 0.1), (1.1, 0.75, 0.35, 0.1))], (0.5, 0.05, 0.05), 0.016)
    return {"kind": "swarm", "dir": (0.15, -1.0, 0.22)}


# ------------------------------------------------------------------ Chamado do Bando

def pack_call():
    horn = []
    bone = mat("bone", BONE, 0.55, bump=0.2, bump_scale=30)
    h = tube([(1.6, 0.3, 0.2), (1.1, 0.3, 0.7), (0.5, 0.3, 1.0), (-0.1, 0.3, 1.45)], 0.1, 3.4, 20)
    setmat(h, bone); horn.append(h)
    band = torus((1.6, 0.3, 0.2), 0.11, 0.025, (0, 40, 0)); shade(band); setmat(band, mat("gold", chars.GOLD, 0.3, 1.0)); horn.append(band)
    lip = torus((-0.1, 0.3, 1.45), 0.34, 0.035, (65, 0, 0)); lip.rotation_euler = Vector((0, 0, 1)).rotation_difference(Vector((-0.6, 0.0, 0.45)).normalized()).to_euler(); shade(lip); setmat(lip, mat("gold", chars.GOLD, 0.3, 1.0)); horn.append(lip)
    group("horn", horn)
    # ondas sonoras saindo da boca da trompa
    waves = []
    d = Vector((-0.6, 0.0, 0.45)).normalized()
    for k, rr in enumerate((0.5, 0.78, 1.06)):
        c = Vector((-0.1, 0.3, 1.45)) + d * (0.35 + k * 0.4)
        t = torus(tuple(c), rr, 0.02, (0, 0, 0)); t.rotation_euler = Vector((0, 0, 1)).rotation_difference(d).to_euler(); shade(t)
        setmat(t, mat("wave", (0.85, 0.7, 0.35), 0.6)); waves.append(t)
    group("waves", waves)
    R((-0.9, -0.7, 0.0), -35, 0.62, rx=-14, eyes=(1.0, 0.7, 0.15))
    R((0.1, -1.1, 0.0), 10, 0.6, rx=-10, eyes=(1.0, 0.7, 0.15))
    R((1.0, -0.8, 0.0), 40, 0.55, rx=-12, eyes=(1.0, 0.7, 0.15))
    R((-0.2, -0.2, 0.0), -10, 0.5, eyes=(1.0, 0.7, 0.15))
    streaks([((x, y + 0.6, z), (x, y + 1.1, z)) for (x, y, z) in ((-0.9, -0.5, 0.2), (0.1, -0.9, 0.18), (1.0, -0.6, 0.14))], r=0.014)
    return {"kind": "spell", "dir": (0.1, -1.0, 0.3), "hatch": 22.0}


# ------------------------------------------------------------------ Ninho de Morcegos

def bat_nest():
    n = monsters2.bat_nest()
    place(n, (0, 0, 0), rot_z=-15)
    for (x, y, z, rz, s) in ((-1.2, -0.8, 3.1, 25, 0.5), (1.4, -0.5, 3.6, -30, 0.45), (0.2, -1.2, 3.9, 8, 0.4)):
        place(monsters2.bat(), (x, y, z), rot_z=rz, scale=s, rot_x=-10)
    return {"kind": "structure", "dir": (0.45, -1.0, 0.2), "lens": 70}


# ------------------------------------------------------------------ Slime

def slime():
    place(chars2.slime(), (0, 0, 0), rot_z=10, scale=1.45)
    place(chars2.slime(), (1.1, -0.5, 0), rot_z=-30, scale=0.62)
    place(chars2.slime(), (-1.0, -0.65, 0), rot_z=25, scale=0.46)
    place(chars2.slime(), (0.75, -1.15, 0), rot_z=-10, scale=0.3)
    # poças e respingos de gosma no chão
    P = []
    gm = mat("goo_puddle", (0.4, 0.85, 0.3), 0.15, coat=1.0)
    for (x, y, rx, ry) in ((0.0, -0.1, 0.9, 0.7), (0.9, -0.3, 0.38, 0.28), (-0.9, -0.5, 0.3, 0.22)):
        p = sph((x, y, 0.01), 1, (rx, ry, 0.02)); shade(p); setmat(p, gm); P.append(p)
    group("puddles", P)
    return {"kind": "monster", "dir": (0.3, -1.0, 0.28)}


# ------------------------------------------------------------------ Rei dos Ratos

def rat_king():
    k = monsters2.rat_king()
    place(k, (0, -0.05, 0.3), rot_z=10, scale=1.15)
    FUR = ((0.36, 0.29, 0.27), (0.2, 0.15, 0.15), (0.78, 0.68, 0.6))
    # corte de ratos: ajoelhados em volta, e o trono de ratos embaixo
    R((-0.95, -0.6, 0.0), 40, 0.5, rx=0, fur=FUR)
    R((0.95, -0.6, 0.0), -42, 0.5, fur=FUR)
    R((-1.5, 0.15, 0.0), 70, 0.45, fur=FUR)
    R((1.5, 0.1, 0.0), -70, 0.45, fur=FUR)
    R((-0.3, 0.75, 0.0), 160, 0.55, fur=FUR)
    R((0.45, 0.7, 0.0), -160, 0.55, fur=FUR)
    # almofada de veludo e moedas
    P = []
    cush = fuse([sph((0, 0.0, 0.62), 1, (0.55, 0.5, 0.1))], "cushion", 0.012); setmat(cush, mat("velvet", (0.75, 0.1, 0.16), 0.75, bump=0.1, bump_scale=60)); P.append(cush)
    for (x, y) in ((-1.2, -1.1), (1.1, -1.15), (0.2, -1.4)):
        c = cyl((x, y, 0.025), 0.09, 0.025, bevel=0.005); hard(c); setmat(c, mat("gold", chars.GOLD, 0.28, 1.0)); P.append(c)
    group("court", P)
    return {"kind": "monster", "dir": (0.22, -1.0, 0.3), "lens": 80}


# ------------------------------------------------------------------ Lobisomem

def werewolf():
    w = monsters2.werewolf()
    place(w, (0, 0, 0), rot_z=-18)
    P = []
    moon = sph((-1.5, 1.6, 2.7), 0.75); setmat(moon, mat("moon", (0.98, 0.95, 0.8), 0.5, emit=1.5)); P.append(moon)
    for (x, y, z, r) in ((-1.3, 0.9, 2.95, 0.12), (-1.75, 0.9, 2.6, 0.09), (-1.2, 0.9, 2.4, 0.07)):
        c = sph((x, y, z), 1, (r, r * 0.3, r)); setmat(c, mat("moonspot", (0.8, 0.77, 0.6), 0.8)); P.append(c)
    group("moon", P)
    st = mat("gravestone", STONE, 0.9, bump=0.4, bump_scale=14)
    G = []
    for (x, y, rz) in ((1.5, 0.6, 14), (-1.4, 0.7, -10)):
        sl = box((x, y, 0.35), (0.5, 0.12, 0.7), (4, 5, rz), bevel=0.04); hard(sl); setmat(sl, st); G.append(sl)
        tp = cyl((x, y, 0.7), 0.25, 0.12, rot=(90, 0, rz), seg=20, bevel=0.02); hard(tp); setmat(tp, st); G.append(tp)
    group("graves", G)
    ground_rocks([(0.9, -0.9, 0.12), (-0.8, -0.7, 0.09), (1.2, -0.4, 0.07)])
    return {"kind": "monster", "dir": (0.42, -1.0, 0.14), "lens": 75}


# ------------------------------------------------------------------ Ratazana

def rat_brute():
    FUR = ((0.3, 0.26, 0.26), (0.15, 0.12, 0.13), (0.6, 0.55, 0.5))
    g = R((0, 0, 0), 20, sc=(1.55, 1.6, 1.45), fur=FUR, eyes=(0.7, 1.0, 0.3))
    # bubões nas costas, orelha rasgada, atadura
    P = sicks([(-0.3, 0.0, 0.62), (0.32, 0.05, 0.6), (-0.27, 0.3, 0.55), (0.28, 0.32, 0.5), (0.0, 0.1, 0.8), (-0.22, -0.25, 0.55)], 0.075)
    for o in P:
        o.parent = g
    band = torus((0, -0.2, 0.55), 0.3, 0.035, (0, 0, 0)); shade(band); setmat(band, mat("cloth", (0.85, 0.8, 0.68), 0.9)); band.parent = g
    R((-1.45, -0.5, 0), -40, 0.45)
    R((1.5, -0.4, 0), 40, 0.4)
    return {"kind": "monster", "dir": (0.4, -1.0, 0.24)}


# ------------------------------------------------------------------ Mordida Infectada

def infected_bite():
    P = []
    skin = mat("skinm", chars.SKIN, 0.55, sss=0.25)
    arm = fuse([capsule((-1.9, 0.25, 0.7), (-0.2, 0.0, 0.62), 0.27, 0.22), capsule((-0.2, 0.0, 0.62), (0.45, -0.05, 0.62), 0.22, 0.2)], "forearm", 0.014)
    setmat(arm, mat("sleeve", (0.16, 0.27, 0.62), 0.8, bump=0.08, bump_scale=200)); P.append(arm)
    steel = mat("steel", (0.62, 0.65, 0.7), 0.42, 0.85)
    br = cyl((-0.5, 0.0, 0.62), 0.29, 0.6, (0, 90, 0), seg=32, bevel=0.03, r2=0.25); hard(br); setmat(br, steel); P.append(br)
    for x in (-0.28, -0.72):
        rv = torus((x, 0.0, 0.62), 0.29, 0.02, (0, 90, 0)); shade(rv); setmat(rv, mat("gold", chars.GOLD, 0.3, 1.0)); P.append(rv)
    hand = fuse([sph((0.62, -0.05, 0.62), 1, (0.2, 0.17, 0.15)), capsule((0.62, -0.18, 0.62), (0.95, -0.3, 0.64), 0.07, 0.055), capsule((0.62, -0.05, 0.68), (0.95, -0.02, 0.7), 0.065, 0.05),
                 capsule((0.62, 0.05, 0.62), (0.9, 0.2, 0.6), 0.065, 0.05)], "hand", 0.01)
    setmat(hand, mat("glove", (0.32, 0.2, 0.12), 0.6)); P.append(hand)
    group("arm", P)
    # veias verdes subindo pelo braço a partir da mordida
    V = []
    gm = mat("vein", (0.45, 0.9, 0.25), 0.4, emit=3.0)
    for (dz, dy) in ((0.14, -0.06), (-0.1, 0.0), (0.04, 0.12)):
        v = tube([(0.35, -0.15 + dy, 0.62 + dz * 1.4), (0.05, -0.1 + dy, 0.74 + dz), (-0.3, -0.12 + dy, 0.82 + dz * 0.6), (-0.9, -0.1 + dy, 0.9)], 0.014, 0.4, 14); setmat(v, gm); V.append(v)
    for (x, y, z) in ((0.45, -0.2, 0.5), (0.4, -0.22, 0.4), (0.3, -0.25, 0.33)):
        d = sph((x, y, z), 1, (0.035, 0.035, 0.06)); setmat(d, gm); V.append(d)
    group("veins", V)
    # o rato pendurado no pulso
    R((0.12, -0.04, 0.84), 90, 0.62, rx=0, eyes=(0.7, 1.0, 0.3))
    return {"kind": "spell", "dir": (0.35, -1.0, 0.45), "hatch": 22.0}


# ------------------------------------------------------------------ Nuvem de Morcegos

def bat_cloud():
    for (x, y, z, rz, rx, s) in ((0, 0, 1.2, 0, -12, 0.75), (-1.4, 0.5, 1.9, -35, -22, 0.6), (1.5, 0.3, 1.7, 35, -8, 0.62),
                                 (-0.7, -0.9, 0.4, -15, 10, 0.55), (0.9, -1.0, 0.7, 25, 6, 0.5),
                                 (-1.9, -0.4, 0.8, -50, 4, 0.45), (0.1, 0.9, 2.4, 5, -30, 0.5), (2.0, -0.5, 0.2, 55, 0, 0.42)):
        place(monsters2.bat(), (x, y, z), rot_z=rz, scale=s, rot_x=rx)
    # luar e riscos de voo
    streaks([((x, y + 0.5, z), (x, y + 1.3, z + 0.1)) for (x, y, z) in ((0.0, 0.3, 1.5), (-1.4, 0.8, 2.1), (1.5, 0.6, 1.9), (-0.7, -0.6, 0.6), (0.9, -0.7, 0.9))])
    return {"kind": "swarm", "dir": (0.2, -1.0, 0.2), "lens": 70}


# ------------------------------------------------------------------ Ratoeira Viva

def rat_trap():
    P = []
    wood = mat("wood", WOOD_C, 0.8, bump=0.4, bump_scale=25)
    base = box((0, 0, 0.07), (2.0, 1.0, 0.14), (0, 0, -6), bevel=0.04); hard(base); setmat(base, wood); P.append(base)
    iron = mat("iron", (0.3, 0.3, 0.33), 0.5, metal=0.6)
    # barra da mola armada, aberta em arco
    bar = tube([(-0.85, -0.38, 0.15), (-0.85, -0.38, 0.95), (-0.5, -0.38, 1.25), (0.5, -0.38, 1.25), (0.85, -0.38, 0.95), (0.85, -0.38, 0.15)], 0.035, 1.0, 20); setmat(bar, iron); P.append(bar)
    for x in (-0.85, 0.85):
        h = torus((x, -0.38, 0.18), 0.06, 0.018, (90, 0, 0)); shade(h); setmat(h, iron); P.append(h)
    sp = tube([(0.9, 0.3, 0.16), (0.9, 0.0, 0.3), (0.7, 0.0, 0.2), (0.7, 0.3, 0.3), (0.5, 0.3, 0.18), (0.5, 0.0, 0.3)], 0.022, 1.0, 20); setmat(sp, iron); P.append(sp)
    pl = box((-0.2, 0.1, 0.17), (0.5, 0.4, 0.04), (0, 0, 8), bevel=0.01); hard(pl); setmat(pl, iron); P.append(pl)
    ch = box((-0.2, 0.1, 0.28), (0.32, 0.26, 0.2), (0, 0, 25), bevel=0.02, taper=(0.9, 0.3)); hard(ch); setmat(ch, mat("cheese", CHEESE, 0.5)); P.append(ch)
    for (x, y) in ((-0.28, 0.07), (-0.1, 0.17), (-0.25, 0.2)):
        hl = sph((x, y - 0.12, 0.3), 1, (0.04, 0.02, 0.04)); setmat(hl, mat("shadow", SHADOW, 0.9)); P.append(hl)
    group("trap", P)
    # folhas e uma tábua escorada: ratos escondidos só com os olhos de fora, e dois já saltando
    pl2 = box((-0.7, 0.75, 0.38), (1.1, 0.1, 0.7), (-25, 0, 15), bevel=0.03); hard(pl2); setmat(pl2, wood)
    group("cover", [pl2])
    for (x, y, z) in ((-0.95, 0.55, 0.22), (-0.78, 0.5, 0.2), (-0.5, 0.53, 0.18)):
        e = sph((x, y, z), 1, (0.035, 0.02, 0.04)); setmat(e, mat("eyeglow", (1.0, 0.82, 0.25), 0.4, emit=8.0)); group("eye", [e])
    R((1.15, -0.55, 0.3), -25, 0.5, rx=-30, eyes=(1.0, 0.7, 0.15))
    R((0.35, 0.95, 0.05), 160, 0.45)
    R((-1.25, -0.5, 0.0), 30, 0.48)
    return {"kind": "structure", "dir": (0.38, -1.0, 0.38)}


# ------------------------------------------------------------------ Matilha de Lobos

def wolf_pack():
    cp.wolf(legs={"fl": 38, "fr": -30, "bl": -28, "br": 32}).location = (0.0, 0.0, 0.0)
    a = cp.wolf(legs={"fl": -20, "fr": 28, "bl": 30, "br": -25}); a.location = (-1.3, 0.9, 0.0); a.rotation_euler = (0, 0, math.radians(-24)); a.scale = (0.9,) * 3
    b = cp.wolf(jaw_open=26, legs={"fl": 8, "fr": 8, "bl": 0, "br": 0}); b.location = (1.25, 0.8, 0.0); b.rotation_euler = (0, 0, math.radians(26)); b.scale = (0.85,) * 3
    # nuvem de peste verde subindo de um deles
    return {"kind": "monster", "dir": (0.3, -1.0, 0.22), "lens": 70}


# ------------------------------------------------------------------ Mãe da Ninhada

def brood_mother():
    FUR = ((0.62, 0.52, 0.5), (0.4, 0.3, 0.3), (0.92, 0.8, 0.74))
    g = R((0, 0, 0), 14, sc=(1.7, 1.55, 1.35), fur=FUR)
    # ninhada: filhotes rosados subindo nas costas e em volta
    BABY = ((0.92, 0.7, 0.68), (0.78, 0.5, 0.52), (0.98, 0.88, 0.84))
    R((0.0, -1.35, 0.0), -20, 0.3, fur=BABY)
    R((0.75, -1.25, 0.0), 30, 0.27, fur=BABY)
    R((-0.75, -1.3, 0.0), -50, 0.28, fur=BABY)
    R((1.35, -0.7, 0.0), 70, 0.26, fur=BABY)
    R((-1.4, -0.55, 0.0), -80, 0.27, fur=BABY)
    R((0.15, 0.1, 0.92), 160, 0.25, fur=BABY, rx=-10)
    R((-0.35, 0.4, 0.9), 130, 0.23, fur=BABY)
    # barriga cheia: tetas marcadas
    return {"kind": "monster", "dir": (0.38, -1.0, 0.3)}


# ------------------------------------------------------------------ Flautista Corrompido

def corrupt_piper():
    old = chars.SKIN
    chars.SKIN = (0.66, 0.8, 0.55)
    P = []
    try:
        coat = mat("coat", (0.4, 0.14, 0.45), 0.8, bump=0.08, bump_scale=200)
        coat2 = mat("coat2", (0.86, 0.66, 0.2), 0.8)
        boot = mat("boot", (0.22, 0.15, 0.12), 0.6)
        chars.legs(P, mat("pants", (0.18, 0.5, 0.35), 0.8), boot)
        body = fuse([sph((0, 0, 0.98), 1, (0.28, 0.22, 0.3)), sph((0, 0, 0.78), 1, (0.25, 0.2, 0.16))], "tunic", 0.01); setmat(body, coat); P.append(body)
        sk = cyl((0, 0, 0.58), 0.28, 0.4, seg=40, bevel=0.03, r2=0.25); hard(sk); setmat(sk, coat); P.append(sk)
        for k in range(5):   # remendos de losango em cores trocadas
            d = box((-0.2 + k * 0.1, -0.235, 0.82 - (k % 2) * 0.12), (0.09, 0.02, 0.09), (0, 45, 0), bevel=0.006); hard(d); setmat(d, coat2); P.append(d)
        head = chars.chibi_head(P)
        # chapéu de pena: cone torto com pluma e aba
        brim = cyl((0, -0.02, 1.7), 0.42, 0.03, (-8, 0, 0), seg=40, bevel=0.012); hard(brim); setmat(brim, coat2); P.append(brim)
        cone = cyl((0, 0.04, 1.9), 0.3, 0.45, (-8, 0, 0), seg=32, bevel=0.0, r2=0.1); hard(cone); setmat(cone, coat2); P.append(cone)
        plume = tube([(0.12, 0.05, 2.05), (0.4, 0.05, 2.25), (0.62, 0.05, 2.05), (0.7, 0.05, 1.85)], 0.04, 0.2, 14); setmat(plume, mat("plume", (0.5, 0.9, 0.3), 0.6)); P.append(plume)
        # flauta de osso, comprida, nos lábios; as duas mãos nela
        fl = tube([(0.02, -0.34, 1.36), (-0.35, -0.55, 1.1), (-0.72, -0.7, 0.88)], 0.03, 1.0, 12); setmat(fl, mat("bone", BONE, 0.55)); P.append(fl)
        for t in (0.35, 0.55, 0.75):
            hl = sph((-0.02 - t * 0.7, -0.34 - t * 0.37, 1.36 - t * 0.52 + 0.025), 0.013); setmat(hl, mat("shadow", SHADOW, 0.9)); P.append(hl)
        chars.arm(P, 1, coat, mat("glove", (0.66, 0.8, 0.55), 0.6), (-0.3, -0.55, 1.12))
        chars.arm(P, -1, coat, mat("glove", (0.66, 0.8, 0.55), 0.6), (-0.62, -0.62, 0.98))
        # capa esfarrapada
        cape = fuse([sph((0, 0.2, 0.85), 1, (0.32, 0.06, 0.45), (8, 0, 0))] + [sph((x, 0.24, 0.45), 1, (0.08, 0.05, 0.2)) for x in (-0.22, -0.07, 0.08, 0.23)], "cape", 0.01)
        setmat(cape, mat("capec", (0.15, 0.3, 0.22), 0.85)); P.append(cape)
    finally:
        chars.SKIN = old
    g = group("piper", P)
    place(g, (0, 0, 0.0), rot_z=-12, scale=1.0)
    # notas verdes da melodia
    N = []
    gm = mat("note", GLOW_G, 0.4, emit=4.0)
    for (x, y, z, s) in ((-1.0, -0.9, 1.3, 1.0), (-1.35, -0.8, 1.65, 0.8), (-0.75, -1.0, 1.75, 0.9)):
        nb = sph((x, y, z), 1, (0.07 * s, 0.05 * s, 0.05 * s)); setmat(nb, gm); N.append(nb)
        st = tube([(x + 0.06 * s, y, z), (x + 0.06 * s, y, z + 0.24 * s)], 0.011, 1.0, 4); setmat(st, gm); N.append(st)
        fg = tube([(x + 0.06 * s, y, z + 0.24 * s), (x + 0.15 * s, y, z + 0.18 * s)], 0.011, 0.8, 4); setmat(fg, gm); N.append(fg)
    group("notes", N)
    # fila de ratos hipnotizados atrás
    for i, (x, y) in enumerate(((-1.3, -1.45), (-0.5, -1.6), (0.4, -1.55), (1.15, -1.3), (1.65, -0.85))):
        R((x, y, 0.0), 8 + i * 5 - 20, 0.42, eyes=GLOW_G)
    return {"kind": "monster", "dir": (0.3, -1.0, 0.22), "lens": 75}


# ------------------------------------------------------------------ Esgoto Transbordante

def sewer_flood():
    P = []
    brick = mat("brick", (0.45, 0.4, 0.38), 0.9, bump=0.6, bump_scale=10)
    wall = box((0, 0.5, 1.25), (3.0, 0.5, 2.5), bevel=0.04); hard(wall); setmat(wall, brick); P.append(wall)
    for (x, z) in ((-1.1, 0.5), (0.6, 2.0), (1.1, 1.0), (-0.9, 2.1)):
        b = box((x, 0.2, z), (0.5, 0.06, 0.22), bevel=0.01); hard(b); setmat(b, mat("brick2", (0.32, 0.28, 0.27), 0.9)); P.append(b)
    pipe = cyl((0, 0.0, 1.5), 0.62, 1.0, (90, 0, 0), seg=32, bevel=0.03); apply_mods(pipe)
    cut = cyl((0, -0.1, 1.5), 0.46, 1.4, (90, 0, 0), seg=32, bevel=0)
    m = pipe.modifiers.new("c", 'BOOLEAN'); m.object = cut; m.operation = 'DIFFERENCE'; m.solver = 'EXACT'; apply_mods(pipe); bpy.data.objects.remove(cut)
    shade(pipe); setmat(pipe, mat("pipe", (0.33, 0.34, 0.36), 0.5, 0.7, bump=0.3, bump_scale=14)); P.append(pipe)
    rim = torus((0, -0.5, 1.5), 0.62, 0.05, (90, 0, 0)); shade(rim); setmat(rim, mat("pipe", (0.33, 0.34, 0.36), 0.5, 0.7)); P.append(rim)
    ph = sph((0, 0.35, 1.5), 1, (0.48, 0.05, 0.48)); setmat(ph, mat("shadow", SHADOW, 0.9)); P.append(ph)
    group("wall", P)
    # a torrente: jorro do cano até a poça, cheio de espuma
    W = []
    gw = mat("sludge", (0.32, 0.55, 0.28), 0.12, coat=1.0, bump=0.2, bump_scale=10)
    stream = fuse([sph((0, -0.35, 1.2 - t * 0.28), 1, (0.42 + t * 0.07, 0.28 + t * 0.2, 0.2)) for t in range(0, 4)] + [sph((0, -0.5, 1.0), 1, (0.45, 0.35, 0.3)),
                   sph((0, -1.05, 0.3), 1, (0.9, 0.7, 0.2)), sph((0, -0.7, 0.5), 1, (0.4, 0.4, 0.4))], "stream", 0.02, 0.7, 6)
    setmat(stream, gw); W.append(stream)
    pool = sph((0, -1.45, 0.06), 1, (1.9, 1.0, 0.1)); shade(pool); setmat(pool, gw); W.append(pool)
    for (x, y, z, r) in ((-0.9, -1.0, 0.2, 0.09), (0.8, -1.2, 0.18, 0.07), (0.3, -1.9, 0.12, 0.06), (-0.4, -0.7, 0.3, 0.05), (1.3, -1.6, 0.1, 0.05), (-1.4, -1.5, 0.1, 0.06)):
        bb = sph((x, y, z), r); shade(bb); setmat(bb, mat("foam", (0.85, 0.95, 0.8), 0.25)); W.append(bb)
    group("water", W)
    R((0.1, -0.8, 0.5), 0, 0.45, rx=-35, eyes=GLOW_G)
    R((-1.0, -1.7, 0.05), -35, 0.5)
    R((0.95, -1.8, 0.05), 40, 0.5)
    R((-0.35, -2.1, 0.0), 10, 0.42)
    R((1.55, -1.0, 0.05), 80, 0.4)
    return {"kind": "structure", "dir": (0.38, -1.0, 0.3), "lens": 70}


# ------------------------------------------------------------------ Javali de Guerra

def war_boar():
    b = cp.boar(legs={"fl": 42, "fr": 20, "bl": -30, "br": -42})
    b.rotation_euler = (math.radians(4), 0, math.radians(-10))
    # poeira da investida e escombros
    D = []
    dm = mat("dust", (0.8, 0.72, 0.58), 0.95, bump=0.3, bump_scale=12)
    for (x, y, z, r) in ((-0.5, 0.95, 0.18, 0.28), (0.5, 1.1, 0.16, 0.24), (0.0, 1.5, 0.28, 0.34), (-1.0, 0.8, 0.1, 0.17), (1.0, 0.75, 0.12, 0.2)):
        d = sph((x, y, z), 1, (r, r * 0.9, r * 0.8)); shade(d); setmat(d, dm); D.append(d)
    group("dust", D)
    S = []
    for (x, y, z, r) in ((-0.9, -1.6, 0.9, 0.1), (0.8, -1.8, 1.1, 0.08), (0.0, -1.9, 0.6, 0.07)):
        s = sph((x, y, z), r, (1, 0.9, 0.7)); shade(s); setmat(s, mat("stone", STONE, 0.9)); S.append(s)
    # escudo de herói estilhaçado à frente
    sh = cyl((-1.7, -1.3, 0.3), 0.4, 0.07, (80, 0, 12), seg=24, bevel=0.015); hard(sh); setmat(sh, mat("shield", (0.12, 0.27, 0.72), 0.5, 0.2)); S.append(sh)
    ctr = sph((-1.7, -1.34, 0.33), 1, (0.1, 0.05, 0.1)); setmat(ctr, mat("gold", chars.GOLD, 0.3, 1.0)); S.append(ctr)
    group("debris", S)
    streaks([((x, 1.1, z), (x, 2.1, z + 0.05)) for (x, z) in ((-0.5, 0.5), (0.3, 0.9), (0.6, 0.4), (-0.2, 1.2))], r=0.014)
    return {"kind": "monster", "dir": (0.5, -1.0, 0.22), "lens": 75}


# ------------------------------------------------------------------ Instinto de Caça

def hunt_instinct():
    w = cp.wolf(jaw_open=22, legs={"fl": -55, "fr": -48, "bl": 55, "br": 60}, tail_up=0.6)
    w.location = (0.3, 0, 0.55); w.rotation_euler = (math.radians(-10), 0, math.radians(-20)); w.scale = (1.25,) * 3
    # três arranhões vermelhos no ar e gotas de sangue (roubo de vida)
    C = []
    cm = mat("claw", (0.8, 0.1, 0.12), 0.6)
    for k in range(3):
        o = k * 0.22
        t = tube([(-0.9 + o, -1.5, 1.5), (-0.55 + o, -1.5, 1.0), (-0.35 + o, -1.5, 0.5)], 0.04, 0.1, 14); setmat(t, cm); C.append(t)
    for (x, y, z, r) in ((-0.1, -1.4, 0.3, 0.05), (0.0, -1.45, 0.1, 0.04), (-0.5, -1.4, 0.15, 0.035)):
        d = sph((x, y, z), 1, (r, r, r * 1.5)); setmat(d, cm); C.append(d)
    group("slash", C)
    streaks([((x, 0.9, z), (x, 2.2, z)) for (x, z) in ((-0.5, 0.5), (0.4, 0.9), (0.8, 0.45), (-0.9, 1.0), (0.0, 1.5))], (0.5, 0.05, 0.05), 0.016)
    return {"kind": "spell", "dir": (0.4, -1.0, 0.18), "hatch": 22.0, "lens": 75}


# ------------------------------------------------------------------ Devorar

def devour():
    w = cp.wolf(jaw_open=48, legs={"fl": 12, "fr": 12, "bl": 0, "br": 0})
    w.scale = (1.15,) * 3; w.rotation_euler = (math.radians(-6), 0, math.radians(-8))
    w.location = (0.4, 0.5, 0)
    R((0.2, -0.75, 0.4), 15, 0.55, rx=-55, eyes=(1.0, 0.8, 0.2))     # preso pelas mandíbulas
    R((-0.9, -1.1, 0.0), -60, 0.5, rx=0)
    R((1.0, -1.2, 0.0), 160, 0.5)
    # ossinhos e sangue no chão
    P = []
    for (x, y, rz) in ((-1.5, -1.4, 20), (0.9, -1.3, -30), (-0.6, -2.3, 70)):
        b = fuse(capsule((x, y, 0.04), (x + 0.3 * math.cos(math.radians(rz)), y + 0.3 * math.sin(math.radians(rz)), 0.04), 0.025) +
                 [sph((x - 0.02, y, 0.07), 0.04), sph((x - 0.02, y + 0.05, 0.03), 0.04)], "bone", 0.008)
        setmat(b, mat("bone", BONE, 0.6)); P.append(b)
    for (x, y, rx, ry) in ((-0.3, -1.5, 0.6, 0.3), (-1.0, -1.1, 0.25, 0.15)):
        p = sph((x, y, 0.01), 1, (rx, ry, 0.015)); shade(p); setmat(p, mat("blood", (0.55, 0.06, 0.08), 0.2, coat=1.0)); P.append(p)
    group("scraps", P)
    return {"kind": "spell", "dir": (0.32, -1.0, 0.24), "hatch": 22.0, "lens": 75}


# ------------------------------------------------------------------ Praga Bubônica

def bubonic_plague():
    P = []
    bone = mat("bone", BONE, 0.55, bump=0.15, bump_scale=40)
    sk = fuse([sph((0, 0, 1.3), 1, (0.55, 0.5, 0.5)), sph((0, -0.18, 0.98), 1, (0.38, 0.32, 0.22)), sph((0, -0.3, 1.0), 1, (0.22, 0.28, 0.14))], "ratskull", 0.014, 0.6, 6)
    setmat(sk, bone); P.append(sk)
    for sx in (-1, 1):
        o = sph((sx * 0.2, -0.43, 1.34), 1, (0.15, 0.1, 0.17), (0, 0, sx * 10)); setmat(o, mat("socket", (0.05, 0.03, 0.06), 0.6)); P.append(o)
        P += monsters.glow_eye((sx * 0.2, -0.5, 1.34), 0.075, GLOW_G, socket=False)
        for k in range(2):
            t = box((sx * 0.05 + (k * 0.01), -0.55, 0.78), (0.07, 0.04, 0.2), (8, 0, 0), bevel=0.01, taper=(0.6, 0.4)); hard(t); setmat(t, mat("tooth", (0.98, 0.95, 0.84), 0.3)); P.append(t)
    nose = sph((0, -0.58, 1.02), 1, (0.07, 0.04, 0.05)); setmat(nose, mat("socket", (0.05, 0.03, 0.06), 0.6)); P.append(nose)
    group("skull", P)
    # névoa de peste enrolando a caveira, bubões e moscas
    goo_cloud([(-0.8, -0.2, 0.55, 0.45), (-0.3, -0.5, 0.35, 0.4), (0.4, -0.45, 0.3, 0.42), (0.9, -0.1, 0.5, 0.42), (1.05, 0.2, 0.95, 0.3),
               (-1.05, 0.0, 0.95, 0.3), (0.0, -0.1, 0.25, 0.55)], GREEN)
    goo_cloud([(-1.0, 0.1, 1.9, 0.28), (-0.7, 0.0, 2.25, 0.22), (1.0, 0.1, 2.05, 0.26), (0.75, 0.0, 2.4, 0.2)], GREEN_D, "miasma2")
    group("buboes", sicks([(-0.6, -0.7, 0.45), (0.1, -0.75, 0.5), (0.65, -0.7, 0.4), (-0.2, -0.8, 0.25), (0.35, -0.82, 0.2), (-0.95, -0.4, 0.4), (1.0, -0.4, 0.45)], 0.1))
    F = []
    for (x, y, z) in ((-0.9, -0.5, 2.0), (0.8, -0.5, 1.9), (-0.5, -0.4, 2.35), (0.3, -0.5, 2.5), (1.15, -0.4, 1.4), (-1.2, -0.3, 1.55)):
        f = sph((x, y, z), 0.035, (1, 1, 0.8)); setmat(f, mat("fly", SHADOW, 0.4)); F.append(f)
        wg = sph((x, y + 0.02, z + 0.035), 1, (0.05, 0.015, 0.03)); setmat(wg, mat("flywing", (0.9, 0.95, 0.9), 0.4)); F.append(wg)
    group("flies", F)
    return {"kind": "spell", "dir": (0.2, -1.0, 0.18), "hatch": 22.0, "lens": 80}


# ------------------------------------------------------------------ Maré de Ratos

def rat_tide():
    k = 0
    for row in range(6):
        n = 6 - (row // 2)
        for i in range(n):
            x = (i - (n - 1) / 2) * 0.8 + (0.35 if row % 2 else 0.0) + math.sin(row * 1.7 + i) * 0.1
            y = row * 0.8
            z = row * row * 0.1 + abs(math.sin(i * 1.3 + row)) * 0.12
            R((x, y, z), math.sin(k * 2.3) * 22, 0.52 - row * 0.015, rx=-14 - row * 4)
            k += 1
    return {"kind": "swarm", "dir": (0.32, -1.0, 0.5), "lens": 70}


# ------------------------------------------------------------------ Ninho-Mãe

def mother_nest():
    P = []
    twig = mat("twig", (0.42, 0.3, 0.2), 0.9, bump=0.4, bump_scale=30)
    twig2 = mat("twig2", (0.3, 0.2, 0.14), 0.9)
    for i in range(46):
        a = i * 2.399963
        t = (i % 7) / 6.0
        r0 = 0.5 + 0.9 * math.sqrt(((i * 37) % 100) / 100.0)
        z0 = 0.15 + (r0 / 1.4) ** 2 * 0.9
        a2 = a + 0.9 + (i % 3) * 0.4
        r1 = min(1.55, r0 + 0.8)
        z1 = 0.15 + (r1 / 1.4) ** 2 * 0.9
        pts = [(math.cos(a) * r0, math.sin(a) * r0, z0), (math.cos((a + a2) / 2) * (r0 + r1) / 2, math.sin((a + a2) / 2) * (r0 + r1) / 2, (z0 + z1) / 2 + 0.12), (math.cos(a2) * r1, math.sin(a2) * r1, z1)]
        w = tube(pts, 0.035 + 0.02 * (i % 3), 0.7, 8); setmat(w, twig if i % 2 else twig2); P.append(w)
    group("nest", P)
    # dentro do ninho: ovos-bolsa rosados, olhos e osso roído
    E = []
    sacm = mat("sac", (0.96, 0.78, 0.76), 0.35, sss=0.4, coat=0.6)
    for (x, y, z, s) in ((-0.3, -0.1, 0.45, 0.3), (0.35, 0.2, 0.42, 0.26), (0.2, -0.35, 0.38, 0.24), (-0.25, 0.35, 0.4, 0.22), (0.0, 0.05, 0.62, 0.28)):
        e = sph((x, y, z), 1, (s, s * 0.85, s * 1.15)); shade(e); setmat(e, sacm); E.append(e)
        v = tube([(x - s * 0.5, y - s * 0.7, z + s * 0.6), (x, y - s * 0.95, z + s * 0.2), (x + s * 0.55, y - s * 0.7, z - s * 0.4)], 0.01, 1.0, 6); setmat(v, mat("vein2", (0.75, 0.25, 0.35), 0.5)); E.append(v)
    group("eggs", E)
    R((-1.55, -1.1, 0.0), -35, 0.5)
    R((1.5, -1.05, 0.0), 38, 0.5)
    R((0.1, -1.7, 0.0), 0, 0.48, rx=-8)
    R((0.0, 0.8, 0.95), 170, 0.6, rx=-8, eyes=(1.0, 0.82, 0.25))
    ground_rocks([(-1.9, -0.2, 0.1), (1.9, 0.3, 0.12), (1.5, -1.7, 0.08)])
    return {"kind": "structure", "dir": (0.4, -1.0, 0.52), "lens": 70}


# ------------------------------------------------------------------ Besta Alfa

def alpha_beast():
    b = cp.wolf("alpha", jaw_open=14, legs={"fl": 22, "fr": -10, "bl": -14, "br": 20})
    b.rotation_euler = (0, 0, math.radians(-16)); b.location = (0, 0, 0)
    # a matilha de ratos e lobos aos pés
    R((-1.4, -1.2, 0.0), -35, 0.5, eyes=(1.0, 0.2, 0.15))
    R((1.35, -1.25, 0.0), 40, 0.5, eyes=(1.0, 0.2, 0.15))
    R((-2.1, -0.4, 0.0), -70, 0.4)
    R((2.0, -0.55, 0.0), 75, 0.4)
    return {"kind": "monster", "dir": (0.48, -1.0, 0.16), "lens": 70}


# ------------------------------------------------------------------ Enxame Sem Fim

def endless_swarm():
    n = 12
    for i in range(n):
        a = i / n * math.tau
        R((math.cos(a) * 1.55, math.sin(a) * 1.55, 0.0), math.degrees(a) + 180, 0.52, rx=-6)
    for i in range(6):
        a = i / 6 * math.tau + 0.4
        R((math.cos(a) * 0.62, math.sin(a) * 0.62, 0.0), math.degrees(a) + 180, 0.3, rx=-4)
    # anel de luz verde: o que morre volta
    P = []
    for (rr, tz, rt) in ((1.55, 0.04, 0.03), (1.1, 0.04, 0.02)):
        t = torus((0, 0, tz), rr, rt); shade(t); setmat(t, mat("rebirth", GLOW_G, 0.4, emit=3.0)); P.append(t)
    for i in range(8):
        a = i * 0.8 + 0.2
        s = sph((math.cos(a) * 1.1, math.sin(a) * 1.1, 0.5 + (i % 3) * 0.3), 0.045); setmat(s, mat("spirit", GLOW_G, 0.4, emit=3.0)); P.append(s)
    group("halo", P)
    return {"kind": "spell", "dir": (0.1, -1.0, 0.75), "hatch": 22.0, "lens": 75}


# ------------------------------------------------------------------ Teia

def web():
    P = []
    stone = mat("stone", STONE, 0.9, bump=0.5, bump_scale=12)
    for sx in (-1, 1):
        p = box((sx * 1.7, 0.4, 1.4), (0.55, 0.55, 2.8), bevel=0.05); hard(p); setmat(p, stone); P.append(p)
    lt = box((0, 0.4, 2.95), (4.0, 0.6, 0.45), bevel=0.05); hard(lt); setmat(lt, stone); P.append(lt)
    group("arch", P)
    silk = mat("silk", (0.96, 0.96, 0.93), 0.4)
    S = []
    cx, cz = 0.0, 1.5
    for k in range(12):
        a = k / 12 * math.tau
        t = tube([(cx, 0.0, cz), (cx + math.cos(a) * 1.55, 0.0, cz + math.sin(a) * 1.55)], 0.016, 0.8, 4); setmat(t, silk); S.append(t)
    for rr in (0.35, 0.65, 0.95, 1.25, 1.5):
        pts = []
        for k in range(13):
            a = k / 12 * math.tau
            sag = math.sin(k * 1.9) * 0.04
            pts.append((cx + math.cos(a) * (rr + sag), 0.0, cz + math.sin(a) * (rr + sag)))
        t = tube(pts, 0.012, 1.0, 40); setmat(t, silk); S.append(t)
    group("web", S)
    # a aranha grande no centro, presa de herói embrulhada em seda e capacete
    sp = []
    sb = fuse([sph((0.0, -0.1, cz + 0.2), 1, (0.3, 0.35, 0.28)), sph((0.0, 0.3, cz + 0.1), 1, (0.38, 0.45, 0.34)), sph((0, -0.38, cz + 0.22), 1, (0.2, 0.17, 0.17))], "spider", 0.012, 0.6, 5)
    paint(sb, lambda p, n: mix((0.12, 0.08, 0.14), (0.4, 0.15, 0.3), smoothstep(0.3, 1.4, ell_w(p, (0, 0.3, cz + 0.4), (0.2, 0.3, 0.2)) * 2))); setmat(sb, mat("spiderv", vcol=True, rough=0.5, coat=0.5)); sp.append(sb)
    for sx in (-1, 1):
        sp += monsters.glow_eye((sx * 0.09, -0.52, cz + 0.28), 0.06, (1.0, 0.2, 0.2), socket=False)
        fang = box((sx * 0.06, -0.55, cz + 0.12), (0.03, 0.03, 0.12), (0, 0, 0), bevel=0.005, taper=(0.1, 0.1)); hard(fang); setmat(fang, mat("tooth", (0.95, 0.9, 0.8), 0.3)); sp.append(fang)
        for j in range(4):
            a = -0.7 + j * 0.45
            leg = tube([(sx * 0.2, -0.1 + a * 0.3, cz + 0.2), (sx * 0.8, a * 0.9 - 0.05, cz + 0.65 - abs(a) * 0.2), (sx * 1.15, a * 1.5, cz - 0.15 - j * 0.1)], 0.035, 0.35, 12)
            setmat(leg, mat("spiderleg", (0.14, 0.09, 0.15), 0.5)); sp.append(leg)
    group("spiderg", sp)
    # casulo com a bota de um herói para fora
    cc = fuse([sph((-0.85, 0.1, cz - 0.75), 1, (0.32, 0.28, 0.5), (0, 12, 0))], "cocoon", 0.012); setmat(cc, silk); group("cocoong", [cc])
    bt = fuse([sph((-0.8, -0.1, cz - 1.15), 1, (0.12, 0.2, 0.09)), capsule((-0.8, -0.05, cz - 1.15), (-0.82, 0.0, cz - 0.9), 0.1, 0.11)], "boot", 0.01); setmat(bt, mat("boot", (0.22, 0.15, 0.12), 0.6)); group("bootg", [bt])
    for (x, z) in ((-0.55, cz - 0.4), (-1.1, cz - 0.55), (-0.95, cz - 1.05)):
        r_ = tube([(x, 0.0, z), (x * 0.5, 0.0, cz + 0.1)], 0.012, 0.6, 6); setmat(r_, silk); group("thread", [r_])
    return {"kind": "spell", "dir": (0.18, -1.0, 0.1), "hatch": 22.0, "lens": 70}


# ------------------------------------------------------------------ Ogro

def ogre():
    o = chars2.ogre()
    place(o, (0, 0, 0), rot_z=-22, scale=1.0)
    # carroça destruída, rodas e tábuas voando
    P = []
    wood = mat("wood", WOOD_C, 0.8, bump=0.4, bump_scale=25)
    for (loc, size, rot) in (((1.5, -1.5, 0.12), (0.9, 0.12, 0.1), (0, 0, 30)), ((-1.3, -1.7, 0.12), (0.8, 0.12, 0.1), (0, 0, -40)), ((0.3, -2.0, 0.9), (0.8, 0.1, 0.1), (30, 10, 70)),
                             ((1.9, -0.6, 0.65), (0.6, 0.1, 0.1), (20, 40, 10))):
        b = box(loc, size, rot, bevel=0.015); hard(b); setmat(b, wood); P.append(b)
    wh = torus((-1.5, -0.8, 0.46), 0.42, 0.05, (80, 0, 20)); shade(wh); setmat(wh, wood); P.append(wh)
    for k in range(4):
        sp = tube([(-1.5, -0.8, 0.46), (-1.5 + 0.38 * math.cos(k * 1.57), -0.8, 0.46 + 0.38 * math.sin(k * 1.57))], 0.02, 1.0, 4); setmat(sp, wood); P.append(sp)
    group("cart", P)
    ground_rocks([(1.2, -0.9, 0.14), (-0.9, -1.2, 0.1), (1.7, -1.3, 0.08), (0.8, -2.2, 0.07)])
    streaks([((1.5, -1.3, 0.2 + k * 0.25), (1.9, -1.3, 0.3 + k * 0.25)) for k in range(3)], r=0.014)
    return {"kind": "monster", "dir": (0.42, -1.0, 0.2)}


# ------------------------------------------------------------------ Barricada

def barricade():
    P = []
    wood = mat("wood", WOOD_C, 0.8, bump=0.5, bump_scale=25)
    wood_d = mat("wood_d", (0.3, 0.18, 0.1), 0.85, bump=0.5, bump_scale=25)
    iron = mat("iron", (0.3, 0.3, 0.33), 0.5, metal=0.6)
    # cavalos de frisa (estacas cruzadas) com pontas de ferro, tábuas e sacos de areia
    for x, rzv in ((-1.2, 8), (0.0, -6), (1.2, 10)):
        for ang in (-35, 35):
            c = cyl((x, 0, 0.7), 0.09, 1.8, (0, ang, rzv), seg=12, bevel=0.012, r2=0.07); hard(c); setmat(c, wood); P.append(c)
        c2 = cyl((x, 0, 0.65), 0.08, 1.6, (90, 0, rzv), seg=12, bevel=0.012); hard(c2); setmat(c2, wood_d); P.append(c2)
        for ang, sgn in ((-35, 1), (35, -1)):
            tpv = Vector((math.sin(math.radians(ang)) * 0.9 * -1, 0, 0.7 + math.cos(math.radians(ang)) * 0.9))
            sp = box((x + tpv.x * -1 * -1 if False else x - math.sin(math.radians(ang)) * -0.95 * -1, 0, 0.7 + 0.95 * math.cos(math.radians(ang))),
                     (0.07, 0.07, 0.3), (0, ang, 0), bevel=0.005, taper=(0.1, 0.1)); hard(sp); setmat(sp, iron); P.append(sp)
    for z, ang in ((0.45, 3), (0.9, -4)):
        pl = box((0, -0.12, z), (3.4, 0.07, 0.22), (0, ang, 0), bevel=0.015); hard(pl); setmat(pl, wood); P.append(pl)
        for x in (-1.5, -0.75, 0, 0.75, 1.5):
            n = sph((x, -0.17, z), 0.025); setmat(n, iron); P.append(n)
    group("fence", P)
    S = []
    sack = mat("sack", (0.72, 0.62, 0.42), 0.95, bump=0.5, bump_scale=30)
    for (x, y, z, rz) in ((-1.7, -0.7, 0.18, 20), (-1.1, -0.85, 0.18, -10), (-1.4, -0.75, 0.5, 5), (1.5, -0.8, 0.18, -15), (1.9, -0.55, 0.18, 30)):
        s = sph((x, y, z), 1, (0.38, 0.24, 0.18), (0, 0, rz)); shade(s); setmat(s, sack); S.append(s)
        tie = sph((x + 0.3 * math.cos(math.radians(rz)), y + 0.3 * math.sin(math.radians(rz)), z + 0.08), 0.06, (1, 1, 0.7)); setmat(tie, sack); S.append(tie)
    brl = cyl((0.0, -0.9, 0.35), 0.28, 0.7, seg=24, bevel=0.02); hard(brl); setmat(brl, wood_d); S.append(brl)
    for z in (0.15, 0.55):
        hp = torus((0.0, -0.9, z), 0.285, 0.02); shade(hp); setmat(hp, iron); S.append(hp)
    group("sacks", S)
    ground_rocks([(0.9, -1.2, 0.08), (-0.6, -1.3, 0.07)])
    return {"kind": "structure", "dir": (0.3, -1.0, 0.32), "lens": 70}


# ------------------------------------------------------------------ Estandarte de Guerra

def war_banner():
    P = []
    wood = mat("wood", WOOD_C, 0.7, bump=0.4, bump_scale=25)
    gold = mat("gold", chars.GOLD, 0.3, 1.0)
    pole = tube([(0, 0, 0.0), (0.02, 0, 1.6), (0, 0, 3.3)], 0.06, 0.9, 16); setmat(pole, wood); P.append(pole)
    bar = tube([(-0.05, 0, 3.0), (1.55, 0, 3.02)], 0.045, 1.0, 10); setmat(bar, wood); P.append(bar)
    sp = box((0, 0, 3.5), (0.12, 0.12, 0.45), bevel=0.01, taper=(0.05, 0.05)); hard(sp); setmat(sp, gold); P.append(sp)
    for x in (-0.05, 1.55):
        kn = sph((x, 0, 3.0), 0.07); setmat(kn, gold); P.append(kn)
    # estandarte: pano vermelho ondulado com ponta dupla e caveira
    bm = bmesh.new()
    bmesh.ops.create_grid(bm, x_segments=16, y_segments=18, size=1.0)
    for v in bm.verts:
        u = (v.co.x + 1.0) / 2.0     # 0..1 ao longo da largura
        w = (v.co.y + 1.0) / 2.0     # 0..1 na altura
        v.co.x = 0.08 + u * 1.4
        v.co.z = 2.95 - w * 2.35
        v.co.y = math.sin(u * 5.0 + w * 2.0) * 0.1 * u
        if w > 0.82:   # barra com corte em V
            k = (w - 0.82) / 0.18
            v.co.z += -abs(u - 0.5) * 0.0 + (0.38 * k * (1.0 - abs(u - 0.5) * 2.0)) * -1.0 + 0.0
    me = bpy.data.meshes.new("cloth"); bm.to_mesh(me); bm.free()
    cl = bpy.data.objects.new("cloth", me); bpy.context.scene.collection.objects.link(cl)
    m = cl.modifiers.new("sol", 'SOLIDIFY'); m.thickness = 0.03; apply_mods(cl)
    shade(cl); setmat(cl, mat("banner", (0.72, 0.1, 0.14), 0.8, bump=0.1, bump_scale=120)); P.append(cl)
    group("banner", P)
    # caveira com punhal e bordas de ouro no pano
    E = []
    sk = fuse([sph((0.78, -0.07, 2.2), 1, (0.26, 0.1, 0.24)), sph((0.78, -0.08, 1.98), 1, (0.17, 0.09, 0.1))], "skullb", 0.008); setmat(sk, mat("bone", BONE, 0.55)); E.append(sk)
    for sx in (-1, 1):
        o = sph((0.78 + sx * 0.09, -0.16, 2.22), 1, (0.065, 0.03, 0.08)); setmat(o, mat("socket", (0.05, 0.03, 0.06), 0.6)); E.append(o)
    for k in range(2):
        sw = box((0.78, -0.09, 1.62), (0.09, 0.04, 0.95), (0, 40 - k * 80, 0), bevel=0.01, taper=(0.5, 0.5)); hard(sw); setmat(sw, mat("bone", BONE, 0.55)); E.append(sw)
    group("emblem", E)
    # base: pedras empilhadas, lanças cruzadas e uma bandeirola
    B = []
    for (x, y, r) in ((0.0, 0.0, 0.42), (0.55, -0.2, 0.3), (-0.5, -0.1, 0.32), (0.2, -0.55, 0.26), (-0.25, 0.45, 0.25)):
        s = sph((x, y, r * 0.55), r, (1, 0.9, 0.7)); shade(s); setmat(s, mat("stone", STONE, 0.9, bump=0.4, bump_scale=14)); B.append(s)
    for sx in (-1, 1):
        ls = tube([(sx * 0.35, -0.3, 0.1), (sx * 0.9, -0.5, 1.3)], 0.025, 1.0, 8); setmat(ls, wood); B.append(ls)
        tp = box((sx * 0.9, -0.5, 1.45), (0.07, 0.03, 0.26), (0, sx * -22, 0), bevel=0.005, taper=(0.1, 0.1)); hard(tp); setmat(tp, mat("iron", (0.4, 0.4, 0.44), 0.4, 0.8)); B.append(tp)
    group("base", B)
    return {"kind": "structure", "dir": (0.32, -1.0, 0.22), "lens": 75}


SCENES_PLAGUE = {
    "rat_horde": rat_horde, "rabid_rats": rabid_rats, "pack_call": pack_call, "bat_nest": bat_nest, "slime": slime,
    "rat_king": rat_king, "werewolf": werewolf, "rat_brute": rat_brute, "infected_bite": infected_bite, "bat_cloud": bat_cloud,
    "rat_trap": rat_trap, "wolf_pack": wolf_pack, "brood_mother": brood_mother, "corrupt_piper": corrupt_piper,
    "sewer_flood": sewer_flood, "war_boar": war_boar, "hunt_instinct": hunt_instinct, "devour": devour,
    "bubonic_plague": bubonic_plague, "rat_tide": rat_tide, "mother_nest": mother_nest, "alpha_beast": alpha_beast,
    "endless_swarm": endless_swarm, "web": web, "ogre": ogre, "barricade": barricade, "war_banner": war_banner,
}
