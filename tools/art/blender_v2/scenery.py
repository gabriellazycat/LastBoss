"""Cenário do Last Boss na linguagem dos monstros novos: folhagem e terreno macios (fundidos por voxel),
mas pedra, madeira e metal com quinas chanfradas, para conversar com os heróis da KayKit.
Cada função devolve o grupo (vazio raiz); tudo parado (sem ossos)."""
import math, random
import bpy, bmesh
from mathutils import Matrix, Vector, noise
from mk import *
from mk import _sel

LEAF = (0.1, 0.3, 0.09)
LEAF_L = (0.32, 0.5, 0.12)
LEAF_D = (0.03, 0.12, 0.06)
BARK = (0.38, 0.24, 0.14)
BARK_D = (0.22, 0.13, 0.08)
STONE = (0.42, 0.4, 0.38)
STONE_D = (0.2, 0.2, 0.22)
MOSS = (0.2, 0.36, 0.1)
PLASTER = (0.93, 0.86, 0.72)
TIMBER = (0.33, 0.2, 0.12)
ROOF = (0.72, 0.3, 0.2)
ROOF_D = (0.46, 0.16, 0.12)
IRON = (0.26, 0.26, 0.3)
WARM = (1.0, 0.72, 0.35)
GOLD = (1.0, 0.72, 0.28)


def rng(seed):
    return random.Random(seed)


def jitter(o, amt, scale=2.0, seed=0):
    """Desalinha os vértices com ruído (pedra lascada, madeira torta), depois de aplicar os modificadores."""
    apply_mods(o)
    off = Vector((seed * 7.1, seed * 3.3, seed * 1.7))
    for v in o.data.vertices:
        p = o.matrix_world @ v.co
        d = noise.noise_vector(p * scale + off)
        v.co += d * amt
    return o


def foliage(blobs, name, voxel=0.06, seed=0, light=LEAF_L, base=LEAF, dark=LEAF_D):
    o = fuse([sph(c, 1, s) for c, s in blobs], name, voxel, smooth=0.5, iters=4)
    off = Vector((seed, seed * 2, 0))

    def col(p, n):
        t = smoothstep(-0.3, 0.9, n.z) * 0.7 + smoothstep(0.0, 5.0, p.z) * 0.3
        c = mix(dark, base, smoothstep(0.0, 0.5, t))
        c = mix(c, light, smoothstep(0.5, 1.0, t))
        k = noise.noise(p * 1.6 + off) * 0.5 + 0.5
        return mix(c, (c[0] * 1.15, c[1] * 1.05, c[2] * 0.8), k * 0.4)
    paint(o, col); setmat(o, mat("leafv", vcol=True, rough=0.8))
    return o


def trunk(pts, r, name="trunk", taper=0.55):
    t = tube(pts, r, taper, 10)
    paint(t, lambda p, n: mix(BARK_D, BARK, smoothstep(-0.5, 0.8, n.x + n.y * 0.3)))
    setmat(t, mat("barkv", vcol=True, rough=0.85, bump=0.5, bump_scale=8))
    return t


# ------------------------------------------------------------------ peças do chão

def tree():
    """Árvore de copa em três tufos, tronco grosso: lê de cima como uma bola verde com miolo claro."""
    P = [trunk([(0, 0, 0), (0.05, 0, 1.2), (-0.05, 0.05, 2.2), (0, 0, 3.0)], 0.32)]
    for sx, a in ((1, 30), (-1, -20)):
        P.append(trunk([(0, 0, 1.6), (sx * 0.5, 0.1, 2.3), (sx * 0.8, 0.0, 2.9)], 0.12, taper=0.5))
    roots = [trunk([(0, 0, 0.35), (math.cos(a) * 0.45, math.sin(a) * 0.45, 0.02)], 0.14, taper=0.4) for a in (0.3, 2.4, 4.4)]
    P += roots
    P.append(foliage([((0, 0, 3.6), (1.5, 1.4, 1.15)), ((0.95, 0.2, 3.1), (0.95, 0.9, 0.8)), ((-0.9, -0.3, 3.2), (1.0, 0.95, 0.85)),
                      ((0.1, 0.8, 3.0), (0.9, 0.8, 0.75)), ((0.15, -0.4, 4.4), (0.9, 0.85, 0.7))], "crown", seed=1))
    return group("tree", P)


def tree_round():
    """Pinheiro arredondado: três saias empilhadas, a de cima mais clara."""
    P = [trunk([(0, 0, 0), (0, 0, 1.0), (0, 0, 2.0)], 0.22)]
    blobs = []
    for i, (z, r) in enumerate(((1.4, 1.35), (2.3, 1.05), (3.1, 0.75), (3.75, 0.42))):
        blobs.append(((0, 0, z), (r, r, r * 0.62)))
    P.append(foliage(blobs, "pine", seed=2, base=(0.05, 0.25, 0.15), light=(0.2, 0.45, 0.2), dark=(0.02, 0.1, 0.07)))
    return group("tree_round", P)


def dead_tree():
    P = [trunk([(0, 0, 0), (0.1, 0, 1.0), (-0.1, 0.1, 2.0), (0.05, 0.0, 2.8)], 0.22, taper=0.35)]
    for (a, b, c) in (((0, 0, 1.4), (0.7, 0.2, 2.0), (1.1, 0.0, 2.6)), ((0, 0, 1.9), (-0.6, -0.2, 2.5), (-0.8, 0.1, 3.1)),
                      ((0, 0, 2.3), (0.2, 0.6, 3.0), (0.4, 0.5, 3.4))):
        P.append(trunk([a, b, c], 0.09, taper=0.25))
    for o in P:
        paint(o, lambda p, n: mix((0.2, 0.17, 0.16), (0.44, 0.38, 0.33), smoothstep(-0.5, 0.9, n.z + n.x * 0.3)))
    roots = [trunk([(0, 0, 0.3), (math.cos(a) * 0.5, math.sin(a) * 0.5, 0.02)], 0.1, taper=0.3) for a in (0.5, 2.6, 4.5)]
    for o in roots:
        paint(o, lambda p, n: (0.25, 0.21, 0.19))
    P += roots
    return group("dead_tree", P)


def bush():
    P = [foliage([((0, 0, 0.45), (0.75, 0.7, 0.55)), ((0.55, 0.2, 0.35), (0.5, 0.45, 0.4)), ((-0.5, -0.15, 0.35), (0.5, 0.5, 0.4)),
                  ((0.1, -0.45, 0.3), (0.45, 0.4, 0.35))], "bush", voxel=0.04, seed=3)]
    r = rng(3)
    for k in range(5):  # frutinhas vermelhas: um ponto de cor que lê de cima
        a = r.random() * math.tau
        b = sph((math.cos(a) * 0.55, math.sin(a) * 0.5, 0.5 + r.random() * 0.25), 0.07); setmat(b, mat("berry", (0.9, 0.18, 0.2), 0.4, coat=0.6)); P.append(b)
    return group("bush", P)


def _stone(loc, size, rot, seed, bevel=0.08, pts=14):
    """Pedra facetada: casco convexo de pontos sorteados num elipsoide, quinas chanfradas, musgo no topo."""
    r = rng(seed)
    bm = bmesh.new()
    for k in range(pts):
        z = r.uniform(-0.6, 1.0); a = r.uniform(0, math.tau); rr = math.sqrt(max(0.0, 1 - z * z))
        bm.verts.new((math.cos(a) * rr * size[0] / 2, math.sin(a) * rr * size[1] / 2, z * size[2] / 2))
    for x in (-1, 1):
        for y in (-1, 1):
            bm.verts.new((x * size[0] * 0.38, y * size[1] * 0.38, -size[2] / 2))
    bmesh.ops.convex_hull(bm, input=bm.verts)
    me = bpy.data.meshes.new("st"); bm.to_mesh(me); bm.free()
    s = bpy.data.objects.new("st", me); bpy.context.scene.collection.objects.link(s)
    s.location = loc; s.rotation_euler = [math.radians(a) for a in rot]
    _sel(s); bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    b = s.modifiers.new("bv", 'BEVEL'); b.width = bevel; b.segments = 2; b.limit_method = 'ANGLE'; b.angle_limit = math.radians(25)
    s = hard(s)

    def col(p, n):
        c = mix(STONE_D, STONE, smoothstep(-0.6, 0.8, n.z) * 0.8 + 0.2)
        return mix(c, MOSS, smoothstep(0.55, 0.95, n.z) * smoothstep(-0.2, 0.4, noise.noise(p * 2.0 + Vector((seed, 0, 0)))))
    paint(s, col); setmat(s, mat("stonev", vcol=True, rough=0.85))
    return s


def rock():
    P = [_stone((0, 0, 0.35), (1.1, 0.85, 0.75), (8, -6, 20), 1), _stone((0.55, 0.3, 0.2), (0.55, 0.5, 0.4), (-10, 12, 50), 2),
         _stone((-0.45, -0.35, 0.12), (0.4, 0.35, 0.25), (5, 0, -30), 3)]
    return group("rock", P)


def road_stone():
    return group("road_stone", [_stone((0, 0, 0.06), (0.55, 0.45, 0.2), (0, 0, 15), 4, 0.05)])


def grass():
    """Tufo de folhas largas (lê melhor que fios finos visto de cima)."""
    P = []
    r = rng(5)
    for k in range(7):
        a = k / 7 * math.tau + r.random() * 0.4
        h = 0.35 + r.random() * 0.3
        b = tube([(0, 0, 0), (math.cos(a) * 0.08, math.sin(a) * 0.08, h * 0.5), (math.cos(a) * 0.2, math.sin(a) * 0.2, h)], 0.035, 0.1, 6)
        paint(b, lambda p, n: mix((0.12, 0.3, 0.12), (0.5, 0.68, 0.25), smoothstep(0.0, 0.5, p.z))); setmat(b, mat("grassv", vcol=True, rough=0.8)); P.append(b)
    return group("grass", P)


def flowers():
    P = []
    r = rng(6)
    cols = [(1.0, 0.85, 0.3), (0.95, 0.5, 0.75), (0.95, 0.95, 0.95)]
    for k in range(5):
        x, y = r.uniform(-0.35, 0.35), r.uniform(-0.35, 0.35)
        st = tube([(x, y, 0), (x, y, 0.22)], 0.012, 1.0, 4); setmat(st, mat("stem", (0.2, 0.42, 0.15), 0.8)); P.append(st)
        c = cols[k % 3]
        # pétalas fundidas numa peça só por flor (espalhadas às centenas: poucas partes, poucos triângulos)
        pe = fuse([sph((x + math.cos(j / 5 * math.tau) * 0.05, y + math.sin(j / 5 * math.tau) * 0.05, 0.23), 1, (0.045, 0.045, 0.015)) for j in range(5)], "petals", 0.012, 0.3, 2)
        setmat(pe, mat("petal%d" % (k % 3), c, 0.6)); P.append(pe)
        ce = sph((x, y, 0.24), 0.025); setmat(ce, mat("fcenter", (1.0, 0.7, 0.15), 0.5)); P.append(ce)
    return group("flowers", P)


def mushroom():
    P = []
    for (x, y, s) in ((0, 0, 1.0), (0.22, 0.12, 0.6), (-0.15, 0.18, 0.45)):
        st = cyl((x, y, 0.12 * s), 0.05 * s, 0.24 * s, seg=10, bevel=0.01, r2=0.04 * s); hard(st); setmat(st, mat("mstem", (0.95, 0.9, 0.8), 0.6)); P.append(st)
        cap = sph((x, y, 0.25 * s), 1, (0.16 * s, 0.16 * s, 0.1 * s)); shade(cap); setmat(cap, mat("mcap", (0.85, 0.2, 0.18), 0.4, coat=0.5)); P.append(cap)
        for k in range(3):
            a = k * 2.1
            d = sph((x + math.cos(a) * 0.08 * s, y + math.sin(a) * 0.08 * s, 0.33 * s), 0.025 * s); setmat(d, mat("mdot", (1, 0.97, 0.9), 0.5)); P.append(d)
    return group("mushroom", P)


# ------------------------------------------------------------------ estrada e locais

def plank(loc, size, rot=(0, 0, 0), seed=0, col=TIMBER, bevel=0.025):
    p = box(loc, size, rot, bevel=bevel, seg=2)
    jitter(p, min(size) * 0.06, 2.5, seed)
    p = hard(p)
    setmat(p, mat("woodh_%s" % str(col), col, 0.75, bump=0.4, bump_scale=12))
    return p


def fence():
    P = []
    for i, x in enumerate((-1.0, 0.0, 1.0)):
        P.append(plank((x, 0, 0.5), (0.16, 0.16, 1.05), (0, (i - 1) * 3, i * 7), i, (0.42, 0.27, 0.15)))
        cap = box((x, 0, 1.05), (0.2, 0.2, 0.06), (0, 0, i * 7), bevel=0.02, taper=(0.4, 0.4)); hard(cap); setmat(cap, mat("wood_d", (0.3, 0.18, 0.1), 0.8)); P.append(cap)
    for z, a in ((0.72, 2), (0.38, -3)):
        P.append(plank((0, -0.09, z), (2.3, 0.07, 0.15), (a, 0, 0), int(z * 10), (0.52, 0.34, 0.19)))
    for x in (-1.0, 0.0, 1.0):
        for z in (0.72, 0.38):
            n = cyl((x, -0.14, z), 0.025, 0.02, (90, 0, 0), seg=8, bevel=0.005); hard(n); setmat(n, mat("ironn", IRON, 0.5, 0.8)); P.append(n)
    return group("fence", P)


def lantern():
    """Poste com lampião. Escala real e sem recentralizar: o jogo põe a luz em (+0,5; 2,15) na Godot,
    que é x = -0,5 no Blender (o eixo x inverte na conversão)."""
    P = [plank((0, 0, 1.2), (0.18, 0.18, 2.4), (0, 0, 0), 1, (0.3, 0.19, 0.11))]
    base = _stone((0, 0, 0.12), (0.45, 0.45, 0.25), (0, 0, 10), 9, 0.05); P.append(base)
    arm = plank((-0.28, 0, 2.38), (0.6, 0.1, 0.1), (0, 0, 0), 2, (0.3, 0.19, 0.11)); P.append(arm)
    brace = plank((-0.18, 0, 2.16), (0.36, 0.07, 0.07), (0, -45, 0), 3, (0.3, 0.19, 0.11)); P.append(brace)
    hook = torus((-0.5, 0, 2.3), 0.04, 0.012, (90, 0, 0)); shade(hook); setmat(hook, mat("ironn", IRON, 0.5, 0.8)); P.append(hook)
    # lampião: gaiola de ferro chanfrada com o miolo aceso
    top = box((-0.5, 0, 2.25), (0.26, 0.26, 0.08), (0, 0, 45), bevel=0.02, taper=(0.4, 0.4)); hard(top); setmat(top, mat("ironn", IRON, 0.5, 0.8)); P.append(top)
    bot = box((-0.5, 0, 1.93), (0.22, 0.22, 0.05), (0, 0, 45), bevel=0.015); hard(bot); setmat(bot, mat("ironn", IRON, 0.5, 0.8)); P.append(bot)
    for k in range(4):
        a = k * math.pi / 2
        bar = box((-0.5 + math.cos(a) * 0.11, math.sin(a) * 0.11, 2.08), (0.03, 0.03, 0.28), bevel=0.008); hard(bar); setmat(bar, mat("ironn", IRON, 0.5, 0.8)); P.append(bar)
    core = sph((-0.5, 0, 2.08), 1, (0.09, 0.09, 0.12)); setmat(core, mat("flame", WARM, 0.5, emit=8.0)); P.append(core)
    return group("lantern", P)


def gravestone():
    P = []
    s = box((0, 0, 0.55), (0.75, 0.22, 1.1), (0, 0, 0), bevel=0.05, seg=2)
    # topo arredondado: aproxima com uma esfera achatada fundida
    apply_mods(s)
    top = cyl((0, 0, 1.1), 0.375, 0.22, (90, 0, 0), seg=16, bevel=0.04); apply_mods(top)
    s = join([s, top], "stone"); jitter(s, 0.02, 2.0, 11); s = hard(s)
    paint(s, lambda p, n: mix(mix(STONE_D, STONE, smoothstep(-0.5, 0.9, n.z) * 0.7 + 0.15), MOSS, smoothstep(0.6, 1.0, n.z) * 0.6))
    setmat(s, mat("stonev", vcol=True, rough=0.85)); P.append(s)
    cross = box((0, -0.12, 0.85), (0.08, 0.03, 0.36), bevel=0.01); hard(cross); setmat(cross, mat("stone_d", STONE_D, 0.8)); P.append(cross)
    cross2 = box((0, -0.12, 0.92), (0.24, 0.03, 0.08), bevel=0.01); hard(cross2); setmat(cross2, mat("stone_d", STONE_D, 0.8)); P.append(cross2)
    mound = fuse([sph((0, -0.5, 0.0), 1, (0.45, 0.65, 0.15))], "mound", 0.04)
    paint(mound, lambda p, n: mix((0.34, 0.26, 0.17), (0.3, 0.45, 0.18), smoothstep(0.7, 1.0, n.z) * 0.5)); setmat(mound, mat("dirtv", vcol=True, rough=0.9)); P.append(mound)
    return group("gravestone", P)


def _roof(loc, w, d, h, rot_z=0, col=ROOF, col_d=ROOF_D, over=0.35):
    """Telhado de duas águas em fileiras de telha chanfradas (lê de cima como listras)."""
    out = []
    rows = 5
    for side in (-1, 1):
        for i in range(rows):
            t0 = i / rows
            L = d / 2 + over
            f = t0 + 0.5 / rows
            y = side * L * (1 - f)
            z = h * f - 0.05
            ang = -side * math.degrees(math.atan2(h, L))
            sl = math.hypot(h, L)
            c = mix(col_d, col, i / (rows - 1)) if side > 0 else mix(col_d, col, i / (rows - 1) * 0.8)
            t = box((0, y, z + 0.05 * i), (w + over * 2, sl / rows * 1.3, 0.12), (ang, 0, 0), bevel=0.03, seg=2)
            jitter(t, 0.015, 3.0, i + side * 10); t = hard(t)
            setmat(t, mat("tile_%d_%d" % (i, side), c, 0.7)); out.append(t)
    ridge = box((0, 0, h + 0.05), (w + over * 2.2, 0.22, 0.16), bevel=0.04); hard(ridge); setmat(ridge, mat("tile_r", col_d, 0.7)); out.append(ridge)
    return xform(out, Matrix.Translation(loc) @ Matrix.Rotation(math.radians(rot_z), 4, 'Z'))


def xform(objs, M):
    bpy.context.view_layer.update()
    for o in objs:
        o.matrix_world = M @ o.matrix_world
    return objs


def _window(x, y, z, face_y, lit=True):
    out = []
    fr = box((x, y, z), (0.6, 0.12, 0.7), bevel=0.02); hard(fr); setmat(fr, mat("timber", TIMBER, 0.8)); out.append(fr)
    gl = box((x, y + face_y * 0.05, z), (0.44, 0.06, 0.54), bevel=0.01); hard(gl); setmat(gl, mat("winglow", WARM, 0.4, emit=3.0) if lit else mat("winglass", (0.2, 0.25, 0.35), 0.2)); out.append(gl)
    m1 = box((x, y + face_y * 0.08, z), (0.05, 0.04, 0.56), bevel=0.005); hard(m1); setmat(m1, mat("timber", TIMBER, 0.8)); out.append(m1)
    m2 = box((x, y + face_y * 0.08, z), (0.46, 0.04, 0.05), bevel=0.005); hard(m2); setmat(m2, mat("timber", TIMBER, 0.8)); out.append(m2)
    sill = box((x, y + face_y * 0.1, z - 0.4), (0.7, 0.18, 0.07), bevel=0.02); hard(sill); setmat(sill, mat("timber", TIMBER, 0.8)); out.append(sill)
    return out


def house(tavern=False):
    """Casa de enxaimel: base de pedra, paredes de reboco com vigas, telhado de telha, chaminé."""
    P = []
    W, D, H = (5.0, 3.6, 2.6) if not tavern else (6.4, 4.2, 3.4)
    # base de pedras chanfradas
    r = rng(12)
    x = -W / 2
    while x < W / 2:
        w = r.uniform(0.5, 0.9)
        for y in (-D / 2, D / 2):
            P.append(_stone((x + w / 2, y, 0.25), (w, 0.35, 0.5), (0, 0, r.uniform(-3, 3)), int(x * 10) + int(y), 0.05))
        x += w
    y = -D / 2
    while y < D / 2:
        w = r.uniform(0.5, 0.9)
        for xx in (-W / 2, W / 2):
            P.append(_stone((xx, y + w / 2, 0.25), (0.35, w, 0.5), (0, 0, r.uniform(-3, 3)), int(y * 10) + int(xx) + 50, 0.05))
        y += w
    wall = box((0, 0, 0.5 + H / 2), (W - 0.2, D - 0.2, H), bevel=0.04); hard(wall); setmat(wall, mat("plaster", PLASTER, 0.9, bump=0.2, bump_scale=6)); P.append(wall)
    # empena (triângulo) nas pontas
    for sx in (-1, 1):
        g = box((sx * (W / 2 - 0.1), 0, 0.5 + H + 0.65), (0.1, D - 0.2, 1.3), bevel=0.0, taper=(1.0, 0.05)); apply_mods(g)
        shade(g, False); setmat(g, mat("plaster", PLASTER, 0.9, bump=0.2, bump_scale=6)); P.append(g)
    # vigas
    for xx in [-W / 2 + 0.05, -W / 6, W / 6, W / 2 - 0.05]:
        for yy in (-D / 2 + 0.05, D / 2 - 0.05):
            P.append(plank((xx, yy, 0.5 + H / 2), (0.18, 0.16, H), (0, 0, 0), int(xx * 10 + yy)))
    for yy in (-D / 2 + 0.05, D / 2 - 0.05):
        for z in (0.55, 0.5 + H - 0.05):
            P.append(plank((0, yy, z), (W, 0.17, 0.18), (0, 0, 0), int(z * 10 + yy)))
        P.append(plank((-W / 3, yy, 0.5 + H / 2), (0.14, 0.12, H * 1.1), (0, 38, 0), 5))
        P.append(plank((W / 3, yy, 0.5 + H / 2), (0.14, 0.12, H * 1.1), (0, -38, 0), 6))
    # porta e janelas na frente (-Y)
    door = box((0, -D / 2 - 0.02, 0.5 + 0.9), (0.9, 0.14, 1.8), bevel=0.03); hard(door); setmat(door, mat("door", (0.45, 0.25, 0.13), 0.75, bump=0.4, bump_scale=10)); P.append(door)
    knob = sph((0.3, -D / 2 - 0.12, 1.3), 0.05); setmat(knob, mat("brass", (0.85, 0.6, 0.25), 0.3, 1.0)); P.append(knob)
    step = _stone((0, -D / 2 - 0.4, 0.1), (1.3, 0.6, 0.2), (0, 0, 0), 21, 0.04); P.append(step)
    for xx in (-W / 3 - 0.1, W / 3 + 0.1):
        P += _window(xx, -D / 2 - 0.03, 0.5 + H * 0.55, -1)
    P += _window(-W / 4, D / 2 + 0.03, 0.5 + H * 0.55, 1, False)
    P += _roof((0, 0, 0.5 + H), W, D, 1.5 if not tavern else 1.8)
    ch = []
    cx = W / 4
    for i in range(4):
        ch.append(_stone((cx, D / 4, 0.5 + H + 1.0 + i * 0.35), (0.6, 0.6, 0.36), (0, 0, i * 4), 30 + i, 0.04))
    P += ch
    if tavern:
        # placa pendurada com caneca e barril na porta
        arm = plank((-W / 2 - 0.4, -D / 2 - 0.1, 0.5 + H - 0.3), (0.9, 0.1, 0.1), (0, 0, 0), 40); P.append(arm)
        sign = plank((-W / 2 - 0.65, -D / 2 - 0.1, 0.5 + H - 0.8), (0.7, 0.08, 0.5), (0, 0, 0), 41, (0.55, 0.36, 0.2)); P.append(sign)
        mug = cyl((-W / 2 - 0.65, -D / 2 - 0.16, 0.5 + H - 0.8), 0.12, 0.24, (0, 0, 0), seg=12, bevel=0.02); hard(mug); setmat(mug, mat("gold", GOLD, 0.3, 1.0)); P.append(mug)
        foam = sph((-W / 2 - 0.65, -D / 2 - 0.16, 0.5 + H - 0.65), 1, (0.13, 0.13, 0.07)); setmat(foam, mat("foam", (1, 0.97, 0.9), 0.6)); P.append(foam)
        for k, xx in enumerate((0.9, 1.6)):
            b = cyl((xx, -D / 2 - 0.5, 0.4), 0.32, 0.8, seg=16, bevel=0.05, r2=0.32); hard(b); setmat(b, mat("woodh_b", (0.5, 0.3, 0.16), 0.75, bump=0.4, bump_scale=12)); P.append(b)
            for z in (0.15, 0.65):
                h_ = torus((xx, -D / 2 - 0.5, z), 0.33, 0.025); shade(h_); setmat(h_, mat("ironn", IRON, 0.5, 0.8)); P.append(h_)
    return group("tavern" if tavern else "house", P)


def tavern():
    return house(True)
