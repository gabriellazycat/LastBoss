"""Locais da estrada, covil e arena do chefe, na linguagem do cenário (scenery.py): pedra escura chanfrada,
madeira com quinas, metal escuro, brilhos de runa roxos (a cor do chefe) e luz quente nas velas."""
import math
import bpy, bmesh
from mathutils import Vector, noise
from mk import *
from scenery import _stone, plank, jitter, rng, STONE, STONE_D, IRON, WARM

WATER = (0.07, 0.3, 0.5)
DARKSTONE = (0.15, 0.13, 0.19)
DARKSTONE_L = (0.27, 0.24, 0.32)
RUNE = (0.85, 0.35, 1.0)
GOLD = (1.0, 0.72, 0.28)
BONE = (0.93, 0.89, 0.76)


def _dark(p, n):
    return mix(DARKSTONE, DARKSTONE_L, smoothstep(-0.5, 0.9, n.z) * 0.45 + 0.25 + noise.noise(p * 0.8) * 0.25)


def _glow(loc, s, col, name, emit=6.0):
    o = sph(loc, 1, s); setmat(o, mat(name, col, 0.4, emit=emit)); return o


def _rune_mat():
    return mat("runep", RUNE, 0.4, emit=5.0)


def coins():
    P = []
    r = rng(8)
    for k in range(14):
        a = r.uniform(0, math.tau); d = r.uniform(0, 0.32) * (1 - k / 14)
        c = cyl((math.cos(a) * d, math.sin(a) * d, 0.03 + k * 0.035), 0.13, 0.04, (r.uniform(-12, 12), r.uniform(-12, 12), 0), seg=12, bevel=0.008)
        hard(c); setmat(c, mat("gold", GOLD, 0.3, 1.0)); P.append(c)
    gem = box((0.1, -0.1, 0.55), (0.12, 0.12, 0.16), (20, 30, 45), bevel=0.01, taper=(0.3, 0.3)); hard(gem); setmat(gem, mat("ruby", (0.95, 0.15, 0.3), 0.2, emit=1.5)); P.append(gem)
    return group("coins", P)


def fountain():
    P = []
    rr = rng(3)
    for k in range(14):
        a = k / 14 * math.tau
        P.append(_stone((math.cos(a) * 2.1, math.sin(a) * 2.1, 0.3), (1.05 * rr.uniform(0.9, 1.1), 0.7, 0.6), (0, 0, math.degrees(a) + 90), 300 + k, 0.04))
    basin = cyl((0, 0, 0.12), 2.0, 0.24, seg=32, bevel=0.03); hard(basin); setmat(basin, mat("stone_d", STONE_D, 0.8)); P.append(basin)
    water = cyl((0, 0, 0.42), 1.85, 0.06, seg=32, bevel=0.0); shade(water); setmat(water, mat("water", WATER, 0.1, emit=0.3)); P.append(water)
    col_ = cyl((0, 0, 1.0), 0.32, 1.4, seg=8, bevel=0.04, r2=0.24); hard(col_); setmat(col_, mat("stone", STONE, 0.8)); P.append(col_)
    bowl = cyl((0, 0, 1.75), 0.8, 0.25, seg=16, bevel=0.05, r2=0.45); hard(bowl); setmat(bowl, mat("stone", STONE, 0.8)); P.append(bowl)
    top = cyl((0, 0, 1.92), 0.68, 0.04, seg=16, bevel=0.0); shade(top); setmat(top, mat("water", WATER, 0.1, emit=0.3)); P.append(top)
    jet = fuse([sph((0, 0, 2.25), 1, (0.12, 0.12, 0.35)), sph((0, 0, 2.55), 0.16)], "jet", 0.02)
    setmat(jet, mat("waterj", (0.75, 0.92, 1.0), 0.1, emit=2.5)); P.append(jet)
    for k in range(4):
        a = k / 4 * math.tau + 0.4
        sp = tube([(math.cos(a) * 0.6, math.sin(a) * 0.6, 1.85), (math.cos(a) * 1.0, math.sin(a) * 1.0, 1.6), (math.cos(a) * 1.25, math.sin(a) * 1.25, 0.5)], 0.05, 0.6, 10)
        setmat(sp, mat("waterj", (0.75, 0.92, 1.0), 0.1, emit=2.5)); P.append(sp)
    return group("fountain", P)


def shrine():
    P = [_stone((0, 0, 0.2), (2.8, 2.8, 0.45), (0, 0, 8), 41, 0.06), _stone((0, 0, 0.5), (1.8, 1.8, 0.3), (0, 0, -6), 42, 0.05)]
    ob = box((0, 0, 1.9), (0.7, 0.7, 2.6), (0, 0, 45), bevel=0.08, seg=2, taper=(0.6, 0.6)); jitter(ob, 0.03, 1.2, 43); ob = hard(ob)
    paint(ob, lambda p, n: mix(STONE_D, STONE, smoothstep(-0.5, 0.9, n.z) * 0.6 + 0.3)); setmat(ob, mat("stonev", vcol=True, rough=0.85)); P.append(ob)
    for z in (1.2, 2.0, 2.7):
        rune = box((0.0, -0.33 + (z - 1.2) * 0.07, z), (0.12, 0.05, 0.3), bevel=0.01); hard(rune); setmat(rune, mat("runeg", (0.35, 1.0, 0.6), 0.4, emit=5.0)); P.append(rune)
    P.append(_glow((0, 0, 3.6), (0.4, 0.4, 0.62), (0.35, 1.0, 0.6), "orbg", 6.0))
    for k in range(4):
        a = k / 4 * math.tau + math.pi / 4
        c = cyl((math.cos(a) * 1.15, math.sin(a) * 1.15, 0.85), 0.07, 0.3, seg=8, bevel=0.01); hard(c); setmat(c, mat("candle", (0.95, 0.9, 0.78), 0.6)); P.append(c)
        P.append(_glow((math.cos(a) * 1.15, math.sin(a) * 1.15, 1.06), (0.05, 0.05, 0.09), WARM, "flame", 8.0))
    return group("shrine", P)


def ritual():
    """Círculo de ritual: velas e crânios em volta de um pentagrama gravado e brilhante (raio ~5 m)."""
    P = []
    ring = torus((0, 0, 0.03), 4.8, 0.09, s=(1, 1, 0.25)); shade(ring); setmat(ring, _rune_mat()); P.append(ring)
    for i in range(5):
        a = i / 5 * math.tau; b = (i + 2) / 5 * math.tau
        p0 = Vector((math.cos(a) * 4.4, math.sin(a) * 4.4, 0.03)); p1 = Vector((math.cos(b) * 4.4, math.sin(b) * 4.4, 0.03))
        mid = (p0 + p1) / 2; d = p1 - p0
        l = box(tuple(mid), (0.12, d.length, 0.04), (0, 0, math.degrees(math.atan2(-d.x, d.y))), bevel=0); setmat(l, _rune_mat()); P.append(l)
        x, y = math.cos(a) * 4.0, math.sin(a) * 4.0
        for dx, dy, hh in ((0, 0, 0.55), (0.25, 0.1, 0.35), (-0.2, 0.2, 0.42)):
            c = cyl((x + dx, y + dy, hh / 2), 0.08, hh, seg=8, bevel=0.01, r2=0.075); hard(c); setmat(c, mat("candlep", (0.55, 0.15, 0.2), 0.6)); P.append(c)
            P.append(_glow((x + dx, y + dy, hh + 0.08), (0.05, 0.05, 0.1), WARM, "flame", 8.0))
        sk = fuse([sph((x * 0.85, y * 0.85, 0.15), 1, (0.16, 0.14, 0.15)), sph((x * 0.85, y * 0.85, 0.06), 1, (0.1, 0.1, 0.06))], "skull", 0.012)
        setmat(sk, mat("bone", BONE, 0.6)); P.append(sk)
    P.append(_stone((0, 0, 0.25), (1.6, 1.0, 0.5), (0, 0, 15), 77, 0.05))
    book = box((0, 0, 0.56), (0.6, 0.45, 0.1), (0, 0, 15), bevel=0.015); hard(book); setmat(book, mat("book", (0.4, 0.08, 0.14), 0.6)); P.append(book)
    return group("ritual", P)


def bridge():
    P = []
    L = 14.0
    for k in range(int(L / 0.55)):
        y = -L / 2 + 0.27 + k * 0.55
        P.append(plank((0, y, 0.25), (5.0, 0.5, 0.14), (0, rng(k).uniform(-2, 2), 0), k, (0.5, 0.33, 0.18)))
    for sx in (-2.55, 2.55):
        P.append(plank((sx, 0, 0.12), (0.3, L, 0.3), (0, 0, 0), 90 + int(sx), (0.35, 0.22, 0.12)))
        for k in range(6):
            y = -L / 2 + 0.5 + k * (L - 1) / 5
            P.append(plank((sx, y, 0.75), (0.26, 0.26, 1.3), (0, 0, 0), 120 + k, (0.35, 0.22, 0.12)))
        P.append(plank((sx, 0, 1.3), (0.16, L, 0.16), (0, 0, 0), 130, (0.45, 0.28, 0.15)))
    return group("bridge", P)


def water():
    """Rio: faixa d'água com margem de pedras e juncos (30 x 9 m), no eixo X."""
    P = []
    w = box((0, 0, -0.12), (30.0, 9.0, 0.06), bevel=0); setmat(w, mat("water", WATER, 0.1, emit=0.3)); P.append(w)
    r = rng(14)
    for side in (-1, 1):
        x = -15.0
        while x < 15.0:
            s = r.uniform(0.6, 1.2)
            P.append(_stone((x, side * 4.5 + r.uniform(-0.3, 0.3), 0.05), (s, s * 0.8, s * 0.45), (0, 0, r.uniform(0, 90)), int(x * 10) + side * 500, 0.05))
            x += s * r.uniform(0.9, 1.6)
        for k in range(6):
            x = r.uniform(-14, 14)
            for j in range(4):
                b = tube([(x + j * 0.08, side * 4.0, -0.1), (x + j * 0.1, side * 4.0, 0.5 + j * 0.1)], 0.03, 0.4, 4)
                setmat(b, mat("reed", (0.38, 0.5, 0.22), 0.8)); P.append(b)
    return group("water", P)


def castle():
    """Covil do chefe: muralha de pedra escura com torres, telhados roxos e janelas acesas. Frente = -Y."""
    P = []
    wall = box((0, 0, 3.5), (16.0, 4.0, 7.0), bevel=0.15, seg=2); jitter(wall, 0.05, 0.6, 50); wall = hard(wall)
    paint(wall, _dark); setmat(wall, mat("dstonev", vcol=True, rough=0.85)); P.append(wall)
    for i in range(8):
        m = box((-7.0 + i * 2.0, 0, 7.4), (1.2, 4.2, 1.0), bevel=0.08); hard(m); setmat(m, mat("dstone", DARKSTONE_L, 0.85)); P.append(m)
    for sx, h, r in ((-9.0, 11.0, 2.4), (9.0, 11.0, 2.4), (0.0, 14.0, 3.0)):
        y = 3.0 if sx == 0 else 0.0
        t = cyl((sx, y, h / 2), r, h, seg=12, bevel=0.12, r2=r * 0.9); hard(t)
        paint(t, _dark); setmat(t, mat("dstonev", vcol=True, rough=0.85)); P.append(t)
        rim = cyl((sx, y, h + 0.2), r * 1.12, 0.5, seg=12, bevel=0.08); hard(rim); setmat(rim, mat("dstone", DARKSTONE_L, 0.85)); P.append(rim)
        roof = cyl((sx, y, h + 0.4 + r * 0.9), r * 1.2, r * 1.8, seg=12, bevel=0.05, r2=0.05); hard(roof); setmat(roof, mat("roofp", (0.3, 0.08, 0.36), 0.6)); P.append(roof)
        flag = box((sx + 0.3, y, h + 0.4 + r * 1.8 + 0.6), (0.8, 0.05, 0.5), bevel=0.01); hard(flag); setmat(flag, mat("flag", (0.85, 0.2, 0.3), 0.7)); P.append(flag)
        for k in range(3):
            a = -math.pi / 2 + (k - 1) * 0.7
            wdw = box((sx + math.cos(a) * r * 0.97, y + math.sin(a) * r * 0.97, h * 0.7), (0.5, 0.3, 0.9), (0, 0, math.degrees(a) + 90), bevel=0.04); hard(wdw)
            setmat(wdw, mat("winp", (1.0, 0.5, 0.95), 0.4, emit=4.0)); P.append(wdw)
    gate = box((0, -2.05, 2.5), (4.0, 0.4, 5.0), bevel=0.06); hard(gate); setmat(gate, mat("gate", (0.12, 0.08, 0.12), 0.8)); P.append(gate)
    arch = torus((0, -2.15, 5.0), 2.0, 0.3, (90, 0, 0)); shade(arch); setmat(arch, mat("dstone", DARKSTONE_L, 0.85)); P.append(arch)
    for i in range(6):
        if i in (2, 3):
            continue
        wdw = box((-6.5 + i * 2.6, -2.05, 5.0), (0.6, 0.2, 1.0), bevel=0.04); hard(wdw); setmat(wdw, mat("winp", (1.0, 0.5, 0.95), 0.4, emit=4.0)); P.append(wdw)
    return group("castle", P)


# ------------------------------------------------------------------ arena do chefe

def pillar():
    P = [_stone((0, 0, 0.2), (1.5, 1.5, 0.4), (0, 0, 10), 61, 0.06)]
    r = rng(62)
    for k in range(5):   # tambores de pedra, cada um um pouco torto
        d = cyl((r.uniform(-0.03, 0.03), r.uniform(-0.03, 0.03), 0.8 + k * 0.8), 0.52 - k * 0.015, 0.76, (r.uniform(-2, 2), r.uniform(-2, 2), k * 17), seg=10, bevel=0.06)
        jitter(d, 0.02, 1.5, 62 + k); d = hard(d)
        paint(d, _dark); setmat(d, mat("dstonev", vcol=True, rough=0.85)); P.append(d)
    cap = cyl((0, 0, 4.5), 0.72, 0.4, seg=10, bevel=0.06, r2=0.6); hard(cap); setmat(cap, mat("dstone", DARKSTONE_L, 0.85)); P.append(cap)
    for z in (1.2, 3.4):
        b = torus((0, 0, z), 0.5, 0.05); shade(b); setmat(b, mat("runep3", RUNE, 0.4, emit=3.0)); P.append(b)
    vine = tube([(0.5 * math.cos(a / 3), 0.5 * math.sin(a / 3), 0.4 + a * 0.35) for a in range(10)], 0.04, 0.6, 30)
    setmat(vine, mat("vine", (0.25, 0.45, 0.2), 0.8)); P.append(vine)
    return group("pillar", P)


def brazier():
    P = []
    for k in range(3):
        a = k / 3 * math.tau
        leg = tube([(math.cos(a) * 0.45, math.sin(a) * 0.45, 0), (math.cos(a) * 0.2, math.sin(a) * 0.2, 0.8), (math.cos(a) * 0.35, math.sin(a) * 0.35, 1.35)], 0.05, 0.8, 10)
        setmat(leg, mat("ironn", IRON, 0.5, 0.8)); P.append(leg)
    bowl = cyl((0, 0, 1.45), 0.6, 0.35, seg=12, bevel=0.04, r2=0.32); hard(bowl); setmat(bowl, mat("ironn", IRON, 0.5, 0.8)); P.append(bowl)
    rim = torus((0, 0, 1.62), 0.6, 0.05); shade(rim); setmat(rim, mat("brass", (0.85, 0.6, 0.25), 0.3, 1.0)); P.append(rim)
    coals = fuse([sph((0, 0, 1.6), 1, (0.5, 0.5, 0.12))], "coals", 0.03); setmat(coals, mat("coal", (1.0, 0.35, 0.1), 0.5, emit=6.0)); P.append(coals)
    fire = fuse([sph((0, 0, 1.9), 1, (0.35, 0.35, 0.4)), sph((0.12, 0.05, 2.25), 1, (0.18, 0.18, 0.3)), sph((-0.1, -0.08, 2.15), 1, (0.15, 0.15, 0.25))], "fire", 0.03)
    paint(fire, lambda p, n: mix((1.0, 0.45, 0.1), (1.0, 0.9, 0.4), smoothstep(1.7, 2.3, p.z))); setmat(fire, mat("firev", vcol=True, rough=0.5, emit=8.0)); P.append(fire)
    return group("brazier", P)


def altar():
    P = [_stone((0, 0, 0.25), (2.3, 2.3, 0.5), (0, 0, 0), 71, 0.06), _stone((0, 0, 0.65), (1.6, 1.6, 0.35), (0, 0, 30), 72, 0.05)]
    ring = torus((0, 0, 0.88), 0.95, 0.07); shade(ring); setmat(ring, _rune_mat()); P.append(ring)
    crystal = box((0, 0, 1.35), (0.35, 0.35, 0.9), (0, 0, 45), bevel=0.02, taper=(0.15, 0.15)); hard(crystal)
    setmat(crystal, mat("crystalp", (0.75, 0.4, 1.0), 0.1, emit=4.0)); P.append(crystal)
    for k in range(4):
        a = k / 4 * math.tau
        s = box((math.cos(a) * 0.55, math.sin(a) * 0.55, 1.05), (0.15, 0.15, 0.4), (math.sin(a) * 25, -math.cos(a) * 25, 45), bevel=0.01, taper=(0.2, 0.2)); hard(s)
        setmat(s, mat("crystalp", (0.75, 0.4, 1.0), 0.1, emit=4.0)); P.append(s)
    return group("altar", P)


def _slab(r0, r1, a0, a1, h, steps=4):
    bm = bmesh.new()
    vs = []
    for j in range(steps + 1):
        a = a0 + (a1 - a0) * j / steps
        vs.append((math.cos(a) * r0, math.sin(a) * r0))
    for j in range(steps, -1, -1):
        a = a0 + (a1 - a0) * j / steps
        vs.append((math.cos(a) * r1, math.sin(a) * r1))
    f = bm.faces.new([bm.verts.new((x, y, 0)) for x, y in vs])
    ext = bmesh.ops.extrude_face_region(bm, geom=[f])
    for v in [e for e in ext["geom"] if isinstance(e, bmesh.types.BMVert)]:
        v.co.z = h
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new("slab"); bm.to_mesh(me); bm.free()
    s = bpy.data.objects.new("slab", me); bpy.context.scene.collection.objects.link(s)
    b = s.modifiers.new("bv", 'BEVEL'); b.width = 0.006; b.segments = 2; b.limit_method = 'ANGLE'
    return hard(s)


def arena():
    """Piso da arena do chefe com raio 1 m (o jogo escala pelo raio da regra): lajes em anéis e runas."""
    P = []
    base = cyl((0, 0, -0.06), 1.08, 0.12, seg=48, bevel=0.01); hard(base); setmat(base, mat("dstone_dd", (0.08, 0.07, 0.1), 0.85)); P.append(base)
    r = rng(91)
    for r0, r1, n in ((0.22, 0.45, 8), (0.45, 0.7, 14), (0.7, 0.98, 20)):
        off = r.uniform(0, 1)
        for k in range(n):
            a0 = (k + off) / n * math.tau + 0.008; a1 = (k + 1 + off) / n * math.tau - 0.008
            s = _slab(r0 + 0.006, r1 - 0.006, a0, a1, 0.02 + r.uniform(-0.003, 0.003))
            c = mix((0.12, 0.1, 0.15), (0.24, 0.21, 0.28), r.uniform(0.0, 1.0))
            paint(s, lambda p, n, c=c: c); setmat(s, mat("dstonev", vcol=True, rough=0.85)); P.append(s)
    mid = cyl((0, 0, 0.01), 0.21, 0.02, seg=24, bevel=0.004); hard(mid); setmat(mid, mat("dstone_m", (0.2, 0.17, 0.24), 0.85)); P.append(mid)
    for rr in (0.835, 0.335):   # o jogo escala x15: 0,004 vira ~6 cm de traço
        t = torus((0, 0, 0.022), rr, 0.004, s=(1, 1, 1.2)); shade(t); setmat(t, mat("runep2", RUNE, 0.4, emit=2.5)); P.append(t)
    return group("arena", P)


def throne():
    P = [_stone((0, 0, 0.3), (3.2, 2.6, 0.6), (0, 0, 0), 81, 0.06)]
    seat = box((0, 0, 0.9), (2.2, 1.6, 0.6), bevel=0.06); hard(seat); setmat(seat, mat("dstone", DARKSTONE_L, 0.85)); P.append(seat)
    cush = box((0, -0.05, 1.25), (1.8, 1.3, 0.15), bevel=0.06); hard(cush); setmat(cush, mat("velvet", (0.5, 0.12, 0.35), 0.8)); P.append(cush)
    back = box((0, 0.75, 3.0), (2.4, 0.5, 4.2), bevel=0.08, taper=(0.75, 1.0)); hard(back); setmat(back, mat("dstone", DARKSTONE_L, 0.85)); P.append(back)
    for sx in (-1.2, 0.0, 1.2):
        sp = box((sx, 0.75, 5.4 + (0.6 if sx == 0 else 0)), (0.4, 0.4, 1.4), (0, 0, 45), bevel=0.02, taper=(0.1, 0.1)); hard(sp); setmat(sp, mat("gold", GOLD, 0.3, 1.0)); P.append(sp)
    gem = box((0, 0.48, 4.3), (0.4, 0.15, 0.55), (0, 45, 0), bevel=0.02); hard(gem); setmat(gem, mat("crystalp", (0.75, 0.4, 1.0), 0.1, emit=4.0)); P.append(gem)
    for sx in (-1, 1):
        arm = box((sx * 1.1, -0.1, 1.5), (0.35, 1.5, 0.35), bevel=0.06); hard(arm); setmat(arm, mat("dstone", DARKSTONE_L, 0.85)); P.append(arm)
        sk = fuse([sph((sx * 1.1, -0.85, 1.7), 1, (0.2, 0.2, 0.2)), sph((sx * 1.1, -0.93, 1.6), 1, (0.12, 0.1, 0.08))], "skull", 0.012); setmat(sk, mat("bone", BONE, 0.6)); P.append(sk)
    return group("throne", P)
