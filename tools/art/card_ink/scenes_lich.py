"""Cenas das cartas do Lich (e comuns dark_forge, weakness_curse, dark_sacrifice, ruin_titan) para o render de nanquim.
Uso: CARD_SCENES=scenes_lich:SCENES_LICH blender -b --factory-startup -P render_cards.py -- <saída> [ids]
O ghoul é o da rodada A1 (scenes.ghoul, aprovado em v2)."""
import math
import bpy
from mathutils import Matrix, Vector
from mk import *
import chars, chars2, monsters, monsters2, creatures_lich
from scenes import place, flame, ghoul, DIRT, DIRT_D, STONE, BONE

PUR = (0.62, 0.3, 0.95)
PUR_D = (0.3, 0.1, 0.55)
GRN = (0.55, 1.0, 0.45)
ICE = (0.55, 0.85, 1.0)
SHADOW = (0.03, 0.02, 0.03)


# ------------------------------------------------------------------ peças comuns

def coarse(fn, vmin=0.022):
    """Constrói uma criatura do kit com voxel mais grosso (a malha fina do fantasma e dos capuzes trava o paint() em Python)."""
    import mk as _mk
    mods = [monsters, monsters2, chars, chars2]
    saved = [(m, m.fuse) for m in mods]
    orig = _mk.fuse

    def f(objs, name, voxel=0.012, smooth=0.6, iters=6):
        return orig(objs, name, max(voxel, vmin), smooth, iters)
    for m in mods:
        m.fuse = f
    try:
        return fn()
    finally:
        for m, o in saved:
            m.fuse = o



def glow(name, c, e=8.0):
    return mat(name, c, 0.4, emit=e)


def orb(loc, r, c=PUR, e=8.0, s=(1, 1, 1)):
    o = sph(loc, r, s); shade(o); setmat(o, glow("orb%s" % str(c), c, e)); return o


def beam(pts, r, c=PUR, taper=1.0, e=8.0):
    t = tube(pts, r, taper, 16); setmat(t, glow("beam%s" % str(c), c, e)); return t


def zigzag(a, b, n=6, amp=0.12, seed=1):
    a, b = Vector(a), Vector(b)
    pts = [tuple(a)]
    d = (b - a)
    side = d.cross(Vector((0, 0, 1))).normalized() if abs(d.normalized().z) < 0.9 else Vector((1, 0, 0))
    for i in range(1, n):
        t = i / n
        off = side * amp * (1 if (i + seed) % 2 else -1) * (1.0 - abs(t - 0.5))
        pts.append(tuple(a + d * t + off + Vector((0, 0, amp * 0.5 * ((i * 7 + seed) % 3 - 1)))))
    pts.append(tuple(b))
    return pts


def wisp(loc, s=1.0, c=GRN, lean=0.0):
    """Alma: gota com rostinho e rabo que sobe."""
    x, y, z = loc
    out = []
    b = sph(loc, 1, (0.11 * s, 0.09 * s, 0.14 * s)); shade(b); setmat(b, glow("wisp%s" % str(c), c, 5.0)); out.append(b)
    t = tube([(x, y, z + 0.08 * s), (x + 0.05 * s + lean * 0.05, y, z + 0.26 * s), (x - 0.03 * s + lean * 0.12, y, z + 0.46 * s)], 0.075 * s, 0.1, 10)
    setmat(t, glow("wisp%s" % str(c), c, 5.0)); out.append(t)
    for sx in (-1, 1):
        e = sph((x + sx * 0.04 * s, y - 0.085 * s, z + 0.02 * s), 1, (0.02 * s, 0.015 * s, 0.03 * s)); setmat(e, mat("shadow", SHADOW, 0.9)); out.append(e)
    return out


def tomb(loc, rot=0.0, s=1.0, lean=6):
    G = []
    st = mat("gravestone", STONE, 0.9, bump=0.4, bump_scale=14)
    x, y, z = loc
    slab = box((x, y, z + 0.5 * s), (0.62 * s, 0.14 * s, 0.9 * s), (lean * 0.5, lean, rot), bevel=0.04); hard(slab); setmat(slab, st); G.append(slab)
    top = cyl((x, y, z + 0.95 * s), 0.31 * s, 0.14 * s, rot=(96, lean, rot), seg=20, bevel=0.03); hard(top); setmat(top, st); G.append(top)
    return G


def mound(loc, size=(1.0, 0.8, 0.3), name="mound"):
    x, y, z = loc
    o = fuse([sph((x, y, z), 1, size), sph((x + size[0] * 0.5, y + size[1] * 0.2, z - 0.02), 1, (size[0] * 0.55, size[1] * 0.6, size[2] * 0.8)),
              sph((x - size[0] * 0.55, y - size[1] * 0.1, z - 0.02), 1, (size[0] * 0.5, size[1] * 0.6, size[2] * 0.7))], name, 0.03, smooth=0.6, iters=4)
    setmat(o, mat("soilf", DIRT_D, 0.95, bump=0.5, bump_scale=18)); return o


def skull_prop(loc, s=1.0, rot=0.0, eye=None):
    x, y, z = loc
    k = fuse([sph((x, y, z), 1, (0.12 * s, 0.13 * s, 0.11 * s)), sph((x, y - 0.06 * s, z - 0.07 * s), 1, (0.08 * s, 0.08 * s, 0.05 * s))], "skull", 0.008 * s + 0.003)
    setmat(k, mat("bone", BONE, 0.6)); out = [k]
    for sx in (-1, 1):
        e = sph((x + sx * 0.045 * s, y - 0.1 * s, z + 0.0), 1, (0.03 * s, 0.02 * s, 0.035 * s)); setmat(e, mat("shadow", SHADOW, 0.9)); out.append(e)
    return out


def bone_prop(a, b, r=0.03):
    a, b = Vector(a), Vector(b)
    ps = capsule(a, b, r) + [sph(a + (a - b).normalized() * 0.01, r * 1.7), sph(b, r * 1.7)]
    for o in ps: setmat(o, mat("bone", BONE, 0.6))
    return ps


def recolor(objs, c1, c2, e1=6.0, e2=9.0):
    for o in objs:
        if o.type == 'MESH' and o.material_slots and o.material_slots[0].material:
            n = o.material_slots[0].material.name
            if n.startswith("flame_core"): setmat(o, mat("pflame_core", c2, 0.4, emit=e2))
            elif n.startswith("flame"): setmat(o, mat("pflame", c1, 0.4, emit=e1))
    return objs


def spikes(center, n, r0, r1, w, c, axes="xz", e=8.0, seed=0):
    out = []
    cx, cy, cz = center
    for i in range(n):
        a = i / n * math.tau + seed
        ln = (r1 if i % 2 == 0 else r1 * 0.62)
        dx, dz = math.cos(a), math.sin(a)
        mid = (r0 + ln) / 2
        if axes == "xz":
            loc = (cx + dx * mid, cy, cz + dz * mid); rot = (0, -math.degrees(a) + 90, 0)
        else:
            loc = (cx + dx * mid, cy + dz * mid, cz); rot = (0, 0, math.degrees(a) - 90)
        b = box(loc, (w, w, ln - r0), rot, bevel=0, taper=(0.05, 0.05)); setmat(b, glow("sp%s" % str(c), c, e)); out.append(b)
    return out


def robed(robe_c, trim_c, pale=True):
    """Acólito: túnica azul com bainha clara, cabeça raspada de pele pálida, mãos à frente."""
    P = []
    rb = mat("acrobe", robe_c, 0.85, bump=0.15, bump_scale=100)
    body = fuse([sph((0, 0.02, 0.45), 1, (0.32, 0.3, 0.45)), sph((0, 0.0, 0.88), 1, (0.26, 0.22, 0.3)), sph((0, 0.04, 0.1), 1, (0.38, 0.36, 0.13))], "acbody", 0.012, 0.6, 5)
    setmat(body, rb); P.append(body)
    trim = torus((0, 0.04, 0.06), 0.36, 0.035, s=(1, 0.95, 1)); shade(trim); setmat(trim, mat("actrim", trim_c, 0.5)); P.append(trim)
    sash = box((0, -0.26, 0.6), (0.16, 0.04, 0.66), (0, 0, 0), bevel=0.01); hard(sash); setmat(sash, mat("actrim", trim_c, 0.5)); P.append(sash)
    head = fuse([sph((0, -0.02, 1.18), 1, (0.2, 0.19, 0.22)), sph((0, -0.1, 1.08), 1, (0.14, 0.12, 0.1))], "achead", 0.01)
    setmat(head, mat("acskin", (0.82, 0.72, 0.68), 0.6)); P.append(head)
    for sx in (-1, 1):
        e = sph((sx * 0.07, -0.2, 1.17), 1, (0.035, 0.02, 0.045)); setmat(e, glow("acglow", (0.6, 0.85, 1.0), 6.0)); P.append(e)
        a = capsule((sx * 0.24, -0.02, 0.9), (sx * 0.18, -0.34, 0.76), 0.08, 0.1)
        for o in a: setmat(o, rb)
        P += a
    mk_ = sph((0, -0.2, 1.3), 1, (0.05, 0.02, 0.05)); setmat(mk_, glow("acglow", (0.6, 0.85, 1.0), 6.0)); P.append(mk_)   # marca na testa
    return group("acolyte", P)


# ------------------------------------------------------------------ 1. Legião de Ossos

def bone_legion():
    spots = [(-1.3, 0.0, -8), (0.0, -0.1, 5), (1.3, 0.05, -4), (-0.65, 1.0, 10), (0.65, 1.05, -12), (1.95, 1.0, 6)]
    for i, (x, y, rz) in enumerate(spots):
        place(monsters.skeleton(archer=False), (x, y, 0), rot_z=rz, scale=0.95 if y > 0.5 else 1.0)
    G = [mound((-0.2, -0.6, -0.02), (2.8, 0.5, 0.08))]
    for (x, y) in ((-2.0, -0.7), (2.3, -0.5), (0.4, -1.0)):
        G += skull_prop((x, y, 0.1), 1.0)
    group("rubble", G)
    return {"kind": "swarm", "dir": (0.4, -1.0, 0.22)}


# ------------------------------------------------------------------ 2. Esqueletos Arqueiros

def skeleton_archers():
    place(monsters.skeleton(archer=True), (1.2, 0.8, 0), rot_z=-90 + 8)
    place(monsters.skeleton(archer=True), (1.4, -0.6, 0), rot_z=-90 - 6, scale=0.97)
    P = []
    wood = mat("wood", (0.45, 0.27, 0.13), 0.8)
    sh = cyl((-0.2, -0.1, 1.15), 0.012, 1.0, rot=(0, 90, 0), seg=6, bevel=0); setmat(sh, wood); P.append(sh)
    hd = box((-0.75, -0.1, 1.15), (0.1, 0.03, 0.14), (0, 90, 0), bevel=0.004, taper=(0.1, 1)); hard(hd); setmat(hd, mat("iron", (0.42, 0.43, 0.47), 0.5, 0.8)); P.append(hd)
    for dz in (-1, 1):
        f = box((0.25, -0.1, 1.15 + dz * 0.035), (0.14, 0.01, 0.07), (0, 0, 0), bevel=0.002); setmat(f, mat("feather", (0.95, 0.9, 0.85), 0.7)); P.append(f)
    P += recolor(flame((-0.75, -0.1, 1.05), h=0.6, r=0.14, lean=(0.7, 0.0)), FLAME_C, FLAME_H)
    for (dx, dz, r) in ((0.3, 0.2, 0.025), (0.55, 0.4, 0.02), (0.1, 0.55, 0.02)):
        s_ = sph((-0.6 + dx, -0.1, 1.1 + dz), r); setmat(s_, glow("ember", FLAME_C, 6.0)); P.append(s_)
    group("arrow", P)
    return {"kind": "monster", "dir": (-0.55, -1.0, 0.2)}


FLAME_C = (1.0, 0.55, 0.12)
FLAME_H = (1.0, 0.9, 0.45)


# ------------------------------------------------------------------ 3. Servo Reanimado

def raised_servant():
    place(monsters.skeleton(archer=False), (0, 0, -0.5), rot_z=-8)
    G = [mound((0, 0.1, -0.05), (1.1, 0.95, 0.22), "m1")]
    G += tomb((0.95, 0.8, -0.05), rot=-14, s=1.0, lean=9)
    for (x, y, z, r) in ((-0.9, -0.5, 0.12, 0.09), (0.9, -0.55, 0.2, 0.07), (-0.55, -0.85, 0.05, 0.1), (0.5, -0.9, 0.04, 0.12), (1.25, -0.2, 0.08, 0.06)):
        c = sph((x, y, z), r, (1, 0.9, 0.8)); shade(c); setmat(c, mat("soilf", DIRT_D, 0.95, bump=0.5, bump_scale=18)); G.append(c)
    G += skull_prop((-1.1, -0.3, 0.08), 0.8)
    G += bone_prop((-1.5, -0.8, 0.04), (-1.15, -0.95, 0.04))
    # luz verde de dentro da cova
    g = sph((0, -0.7, 0.18), 1, (0.55, 0.12, 0.1)); setmat(g, glow("gg", GRN, 4.0)); G.append(g)
    group("grave", G)
    return {"kind": "monster", "dir": (0.45, -1.0, 0.3)}


# ------------------------------------------------------------------ 4. Raio Sombrio (shadow_bolt)

def shadow_bolt():
    P = []
    wood = mat("wood", (0.45, 0.27, 0.13), 0.8, bump=0.4, bump_scale=25)
    iron = mat("iron", (0.42, 0.43, 0.47), 0.5, metal=0.7)
    disc = cyl((0, 0, 1.05), 0.85, 0.12, rot=(90, 0, 0), seg=40, bevel=0.025); hard(disc); setmat(disc, wood); P.append(disc)
    rim = torus((0, 0, 1.05), 0.85, 0.045, (90, 0, 0)); shade(rim); setmat(rim, iron); P.append(rim)
    for k in (-1, 0, 1):
        pl = box((k * 0.28, -0.07, 1.05), (0.02, 0.02, 1.5), (0, 0, 0), bevel=0.003); setmat(pl, mat("woodd", (0.28, 0.16, 0.08), 0.8)); P.append(pl)
    bo = sph((0, -0.1, 1.05), 0.2, (1, 0.5, 1)); setmat(bo, iron); P.append(bo)
    # buraco queimado
    ring = torus((0, -0.075, 1.05), 0.19, 0.04, (90, 0, 0)); shade(ring); setmat(ring, mat("char", (0.05, 0.04, 0.05), 0.9)); P.append(ring)
    # o raio atravessa: núcleo claro + bainha roxa irregular + farpas
    P.append(beam(zigzag((0.0, 3.2, 1.05), (0.0, -3.2, 1.05), 9, 0.2), 0.07, PUR, 1.0))
    P.append(beam(zigzag((0.0, 3.0, 1.05), (0.0, -3.0, 1.05), 9, 0.1, 2), 0.04, (0.95, 0.9, 1.0), 1.0, 10.0))
    for i, (y, a) in enumerate(((-2.4, 40), (-1.6, -50), (-0.9, 70), (1.4, -35), (2.1, 55), (0.8, 20))):
        b = beam([(0, y, 1.05), (0.28 * math.cos(math.radians(a)), y - 0.05, 1.05 + 0.28 * math.sin(math.radians(a)))], 0.035, PUR_D, 0.2); P.append(b)
    # estilhaços de madeira voando
    for (x, y, z, a) in ((0.9, -0.25, 1.9, 30), (-0.8, -0.3, 1.7, -50), (0.6, -0.4, 0.4, 70), (-0.7, -0.2, 0.5, 10)):
        s = box((x, y, z), (0.07, 0.03, 0.22), (a, a, a), bevel=0.004, taper=(0.3, 1)); setmat(s, wood); P.append(s)
    group("bolt", P)
    return {"kind": "spell", "dir": (0.8, -1.0, 0.12), "hatch": 22.0}


# ------------------------------------------------------------------ 5. Faísca Arcana

def arcane_spark():
    P = [orb((0, 0, 1.0), 0.28, (0.8, 0.95, 1.0), 10.0)]
    P += spikes((0, 0, 1.0), 8, 0.2, 0.75, 0.09, ICE, "xz", 8.0)
    P += spikes((0, 0, 1.0), 8, 0.32, 0.5, 0.05, (0.7, 0.8, 1.0), "xz", 8.0, seed=0.2)
    for i, (x, z, r) in enumerate(((-0.95, 0.6, 0.07), (0.85, 1.55, 0.06), (1.1, 0.7, 0.045), (-0.7, 1.55, 0.04), (0.2, 0.2, 0.035), (-0.2, 1.85, 0.03))):
        P.append(orb((x, 0.0, z), r, ICE, 8.0))
    # rastro de faíscas anteriores: três estrelinhas menores empilhadas atrás
    for (x, y, z, r) in ((-1.1, 0.6, 0.45, 0.14), (-1.6, 1.2, 0.2, 0.1), (-2.0, 1.8, 0.0, 0.07)):
        P.append(orb((x, y, z), r, (0.6, 0.7, 1.0), 6.0))
        P += spikes((x, y, z), 6, r * 0.7, r * 2.6, r * 0.5, (0.55, 0.65, 1.0), "xz", 6.0)
    P.append(beam([(-0.3, 0.15, 0.95), (-0.8, 0.45, 0.6), (-1.1, 0.6, 0.45)], 0.04, ICE, 0.5))
    P.append(beam([(-1.1, 0.6, 0.45), (-1.6, 1.2, 0.2)], 0.025, ICE, 0.5))
    # círculo arcano que o gera
    c = torus((0, 0.35, 1.0), 1.15, 0.025, (90, 0, 0)); shade(c); setmat(c, glow("ring", (0.55, 0.65, 1.0), 5.0)); P.append(c)
    group("spark", P)
    return {"kind": "spell", "dir": (0.4, -1.0, 0.1), "hatch": 20.0}


# ------------------------------------------------------------------ 6. Acólitos

def acolyte():
    a = robed((0.14, 0.2, 0.46), (0.85, 0.82, 0.7))
    place(a, (-0.5, 0.2, 0), rot_z=-16)
    b = robed((0.2, 0.16, 0.42), (0.75, 0.62, 0.85))
    place(b, (0.7, -0.5, 0), rot_z=14, scale=0.92)
    P = []
    # um orbe em cada par de mãos e o disparo saindo
    P.append(orb((-0.78, -0.7, 0.88), 0.14, PUR, 8.0))
    P.append(beam([(-0.78, -0.75, 0.88), (-1.3, -1.35, 0.95), (-2.0, -2.2, 1.0)], 0.045, PUR, 0.2))
    P.append(orb((0.85, -1.1, 0.8), 0.12, (0.6, 0.85, 1.0), 8.0))
    P.append(beam([(0.85, -1.15, 0.8), (1.4, -1.8, 0.9), (2.1, -2.6, 1.0)], 0.04, (0.6, 0.85, 1.0), 0.2))
    P += spikes((-0.78, -0.7, 0.88), 6, 0.1, 0.28, 0.04, PUR, "xz", 8.0)
    group("shots", P)
    return {"kind": "monster", "dir": (0.15, -1.0, 0.16)}


# ------------------------------------------------------------------ 7. Explosão de Cadáver

def corpse_blast():
    P = []
    P.append(orb((0, 0, 1.0), 0.5, (0.9, 1.0, 0.55), 9.0))
    P += spikes((0, 0, 1.0), 12, 0.4, 1.35, 0.17, (0.7, 1.0, 0.25), "xz", 7.0)
    P += spikes((0, 0, 1.0), 10, 0.55, 1.0, 0.1, (0.95, 1.0, 0.5), "xz", 8.0, seed=0.3)
    for a in (0.5, 1.9, 3.3, 4.6):
        P.append(beam([(0, 0, 1.0), (math.cos(a) * 1.0, 0.55, 1.0 + math.sin(a) * 0.9), (math.cos(a) * 1.7, 0.7, 1.0 + math.sin(a) * 1.5)], 0.09, (0.5, 0.85, 0.2), 0.1, 6.0))
    # restos que voam: crânio, costelas, ossos, elmo
    P += skull_prop((1.3, -0.5, 1.8), 1.5)
    P += skull_prop((-1.6, -0.3, 0.55), 1.1)
    P += bone_prop((-1.2, -0.4, 1.9), (-0.7, -0.4, 1.55), 0.04)
    P += bone_prop((1.1, -0.3, 0.3), (1.55, -0.3, 0.55), 0.04)
    P += bone_prop((0.2, -0.5, 2.2), (0.55, -0.5, 2.0), 0.035)
    for (x, z, a) in ((1.7, 1.1, 20), (-1.3, 1.5, -30)):
        rib = torus((x, -0.35, z), 0.2, 0.03, (a, 90, 0), s=(1, 1, 0.6)); shade(rib); setmat(rib, mat("bone", BONE, 0.6)); P.append(rib)
    hel = sph((0.5, -0.4, 0.05), 1, (0.2, 0.2, 0.14)); setmat(hel, mat("iron", (0.42, 0.43, 0.47), 0.5, 0.8)); P.append(hel)
    # crateras de terra e fumaça
    m = mound((0, 0.2, -0.04), (1.8, 0.8, 0.07)); P.append(m)
    group("blast", P)
    return {"kind": "spell", "dir": (0.35, -1.0, 0.16), "hatch": 22.0}


# ------------------------------------------------------------------ 8. Cultistas

def cultists():
    c1 = coarse(monsters2.cultists); place(c1, (-0.7, 0.1, 0), rot_z=24)
    c2 = coarse(monsters2.cultists); place(c2, (0.75, 0.0, 0), rot_z=-22, scale=0.94)
    c3 = coarse(monsters2.cultists); place(c3, (0.05, 0.9, 0), rot_z=2, scale=0.88)
    P = []
    # livro de feitiços flutuando no meio, com brilho roxo, e fagulhas
    bk = box((0.0, -0.42, 0.95), (0.42, 0.08, 0.3), (20, 0, 0), bevel=0.015); hard(bk); setmat(bk, mat("book", (0.12, 0.1, 0.12), 0.6)); P.append(bk)
    pg = box((0.0, -0.46, 0.99), (0.36, 0.04, 0.26), (20, 0, 0), bevel=0.004); setmat(pg, mat("page", (0.92, 0.86, 0.68), 0.8)); P.append(pg)
    P.append(orb((0.0, -0.5, 1.28), 0.07, (0.95, 0.35, 0.8), 8.0))
    for (x, z, r) in ((-0.2, 1.5, 0.03), (0.22, 1.42, 0.025), (0.1, 1.7, 0.02)):
        P.append(orb((x, -0.5, z), r, (0.95, 0.35, 0.8), 8.0))
    # moedas de elixir cortadas ao meio no chão (feitiços mais baratos)
    for (x, y) in ((-0.2, -0.75), (0.25, -0.8)):
        cn = cyl((x, y, 0.025), 0.07, 0.025, seg=14, bevel=0.004); setmat(cn, mat("gold", (1.0, 0.72, 0.28), 0.3, 1.0)); P.append(cn)
    group("book", P)
    return {"kind": "monster", "dir": (0.18, -1.0, 0.16)}


# ------------------------------------------------------------------ 9. Marca Sombria

def shadow_mark():
    k = coarse(chars.knight); place(k, (0, 0, 0), rot_z=-10)
    P = []
    cz = 1.1
    for R, r in ((1.25, 0.045), (0.95, 0.03), (0.65, 0.025)):
        t = torus((0, 0.45, cz), R, r, (90, 0, 0)); shade(t); setmat(t, glow("mk%s" % R, PUR, 7.0)); P.append(t)
    P += spikes((0, 0.45, cz), 4, 0.5, 1.7, 0.05, PUR, "xz", 7.0, seed=0.0)
    for i in range(8):
        a = i / 8 * math.tau + 0.2
        tk = box((math.cos(a) * 1.1, 0.45, cz + math.sin(a) * 1.1), (0.04, 0.04, 0.2), (0, -math.degrees(a) + 90, 0), bevel=0); setmat(tk, glow("mk", PUR, 7.0)); P.append(tk)
    eye = sph((0, 0.45, cz), 1, (0.32, 0.03, 0.18)); setmat(eye, glow("mk", PUR, 7.0)); P.append(eye)
    pu = sph((0, 0.41, cz), 1, (0.09, 0.03, 0.14)); setmat(pu, mat("shadow", SHADOW, 0.9)); P.append(pu)
    # gotas sombrias escorrendo
    for (x, z, r) in ((-0.7, 0.35, 0.05), (0.5, 0.55, 0.06), (0.95, 0.25, 0.04), (-0.2, 0.15, 0.035)):
        d = sph((x, 0.35, z), 1, (r, r, r * 1.6)); setmat(d, glow("mkd", PUR_D, 5.0)); P.append(d)
    group("mark", P)
    return {"kind": "spell", "dir": (0.15, -1.0, 0.1), "hatch": 22.0}


# ------------------------------------------------------------------ 10. Fantasma

def ghost():
    g = coarse(monsters.ghost); place(g, (0.5, 0.0, 0.0), rot_z=-12, scale=1.2)
    gb = coarse(chars2.goblin); place(gb, (-1.2, -0.55, 0.0), rot_z=-65, scale=0.85)
    P = []
    # gotas de suor e riscos de pânico do goblin
    for (x, z) in ((-1.5, 1.55), (-1.0, 1.7), (-1.7, 1.2)):
        d = sph((x, -0.9, z), 1, (0.03, 0.02, 0.05)); setmat(d, mat("sweat", ICE, 0.3, emit=2.0)); P.append(d)
    # parede de pedra que ele atravessa, atrás
    wall = box((0.4, 0.9, 0.8), (3.6, 0.3, 1.6), bevel=0.03); hard(wall); setmat(wall, mat("brickw", (0.5, 0.48, 0.46), 0.9, bump=0.5, bump_scale=14)); P.append(wall)
    for (x, z) in ((-1.0, 0.4), (0.2, 0.8), (1.4, 0.4), (0.8, 1.3), (-0.6, 1.2)):
        br = box((x, 0.74, z), (0.72, 0.02, 0.34), bevel=0.01); setmat(br, mat("brickl", (0.36, 0.34, 0.33), 0.9)); P.append(br)
    group("wall", P)
    return {"kind": "monster", "dir": (0.3, -1.0, 0.16)}


# ------------------------------------------------------------------ 11. Totem de Ossos

def bone_totem():
    t = coarse(monsters2.bone_totem, 0.035); place(t, (0, 0, 0), rot_z=-10)
    sk1 = monsters.skeleton(archer=False); place(sk1, (-1.1, -0.5, -0.5), rot_z=20, scale=0.85)
    sk2 = monsters.skeleton(archer=True); place(sk2, (1.1, -0.3, -0.45), rot_z=-15, scale=0.8)
    G = [mound((-1.1, -0.2, 0.0), (0.8, 0.7, 0.28), "m1"), mound((1.1, 0.0, 0.0), (0.75, 0.65, 0.25), "m2")]
    for (x, y, r) in ((-0.6, -1.0, 0.1), (0.6, -0.9, 0.08), (1.7, -0.6, 0.1), (-1.8, -0.4, 0.07)):
        c = sph((x, y, r * 0.6), r, (1, 0.9, 0.7)); shade(c); setmat(c, mat("stone", STONE, 0.9)); G.append(c)
    for a in (0.3, 1.2, 2.1):
        G.append(orb((math.cos(a * 3) * 0.55, -0.4 + math.sin(a * 3) * 0.2, 0.4 + a * 0.5), 0.04, GRN, 8.0))
    group("ground", G)
    return {"kind": "structure", "dir": (0.4, -1.0, 0.22)}


# ------------------------------------------------------------------ 12. Banquete de Almas

def soul_feast():
    P = []
    cloth = mat("cloth", (0.5, 0.12, 0.2), 0.9, bump=0.2, bump_scale=40)
    top = cyl((0, 0, 0.78), 0.95, 0.08, seg=40, bevel=0.02); hard(top); setmat(top, mat("woodd", (0.3, 0.2, 0.13), 0.8, bump=0.4, bump_scale=10)); P.append(top)
    dr = cyl((0, 0, 0.6), 1.0, 0.38, seg=40, bevel=0.03, r2=1.06); hard(dr); setmat(dr, cloth); P.append(dr)
    for k in range(10):
        a = k / 10 * math.tau
        f = box((math.cos(a) * 1.04, math.sin(a) * 1.04, 0.42), (0.18, 0.04, 0.12), (0, 0, math.degrees(a)), bevel=0.004, taper=(0.4, 1)); setmat(f, cloth); P.append(f)
    leg = cyl((0, 0, 0.2), 0.2, 0.4, seg=20, bevel=0.02, r2=0.3); hard(leg); setmat(leg, mat("woodd", (0.3, 0.2, 0.13), 0.8)); P.append(leg)
    pl = cyl((0, -0.1, 0.9), 0.55, 0.05, seg=36, bevel=0.015, r2=0.5); hard(pl); setmat(pl, mat("iron", (0.55, 0.56, 0.6), 0.4, 0.8)); P.append(pl)
    # almas servidas na travessa e sobem pelo garfo
    for (x, z, s, l) in ((-0.28, 1.02, 1.0, -0.4), (0.12, 1.1, 1.15, 0.2), (0.35, 1.0, 0.85, 0.5), (-0.05, 1.45, 0.8, -0.2)):
        P += wisp((x, -0.1, z), s, GRN, l)
    # taças de caveira e candelabro de chama verde
    for x in (-0.7, 0.7):
        cp = cyl((x, -0.4, 0.92), 0.1, 0.18, seg=16, bevel=0.01, r2=0.07); hard(cp); setmat(cp, mat("bone", BONE, 0.6)); P.append(cp)
        lq = cyl((x, -0.4, 1.0), 0.075, 0.02, seg=16, bevel=0); setmat(lq, glow("gg", GRN, 5.0)); P.append(lq)
    cd = cyl((0.0, 0.6, 1.0), 0.04, 0.45, seg=10, bevel=0.005); hard(cd); setmat(cd, mat("iron", (0.55, 0.56, 0.6), 0.4, 0.8)); P.append(cd)
    for dx in (-0.3, 0, 0.3):
        c = cyl((dx, 0.6, 1.3), 0.035, 0.1, seg=8, bevel=0.004); setmat(c, mat("candle", (0.95, 0.9, 0.78), 0.6)); P.append(c)
        P.append(orb((dx, 0.6, 1.42), 1, GRN, 8.0, (0.035, 0.035, 0.07)))
    bar = box((0, 0.6, 1.24), (0.7, 0.03, 0.03), bevel=0.003); hard(bar); setmat(bar, mat("iron", (0.55, 0.56, 0.6), 0.4, 0.8)); P.append(bar)
    group("table", P)
    sk = monsters.skeleton(archer=False); place(sk, (0.0, 1.0, 0.0), rot_z=180, scale=1.15)
    # babador de guardanapo no esqueleto
    return {"kind": "spell", "dir": (0.3, -1.0, 0.3), "hatch": 22.0}


# ------------------------------------------------------------------ 13. Colheita de Almas

def soul_harvest():
    P = []
    wood = mat("woodd", (0.3, 0.2, 0.13), 0.8, bump=0.4, bump_scale=10)
    shaft = tube([(0.5, 0, 0.0), (0.45, 0, 1.0), (0.4, 0, 2.2)], 0.045, 1.0, 12); setmat(shaft, wood); P.append(shaft)
    bl = tube([(0.4, 0, 2.2), (0.0, 0, 2.55), (-0.6, 0, 2.5), (-1.15, 0, 2.15)], 0.14, 0.12, 20)
    bl.scale = (1.0, 0.3, 1.0); bpy.context.view_layer.update()
    setmat(bl, mat("scythe", (0.7, 0.72, 0.8), 0.3, 0.9)); P.append(bl)
    for z in (1.1, 1.5):
        gr = box((0.45, -0.06, z), (0.1, 0.1, 0.14), (0, 0, 0), bevel=0.01); hard(gr); setmat(gr, mat("iron", (0.42, 0.43, 0.47), 0.5, 0.8)); P.append(gr)
    P.append(mound((0.5, 0.0, 0.0), (1.1, 0.8, 0.14)))
    # almas subindo em espiral e moedas de elixir
    for i in range(7):
        a = i * 0.95; h = 0.5 + i * 0.28
        P += wisp((0.5 + math.cos(a) * (0.9 - i * 0.05), -0.1 + math.sin(a) * 0.5, h), 0.75 + 0.05 * (i % 3), GRN, 0.0)
    for (x, z, r) in ((-1.2, 1.1, 0.07), (-0.9, 1.5, 0.06), (1.6, 1.9, 0.07), (1.3, 1.3, 0.05)):
        cn = cyl((x, -0.1, z), r, r * 0.35, rot=(80, 0, 0), seg=14, bevel=0.004); setmat(cn, glow("coin", (1.0, 0.82, 0.3), 3.0)); P.append(cn)
    P += skull_prop((-0.5, -0.9, 0.1), 1.3)
    P += skull_prop((1.4, -0.5, 0.08), 1.0)
    group("harvest", P)
    return {"kind": "lair", "dir": (0.4, -1.0, 0.1)}


# ------------------------------------------------------------------ 14. Golem de Sucata

def scrap_golem():
    g = monsters2.scrap_golem(); place(g, (0, 0, 0), rot_z=-10)
    P = []
    plate = lambda c: mat("plate_%s" % str(c), c, 0.6, 0.7)
    # sucata atraída: chapas, engrenagens, um capacete e ossos voando para o peito
    for (x, y, z, sz, rot, c) in ((-1.8, -0.8, 1.8, (0.4, 0.05, 0.3), (20, 10, 30), (0.5, 0.45, 0.4)), (-1.5, 0.1, 0.9, (0.3, 0.05, 0.4), (-30, 0, 15), (0.62, 0.36, 0.22)),
                                  (-2.3, -0.2, 1.3, (0.25, 0.05, 0.25), (10, 40, 60), (0.36, 0.42, 0.48)), (1.9, -0.9, 2.2, (0.35, 0.05, 0.25), (-20, 10, -20), (0.5, 0.45, 0.4))):
        s = box((x, y, z), sz, rot, bevel=0.015); hard(s); setmat(s, plate(c)); P.append(s)
    for (x, y, z, R) in ((-1.0, -1.2, 2.3, 0.2), (1.5, -0.2, 0.6, 0.15)):
        gr = torus((x, y, z), R, R * 0.35, (80, 0, 30)); shade(gr); setmat(gr, mat("ironn", (0.42, 0.43, 0.47), 0.5, 0.8)); P.append(gr)
        for k in range(8):
            a = k / 8 * math.tau
            t = box((x + math.cos(a) * R * 1.3, y, z + math.sin(a) * R * 1.3 * 0.2 + math.sin(a) * R * 0.4), (R * 0.4, R * 0.4, R * 0.35), (80, 0, 30), bevel=0.004); setmat(t, mat("ironn", (0.42, 0.43, 0.47), 0.5, 0.8)); P.append(t)
    P += bone_prop((-1.9, -1.0, 2.6), (-1.4, -1.0, 2.3), 0.04)
    P += skull_prop((-0.9, -1.4, 1.6), 1.1)
    for (x0, z0) in ((-1.9, 1.7), (-1.5, 0.95), (-1.0, 2.3)):
        P.append(beam([(x0 - 0.35, -0.8, z0 + 0.1), (x0 - 0.1, -0.8, z0 + 0.02)], 0.012, (1.0, 0.5, 0.12), 0.5, 4.0))
    # pilha de sucata e ossos aos pés
    P.append(mound((-0.9, 0.3, -0.03), (1.2, 0.6, 0.08)))
    for (x, y, a) in ((-1.5, 0.4, 30), (-0.6, 0.6, -20), (-1.1, 0.0, 60)):
        s = box((x, y, 0.12), (0.5, 0.35, 0.08), (0, 0, a), bevel=0.01); hard(s); setmat(s, plate((0.55, 0.3, 0.18))); P.append(s)
    group("scrap", P)
    return {"kind": "monster", "dir": (0.25, -1.0, 0.16)}


# ------------------------------------------------------------------ 15. Eco Sombrio

def shadow_echo():
    P = []
    cz = 1.0
    # fonte: orbe sombrio com núcleo claro; ondas concêntricas que se afastam e dois ecos menores
    P.append(orb((0, 0, cz), 0.38, (0.95, 0.88, 1.0), 9.0))
    core = sph((0, -0.04, cz), 1, (0.44, 0.44, 0.44)); shade(core); setmat(core, glow("echoc", PUR_D, 4.0)); P.append(core)
    for i, R in enumerate((0.6, 0.9, 1.25, 1.65)):
        t = torus((0, 0.15 * i, cz), R, 0.045 - i * 0.008, (90, 0, 0)); shade(t); setmat(t, glow("echor%d" % i, PUR, 7.0 - i)); P.append(t)
    for (x, y, z, r) in ((-1.9, 0.5, 0.45, 0.22), (-2.8, 1.1, 0.0, 0.14)):
        P.append(orb((x, y, z), r, PUR, 7.0))
        c2 = sph((x, y - 0.02, z), 1.0 * r * 1.05); shade(c2); setmat(c2, glow("echoc", PUR_D, 4.0)); P.append(c2)
        P += spikes((x, y, z), 6, r * 1.1, r * 2.4, r * 0.3, PUR, "xz", 6.0)
        for k in (1, 2):
            t = torus((x, y + 0.1 * k, z), r * (1.4 + 0.7 * k), 0.025, (90, 0, 0)); shade(t); setmat(t, glow("echor", PUR, 5.0)); P.append(t)
    P.append(beam([(-0.5, 0.0, cz), (-1.2, 0.3, 0.75), (-1.9, 0.5, 0.45)], 0.05, PUR, 0.3))
    P.append(beam([(-2.0, 0.55, 0.4), (-2.4, 0.8, 0.2), (-2.8, 1.1, 0.0)], 0.035, PUR, 0.3))
    P += spikes((0, 0, cz), 8, 0.5, 1.05, 0.08, (0.85, 0.7, 1.0), "xz", 8.0)
    group("echo", P)
    return {"kind": "spell", "dir": (0.5, -1.0, 0.08), "hatch": 22.0}


# ------------------------------------------------------------------ 16. Biblioteca Proibida

def forbidden_library():
    P = []
    wd = mat("woodd", (0.3, 0.2, 0.13), 0.8, bump=0.4, bump_scale=10)
    for x in (-1.5, 1.5):
        s = box((x, 0.5, 1.5), (0.14, 0.6, 3.0), bevel=0.02); setmat(s, wd); P.append(s)
    tp = box((0, 0.5, 3.05), (3.3, 0.7, 0.16), bevel=0.03); setmat(tp, wd); P.append(tp)
    bk = box((0, 0.76, 1.5), (3.0, 0.06, 3.0), bevel=0); setmat(bk, mat("woodv", (0.18, 0.12, 0.08), 0.8)); P.append(bk)
    cols = [(0.5, 0.1, 0.12), (0.12, 0.2, 0.46), (0.14, 0.38, 0.2), (0.45, 0.3, 0.1), (0.3, 0.12, 0.42), (0.1, 0.1, 0.12), (0.55, 0.45, 0.15)]
    n = 0
    for zi, z0 in enumerate((0.2, 1.0, 1.8, 2.5)):
        sh = box((0, 0.5, z0), (3.0, 0.6, 0.07), bevel=0.01); setmat(sh, wd); P.append(sh)
        x = -1.35
        while x < 1.3:
            w = 0.1 + ((n * 7) % 5) * 0.03; h = 0.45 + ((n * 5) % 4) * 0.08
            if zi == 1 and 0.0 < x < 0.5:
                x += 0.5; continue                       # vão: o livro que fugiu
            b = box((x + w / 2, 0.38, z0 + 0.035 + h / 2), (w, 0.38, h), (0, 0, ((n * 11) % 7 - 3) * 1.4), bevel=0.006); setmat(b, mat("bk%d" % (n % 7), cols[n % 7], 0.7)); P.append(b)
            if n % 3 == 0:
                bd = box((x + w / 2, 0.18, z0 + 0.035 + h * 0.65), (w * 1.05, 0.02, 0.05), bevel=0); setmat(bd, mat("gold", (1.0, 0.72, 0.28), 0.3, 1.0)); P.append(bd)
            x += w + 0.01; n += 1
    # livro grande acorrentado e brilhando num atril
    sd = cyl((0, -0.9, 0.55), 0.09, 1.1, seg=10, bevel=0.01, r2=0.14); hard(sd); setmat(sd, wd); P.append(sd)
    ds = box((0, -0.9, 1.15), (1.0, 0.7, 0.07), (-28, 0, 0), bevel=0.02); hard(ds); setmat(ds, wd); P.append(ds)
    bk2 = box((0, -0.93, 1.27), (0.85, 0.5, 0.14), (-28, 0, 0), bevel=0.03); hard(bk2); setmat(bk2, mat("book", (0.14, 0.08, 0.2), 0.6)); P.append(bk2)
    pg = box((0, -1.02, 1.32), (0.7, 0.4, 0.04), (-28, 0, 0), bevel=0.004); setmat(pg, glow("pg", PUR, 3.0)); P.append(pg)
    for sx in (-1, 1):
        ch = tube([(sx * 0.4, -0.95, 1.3), (sx * 0.9, -1.05, 1.0), (sx * 1.1, -1.0, 0.35)], 0.025, 1.0, 12); setmat(ch, mat("iron", (0.42, 0.43, 0.47), 0.5, 0.8)); P.append(ch)
        for k in range(5):
            l = torus((sx * (0.55 + 0.1 * k), -0.98 - 0.02 * k, 1.2 - 0.17 * k), 0.035, 0.012, (0, 90 * (k % 2), 0)); shade(l); setmat(l, mat("iron", (0.42, 0.43, 0.47), 0.5, 0.8)); P.append(l)
    lk = box((0, -1.04, 1.22), (0.12, 0.06, 0.14), (-28, 0, 0), bevel=0.015); hard(lk); setmat(lk, mat("gold", (1.0, 0.72, 0.28), 0.3, 1.0)); P.append(lk)
    P += spikes((0, -1.1, 1.45), 6, 0.1, 0.35, 0.04, PUR, "xz", 6.0)
    for (x, z, a) in ((-0.8, 1.9, 20), (0.7, 2.1, -25), (-0.3, 2.5, 40)):
        pgs = box((x, -0.5, z), (0.22, 0.015, 0.3), (10, a, 20), bevel=0.004); setmat(pgs, mat("page", (0.92, 0.86, 0.68), 0.8)); P.append(pgs)
    group("library", P)
    return {"kind": "lair", "dir": (0.35, -1.0, 0.22)}


# ------------------------------------------------------------------ 17. Dreno de Vida

def life_drain():
    kn = chars.knight(); place(kn, (-1.7, 0.0, 0.0), rot_z=-30, scale=0.95)
    sk = monsters.skeleton(archer=False); place(sk, (1.6, 0.0, 0.0), rot_z=30)
    P = []
    for i, amp in enumerate((0.45, -0.35, 0.2)):
        pts = []
        for k in range(8):
            t = k / 7
            pts.append((-1.3 + t * 2.55, -0.45 - 0.0, 1.0 + 0.2 * math.sin(t * 6.28 + i * 2.1) * (amp * 2) + 0.08 * i - 0.1))
        P.append(beam(pts, 0.05 - i * 0.01, GRN if i != 1 else (0.75, 1.0, 0.55), 0.7, 7.0))
    for (t, i, r) in ((0.15, 0, 0.1), (0.4, 1, 0.08), (0.6, 0, 0.09), (0.82, 2, 0.07), (0.3, 2, 0.06)):
        P.append(orb((-1.3 + t * 2.55, -0.45, 1.0 + 0.2 * math.sin(t * 6.28 + i * 2.1) * (0.9 if i == 0 else -0.7 if i == 1 else 0.4)), r, (0.75, 1.0, 0.55), 8.0))
    # cruzes de cura sobre o esqueleto
    for (x, z, s) in ((1.2, 2.0, 0.09), (1.9, 2.15, 0.07), (1.55, 2.4, 0.06)):
        P.append(box((x, -0.3, z), (s * 3.0, 0.03, s), bevel=0.0)); P[-1].data.materials.append(glow("cross", GRN, 6.0))
        P.append(box((x, -0.3, z), (s, 0.03, s * 3.0), bevel=0.0)); P[-1].data.materials.append(glow("cross", GRN, 6.0))
    # a mão sombria que puxa do peito do herói
    ring = torus((-1.45, -0.3, 1.1), 0.28, 0.03, (90, 0, 0)); shade(ring); setmat(ring, glow("dr", PUR, 6.0)); P.append(ring)
    group("drain", P)
    return {"kind": "spell", "dir": (0.1, -1.0, 0.1), "hatch": 22.0}


# ------------------------------------------------------------------ 18. Ritual Profano

def profane_ritual():
    P = []
    dk = mat("shadow", SHADOW, 0.9)
    base = cyl((0, 0, 0.02), 1.9, 0.05, seg=48, bevel=0.01); setmat(base, mat("slate", (0.28, 0.26, 0.3), 0.9, bump=0.4, bump_scale=14)); P.append(base)
    for R, r in ((1.75, 0.04), (1.35, 0.025)):
        t = torus((0, 0, 0.06), R, r, (0, 0, 0)); shade(t); setmat(t, glow("pr", PUR, 6.0)); P.append(t)
    verts = [(math.cos(math.radians(90 + 72 * k)) * 1.55, math.sin(math.radians(90 + 72 * k)) * 1.55) for k in range(5)]
    for i in range(5):
        a, b = verts[i], verts[(i + 2) % 5]
        mid = ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2); ln = math.hypot(b[0] - a[0], b[1] - a[1])
        ang = math.degrees(math.atan2(b[1] - a[1], b[0] - a[0]))
        s = box((mid[0], mid[1], 0.07), (ln, 0.05, 0.02), (0, 0, ang), bevel=0); setmat(s, glow("pr", PUR, 6.0)); P.append(s)
    # cinco velas nas pontas
    for (x, y) in verts:
        c = cyl((x, y, 0.2), 0.06, 0.28, seg=10, bevel=0.006); setmat(c, mat("candle", (0.95, 0.9, 0.78), 0.6)); P.append(c)
        P += recolor(flame((x, y, 0.34), h=0.3, r=0.06), PUR, (0.9, 0.8, 1.0))
    # adaga cravada flutuando sobre o centro, três esferas = os próximos 3 feitiços
    bl = box((0, 0, 1.1), (0.14, 0.04, 0.8), (0, 0, 0), bevel=0.01, taper=(0.1, 1)); bl.rotation_euler[0] = math.radians(180); hard(bl); bl.location = (0, 0, 1.1); setmat(bl, mat("blade", (0.7, 0.72, 0.8), 0.3, 0.9)); P.append(bl)
    gd = box((0, 0, 1.58), (0.34, 0.07, 0.06), bevel=0.015); hard(gd); setmat(gd, mat("gold", (1.0, 0.72, 0.28), 0.3, 1.0)); P.append(gd)
    gr = cyl((0, 0, 1.78), 0.035, 0.34, seg=8, bevel=0.004); hard(gr); setmat(gr, mat("leather", (0.2, 0.12, 0.2), 0.6)); P.append(gr)
    pm = sph((0, 0, 1.98), 0.07); setmat(pm, glow("pr", PUR, 6.0)); P.append(pm)
    for k in range(3):
        a = k / 3 * math.tau + 0.4
        o = orb((math.cos(a) * 0.9, math.sin(a) * 0.9 * 0.5, 1.05 + 0.2 * k), 0.12 - 0.015 * k, PUR, 8.0); P.append(o)
        P += spikes((math.cos(a) * 0.9, math.sin(a) * 0.9 * 0.5, 1.05 + 0.2 * k), 6, 0.14, 0.3, 0.04, PUR, "xz", 7.0)
    # fio de luz subindo em espiral
    pts = [(math.cos(i * 0.9) * 0.3, math.sin(i * 0.9) * 0.3, 0.1 + i * 0.28) for i in range(9)]
    P.append(beam(pts, 0.02, PUR, 0.5, 6.0))
    group("ritual", P)
    return {"kind": "spell", "dir": (0.3, -1.0, 0.34), "hatch": 22.0}


# ------------------------------------------------------------------ 19. Cavaleiro da Morte

def death_knight():
    k = creatures_lich.death_knight(); place(k, (0, 0, 0), rot_z=-14)
    P = []
    # feitiços girando e entrando no peito: orbes e fios de luz
    for i, (x, z, c) in enumerate(((-1.2, 1.6, PUR), (-1.5, 0.9, GRN), (1.4, 2.1, PUR), (1.35, 0.5, GRN))):
        P.append(orb((x, -0.3, z), 0.06, c, 8.0))
        P.append(orb((x * 0.7, -0.4, (z + 1.4) / 2 + 0.05), 0.035, c, 8.0))
        P.append(orb((x * 0.4, -0.45, (z + 3 * 1.4) / 4), 0.02, c, 8.0))
    for (x, y, r) in ((-1.1, -0.4, 0.14), (1.2, -0.2, 0.1)):
        c = sph((x, y, r * 0.6), r, (1, 0.9, 0.7)); shade(c); setmat(c, mat("stone", STONE, 0.9)); P.append(c)
    P += tomb((1.3, 0.8, -0.04), rot=-20, s=0.9, lean=10)
    P += tomb((-1.4, 0.9, -0.04), rot=18, s=0.8, lean=-8)
    P.append(mound((0, 0.0, -0.03), (1.3, 0.9, 0.06)))
    group("dk_bits", P)
    return {"kind": "monster", "dir": (0.3, -1.0, 0.14)}


# ------------------------------------------------------------------ 20. Túmulo Aberto

def open_grave():
    P = []
    M = mound((0, 0.1, 0.0), (1.8, 1.1, 0.2)); P.append(M)
    pit = sph((0, -0.2, 0.18), 1, (0.95, 0.55, 0.08)); setmat(pit, mat("shadow", SHADOW, 0.9)); P.append(pit)
    gl = sph((0, -0.28, 0.22), 1, (0.65, 0.25, 0.03)); setmat(gl, glow("gg", GRN, 4.0)); P.append(gl)
    cf = box((0, -0.15, 0.2), (1.0, 0.6, 0.05), (0, 0, 0), bevel=0.01); hard(cf); setmat(cf, mat("woodd", (0.3, 0.2, 0.13), 0.8, bump=0.4, bump_scale=10)); P.append(cf)
    lid = box((0.55, 0.35, 0.55), (1.0, 0.55, 0.06), (58, 0, -12), bevel=0.015); hard(lid); setmat(lid, mat("woodl", (0.38, 0.25, 0.15), 0.8, bump=0.4, bump_scale=12)); P.append(lid)
    cross = box((0.55, 0.28, 0.58), (0.06, 0.02, 0.4), (58, 0, -12), bevel=0.004); setmat(cross, mat("iron", (0.42, 0.43, 0.47), 0.5, 0.8)); P.append(cross)
    # duas mãos de osso saindo, com antebraço
    for (x, rz, up) in ((-0.35, 12, 0.0), (0.3, -20, 0.1)):
        a = Vector((x, -0.3, 0.1)); b = Vector((x + rz * 0.006, -0.42, 0.75 + up)); c = Vector((x + rz * 0.012, -0.5, 1.15 + up))
        P += bone_prop(tuple(a), tuple(b), 0.045) + bone_prop(tuple(b), tuple(c), 0.04)
        hand = fuse([sph(tuple(c + Vector((0, -0.02, 0.07))), 0.07, (1, 0.7, 1))] + [sph((c.x + (k - 1.5) * 0.045, c.y - 0.04, c.z + 0.17 + (0.03 if k in (1, 2) else 0)), 0.022, (1, 1, 2.8)) for k in range(4)], "hand", 0.008)
        setmat(hand, mat("bone", BONE, 0.6)); P.append(hand)
    P += tomb((-1.2, 0.8, 0.0), rot=14, s=1.1, lean=-8)
    P += skull_prop((-0.9, -0.9, 0.1), 1.3)
    P += skull_prop((1.2, -0.7, 0.1), 1.0)
    P += bone_prop((0.5, -1.1, 0.04), (0.95, -1.2, 0.04))
    for (x, y, r) in ((-1.3, -0.4, 0.1), (1.5, 0.0, 0.12), (1.05, 0.85, 0.08)):
        c = sph((x, y, r * 0.6), r, (1, 0.9, 0.7)); shade(c); setmat(c, mat("stone", STONE, 0.9)); P.append(c)
    for (x, z, r) in ((-0.3, 1.6, 0.04), (0.4, 1.9, 0.035), (0.0, 1.45, 0.03)):
        P.append(orb((x, -0.5, z), r, GRN, 8.0))
    group("grave", P)
    return {"kind": "spell", "dir": (0.4, -1.0, 0.34), "hatch": 22.0}


# ------------------------------------------------------------------ 21. Tempestade de Almas

def soul_storm():
    P = []
    # chão de lápides sob o funil
    P.append(mound((0, 0.0, -0.03), (2.4, 1.4, 0.08)))
    for (x, y, r, s) in ((-2.0, 0.5, 20, 0.9), (1.9, 0.7, -15, 1.0), (-1.3, -0.9, 10, 0.8), (1.4, -0.9, -8, 0.85)):
        P += tomb((x, y, 0.0), rot=r, s=s, lean=6 if x > 0 else -6)
    # funil: anéis cada vez mais largos, almas girando, raios
    cm = mat("cloud", (0.2, 0.14, 0.3), 0.9, bump=0.6, bump_scale=20)
    for i in range(7):
        t = i / 6
        R = 0.25 + t * 1.5; z = 0.5 + t * 2.7
        ring = torus((0, 0, z), R, 0.07 + 0.04 * t, (0, 0, 0), s=(1, 0.8, 1)); shade(ring); setmat(ring, cm); P.append(ring)
        for k in range(2 + (i % 2)):
            a = k / (2 + i % 2) * math.tau + i * 1.1
            P += wisp((math.cos(a) * R, math.sin(a) * R * 0.8 - 0.1, z + 0.1), 0.55 + 0.25 * t, GRN, 0.0)
    cl = fuse([sph((x, y, 3.55), 1, (0.9, 0.6, 0.35)) for (x, y) in ((-1.2, 0.0), (0.0, 0.2), (1.2, 0.0), (0.4, -0.3), (-0.5, -0.3))], "clouds", 0.04, 0.7, 4); setmat(cl, cm); P.append(cl)
    P.append(beam(zigzag((0.6, -0.4, 3.4), (1.2, -0.6, 0.1), 7, 0.14), 0.045, (0.85, 1.0, 0.45), 0.6, 9.0))
    P.append(beam(zigzag((-0.8, -0.2, 3.4), (-1.5, -0.4, 0.8), 6, 0.12, 2), 0.035, (0.85, 1.0, 0.45), 0.6, 9.0))
    group("storm", P)
    return {"kind": "spell", "dir": (0.3, -1.0, 0.12), "hatch": 22.0}


# ------------------------------------------------------------------ 22. Colosso de Ossos

def bone_colossus():
    c = creatures_lich.bone_colossus(); place(c, (0, 0, 0), rot_z=-12)
    for (x, y, rz, s, ar) in ((-2.0, -0.9, 30, 0.55, False), (1.9, -0.6, -25, 0.5, True), (-1.2, -1.5, 10, 0.45, False)):
        place(monsters.skeleton(archer=ar), (x, y, 0), rot_z=rz, scale=s)
    P = []
    P += skull_prop((1.2, -1.4, 0.1), 1.4)
    P += bone_prop((-0.4, -1.5, 0.05), (0.2, -1.6, 0.05), 0.05)
    P.append(mound((0, 0.0, -0.03), (2.6, 1.3, 0.07)))
    for (x0, z0) in ((-1.7, 1.0), (1.6, 1.2)):
        for t in (0.0, 0.3, 0.6):
            P.append(orb((x0 * (1 - t) * 0.9, -0.8, z0 + (1.9 - z0) * t), 0.05 - 0.012 * t * 3, GRN, 8.0))
    group("pile", P)
    return {"kind": "monster", "dir": (0.3, -1.0, 0.1)}


# ------------------------------------------------------------------ 23. Apocalipse Arcano

def arcane_apocalypse():
    P = []
    cz = 3.0
    ring = torus((0, 0, cz), 1.9, 0.07, (90, 0, 0)); shade(ring); setmat(ring, glow("ap", PUR, 7.0)); P.append(ring)
    ring2 = torus((0, 0, cz), 1.3, 0.04, (90, 0, 0)); shade(ring2); setmat(ring2, glow("ap", PUR, 7.0)); P.append(ring2)
    cols = [(0.8, 0.45, 1.0), (0.45, 0.8, 1.0), (0.55, 1.0, 0.45), (1.0, 0.65, 0.25), (1.0, 0.45, 0.7), (0.95, 0.95, 0.5)]
    for k in range(6):
        a = k / 6 * math.tau + 0.3
        x, z = math.cos(a) * 1.9, cz + math.sin(a) * 1.9
        P.append(orb((x, 0, z), 0.2, cols[k], 8.0))
        P += spikes((x, 0, z), 6, 0.2, 0.46, 0.06, cols[k], "xz", 7.0, seed=a)
        tx = (k - 2.5) * 0.28
        P.append(beam([(x, 0, z - 0.2), ((x + tx) / 2, -0.2, (z + 0.5) / 2), (tx, -0.4, 0.55)], 0.07, cols[k], 0.5, 8.0))
    P.append(orb((0, 0, cz), 0.4, (0.95, 0.9, 1.0), 9.0))
    P += spikes((0, 0, cz), 12, 0.3, 1.0, 0.1, PUR, "xz", 8.0)
    # alvo lá embaixo: uma torre e casebres em ruínas e o brilho do impacto
    P.append(orb((0, -0.4, 0.5), 0.35, (1.0, 0.9, 0.7), 9.0))
    P += spikes((0, -0.4, 0.5), 10, 0.3, 0.95, 0.12, (1.0, 0.7, 0.3), "xz", 7.0)
    gnd = cyl((0, 0, -0.04), 2.6, 0.08, seg=40, bevel=0.02); setmat(gnd, mat("soilf", DIRT_D, 0.95, bump=0.5, bump_scale=18)); P.append(gnd)
    st = mat("stone", STONE, 0.9, bump=0.4, bump_scale=14)
    tw = cyl((1.4, 0.6, 0.45), 0.28, 0.9, seg=16, bevel=0.02); hard(tw); setmat(tw, st); P.append(tw)
    rf = cyl((1.4, 0.6, 1.1), 0.34, 0.4, seg=16, bevel=0.01, r2=0.02); hard(rf); setmat(rf, mat("roof", (0.5, 0.1, 0.12), 0.8)); P.append(rf)
    for (x, y, a) in ((-1.5, 0.5, 12), (-0.8, 1.0, -10)):
        h = box((x, y, 0.25), (0.6, 0.5, 0.5), (0, 0, a), bevel=0.03); hard(h); setmat(h, st); P.append(h)
        r_ = box((x, y, 0.62), (0.7, 0.55, 0.28), (0, 0, a), bevel=0.02, taper=(0.1, 1.0)); hard(r_); setmat(r_, mat("roof", (0.5, 0.1, 0.12), 0.8)); P.append(r_)
    group("apoc", P)
    return {"kind": "spell", "dir": (0.25, -1.0, 0.1), "hatch": 22.0}


# ------------------------------------------------------------------ comuns

def dark_forge():
    P = []
    st = mat("stone", (0.4, 0.38, 0.4), 0.9, bump=0.4, bump_scale=14)
    iron = mat("ironn", (0.3, 0.3, 0.36), 0.45, 0.8)
    # fornalha ao fundo, com boca de fogo roxo
    fb = box((0, 1.1, 0.9), (2.2, 1.0, 1.8), bevel=0.05); hard(fb); setmat(fb, st); P.append(fb)
    ch = cyl((0, 1.2, 2.2), 0.4, 1.0, seg=14, bevel=0.02, r2=0.32); hard(ch); setmat(ch, st); P.append(ch)
    mo = box((0, 0.58, 0.7), (1.2, 0.2, 0.8), bevel=0.04, taper=(0.9, 1)); hard(mo); setmat(mo, mat("shadow", SHADOW, 0.9)); P.append(mo)
    P += recolor(flame((0, 0.4, 0.4), h=0.65, r=0.28), PUR, (0.95, 0.85, 1.0))
    P += recolor(flame((-0.38, 0.4, 0.4), h=0.4, r=0.14, lean=(-0.05, 0)), PUR, (0.95, 0.85, 1.0))
    P += recolor(flame((0.4, 0.4, 0.4), h=0.45, r=0.14, lean=(0.05, 0)), PUR, (0.95, 0.85, 1.0))
    # bigorna: base, cintura, mesa e chifre
    ab = box((-0.0, -0.75, 0.3), (0.9, 0.55, 0.6), bevel=0.04); hard(ab); setmat(ab, mat("woodd", (0.3, 0.2, 0.13), 0.8, bump=0.4, bump_scale=10)); P.append(ab)
    aw = box((0, -0.75, 0.75), (0.5, 0.3, 0.3), bevel=0.04, taper=(1.3, 1)); hard(aw); setmat(aw, iron); P.append(aw)
    at = box((0, -0.75, 1.0), (1.2, 0.42, 0.22), bevel=0.04); hard(at); setmat(at, iron); P.append(at)
    hn = cyl((0.72, -0.75, 1.0), 0.18, 0.5, rot=(0, 90, 0), seg=14, bevel=0.01, r2=0.02); hard(hn); hn.rotation_euler[1] = math.radians(-90); setmat(hn, iron); P.append(hn)
    # lingote em brasa roxa e fagulhas
    ig = box((-0.1, -0.75, 1.17), (0.5, 0.2, 0.1), (0, 0, 10), bevel=0.02, taper=(1, 1)); hard(ig); setmat(ig, glow("ingot", PUR, 6.0)); P.append(ig)
    for (dx, dy, dz, r) in ((0.2, 0.0, 0.5, 0.03), (-0.3, -0.1, 0.7, 0.025), (0.4, 0.1, 0.3, 0.022), (0.0, 0.0, 0.9, 0.02), (-0.5, 0.1, 0.45, 0.02)):
        P.append(orb((dx, -0.75 + dy, 1.2 + dz), r, PUR, 8.0))
    # martelo apoiado e tenazes pendurados
    hd = box((-0.85, -0.85, 1.28), (0.4, 0.2, 0.2), (0, 0, 0), bevel=0.03); hard(hd); setmat(hd, iron); P.append(hd)
    hl = cyl((-0.85, -0.85, 1.28), 0.03, 1.0, rot=(0, 90, 0), seg=8, bevel=0.004); setmat(hl, mat("wood", (0.45, 0.27, 0.13), 0.8)); P.append(hl)
    hl.location = (-0.85 - 0.4, -0.85, 1.28)
    # crânio no alto, com olhos roxos
    P += skull_prop((-1.3, -0.3, 0.12), 1.3)
    P.append(mound((0, -0.2, -0.02), (2.2, 1.7, 0.04)))
    group("forge", P)
    return {"kind": "lair", "dir": (0.5, -1.0, 0.22)}


def weakness_curse():
    P = []
    iron = mat("iron", (0.55, 0.56, 0.6), 0.4, 0.8)
    P.append(mound((0, 0.0, -0.02), (2.0, 1.1, 0.07)))
    # espada quebrada cravada no chão, lâmina murcha e torta
    bl = tube([(0.0, 0, 0.25), (0.1, 0, 1.0), (0.45, 0, 1.45)], 0.07, 0.5, 14)
    bl.scale = (1.0, 0.35, 1.0); setmat(bl, iron); P.append(bl)
    gd = box((0.0, 0, 0.25), (0.62, 0.1, 0.09), (0, 0, 0), bevel=0.02); hard(gd); setmat(gd, mat("gold", (1.0, 0.72, 0.28), 0.3, 1.0)); P.append(gd)
    gr = cyl((0.0, 0, -0.1), 0.045, 0.45, seg=10, bevel=0.005); setmat(gr, mat("leather", (0.38, 0.22, 0.12), 0.6)); P.append(gr)
    for (x, y, a, l) in ((0.9, -0.5, 30, 0.35), (-0.8, -0.6, -40, 0.28)):
        s = box((x, y, 0.05), (0.1, 0.02, l), (80, 0, a), bevel=0.004, taper=(0.1, 1)); setmat(s, iron); P.append(s)
    # escudo rachado, caído
    sd = cyl((-1.15, -0.1, 0.12), 0.62, 0.1, rot=(70, 0, 0), seg=30, bevel=0.025); hard(sd); setmat(sd, mat("wood", (0.45, 0.27, 0.13), 0.8, bump=0.4, bump_scale=25)); P.append(sd)
    rm = torus((-1.15, -0.1, 0.12), 0.62, 0.04, (70, 0, 0)); shade(rm); setmat(rm, iron); P.append(rm)
    ck = tube([(-1.1, -0.45, 0.45), (-1.2, -0.46, 0.2), (-1.05, -0.48, -0.0), (-1.25, -0.5, -0.2)], 0.014, 0.4, 8); setmat(ck, mat("shadow", SHADOW, 0.9)); P.append(ck)
    # flor murcha
    st = tube([(1.2, -0.2, 0.0), (1.22, -0.2, 0.35), (1.4, -0.2, 0.55)], 0.018, 0.8, 8); setmat(st, mat("dead", (0.3, 0.28, 0.14), 0.9)); P.append(st)
    pt = sph((1.45, -0.2, 0.52), 1, (0.09, 0.05, 0.05)); setmat(pt, mat("dead", (0.4, 0.3, 0.2), 0.9)); P.append(pt)
    # nuvem de maldição com caveira, olhos roxos, e gotas caindo sobre tudo
    cm = mat("cloud", (0.2, 0.14, 0.3), 0.9, bump=0.6, bump_scale=20)
    cl = fuse([sph((x, 0.1, z), 1, s) for (x, z, s) in ((-0.3, 2.2, (0.7, 0.4, 0.3)), (0.3, 2.35, (0.65, 0.4, 0.32)), (0.8, 2.15, (0.5, 0.35, 0.25)), (-0.9, 2.1, (0.45, 0.3, 0.22)), (0.0, 2.0, (0.9, 0.4, 0.25)))], "cloud", 0.035, 0.7, 4)
    setmat(cl, cm); P.append(cl)
    P += skull_prop((0.0, -0.3, 2.2), 1.9)
    for sx in (-1, 1):
        P.append(orb((sx * 0.14, -0.58, 2.22), 0.045, PUR, 9.0, (1.0, 0.5, 1.0)))
    for (x, z, ln) in ((-0.4, 1.5, 0.25), (0.35, 1.2, 0.3), (0.9, 1.4, 0.22), (-0.9, 1.3, 0.2), (0.0, 1.0, 0.18)):
        d = beam([(x, -0.1, z + ln), (x, -0.1, z)], 0.035, PUR_D, 0.3, 5.0); P.append(d)
        d2 = sph((x, -0.1, z - 0.02), 1, (0.05, 0.05, 0.08)); setmat(d2, glow("drop", PUR_D, 5.0)); P.append(d2)
    group("curse", P)
    return {"kind": "spell", "dir": (0.3, -1.0, 0.14), "hatch": 22.0}


def dark_sacrifice():
    P = []
    st = mat("slate", (0.3, 0.28, 0.32), 0.9, bump=0.4, bump_scale=14)
    for i, (w, d, z) in enumerate(((2.1, 1.4, 0.15), (1.6, 1.0, 0.45))):
        s = box((0, 0, z), (w, d, 0.3 + i * 0.1), bevel=0.04); hard(s); setmat(s, st); P.append(s)
    top = box((0, 0, 0.82), (1.5, 0.9, 0.2), bevel=0.04); hard(top); setmat(top, mat("slate2", (0.38, 0.36, 0.4), 0.9, bump=0.4, bump_scale=14)); P.append(top)
    for k in range(3):
        r = box((-0.5 + k * 0.5, -0.46, 0.82), (0.16, 0.02, 0.08), (0, 0, 0), bevel=0.0); setmat(r, glow("sr", (0.85, 0.15, 0.35), 4.0)); P.append(r)
    # canal de sangue/elixir escorrendo até uma tigela
    ch = box((0.85, -0.2, 0.9), (0.05, 0.05, 0.05), bevel=0.0)
    ch.dimensions = (0.4, 0.04, 0.03); setmat(ch, glow("el", (0.85, 0.15, 0.35), 3.0)); P.append(ch)
    bw = cyl((1.25, -0.2, 0.62), 0.22, 0.2, seg=20, bevel=0.015, r2=0.14); hard(bw); setmat(bw, mat("iron", (0.3, 0.3, 0.36), 0.45, 0.8)); P.append(bw)
    lq = cyl((1.25, -0.2, 0.72), 0.2, 0.02, seg=20, bevel=0); setmat(lq, glow("el", (0.85, 0.15, 0.35), 4.0)); P.append(lq)
    # braseiros roxos
    for x in (-1.5, 1.7):
        br = cyl((x, 0.55, 0.45), 0.2, 0.9, seg=12, bevel=0.015, r2=0.12); hard(br); setmat(br, mat("ironn", (0.3, 0.3, 0.36), 0.45, 0.8)); P.append(br)
        bo = cyl((x, 0.55, 0.95), 0.28, 0.12, seg=16, bevel=0.015, r2=0.34); hard(bo); setmat(bo, mat("ironn", (0.3, 0.3, 0.36), 0.45, 0.8)); P.append(bo)
        P += recolor(flame((x, 0.55, 1.0), h=0.5, r=0.12), PUR, (0.95, 0.85, 1.0))
    # adaga erguida acima, pingando
    bd = box((0, -0.05, 1.7), (0.13, 0.04, 0.75), (0, 0, 0), bevel=0.01, taper=(0.1, 1)); bd.rotation_euler[0] = math.radians(180); hard(bd); setmat(bd, mat("blade", (0.7, 0.72, 0.8), 0.3, 0.9)); P.append(bd)
    gd = box((0, -0.05, 2.14), (0.34, 0.07, 0.06), bevel=0.015); hard(gd); setmat(gd, mat("gold", (1.0, 0.72, 0.28), 0.3, 1.0)); P.append(gd)
    gr = cyl((0, -0.05, 2.34), 0.035, 0.34, seg=8, bevel=0.004); hard(gr); setmat(gr, mat("leather", (0.2, 0.12, 0.2), 0.6)); P.append(gr)
    d = sph((0, -0.05, 1.22), 1, (0.03, 0.03, 0.06)); setmat(d, glow("el", (0.85, 0.15, 0.35), 4.0)); P.append(d)
    group("altar", P)
    gb = chars2.goblin(); place(gb, (0.0, 0.0, 0.92), rot_z=-10, rot_x=-90, scale=0.6)
    # oferenda: o goblin deitado de costas sobre a mesa de pedra
    return {"kind": "spell", "dir": (0.3, -1.0, 0.25), "hatch": 22.0}


def ruin_titan():
    t = creatures_lich.ruin_titan(); place(t, (0, 0, 0), rot_z=-14)
    P = []
    st = mat("ruinstone_d", (0.36, 0.34, 0.33), 0.9, bump=0.5, bump_scale=14)
    for (x, y, z, s, a) in ((-1.6, -0.9, 0.12, 0.3, 30), (1.7, -0.8, 0.1, 0.34, -20), (-0.9, -1.4, 0.08, 0.2, 10), (0.9, -1.5, 0.07, 0.24, 50), (2.0, 0.2, 0.1, 0.26, 70)):
        b = box((x, y, z), (s, s * 0.8, s * 0.7), (a * 0.3, a * 0.2, a), bevel=0.04); hard(b); setmat(b, st); P.append(b)
    # destroços e coluna caída
    cf = cyl((-1.8, 0.4, 0.2), 0.2, 1.1, rot=(0, 90, 20), seg=12, bevel=0.02); hard(cf); setmat(cf, mat("ruinstone", (0.56, 0.54, 0.5), 0.9, bump=0.5, bump_scale=14)); P.append(cf)
    for (x, z, s) in ((-1.4, 2.1, 0.18), (1.5, 2.6, 0.15), (-0.2, 3.7, 0.12), (1.1, 3.2, 0.1)):
        b = box((x, -0.3, z), (s, s, s * 0.8), (20, 30, 40), bevel=0.03); setmat(b, st); P.append(b)
    P.append(mound((0, 0.0, -0.03), (2.4, 1.3, 0.07)))
    group("rubble", P)
    return {"kind": "monster", "dir": (0.3, -1.0, 0.1)}


def villain_lich():
    k = creatures_lich.lich(); place(k, (0, 0, 0), rot_z=-10)
    P = []
    P.append(mound((0, 0.0, -0.03), (1.8, 1.1, 0.06)))
    P += tomb((-1.6, 0.5, 0.0), rot=18, s=0.9, lean=-8)
    P += tomb((1.7, 0.6, 0.0), rot=-16, s=1.0, lean=8)
    P += skull_prop((-1.0, -0.8, 0.1), 1.2)
    P += skull_prop((1.1, -0.9, 0.08), 1.0)
    group("ground", P)
    return {"kind": "monster", "dir": (0.25, -1.0, 0.14), "lens": 95}


SCENES_LICH = {
    "bone_legion": bone_legion, "skeleton_archers": skeleton_archers, "shadow_bolt": shadow_bolt, "arcane_spark": arcane_spark,
    "acolyte": acolyte, "ghoul": ghoul, "corpse_blast": corpse_blast, "cultists": cultists, "shadow_mark": shadow_mark,
    "ghost": ghost, "bone_totem": bone_totem, "soul_feast": soul_feast, "soul_harvest": soul_harvest, "scrap_golem": scrap_golem,
    "shadow_echo": shadow_echo, "forbidden_library": forbidden_library, "raised_servant": raised_servant, "life_drain": life_drain,
    "profane_ritual": profane_ritual, "death_knight": death_knight, "open_grave": open_grave, "soul_storm": soul_storm,
    "bone_colossus": bone_colossus, "arcane_apocalypse": arcane_apocalypse,
    "dark_forge": dark_forge, "weakness_curse": weakness_curse, "dark_sacrifice": dark_sacrifice, "ruin_titan": ruin_titan,
    "villain_lich": villain_lich,
}
