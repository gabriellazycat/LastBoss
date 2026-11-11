"""Cenas das cartas do Dragão Avarento (e comuns do lote) para o render de nanquim.
Uso: CARD_SCENES_MODULE=scenes_dragon blender -b --factory-startup -P tools/art/card_ink/render_cards.py -- <saida> [ids]
Mesmo formato de scenes.py: cada função monta a cena (Z para cima, frente = -Y) e devolve o dicionário de câmera."""
import math, random
import bpy, bmesh
from mathutils import Matrix, Vector
from mk import *
import chars, chars2, monsters, monsters2
import scenes as S
import creatures_dragon as CD
from monsters import xform as xform_
from scenes import place, flame, DIRT, DIRT_D, STONE, BONE, FLAME, FLAME_HOT

GOLDC = (1.0, 0.55, 0.04)
OIL = (0.15, 0.1, 0.06)
IRONC = (0.3, 0.3, 0.33)
WOODC = (0.45, 0.27, 0.13)
PURP = (0.62, 0.3, 1.0)
rad = math.radians

CARD_IDS = {
    "oil_splash", "boiling_oil", "goblin_dynamiter", "gold_merc", "cursed_coins", "gold_bait", "tar_net", "burn_village", "mimic", "toll",
    "spark", "kobold_scavengers", "molten_gold", "trap_chest", "treasure_guard", "furnace", "dragon_vault", "blood_tax", "ember_rain",
    "gold_avalanche", "eruption", "elder_dragon", "gargoyle_tower", "soul_collector", "deep_chalice", "cave_troll", "villain_dragon",
    "hero_escudeiro", "hero_arqueira", "hero_cleriga", "hero_mago",
}


# ------------------------------------------------------------------ utilidades

def _lk(o):
    bpy.context.scene.collection.objects.link(o)
    return o


def coins(items, r=0.08, th=0.022, name="coins", seg=14, material=None):
    """Moedas numa malha só. items: (posição, normal) de cada disco."""
    bm = bmesh.new()
    for (p, n) in items:
        q = Vector(n).normalized().to_track_quat('Z', 'Y').to_matrix().to_4x4()
        M = Matrix.Translation(p) @ q
        bmesh.ops.create_cone(bm, cap_ends=True, segments=seg, radius1=r, radius2=r, depth=th, matrix=M)
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    o = _lk(bpy.data.objects.new(name, me))
    setmat(o, material or mat("gold", GOLDC, 0.3, 1.0))
    return o


def heap_items(cx, cy, rx, ry, h, n, seed=1, r=0.08, base_z=0.0):
    rnd = random.Random(seed)
    out = []
    for i in range(n):
        a = rnd.uniform(0, math.tau); b = rnd.uniform(0.0, 1.35) ** 1.0
        sb = math.sin(b)
        p = Vector((cx + rx * math.cos(a) * sb, cy + ry * math.sin(a) * sb, base_z + h * math.cos(b) * 0.9 + 0.01))
        nrm = Vector((math.cos(a) * sb / rx, math.sin(a) * sb / ry, math.cos(b) / max(h, 0.01)))
        nrm += Vector((rnd.uniform(-0.5, 0.5), rnd.uniform(-0.5, 0.5), rnd.uniform(-0.2, 0.4)))
        out.append((p, nrm))
    return out


def gold_heap(cx, cy, rx, ry, h, n=50, seed=1, r=0.08, base_z=0.0):
    """Monte de ouro: massa fundida dourada + moedas de pé por cima."""
    bl = [sph((cx, cy, base_z + h * 0.42), 1, (rx, ry, h * 0.55)),
          sph((cx - rx * 0.5, cy + ry * 0.1, base_z + h * 0.28), 1, (rx * 0.55, ry * 0.6, h * 0.4)),
          sph((cx + rx * 0.5, cy - ry * 0.1, base_z + h * 0.26), 1, (rx * 0.55, ry * 0.6, h * 0.38))]
    m = fuse(bl, "heap", 0.03, smooth=0.6, iters=5)
    setmat(m, mat("goldheap", GOLDC, 0.4, 1.0, bump=0.3, bump_scale=30))
    c = coins(heap_items(cx, cy, rx, ry, h, n, seed, r, base_z), r)
    return [m, c]


def ground(r=1.6, y=0.0, x=0.0, z=-0.02, color=(0.52, 0.4, 0.26), ry=None, seed=3):
    r = r * 0.72; ry = ry * 0.72 if ry else None
    g = fuse([sph((x, y, z), 1, (r, ry or r, 0.07)), sph((x + r * 0.5, y + r * 0.3, z), 1, (r * 0.5, r * 0.4, 0.06))], "ground", 0.04, 0.6, 4)
    setmat(g, mat("soilg", color, 0.95, bump=0.5, bump_scale=18))
    return g


def stone(x, y, r, sc=(1, 0.9, 0.7), color=STONE):
    s = sph((x, y, r * sc[2] * 0.7), r, sc); shade(s); setmat(s, mat("stone", color, 0.9, bump=0.3, bump_scale=14)); return s


def drop(x, y, z, r, material):
    s = sph((x, y, z), 1, (r, r, r * 1.3)); shade(s); setmat(s, material); return s


def spark_pts(c, n, spread, seed, hot_mat, r=0.03, tail=0.25):
    rnd = random.Random(seed); out = []
    for i in range(n):
        d = Vector((rnd.uniform(-1, 1), rnd.uniform(-0.6, 0.6), rnd.uniform(0.1, 1.0))).normalized() * spread * rnd.uniform(0.4, 1.0)
        p = Vector(c) + d
        s = sph(tuple(p), r * rnd.uniform(0.6, 1.2)); shade(s); setmat(s, hot_mat); out.append(s)
        t = tube([tuple(p), tuple(p - d.normalized() * tail * rnd.uniform(0.5, 1.0))], r * 0.45, 0.2, 4); setmat(t, hot_mat); out.append(t)
    return out


def hotm(name="ember", col=FLAME, e=6.0):
    return mat(name, col, 0.4, emit=e)


def barrel(x, y, r=0.3, h=0.6, rot=(0, 0, 0)):
    P = []
    b = cyl((x, y, h / 2), r, h, seg=24, bevel=0.02, r2=r * 0.92); hard(b); setmat(b, mat("wood", WOODC, 0.8, bump=0.4, bump_scale=25)); P.append(b)
    for z in (0.12 * h, 0.5 * h, 0.88 * h):
        t = torus((x, y, z), r * (0.96 if z > 0.1 * h else 0.99), 0.02); shade(t); setmat(t, mat("iron", IRONC, 0.5, 0.6)); P.append(t)
    return P


# ------------------------------------------------------------------ Balde de Óleo

def oil_splash():
    P = []
    woodm = mat("wood", WOODC, 0.8, bump=0.4, bump_scale=25)
    ironm = mat("iron", IRONC, 0.5, 0.6)
    oil = mat("oil", OIL, 0.3, bump=0.1, bump_scale=30)
    b = cyl((0, 0, 0), 0.3, 0.6, seg=28, bevel=0.015, r2=0.38); hard(b)
    inner = cyl((0, 0, 0.06), 0.34, 0.6, seg=28, bevel=0, r2=0.36)
    m = b.modifiers.new("c", 'BOOLEAN'); m.object = inner; m.operation = 'DIFFERENCE'; m.solver = 'EXACT'; apply_mods(b); bpy.data.objects.remove(inner)
    shade(b); setmat(b, woodm); P.append(b)
    for z in (-0.22, 0.2):
        t = torus((0, 0, z), 0.335 if z < 0 else 0.375, 0.022); shade(t); setmat(t, ironm); P.append(t)
    for sx in (-1, 1):
        ear = sph((sx * 0.37, 0, 0.2), 0.04); shade(ear); setmat(ear, ironm); P.append(ear)
    han = tube([(-0.37, 0, 0.2), (-0.3, 0, 0.62), (0, 0, 0.72), (0.3, 0, 0.62), (0.37, 0, 0.2)], 0.018, 1.0, 20); setmat(han, ironm); P.append(han)
    skin = sph((0, 0, 0.19), 1, (0.35, 0.35, 0.02)); setmat(skin, oil); P.append(skin)
    root = group("bucket", P)
    root.location = (0.1, 0.1, 1.45); root.rotation_euler = (rad(66), 0, rad(8))
    bpy.context.view_layer.update()
    lip = root.matrix_world @ Vector((0, -0.37, 0.3))
    # fio de óleo que cai do bocal e a poça com a coroa de respingo
    O = []
    st = tube([tuple(lip), (lip.x - 0.02, lip.y - 0.3, lip.z - 0.14), (lip.x - 0.04, lip.y - 0.45, lip.z - 0.6), (lip.x - 0.05, lip.y - 0.5, 0.18)], 0.075, 0.6, 24)
    setmat(st, oil); O.append(st)
    cx, cy = lip.x - 0.05, lip.y - 0.5
    pud = [sph((cx, cy, 0.04), 1, (0.75, 0.6, 0.06)), sph((cx + 0.5, cy - 0.15, 0.03), 1, (0.35, 0.25, 0.05)), sph((cx - 0.5, cy + 0.2, 0.03), 1, (0.3, 0.25, 0.05))]
    for k in range(11):
        a = k / 11 * math.tau + 0.2; rr = 0.42; ln = 0.35 + 0.15 * ((k * 7) % 3)
        pud += capsule((cx + math.cos(a) * rr * 0.6, cy + math.sin(a) * rr * 0.5, 0.1), (cx + math.cos(a) * rr * 1.5, cy + math.sin(a) * rr * 1.3, 0.1 + ln), 0.055, 0.03)
    pu = fuse(pud, "crown", 0.012, 0.6, 3); setmat(pu, oil); O.append(pu)
    rnd = random.Random(5)
    for k in range(14):
        a = rnd.uniform(0, math.tau); d = rnd.uniform(0.5, 1.1)
        O.append(drop(cx + math.cos(a) * d, cy + math.sin(a) * d * 0.8, rnd.uniform(0.35, 0.95), rnd.uniform(0.025, 0.05), oil))
    group("oil", O)
    group("ground", [ground(1.5, cy, cx, ry=1.1, seed=1)])
    return {"kind": "spell", "dir": (0.45, -1.0, 0.3), "lens": 80}


# ------------------------------------------------------------------ Óleo Fervente

def boiling_oil():
    P = []
    iron = mat("cast", (0.22, 0.22, 0.25), 0.5, 0.7, bump=0.2, bump_scale=40)
    oil = mat("oil", OIL, 0.3, bump=0.1, bump_scale=30)
    pot = sph((0, 0, 0.78), 1, (0.62, 0.62, 0.5)); shade(pot)
    cut = sph((0, 0, 1.18), 1, (0.55, 0.55, 0.32))
    m = pot.modifiers.new("c", 'BOOLEAN'); m.object = cut; m.operation = 'DIFFERENCE'; m.solver = 'EXACT'; apply_mods(pot); bpy.data.objects.remove(cut)
    m = pot.modifiers.new("s", 'SOLIDIFY'); m.thickness = 0.05; apply_mods(pot); shade(pot); setmat(pot, iron); P.append(pot)
    rim = torus((0, 0, 1.09), 0.52, 0.045, s=(1, 1, 1)); shade(rim); setmat(rim, iron); P.append(rim)
    surf = sph((0, 0, 1.02), 1, (0.5, 0.5, 0.05)); setmat(surf, oil); P.append(surf)
    for k in range(7):   # bolhas
        a = k * 2.4; d = 0.08 + 0.34 * ((k * 5) % 7) / 7
        b = sph((math.cos(a) * d, math.sin(a) * d, 1.05), 1, (0.075 - k * 0.006, 0.075 - k * 0.006, 0.06)); shade(b); setmat(b, mat("bubble", (0.3, 0.2, 0.1), 0.2, coat=1.0)); P.append(b)
    for sx in (-1, 1):
        h = tube([(sx * 0.6, 0, 1.0), (sx * 0.78, 0, 1.12), (sx * 0.82, 0, 0.95)], 0.035, 1.0, 12); setmat(h, iron); P.append(h)
    for k in range(3):   # tripé
        a = k * 2.094 + 0.5
        l = tube([(math.cos(a) * 0.38, math.sin(a) * 0.38, 0.55), (math.cos(a) * 0.55, math.sin(a) * 0.55, 0.0)], 0.04, 0.9, 8); setmat(l, mat("blk", (0.1, 0.1, 0.12), 0.6, 0.5)); P.append(l)
    # óleo transbordando pela borda
    for (a, ln) in ((-1.2, 0.65), (-0.3, 0.5), (0.6, 0.7)):
        x, y = math.cos(a) * 0.55, math.sin(a) * 0.55 - 0.1
        d = tube([(x * 0.95, y * 0.95, 1.08), (x * 1.18, y * 1.18, 1.02), (x * 1.22, y * 1.22, 1.0 - ln)], 0.07, 0.5, 14); setmat(d, oil); P.append(d)
    pool = fuse([sph((0, -0.15, 0.03), 1, (1.15, 1.0, 0.05)), sph((0.7, -0.5, 0.03), 1, (0.5, 0.35, 0.04)), sph((-0.8, -0.4, 0.03), 1, (0.4, 0.3, 0.04))], "pool", 0.03, 0.6, 4)
    setmat(pool, oil); P.append(pool)
    group("pot", P)
    F = flame((0, -0.02, 0.02), h=0.75, r=0.2, lean=(0.0, 0.0)) + flame((-0.4, 0.15, 0.02), h=0.5, r=0.14, lean=(-0.06, 0)) + flame((0.42, 0.12, 0.02), h=0.55, r=0.15, lean=(0.06, 0))
    F += flame((0.1, -0.25, 1.1), h=0.6, r=0.17, lean=(0.04, 0))   # óleo pegando fogo na superfície
    group("fire", F)
    group("ground", [ground(1.5, -0.1)])
    return {"kind": "spell", "dir": (0.4, -1.0, 0.3), "lens": 80}


# ------------------------------------------------------------------ Isca de Ouro

def gold_bait():
    P = []
    sack_m = mat("sack", (0.68, 0.55, 0.36), 0.9, bump=0.5, bump_scale=60)
    sack = fuse([sph((0, 0, 0.42), 1, (0.55, 0.5, 0.42)), sph((0, 0.0, 0.85), 1, (0.3, 0.28, 0.2)), sph((0.25, -0.3, 0.2), 1, (0.3, 0.2, 0.2))], "sack", 0.02, 0.7, 6)
    setmat(sack, sack_m); P.append(sack)
    tie = torus((0, 0, 0.78), 0.2, 0.03, s=(1, 1, 1)); shade(tie); setmat(tie, mat("cord", (0.45, 0.25, 0.12), 0.8)); P.append(tie)
    for sx in (-1, 1):
        fl = sph((sx * 0.2, 0, 1.08), 1, (0.14, 0.05, 0.16), (0, 0, sx * 30)); shade(fl); setmat(fl, sack_m); P.append(fl)
    sm = mat("goldsign", GOLDC, 0.3, 1.0)
    sg = cyl((0, -0.4, 0.5), 0.17, 0.05, (90, 0, 0), seg=24, bevel=0.01); hard(sg); setmat(sg, sm); P.append(sg)
    P += coins(heap_items(0.0, -0.1, 0.5, 0.45, 0.5, 32, 4, 0.085), 0.085),
    group("sack", P)
    # estrada de pedras com rastro de moedas
    R = []
    for i in range(9):
        t = i / 8.0
        x = -2.2 + t * 2.0 + 0.0; y = -1.5 + t * 1.0 + math.sin(t * 5) * 0.12
        b = box((x, y, 0.03), (0.34 + (i % 2) * 0.06, 0.26, 0.07), (0, 0, 20 + i * 11), bevel=0.02); hard(b); setmat(b, mat("stone", STONE, 0.9, bump=0.3, bump_scale=14)); R.append(b)
    items = []
    for i in range(7):
        t = i / 7.0
        items.append(((-2.2 + t * 2.0 + 0.1, -1.38 + t * 0.95, 0.09 + 0.012 * (i % 2)), (0.2, -0.1, 1.0) if i % 2 else (0, 0.3, 1.0)))
    R.append(coins(items, 0.07, 0.02, "trail"))
    group("road", R)
    # vara com fio e moeda grande pendurada: a isca
    wd = mat("wood", WOODC, 0.8, bump=0.4, bump_scale=25)
    pole = tube([(1.5, 0.3, 0.0), (1.45, 0.3, 1.5), (1.0, 0.2, 2.1), (0.3, -0.2, 2.3)], 0.03, 0.5, 20); setmat(pole, wd)
    line = tube([(0.3, -0.2, 2.3), (0.28, -0.22, 1.7), (0.3, -0.24, 1.45)], 0.006, 1.0, 6); setmat(line, mat("line", (0.9, 0.88, 0.8), 0.5))
    big = cyl((0.3, -0.26, 1.32), 0.2, 0.04, (90, 0, 10), seg=28, bevel=0.01); hard(big); setmat(big, sm)
    rim = torus((0.3, -0.26, 1.32), 0.2, 0.02, (90, 0, 10)); shade(rim); setmat(rim, sm)
    group("rod", [pole, line, big, rim])
    return {"kind": "route", "dir": (0.4, -1.0, 0.35), "lens": 70}


# ------------------------------------------------------------------ Moedas Amaldiçoadas

def cursed_coins():
    P = []
    gm = mat("cgold", (0.78, 0.6, 0.3), 0.35, 1.0)
    dark = mat("shadow", (0.03, 0.02, 0.03), 0.9)
    glow = mat("curse", PURP, 0.4, emit=5.0)
    # moeda grande de frente, com caveira em relevo
    big = cyl((0, 0, 1.0), 0.62, 0.1, (90, 0, 0), seg=40, bevel=0.02); hard(big); setmat(big, gm); P.append(big)
    rim = torus((0, 0, 1.0), 0.62, 0.05, (90, 0, 0)); shade(rim); setmat(rim, gm); P.append(rim)
    sk = fuse([sph((0, -0.08, 1.07), 1, (0.22, 0.05, 0.24)), sph((0, -0.08, 0.89), 1, (0.14, 0.05, 0.1))], "skull", 0.006)
    setmat(sk, mat("bone", BONE, 0.6)); P.append(sk)
    for sx in (-1, 1):
        e = sph((sx * 0.08, -0.12, 1.08), 1, (0.05, 0.03, 0.06)); setmat(e, dark); P.append(e)
    nz = box((0, -0.12, 0.99), (0.04, 0.02, 0.05), (0, 45, 0), bevel=0.004); hard(nz); setmat(nz, dark); P.append(nz)
    for k in range(5):
        t = box((-0.08 + k * 0.04, -0.12, 0.86), (0.025, 0.02, 0.05), bevel=0.004); hard(t); setmat(t, dark); P.append(t)
    for k in range(16):   # letras em volta (risquinhos)
        a = k / 16 * math.tau
        c = box((math.cos(a) * 0.5, -0.07, 1.0 + math.sin(a) * 0.5), (0.05, 0.02, 0.025), (0, -math.degrees(a), 0), bevel=0.003); hard(c); setmat(c, mat("etch", (0.4, 0.3, 0.15), 0.6, 0.8)); P.append(c)
    # moedas menores girando em espiral
    items = []
    for k in range(9):
        a = k * 0.9 + 0.3
        p = Vector((math.cos(a) * (0.95 + k * 0.05), 0.15 - k * 0.07, 0.25 + k * 0.17)); items.append((p, Vector((math.cos(a) * 0.4, -1, 0.5))))
    P.append(coins(items, 0.15, 0.04, "orbit", 20, gm))
    group("coins", P)
    G = []
    for k in range(4):   # fumaça arroxeada que sobe das moedas
        ox = (-0.8, -0.3, 0.5, 1.0)[k]
        w = tube([(ox, 0.2, 0.05), (ox - 0.2, 0.2, 0.4), (ox + 0.15, 0.2, 0.75), (ox - 0.1, 0.2, 1.15 + k * 0.1), (ox + 0.1, 0.2, 1.5 + k * 0.1)], 0.045, 0.15, 24); setmat(w, glow); G.append(w)
    G += spark_pts((0, 0, 1.0), 10, 1.1, 7, glow, 0.03, 0.15)
    group("curse", G)
    pile = gold_heap(0.0, 0.25, 0.9, 0.5, 0.25, 22, 5, 0.09)
    group("pile", pile)
    return {"kind": "spell", "dir": (0.25, -1.0, 0.12), "lens": 80}


# ------------------------------------------------------------------ Rede de Piche

def tar_net():
    P = []
    tarm = mat("tar", (0.13, 0.1, 0.08), 0.35, bump=0.15, bump_scale=40)
    rope = mat("rope", (0.45, 0.35, 0.2), 0.9, bump=0.6, bump_scale=80)
    N = 7
    def pt(i, j):
        u = i / (N - 1.0) - 0.5; v = j / (N - 1.0) - 0.5
        return (u * 2.4 * (1 + 0.1 * v), v * 1.8 + math.sin(u * 3) * 0.1, 1.0 + 0.5 * (0.25 - (u * u + v * v)) * 1.4 + 0.15 * math.sin(u * 4 + v * 3))
    for i in range(N):
        t = tube([pt(i, j) for j in range(N)], 0.028, 1.0, 16); setmat(t, rope); P.append(t)
    for j in range(N):
        t = tube([pt(i, j) for i in range(N)], 0.028, 1.0, 16); setmat(t, rope); P.append(t)
    for i in range(N):
        for j in range(N):
            k = sph(pt(i, j), 0.06); shade(k); setmat(k, tarm if (i + j) % 2 == 0 else rope); P.append(k)
    # estacas nos cantos
    wd = mat("wood", WOODC, 0.8, bump=0.4, bump_scale=25)
    for (i, j) in ((0, 0), (N - 1, 0), (0, N - 1), (N - 1, N - 1)):
        p = pt(i, j)
        s = cyl((p[0] * 1.05, p[1] * 1.05, 0.55), 0.06, 1.2, seg=10, bevel=0.01, r2=0.08); hard(s); setmat(s, wd); P.append(s)
    # piche escorrendo
    rnd = random.Random(2)
    for k in range(9):
        i = rnd.randint(1, N - 2); j = rnd.randint(1, N - 2); p = pt(i, j); ln = rnd.uniform(0.2, 0.7)
        d = tube([p, (p[0], p[1], p[2] - ln * 0.5), (p[0], p[1], p[2] - ln)], 0.03, 0.5, 8); setmat(d, tarm); P.append(d)
        P.append(drop(p[0], p[1], p[2] - ln - 0.06, 0.04, tarm))
    for (i, j) in ((2, 2), (3, 3), (4, 2), (3, 4)):
        p = pt(i, j); b = sph((p[0], p[1], p[2]), 1, (0.17, 0.14, 0.07)); shade(b); setmat(b, tarm); P.append(b)
    pool = fuse([sph((0, 0, 0.03), 1, (1.2, 0.9, 0.05)), sph((0.9, -0.5, 0.03), 1, (0.4, 0.3, 0.04)), sph((-0.8, 0.4, 0.03), 1, (0.35, 0.3, 0.04))], "pool", 0.03, 0.6, 4); setmat(pool, tarm); P.append(pool)
    group("net", P)
    group("ground", [ground(1.9, 0.0, 0.0)])
    return {"kind": "spell", "dir": (0.35, -1.0, 0.5), "lens": 75}


# ------------------------------------------------------------------ Pedágio

def toll():
    P = []
    wd = mat("wood", WOODC, 0.8, bump=0.4, bump_scale=25)
    red = mat("red", (0.75, 0.1, 0.1), 0.7); white = mat("white", (0.93, 0.9, 0.82), 0.7)
    gm = mat("gold", GOLDC, 0.3, 1.0)
    for sx in (-1, 1):   # dois postes e uma cancela listrada
        po = box((sx * 1.2, 0, 0.7), (0.2, 0.2, 1.4), (0, 0, 0), bevel=0.03); hard(po); setmat(po, wd); P.append(po)
        cap = box((sx * 1.2, 0, 1.45), (0.28, 0.28, 0.1), bevel=0.02); hard(cap); setmat(cap, mat("iron", IRONC, 0.5, 0.6)); P.append(cap)
    for k in range(8):
        b = box((-1.0 + k * 0.28, 0, 0.9 + k * 0.01), (0.28, 0.1, 0.1), bevel=0.01); hard(b); setmat(b, red if k % 2 else white); P.append(b)
    # placa com a moeda
    board = box((-1.2, -0.2, 1.75), (0.7, 0.06, 0.5), (0, 0, 0), bevel=0.03); hard(board); setmat(board, wd); P.append(board)
    cn = cyl((-1.2, -0.25, 1.75), 0.17, 0.03, (90, 0, 0), seg=24, bevel=0.005); hard(cn); setmat(cn, gm); P.append(cn)
    # cofre de moedas com a mão aberta pedindo
    box_ = box((0.2, -0.9, 0.2), (0.7, 0.45, 0.4), (0, 0, -8), bevel=0.04); hard(box_); setmat(box_, wd); P.append(box_)
    for dx in (-0.22, 0.22):
        bd = box((0.2 + dx, -0.9, 0.2), (0.07, 0.48, 0.42), (0, 0, -8), bevel=0.01); hard(bd); setmat(bd, mat("iron", IRONC, 0.5, 0.6)); P.append(bd)
    slot = box((0.2, -0.9, 0.41), (0.3, 0.05, 0.02), (0, 0, -8), bevel=0.003); hard(slot); setmat(slot, mat("shadow", (0.03, 0.02, 0.03), 0.9)); P.append(slot)
    # moeda caindo no cofre, outras no tampo
    cc = cyl((0.15, -0.86, 0.95), 0.14, 0.035, (80, 0, -8), seg=24, bevel=0.005); hard(cc); setmat(cc, gm); P.append(cc)
    ccr = torus((0.15, -0.86, 0.95), 0.14, 0.018, (80, 0, -8)); shade(ccr); setmat(ccr, gm); P.append(ccr)
    for (t, z) in ((0.15, 0.65), (0.12, 0.4)):
        pass
    P.append(coins([((0.5, -0.75, 0.43), (0.1, 0.1, 1)), ((0.38, -1.0, 0.425), (0, 0.3, 1)), ((-0.1, -1.05, 0.41), (0.2, 0, 1)), ((0.62, -1.05, 0.42), (0, 0, 1))], 0.1, 0.025))
    # três gotas de elixir (o que se ganha)
    for k in range(3):
        e = sph((0.95 + k * 0.17, -0.85, 0.6 + (k % 2) * 0.12), 1, (0.07, 0.07, 0.1)); shade(e); setmat(e, mat("elixir", (0.7, 0.2, 0.9), 0.3, emit=4.0)); P.append(e)
    group("toll", P)
    group("road", [ground(2.0, -0.3, 0.0, ry=1.3)])
    return {"kind": "spell", "dir": (0.35, -1.0, 0.3), "lens": 70}


# ------------------------------------------------------------------ Faísca

def spark():
    P = []
    flint = fuse([sph((0.0, 0, 0.18), 1, (0.55, 0.38, 0.2)), sph((0.3, 0.1, 0.15), 1, (0.3, 0.25, 0.16)), sph((-0.3, -0.05, 0.25), 1, (0.3, 0.25, 0.2))], "flint", 0.02, 0.4, 3)
    setmat(flint, mat("flint", (0.38, 0.4, 0.45), 0.5, bump=0.5, bump_scale=14)); P.append(flint)
    steel = mat("steel", (0.6, 0.62, 0.68), 0.35, 0.9)
    st = tube([(1.3, -0.1, 0.95), (0.75, -0.1, 1.15), (0.3, -0.12, 0.62), (0.05, -0.12, 0.42)], 0.05, 0.8, 18); setmat(st, steel); P.append(st)
    grip = tube([(1.3, -0.1, 0.95), (1.75, -0.08, 1.2), (1.95, -0.05, 0.95), (1.75, -0.05, 0.75), (1.35, -0.1, 0.8)], 0.045, 1.0, 20); setmat(grip, mat("leather", (0.38, 0.22, 0.12), 0.55)); P.append(grip)
    group("strike", P)
    hm = hotm("spk", FLAME_HOT, 9.0)
    F = spark_pts((0.05, -0.12, 0.45), 14, 1.1, 11, hm, 0.032, 0.32)
    F += flame((-0.55, -0.45, 0.02), h=0.5, r=0.14, lean=(-0.1, 0))      # a faísca pegou no gravetos
    tw = mat("twig", (0.35, 0.22, 0.12), 0.9)
    for (a, ln) in ((0.3, 0.7), (1.2, 0.6), (2.0, 0.55), (-0.5, 0.65)):
        t = tube([(-0.55 + math.cos(a) * 0.1, -0.45 + math.sin(a) * 0.1, 0.05), (-0.55 + math.cos(a) * ln, -0.45 + math.sin(a) * ln, 0.04)], 0.025, 0.7, 6); setmat(t, tw); F.append(t)
    big = sph((0.05, -0.15, 0.48), 1, (0.13, 0.05, 0.13)); setmat(big, hm); F.append(big)
    for k in range(4):   # raios da estrela da faísca
        a = k * math.pi / 4
        r = tube([(0.05 - math.cos(a) * 0.25, -0.2, 0.48 - math.sin(a) * 0.25), (0.05 + math.cos(a) * 0.25, -0.2, 0.48 + math.sin(a) * 0.25)], 0.014, 0.4, 4); setmat(r, hm); F.append(r)
    group("fx", F)
    group("ground", [ground(1.7, -0.2, 0.3, ry=1.0)])
    return {"kind": "spell", "dir": (0.1, -1.0, 0.2), "lens": 75}


# ------------------------------------------------------------------ Ouro Derretido

def molten_gold():
    P = []
    clay = mat("clay", (0.6, 0.34, 0.2), 0.85, bump=0.4, bump_scale=30)
    hot = mat("hotgold", (1.0, 0.72, 0.2), 0.3, emit=5.0)
    cr = cyl((0, 0, 0), 0.4, 0.62, seg=32, bevel=0.015, r2=0.56); hard(cr)
    inner = cyl((0, 0, 0.1), 0.35, 0.6, seg=32, bevel=0, r2=0.5)
    m = cr.modifiers.new("c", 'BOOLEAN'); m.object = inner; m.operation = 'DIFFERENCE'; m.solver = 'EXACT'; apply_mods(cr); bpy.data.objects.remove(inner)
    shade(cr); setmat(cr, clay); P.append(cr)
    rim = torus((0, 0, 0.31), 0.56, 0.025); shade(rim); setmat(rim, clay); P.append(rim)
    sf = sph((0, 0, 0.22), 1, (0.5, 0.5, 0.025)); setmat(sf, hot); P.append(sf)
    for sx in (-1, 1):
        for k in (0, 1):
            pass
    tong = mat("iron", IRONC, 0.5, 0.6)
    for sx in (-1, 1):
        t = tube([(sx * 0.58, 0, 0.16), (sx * 0.9, 0, 0.5), (sx * 1.4, 0, 1.05), (sx * 1.9, 0, 1.55)], 0.03, 1.0, 14); setmat(t, tong); P.append(t)
    root = group("crucible", P)
    root.location = (0.0, 0.0, 1.5); root.rotation_euler = (rad(68), 0, rad(-6))
    bpy.context.view_layer.update()
    lip = root.matrix_world @ Vector((0, -0.55, 0.3))
    G = []
    st = tube([tuple(lip), (lip.x, lip.y - 0.25, lip.z - 0.2), (lip.x, lip.y - 0.4, lip.z - 0.7), (lip.x, lip.y - 0.42, 0.3)], 0.1, 0.55, 24); setmat(st, hot); G.append(st)
    cx, cy = lip.x, lip.y - 0.42
    pud = [sph((cx, cy, 0.05), 1, (0.8, 0.65, 0.06)), sph((cx + 0.45, cy - 0.2, 0.04), 1, (0.4, 0.3, 0.05))]
    for k in range(9):
        a = k / 9 * math.tau; pud += capsule((cx + math.cos(a) * 0.3, cy + math.sin(a) * 0.25, 0.1), (cx + math.cos(a) * 0.8, cy + math.sin(a) * 0.65, 0.35 + 0.1 * (k % 3)), 0.06, 0.03)
    pu = fuse(pud, "gpud", 0.012, 0.6, 3); setmat(pu, hot); G.append(pu)
    rnd = random.Random(9)
    for k in range(12):
        a = rnd.uniform(0, math.tau); d = rnd.uniform(0.6, 1.2); G.append(drop(cx + math.cos(a) * d, cy + math.sin(a) * d * 0.8, rnd.uniform(0.3, 0.9), rnd.uniform(0.03, 0.055), hot))
    group("molten", G)
    # moedas sólidas ao redor, já frias
    group("cool", [coins([((cx - 1.2, cy + 0.3, 0.02), (0, 0, 1)), ((cx + 1.15, cy + 0.2, 0.025), (0.1, 0, 1)), ((cx - 0.95, cy - 0.5, 0.02), (0, 0.1, 1)), ((cx + 1.0, cy - 0.5, 0.03), (0.2, 0.1, 1))], 0.1, 0.025),
                   ground(1.7, cy, cx, ry=1.2)])
    return {"kind": "spell", "dir": (0.45, -1.0, 0.3), "lens": 80}


# (as demais cenas vêm abaixo; o registro SCENES_DRAGON fica no fim do arquivo)


# ------------------------------------------------------------------ Kobolds

def kobold(sack=True, pick=False, coin=False):
    P = []
    SC = (0.74, 0.43, 0.2); SD = (0.42, 0.2, 0.12)
    body = fuse([
        sph((0, 0, 0.42), 1, (0.17, 0.15, 0.2)), sph((0, -0.04, 0.78), 1, (0.17, 0.17, 0.16)), sph((0, -0.2, 0.74), 1, (0.08, 0.13, 0.07)),
        capsule((0.1, 0, 0.3), (0.12, -0.04, 0.05), 0.06, 0.05), capsule((-0.1, 0, 0.3), (-0.12, 0.0, 0.05), 0.06, 0.05),
        capsule((0.16, -0.02, 0.55), (0.26, -0.18, 0.42), 0.045, 0.04), capsule((-0.16, -0.02, 0.55), (-0.25, -0.15, 0.4), 0.045, 0.04),
        sph((0.12, -0.08, 0.04), 1, (0.06, 0.1, 0.03)), sph((-0.12, -0.04, 0.04), 1, (0.06, 0.1, 0.03)),
        capsule((0, 0.12, 0.3), (0.0, 0.4, 0.1), 0.06, 0.015),
    ], "kobold", 0.009, 0.6, 5)
    paint(body, lambda p, n: mix(SD, SC, smoothstep(-0.3, 0.8, n.z) * 0.7 + 0.2)); setmat(body, mat("kobskin", vcol=True, rough=0.6, bump=0.2, bump_scale=90)); P.append(body)
    hm = mat("kobhorn", (0.9, 0.82, 0.6), 0.5)
    for sx in (-1, 1):
        P += monsters2.yellow_eye((sx * 0.085, -0.17, 0.83), 0.055, 15, sx)
        h = tube([(sx * 0.08, 0.0, 0.92), (sx * 0.14, 0.04, 1.04), (sx * 0.12, 0.1, 1.1)], 0.028, 0.15, 8); setmat(h, hm); P.append(h)
    nos = mat("kobnos", (0.1, 0.06, 0.06), 0.5)
    for sx in (-1, 1):
        n = sph((sx * 0.03, -0.32, 0.78), 0.015); setmat(n, nos); P.append(n)
    for k in range(3):   # espinhos na nuca
        sp = box((0, 0.1 + k * 0.06, 0.97 - k * 0.06), (0.03, 0.05, 0.08), (30, 0, 0), bevel=0.005, taper=(0.1, 0.2)); hard(sp); setmat(sp, hm); P.append(sp)
    sh = mat("sackk", (0.66, 0.52, 0.34), 0.9, bump=0.5, bump_scale=60)
    if sack:
        sk = fuse([sph((0, 0.25, 0.6), 1, (0.2, 0.18, 0.22)), sph((0, 0.22, 0.82), 1, (0.1, 0.09, 0.08))], "ksack", 0.012, 0.7, 4); setmat(sk, sh); P.append(sk)
        P.append(coins([((0, 0.2, 0.93), (0, 0, 1)), ((0.05, 0.2, 0.95), (0.3, 0, 1))], 0.06, 0.02))
    if pick:
        hd = tube([(0.26, -0.18, 0.12), (0.32, -0.2, 0.75)], 0.018, 1.0, 6); setmat(hd, mat("wood", WOODC, 0.8)); P.append(hd)
        pk = tube([(0.14, -0.2, 0.78), (0.32, -0.2, 0.86), (0.5, -0.2, 0.76)], 0.03, 0.2, 10); setmat(pk, mat("iron", IRONC, 0.5, 0.6)); P.append(pk)
    if coin:
        c = cyl((0.28, -0.3, 0.62), 0.11, 0.025, (90, 0, 20), seg=20, bevel=0.003); hard(c); setmat(c, mat("gold", GOLDC, 0.3, 1.0)); P.append(c)
    return group("kobold", P)


def kobold_scavengers():
    group("hoard", gold_heap(0.0, 0.1, 0.9, 0.7, 0.45, 40, 3, 0.085))
    place(kobold(True, False, True), (-0.95, -0.6, 0), rot_z=35, scale=1.0)
    place(kobold(True, True, False), (0.95, -0.55, 0), rot_z=-40, scale=0.95)
    place(kobold(True, False, False), (0.0, -1.05, 0), rot_z=8, scale=0.88)
    place(kobold(False, False, True), (-0.1, 0.5, 0.35), rot_z=190, scale=0.8)
    group("ground", [ground(2.0, -0.3)])
    return {"kind": "swarm", "dir": (0.3, -1.0, 0.28), "lens": 70}


# ------------------------------------------------------------------ Baú Armadilha

def dynamite(x, y, z, rot=(0, 0, 0), L=0.4):
    red = mat("dyn", (0.72, 0.1, 0.08), 0.7)
    d = cyl((x, y, z), 0.055, L, rot, seg=14, bevel=0.01); hard(d); setmat(d, red)
    return d


def trap_chest():
    P = []
    woodm = mat("chestwood", (0.55, 0.32, 0.16), 0.7, bump=0.3, bump_scale=14)
    metal = mat("chestiron", (0.38, 0.36, 0.4), 0.45, 0.8)
    gold = mat("gold", GOLDC, 0.3, 1.0)
    base = box((0, 0, 0.35), (1.3, 0.8, 0.7), bevel=0.05, seg=2); hard(base); setmat(base, woodm); P.append(base)
    for x in (-0.5, 0.5):
        b = box((x, 0, 0.35), (0.1, 0.84, 0.74), bevel=0.02); hard(b); setmat(b, metal); P.append(b)
    inner = box((0, 0, 0.7), (1.15, 0.65, 0.05), bevel=0); setmat(inner, mat("shadow", (0.05, 0.03, 0.03), 0.9)); P.append(inner)
    P += gold_heap(0, 0, 0.5, 0.28, 0.32, 24, 2, 0.085, 0.68)
    lid = []
    lm = box((0, 0.0, 0.0), (1.32, 0.82, 0.22), bevel=0.06, seg=3); hard(lm); setmat(lm, woodm); lid.append(lm)
    for x in (-0.5, 0.5):
        b = box((x, 0, 0.0), (0.1, 0.86, 0.26), bevel=0.02); hard(b); setmat(b, metal); lid.append(b)
    lock = box((0, -0.43, -0.05), (0.16, 0.05, 0.2), bevel=0.02); hard(lock); setmat(lock, gold); lid.append(lock)
    for k in range(9):   # dentes de ferro por dentro da tampa: armadilha
        t = box((-0.5 + k * 0.125, -0.32, -0.15), (0.06, 0.05, 0.16), (180, 0, 0), bevel=0.005, taper=(0.1, 0.5)); hard(t); setmat(t, mat("tooth", (0.85, 0.85, 0.8), 0.3, 0.5)); lid.append(t)
    lr = group("lid", lid)
    lr.location = (0, 0.4, 0.82); lr.rotation_euler = (rad(-70), 0, 0)
    group("chest", P)
    # dinamite amarrada dentro do baú e pavio aceso
    D = [dynamite(-0.3, 0.05, 0.9, (0, 20, 10)), dynamite(-0.18, -0.05, 0.92, (0, 10, -5)), dynamite(-0.05, 0.05, 0.9, (0, -10, 0))]
    band = torus((-0.18, 0.0, 0.9), 0.12, 0.012, (0, 90, 0)); shade(band); setmat(band, mat("cord", (0.4, 0.25, 0.12), 0.8)); D.append(band)
    fz = tube([(-0.12, 0.0, 1.08), (0.0, -0.1, 1.2), (0.1, -0.05, 1.28), (0.18, -0.12, 1.4)], 0.012, 1.0, 10); setmat(fz, mat("fuse", (0.15, 0.1, 0.07), 0.8)); D.append(fz)
    group("dyn", D)
    F = flame((0.18, -0.12, 1.4), h=0.25, r=0.07)
    F += spark_pts((0.18, -0.12, 1.45), 8, 0.35, 4, hotm("spk", FLAME_HOT, 9.0), 0.022, 0.12)
    group("fz", F)
    # fio de gatilho ligando a tampa a uma estaca
    tw = tube([(0.65, -0.4, 0.78), (1.0, -0.8, 0.2), (1.3, -1.2, 0.08)], 0.01, 1.0, 10); setmat(tw, mat("wire", (0.2, 0.2, 0.2), 0.5))
    stk = cyl((1.3, -1.2, 0.2), 0.04, 0.4, seg=8, bevel=0.005); hard(stk); setmat(stk, mat("wood", WOODC, 0.8))
    group("wire", [tw, stk])
    group("ground", [ground(1.9, -0.2, 0.2)])
    return {"kind": "structure", "dir": (0.45, -1.0, 0.4), "lens": 75}


# ------------------------------------------------------------------ Fornalha

def furnace():
    P = []
    st = mat("brick", (0.5, 0.36, 0.3), 0.9, bump=0.5, bump_scale=18)
    stl = mat("stoneb", (0.6, 0.57, 0.52), 0.9, bump=0.4, bump_scale=14)
    base = box((0, 0, 0.9), (1.7, 1.3, 1.8), bevel=0.05, taper=(0.85, 0.85)); hard(base); setmat(base, st); P.append(base)
    for z in (0.2, 0.6, 1.0, 1.4):   # fiadas de tijolos marcadas
        b = box((0, -0.66, z), (1.76, 0.03, 0.025), bevel=0.003); hard(b); setmat(b, mat("mort", (0.25, 0.18, 0.15), 0.9)); P.append(b)
    ch = box((0.35, 0.2, 2.5), (0.6, 0.6, 1.3), bevel=0.04, taper=(0.8, 0.8)); hard(ch); setmat(ch, st); P.append(ch)
    cp = box((0.35, 0.2, 3.2), (0.8, 0.8, 0.16), bevel=0.03); hard(cp); setmat(cp, stl); P.append(cp)
    arch = cyl((0, -0.62, 0.7), 0.5, 0.2, (90, 0, 0), seg=24, bevel=0.0); hard(arch); setmat(arch, mat("mouth", (0.05, 0.03, 0.03), 0.9)); P.append(arch)
    for k in range(7):   # pedras do arco
        a = rad(180 - k * 30)
        s = box((math.cos(a) * 0.58, -0.7, 0.7 + math.sin(a) * 0.58), (0.18, 0.22, 0.17), (0, -math.degrees(a) + 90, 0), bevel=0.02); hard(s); setmat(s, stl); P.append(s)
    for sx in (-1, 1):
        fb = box((sx * 0.58, -0.7, 0.38), (0.18, 0.22, 0.4), bevel=0.02); hard(fb); setmat(fb, stl); P.append(fb)
    grate = mat("iron", IRONC, 0.5, 0.6)
    for k in range(5):
        g = cyl((-0.3 + k * 0.15, -0.72, 0.1), 0.025, 0.7, (90, 0, 0), seg=8, bevel=0); hard(g); setmat(g, grate); P.append(g)
    glow = sph((0, -0.72, 0.45), 1, (0.42, 0.1, 0.32)); setmat(glow, mat("hotc", (1.0, 0.45, 0.1), 0.4, emit=5.0)); P.append(glow)
    for (x, z, r) in ((-0.2, 0.18, 0.1), (0.15, 0.2, 0.08), (0.0, 0.15, 0.09)):
        c = sph((x, -0.77, z), 1, (r, r, r * 0.7)); shade(c); setmat(c, mat("coalh", (1.0, 0.5, 0.1), 0.4, emit=6.0)); P.append(c)
    group("body", P)
    F = flame((0, -0.84, 0.3), h=0.85, r=0.22) + flame((-0.25, -0.82, 0.25), h=0.55, r=0.13, lean=(-0.05, 0)) + flame((0.28, -0.82, 0.25), h=0.6, r=0.14, lean=(0.05, 0))
    group("fire", F)
    sm = mat("smoke", (0.5, 0.48, 0.46), 0.95); G = []
    for (x, z, r) in ((0.35, 3.45, 0.2), (0.5, 3.75, 0.26), (0.3, 4.1, 0.3), (0.55, 4.5, 0.34)):
        s = sph((x, 0.2, z), 1, (r, r, r * 0.85)); shade(s); setmat(s, sm); G.append(s)
    group("smoke", G)
    cb = cyl((1.3, -0.5, 0.18), 0.22, 0.36, seg=16, bevel=0.015, r2=0.28); hard(cb); setmat(cb, mat("wood", WOODC, 0.8)); coalp = [sph((1.3 + k * 0.08 - 0.1, -0.5 + (k % 2) * 0.08, 0.4), 1, (0.09, 0.09, 0.07)) for k in range(4)]
    for c in coalp:
        shade(c); setmat(c, mat("coal", (0.08, 0.07, 0.07), 0.6))
    group("bucket", [cb] + coalp)
    anv = fuse([box((-1.4, -0.5, 0.3), (0.55, 0.3, 0.2), bevel=0.02), box((-1.4, -0.5, 0.15), (0.3, 0.2, 0.3), bevel=0.02), box((-1.4, -0.5, 0.45), (0.8, 0.28, 0.16), bevel=0.03, taper=(0.9, 0.9))], "anvil", 0.015, 0.4, 3)
    setmat(anv, mat("anvil", (0.25, 0.25, 0.3), 0.4, 0.7))
    group("ground", [ground(2.3, -0.3)])
    return {"kind": "structure", "dir": (0.45, -1.0, 0.25), "lens": 75}


# ------------------------------------------------------------------ Cofre do Dragão

def dragon_vault():
    P = []
    stl = mat("stoneb", (0.55, 0.52, 0.5), 0.9, bump=0.4, bump_scale=14)
    steel = mat("steel", (0.55, 0.57, 0.63), 0.35, 0.9, bump=0.1, bump_scale=60)
    gold = mat("gold", GOLDC, 0.3, 1.0)
    hot = mat("hotgold", (1.0, 0.7, 0.2), 0.3, emit=3.0)
    for sx in (-1, 1):
        p = box((sx * 1.35, 0, 1.2), (0.55, 0.9, 2.4), bevel=0.05); hard(p); setmat(p, stl); P.append(p)
    lin = box((0, 0, 2.55), (3.2, 0.9, 0.5), bevel=0.05); hard(lin); setmat(lin, stl); P.append(lin)
    keys = box((0, -0.46, 2.55), (0.3, 0.06, 0.5), bevel=0.02); hard(keys); setmat(keys, mat("goldkey", GOLDC, 0.3, 1.0)); P.append(keys)
    back = box((0, 0.3, 1.1), (2.2, 0.4, 2.3), bevel=0); setmat(back, mat("shadow", (0.05, 0.03, 0.03), 0.9)); P.append(back)
    sl = box((0, 0.0, 0.05), (2.2, 0.9, 0.1), bevel=0.01); hard(sl); setmat(sl, stl); P.append(sl)
    gl = box((0, 0.05, 1.0), (1.9, 0.1, 1.6), bevel=0); setmat(gl, hot); P.append(gl)   # luz do ouro lá dentro
    group("frame", P)
    group("hoard", gold_heap(0.0, -0.1, 0.9, 0.4, 0.8, 50, 8, 0.1, 0.05) + gold_heap(-0.45, 0.1, 0.45, 0.3, 0.7, 20, 9, 0.1, 0.05))
    # porta redonda aberta, girada na dobradiça
    D = []
    disc = cyl((0, 0, 0), 1.0, 0.24, (90, 0, 0), seg=48, bevel=0.03); hard(disc); setmat(disc, steel); D.append(disc)
    for r, t in ((0.9, 0.04), (0.45, 0.05)):
        rg = torus((0, -0.12, 0), r, t, (90, 0, 0)); shade(rg); setmat(rg, steel); D.append(rg)
    for k in range(16):
        a = k / 16 * math.tau
        rv = sph((math.cos(a) * 0.78, -0.13, math.sin(a) * 0.78), 0.035); shade(rv); setmat(rv, mat("rivet", (0.7, 0.72, 0.78), 0.3, 0.9)); D.append(rv)
    for k in range(5):
        a = k / 5 * math.tau + 0.3
        sp = tube([(0, -0.16, 0), (math.cos(a) * 0.5, -0.17, math.sin(a) * 0.5)], 0.035, 1.0, 6); setmat(sp, steel); D.append(sp)
    hub = sph((0, -0.2, 0), 1, (0.2, 0.1, 0.2)); shade(hub); setmat(hub, gold); D.append(hub)
    for sx in (-1, 1):   # emblema: chifres e olho de dragão
        h = tube([(sx * 0.14, -0.2, 0.1), (sx * 0.34, -0.2, 0.28), (sx * 0.28, -0.2, 0.55)], 0.05, 0.15, 10); setmat(h, gold); D.append(h)
    ey = sph((0, -0.29, 0), 1, (0.06, 0.03, 0.09)); setmat(ey, mat("eyered", (1.0, 0.2, 0.1), 0.4, emit=5.0)); D.append(ey)
    dr = group("door", D)
    piv = bpy.data.objects.new("pivot", None); bpy.context.scene.collection.objects.link(piv)
    piv.location = (-1.1, -0.2, 0.0); dr.parent = piv; dr.location = (1.0, 0, 1.1); piv.rotation_euler = (0, 0, rad(-75))
    hg = []
    for z in (0.5, 1.7):
        h = cyl((-1.12, -0.25, z), 0.06, 0.25, seg=10, bevel=0.005); hard(h); setmat(h, steel); hg.append(h)
    group("hinges", hg)
    group("ground", [ground(2.6, -0.8, 0.0, ry=1.6)])
    return {"kind": "structure", "dir": (0.5, -1.0, 0.22), "lens": 70}


# ------------------------------------------------------------------ Imposto de Sangue

def blood_tax():
    P = []
    pap = mat("page", (0.92, 0.86, 0.7), 0.9, bump=0.2, bump_scale=60)
    cov = mat("cover", (0.35, 0.1, 0.1), 0.7, bump=0.3, bump_scale=40)
    blood = mat("blood", (0.62, 0.04, 0.07), 0.25, bump=0.1, bump_scale=30)
    gold = mat("gold", GOLDC, 0.3, 1.0)
    for sx in (-1, 1):
        c = box((sx * 0.62, 0.0, 0.03), (1.2, 1.6, 0.07), (0, sx * -3, sx * -2), bevel=0.02); hard(c); setmat(c, cov); P.append(c)
        pg = box((sx * 0.6, 0.0, 0.1), (1.12, 1.5, 0.08), (0, sx * -5, 0), bevel=0.01); hard(pg); setmat(pg, pap); P.append(pg)
        for k in range(7):   # linhas de registro
            ln = box((sx * 0.6, -0.55 + k * 0.17, 0.15), (0.9, 0.012, 0.005), (0, sx * -5, 0), bevel=0); setmat(ln, mat("inkl", (0.12, 0.09, 0.07), 0.8)); P.append(ln)
    pl = fuse([sph((0.4, 0.0, 0.16), 1, (0.38, 0.28, 0.025)), sph((0.62, -0.18, 0.16), 1, (0.17, 0.12, 0.02))], "pool", 0.01, 0.5, 3); setmat(pl, blood); P.append(pl)
    sl = cyl((-0.6, -0.4, 0.17), 0.17, 0.05, seg=20, bevel=0.01); hard(sl); setmat(sl, mat("wax", (0.55, 0.05, 0.08), 0.4, coat=0.5)); P.append(sl)
    cl = box((-0.6, -0.4, 0.2), (0.05, 0.14, 0.02), (0, 0, 20), bevel=0.003); hard(cl); setmat(cl, mat("waxd", (0.35, 0.03, 0.05), 0.4)); P.append(cl)
    qu = tube([(0.55, -0.1, 0.17), (0.8, 0.2, 0.6), (1.1, 0.5, 1.15)], 0.012, 0.8, 12); setmat(qu, mat("quill", (0.95, 0.93, 0.88), 0.6)); P.append(qu)
    fe = fuse([sph((1.0 + k * 0.07, 0.45 + k * 0.09, 1.0 + k * 0.14), 1, (0.22 - k * 0.02, 0.025, 0.07), (0, 0, 40)) for k in range(5)], "feather", 0.008, 0.5, 2)
    setmat(fe, mat("feath", (0.95, 0.93, 0.88), 0.6)); P.append(fe)
    group("book", P)
    S = []   # bolsa de moedas pendurada, sangrando
    bag = fuse([sph((0, 0, 1.2), 1, (0.38, 0.34, 0.4)), sph((0, 0, 1.58), 1, (0.16, 0.14, 0.09))], "bag", 0.015, 0.7, 5); setmat(bag, mat("purse", (0.42, 0.26, 0.14), 0.8, bump=0.4, bump_scale=50)); S.append(bag)
    tie = torus((0, 0, 1.52), 0.15, 0.03); shade(tie); setmat(tie, mat("cord", (0.75, 0.6, 0.3), 0.8)); S.append(tie)
    cd = sph((0, -0.35, 1.2), 1, (0.14, 0.03, 0.14)); setmat(cd, gold); S.append(cd)
    ch = tube([(0, 0, 1.66), (0, 0.05, 2.1), (0.0, 0.0, 2.5)], 0.015, 1.0, 8); setmat(ch, mat("iron", IRONC, 0.5, 0.6)); S.append(ch)
    for (x, z0, ln) in ((-0.1, 0.9, 0.5), (0.12, 1.0, 0.35), (0.0, 0.9, 0.55)):
        d = tube([(x, -0.3, z0 + 0.1), (x, -0.32, z0 - ln * 0.3), (x, -0.32, z0 - ln)], 0.03, 0.5, 8); setmat(d, blood); S.append(d)
        S.append(drop(x, -0.32, z0 - ln - 0.08, 0.04, blood))
    pr = group("purse", S); pr.location = (-0.2, -0.2, 0.0)
    group("ground", [ground(1.8, 0.0, 0.2, color=(0.45, 0.3, 0.2))])
    return {"kind": "spell", "dir": (0.4, -1.0, 0.45), "lens": 70}


# ------------------------------------------------------------------ Chuva de Brasas

def ember_rain():
    hm = hotm("ember", FLAME, 6.0)
    hm2 = hotm("emberh", FLAME_HOT, 9.0)
    F = []
    spots = [(-1.4, -0.4, 2.3), (0.2, -1.0, 2.6), (1.4, 0.2, 3.0), (-0.4, 0.6, 3.3), (0.9, -0.8, 1.5), (-1.0, -1.2, 1.4), (1.6, -0.9, 3.4)]
    for (x, y, z) in spots:
        r = 0.16 + 0.04 * ((int(abs(x * 7)) % 3))
        b = sph((x, y, z), r, (1, 1, 1)); shade(b); setmat(b, hm2); F.append(b)
        tr = tube([(x, y, z), (x - 0.4, y + 0.1, z + 0.7), (x - 0.75, y + 0.15, z + 1.5)], r, 0.04, 14); setmat(tr, hm); F.append(tr)
        F += flame((x - 0.05, y, z + 0.05), h=r * 3.0, r=r * 0.8, lean=(-0.12, 0))
    group("meteors", F)
    G = []
    for (x, y) in ((-1.4, -0.4), (0.9, -0.8), (-1.0, -1.2), (1.2, 0.5)):
        G += flame((x, y, 0.02), h=0.5, r=0.14, lean=(0.05, 0))
    group("fires", G)
    P = []
    for (x, y, r) in ((-1.9, -0.9, 0.3), (1.9, -0.5, 0.25), (0.3, 0.8, 0.35)):
        P.append(stone(x, y, r))
    tr = tube([(-0.2, 0.9, 0.0), (-0.15, 0.9, 0.8), (-0.3, 0.95, 1.5), (-0.1, 1.0, 2.1)], 0.1, 0.4, 14); setmat(tr, mat("dead", (0.22, 0.14, 0.09), 0.9)); P.append(tr)
    for (x, z, dx) in ((-0.2, 1.1, 0.5), (-0.28, 1.5, -0.5)):
        br = tube([(x, 0.93, z), (x + dx * 0.5, 0.95, z + 0.2), (x + dx, 0.97, z + 0.2)], 0.035, 0.4, 8); setmat(br, mat("dead", (0.22, 0.14, 0.09), 0.9)); P.append(br)
    wd = mat("wood", (0.3, 0.2, 0.12), 0.8, bump=0.4, bump_scale=25)
    for k in range(5):
        p = cyl((0.7 + k * 0.28, -0.1 - k * 0.08, 0.3), 0.04, 0.6 - (k % 2) * 0.15, (0, 8 * (k % 3 - 1), 0), seg=8, bevel=0.005); hard(p); setmat(p, wd); P.append(p)
    P.append(ground(2.3, -0.2, 0.0, color=(0.42, 0.33, 0.24)))
    group("ground", P)
    sm = mat("smoke", (0.45, 0.43, 0.42), 0.95); S = []
    for (x, y, z, r) in ((-1.4, -0.3, 0.9, 0.2), (-1.3, -0.2, 1.3, 0.25), (0.95, -0.7, 0.8, 0.18)):
        s = sph((x, y, z), 1, (r, r, r * 0.9)); shade(s); setmat(s, sm); S.append(s)
    group("smoke", S)
    return {"kind": "spell", "dir": (0.25, -1.0, 0.3), "lens": 65}


# ------------------------------------------------------------------ Avalanche de Ouro

def gold_avalanche():
    P = []
    wall = fuse([sph((-2.0, 1.0, 1.4), 1, (1.2, 1.2, 1.5)), sph((-1.2, 1.4, 2.2), 1, (1.0, 0.9, 1.3)), sph((2.0, 1.0, 1.2), 1, (1.2, 1.1, 1.3)),
                 sph((1.2, 1.6, 2.4), 1, (1.1, 0.9, 1.4)), sph((0, 1.8, 2.3), 1, (1.6, 0.9, 1.2)), sph((0, 1.1, 0.5), 1, (2.4, 1.2, 0.5))], "cliff", 0.06, 0.5, 4)
    paint(wall, lambda p, n: mix((0.3, 0.27, 0.26), (0.55, 0.5, 0.45), smoothstep(-0.2, 0.9, n.z) * 0.6 + smoothstep(0, 3, p.z) * 0.3))
    setmat(wall, mat("rockv", vcol=True, rough=0.95, bump=0.6, bump_scale=9)); P.append(wall)
    cl_ = group("cliff", P); cl_.scale = (0.7, 0.7, 0.7); cl_.location = (0, 0.5, 0)
    rnd = random.Random(21)
    items = []
    for i in range(110):
        t = rnd.random()
        w = 0.3 + 1.1 * t
        x = (rnd.random() - 0.5) * 2 * w + math.sin(t * 5) * 0.25
        y = 1.2 - t * 2.6
        z = 2.4 - t * 2.2 + rnd.random() * 0.55
        items.append(((x, y, max(z, 0.06)), (rnd.uniform(-1, 1), rnd.uniform(-1, 0.3), rnd.uniform(0.2, 1))))
    group("stream", [coins(items, 0.11, 0.03, "stream", 16)])
    N = []
    gm = mat("nug", GOLDC, 0.4, 1.0, bump=0.3, bump_scale=30)
    for i in range(30):
        t = rnd.random(); x = (rnd.random() - 0.5) * 2 * (0.3 + 1.1 * t); y = 1.2 - t * 2.6; z = 2.3 - t * 2.1 + rnd.random() * 0.5
        s = sph((x, y, max(z, 0.07)), 1, (0.09 + rnd.random() * 0.06, 0.08 + rnd.random() * 0.05, 0.07)); shade(s); setmat(s, gm); N.append(s)
    for (x, y, z, r) in ((-0.5, -0.6, 0.8, 0.32), (0.55, -1.1, 0.55, 0.26), (0.0, 0.2, 1.7, 0.36), (-0.9, -1.2, 0.3, 0.2)):
        s = stone(x, y, r, color=(0.5, 0.46, 0.42)); s.location.z = z; N.append(s)
    dust = mat("dust", (0.75, 0.68, 0.55), 0.95)
    for (x, y, z, r) in ((-1.1, -1.6, 0.45, 0.45), (0.2, -1.8, 0.4, 0.5), (1.1, -1.5, 0.5, 0.4), (0.6, -0.4, 1.3, 0.4)):
        d = sph((x, y, z), 1, (r, r, r * 0.8)); shade(d); setmat(d, dust); N.append(d)
    group("rubble", N)
    place(chars.knight(), (0.9, -1.9, 0.0), rot_z=150, scale=0.5, rot_x=-10)   # um herói minúsculo sendo soterrado
    group("ground", [ground(3.2, -0.6, 0.0, ry=2.3, color=(0.45, 0.36, 0.26))])
    return {"kind": "spell", "dir": (0.1, -1.0, 0.35), "lens": 60}


# ------------------------------------------------------------------ Erupção

def eruption():
    lava = mat("lava", (1.0, 0.35, 0.05), 0.4, emit=5.0)
    lavah = mat("lavah", (1.0, 0.8, 0.3), 0.4, emit=8.0)
    P = []
    cone = cyl((0, 0, 0.85), 1.9, 1.7, seg=18, bevel=0.0, r2=0.55); hard(cone)
    inner = cyl((0, 0, 1.45), 0.45, 0.8, seg=18, bevel=0.0, r2=0.4)
    m = cone.modifiers.new("c", 'BOOLEAN'); m.object = inner; m.operation = 'DIFFERENCE'; m.solver = 'EXACT'; apply_mods(cone); bpy.data.objects.remove(inner)
    paint(cone, lambda p, n: mix((0.2, 0.17, 0.17), (0.48, 0.38, 0.32), smoothstep(-0.2, 0.9, n.z) * 0.6 + smoothstep(0, 1.7, p.z) * 0.3))
    setmat(cone, mat("volc", vcol=True, rough=0.95, bump=0.7, bump_scale=9)); P.append(cone)
    for (a, r, s) in ((0.6, 1.8, 0.45), (2.4, 1.9, 0.5), (4.0, 1.7, 0.4), (5.3, 1.9, 0.38), (1.5, 2.1, 0.3)):
        P.append(stone(math.cos(a) * r, math.sin(a) * r * 0.9, s, color=(0.28, 0.24, 0.23)))
    crater = sph((0, 0, 1.69), 1, (0.43, 0.43, 0.06)); setmat(crater, lavah); P.append(crater)
    group("volcano", P)
    L = []

    def surf(a, t):
        r = 0.5 + t * 1.3
        return (math.cos(a) * r, math.sin(a) * r, 1.7 - t * 1.62)
    for (a, w) in ((-1.35, 0.1), (-0.5, 0.08), (-2.3, 0.07)):
        pts = [surf(a + math.sin(t * 4) * 0.12, t) for t in (0.0, 0.25, 0.5, 0.75, 1.0)]
        pts = [(p[0] * 1.03, p[1] * 1.03, p[2] + 0.02) for p in pts]
        o = tube(pts, w, 1.4, 20); setmat(o, lava); L.append(o)
    group("rivers", L)
    F = []
    for (dx, dz, h, r) in ((0.0, 1.7, 1.8, 0.34), (-0.25, 1.7, 1.2, 0.2), (0.25, 1.7, 1.3, 0.22)):
        F += flame((dx, 0.0, dz), h=h, r=r, lean=(dx * 0.4, 0))
    hmb = hotm("bomb", (1.0, 0.45, 0.1), 6.0)
    for (x, z, r) in ((-1.0, 3.2, 0.14), (1.2, 3.0, 0.17), (0.8, 3.8, 0.11), (-0.5, 3.9, 0.1), (-1.5, 2.2, 0.09), (1.6, 2.1, 0.1)):
        b = sph((x, -0.1, z), r); shade(b); setmat(b, hmb); F.append(b)
        t = tube([(x, -0.1, z), (x * 0.7, -0.1, z - 0.3), (x * 0.45, -0.1, z - 0.7)], r * 0.7, 0.05, 8); setmat(t, hmb); F.append(t)
    group("fountain", F)
    sm = mat("smoke", (0.4, 0.38, 0.37), 0.95); S = []
    for (x, z, r) in ((0.0, 3.0, 0.5), (-0.5, 3.6, 0.65), (0.5, 4.2, 0.8), (-0.3, 4.9, 0.9)):
        s = sph((x, 0.3, z), 1, (r, r * 0.9, r * 0.8)); shade(s); setmat(s, sm); S.append(s)
    group("smoke", S)
    group("ground", [ground(3.0, 0.0, 0.0, color=(0.3, 0.25, 0.22))])
    return {"kind": "spell", "dir": (0.3, -1.0, 0.2), "lens": 60}


# ------------------------------------------------------------------ Goblin Dinamiteiro

def goblin_dynamiter():
    g = chars2.goblin()
    place(g, (0, 0, 0.1), rot_z=18, scale=1.0, rot_x=-14)
    P = []
    # bandoleira de dinamite atravessada no peito
    band = tube([(0.28, -0.12, 0.72), (0.05, -0.22, 0.52), (-0.2, -0.17, 0.28)], 0.022, 1.0, 14); setmat(band, mat("leather", (0.38, 0.22, 0.12), 0.55)); P.append(band)
    for k in range(4):
        t = k / 3.0
        d = dynamite(0.24 - t * 0.43, -0.2 - 0.03 * math.sin(t * 3), 0.68 - t * 0.38, (0, 0, -30), 0.2); P.append(d)
    # feixe de dinamite na mão levantada, pavio aceso
    B = [dynamite(0.5 + k * 0.07 - 0.07, -0.42, 0.62, (0, 12 * (k - 1), 8 * (k - 1)), 0.4) for k in range(3)]
    bd = torus((0.5, -0.42, 0.62), 0.11, 0.014, (0, 90, 0)); shade(bd); setmat(bd, mat("cord", (0.4, 0.25, 0.12), 0.8)); B.append(bd)
    fz = tube([(0.5, -0.42, 0.82), (0.58, -0.45, 0.95), (0.5, -0.5, 1.05), (0.6, -0.5, 1.15)], 0.012, 1.0, 10); setmat(fz, mat("fuse", (0.15, 0.1, 0.07), 0.8)); B.append(fz)
    group("bundle", B)
    F = flame((0.6, -0.5, 1.15), h=0.3, r=0.08, lean=(0.04, 0)) + spark_pts((0.6, -0.5, 1.2), 10, 0.45, 3, hotm("spk", FLAME_HOT, 9.0), 0.022, 0.14)
    group("fz", F)
    # riscos de velocidade e pegadas chamuscadas
    sp = mat("speed", (0.03, 0.02, 0.03), 0.9); S = []
    for (z0, ln) in ((0.25, 0.7), (0.5, 0.55), (0.8, 0.5), (0.1, 0.5)):
        s = tube([(-0.55 - ln, 0.35, z0), (-0.55, 0.35, z0 + 0.02)], 0.012, 0.3, 4); setmat(s, sp); S.append(s)
    group("speed", S)
    group("ground", P + [ground(1.5, -0.1, 0.0)])
    return {"kind": "monster", "dir": (0.4, -1.0, 0.18), "lens": 85}


# ------------------------------------------------------------------ Mercenário Goblin

def gold_merc():
    g = chars2.goblin()
    place(g, (0, 0, 0.2), rot_z=-22, scale=1.15)
    P = []
    steel = mat("steel", (0.62, 0.65, 0.7), 0.4, 0.85)
    gold = mat("gold", GOLDC, 0.3, 1.0)
    # elmo de aço sobre a cabeçorra
    helm = sph((0, 0.0, 1.0 * 1.15 + 0.2 + 0.08), 1, (0.34 * 1.15, 0.32 * 1.15, 0.2 * 1.15)); shade(helm); setmat(helm, steel); P.append(helm)
    rm = torus((0, 0.0, 1.22 + 0.1), 0.33 * 1.15, 0.03, (-8, 0, 0)); shade(rm); setmat(rm, gold); P.append(rm)
    crest = box((0, 0.0, 1.5), (0.05, 0.4, 0.1), bevel=0.02); hard(crest); setmat(crest, mat("red", (0.75, 0.1, 0.1), 0.7)); P.append(crest)
    # espada larga na mão e escudinho de ouro
    sw = box((0.62, -0.35, 0.95), (0.08, 0.025, 0.9), (-20, 0, 18), bevel=0.01, taper=(0.15, 0.5)); hard(sw); setmat(sw, mat("blade", (0.85, 0.88, 0.93), 0.18, 1.0)); P.append(sw)
    gd = box((0.5, -0.32, 0.5), (0.24, 0.05, 0.05), (-20, 0, 18), bevel=0.01); hard(gd); setmat(gd, gold); P.append(gd)
    # bolsas de moedas na cintura e um colar de moedas
    for (x, y) in ((-0.28, -0.12), (0.3, -0.08)):
        b = fuse([sph((x, y, 0.62), 1, (0.1, 0.09, 0.11)), sph((x, y, 0.74), 1, (0.04, 0.04, 0.04))], "pouch", 0.01, 0.6, 3); setmat(b, mat("purse", (0.42, 0.26, 0.14), 0.8)); P.append(b)
    P.append(coins([((0.0, -0.3, 0.7 + 0.02 * k), (0, -1, 0.3)) for k in range(0)] + [((-0.1 + k * 0.1, -0.33, 0.62), (0, -1, 0.2)) for k in range(3)], 0.05, 0.015))
    P += gold_heap(0.0, -0.1, 1.0, 0.7, 0.55, 40, 12, 0.09)
    # pilhas de moedas
    for (x, y, n) in ((-1.1, -0.5, 6), (1.05, -0.6, 4)):
        P.append(coins([((x, y, 0.025 + k * 0.026), (0, 0, 1)) for k in range(n)], 0.1, 0.025))
    group("loot", P)
    group("ground", [ground(2.0, -0.2)])
    return {"kind": "monster", "dir": (-0.35, -1.0, 0.22), "lens": 80}


# ------------------------------------------------------------------ Mímico

def mimic():
    m = monsters2.mimic()
    xform_([o for o in m.children if o.get('bone') == 'lid'], Matrix.Translation((0, 0.36, 0.6)) @ Matrix.Rotation(rad(-58), 4, 'X') @ Matrix.Translation((0, -0.36, -0.6)))
    place(m, (0, 0, 0), rot_z=-14, scale=1.0)
    G = []
    G += gold_heap(0.0, 0.3, 0.3, 0.2, 0.2, 14, 3, 0.07, 0.62)
    gm = mat("gold", GOLDC, 0.3, 1.0)
    G.append(coins([((-0.9, -0.7, 0.02), (0, 0.2, 1)), ((-0.7, -0.95, 0.025), (0.2, 0, 1)), ((0.95, -0.8, 0.02), (0, 0.1, 1)), ((1.1, -0.55, 0.03), (0.3, 0.1, 1)),
                    ((-1.1, -0.35, 0.02), (0, 0, 1))], 0.1, 0.025))
    # luva de herói caída e uma espada quebrada: quem se aproximou
    bl = box((-1.0, -0.2, 0.06), (0.9, 0.09, 0.03), (0, 0, 28), bevel=0.01, taper=(0.1, 0.6)); hard(bl); setmat(bl, mat("blade", (0.85, 0.88, 0.93), 0.18, 1.0)); G.append(bl)
    hl = box((-0.55, 0.12, 0.05), (0.15, 0.04, 0.05), (0, 0, 28), bevel=0.01); hard(hl); setmat(hl, gm); G.append(hl)
    # baba brilhando
    sl = mat("slobber", (0.95, 0.5, 0.6), 0.2, coat=1.0)
    for x in (-0.2, 0.0, 0.2):
        d = tube([(x, -0.38, 0.62), (x, -0.4, 0.45), (x, -0.4, 0.33)], 0.012, 0.5, 6); setmat(d, sl); G.append(d)
    group("loot", G)
    group("ground", [ground(1.8, -0.2, 0.0, ry=1.3)])
    return {"kind": "structure", "dir": (0.45, -1.0, 0.3), "lens": 80}


# ------------------------------------------------------------------ Incêndio (vila em chamas)

def burn_village():
    import scenery
    h1 = scenery.house(); place(h1, (-1.5, 0.3, 0.0), rot_z=15, scale=0.55)
    h2 = scenery.tavern(); place(h2, (1.4, 0.7, 0.0), rot_z=-20, scale=0.5)
    h3 = scenery.house(); place(h3, (0.1, 1.9, 0.0), rot_z=3, scale=0.42)
    F = []
    F += flame((-1.5, 0.3, 1.9), h=1.5, r=0.4, lean=(0.15, 0)) + flame((-1.1, 0.35, 1.3), h=0.9, r=0.25, lean=(0.1, 0))
    F += flame((1.4, 0.7, 2.0), h=1.7, r=0.45, lean=(-0.2, 0)) + flame((1.9, 0.8, 1.2), h=0.9, r=0.25, lean=(-0.1, 0))
    F += flame((0.1, 1.9, 1.5), h=1.1, r=0.3, lean=(0.1, 0))
    F += flame((-0.3, -0.5, 0.0), h=0.6, r=0.18) + flame((0.6, -0.2, 0.0), h=0.5, r=0.15)
    group("fire", F)
    sm = mat("smoke", (0.25, 0.23, 0.22), 0.95); S = []
    for (x, y, z, r) in ((-1.4, 0.4, 3.0, 0.5), (-1.1, 0.6, 3.6, 0.65), (-0.7, 0.8, 4.3, 0.8), (1.6, 0.8, 3.3, 0.55), (1.9, 1.0, 4.0, 0.7), (2.3, 1.1, 4.7, 0.85)):
        s = sph((x, y, z), 1, (r, r * 0.9, r * 0.8)); shade(s); setmat(s, sm); S.append(s)
    group("smoke", S)
    # cerca queimada, poço e uma estrada à frente
    wd = mat("wood", (0.3, 0.2, 0.12), 0.8, bump=0.4, bump_scale=25); P = []
    for k in range(6):
        p = cyl((-2.2 + k * 0.38, -1.2 + k * 0.05, 0.32), 0.05, 0.6 - (k % 3) * 0.12, (0, 6 * (k % 3 - 1), 0), seg=8, bevel=0.005); hard(p); setmat(p, wd); P.append(p)
    for k in range(8):
        t = k / 7.0
        b = box((-0.9 + t * 2.4, -1.5 - 0.1 * math.sin(t * 5), 0.03), (0.4, 0.3, 0.06), (0, 0, 15 + k * 9), bevel=0.02); hard(b); setmat(b, mat("stone", STONE, 0.9, bump=0.3, bump_scale=14)); P.append(b)
    P.append(ground(3.0, 0.5, 0.0, ry=2.2, color=(0.4, 0.33, 0.22)))
    group("ground", P)
    return {"kind": "route", "dir": (0.3, -1.0, 0.35), "lens": 60}


# ------------------------------------------------------------------ Torre de Gárgula

def gargoyle_tower():
    t = monsters2.gargoyle_tower()
    place(t, (0, 0, 0), rot_z=-8, scale=1.0)
    P = []
    for (x, y, r) in ((-1.1, -0.6, 0.35), (1.0, -0.5, 0.3), (0.7, 0.8, 0.4), (-0.9, 0.7, 0.3)):
        P.append(stone(x, y, r))
    wd = mat("wood", (0.3, 0.2, 0.12), 0.8)
    for k in range(5):   # arqueiros de pedra no chão: rastros de poeira de pedra
        pass
    P.append(ground(2.1, 0.0, 0.0, color=(0.4, 0.37, 0.34)))
    group("ground", P)
    # luz de feitiço rosa nos olhos e pedrinhas caindo
    G = []
    pm = mat("pinkglow", (1.0, 0.45, 0.9), 0.4, emit=5.0)
    for (x, y, z, r) in ((0.4, -0.5, 2.4, 0.05), (0.55, -0.4, 2.1, 0.04), (-0.4, -0.55, 2.2, 0.035)):
        s = sph((x, y, z), r); shade(s); setmat(s, pm); G.append(s)
    group("fx", G)
    return {"kind": "structure", "dir": (0.4, -1.0, 0.1), "lens": 80}


# ------------------------------------------------------------------ Coletor de Almas

def soul_collector():
    P = []
    robe = mat("robe", (0.24, 0.2, 0.3), 0.85, bump=0.2, bump_scale=60)
    robed = mat("robed", (0.12, 0.1, 0.17), 0.85)
    rb = cyl((0, 0, 0.7), 0.5, 1.4, seg=40, bevel=0.0, r2=0.2); hard(rb); setmat(rb, robe); P.append(rb)
    hem = torus((0, 0, 0.03), 0.5, 0.03); shade(hem); setmat(hem, robed); P.append(hem)
    sh = fuse([sph((0, 0, 1.38), 1, (0.38, 0.26, 0.14)), sph((0, 0.0, 1.5), 1, (0.2, 0.2, 0.15))], "shoulders", 0.012, 0.6, 4); setmat(sh, robe); P.append(sh)
    hood = fuse([sph((0, 0.05, 1.75), 1, (0.3, 0.3, 0.32)), sph((0, 0.25, 1.65), 1, (0.2, 0.2, 0.28))], "hood", 0.012, 0.6, 4)
    cut = sph((0, -0.32, 1.72), 1, (0.24, 0.3, 0.22))
    m = hood.modifiers.new("cut", 'BOOLEAN'); m.object = cut; m.operation = 'DIFFERENCE'; m.solver = 'EXACT'; apply_mods(hood); bpy.data.objects.remove(cut)
    shade(hood); setmat(hood, robe); P.append(hood)
    face = sph((0, -0.1, 1.72), 1, (0.2, 0.17, 0.22)); setmat(face, mat("shadow", (0.03, 0.02, 0.04), 0.9)); P.append(face)
    P += monsters.glow_eye((-0.08, -0.26, 1.76), 0.06, color=(0.5, 1.0, 0.7), socket=False) + monsters.glow_eye((0.08, -0.26, 1.76), 0.06, color=(0.5, 1.0, 0.7), socket=False)
    # braços estendidos carregando um frasco de vidro com almas
    for sx in (-1, 1):
        a = fuse(capsule((sx * 0.38, 0, 1.35), (sx * 0.5, -0.4, 1.1), 0.1, 0.085) + capsule((sx * 0.5, -0.4, 1.1), (sx * 0.22, -0.62, 1.05), 0.085, 0.06), "arm", 0.01, 0.5, 3)
        setmat(a, robe); P.append(a)
        hd = sph((sx * 0.2, -0.65, 1.03), 0.07); shade(hd); setmat(hd, mat("bonehand", BONE, 0.6)); P.append(hd)
    glass = mat("glass", (0.7, 0.9, 0.85), 0.1, coat=1.0)
    jar = sph((0, -0.7, 0.95), 1, (0.3, 0.3, 0.36)); shade(jar); setmat(jar, glass); P.append(jar)
    neck = cyl((0, -0.7, 1.28), 0.12, 0.12, seg=20, bevel=0.0); hard(neck); setmat(neck, glass); P.append(neck)
    cork = cyl((0, -0.7, 1.38), 0.1, 0.1, seg=16, bevel=0.01, r2=0.12); hard(cork); setmat(cork, mat("wood", WOODC, 0.8)); P.append(cork)
    sm = mat("soul", (0.5, 1.0, 0.75), 0.3, emit=5.0)
    for (x, z, r) in ((-0.1, 0.9, 0.1), (0.1, 1.0, 0.09), (0.0, 0.8, 0.08)):
        s = sph((x, -0.74, z), 1, (r, r * 0.8, r * 1.2)); setmat(s, sm); P.append(s)
        P.append(tube([(x, -0.74, z + r), (x + 0.04, -0.74, z + r + 0.12), (x - 0.02, -0.74, z + r + 0.2)], r * 0.5, 0.1, 6)); setmat(P[-1], sm)
        for ex in (-1, 1):
            pass
    group("collector", P)
    # almas entrando no frasco em fila
    S = []
    for k, (x, z0) in enumerate(((-1.0, 0.6), (-0.7, 1.2), (0.9, 0.8), (1.0, 1.5))):
        w = tube([(x, -0.4, z0), (x * 0.7, -0.5, z0 + 0.3), (x * 0.35, -0.65, z0 + 0.45), (0.1 * (1 if x > 0 else -1), -0.72, 1.28)], 0.06, 0.1, 18); setmat(w, sm); S.append(w)
        hd = sph((x, -0.4, z0), 1, (0.1, 0.08, 0.12)); shade(hd); setmat(hd, sm); S.append(hd)
        for sx in (-1, 1):
            e = sph((x + sx * 0.035, -0.47, z0 + 0.02), 0.018); setmat(e, mat("shadow", (0.03, 0.02, 0.04), 0.9)); S.append(e)
    group("souls", S)
    # sacola cheia de frascos e o cajado com lanterna
    sk = fuse([sph((0.95, 0.35, 0.3), 1, (0.35, 0.3, 0.32)), sph((0.95, 0.35, 0.62), 1, (0.14, 0.12, 0.1))], "sack", 0.012, 0.6, 4); setmat(sk, mat("sack", (0.5, 0.4, 0.28), 0.9, bump=0.5, bump_scale=60))
    for k in range(3):
        j = cyl((0.8 + k * 0.14, 0.2, 0.7 + (k % 2) * 0.05), 0.07, 0.2, seg=14, bevel=0.01); hard(j); setmat(j, glass)
    st = tube([(-0.9, -0.2, 0.0), (-0.88, -0.2, 1.4), (-0.8, -0.2, 2.0)], 0.03, 0.8, 12); setmat(st, mat("wood", WOODC, 0.8))
    lt = cyl((-0.65, -0.2, 1.75), 0.1, 0.22, seg=12, bevel=0.01); hard(lt); setmat(lt, mat("glassl", (0.5, 1.0, 0.75), 0.3, emit=4.0))
    lh = tube([(-0.8, -0.2, 2.0), (-0.7, -0.2, 2.0), (-0.65, -0.2, 1.9)], 0.015, 1.0, 8); setmat(lh, mat("iron", IRONC, 0.5, 0.6))
    group("gear", [sk, st, lt, lh])
    group("ground", [ground(2.0, -0.2, 0.0, color=(0.35, 0.3, 0.3))])
    return {"kind": "monster", "dir": (0.3, -1.0, 0.18), "lens": 75}


# ------------------------------------------------------------------ Cálice Profundo

def deep_chalice():
    P = []
    gold = mat("cgold", (0.9, 0.62, 0.2), 0.3, 1.0)
    liq = mat("elix", (0.72, 0.25, 0.95), 0.3, emit=4.0)
    bowl = sph((0, 0, 1.35), 1, (0.5, 0.5, 0.42)); shade(bowl)
    cut = sph((0, 0, 1.7), 1, (0.46, 0.46, 0.4))
    m = bowl.modifiers.new("c", 'BOOLEAN'); m.object = cut; m.operation = 'DIFFERENCE'; m.solver = 'EXACT'; apply_mods(bowl); bpy.data.objects.remove(cut)
    m = bowl.modifiers.new("s", 'SOLIDIFY'); m.thickness = 0.04; apply_mods(bowl); shade(bowl); setmat(bowl, gold); P.append(bowl)
    rim = torus((0, 0, 1.66), 0.44, 0.03); shade(rim); setmat(rim, gold); P.append(rim)
    P.append(setmat(sph((0, 0, 1.6), 1, (0.43, 0.43, 0.04)), liq))
    stem = tube([(0, 0, 0.5), (0, 0, 0.9), (0, 0, 1.0)], 0.07, 1.0, 10); setmat(stem, gold); P.append(stem)
    for z in (0.62, 0.95):
        k = sph((0, 0, z), 1, (0.14, 0.14, 0.07)); shade(k); setmat(k, gold); P.append(k)
    base = cyl((0, 0, 0.4), 0.38, 0.1, seg=32, bevel=0.02, r2=0.14); hard(base); setmat(base, gold); P.append(base)
    gm = mat("gem", (0.75, 0.2, 0.55), 0.1, emit=3.0)
    for k in range(5):
        a = k / 5 * math.tau
        g = sph((math.cos(a) * 0.5, math.sin(a) * 0.5, 1.4), 1, (0.05, 0.05, 0.07)); shade(g); setmat(g, gm); P.append(g)
    group("chalice", P)
    # elixir transbordando pela borda, gotas e vapor
    E = []
    for (a, ln) in ((-1.3, 0.55), (-0.2, 0.4), (0.9, 0.5)):
        x, y = math.cos(a) * 0.45, math.sin(a) * 0.45
        d = tube([(x * 0.95, y * 0.95, 1.66), (x * 1.1, y * 1.1, 1.55), (x * 1.12, y * 1.12, 1.55 - ln)], 0.045, 0.5, 12); setmat(d, liq); E.append(d)
        E.append(drop(x * 1.12, y * 1.12, 1.55 - ln - 0.08, 0.035, liq))
    for k in range(3):
        ox = (-0.2, 0.1, 0.25)[k]
        w = tube([(ox, 0, 1.75), (ox + 0.12, 0, 2.05), (ox - 0.1, 0, 2.35 + k * 0.1), (ox + 0.05, 0, 2.7 + k * 0.1)], 0.04, 0.1, 18); setmat(w, liq); E.append(w)
    group("elixir", E)
    # pedestal de pedra e cristais da caverna
    G = []
    ped = cyl((0, 0, 0.17), 0.7, 0.34, seg=10, bevel=0.03, r2=0.55); hard(ped); setmat(ped, mat("stoneb", (0.4, 0.38, 0.42), 0.9, bump=0.4, bump_scale=14)); G.append(ped)
    cm = mat("crystal", (0.5, 0.25, 0.85), 0.1, emit=2.5)
    for (x, y, h, tilt) in ((-1.1, 0.3, 0.9, 12), (-1.35, -0.1, 0.55, -18), (1.15, 0.2, 1.0, -10), (1.4, -0.2, 0.6, 16), (-0.6, 0.9, 0.7, 5), (0.7, 0.85, 0.8, -6)):
        c = box((x, y, h / 2), (0.2, 0.2, h), (tilt, 0, tilt * 2), bevel=0.01, taper=(0.1, 0.1)); hard(c); setmat(c, cm); G.append(c)
    st = mat("rocks", (0.3, 0.28, 0.32), 0.9, bump=0.5, bump_scale=10)
    for (x, y, r, h) in ((-1.0, -0.8, 0.28, 0.7), (1.0, -0.8, 0.25, 0.55), (-0.3, 1.2, 0.3, 0.8)):
        s = cyl((x, y, h / 2), r, h, seg=7, bevel=0.03, r2=0.04); hard(s); setmat(s, st); G.append(s)
    group("cave", G)
    group("ground", [ground(2.1, 0.0, 0.0, color=(0.3, 0.27, 0.33))])
    return {"kind": "spell", "dir": (0.3, -1.0, 0.15), "lens": 75}


# ------------------------------------------------------------------ criaturas (o modelo da carta é o do jogo)

def treasure_guard():
    g = CD.treasure_guard()
    place(g, (0.1, 0.0, 0.0), rot_z=-14, scale=1.1)
    H = gold_heap(-1.3, 0.1, 0.95, 0.7, 0.6, 40, 31, 0.09) + gold_heap(1.35, 0.35, 0.8, 0.6, 0.5, 30, 32, 0.09)
    group("hoard", H)
    # baú transbordando atrás, espada de herói caída e um elmo vazio: o que sobrou de quem tentou levar
    ch = box((0.2, 1.2, 0.3), (1.0, 0.6, 0.6), (0, 0, 8), bevel=0.04); hard(ch); setmat(ch, mat("chestwood", (0.55, 0.32, 0.16), 0.7, bump=0.3, bump_scale=14))
    group("chest", [ch] + gold_heap(0.2, 1.2, 0.4, 0.22, 0.25, 12, 33, 0.07, 0.58))
    bl = box((-0.35, -0.9, 0.05), (1.0, 0.1, 0.03), (0, 0, 28), bevel=0.01, taper=(0.1, 0.6)); hard(bl); setmat(bl, mat("blade", (0.85, 0.88, 0.93), 0.18, 1.0))
    hm = sph((0.9, -0.8, 0.12), 1, (0.17, 0.17, 0.14)); shade(hm); setmat(hm, mat("steel", (0.62, 0.65, 0.7), 0.4, 0.85))
    sk = fuse([sph((0.6, -1.05, 0.1), 1, (0.12, 0.13, 0.11)), sph((0.6, -1.14, 0.06), 1, (0.08, 0.07, 0.05))], "skull", 0.008); setmat(sk, mat("bone", BONE, 0.6))
    group("remains", [bl, hm, sk])
    # braseiro aceso ao lado
    br = cyl((-1.7, -0.5, 0.35), 0.2, 0.7, seg=12, bevel=0.01, r2=0.12); hard(br); setmat(br, mat("iron", IRONC, 0.5, 0.6))
    bw = cyl((-1.7, -0.5, 0.75), 0.3, 0.12, seg=16, bevel=0.01, r2=0.34); hard(bw); setmat(bw, mat("iron", IRONC, 0.5, 0.6))
    group("brazier", [br, bw] + flame((-1.7, -0.5, 0.8), h=0.7, r=0.2))
    group("ground", [ground(2.6, 0.2, 0.0, ry=1.7)])
    return {"kind": "monster", "dir": (0.35, -1.0, 0.18), "lens": 75}


def elder_dragon():
    d = CD.elder_dragon()
    F = []
    for (dx, dz, h, r) in ((0.0, 0.0, 2.4, 0.38), (-0.35, 0.18, 1.7, 0.26), (0.35, -0.14, 1.8, 0.26)):
        F += flame((dx, 0, dz), h=h, r=r)
    xform_(F, Matrix.Translation((0.0, -2.5, 2.95)) @ Matrix.Rotation(rad(105), 4, 'X'))
    group("breath", F)
    # brasas caindo (a chuva que ele solta ao entrar) e nuvem de fumaça
    hm = hotm("ember", FLAME, 6.0); E = []
    rnd = random.Random(8)
    for k in range(14):
        s = sph((rnd.uniform(-3.5, 3.5), rnd.uniform(-2.5, 0.5), rnd.uniform(-0.4, 1.0)), rnd.uniform(0.03, 0.07)); shade(s); setmat(s, hm); E.append(s)
    group("embers", E)
    return {"kind": "monster", "dir": (0.85, -0.6, 0.18), "lens": 55}


def cave_troll():
    t = CD.cave_troll()
    place(t, (0, 0, 0.0), rot_z=-12, scale=1.0)
    P = []
    P.append(ground(2.2, 0.0, 0.0, color=(0.33, 0.3, 0.3)))
    for (x, y, h, r) in ((-1.6, 0.4, 1.0, 0.18), (-1.9, 0.1, 0.7, 0.14), (1.7, 0.6, 1.2, 0.2), (1.4, 0.9, 0.7, 0.14)):   # estalagmites
        s = cyl((x, y, h / 2), r, h, seg=7, bevel=0.02, r2=0.02); hard(s); setmat(s, mat("rocks", (0.38, 0.35, 0.36), 0.9, bump=0.5, bump_scale=10)); P.append(s)
    for (x, y, r) in ((-1.0, -0.9, 0.22), (0.95, -0.95, 0.18)):
        P.append(stone(x, y, r))
    # ossos roídos no chão
    bn = mat("bone", BONE, 0.6)
    for (x, y, rz) in ((-0.6, -1.1, 20), (0.5, -1.2, -35)):
        b = fuse(capsule((x, y, 0.05), (x + 0.4, y - 0.1, 0.05), 0.03) + [sph((x - 0.02, y + 0.03, 0.06), 0.05), sph((x - 0.02, y - 0.03, 0.04), 0.05)], "bone", 0.008); setmat(b, bn); P.append(b)
    group("ground", P)
    return {"kind": "monster", "dir": (0.4, -1.0, 0.15), "lens": 80}


def villain_dragon():
    """Retrato do Dragão Avarento: cabeça enorme sobre o monte de ouro, uma asa aberta atrás, fumaça nas narinas."""
    Hh = CD._dragon_head(jaw_open=0.35)
    xform_(Hh, Matrix.Translation((0.0, -0.2, 2.9)) @ Matrix.Rotation(rad(10), 4, 'X') @ Matrix.Rotation(rad(-18), 4, 'Z') @ Matrix.Scale(2.6, 4))
    group("head", Hh)
    # pescoço grosso subindo do monte
    scales = mat("dscales", vcol=True, rough=0.6, bump=0.25, bump_scale=60)
    neck = fuse([sph(p, 1, r) for p, r in (((0.2, 1.5, 0.6), (0.9, 0.8, 0.7)), ((0.15, 1.2, 1.5), (0.75, 0.65, 0.65)), ((0.05, 0.9, 2.3), (0.62, 0.55, 0.6)), ((0.0, 0.55, 2.9), (0.55, 0.5, 0.5)))], "dneck", 0.025, 0.6, 5)
    paint(neck, lambda p, n: mix(CD.RSD, CD.RS, smoothstep(-0.3, 0.9, n.z) * 0.7 + 0.15)); setmat(neck, scales)
    pl = []
    for k in range(0):   # placas douradas da garganta
        z = 0.9 + k * 0.22
        b = box((0.1 - k * 0.02, 0.4 - k * 0.05 - 0.0, z), (0.34 - k * 0.02, 0.1, 0.12), (-25, 0, 0), bevel=0.01); hard(b); setmat(b, mat("dbelly", CD.BELLY, 0.45, 0.5)); pl.append(b)
    group("neck", [neck] + pl)
    W = CD._wing(-1)
    xform_(W, Matrix.Translation((1.8, 1.4, -0.4)) @ Matrix.Rotation(rad(28), 4, 'Z') @ Matrix.Scale(0.7, 4))
    group("wing", W)
    # monte de ouro, colar de moedas e rubi
    group("hoard", gold_heap(0.0, -0.4, 2.0, 1.4, 0.8, 90, 41, 0.1) + gold_heap(-1.5, -0.7, 0.8, 0.6, 0.45, 25, 42, 0.09) + gold_heap(1.5, -0.6, 0.8, 0.6, 0.4, 25, 43, 0.09))
    ch = tube([(-0.45, -0.5, 1.4), (-0.3, -0.75, 1.1), (0.1, -0.8, 1.0), (0.5, -0.7, 1.2), (0.6, -0.45, 1.5)], 0.04, 1.0, 20); setmat(ch, mat("gold", GOLDC, 0.3, 1.0))
    rb = sph((0.05, -0.85, 1.0), 1, (0.13, 0.07, 0.17)); setmat(rb, mat("ruby", (0.9, 0.05, 0.15), 0.1, emit=1.5))
    group("jewel", [ch, rb])
    # fumaça nas narinas
    sm = mat("smoke", (0.5, 0.48, 0.46), 0.95); S = []
    for (x, y, z, r) in ((-0.15, -2.0, 2.0, 0.12), (-0.05, -2.2, 2.2, 0.17), (0.1, -2.4, 2.5, 0.22)):
        s = sph((x, y, z), 1, (r, r, r * 0.8)); shade(s); setmat(s, sm); S.append(s)
    group("smoke", S)
    return {"kind": "monster", "dir": (0.2, -1.0, 0.1), "lens": 65}


# ------------------------------------------------------------------ heróis (retrato de busto)

def bust(zcut):
    """Corta toda a malha da cena abaixo de zcut (a fronteira vira um traço limpo no nanquim)."""
    bpy.context.view_layer.update()
    for o in [o for o in bpy.context.scene.objects if o.type == 'MESH']:
        for md in list(o.modifiers):
            if md.type != 'WEIGHTED_NORMAL':
                continue
            o.modifiers.remove(md)
        mw = o.matrix_world.copy()
        me = o.data
        bm = bmesh.new(); bm.from_mesh(me)
        bm.transform(mw)
        geom = bm.verts[:] + bm.edges[:] + bm.faces[:]
        bmesh.ops.bisect_plane(bm, geom=geom, plane_co=(0, 0, zcut), plane_no=(0, 0, 1), clear_inner=True)
        for v in list(bm.verts):
            if v.co.z < zcut - 1e-4:
                bm.verts.remove(v)
        o.parent = None
        o.matrix_world = Matrix.Identity(4)
        bm.to_mesh(me); bm.free()
        if len(me.vertices) == 0:
            bpy.data.objects.remove(o)


def hero_escudeiro():
    k = chars.knight()
    bust(0.82)
    return {"kind": "monster", "dir": (0.3, -1.0, 0.05), "lens": 85}


def hero_arqueira():
    a = chars.archer()
    bust(0.8)
    return {"kind": "monster", "dir": (-0.3, -1.0, 0.05), "lens": 85}


def hero_mago():
    w = chars2.wizard()
    bust(0.72)
    return {"kind": "monster", "dir": (0.3, -1.0, 0.05), "lens": 85}


def hero_cleriga():
    P = []
    white = mat("cwhite", (0.93, 0.9, 0.84), 0.8, bump=0.08, bump_scale=200)
    whited = mat("cwhite_d", (0.78, 0.74, 0.68), 0.85, bump=0.08, bump_scale=200)
    gold = mat("cgold2", GOLDC, 0.25, 1.0)
    blue = mat("cblue", (0.2, 0.35, 0.7), 0.8)
    skin = (0.88, 0.62, 0.48)
    gown = cyl((0, 0, 0.52), 0.36, 0.7, seg=56, bevel=0.04, r2=0.27); hard(gown); setmat(gown, white); P.append(gown)
    chest = fuse([sph((0, 0, 0.98), 1, (0.31, 0.24, 0.26)), sph((0, 0, 0.82), 1, (0.29, 0.23, 0.15))], "chest", 0.01); setmat(chest, white); P.append(chest)
    sash = box((0, -0.26, 0.6), (0.14, 0.03, 0.7), (-4, 0, 0), bevel=0.01); hard(sash); setmat(sash, blue); P.append(sash)
    for z in (0.45, 0.65, 0.85):
        r = box((0, -0.28, z), (0.06, 0.02, 0.06), (0, 45, 0), bevel=0.006); hard(r); setmat(r, gold); P.append(r)
    belt = torus((0, 0, 0.74), 0.28, 0.03, s=(1, 0.88, 1)); shade(belt); setmat(belt, gold); P.append(belt)
    # capa-capuz azul e ombreiras
    cape = fuse([sph((0, 0.22, 0.88), 1, (0.35, 0.06, 0.5), (6, 0, 0)), sph((0, 0.1, 1.22), 1, (0.35, 0.22, 0.12))], "cape", 0.01); setmat(cape, blue); P.append(cape)
    for sx in (-1, 1):
        sd = sph((sx * 0.34, 0, 1.18), 1, (0.14, 0.14, 0.09)); shade(sd); setmat(sd, gold); P.append(sd)
    # braços: esquerda segura a maça, direita ergue o símbolo sagrado
    chars.arm(P, -1, white, mat("skinm", skin, 0.55, sss=0.25), (-0.5, -0.14, 0.76))
    chars.arm(P, 1, white, mat("skinm", skin, 0.55, sss=0.25), (0.42, -0.3, 1.0))
    mc = tube([(-0.52, -0.12, 0.2), (-0.52, -0.14, 0.95)], 0.03, 1.0, 10); setmat(mc, mat("wood", WOODC, 0.6)); P.append(mc)
    mh = fuse([sph((-0.52, -0.14, 1.05), 1, (0.1, 0.1, 0.1))] + [sph((-0.52 + math.cos(a) * 0.1, -0.14 + math.sin(a) * 0.1, 1.05), 1, (0.03, 0.03, 0.1)) for a in (0, 1.57, 3.14, 4.71)], "machead", 0.008); setmat(mh, gold); P.append(mh)
    # símbolo sagrado: sol dourado brilhando e raios
    sun = sph((0.42, -0.42, 1.1), 1, (0.1, 0.03, 0.1)); setmat(sun, mat("sunglow", (1.0, 0.85, 0.35), 0.4, emit=6.0)); P.append(sun)
    for k in range(10):
        a = k / 10 * math.tau
        r = tube([(0.42 + math.cos(a) * 0.14, -0.43, 1.1 + math.sin(a) * 0.14), (0.42 + math.cos(a) * 0.3, -0.43, 1.1 + math.sin(a) * 0.3)], 0.012, 0.3, 4); setmat(r, mat("sunglow", (1.0, 0.85, 0.35), 0.4, emit=6.0)); P.append(r)
    # cabeça de cabelo castanho preso, tiara e auréola
    chars.chibi_head(P)
    hair = fuse([sph((0, 0.04, 1.58), 1, (0.36, 0.34, 0.3))] + [sph((x, -0.24, 1.66 - abs(x) * 0.5), 1, (0.1, 0.08, 0.07), (20, 0, x * 60)) for x in (-0.15, -0.05, 0.06, 0.16)] +
                [sph((0, 0.3, 1.4 - i * 0.1), 1, (0.1, 0.1, 0.1)) for i in range(4)], "chair", 0.01)
    setmat(hair, mat("hairc", (0.45, 0.25, 0.12), 0.45, bump=0.15, bump_scale=40)); P.append(hair)
    tia = torus((0, -0.02, 1.7), 0.33, 0.022, (-12, 0, 0)); shade(tia); setmat(tia, gold); P.append(tia)
    gem = sph((0, -0.34, 1.72), 0.04); shade(gem); setmat(gem, mat("cgem", (0.3, 0.6, 1.0), 0.1, emit=3.0)); P.append(gem)
    halo = torus((0, 0.22, 1.92), 0.34, 0.025, (80, 0, 0)); shade(halo); setmat(halo, mat("sunglow", (1.0, 0.85, 0.35), 0.4, emit=6.0)); P.append(halo)
    group("cleric", P)
    # faíscas de cura subindo
    F = []
    for (x, z, r) in ((0.75, 1.0, 0.035), (0.9, 1.3, 0.03), (0.6, 1.5, 0.025), (-0.75, 1.5, 0.03), (-0.9, 1.2, 0.022)):
        s = sph((x, -0.3, z), 1, (r, r, r * 1.6)); setmat(s, mat("sunglow", (1.0, 0.85, 0.35), 0.4, emit=6.0)); F.append(s)
    group("spark", F)
    bust(0.76)
    return {"kind": "monster", "dir": (0.3, -1.0, 0.05), "lens": 85}


# registro: toda função de cena deste módulo cujo nome é um id de carta (acrescentado automaticamente no fim)
SCENES_DRAGON = {n: f for n, f in list(globals().items()) if callable(f) and getattr(f, "__module__", None) == __name__ and n in CARD_IDS}
