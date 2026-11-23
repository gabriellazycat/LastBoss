"""Árvores e arbustos "em pinceladas" (22/11/2026): o designer achou as copas de antes com cara de massinha (elipsoides
fundidos por voxel, alisados e reduzidos: superfície lisa, sombra em degradê macio, borda redonda). Aqui a copa é feita
de pinceladas: cada tufo é um miolo escuro facetado coberto por dezenas de placas angulosas (a forma de uma pincelada
de pincel chato, ponta para baixo e para fora), cada placa com UMA cor chapada e UMA normal (a luz do jogo pinta cada
placa por inteiro, em degraus, como o guache das cartas). A silhueta fica serrilhada pelas pontas; o miolo escuro
aparece entre elas como a sombra funda das cartas. O atlas leva, em cada placa, um veio de pincel largo que só clareia.

Estilos (mesmos troncos e silhuetas que ele já aprovou em 21/11, tools/art/blender_arvores/build_arvores.py):
  5  carvalho: "tree" = largo e achatado (3 galhos), "tree_round" = torto e inclinado; e os arbustos "bush" dos 3 atos;
  6  pinheiro: "tree" = pinheiro de saias em agulhas largas, "tree_round" = álamo alto de pinceladas para cima.
Atos: 0 primavera, 1 outono, 2 terra amaldiçoada.

"C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --factory-startup -P tools/art/blender_arvores/build_pinceladas.py -- <saída> --estilo=N [--sheet=<prefixo>]
Depois: bash tools/art/blender_arvores/fazer.sh N <saída>  (vira assets/models/arv<N>/<id>_a<ato>.res + .png).
No jogo: game/art/arvores.gd (--arvores=N)."""
import os, sys, math, random, traceback
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, "..", "blender_v2"))
sys.path.insert(0, os.path.join(HERE, "..", "blender_g"))
import bpy, bmesh
import numpy as np
from mathutils import Vector, noise
import mk
from mk import setmat, paint, mix, smoothstep, group
import vat_g, treat
import build_arvores as ba
from build_arvores import limb, bark, roots, L, PAL

ATLAS = 1024
GRID = 32                    # células de placa por linha do atlas
DAB_V0 = 0.27                # abaixo disso: tronco e miolos (smart project); acima: uma célula por placa
PULL, SAT, GAIN = 0.25, 1.45, 0.6
COOL = (0.30, 0.32, 0.42)
LDIR = Vector((-0.35, -0.55, 0.76)).normalized()   # luz de cima, do lado da câmera (frente = -Y)

# Famílias de cor por ato (sRGB): (escuro, meio, claro). Cada tufo puxa uma família; o outono mistura famílias por placa.
FAM = {
    0: [((0.14, 0.27, 0.19), (0.27, 0.46, 0.25), (0.47, 0.64, 0.31)),
        ((0.16, 0.30, 0.17), (0.34, 0.51, 0.24), (0.54, 0.69, 0.33)),
        ((0.12, 0.25, 0.23), (0.23, 0.42, 0.32), (0.41, 0.59, 0.40))],
    1: [((0.45, 0.20, 0.12), (0.85, 0.45, 0.18), (0.98, 0.73, 0.36)),
        ((0.47, 0.31, 0.12), (0.86, 0.63, 0.24), (0.99, 0.85, 0.48)),
        ((0.40, 0.15, 0.13), (0.73, 0.28, 0.17), (0.92, 0.52, 0.30)),
        ((0.30, 0.31, 0.16), (0.55, 0.54, 0.25), (0.78, 0.73, 0.40))],
    2: [((0.23, 0.18, 0.31), (0.43, 0.33, 0.53), (0.67, 0.57, 0.77)),
        ((0.26, 0.24, 0.31), (0.49, 0.46, 0.57), (0.71, 0.67, 0.79)),
        ((0.28, 0.17, 0.30), (0.52, 0.32, 0.52), (0.74, 0.55, 0.74))],
}


class Atlas:
    """Distribui uma célula do atlas por placa."""
    def __init__(self):
        self.n = 0
        self.rows = int((1.0 - DAB_V0) * GRID)

    def cell(self):
        k = self.n
        self.n += 1
        if k >= GRID * self.rows:
            raise RuntimeError("placas demais para o atlas (%d)" % k)
        cs = 1.0 / GRID
        return (k % GRID) * cs, DAB_V0 + (k // GRID) * cs, cs


class Dabs:
    """Uma malha com todas as placas de uma copa: vértices próprios por placa (cor, normal e UV por vértice)."""
    def __init__(self, atlas, name):
        self.bm = bmesh.new()
        self.atlas = atlas
        self.name = name
        self.attr = []   # por vértice: (uv, normal, cor linear)

    def _v(self, p, uv, n, c):
        self.attr.append((uv, n, c))
        return self.bm.verts.new(p)

    def plate(self, c, t, b, pn, outline, L_, W, col, nrm, bulge=0.05):
        """Placa em leque: contorno (x ao longo de t, de -0,45 a 0,55; y ao longo de b, -0,5 a 0,5), centro levantado."""
        u0, v0, cs = self.atlas.cell()

        def uv(x, y):
            return (u0 + cs * (0.1 + 0.8 * (y + 0.5)), v0 + cs * (0.1 + 0.8 * min(max((x + 0.45), 0.0), 1.0)))
        vs = [self._v(c + t * (x * L_) + b * (y * W), uv(x, y), nrm, col) for x, y in outline]
        ctr = self._v(c + t * (0.03 * L_) + pn * (bulge * L_), uv(0.03, 0.0), nrm, col)
        m = len(vs)
        for k in range(m):
            f = self.bm.faces.new([ctr, vs[k], vs[(k + 1) % m]])
            f.normal_update()
            if f.normal.dot(pn) < 0:
                f.normal_flip()

    def obj(self):
        me = bpy.data.meshes.new(self.name)
        self.bm.verts.index_update()
        self.bm.to_mesh(me)
        self.bm.free()
        o = bpy.data.objects.new(self.name, me)
        bpy.context.scene.collection.objects.link(o)
        uvl = me.uv_layers.new(name="UVMap")
        ca = me.color_attributes.new("Col", 'FLOAT_COLOR', 'POINT')
        for i, (uv, n, c) in enumerate(self.attr):
            ca.data[i].color = (c[0], c[1], c[2], 1.0)
        ln = []
        for poly in me.polygons:
            poly.use_smooth = True
            for li in poly.loop_indices:
                vi = me.loops[li].vertex_index
                uvl.data[li].uv = self.attr[vi][0]
                ln.append(self.attr[vi][1])
        me.normals_split_custom_set(ln)
        setmat(o, ba.V("v_" + self.name))
        o["dabs"] = 1
        return o


LEAF = [(-0.45, 0.0), (-0.32, 0.40), (0.0, 0.50), (0.30, 0.35), (0.55, 0.03), (0.33, -0.31), (0.02, -0.48), (-0.30, -0.41)]


def jitter(outline, rr, a=0.06):
    return [(x + rr.uniform(-a, a), y * rr.uniform(0.85, 1.12) + rr.uniform(-a, a) * 0.5) for x, y in outline]


def step_color(fam, l, rr, top=False):
    """Cor chapada da placa pela luz (3 degraus) com um empurrão aleatório para o degrau vizinho."""
    d, m, li = (L(x) for x in fam)
    if l < 0.08:
        c = mix(d, m, rr.uniform(0.1, 0.35))
    elif l < 0.62:
        c = mix(m, d if rr.random() < 0.5 else li, rr.uniform(0.0, 0.15))
    else:
        c = mix(li, m, rr.uniform(0.2, 0.45))
    if top:
        c = mix(c, L((1.0, 0.96, 0.82)), 0.08)
    j = rr.uniform(-0.035, 0.035)
    return (max(0.0, c[0] * (1 + j)), max(0.0, c[1] * (1 + j * 0.6)), max(0.0, c[2] * (1 - j)))


def fib_dirs(n, rr):
    out = []
    ga = math.pi * (3 - math.sqrt(5))
    off = rr.uniform(0, math.tau)
    for i in range(n):
        z = 1 - (i + 0.5) / n * 2
        r = math.sqrt(max(0.0, 1 - z * z))
        a = i * ga + off
        out.append(Vector((math.cos(a) * r, math.sin(a) * r, z)))
    return out


def clump(D, cen, rad, fams, rr, dab=0.6, density=1.0, tip="down", keep_bottom=0.25, mixp=0.0, all_fams=None):
    """Tufo: placas sobre o elipsoide (centro, raios). dab = comprimento da placa / raio médio."""
    cen, rad = Vector(cen), Vector(rad)
    rm = (rad.x + rad.y + rad.z) / 3
    Ld = dab * rm
    area = 4 * math.pi * ((rad.x * rad.y) ** 1.6 + (rad.x * rad.z) ** 1.6 + (rad.y * rad.z) ** 1.6) ** (1 / 1.6) / 3 ** (1 / 1.6)
    n = max(8, int(area / (Ld * Ld * 0.42) * density))
    fam = fams
    zt = None
    for d in fib_dirs(n, rr):
        if d.z < -0.55 and rr.random() > keep_bottom:
            continue
        d = (d + Vector((rr.uniform(-1, 1), rr.uniform(-1, 1), rr.uniform(-1, 1))) * 0.12).normalized()
        p = cen + Vector((d.x * rad.x, d.y * rad.y, d.z * rad.z)) * 1.0
        nd = Vector((d.x / rad.x, d.y / rad.y, d.z / rad.z)).normalized()
        want = Vector((0, 0, -1)) if tip == "down" else Vector((0, 0, 1))
        t = want - nd * want.dot(nd)
        if t.length < 0.25:
            a = rr.uniform(0, math.tau)
            t = Vector((math.cos(a), math.sin(a), 0))
            t = t - nd * t.dot(nd)
        t.normalize()
        # um giro pequeno em volta da normal: as pontas não ficam alinhadas
        ang = rr.uniform(-0.45, 0.45)
        b0 = nd.cross(t).normalized()
        t = (t * math.cos(ang) + b0 * math.sin(ang)).normalized()
        b = nd.cross(t).normalized()
        t2 = (t + nd * 0.22).normalized()           # a ponta levanta para fora: silhueta serrilhada
        pn = b.cross(t2).normalized()
        if pn.dot(nd) < 0:
            pn = -pn
        s = rr.uniform(0.85, 1.18)
        nrm = (nd * 0.8 + pn * 0.2).normalized()
        f = fam
        if mixp and all_fams and rr.random() < mixp:
            f = rr.choice(all_fams)
        col = step_color(f, nrm.dot(LDIR), rr, top=nd.z > 0.8 and rr.random() < 0.5)
        D.plate(p, t2, b, pn, jitter(LEAF, rr), Ld * s, Ld * 0.78 * s, col, nrm)


def core(cen, rad, fam, rr, name="core", shrink=0.74):
    """Miolo escuro facetado do tufo (aparece entre as placas como a sombra funda)."""
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=1, radius=1.0)
    for v in bm.verts:
        k = 1 + noise.noise(v.co * 1.7 + Vector((rr.random() * 9, 0, 0))) * 0.12
        v.co = Vector((v.co.x * rad[0], v.co.y * rad[1], v.co.z * rad[2])) * shrink * k + Vector(cen)
    o = ba._new_obj(bm, name)
    mk.shade(o, True)
    d = L(fam[0])
    m = L(fam[1])

    def f(p, n):
        return mix(mix(d, m, 0.25), d, smoothstep(0.3, -0.6, n.z) * 0.6)
    paint(o, f)
    setmat(o, ba.V("v_" + name))
    return o


def crown(masses, act, rr, A, name="crown", **kw):
    """Copa de tufos: masses = [(centro, raios, família)]; devolve [placas, miolos...]."""
    fams = FAM[act]
    D = Dabs(A, name)
    parts = []
    for k, (c, s, fi) in enumerate(masses):
        fam = fams[fi % len(fams)]
        parts.append(core(c, s, fam, rr, name="core%d" % k))
        clump(D, c, s, fam, rr, all_fams=fams, **kw)
    parts.append(D.obj())
    return parts


# ------------------------------------------------------------------ estilo 5: carvalhos e arbustos

def oak(act, P, tr, rr_, br, ms, ms1, ms2, name, seed):
    rr = random.Random(seed + act * 101)
    A = Atlas()
    msx = {0: ms, 1: ms1, 2: ms2}[act]
    T = [limb(tr, rr_, seg=7, flare=0.35, lobes=4, tip=True, name="trunk")]
    T += roots(4, rr_[0], 0.45, seed=seed, rot=0.7)
    split = Vector(tr[-2])
    for k, (mid, end, r) in enumerate(br):
        T.append(limb([split, Vector(mid), Vector(end)], [r, r * 0.75, r * 0.55], seg=6, tip=True, name="br%d" % k))
        if act == 2 and not any((Vector(c) - Vector(end)).length < 0.9 for c, _, _ in msx):
            e, m = Vector(end), Vector(mid)
            d = (e - m).normalized()
            side = Vector((-d.y, d.x, 0)).normalized()
            for sgn in (1, -1):
                T.append(limb([e - d * 0.25, e + side * 0.45 * sgn + d * 0.3 + Vector((0, 0, 0.45))], [r * 0.5, r * 0.32], seg=5, name="fk"))
    for t in T:
        bark(t, P, seed)
    kw = {0: {}, 1: {"density": 0.85, "mixp": 0.3}, 2: {"density": 0.8, "dab": 0.62}}[act]
    return group(name, T + crown(msx, act, rr, A, **kw))


OAK_T = dict(tr=[(0, 0, -0.08), (0.25, 0.05, 0.7), (0.0, 0.1, 1.35), (0.15, 0.05, 1.75)], rr_=[0.46, 0.38, 0.34, 0.3],
             br=[((0.95, 0.25, 2.3), (1.75, 0.35, 2.85), 0.24), ((-0.75, 0.45, 2.4), (-1.65, 0.55, 2.9), 0.23),
                 ((0.2, -0.75, 2.45), (0.15, -1.5, 3.05), 0.22)],
             ms=[((1.65, 0.35, 3.3), (1.3, 1.15, 0.8), 0), ((-1.55, 0.6, 3.35), (1.25, 1.15, 0.8), 1),
                 ((0.15, -1.35, 3.45), (1.2, 1.0, 0.75), 2), ((0.1, 0.35, 3.85), (1.3, 1.25, 0.85), 1),
                 ((0.75, 1.25, 3.45), (0.95, 0.85, 0.65), 2)],
             ms1=[((1.65, 0.35, 3.3), (1.15, 1.05, 0.72), 0), ((-1.55, 0.6, 3.35), (1.12, 1.05, 0.72), 1),
                  ((0.15, -1.35, 3.45), (1.08, 0.92, 0.68), 2), ((0.1, 0.35, 3.8), (1.18, 1.12, 0.75), 3)],
             ms2=[((-1.7, 0.65, 3.4), (0.78, 0.68, 0.5), 0), ((-1.2, 0.95, 3.25), (0.52, 0.48, 0.4), 1),
                  ((1.75, 0.45, 3.3), (0.62, 0.58, 0.45), 2), ((2.05, 0.15, 3.2), (0.42, 0.4, 0.34), 0)],
             name="tree", seed=20)

OAK_R = dict(tr=[(0, 0, -0.08), (-0.2, 0.0, 0.7), (0.15, 0.05, 1.3), (0.45, 0.0, 1.85)], rr_=[0.44, 0.36, 0.32, 0.28],
             br=[((1.25, 0.15, 2.55), (1.45, 0.25, 3.25), 0.23), ((-0.1, 0.35, 2.75), (-0.75, 0.45, 3.4), 0.22)],
             ms=[((1.25, 0.2, 3.55), (1.3, 1.25, 1.0), 0), ((-0.75, 0.35, 3.75), (1.2, 1.15, 0.95), 2),
                 ((0.3, -0.25, 4.3), (1.05, 1.0, 0.8), 1)],
             ms1=[((1.25, 0.2, 3.5), (1.12, 1.05, 0.88), 0), ((-0.75, 0.35, 3.7), (1.05, 1.0, 0.82), 2),
                  ((0.35, -0.3, 4.15), (0.88, 0.82, 0.66), 1)],
             ms2=[((1.6, 0.3, 3.6), (0.82, 0.72, 0.52), 0), ((1.95, 0.0, 3.45), (0.52, 0.48, 0.4), 1)],
             name="tree_round", seed=30)


def bush(act, P):
    rr = random.Random(77 + act * 13)
    A = Atlas()
    ms = [((0.0, 0.05, 0.7), (0.66, 0.62, 0.62), 0), ((0.45, 0.25, 0.5), (0.46, 0.44, 0.44), 1),
          ((-0.42, -0.2, 0.48), (0.48, 0.46, 0.44), 2)]
    parts = []
    kw = {"dab": 0.62, "keep_bottom": 0.0}
    if act == 1:
        kw.update(mixp=0.35)
    if act == 2:
        # arbusto ralo: tufos menores, dois galhos secos espetados
        ms = [((0.05, 0.05, 0.6), (0.6, 0.56, 0.52), 0), ((0.45, 0.3, 0.45), (0.4, 0.38, 0.36), 1)]
        for k, (a, e) in enumerate((((-0.1, 0.0, 0.3), (-0.8, -0.25, 1.45)), ((0.2, -0.1, 0.3), (0.4, -0.6, 1.35)), ((0.1, 0.2, 0.3), (0.2, 0.75, 1.3)))):
            g = limb([Vector(a), (Vector(a) + Vector(e)) * 0.5 + Vector((0.08, 0, 0.05)), Vector(e)], [0.1, 0.075, 0.05], seg=5, name="tw%d" % k)
            bark(g, P, 5)
            parts.append(g)
        kw.update(density=0.9)
    return group("bush", parts + crown(ms, act, rr, A, name="bush", **kw))


# ------------------------------------------------------------------ estilo 6: pinheiro e álamo

def needles(D, apex, R, h, fam, rr, n=None, skip=0.0, droop=0.25, inner=True):
    """Saia do pinheiro: agulhas largas (pinceladas compridas) que saem do tronco, caem e terminam em ponta."""
    ax, ay, az = apex
    n = n or int(9 + R * 6)
    rings = [(0.0, 1.0, 0.0)] + ([(0.5, 0.78, 0.14)] if inner else [])
    for off, rs, dz in rings:
        for k in range(n):
            if rr.random() < skip:
                continue
            a = (k + off + rr.uniform(-0.18, 0.18)) / n * math.tau
            d = Vector((math.cos(a), math.sin(a), 0))
            r = R * rs * rr.uniform(0.88, 1.08)
            s = Vector((ax, ay, az - h * 0.12 + dz * h)) + d * 0.12
            e = Vector((ax, ay, az + dz * h)) + d * r + Vector((0, 0, -h * (0.82 + droop * rr.uniform(0.2, 1.0))))
            t = (e - s)
            Lb = t.length
            t.normalize()
            b = Vector((-d.y, d.x, 0))
            pn = t.cross(b) if t.cross(b).z > 0 else b.cross(t)
            pn.normalize()
            W = max(0.35, 2 * math.pi * r / n * 1.25)
            outline = [(-0.45, 0.22), (-0.1, 0.46), (0.3, 0.34), (0.55, 0.0), (0.3, -0.34), (-0.1, -0.46), (-0.45, -0.22)]
            nrm = (pn * 0.7 + d * 0.3).normalized()
            col = step_color(fam, nrm.dot(LDIR), rr, top=dz > 0 and rr.random() < 0.3)
            ctr = s + t * (Lb * 0.45)
            D.plate(ctr, t, b, pn, jitter(outline, rr, 0.04), Lb, W, col, nrm, bulge=0.03)


def cone_core(apex, R, h, fam, name):
    ax, ay, az = apex
    bm = bmesh.new()
    top = bm.verts.new((ax, ay, az - h * 0.05))
    ring = [bm.verts.new((ax + math.cos(k / 10 * math.tau) * R, ay + math.sin(k / 10 * math.tau) * R, az - h * 0.85)) for k in range(10)]
    bot = bm.verts.new((ax, ay, az - h * 0.95))
    for k in range(10):
        bm.faces.new([top, ring[k], ring[(k + 1) % 10]])
        bm.faces.new([bot, ring[(k + 1) % 10], ring[k]])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    o = ba._new_obj(bm, name)
    mk.shade(o, True)
    d = L(fam[0])
    paint(o, lambda p, n: mix(d, L(fam[1]), 0.15))
    setmat(o, ba.V("v_" + name))
    return o


def pine(act, P):
    rr = random.Random(50 + act * 7)
    A = Atlas()
    fams = FAM[act]
    T = [limb([(0, 0, -0.08), (0, 0, 1.2), (0, 0, 2.6), (0.0, 0, 4.3)], [0.30, 0.25, 0.19, 0.12], seg=6, flare=0.3, lobes=3, tip=True, name="trunk")]
    D = Dabs(A, "needles")
    cores = []
    if act == 0:
        tiers = [((0, 0, 2.55), 2.0, 1.55, 0), ((0, 0, 3.45), 1.6, 1.25, 1), ((0, 0, 4.3), 1.18, 1.05, 0), ((0, 0, 5.1), 0.72, 0.95, 2)]
        kw = {}
    elif act == 1:
        tiers = [((0, 0, 2.5), 1.9, 1.3, 1), ((0, 0, 3.6), 1.45, 1.1, 0), ((0, 0, 4.75), 0.95, 1.05, 1)]
        kw = {"skip": 0.12, "droop": 0.32}
        T.append(limb([(0, 0, 1.0), (0.55, -0.3, 1.25), (0.85, -0.45, 1.25)], [0.12, 0.09, 0.07], seg=5, name="stub"))
    else:
        tiers = [((0, 0, 3.0), 1.65, 1.35, 0), ((0, 0, 3.95), 1.25, 1.15, 1), ((0, 0, 4.75), 0.8, 0.95, 2)]
        kw = {"skip": 0.35, "droop": 0.5, "inner": False}
        T.append(limb([(0, 0, 1.2), (0.6, 0.2, 1.65), (1.0, 0.35, 2.2)], [0.13, 0.1, 0.08], seg=5, name="stub1"))
        T.append(limb([(0, 0, 1.0), (-0.55, -0.35, 1.3), (-1.0, -0.5, 1.6)], [0.13, 0.1, 0.08], seg=5, name="stub2"))
        T.append(limb([(0, 0, 4.5), (0.08, 0.05, 4.95), (0.2, 0.0, 5.25)], [0.12, 0.09, 0.07], seg=5, name="spike"))
    for i, (ap, R, h, fi) in enumerate(tiers):
        fam = fams[fi % len(fams)]
        needles(D, ap, R, h, fam, rr, **kw)
        cores.append(cone_core(ap, R * 0.62, h, fam, "cc%d" % i))
    for t in T:
        bark(t, P, 3)
    return group("tree", T + cores + [D.obj()])


def poplar(act, P):
    rr = random.Random(60 + act * 5)
    A = Atlas()
    T = [limb([(0, 0, -0.08), (0, 0, 0.9), (0.0, 0, 2.2)], [0.30, 0.25, 0.2], seg=6, flare=0.35, lobes=4, tip=True, name="trunk")]
    if act == 2:
        T.append(limb([(0, 0, 1.6), (0.55, 0.1, 2.5), (0.9, 0.15, 3.3), (0.95, 0.1, 3.9)], [0.2, 0.16, 0.12, 0.09], seg=6, name="b1"))
        T.append(limb([(0, 0, 1.6), (-0.5, -0.1, 2.4), (-0.75, -0.15, 3.4), (-0.7, -0.05, 5.0)], [0.2, 0.16, 0.12, 0.09], seg=6, name="b2"))
        T.append(limb([(-0.73, -0.13, 3.9), (-1.15, -0.2, 4.35)], [0.1, 0.08], seg=5, name="b3"))
        ms = [((1.0, 0.12, 3.45), (0.58, 0.55, 1.05), 0), ((-0.78, -0.12, 2.9), (0.5, 0.48, 0.75), 2)]
        kw = {"density": 0.85}
    else:
        ms = [((0, 0, 3.2), (1.05, 1.0, 1.95), 0), ((0.62, 0.2, 2.35), (0.72, 0.66, 0.85), 1),
              ((-0.58, -0.3, 2.65), (0.7, 0.66, 0.9), 2), ((0.1, -0.05, 4.5), (0.62, 0.6, 0.75), 1)]
        kw = {"mixp": 0.3, "density": 0.9} if act == 1 else {}
    for t in T:
        bark(t, P, 4)
    return group("tree_round", T + crown(ms, act, rr, A, dab=0.66, **kw))


STYLES = {
    5: [("tree", lambda a, P: oak(a, P, **OAK_T)), ("tree_round", lambda a, P: oak(a, P, **OAK_R)), ("bush", bush)],
    6: [("tree", pine), ("tree_round", poplar)],
}


# ------------------------------------------------------------------ exportação

def prepare(root):
    objs = [o for o in ba.vat.descendants(root) if o.type == 'MESH']
    rest = [o for o in objs if not o.get("dabs")]
    for o in objs:
        mk.apply_mods(o)
    for x in bpy.context.selected_objects:
        x.select_set(False)
    for o in rest:
        o.select_set(True)
        if not o.data.uv_layers:
            o.data.uv_layers.new(name="UVMap")
    bpy.context.view_layer.objects.active = rest[0]
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=0.02)
    bpy.ops.uv.pack_islands(margin=0.02)
    bpy.ops.object.mode_set(mode='OBJECT')
    for o in rest:   # tronco e miolos na faixa de baixo do atlas
        for d in o.data.uv_layers.active.data:
            d.uv = (d.uv[0], d.uv[1] * (DAB_V0 - 0.01))
    return objs


def strokes(img, C, Mk):
    """Veio de pincel largo nas placas (só clareia): listras ao longo da placa, tinta carregada na base."""
    S = img.shape[0]
    y0 = int(DAB_V0 * S)
    cs = S / GRID
    yy, xx = np.mgrid[y0:S, 0:S].astype(np.float64) + 0.5
    lu, lv = (xx / cs) % 1.0, (yy / cs) % 1.0
    cid = np.floor(xx / cs) + np.floor(yy / cs) * 37.0
    q = np.stack([lu * 6.5 + cid * 1.37, lv * 1.1 + cid * 0.71, cid * 0.13], axis=-1)
    s = treat.fbm(q, 41, 2)
    up = np.clip((s - 0.48) / 0.4, 0, 1) * 0.16 - np.clip((0.42 - s) / 0.42, 0, 1) * 0.04
    load = treat.ss(0.45, 0.1, lv) * 0.05
    out = img.copy()
    out[y0:] = np.clip(C[y0:] * (1 + up + load)[..., None], 0, 1)
    return out


def one(style, idx, act, out):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    mk._MATS.clear()
    root = dict(STYLES[style])[idx](act, PAL[act])
    objs = prepare(root)
    grade = treat.make_grade("scenery", pull=PULL, lift=0.04, sat=SAT, gain=GAIN)
    os.makedirs(os.path.join(out, "n"), exist_ok=True)
    name = "%s_a%d" % (idx, act)
    d = vat_g.export(root, os.path.join(out, "n", name + ".lbm"), None, objs, grade, None, None, None, recenter=False)
    C, Pp, N, Mk = treat.raster(d, ATLAS)
    img = treat.treat("dry", C, Pp, N, d["height"], COOL)
    img = strokes(img, C, Mk)
    td = os.path.join(out, "tex", "m2")
    os.makedirs(td, exist_ok=True)
    treat.save_png(img, os.path.join(td, name + ".png"))
    pos = d["pos"]
    w = max(pos[:, 0].max() - pos[:, 0].min(), pos[:, 2].max() - pos[:, 2].min())
    r = (name, len(d["idx"]), float(d["height"]), float(w))
    print("ARV %s %d tris %.2f m alt %.2f m larg" % r)
    return r


def main():
    argv = sys.argv[sys.argv.index("--") + 1:]
    out = os.path.abspath(argv[0])
    style = int(next(a.split("=", 1)[1] for a in argv if a.startswith("--estilo=")))
    sh = next((os.path.abspath(a.split("=", 1)[1]) for a in argv if a.startswith("--sheet=")), None)
    only = next((a.split("=", 1)[1] for a in argv if a.startswith("--so=")), None)
    names, rep = [], []
    for idx, _ in STYLES[style]:
        if only and idx != only:
            continue
        for act in (0, 1, 2):
            try:
                r = one(style, idx, act, out)
                names.append(r[0])
                rep.append(r)
            except Exception:
                print("FALHOU", idx, act)
                traceback.print_exc()
    with open(os.path.join(out, "relatorio_estilo%d.txt" % style), "w") as f:
        for r in rep:
            f.write("%s\t%d tris\t%.2f m alt\t%.2f m larg\n" % r)
    if sh:
        os.makedirs(os.path.dirname(sh), exist_ok=True)
        for k in range(0, len(names), 6):
            ba.sheet(out, names[k:k + 6], "%s_%d.png" % (sh, k // 6), style)


if __name__ == "__main__":
    main()
