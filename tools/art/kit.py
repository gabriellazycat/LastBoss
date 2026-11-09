"""Construtor de modelos para o Blender (rodado sem janela por build_models.py).

Coordenadas no padrão da Godot: +Y para cima, frente = -Z, chão em y = 0.
Cada modelo é feito de:
  - blobs: elementos de metaball que se fundem (corpos orgânicos lisos);
  - hard: peças rígidas (caixas, cilindros, cones, esferas, toros) com chanfro;
  - paint: volumes que pintam a cor dos vértices por dentro (barriga, listras, manchas).
Depois o kit calcula a oclusão de ambiente por raios, o gradiente de luz de cima, as bordas
(curvatura) e grava um binário simples que tools/art/import_models.gd converte em ArrayMesh.

Cor com alfa < 1 = parte emissiva (olhos, cristais, fogo), igual ao jogo.
UV2 = (rugosidade, metal) por vértice.
"""
import math
import struct

import bmesh
import bpy
import numpy as np
from mathutils import Euler, Matrix, Vector
from mathutils.bvhtree import BVHTree

THR = 0.6
STIFF = 6.0  # rigidez padrão: funde com um filete suave sem inflar muito onde as peças se encostam


def ksurf(stiff):
    """Raio da superfície / raio de influência do elemento (campo s*(1-d²/r²)³ = limiar)."""
    return math.sqrt(1.0 - (THR / stiff) ** (1.0 / 3.0))


def col(c, a=1.0):
    if len(c) == 4:
        return tuple(c)
    return (c[0], c[1], c[2], a)


def mix(a, b, t):
    n = min(len(a), len(b))
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(n)) + tuple(a[n:])


def lighten(c, t):
    return mix(c[:3], (1, 1, 1), t) + tuple(c[3:])


def darken(c, t):
    return tuple(x * (1 - t) for x in c[:3]) + tuple(c[3:])


def glow(c):
    return (c[0], c[1], c[2], 0.0)


def _rot(rot):
    return Euler(tuple(math.radians(a) for a in rot), 'XYZ').to_matrix()


class Model:
    def __init__(self, name, res=0.03, smooth_blend=1.0):
        self.name = name
        self.res = res
        self.blend = smooth_blend
        self.blobs = []   # (grupo, dict)
        self.hards = []
        self.paints = []
        self.style = {}
        self.blob_budget = 2500  # triângulos para todos os blobs, divididos entre os grupos
        self.detail = 1.0        # fator dos segmentos das peças rígidas

    # -------------------------------------------------- elementos
    def ball(self, pos, r, c, group="body", stiff=STIFF, neg=False, rough=0.75, metal=0.0):
        """Esfera com raio de superfície r (quando isolada)."""
        self.blobs.append((group, dict(kind="BALL", pos=pos, r=r, c=col(c), stiff=stiff, neg=neg, size=(1, 1, 1), rot=(0, 0, 0), rough=rough, metal=metal)))
        return self

    def ell(self, pos, radii, c, rot=(0, 0, 0), group="body", stiff=STIFF, neg=False, rough=0.75, metal=0.0):
        """Elipsoide com semi-eixos radii (x, y, z) locais, girado por rot (graus, XYZ)."""
        self.blobs.append((group, dict(kind="ELLIPSOID", pos=pos, r=1.0, c=col(c), stiff=stiff, neg=neg, size=tuple(radii), rot=rot, rough=rough, metal=metal)))
        return self

    def limb(self, a, b, r, c, group="body", stiff=STIFF, r2=None, rough=0.75, metal=0.0, steps=None):
        """Membro de a até b. Com r2, afina (cadeia de esferas); sem r2, cápsula."""
        a = Vector(a)
        b = Vector(b)
        if r2 is None:
            d = b - a
            mid = (a + b) * 0.5
            L = d.length
            q = Vector((1, 0, 0)).rotation_difference(d.normalized()) if L > 1e-6 else Matrix.Identity(3).to_quaternion()
            e = q.to_euler('XYZ')
            self.blobs.append((group, dict(kind="CAPSULE", pos=tuple(mid), r=r, c=col(c), stiff=stiff, neg=False, size=(L * 0.5, 1, 1), rot=tuple(math.degrees(x) for x in e), rough=rough, metal=metal)))
        else:
            # Afinando: cápsulas em sequência (só se tocam nas juntas, então quase não inflam).
            n = steps or 3
            for i in range(n):
                t0, t1 = i / n, (i + 1) / n
                self.limb(tuple(a.lerp(b, t0)), tuple(a.lerp(b, t1)), r + (r2 - r) * (t0 + t1) * 0.5, c, group, stiff, rough=rough, metal=metal)
        return self

    def hard(self, prim, pos, size, c, rot=(0, 0, 0), bevel=0.02, rough=0.6, metal=0.0, seg=16, smooth=True):
        """Peça rígida. prim: box (size=x,y,z), cyl (size=r_top,r_bottom,h), cone (r,h),
        sphere (r ou rx,ry,rz), torus (R, r), spike (r, h) = cone fino curvo, blade (largura, espessura, comprimento)."""
        self.hards.append(dict(prim=prim, pos=pos, size=size, c=col(c), rot=rot, bevel=bevel, rough=rough, metal=metal, seg=seg, smooth=smooth))
        return self

    def paint(self, pos, radii, c, rot=(0, 0, 0), soft=0.5, only=None):
        """Pinta os vértices dentro do elipsoide (borda suave). only = grupo de blobs."""
        if not isinstance(radii, (tuple, list)):
            radii = (radii, radii, radii)
        self.paints.append(dict(pos=pos, radii=radii, c=col(c), rot=rot, soft=soft, only=only))
        return self

    def mirror(self, fn):
        """Chama fn(sx) para sx em -1 e +1 (peças pares)."""
        for sx in (-1.0, 1.0):
            fn(sx)
        return self

    # -------------------------------------------------- geometria
    def _blob_meshes(self):
        groups = {}
        for g, b in self.blobs:
            groups.setdefault(g, []).append(b)
        out = []
        for g, els in groups.items():
            mb = bpy.data.metaballs.new("mb_" + g)
            mb.resolution = self.res
            mb.render_resolution = self.res
            mb.threshold = THR
            ob = bpy.data.objects.new("MB" + g.replace("_", "") + "x", mb)
            bpy.context.scene.collection.objects.link(ob)
            for b in els:
                e = mb.elements.new(type=b["kind"])
                e.co = b["pos"]
                e.stiffness = b["stiff"]
                e.use_negative = b["neg"]
                if b["kind"] == "BALL":
                    e.radius = b["r"] / ksurf(b["stiff"])
                elif b["kind"] == "ELLIPSOID":
                    e.radius = 1.0 / ksurf(b["stiff"])
                    e.size_x, e.size_y, e.size_z = b["size"]
                else:  # CAPSULE
                    e.radius = b["r"] / ksurf(b["stiff"])
                    e.size_x = b["size"][0]
                e.rotation = Euler(tuple(math.radians(a) for a in b["rot"]), 'XYZ').to_quaternion()
            bpy.context.view_layer.update()
            dg = bpy.context.evaluated_depsgraph_get()
            me = bpy.data.meshes.new_from_object(ob.evaluated_get(dg))
            bpy.data.objects.remove(ob)
            if len(me.vertices) == 0:
                continue
            out.append((g, me, els))
        # Orçamento total dividido pelo tamanho de cada grupo (grupos pequenos não ficam com malha demais).
        raw = []
        for g, me, els in out:
            me.calc_loop_triangles()
            raw.append(len(me.loop_triangles))
        tot = max(1, sum(raw))
        return [(g, self._decimate(me, max(80, int(self.blob_budget * n / tot))), els) for (g, me, els), n in zip(out, raw)]

    def _decimate(self, me, tris):
        """Reduz para ~tris triângulos (colapso de arestas), mantendo a malha lisa."""
        me.calc_loop_triangles()
        n = len(me.loop_triangles)
        if n <= tris:
            for p in me.polygons:
                p.use_smooth = True
            return me
        ob = bpy.data.objects.new("dec", me)
        bpy.context.scene.collection.objects.link(ob)
        m = ob.modifiers.new("d", 'DECIMATE')
        m.ratio = tris / n
        m.use_collapse_triangulate = True
        bpy.context.view_layer.update()
        dg = bpy.context.evaluated_depsgraph_get()
        me2 = bpy.data.meshes.new_from_object(ob.evaluated_get(dg))
        bpy.data.objects.remove(ob)
        bpy.data.meshes.remove(me)
        for p in me2.polygons:
            p.use_smooth = True
        return me2

    def _hard_mesh(self, h):
        bm = bmesh.new()
        p = h["prim"]
        s = h["size"]
        seg = max(6, int(round(h["seg"] * self.detail)))
        if p == "box":
            bmesh.ops.create_cube(bm, size=1.0)
            bmesh.ops.scale(bm, vec=Vector(s), verts=bm.verts)
        elif p in ("cyl", "cone"):
            if p == "cone":
                s = (0.0, s[0], s[1])
            # Eixo do cone/cilindro da Blender é Z; aqui é Y.
            bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=seg, radius1=s[1], radius2=max(s[0], 0.0), depth=s[2])
            bmesh.ops.rotate(bm, cent=(0, 0, 0), matrix=Matrix.Rotation(math.radians(-90), 3, 'X'), verts=bm.verts)
        elif p == "sphere":
            bmesh.ops.create_uvsphere(bm, u_segments=seg, v_segments=max(6, seg // 2), radius=1.0)
            rr = s if isinstance(s, (tuple, list)) else (s, s, s)
            bmesh.ops.scale(bm, vec=Vector(rr), verts=bm.verts)
        elif p == "torus":
            R, r = s
            ring = max(6, seg // 2)
            verts = []
            for i in range(seg):
                a = 2 * math.pi * i / seg
                row = []
                for j in range(ring):
                    b = 2 * math.pi * j / ring
                    row.append(bm.verts.new(((R + r * math.cos(b)) * math.cos(a), r * math.sin(b), (R + r * math.cos(b)) * math.sin(a))))
                verts.append(row)
            for i in range(seg):
                for j in range(ring):
                    bm.faces.new((verts[i][j], verts[(i + 1) % seg][j], verts[(i + 1) % seg][(j + 1) % ring], verts[i][(j + 1) % ring]))
        elif p == "spike":
            # Cone curvado (chifre, garra, espinho): r na base, comprimento h, curva no último valor.
            r, hh = s[0], s[1]
            bend = s[2] if len(s) > 2 else 0.0
            rings = 6
            prev = None
            first = None
            for i in range(rings + 1):
                t = i / rings
                rr = r * (1 - t) ** 0.9
                cy = hh * t
                cz = bend * hh * t * t
                row = []
                for j in range(seg):
                    a = 2 * math.pi * j / seg
                    row.append(bm.verts.new((math.cos(a) * max(rr, 0.0005), cy, cz + math.sin(a) * max(rr, 0.0005))))
                if prev:
                    for j in range(seg):
                        bm.faces.new((prev[j], prev[(j + 1) % seg], row[(j + 1) % seg], row[j]))
                else:
                    first = row
                prev = row
            bm.faces.new(list(reversed(first)))
        elif p == "blade":
            w, t, L = s
            # Lâmina com gume: losango no corte, ponta afilada.
            pts = []
            n = 8
            rows = []
            for i in range(n + 1):
                u = i / n
                ww = w * (1.0 if u < 0.8 else max(0.0, (1 - u) / 0.2)) * 0.5
                z = -L * u
                row = [bm.verts.new((-ww, 0, z)), bm.verts.new((0, t * 0.5 * (1 if u < 0.95 else 0.2), z)), bm.verts.new((ww, 0, z)), bm.verts.new((0, -t * 0.5 * (1 if u < 0.95 else 0.2), z))]
                rows.append(row)
            for i in range(n):
                a, b = rows[i], rows[i + 1]
                for j in range(4):
                    bm.faces.new((a[j], a[(j + 1) % 4], b[(j + 1) % 4], b[j]))
            bm.faces.new(list(reversed(rows[0])))
            bm.faces.new(rows[-1])
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        me = bpy.data.meshes.new("h")
        bm.to_mesh(me)
        bm.free()
        ob = bpy.data.objects.new("h", me)
        bpy.context.scene.collection.objects.link(ob)
        if h["bevel"] > 0 and p in ("box", "cyl", "cone"):
            bv = ob.modifiers.new("bv", 'BEVEL')
            bv.width = h["bevel"]
            bv.segments = 2
            bv.limit_method = 'ANGLE'
            bv.angle_limit = math.radians(35)
            bv.harden_normals = False
        bpy.context.view_layer.update()
        dg = bpy.context.evaluated_depsgraph_get()
        me2 = bpy.data.meshes.new_from_object(ob.evaluated_get(dg))
        bpy.data.objects.remove(ob)
        bpy.data.meshes.remove(me)
        mat = Matrix.Translation(Vector(h["pos"])) @ _rot(h["rot"]).to_4x4()
        me2.transform(mat)
        # Arestas vivas (> 40°) ficam marcadas; o resto é liso.
        bm = bmesh.new()
        bm.from_mesh(me2)
        for e in bm.edges:
            if len(e.link_faces) == 2 and e.calc_face_angle(0) > math.radians(40 if h["smooth"] else 1):
                e.smooth = False
        for f in bm.faces:
            f.smooth = True
        bm.to_mesh(me2)
        bm.free()
        return me2

    # -------------------------------------------------- cor
    def _blob_colors(self, verts, els):
        """Cor de cada vértice pela influência de cada elemento (o campo do metaball)."""
        n = len(verts)
        W = np.zeros((n, len(els)))
        for i, b in enumerate(els):
            if b["neg"]:
                continue
            R = np.array(_rot(b["rot"]))
            local = (verts - np.array(b["pos"])) @ R  # linha * R = R^T * coluna
            if b["kind"] == "BALL":
                d2 = (local ** 2).sum(1) / (b["r"] / ksurf(b["stiff"])) ** 2
            elif b["kind"] == "ELLIPSOID":
                d2 = ((local / np.array(b["size"])) ** 2).sum(1) / (1.0 / ksurf(b["stiff"])) ** 2
            else:
                hl = b["size"][0]
                lx = np.clip(local[:, 0], -hl, hl)
                q = local.copy()
                q[:, 0] -= lx
                d2 = (q ** 2).sum(1) / (b["r"] / ksurf(b["stiff"])) ** 2
            f = b["stiff"] * np.clip(1 - d2, 0, None) ** 3
            W[:, i] = f
        W = W ** 4 + 1e-12
        W /= W.sum(1, keepdims=True)
        C = np.array([b["c"] for b in els])
        RM = np.array([(b["rough"], b["metal"]) for b in els])
        return W @ C, W @ RM

    def _apply_paints(self, verts, cols, groups):
        for p in self.paints:
            R = np.array(_rot(p["rot"]))
            local = (verts - np.array(p["pos"])) @ R
            d = np.sqrt(((local / np.array(p["radii"])) ** 2).sum(1))
            s = max(p["soft"], 1e-3)
            w = np.clip((1 - d) / s, 0, 1)
            w = w * w * (3 - 2 * w)
            if p["only"] is not None:
                w = w * (groups == p["only"])
            cols[:] = cols * (1 - w[:, None]) + np.array(p["c"]) * w[:, None]

    # -------------------------------------------------- montagem
    def build(self):
        st = self.style
        parts = []  # (verts, faces(list de tuplas), loop normals, cor por vértice, rm por vértice, grupo)
        for g, me, els in self._blob_meshes():
            v = np.array([x.co[:] for x in me.vertices])
            c, rm = self._blob_colors(v, els)
            parts.append([me, v, c, rm, g, True])
        for h in self.hards:
            me = self._hard_mesh(h)
            v = np.array([x.co[:] for x in me.vertices])
            c = np.tile(np.array(h["c"]), (len(v), 1))
            rm = np.tile(np.array([h["rough"], h["metal"]]), (len(v), 1))
            parts.append([me, v, c, rm, "hard", False])
        # Pintura por volumes (só nos blobs e peças marcadas).
        for pt in parts:
            groups = np.array([pt[4]] * len(pt[1]))
            self._apply_paints(pt[1], pt[2], groups)
        # Malha única para a oclusão.
        allv = []
        allf = []
        off = 0
        for pt in parts:
            me = pt[0]
            allv.extend([tuple(x) for x in pt[1]])
            for poly in me.polygons:
                allf.append(tuple(off + i for i in poly.vertices))
            off += len(pt[1])
        bvh = BVHTree.FromPolygons(allv, allf, epsilon=0.0)
        ext = np.array(allv)
        lo, hi = ext.min(0), ext.max(0)
        size = float(np.linalg.norm(hi - lo))
        out = []
        rng = np.random.default_rng(7)
        dirs = rng.normal(size=(st.get("ao_rays", 28), 3))
        dirs /= np.linalg.norm(dirs, axis=1, keepdims=True)
        for pt in parts:
            me, v, c, rm, g, blob = pt
            me.calc_loop_triangles()
            vn = np.array([x.normal[:] for x in me.vertices])
            # Oclusão de ambiente por raios (hemisfério da normal), alcance relativo ao tamanho.
            ao = np.ones(len(v))
            reach = size * st.get("ao_reach", 0.35)
            for i in range(len(v)):
                nrm = Vector(vn[i])
                o = Vector(v[i]) + nrm * 0.004
                hit = 0.0
                tot = 0.0
                for d in dirs:
                    dd = Vector(d)
                    cs = dd.dot(nrm)
                    if cs <= 0:
                        dd = -dd
                        cs = -cs
                    r = bvh.ray_cast(o, dd, reach)
                    tot += cs
                    if r[0] is not None:
                        hit += cs * (1.0 - (r[3] / reach) ** 2)
                ao[i] = 1.0 - hit / max(tot, 1e-6)
            # Céu: as faces para cima recebem mais luz pintada.
            up = np.clip(vn[:, 1] * 0.5 + 0.5, 0, 1)
            hgt = (v[:, 1] - lo[1]) / max(hi[1] - lo[1], 1e-6)
            # Curvatura aproximada: diferença entre a normal do vértice e a direção para o centro dos vizinhos.
            curv = np.zeros(len(v))
            nb = [[] for _ in range(len(v))]
            for e in me.edges:
                a, b = e.vertices
                nb[a].append(b)
                nb[b].append(a)
            for i in range(len(v)):
                if nb[i]:
                    cen = v[nb[i]].mean(0)
                    d = v[i] - cen
                    L = np.linalg.norm(d)
                    if L > 1e-7:
                        curv[i] = np.dot(d / L, vn[i])
            rgb = c[:, :3].copy()
            a = c[:, 3:4].copy()
            emis = (a[:, 0] < 0.99)
            k_ao = st.get("ao", 0.6)
            shade = (1 - k_ao) + k_ao * np.maximum(ao, 0.3) ** st.get("ao_pow", 1.0)
            shade *= 1 + st.get("sky", 0.0) * (up - 0.5) + st.get("height", 0.0) * (hgt - 0.5)
            shade *= 1 + st.get("edge", 0.0) * np.clip(curv * 4, -1, 1)
            shade = np.where(emis, 1.0, shade)
            rgb = rgb * shade[:, None]
            # Sombras puxam para o frio e luzes para o quente (pintura à mão).
            hk = st.get("hue", 0.0)
            if hk > 0:
                t = np.clip(shade - 1.0, -1, 1)[:, None] * (~emis)[:, None]
                coolc = np.array(st.get("cool", (0.45, 0.4, 0.8)))
                warmc = np.array(st.get("warm", (1.0, 0.86, 0.55)))
                rgb = np.where(t < 0, rgb * (1 + (coolc - 1) * (-t) * hk), rgb + (warmc - rgb) * t * hk * 0.35)
            # Variação de cor pintada à mão (ruído suave por posição).
            nv = st.get("noise", 0.0)
            if nv > 0:
                ph = v @ np.array([3.1, 5.7, 4.3]) * st.get("noise_freq", 6.0)
                nz = np.sin(ph) * 0.5 + np.sin(ph * 2.3 + 1.7) * 0.3 + np.sin(v[:, 0] * 23 + v[:, 2] * 17) * 0.2
                rgb = rgb * (1 + nv * nz[:, None] * (~emis)[:, None])
            rgb = np.clip(rgb, 0, 1.0)
            fc = np.concatenate([rgb, a], 1)
            out.append((me, v, fc, rm))
        return out


def export(model, path):
    """Binário: 'LBM1', nv, ni, pos f32*3, nrm f32*3, cor f32*4, uv2 f32*2, índices u32.
    Converte da Blender (aqui já em coordenadas da Godot) sem troca de eixos."""
    parts = model.build()
    P, N, C, U, I = [], [], [], [], []
    key = {}
    for me, v, fc, rm in parts:
        cn = me.corner_normals
        for tri in me.loop_triangles:
            if tri.area < 1e-9:
                continue
            ids = []
            for li, vi in zip(tri.loops, tri.vertices):
                n = cn[li].vector
                if not (n.length > 1e-6 and all(math.isfinite(x) for x in n)):
                    n = tri.normal if tri.normal.length > 1e-6 else Vector((0, 1, 0))
                k = (round(v[vi][0], 5), round(v[vi][1], 5), round(v[vi][2], 5), round(n[0], 3), round(n[1], 3), round(n[2], 3), round(float(fc[vi][0]), 3), round(float(fc[vi][1]), 3), round(float(fc[vi][2]), 3), round(float(fc[vi][3]), 2))
                j = key.get(k)
                if j is None:
                    j = len(P)
                    key[k] = j
                    P.append(v[vi])
                    N.append((n[0], n[1], n[2]))
                    C.append(fc[vi])
                    U.append(rm[vi])
                ids.append(j)
            # A Godot usa ordem horária para a frente da face.
            I.extend([ids[0], ids[2], ids[1]])
    P = np.array(P, dtype=np.float32)
    with open(path, "wb") as f:
        f.write(b"LBM1")
        f.write(struct.pack("<II", len(P), len(I)))
        f.write(P.tobytes())
        f.write(np.array(N, dtype=np.float32).tobytes())
        f.write(np.array(C, dtype=np.float32).tobytes())
        f.write(np.array(U, dtype=np.float32).tobytes())
        f.write(np.array(I, dtype=np.uint32).tobytes())
    for me, *_ in parts:
        bpy.data.meshes.remove(me)
    return len(P), len(I) // 3
