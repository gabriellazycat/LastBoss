"""Peças paradas refeitas à mão (rodada de modelos 3D, 20/11/2026): casa, taverna, covil (castle), pilar, braseiro e
altar da arena, com silhueta forte e riqueza em escala média. Regras do usuário: guache das cartas, pincel largo, nada
menor que ~5% da altura da peça, legível de cima (câmera alta ~50°), olhos (caveiras) de uma cor só, sem pupila.
Mesmo tamanho, origem e frente (-Y no Blender) das peças antigas (g_n_a), exportadas como no g (vat_g + atlas "dry").

"C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --factory-startup -P tools/art/blender_m2/build_m2.py -- <saída> [ids] [--prev=<pasta>] [--giro=<pasta>]
Saída: <saída>/n/<id>.lbm e <saída>/tex/m2/<id>.png. Depois:
  godot --headless --path . -s res://tools/art/import_g.gd -- --src=<saída> --m2
  godot --headless --path . --import
No jogo: Looks.m2_mesh (assets/models/m2_a)."""
import os, sys, math, random, traceback
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "blender_v2"))
sys.path.insert(0, os.path.join(HERE, "..", "blender_g"))
import bpy, bmesh
from mathutils import Vector, Matrix, noise
import mk
from mk import box, cyl, sph, tube, group, setmat, paint, mix, smoothstep, apply_mods, shade, _sel
import vat, vat_g, treat

# id -> (altura no jogo (None = escala do Blender), orçamento de triângulos, lado do atlas)
PROPS = {
    "house": (3.9, 4800, 1024), "tavern": (4.3, 6400, 1024), "castle": (None, 8000, 1024),
    "pillar": (None, 1500, 512), "brazier": (None, 1200, 512), "altar": (None, 1450, 512),
}
# Graduação do cenário como a do jogo (MODELOS_GUACHE: LBG_PULL_SC 0,25, LBG_SAT 1,45, LBG_GAIN_SC 0,6).
PULL, SAT, GAIN = 0.25, 1.45, 0.6
COOL = (0.30, 0.32, 0.42)
SAT_OF = {"house": 1.05, "tavern": 1.05}


def L(c):
    """sRGB -> linear (as cores abaixo são pensadas em sRGB; o kit trabalha em linear)."""
    return tuple((x / 12.92) if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in c)


# Paleta (sRGB), tirada das cartas: madeira quente, reboco creme, telha de barro, palha ocre, pedra cinza-lavanda.
PLASTER, PLASTER_D = L((0.98, 0.95, 0.88)), L((0.90, 0.84, 0.74))   # claro como as antigas: contraste com o telhado
TIMBER, TIMBER_L = L((0.40, 0.26, 0.17)), L((0.52, 0.35, 0.22))
TILE, TILE_L, TILE_D = L((0.86, 0.50, 0.40)), L((0.93, 0.64, 0.52)), L((0.66, 0.33, 0.28))
THATCH, THATCH_L, THATCH_D = L((0.66, 0.48, 0.30)), L((0.76, 0.58, 0.36)), L((0.46, 0.32, 0.20))
STONE, STONE_L, STONE_D = L((0.62, 0.60, 0.64)), L((0.76, 0.74, 0.76)), L((0.42, 0.40, 0.47))
MOSS = L((0.46, 0.58, 0.30))
WARM = L((1.0, 0.76, 0.42))
SHUTTER, SHUTTER_R = L((0.34, 0.52, 0.58)), L((0.66, 0.30, 0.26))
DOOR = L((0.50, 0.31, 0.19))
IRON, IRON_L = L((0.30, 0.30, 0.36)), L((0.45, 0.44, 0.50))
GOLD = L((0.92, 0.70, 0.32))
CREAM = L((0.95, 0.90, 0.78))
RED = L((0.72, 0.22, 0.24))
FLOWER = L((0.95, 0.42, 0.55))
LEAF = L((0.36, 0.55, 0.28))
# covil: rocha escura arroxeada (não preta: as cartas não têm preto), chifres de osso, brilho roxo do chefe
ROCK, ROCK_L, ROCK_D = L((0.40, 0.36, 0.46)), L((0.56, 0.52, 0.60)), L((0.25, 0.22, 0.30))
BONE, BONE_D = L((0.93, 0.88, 0.74)), L((0.70, 0.64, 0.54))
MAW = L((0.10, 0.06, 0.12))
RUNE = L((0.86, 0.45, 1.0))
FIRE, FIRE_L = L((1.0, 0.48, 0.16)), L((1.0, 0.86, 0.42))
CLOTH, CLOTH_D = L((0.62, 0.16, 0.22)), L((0.42, 0.10, 0.16))
ROOF_P = L((0.42, 0.20, 0.50))
# arena: pedra cinza-lavanda como o piso
ASTONE, ASTONE_L, ASTONE_D = L((0.58, 0.52, 0.66)), L((0.72, 0.67, 0.78)), L((0.38, 0.33, 0.47))


# ------------------------------------------------------------------ ferramentas

def M(name, col, rough=0.8, emit=0.0):
    return mk.mat(name, col, rough, emit=emit)


def V(name, emit=0.0):
    return mk.mat(name, vcol=True, rough=0.8, emit=emit)


def blotch(o, a, b, scale=0.8, seed=0, up=None, k=0.55):
    """Cor por vértice em manchas largas (pincel largo): a..b pelo ruído; `up` = cor do que olha para cima."""
    off = Vector((seed * 3.1, seed * 1.7, seed * 0.9))

    def f(p, n):
        t = noise.noise(p * scale + off) * 0.5 + 0.5
        c = mix(a, b, smoothstep(0.3, 0.7, t))
        if up is not None:
            c = mix(c, up, smoothstep(0.45, 0.95, n.z) * k)
        return c
    paint(o, f)
    setmat(o, V("v_%s" % o.name))
    return o


def hull(loc, size, rot=(0, 0, 0), seed=0, pts=12, bevel=0.0, flat_bottom=True):
    """Pedra facetada (casco convexo de pontos num elipsoide), poucas faces: lê como pincelada larga."""
    r = random.Random(seed)
    bm = bmesh.new()
    for k in range(pts):
        z = r.uniform(-0.5 if flat_bottom else -1.0, 1.0)
        a = r.uniform(0, math.tau)
        rr = math.sqrt(max(0.0, 1 - z * z))
        bm.verts.new((math.cos(a) * rr * size[0] / 2, math.sin(a) * rr * size[1] / 2, z * size[2] / 2))
    if flat_bottom:
        for x in (-1, 1):
            for y in (-1, 1):
                bm.verts.new((x * size[0] * 0.36, y * size[1] * 0.36, -size[2] / 2))
    bmesh.ops.convex_hull(bm, input=bm.verts)
    me = bpy.data.meshes.new("hull")
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new("hull", me)
    bpy.context.scene.collection.objects.link(o)
    o.location = loc
    o.rotation_euler = [math.radians(a) for a in rot]
    _sel(o)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    if bevel:
        b = o.modifiers.new("bv", 'BEVEL'); b.width = bevel; b.segments = 1; b.limit_method = 'ANGLE'
        apply_mods(o)
    shade(o, False)
    return o


def bx(loc, size, rot=(0, 0, 0), bevel=0.03, taper=None):
    o = box(loc, size, rot, bevel=bevel, seg=1, taper=taper)
    apply_mods(o)
    shade(o, False)
    return o


def cy(loc, r, h, rot=(0, 0, 0), seg=8, r2=None, bevel=0.0):
    o = cyl(loc, r, h, rot, seg=seg, bevel=bevel, r2=r2)
    apply_mods(o)
    shade(o, False)
    return o


def bend(objs, fn):
    """Desloca os vértices (no mundo) por fn(p) -> Vector: cumeeira torta, telhado caído."""
    bpy.context.view_layer.update()
    for o in objs:
        apply_mods(o)
        mw = o.matrix_world
        inv = mw.inverted()
        for v in o.data.vertices:
            p = mw @ v.co
            v.co = inv @ (p + fn(p))
    return objs


def subdiv(o, cuts):
    """Corta as arestas (para o telhado poder envergar)."""
    apply_mods(o)
    bm = bmesh.new()
    bm.from_mesh(o.data)
    bmesh.ops.subdivide_edges(bm, edges=bm.edges[:], cuts=cuts, use_grid_fill=True)
    bm.to_mesh(o.data)
    bm.free()
    return o


def prism(pts, z0, z1, axis='Y', at=0.0):
    """Prisma de um polígono 2D (x, z) extrudado no eixo Y de at-d/2 a at+d/2 com d = z1 - z0 (empena)."""
    bm = bmesh.new()
    vs = [bm.verts.new((x, z0, z)) for x, z in pts]
    f = bm.faces.new(vs)
    ext = bmesh.ops.extrude_face_region(bm, geom=[f])
    for v in [e for e in ext["geom"] if isinstance(e, bmesh.types.BMVert)]:
        v.co.y = z1
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new("prism")
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new("prism", me)
    bpy.context.scene.collection.objects.link(o)
    shade(o, False)
    return o


def horn(base, r, h, lean=(0.0, 0.0), curl=0.0, seg=6, rings=6, name="horn"):
    """Chifre/pico: anéis de `seg` lados ao longo de uma curva, afinando até a ponta."""
    bm = bmesh.new()
    rings_v = []
    for i in range(rings):
        t = i / rings
        rr = r * (1 - t) ** 0.85
        c = Vector(base) + Vector((lean[0] * t * t * h, lean[1] * t * t * h, h * t))
        c.x += curl * math.sin(t * math.pi) * h * 0.15
        ring = [bm.verts.new(c + Vector((math.cos(a) * rr, math.sin(a) * rr, 0))) for a in
                [k / seg * math.tau + i * 0.25 for k in range(seg)]]
        rings_v.append(ring)
    tip = bm.verts.new(Vector(base) + Vector((lean[0] * h, lean[1] * h, h)))
    for i in range(rings - 1):
        a, b = rings_v[i], rings_v[i + 1]
        for k in range(seg):
            bm.faces.new([a[k], a[(k + 1) % seg], b[(k + 1) % seg], b[k]])
    top = rings_v[-1]
    for k in range(seg):
        bm.faces.new([top[k], top[(k + 1) % seg], tip])
    bm.faces.new(list(reversed(rings_v[0])))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(o)
    shade(o, False)
    return o


def tongue(loc, w, h, rot_z=0.0, lean=0.0):
    """Língua de fogo: gota alongada com a ponta torta (forma larga, sem miúdo)."""
    o = sph(loc, 1, (w, w * 0.8, h * 0.5), seg=10)
    apply_mods(o)
    for v in o.data.vertices:
        t = (v.co.z + 1) / 2
        k = 1.0 - t ** 2.4 * 0.92
        v.co.x *= k
        v.co.y *= k
        v.co.x += lean * t * t
        v.co.z += t * t * 0.4
    o.rotation_euler = (0, 0, rot_z)
    shade(o, True)
    return o


def glow_paint(o, z0, z1, a=FIRE, b=FIRE_L, emit=8.0, name="fire"):
    paint(o, lambda p, n: mix(a, b, smoothstep(z0, z1, p.z)))
    setmat(o, mk.mat(name, vcol=True, rough=0.5, emit=emit))
    return o


def window(x, y, z, face, w=0.5, h=0.6, lit=True, shut=SHUTTER, rot=0.0):
    """Janela larga: vidro aceso recuado, duas folhas de veneziana coloridas e peitoril. face = -1 frente (-Y), +1 trás.
    rot = 90 para as paredes do lado (x)."""
    P = []
    gl = bx((0, 0, 0), (w, 0.08, h), bevel=0.01)
    setmat(gl, M("win_lit", WARM, 0.4, emit=5.0) if lit else M("win_dark", L((0.22, 0.26, 0.36)), 0.3))
    P.append(gl)
    fr = bx((0, 0.02 * -face, h / 2 + 0.06), (w + 0.2, 0.14, 0.12), bevel=0.02)
    setmat(fr, M("timber", TIMBER))
    P.append(fr)
    sill = bx((0, 0.06 * face, -h / 2 - 0.06), (w + 0.26, 0.2, 0.12), bevel=0.02)
    setmat(sill, M("timber_l", TIMBER_L))
    P.append(sill)
    for sx in (-1, 1):
        s = bx((sx * (w / 2 + 0.15), 0.05 * face, 0), (0.28, 0.07, h + 0.04), (0, 0, sx * face * 12), bevel=0.015)
        setmat(s, M("shut_%s" % str(shut), shut, 0.8))
        P.append(s)
    Mx = Matrix.Translation((x, y, z)) @ Matrix.Rotation(math.radians(rot), 4, 'Z')
    for o in P:
        o.matrix_world = Mx @ o.matrix_world
    return P


def timber(a, b, t=0.17):
    """Viga reta de a até b (seção t x t), quina chanfrada."""
    a, b = Vector(a), Vector(b)
    d = b - a
    o = bx((0, 0, 0), (t, t, d.length + t * 0.6), bevel=0.025)
    o.matrix_world = Matrix.Translation((a + b) / 2) @ d.to_track_quat('Z', 'Y').to_matrix().to_4x4()
    setmat(o, M("timber", TIMBER))
    return o


# ------------------------------------------------------------------ casa e taverna

def _walls(W, D, z0, z1, seed, rot=0.0):
    w = bx((0, 0, (z0 + z1) / 2), (W, D, z1 - z0), (0, 0, rot), bevel=0.04)
    w = subdiv(w, 2)
    return blotch(w, PLASTER, PLASTER_D, 0.9, seed)


def _frame(W, D, z0, z1, t=0.17, braces=True, back=True):
    """Enxaimel largo: postes nos cantos e no meio, viga de baixo e de cima, uma mão-francesa em cada face larga."""
    P = []
    hx, hy = W / 2 + 0.02, D / 2 + 0.02
    for x in (-hx, hx):
        for y in (-hy, hy):
            P.append(timber((x, y, z0), (x, y, z1), t))
    for y in (-hy, hy):
        P.append(timber((-hx, y, z1 - t / 2), (hx, y, z1 - t / 2), t))
        P.append(timber((-hx, y, z0 + t / 2), (hx, y, z0 + t / 2), t))
        if braces and (back or y < 0):
            P.append(timber((-hx + 0.1, y, z0 + 0.1), (-hx + (z1 - z0) * 0.8, y, z1 - 0.12), t * 0.9))
            P.append(timber((hx - 0.1, y, z0 + 0.1), (hx - (z1 - z0) * 0.8, y, z1 - 0.12), t * 0.9))
    for x in (-hx, hx):
        P.append(timber((x, -hy, z1 - t / 2), (x, hy, z1 - t / 2), t))
    return P


def _tile_roof(W, D, z_eave, z_ridge, over_x=0.32, over_y=0.42, courses=3, cols=(TILE_D, TILE, TILE_L), thick=0.16,
               sag=0.13, name="tile", bevel=0.035):
    """Telhado de duas águas com fileiras largas de telha (degrau entre elas), cumeeira envergada."""
    P = []
    hy = D / 2 + over_y
    zl = z_eave - over_y * (z_ridge - z_eave) / (D / 2)
    for side in (-1, 1):
        for i in range(courses):
            t0, t1 = i / courses, (i + 1) / courses + 0.08
            p0 = Vector((0, side * hy * (1 - t0), zl + (z_ridge - zl) * t0))
            p1 = Vector((0, side * hy * (1 - min(t1, 1.0)), zl + (z_ridge - zl) * min(t1, 1.0)))
            mid = (p0 + p1) / 2
            ln = (p1 - p0).length
            ang = math.degrees(math.atan2(p1.z - p0.z, abs(p1.y - p0.y)))
            o = bx((0, 0, 0), (W + over_x * 2, ln, thick), bevel=bevel)
            o = subdiv(o, 3)
            o.matrix_world = Matrix.Translation(mid + Vector((0, 0, thick * 0.4 * (courses - i) / courses))) @ \
                Matrix.Rotation(math.radians(-side * ang), 4, 'X')
            c = cols[i % len(cols)]
            o = blotch(o, c, mix(c, cols[-1], 0.35), 1.6, i + side * 7)
            P.append(o)
    ridge = bx((0, 0, z_ridge + thick * 0.55), (W + over_x * 2.1, 0.32 + thick * 0.4, 0.32 + thick * 0.4), (45, 0, 0), bevel=0.04)
    ridge = subdiv(ridge, 3)
    setmat(ridge, M(name + "_ridge", cols[0], 0.8))
    P.append(ridge)
    Wr = W / 2 + over_x
    bend(P, lambda p: Vector((0, 0, -sag * (1 - (p.x / Wr) ** 2) + 0.05 * (p.x / Wr) * (1 if p.y > 0 else -1))))
    return P


def _thatch_roof(W, D, z_eave, z_ridge, over_x=0.38, over_y=0.5, sag=0.12):
    """Telhado de palha: duas águas grossas de borda redonda, faixa escura na beirada e cumeeira em rolo."""
    P = []
    hy = D / 2 + over_y
    zl = z_eave - over_y * (z_ridge - z_eave) / (D / 2)
    for side in (-1, 1):
        p0 = Vector((0, side * hy, zl))
        p1 = Vector((0, 0, z_ridge))
        mid = (p0 + p1) / 2
        ln = (p1 - p0).length + 0.15
        ang = math.degrees(math.atan2(z_ridge - zl, hy))
        o = box((0, 0, 0), (W + over_x * 2, ln, 0.42), bevel=0.17, seg=2)
        apply_mods(o)
        o = subdiv(o, 2)
        o.matrix_world = Matrix.Translation(mid) @ Matrix.Rotation(math.radians(-side * ang), 4, 'X')
        bpy.context.view_layer.update()
        o.data.transform(o.matrix_world)
        o.matrix_world = Matrix.Identity(4)

        def col(p, n, side=side):
            edge = smoothstep(0.35, 0.05, abs(abs(p.y) - hy) if True else 0)
            c = mix(THATCH, THATCH_L, smoothstep(0.3, 0.9, n.z) * 0.6 + (noise.noise(p * 1.3) * 0.5 + 0.5) * 0.3)
            low = smoothstep(zl + 0.45, zl, p.z)
            return mix(c, THATCH_D, low * 0.8)
        paint(o, col)
        setmat(o, V("v_thatch%d" % side))
        shade(o, True)
        P.append(o)
    ridge = cy((0, 0, z_ridge + 0.12), 0.3, W + over_x * 2.2, (0, 90, 0), seg=8)
    ridge = subdiv(ridge, 2)
    setmat(ridge, M("thatch_d", THATCH_D, 0.9))
    P.append(ridge)
    Wr = W / 2 + over_x
    bend(P, lambda p: Vector((0, 0, -sag * (1 - (p.x / Wr) ** 2) + 0.06 * (p.x / Wr) * (1 if p.y > 0 else -1))))
    return P


def _gable(W, D, z0, z1, x, over=0.0):
    """Empena de reboco (triângulo) na ponta x da casa, com a viga do meio."""
    g = prism([(-D / 2, z0), (D / 2, z0), (0, z1)], -0.09, 0.09)
    g.rotation_euler = (0, 0, math.radians(90))
    g.location = (x, 0, 0)
    bpy.context.view_layer.update()
    g = subdiv(g, 1)
    blotch(g, PLASTER, PLASTER_D, 0.9, int(x * 10) + 3)
    return [g, timber((x * 1.02, 0, z0), (x * 1.02, 0, z1 - 0.15)), timber((x * 1.02, -D / 2 + 0.2, z0 + 0.12), (x * 1.02, D / 2 - 0.2, z0 + 0.12))]


def _chimney(x, y, z0, z1, lean=4.0, seed=0):
    P = []
    c = bx((x, y, (z0 + z1) / 2), (0.6, 0.6, z1 - z0), (lean, -lean * 0.5, 7), bevel=0.05)
    c = subdiv(c, 2)
    blotch(c, STONE, STONE_D, 1.4, seed)
    P.append(c)
    top = bx((x + math.sin(math.radians(-lean * 0.5)) * 0 + (z1 - z0) * math.sin(math.radians(lean * 0.5)) * 0.5,
              y - (z1 - z0) * math.sin(math.radians(lean)) * 0.5, z1 + 0.08), (0.78, 0.78, 0.2), (0, 0, 7), bevel=0.04)
    setmat(top, M("stone_d", STONE_D))
    P.append(top)
    hole = bx((top.location.x, top.location.y, z1 + 0.19), (0.42, 0.42, 0.04), (0, 0, 7), bevel=0.0)
    setmat(hole, M("soot", L((0.18, 0.15, 0.18))))
    P.append(hole)
    return P


def _plinth(W, D, seed):
    """Base de pedra: um embasamento largo e pedras grandes de canto saindo para fora."""
    P = []
    b = bx((0, 0, 0.17), (W + 0.18, D + 0.18, 0.34), bevel=0.05)
    b = subdiv(b, 2)
    blotch(b, STONE, STONE_D, 1.2, seed, up=STONE_L, k=0.5)
    P.append(b)
    r = random.Random(seed)
    for x in (-1, 1):
        for y in (-1, 1):
            s = hull((x * (W / 2 + 0.05), y * (D / 2 + 0.05), 0.22), (0.62, 0.55, 0.48), (0, 0, r.uniform(0, 90)), seed + x * 3 + y)
            blotch(s, STONE_L, STONE, 1.5, seed + 9, up=MOSS, k=0.6)
            P.append(s)
    return P


def _door(x, y, w=0.82, h=1.25, z0=0.34, arch=True):
    P = []
    d = bx((x, y, z0 + h / 2), (w, 0.14, h), bevel=0.03)
    setmat(d, M("door", DOOR))
    P.append(d)
    if arch:
        a = cy((x, y, z0 + h), w / 2, 0.14, (90, 0, 0), seg=10)
        setmat(a, M("door", DOOR))
        P.append(a)
    for sx in (-1, 1):
        P.append(timber((x + sx * (w / 2 + 0.08), y - 0.03, z0), (x + sx * (w / 2 + 0.08), y - 0.03, z0 + h + (w / 2 if arch else 0) * 0.8), 0.16))
    lin = bx((x, y - 0.04, z0 + h + (w / 2 if arch else 0) + 0.08), (w + 0.42, 0.18, 0.18), bevel=0.02)
    setmat(lin, M("timber", TIMBER))
    P.append(lin)
    st = hull((x, y - 0.42, 0.1), (w + 0.5, 0.6, 0.22), (0, 0, 3), 77)
    blotch(st, STONE_L, STONE, 1.2, 3)
    P.append(st)
    ring = bx((x + w * 0.25, y - 0.1, z0 + h * 0.55), (0.14, 0.08, 0.14), bevel=0.02)
    setmat(ring, M("iron_l", IRON_L, 0.5))
    P.append(ring)
    return P


def _flowerbox(x, y, z, face=-1, w=0.75):
    P = []
    b = bx((x, y, z), (w, 0.22, 0.2), bevel=0.02)
    setmat(b, M("timber_l", TIMBER_L))
    P.append(b)
    r = random.Random(int(x * 100))
    fl = mk.fuse([sph((x + (k - 1.5) * w / 4.5, y + face * 0.02, z + 0.16), 1, (0.14, 0.12, 0.12), seg=8) for k in range(4)], "flowers", 0.04, 0.4, 2)
    paint(fl, lambda p, n: mix(LEAF, FLOWER, smoothstep(0.2, 0.7, noise.noise(p * 7.0) * 0.5 + 0.5 + (p.z - z) * 2.0)))
    setmat(fl, V("v_flowers"))
    shade(fl, True)
    P.append(fl)
    return P


def _barrel(loc, r=0.32, h=0.72, lying=False, seed=0):
    P = []
    rot = (90, 0, 20) if lying else (0, 0, seed * 13)
    b = cy(loc, r, h, rot, seg=10, r2=r)
    # barriga do barril
    mw = b.matrix_world
    ax = (mw.to_3x3() @ Vector((0, 0, 1))).normalized()
    c = Vector(loc)
    for v in b.data.vertices:
        p = mw @ v.co
        t = (p - c).dot(ax) / (h / 2)
        radial = (p - c) - ax * (p - c).dot(ax)
        v.co = mw.inverted() @ (p + radial.normalized() * r * 0.16 * (1 - t * t))
    setmat(b, M("barrel", L((0.62, 0.40, 0.24)), 0.75))
    P.append(b)
    for s in (-0.3, 0.3):
        hoop = cy(c + ax * h * s, r * 1.13, 0.09, rot, seg=10)
        setmat(hoop, M("iron", IRON, 0.5))
        P.append(hoop)
    return P


def house():
    """Casa de enxaimel com o andar de cima saliente, telhado de telha envergado, água-furtada e chaminé torta."""
    P = []
    W1, D1, W2, D2 = 3.4, 2.3, 3.7, 2.7
    z1, z2, z3, zr = 0.34, 1.7, 2.78, 3.62
    P += _plinth(W1, D1, 12)
    P.append(_walls(W1, D1, z1, z2, 1))
    P.append(_walls(W2, D2, z2, z3, 2, rot=1.2))
    jetty = bx((0, 0, z2 + 0.06), (W2 + 0.14, D2 + 0.14, 0.22), (0, 0, 1.2), bevel=0.03)
    setmat(jetty, M("timber", TIMBER))
    P.append(jetty)
    P += [timber((x, y, z1), (x, y, z2), 0.18) for x in (-W1 / 2 - 0.02, W1 / 2 + 0.02) for y in (-D1 / 2 - 0.02, D1 / 2 + 0.02)]
    fr = _frame(W2, D2, z2 + 0.1, z3, 0.17)
    for o in fr:
        o.matrix_world = Matrix.Rotation(math.radians(1.2), 4, 'Z') @ o.matrix_world
    P += fr
    for sx in (-1, 1):
        P += _gable(W2, D2, z3 - 0.02, zr - 0.05, sx * (W2 / 2 + 0.03))
    P += _tile_roof(W2, D2, z3, zr)
    # água-furtada na água da frente, com janela acesa
    dz = z3 + 0.25
    dor = bx((0.55, -D2 / 2 + 0.55, dz + 0.32), (0.85, 0.75, 0.7), bevel=0.03)
    blotch(dor, PLASTER, PLASTER_D, 1.0, 5)
    P.append(dor)
    dr = _tile_roof(0.85, 0.75, dz + 0.65, dz + 1.0, over_x=0.0, over_y=0.12, courses=1, cols=(TILE,), thick=0.13, sag=0.0)
    for o in dr:
        o.matrix_world = Matrix.Translation((0.55, -D2 / 2 + 0.38, 0)) @ Matrix.Rotation(math.radians(90), 4, 'Z') @ o.matrix_world
    P += dr
    P += window(0.55, -D2 / 2 + 0.16, dz + 0.32, -1, 0.42, 0.42)
    # frente (-Y): porta em arco, duas janelas embaixo, duas em cima com floreira
    P += _door(-0.2, -D1 / 2 - 0.05)
    P += window(-1.15, -D1 / 2 - 0.05, 1.08, -1, 0.5, 0.55)
    P += window(0.95, -D1 / 2 - 0.05, 1.08, -1, 0.5, 0.55)
    for x in (-0.95, 1.0):
        P += window(x, -D2 / 2 - 0.06, 2.25, -1, 0.5, 0.52, lit=x < 0, shut=SHUTTER_R)
    P += _flowerbox(-0.95, -D2 / 2 - 0.2, 1.88)
    # trás e lados
    P += window(-0.8, D1 / 2 + 0.05, 1.08, 1, 0.5, 0.55, lit=False)
    P += window(0.6, D2 / 2 + 0.06, 2.25, 1, 0.5, 0.52)
    P += window(W2 / 2 + 0.06, 0.0, 2.25, 1, 0.5, 0.52, rot=90, shut=SHUTTER_R)
    P += window(-W1 / 2 - 0.05, 0.3, 1.08, 1, 0.45, 0.5, lit=True, rot=-90)
    P += _chimney(1.15, 0.55, 2.4, 4.22, 4.0, 31)
    # lenha empilhada no lado
    for k, (yy, zz) in enumerate(((-0.35, 0.2), (0.0, 0.2), (0.35, 0.2), (-0.18, 0.5), (0.18, 0.5))):
        lg = cy((-W1 / 2 - 0.42, yy, zz), 0.17, 0.9, (90, 0, 90), seg=7)
        paint(lg, lambda p, n: mix(TIMBER_L, L((0.86, 0.72, 0.50)), smoothstep(0.6, 0.95, abs(n.x))))
        setmat(lg, V("v_log"))
        P.append(lg)
    return group("house", P)


def tavern():
    """Taverna: dois andares, palha grossa, puxado da cozinha, toldo listrado, placa da caneca, barris e lampiões."""
    P = []
    W1, D1, W2, D2 = 4.2, 2.8, 4.5, 3.2
    z1, z2, z3, zr = 0.34, 1.85, 3.0, 4.55
    P += _plinth(W1, D1, 22)
    P.append(_walls(W1, D1, z1, z2, 11))
    P.append(_walls(W2, D2, z2, z3, 12, rot=-1.0))
    jetty = bx((0, 0, z2 + 0.06), (W2 + 0.14, D2 + 0.14, 0.22), (0, 0, -1.0), bevel=0.03)
    setmat(jetty, M("timber", TIMBER))
    P.append(jetty)
    P += [timber((x, y, z1), (x, y, z2), 0.2) for x in (-W1 / 2 - 0.02, 0.0, W1 / 2 + 0.02) for y in (-D1 / 2 - 0.02, D1 / 2 + 0.02)]
    fr = _frame(W2, D2, z2 + 0.1, z3, 0.18)
    for o in fr:
        o.matrix_world = Matrix.Rotation(math.radians(-1.0), 4, 'Z') @ o.matrix_world
    P += fr
    for sx in (-1, 1):
        P += _gable(W2, D2, z3 - 0.02, zr - 0.1, sx * (W2 / 2 + 0.03))
    P += _tile_roof(W2, D2, z3, zr, over_x=0.4, over_y=0.5, courses=2, cols=(THATCH, THATCH_L), thick=0.36, sag=0.14,
                    name="thatch", bevel=0.12)
    # água-furtada grande na frente (palha), janela acesa
    dz = z3 + 0.2
    dor = bx((0.0, -D2 / 2 + 0.75, dz + 0.45), (1.3, 1.1, 0.95), bevel=0.04)
    blotch(dor, PLASTER, PLASTER_D, 1.0, 15)
    P.append(dor)
    dr = _tile_roof(1.3, 1.1, dz + 0.9, dz + 1.45, over_x=0.0, over_y=0.2, courses=1, cols=(THATCH_L,), thick=0.26, sag=0.0,
                    name="thatch", bevel=0.09)
    for o in dr:
        o.matrix_world = Matrix.Translation((0.0, -D2 / 2 + 0.45, 0)) @ Matrix.Rotation(math.radians(90), 4, 'Z') @ o.matrix_world
    P += dr
    P += window(0.0, -D2 / 2 + 0.18, dz + 0.45, -1, 0.6, 0.5)
    # puxado da cozinha (+X), telhado de uma água em telha
    kx = W1 / 2 + 0.7
    k = bx((kx, 0.25, 0.34 + 0.75), (1.4, 2.0, 1.5), bevel=0.04)
    k = subdiv(k, 1)
    blotch(k, PLASTER_D, PLASTER, 1.0, 13)
    P.append(k)
    kr = bx((kx + 0.1, 0.25, 2.0), (1.85, 2.5, 0.16), (0, -24, 0), bevel=0.04)
    kr = subdiv(kr, 2)
    blotch(kr, TILE, TILE_L, 1.6, 14)
    P.append(kr)
    P += window(kx + 0.71, 0.25, 1.15, 1, 0.45, 0.5, rot=90)
    # frente: porta dupla larga, toldo listrado, janelas acesas
    P += _door(0.0, -D1 / 2 - 0.05, w=1.05, h=1.35)
    for x in (-1.45, 1.45):
        P += window(x, -D1 / 2 - 0.05, 1.15, -1, 0.6, 0.6)
    for x in (-1.45, 0.0, 1.45):
        P += window(x, -D2 / 2 - 0.06, 2.5, -1, 0.5, 0.55, shut=SHUTTER_R)
    P += _flowerbox(-1.45, -D2 / 2 - 0.2, 2.12)
    P += _flowerbox(1.45, -D2 / 2 - 0.2, 2.12)
    for i in range(4):
        st = bx((-0.75 + i * 0.5, -D1 / 2 - 0.55, 2.0), (0.5, 0.95, 0.09), (-22, 0, 0), bevel=0.02)
        setmat(st, M("awn_%d" % (i % 2), RED if i % 2 == 0 else CREAM, 0.85))
        P.append(st)
    for i in range(4):
        fl = bx((-0.75 + i * 0.5, -D1 / 2 - 1.0, 1.72), (0.5, 0.06, 0.24), bevel=0.01)
        setmat(fl, M("awn_%d" % (i % 2), RED if i % 2 == 0 else CREAM, 0.85))
        P.append(fl)
    for sx in (-1, 1):
        P.append(timber((sx * 0.98, -D1 / 2 - 0.98, 0.0), (sx * 0.98, -D1 / 2 - 0.98, 1.85), 0.13))
    # placa da caneca pendurada no canto (-X da frente)
    P.append(timber((-W2 / 2 - 0.1, -D2 / 2 - 0.05, 2.62), (-W2 / 2 - 1.25, -D2 / 2 - 0.05, 2.62), 0.15))
    sg = bx((-W2 / 2 - 0.75, -D2 / 2 - 0.05, 2.05), (1.05, 0.12, 0.85), bevel=0.04)
    setmat(sg, M("sign", L((0.30, 0.20, 0.30)), 0.8))
    P.append(sg)
    sgf = bx((-W2 / 2 - 0.75, -D2 / 2 - 0.05, 2.05), (1.2, 0.09, 1.0), bevel=0.04)
    setmat(sgf, M("gold", GOLD, 0.45))
    P.append(sgf)
    for sy in (-1, 1):
        mug = cy((-W2 / 2 - 0.75, -D2 / 2 - 0.05 + sy * 0.1, 2.0), 0.22, 0.44, (0, 0, 0), seg=8)
        setmat(mug, M("cream", CREAM, 0.6))
        P.append(mug)
        foam = sph((-W2 / 2 - 0.75, -D2 / 2 - 0.05 + sy * 0.1, 2.27), 1, (0.27, 0.2, 0.12), seg=8)
        setmat(foam, M("white", L((0.98, 0.96, 0.92)), 0.7))
        P.append(foam)
    # barris e lampiões
    P += _barrel((1.6, -D1 / 2 - 0.55, 0.36), seed=1)
    P += _barrel((2.25, -D1 / 2 - 0.4, 0.36), seed=2)
    P += _barrel((1.9, -D1 / 2 - 0.5, 1.05), 0.28, 0.62, seed=3)
    P += _barrel((-1.9, -D1 / 2 - 0.65, 0.3), 0.28, 0.75, lying=True, seed=4)
    for sx in (-1, 1):
        lp = bx((sx * 0.98, -D1 / 2 - 0.98, 1.55), (0.24, 0.24, 0.3), bevel=0.03)
        setmat(lp, M("win_lit", WARM, 0.4, emit=5.0))
        P.append(lp)
    P += _chimney(-1.3, 0.75, 2.8, 5.05, -3.0, 41)
    P += window(-0.9, D1 / 2 + 0.05, 1.15, 1, 0.55, 0.6)
    P += window(1.0, D2 / 2 + 0.06, 2.5, 1, 0.5, 0.55, lit=False)
    P += window(-W2 / 2 - 0.06, -0.3, 2.5, 1, 0.5, 0.55, rot=-90)
    return group("tavern", P)


# ------------------------------------------------------------------ covil (montanha de chifres com a bocarra)

def castle():
    """Covil do chefe como no mapa da campanha: montanha de chifres, bocarra de presas acesa por dentro, caveira
    entalhada em cima e duas torres sombrias nos ombros. Frente (-Y) = boca, virada para a estrada."""
    P = []
    r = random.Random(5)
    # massa da montanha: rochedos grandes facetados, mais alta no meio
    for k in range(15):
        t = (k / 14) * 2 - 1
        x = t * 10.5 + r.uniform(-0.6, 0.6)
        hgt = 7.5 * (1 - 0.45 * t * t) + r.uniform(-0.8, 0.8)
        for row, (y, s) in enumerate(((-0.8, 1.0), (2.3, 1.15))):
            sz = (r.uniform(4.0, 5.5) * s, r.uniform(4.2, 5.2), hgt * (0.95 if row == 0 else 1.15))
            o = hull((x + r.uniform(-0.4, 0.4), y + r.uniform(-0.3, 0.3), sz[2] / 2 - 0.4), sz, (0, 0, r.uniform(0, 60)), 200 + k * 2 + row, 14)
            P.append(o)
    rocks = list(P)
    for o in rocks:
        def col(p, n, o=o):
            c = mix(ROCK_D, ROCK, smoothstep(-0.4, 0.6, n.z) * 0.7 + 0.25)
            c = mix(c, ROCK_L, smoothstep(0.55, 0.95, n.z) * 0.6)
            return mix(c, ROCK_D, smoothstep(2.5, 0.0, p.z) * 0.5)
        paint(o, col)
        setmat(o, V("v_rock"))
    # chifres: 7 picos em arco, o do meio mais alto, pontas de osso
    horns = [(-10.0, 0.55, 8.0), (-6.8, 0.8, 11.5), (-3.6, 1.0, 15.0), (0.0, 1.2, 19.8), (3.6, 1.0, 15.5), (6.8, 0.8, 12.0), (10.0, 0.6, 8.5)]
    for i, (x, w, h) in enumerate(horns):
        side = -1 if x < 0 else (1 if x > 0 else 0)
        y = 2.0 + abs(x) * 0.05
        z0 = 4.5 * (1 - 0.45 * (x / 10.5) ** 2)
        o = horn((x, y, z0 - 1.5), 1.55 * w + 0.6, h - z0 + 1.5, lean=(side * 0.22, 0.12), curl=side * 0.6, seg=7, rings=6)
        tip0 = z0 + (h - z0) * 0.55
        paint(o, lambda p, n, tip0=tip0, h=h: mix(mix(ROCK, ROCK_L, smoothstep(-0.3, 0.8, n.x * 0.5 + n.z)),
                                                  mix(BONE_D, BONE, smoothstep(-0.3, 0.6, n.z + n.x * 0.3)), smoothstep(tip0 - 0.8, tip0 + 0.8, p.z)))
        setmat(o, V("v_horn%d" % i))
        P.append(o)
    # bocarra: arco escuro na frente, brilho quente no fundo e presas de osso em cima e embaixo
    mw, mh, my = 7.2, 6.4, -3.2
    mouth = prism([(-mw / 2, 0.0)] + [(-mw / 2 * math.cos(a), mh * 0.55 + mh * 0.45 * math.sin(a)) for a in
                  [k / 8 * math.pi for k in range(9)]] + [(mw / 2, 0.0)], -0.3, 0.3)
    mouth.location = (0, my, 0)
    paint(mouth, lambda p, n: mix(L((0.85, 0.30, 0.55)), MAW, smoothstep(0.3, 2.8, p.z)))
    setmat(mouth, mk.mat("v_maw", vcol=True, rough=0.6, emit=4.0))
    P.append(mouth)
    lip = prism([(-mw / 2 - 1.0, 0.0)] + [(-(mw / 2 + 1.0) * math.cos(a), mh * 0.55 + (mh * 0.45 + 1.0) * math.sin(a)) for a in
                [k / 8 * math.pi for k in range(9)]] + [(mw / 2 + 1.0, 0.0), (mw / 2, 0.0)] +
               [((mw / 2) * math.cos(a), mh * 0.55 + mh * 0.45 * math.sin(a)) for a in [k / 8 * math.pi for k in range(9)]] + [(-mw / 2, 0.0)],
               -0.9, 0.9)
    lip.location = (0, my - 0.4, 0)
    paint(lip, lambda p, n: mix(ROCK, ROCK_L, smoothstep(-0.2, 0.8, n.z + 0.3)))
    setmat(lip, V("v_lip"))
    P.append(lip)
    for k in range(6):
        x = -mw * 0.36 + k * mw * 0.144
        ln = 2.9 - abs(k - 2.5) * 0.35
        top = mh * 0.55 + mh * 0.45 * math.sqrt(max(0.0, 1 - (x / (mw / 2)) ** 2)) - 0.1
        f = horn((x, my - 0.55, top), 0.62, ln, seg=5, rings=3, name="fang")
        f.scale = (1, 1, -1)
        f.location.z = top * 2
        bpy.context.view_layer.update()
        f.data.transform(f.matrix_world)
        f.matrix_world = Matrix.Identity(4)
        f.data.flip_normals()
        paint(f, lambda p, n: mix(BONE_D, BONE, smoothstep(-0.5, 0.7, n.z + n.y * -0.5)))
        setmat(f, V("v_fang"))
        P.append(f)
    for k in range(5):
        x = -mw * 0.3 + k * mw * 0.15
        f = horn((x, my - 0.55, -0.1), 0.58, 2.0 - abs(k - 2) * 0.25, seg=5, rings=3, name="fang")
        paint(f, lambda p, n: mix(BONE_D, BONE, smoothstep(-0.5, 0.7, n.z + n.y * -0.5)))
        setmat(f, V("v_fang"))
        P.append(f)
    # caveira entalhada acima da boca (olhos de uma cor só, acesos, sem pupila)
    sk_z, sk_y = 10.8, -2.6
    head = mk.fuse([sph((0, sk_y, sk_z), 1, (2.9, 1.8, 2.6), seg=14), sph((0, sk_y - 0.3, sk_z - 2.2), 1, (1.9, 1.4, 1.2), seg=12)], "skull", 0.22, 0.5, 3)
    paint(head, lambda p, n: mix(BONE_D, BONE, smoothstep(-0.4, 0.7, n.z * 0.6 - n.y * 0.5)))
    setmat(head, V("v_skull"))
    P.append(head)
    for sx in (-1, 1):
        e = sph((sx * 1.15, sk_y - 1.6, sk_z - 0.3), 1, (0.85, 0.45, 0.75), seg=10)
        setmat(e, M("skull_eye", RUNE, 0.4, emit=6.0))
        P.append(e)
    nose = horn((0, sk_y - 1.75, sk_z - 1.6), 0.42, 0.7, seg=3, rings=2, name="nose")
    setmat(nose, M("maw", MAW, 0.8))
    P.append(nose)
    for k in range(3):
        t = bx(((k - 1) * 0.72, sk_y - 1.6, sk_z - 2.8), (0.55, 0.3, 0.8), bevel=0.06)
        setmat(t, M("bone", BONE, 0.7))
        P.append(t)
    # duas torres sombrias nos ombros, telhado roxo pontudo e janelas acesas
    for sx in (-1, 1):
        tx, ty = sx * 8.6, -0.3
        tw = cy((tx, ty, 6.0), 1.5, 8.0, (0, 0, 0), seg=8, r2=1.25)
        tw = subdiv(tw, 1)
        blotch(tw, ROCK, ROCK_D, 0.6, 50 + sx, up=ROCK_L, k=0.4)
        P.append(tw)
        rim = cy((tx, ty, 10.2), 1.65, 0.6, seg=8)
        setmat(rim, M("rock_l", ROCK_L))
        P.append(rim)
        for k in range(4):
            a = k / 4 * math.tau + math.pi / 4
            m_ = bx((tx + math.cos(a) * 1.45, ty + math.sin(a) * 1.45, 10.85), (0.8, 0.8, 0.8), (0, 0, math.degrees(a)), bevel=0.06)
            setmat(m_, M("rock_l", ROCK_L))
            P.append(m_)
        rf = horn((tx, ty, 10.6), 1.85, 4.6, lean=(sx * 0.12, 0.05), seg=8, rings=3, name="roof")
        paint(rf, lambda p, n: mix(ROOF_P, mix(ROOF_P, L((0.68, 0.42, 0.74)), 0.7), smoothstep(-0.2, 0.8, n.z + n.x * 0.3)))
        setmat(rf, V("v_rooftower"))
        P.append(rf)
        for k, z in enumerate((5.2, 7.8)):
            a = -math.pi / 2 + (k - 0.5) * 0.5
            wdw = bx((tx + math.cos(a) * 1.38, ty + math.sin(a) * 1.38, z), (0.8, 0.4, 1.2), (0, 0, math.degrees(a) + 90), bevel=0.05)
            setmat(wdw, M("win_lit", WARM, 0.4, emit=5.0))
            P.append(wdw)
    # dentes de pedra soltos na frente (pedregulhos em ponta) e pedras na boca do caminho
    for k, (x, y, h) in enumerate(((-6.0, -4.3, 2.6), (6.4, -4.0, 3.0), (-4.6, -5.0, 1.6), (4.8, -5.2, 1.8))):
        s = horn((x, y, -0.2), 0.9, h, lean=(0.1 * (1 if x > 0 else -1), -0.08), seg=5, rings=3, name="spike")
        paint(s, lambda p, n: mix(ROCK_D, ROCK_L, smoothstep(-0.3, 0.8, n.z + n.x * 0.3)))
        setmat(s, V("v_spike"))
        P.append(s)
    # brilho roxo das runas na base dos lados da boca
    for sx in (-1, 1):
        rn = bx((sx * (mw / 2 + 0.55), my - 1.35, 2.2), (0.55, 0.12, 1.6), bevel=0.04)
        setmat(rn, M("rune", RUNE, 0.4, emit=5.0))
        P.append(rn)
    return group("castle", P)


# ------------------------------------------------------------------ arena: pilar, braseiro, altar

def _ring_stone(r, z0, h, seg=8, rot=0.0, seed=0, col=(ASTONE, ASTONE_D)):
    o = cy((0, 0, z0 + h / 2), r, h, (0, 0, rot), seg=seg, bevel=0.05)
    blotch(o, col[0], col[1], 1.6, seed, up=ASTONE_L, k=0.5)
    return o


def pillar():
    """Pilar quebrado: base em dois degraus, fuste de 8 faces em tambores tortos, topo partido em bisel,
    runas acesas e um pedaço caído na base. O raio da base é o do antigo (o jogo o escala 1,1 x 0,75)."""
    P = [_ring_stone(0.72, 0.0, 0.22, 8, 22.5, 1), _ring_stone(0.6, 0.22, 0.2, 8, 0.0, 2)]
    r = random.Random(62)
    z = 0.42
    hs = (1.1, 1.05, 1.0, 0.95)
    for k, h in enumerate(hs):
        d = cy((r.uniform(-0.03, 0.03), r.uniform(-0.03, 0.03), z + h / 2), 0.47 - k * 0.012, h - 0.04,
               (r.uniform(-1.5, 1.5), r.uniform(-1.5, 1.5), k * 11), seg=8, bevel=0.04)
        if k == len(hs) - 1:
            # topo partido: corte inclinado e serrilhado largo (3 dentes)
            for v in d.data.vertices:
                if v.co.z > 0:
                    a = math.atan2(v.co.y, v.co.x)
                    v.co.z -= (0.55 + 0.45 * math.cos(a - 0.6)) * 0.9 + 0.18 * math.sin(a * 3)
        def col(p, n):
            c = mix(ASTONE_D, ASTONE, smoothstep(-0.6, 0.8, n.x * 0.6 + n.y * 0.4) * 0.8 + 0.2)
            c = mix(c, ASTONE_L, smoothstep(0.5, 0.95, n.z) * 0.6)
            return mix(c, MOSS, smoothstep(0.85, 1.0, n.z) * smoothstep(3.4, 4.2, p.z) * 0.7)
        paint(d, col)
        setmat(d, V("v_drum"))
        P.append(d)
        z += h
    # runas acesas: um glifo largo em cada face do segundo tambor, e um anel no terceiro
    for k in range(4):
        a = k / 4 * math.tau + math.pi / 8
        g = bx((math.cos(a) * 0.45, math.sin(a) * 0.45, 2.0), (0.08, 0.26, 0.78), (0, 0, math.degrees(a)), bevel=0.02, taper=(1.0, 0.4))
        setmat(g, M("rune", RUNE, 0.4, emit=5.0))
        P.append(g)
        g2 = bx((math.cos(a) * 0.46, math.sin(a) * 0.46, 2.12), (0.08, 0.46, 0.13), (32, 0, math.degrees(a)), bevel=0.02)   # traço inclinado: runa, não cruz
        setmat(g2, M("rune", RUNE, 0.4, emit=5.0))
        P.append(g2)
    band = cy((0, 0, 3.0), 0.5, 0.26, seg=8)
    setmat(band, M("rune", RUNE, 0.4, emit=5.0))
    P.append(band)
    band = cy((0, 0, 0.98), 0.5, 0.2, seg=8)
    setmat(band, M("rune", RUNE, 0.4, emit=5.0))
    P.append(band)
    # pedaço caído
    # dentro do raio da base (0,72): não alarga a caixa nem desloca a origem
    ch = cy((0.36, -0.42, 0.6), 0.24, 0.42, (62, 10, 40), seg=8, bevel=0.03)
    blotch(ch, ASTONE, ASTONE_D, 2.0, 7, up=MOSS, k=0.5)
    P.append(ch)
    return group("pillar", P)


def brazier():
    """Braseiro de pedra e ferro: pedestal largo, tigela com garras, brasas e três línguas de fogo largas.
    A boca da tigela fica em ~1,6 m (a chama do ArenaLook nasce em +1,7 m)."""
    P = [_ring_stone(0.62, 0.0, 0.22, 8, 22.5, 11), _ring_stone(0.46, 0.22, 0.2, 8, 0.0, 12)]
    col_ = cy((0, 0, 0.82), 0.22, 1.0, seg=8, r2=0.3)
    blotch(col_, ASTONE, ASTONE_D, 2.0, 13)
    P.append(col_)
    bowl = cy((0, 0, 1.42), 0.36, 0.38, seg=10, r2=0.64)
    paint(bowl, lambda p, n: mix(IRON, IRON_L, smoothstep(-0.3, 0.8, n.z + n.x * 0.4)))
    setmat(bowl, V("v_iron"))
    P.append(bowl)
    rim = cy((0, 0, 1.62), 0.7, 0.13, seg=10)
    setmat(rim, M("gold", GOLD, 0.45))
    P.append(rim)
    for k in range(4):
        a = k / 4 * math.tau + math.pi / 4
        cl = tube([(math.cos(a) * 0.62, math.sin(a) * 0.62, 1.55), (math.cos(a) * 0.82, math.sin(a) * 0.82, 1.8),
                   (math.cos(a) * 0.68, math.sin(a) * 0.68, 2.05)], 0.075, 0.35, 4)
        setmat(cl, M("iron", IRON, 0.5))
        P.append(cl)
    coals = sph((0, 0, 1.66), 1, (0.58, 0.58, 0.14), seg=10)
    glow_paint(coals, 1.6, 1.78, L((0.9, 0.25, 0.1)), FIRE, 6.0, "coal")
    P.append(coals)
    for k, (dx, dy, w, h, rz, ln) in enumerate(((0.0, 0.0, 0.34, 0.95, 0.0, 0.1), (0.24, 0.1, 0.22, 0.62, 1.2, 0.12),
                                                 (-0.2, -0.14, 0.22, 0.7, 2.4, -0.12))):
        f = tongue((dx, dy, 1.64 + h * 0.4), w, h, rz, ln)
        glow_paint(f, 1.7, 1.64 + h * 0.85, FIRE, FIRE_L, 8.0, "fire%d" % k)
        P.append(f)
    return group("brazier", P)


def altar():
    """Altar: dais de pedra em dois degraus com anel de runas aceso, mesa de pedra com pano vermelho, caveira de olhos
    acesos (uma cor só) e velas grossas. Altura ~1,8 m (o número fica em 2,2 m)."""
    P = [_ring_stone(1.0, 0.0, 0.24, 8, 22.5, 21), _ring_stone(0.8, 0.24, 0.22, 8, 0.0, 22)]
    ring = mk.torus((0, 0, 0.47), 0.7, 0.11, s=(1, 1, 0.35))
    apply_mods(ring)
    setmat(ring, M("rune", RUNE, 0.4, emit=5.0))
    P.append(ring)
    tb = bx((0, 0, 0.46 + 0.28), (1.15, 0.72, 0.56), bevel=0.05, taper=(1.08, 1.1))
    blotch(tb, ASTONE, ASTONE_D, 2.0, 23, up=ASTONE_L, k=0.4)
    P.append(tb)
    top = bx((0, 0, 1.06), (1.32, 0.86, 0.12), bevel=0.04)
    blotch(top, ASTONE_L, ASTONE, 2.0, 24)
    P.append(top)
    cl = bx((0, 0, 1.13), (0.5, 0.94, 0.05), bevel=0.01)
    setmat(cl, M("cloth", CLOTH, 0.85))
    P.append(cl)
    for sy in (-1, 1):
        h = bx((0, sy * 0.47, 0.86), (0.5, 0.05, 0.5), bevel=0.01)
        setmat(h, M("cloth", CLOTH, 0.85))
        P.append(h)
        hem = bx((0, sy * 0.48, 0.6), (0.5, 0.06, 0.1), bevel=0.01)
        setmat(hem, M("gold", GOLD, 0.45))
        P.append(hem)
    # caveira
    sk = mk.fuse([sph((0, 0.05, 1.38), 1, (0.22, 0.2, 0.2), seg=12), sph((0, -0.03, 1.22), 1, (0.14, 0.13, 0.08), seg=10)], "skull", 0.025, 0.5, 3)
    paint(sk, lambda p, n: mix(BONE_D, BONE, smoothstep(-0.4, 0.7, n.z * 0.7 - n.y * 0.4)))
    setmat(sk, V("v_skull"))
    P.append(sk)
    for sx in (-1, 1):
        e = sph((sx * 0.085, -0.13, 1.36), 1, (0.07, 0.05, 0.065), seg=8)
        setmat(e, M("skull_eye", RUNE, 0.4, emit=6.0))
        P.append(e)
    # velas grossas de alturas diferentes, chama larga
    for k, (x, y, h, r_) in enumerate(((-0.48, -0.22, 0.42, 0.09), (-0.38, 0.22, 0.3, 0.1), (0.46, -0.2, 0.36, 0.1),
                                        (0.5, 0.2, 0.24, 0.09), (-0.9, -0.62, 0.3, 0.1), (0.88, 0.6, 0.34, 0.1))):
        z0 = 1.12 if abs(x) < 0.6 else 0.46
        c = cy((x, y, z0 + h / 2), r_, h, seg=8, r2=r_ * 0.9)
        setmat(c, M("candle", CREAM, 0.6))
        P.append(c)
        f = tongue((x, y, z0 + h + 0.07), 0.07, 0.2, k * 0.7, 0.02)
        glow_paint(f, z0 + h, z0 + h + 0.2, FIRE, FIRE_L, 8.0, "cflame")
        P.append(f)
    return group("altar", P)


BUILD = {"house": house, "tavern": tavern, "castle": castle, "pillar": pillar, "brazier": brazier, "altar": altar}


# ------------------------------------------------------------------ prévia e giro (Blender, atlas aplicado)

def _atlas_mats(objs, png):
    img = bpy.data.images.load(png)
    img.colorspace_settings.name = 'sRGB'
    cache = {}
    for o in objs:
        for i, m in enumerate(o.data.materials):
            info = vat._mat_info(m)
            key = round(info[2], 3)
            if key not in cache:
                nm = bpy.data.materials.new("atlas_%s" % key)
                nm.use_nodes = True
                nt = nm.node_tree
                p = next(n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED')
                tx = nt.nodes.new('ShaderNodeTexImage')
                tx.image = img
                nt.links.new(tx.outputs[0], p.inputs['Base Color'])
                p.inputs['Roughness'].default_value = 0.9
                if info[2] > 0:
                    nt.links.new(tx.outputs[0], p.inputs['Emission Color'])
                    p.inputs['Emission Strength'].default_value = info[2] * 3.0
                cache[key] = nm
            o.data.materials[i] = cache[key]


def _stage(objs):
    sc = bpy.context.scene
    for eng in ('BLENDER_EEVEE_NEXT', 'BLENDER_EEVEE'):
        try:
            sc.render.engine = eng
            break
        except TypeError:
            pass
    sc.render.resolution_x, sc.render.resolution_y = 900, 900
    sc.view_settings.view_transform = 'Standard'
    sc.render.film_transparent = False
    w = bpy.data.worlds.new("W")
    sc.world = w
    w.use_nodes = True
    bg = next(n for n in w.node_tree.nodes if n.type == 'BACKGROUND')
    bg.inputs[0].default_value = (0.62, 0.66, 0.62, 1)
    bg.inputs[1].default_value = 0.9
    sun = bpy.data.lights.new("Sun", 'SUN')
    sun.energy = 3.2
    so = bpy.data.objects.new("Sun", sun)
    sc.collection.objects.link(so)
    so.rotation_euler = (math.radians(40), math.radians(10), math.radians(-30))
    bpy.context.view_layer.update()
    lo = Vector((1e9,) * 3)
    hi = Vector((-1e9,) * 3)
    for o in objs:
        for c in o.bound_box:
            p = o.matrix_world @ Vector(c)
            lo = Vector(map(min, lo, p))
            hi = Vector(map(max, hi, p))
    gd = bpy.data.meshes.new("ground")
    bm = bmesh.new()
    bmesh.ops.create_grid(bm, x_segments=1, y_segments=1, size=(hi - lo).length * 10)
    bm.to_mesh(gd)
    bm.free()
    g = bpy.data.objects.new("ground", gd)
    sc.collection.objects.link(g)
    g.location = (0, 0, lo.z)
    gm = bpy.data.materials.new("gm")
    gm.use_nodes = True
    next(n for n in gm.node_tree.nodes if n.type == 'BSDF_PRINCIPLED').inputs['Base Color'].default_value = (0.32, 0.4, 0.26, 1)
    gd.materials.append(gm)
    cd = bpy.data.cameras.new("C")
    cd.lens = 50
    cam = bpy.data.objects.new("C", cd)
    sc.collection.objects.link(cam)
    sc.camera = cam
    return cam, (lo + hi) / 2, max((hi - lo).length, 0.1)


def _shoot(cam, ctr, rad, az, el, path):
    d = Vector((math.sin(az) * math.cos(el), -math.cos(az) * math.cos(el), math.sin(el)))
    cam.location = ctr + d * rad * 1.45
    cam.rotation_euler = (ctr - cam.location).to_track_quat('-Z', 'Y').to_euler()
    bpy.context.scene.render.filepath = path
    bpy.ops.render.render(write_still=True)


# ------------------------------------------------------------------ exportação

def one(i, out, prev=None, giro=None):
    h, budget, size = PROPS[i]
    bpy.ops.wm.read_factory_settings(use_empty=True)
    mk._MATS.clear()
    root = BUILD[i]()
    objs = vat_g.prepare(root, budget)
    # casa e taverna: as cores da paleta já vêm saturadas (sRGB); a saturação extra do g as deixava berrantes no jogo
    grade = treat.make_grade("scenery", pull=PULL, lift=0.04, sat=SAT_OF.get(i, SAT), gain=GAIN)
    os.makedirs(os.path.join(out, "n"), exist_ok=True)
    d = vat_g.export(root, os.path.join(out, "n", i + ".lbm"), h, objs, grade, None, None, None, recenter=True)
    C, Pp, N, Mk = treat.raster(d, size)
    img = treat.treat("dry", C, Pp, N, d["height"], COOL)
    td = os.path.join(out, "tex", "m2")
    os.makedirs(td, exist_ok=True)
    png = os.path.join(td, i + ".png")
    treat.save_png(img, png)
    print("M2 %s: %d tris, altura %.2f" % (i, len(d["idx"]), d["height"]))
    if prev or giro:
        _atlas_mats(objs, png)
        cam, ctr, rad = _stage(objs)
        if prev:
            os.makedirs(prev, exist_ok=True)
            _shoot(cam, ctr, rad, math.radians(25), math.radians(50), os.path.join(prev, i + "_cima.png"))
            _shoot(cam, ctr, rad, math.radians(200), math.radians(30), os.path.join(prev, i + "_tras.png"))
        if giro:
            os.makedirs(giro, exist_ok=True)
            bpy.context.scene.render.resolution_x = bpy.context.scene.render.resolution_y = 720
            for k in range(12):
                _shoot(cam, ctr, rad, math.radians(k * 30), math.radians(38), os.path.join(giro, "%s_%02d.png" % (i, k)))


def main():
    argv = sys.argv[sys.argv.index("--") + 1:]
    out = os.path.abspath(argv[0])
    ids = argv[1].split(",") if len(argv) > 1 and not argv[1].startswith("--") else list(PROPS)
    prev = next((os.path.abspath(a.split("=", 1)[1]) for a in argv if a.startswith("--prev=")), None)
    giro = next((os.path.abspath(a.split("=", 1)[1]) for a in argv if a.startswith("--giro=")), None)
    for i in ids:
        try:
            one(i, out, prev, giro)
        except Exception:
            print("FALHOU", i)
            traceback.print_exc()


main()
