"""Taverna e casas do diorama (26/11/2026, branches diorama-*): construções de miniatura com cor nos vértices.
As janelas levam alfa < 1 na cor (o look5 faz brilhar: glow = 1 - alfa), para a luz quente de dentro.
  a  maquete de dia: enxaimel (reboco creme e vigas escuras), telhado de telha laranja, base de pedra;
  b  brinquedo de madeira: blocos lisos pintados, telhado em prisma de cor viva, pinos e rodelas;
  c  feltro: formas fofas e arredondadas, telhado de palha/lã, cores de lã.
"C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --factory-startup -P tools/art/blender_dio/buildings.py -- <saída> <a|b|c>
Grava <saída>/tavern.glb e house.glb (+Y para a frente no Blender; o import_dio gira para o jogo)."""
import math
import os
import sys

import bmesh
import bpy
from mathutils import Vector, noise

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = argv[0] if argv else "."
STYLE = argv[1] if len(argv) > 1 else "a"


def lin(h, a=1.0):
    h = h.lstrip("#")
    c = [int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    return tuple(x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in c) + (a,)


PAL = {
    "a": {"wall": "#efe3c8", "beam": "#5b3f2c", "stone": "#a49c8c", "roof": "#c8643a", "roof2": "#a94f2e",
          "door": "#7a4a2a", "win": "#ffcf7a", "sign": "#8a5a34", "barrel": "#9a6a3e", "hoop": "#4a4a4a",
          "chim": "#9b8f80", "thatch": "#d9b66a", "bevel": 0.06, "wobble": 0.0},
    "b": {"wall": "#f3e9d2", "beam": "#d9534f", "stone": "#4f7cc4", "roof": "#e8563f", "roof2": "#3f8fd2",
          "door": "#f2b33d", "win": "#ffe08a", "sign": "#f2b33d", "barrel": "#c98b4e", "hoop": "#d9534f",
          "chim": "#e8e0cc", "thatch": "#f2c14e", "bevel": 0.14, "wobble": 0.0},
    "c": {"wall": "#e9dccb", "beam": "#8a6a55", "stone": "#9c938a", "roof": "#b5624d", "roof2": "#9b5242",
          "door": "#8b5e44", "win": "#ffc874", "sign": "#9b7155", "barrel": "#a7795a", "hoop": "#6d625c",
          "chim": "#a89d92", "thatch": "#d8b27a", "bevel": 0.22, "wobble": 0.05},
}[STYLE]

PARTS = []


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    PARTS.clear()


def _obj(bm, name, col, bevel=None):
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(o)
    b = PAL["bevel"] if bevel is None else bevel
    if b > 0:
        m = o.modifiers.new("b", "BEVEL")
        m.width = b
        m.segments = 3 if STYLE != "a" else 2
        m.limit_method = "ANGLE"
    o["col"] = col[0] if isinstance(col, tuple) else col
    o["alpha"] = col[1] if isinstance(col, tuple) else 1.0
    PARTS.append(o)
    return o


def box(lo, hi, col, bevel=None):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        v.co = Vector((lo[0] + (v.co.x + 0.5) * (hi[0] - lo[0]), lo[1] + (v.co.y + 0.5) * (hi[1] - lo[1]),
                       lo[2] + (v.co.z + 0.5) * (hi[2] - lo[2])))
    return _obj(bm, "box", col, bevel)


def cyl(c, r, h, col, seg=16, axis="Z", bevel=None, r2=None):
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=seg, radius1=r, radius2=r if r2 is None else r2, depth=h)
    for v in bm.verts:
        p = v.co.copy()
        if axis == "Y":
            p = Vector((p.x, p.z, p.y))
        elif axis == "X":
            p = Vector((p.z, p.y, p.x))
        v.co = p + Vector(c)
    return _obj(bm, "cyl", col, bevel)


def prism(lo, hi, ridge_h, col, over=0.35, bevel=None):
    """Telhado de duas águas ao longo de X: base retangular lo..hi (z = lo[2]), cumeeira a ridge_h acima."""
    x0, x1 = lo[0] - over, hi[0] + over
    y0, y1 = lo[1] - over, hi[1] + over
    z0 = lo[2]
    ym = (y0 + y1) / 2
    t = 0.18
    bm = bmesh.new()
    vs = [bm.verts.new(p) for p in [
        (x0, y0, z0), (x1, y0, z0), (x1, ym, z0 + ridge_h), (x0, ym, z0 + ridge_h),
        (x0, y1, z0), (x1, y1, z0),
        (x0, y0, z0 + t), (x1, y0, z0 + t), (x1, ym, z0 + ridge_h + t), (x0, ym, z0 + ridge_h + t),
        (x0, y1, z0 + t), (x1, y1, z0 + t)]]
    F = [(0, 1, 7, 6), (4, 10, 11, 5), (6, 7, 8, 9), (9, 8, 11, 10), (0, 3, 2, 1), (3, 4, 5, 2),
         (0, 6, 9, 3), (3, 9, 10, 4), (1, 2, 8, 7), (2, 5, 11, 8)]
    for f in F:
        bm.faces.new([vs[i] for i in f])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return _obj(bm, "roof", col, bevel)


def roof(lo, hi, ridge_h, col, col2, over=0.35, rows=4):
    """Telhado em fiadas: prismas empilhados, cada um mais para dentro e um pouco acima, como telhas/palha."""
    hd = (hi[1] - lo[1]) / 2 + over
    slope = ridge_h / hd
    for i in range(rows):
        ins = i * hd / rows * 0.92
        z = lo[2] + ins * slope + 0.045 * i
        prism((lo[0], lo[1] + ins, z), (hi[0], hi[1] - ins, z), ridge_h - ins * slope, col if i % 2 == 0 else col2,
              over, 0.05 if STYLE == "a" else None)
    ym = (lo[1] + hi[1]) / 2
    zt = lo[2] + ridge_h + 0.045 * rows + 0.12
    box((lo[0] - over - 0.05, ym - 0.16, zt - 0.12), (hi[0] + over + 0.05, ym + 0.16, zt + 0.06), PAL["beam"], 0.04)


def paint_all():
    for o in PARTS:
        bpy.context.view_layer.objects.active = o
        for m in list(o.modifiers):
            bpy.ops.object.modifier_apply(modifier=m.name)
        me = o.data
        base = lin(o["col"], o["alpha"])
        if "Col" not in me.color_attributes:
            me.color_attributes.new("Col", "FLOAT_COLOR", "CORNER")
        ca = me.color_attributes["Col"]
        for p in me.polygons:
            p.use_smooth = STYLE != "a" or o.name.startswith("cyl")
        for li, loop in enumerate(me.loops):
            v = me.vertices[loop.vertex_index]
            co = o.matrix_world @ v.co
            # oclusão barata: mais escuro rente ao chão; leve variação para não ficar plástico chapado
            k = 0.78 + 0.22 * min(1.0, co.z / 1.2)
            k *= 1.0 + (noise.noise(co * 1.7) * 0.06 if STYLE != "b" else 0.0)
            if base[3] < 1.0:
                k = 1.0
            ca.data[li].color = (base[0] * k, base[1] * k, base[2] * k, base[3])
        if STYLE == "c" and PAL["wobble"] > 0:
            for v in me.vertices:
                d = noise.noise(v.co * 2.3) * PAL["wobble"]
                v.co += v.normal * d


def export(name):
    paint_all()
    bpy.ops.object.select_all(action="DESELECT")
    for o in PARTS:
        o.select_set(True)
    bpy.context.view_layer.objects.active = PARTS[0]
    bpy.ops.object.join()
    path = os.path.join(OUT, name + ".glb")
    bpy.ops.export_scene.gltf(filepath=path, use_selection=True, export_format="GLB", export_vertex_color="ACTIVE",
                              export_all_vertex_colors=False)
    print("dio-build:", name)


WIN = (PAL["win"], 0.72 if STYLE != "c" else 0.45)   # alfa 0,72: brilho quente na janela


def window(x, y, z, w, h, face_y):
    """Janela na parede de normal +-Y em y; moldura e vidro aceso."""
    d = 0.06 if face_y > 0 else -0.06
    box((x - w / 2 - 0.08, y - 0.02, z - 0.08), (x + w / 2 + 0.08, y + d * 1.4, z + h + 0.08), PAL["beam"], 0.02)
    box((x - w / 2, y + d * 0.5, z), (x + w / 2, y + d * 2.0, z + h), WIN, 0.0)


def barrel(c, r=0.32, h=0.75):
    cyl((c[0], c[1], c[2] + h / 2), r, h, PAL["barrel"], 14, bevel=0.04)
    for z in (0.18, h - 0.18):
        cyl((c[0], c[1], c[2] + z), r + 0.025, 0.06, PAL["hoop"], 14, bevel=0.0)


def tavern():
    reset()
    W, D = 6.0, 4.2
    x0, x1, y0, y1 = -W / 2, W / 2, -D / 2, D / 2
    if STYLE == "b":
        box((x0 - 0.15, y0 - 0.15, 0), (x1 + 0.15, y1 + 0.15, 0.35), PAL["stone"])
        box((x0, y0, 0.35), (x1, y1, 2.2), PAL["wall"])
        box((x0 + 0.4, y0 + 0.3, 2.2), (x1 - 0.4, y1 - 0.3, 3.6), PAL["beam"])
        prism((x0 + 0.4, y0 + 0.3, 3.6), (x1 - 0.4, y1 - 0.3, 3.6), 1.6, PAL["roof"], 0.3)
        for x in (-1.6, 0.0, 1.6):
            window(x, y1, 1.1, 0.7, 0.75, 1)
        for x in (-1.2, 1.2):
            window(x, y1 - 0.3, 2.6, 0.55, 0.6, 1)
        cyl((2.1, 0.6, 4.6), 0.35, 1.8, PAL["chim"], 16)
        box((-0.45, y1, 0.35), (0.45, y1 + 0.12, 1.75), PAL["door"])
        cyl((0.0, y1 + 0.1, 1.75), 0.45, 0.12, PAL["door"], 16, axis="Y")
    else:
        box((x0 - 0.12, y0 - 0.12, 0), (x1 + 0.12, y1 + 0.12, 0.55), PAL["stone"])
        box((x0, y0, 0.55), (x1, y1, 2.3), PAL["wall"])
        # andar de cima um pouco mais largo (enxaimel em balanço)
        box((x0 - 0.15, y0 - 0.15, 2.3), (x1 + 0.15, y1 + 0.15, 3.9), PAL["wall"])
        if STYLE == "a":
            for x in (x0, -1.0, 1.0, x1):
                for y, s in ((y1 + 0.15, 1), (y0 - 0.15, -1)):
                    box((x - 0.1, y - 0.05 * s, 2.3), (x + 0.1, y + 0.08 * s, 3.9), PAL["beam"], 0.02)
            for y, s in ((y1 + 0.15, 1), (y0 - 0.15, -1)):
                box((x0 - 0.15, y - 0.05 * s, 2.25), (x1 + 0.15, y + 0.09 * s, 2.42), PAL["beam"], 0.02)
                box((x0 - 0.15, y - 0.05 * s, 3.8), (x1 + 0.15, y + 0.09 * s, 3.95), PAL["beam"], 0.02)
        roof((x0 - 0.15, y0 - 0.15, 3.9), (x1 + 0.15, y1 + 0.15, 3.9), 2.0, PAL["roof"], PAL["roof2"], 0.45, 5)
        # oitões fechando o telhado
        for x, s in ((x0 - 0.12, -1), (x1 + 0.12, 1)):
            bm = bmesh.new()
            a = bm.verts.new((x, y0 - 0.15, 3.9))
            b = bm.verts.new((x, y1 + 0.15, 3.9))
            c = bm.verts.new((x, 0.0, 5.85))
            bm.faces.new((a, b, c) if s > 0 else (a, c, b))
            _obj(bm, "gable", PAL["wall"], 0.0)
        for x in (-1.9, 1.9):
            window(x, y1, 1.0, 0.8, 0.85, 1)
        for x in (-1.9, 0.0, 1.9):
            window(x, y1 + 0.15, 2.8, 0.7, 0.7, 1)
        for x in (-1.5, 1.5):
            window(x, y0, 1.0, 0.8, 0.85, -1)
        box((-0.55, y1, 0.55), (0.55, y1 + 0.1, 2.05), PAL["door"], 0.03)
        box((-1.2, y1 + 0.1, 2.0), (1.2, y1 + 0.9, 2.1), PAL["roof2"], 0.03)   # alpendre
        box((2.4, -0.4, 3.5), (3.0, 0.3, 6.6), PAL["chim"])
    # placa pendurada num braço, com uma caneca
    box((x1 - 0.2, y1 + 0.1, 2.75), (x1 + 0.1, y1 + 1.3, 2.85), PAL["beam"], 0.02)
    box((x1 - 0.12, y1 + 0.55, 1.85), (x1 + 0.02, y1 + 1.25, 2.6), PAL["sign"], 0.03)
    cyl((x1 - 0.13, y1 + 0.9, 2.2), 0.17, 0.3, "#f2d38a", 12, bevel=0.02)
    # barris e um banco na frente
    barrel((-2.4, y1 + 0.7, 0))
    barrel((-1.75, y1 + 0.85, 0))
    barrel((-2.1, y1 + 0.8, 0.75), 0.28, 0.6)
    box((1.3, y1 + 0.45, 0.4), (2.5, y1 + 0.85, 0.5), PAL["barrel"], 0.03)
    for x in (1.4, 2.4):
        box((x - 0.06, y1 + 0.5, 0), (x + 0.06, y1 + 0.8, 0.4), PAL["beam"], 0.02)
    export("tavern")


def house(name, seed):
    reset()
    W, D = 4.0, 3.2
    x0, x1, y0, y1 = -W / 2, W / 2, -D / 2, D / 2
    if STYLE == "b":
        box((x0, y0, 0), (x1, y1, 2.0), PAL["wall"])
        prism((x0, y0, 2.0), (x1, y1, 2.0), 1.5, PAL["roof2"] if seed % 2 else PAL["roof"], 0.3)
        window(-0.9, y1, 0.9, 0.6, 0.6, 1)
        box((0.3, y1, 0), (1.1, y1 + 0.12, 1.4), PAL["door"])
        cyl((1.2, 0.0, 3.2), 0.28, 1.2, PAL["chim"], 16)
    else:
        box((x0 - 0.1, y0 - 0.1, 0), (x1 + 0.1, y1 + 0.1, 0.4), PAL["stone"])
        box((x0, y0, 0.4), (x1, y1, 2.2), PAL["wall"])
        if STYLE == "a":
            for x in (x0, 0.0, x1):
                box((x - 0.09, y1 - 0.02, 0.4), (x + 0.09, y1 + 0.07, 2.2), PAL["beam"], 0.02)
            box((x0, y1 - 0.02, 2.1), (x1, y1 + 0.08, 2.25), PAL["beam"], 0.02)
        roof_c = PAL["thatch"] if STYLE == "c" or seed % 2 == 0 else PAL["roof"]
        roof((x0, y0, 2.2), (x1, y1, 2.2), 1.7, roof_c, PAL["roof2"] if roof_c == PAL["roof"] else PAL["thatch"], 0.4, 4)
        for x, s in ((x0 + 0.02, -1), (x1 - 0.02, 1)):
            bm = bmesh.new()
            a = bm.verts.new((x, y0, 2.2))
            b = bm.verts.new((x, y1, 2.2))
            c = bm.verts.new((x, 0.0, 3.9))
            bm.faces.new((a, b, c) if s > 0 else (a, c, b))
            _obj(bm, "gable", PAL["wall"], 0.0)
        window(-1.0, y1, 1.1, 0.7, 0.7, 1)
        window(1.0, y0, 1.1, 0.7, 0.7, -1)
        box((0.45, y1, 0.4), (1.25, y1 + 0.1, 1.85), PAL["door"], 0.03)
        box((-1.6, -0.3, 3.0), (-1.1, 0.2, 4.4), PAL["chim"])
    export(name)


os.makedirs(OUT, exist_ok=True)
tavern()
house("house", 1)
house("house_b", 2)
