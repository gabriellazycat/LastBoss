"""Peças de cenário do diorama (26/11/2026, branches diorama-*): árvores, arbustos e pedras arredondados, com a cor
pintada nos vértices (degradê de luz de cima para baixo, ruído macio de duas cores), no espírito do Holy Sheep
(tools/blender/diorama_kit.py de lá). Uma paleta e uma forma por versão:
  a  maquete de dia: copas em bolhas macias, verdes de prado;
  b  brinquedo de madeira: formas de torno (esfera, cone, cilindro) lisas, tinta de brinquedo;
  c  feltro: bolhas mais irregulares e foscas, verdes de lã.
"C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --factory-startup -P tools/art/blender_dio/props.py -- <saída> <a|b|c>
Grava <saída>/<id>.glb (cor de vértice linear em COLOR_0); o tools/art/import_dio.gd converte para o jogo."""
import math
import os
import random
import sys

import bmesh
import bpy
from mathutils import Vector, noise

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = argv[0] if argv else "."
STYLE = argv[1] if len(argv) > 1 else "a"


def lin(h):
    h = h.lstrip("#")
    c = [int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    return tuple(x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in c)


def mix(a, b, t):
    t = max(0.0, min(1.0, t))
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def mul(a, k):
    return tuple(a[i] * k for i in range(3))


PAL = {
    "a": {"leaf": ("#4c8a2c", "#3b7426", "#a6cc52"), "pine": ("#2f6e3c", "#255a31", "#78ad5c"),
          "poplar": ("#5f9a34", "#4b8329", "#b4d35e"), "bush": ("#3f7c2a", "#336a23", "#8cbf4c"),
          "trunk": ("#6e4c33", "#5a3c28"), "rock": ("#9a958a", "#7d786e", "#c9c3b4"), "noise": 0.55, "bumps": 0.16},
    "b": {"leaf": ("#5fa04a", "#4f8a3d", "#8fc46a"), "pine": ("#3d7f58", "#326c4a", "#6aa47c"),
          "poplar": ("#88b84a", "#77a53e", "#b4d470"), "bush": ("#5a9a45", "#4c873a", "#86bd62"),
          "trunk": ("#a8714a", "#8f5e3c"), "rock": ("#b9ad9a", "#a29683", "#d8ccb6"), "noise": 0.12, "bumps": 0.0},
    "c": {"leaf": ("#5b8f4e", "#4a7a41", "#8fb879"), "pine": ("#3f6e52", "#335c44", "#6e977a"),
          "poplar": ("#7a9e4e", "#678a41", "#a5c37a"), "bush": ("#507f46", "#42703b", "#7fa86c"),
          "trunk": ("#7a5a46", "#664a39"), "rock": ("#9c9690", "#86807a", "#c2bbb3"), "noise": 0.8, "bumps": 0.24},
}[STYLE]


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def painted(c3, zlo, zhi, seed, low=0.72):
    base, var, top = lin(c3[0]), lin(c3[1]), lin(c3[2] if len(c3) > 2 else c3[0])

    def f(co, n):
        t = noise.noise(Vector((co.x * 1.3 + seed, co.y * 1.3, co.z * 1.3))) * 0.5 + 0.5
        c = mix(base, var, 0.5 + (t - 0.5) * 2.0 * PAL["noise"])
        h = (co.z - zlo) / max(zhi - zlo, 0.01)
        c = mul(c, low + (1.0 - low) * max(0.0, min(1.0, h)))
        k = max(0.0, min(1.0, (n.z - 0.25) / 0.6)) * 0.55 * max(0.0, min(1.0, h * 1.4))
        return mix(c, top, k)
    return f


def _obj(bm, name):
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(o)
    return o


def blob(center, radius, scale=(1, 1, 1), seed=0.0, sub=3, bumps=None):
    bumps = PAL["bumps"] if bumps is None else bumps
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=sub, radius=radius)
    for v in bm.verts:
        d = v.co.normalized()
        k = noise.noise(d * 1.7 + Vector((seed, seed * 0.7, 0))) * bumps * radius
        v.co = Vector((v.co.x * scale[0], v.co.y * scale[1], v.co.z * scale[2])) + d * k + Vector(center)
    return _obj(bm, "blob")


def cone(z0, h, r0, r1, seg=20, rings=6, center=(0, 0), round_k=0.0):
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=seg, radius1=r0, radius2=r1, depth=h)
    for v in bm.verts:
        v.co.z += z0 + h / 2
        v.co.x += center[0]
        v.co.y += center[1]
    o = _obj(bm, "cone")
    if round_k > 0:
        m = o.modifiers.new("b", "BEVEL")
        m.width = round_k
        m.segments = 3
    return o


def paint(objs, fn):
    for o in objs:
        me = o.data
        for p in me.polygons:
            p.use_smooth = True
        if "Col" not in me.color_attributes:
            me.color_attributes.new("Col", "FLOAT_COLOR", "CORNER")
        ca = me.color_attributes["Col"]
        mw = o.matrix_world
        for li, loop in enumerate(me.loops):
            v = me.vertices[loop.vertex_index]
            co = mw @ v.co
            n = (mw.to_3x3() @ v.normal).normalized()
            c = fn(co, n)
            ca.data[li].color = (c[0], c[1], c[2], 1.0)


def apply_mods(objs):
    for o in objs:
        bpy.context.view_layer.objects.active = o
        for m in list(o.modifiers):
            bpy.ops.object.modifier_apply(modifier=m.name)


def export(name, objs):
    apply_mods(objs)
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    if len(objs) > 1:
        bpy.ops.object.join()
    path = os.path.join(OUT, name + ".glb")
    bpy.ops.export_scene.gltf(filepath=path, use_selection=True, export_format="GLB", export_vertex_color="ACTIVE",
                              export_all_vertex_colors=False)
    print("dio-props:", name)


def trunk(h, r0, r1, seg=10):
    return cone(0.0, h, r0, r1, seg=seg)


# ---------------------------------------------------------------- peças

def oak(name, seed, tall):
    reset()
    rnd = random.Random(seed)
    th = 1.7 if tall else 1.3
    parts = [trunk(th + 0.8, 0.32, 0.2)]
    paint(parts, lambda co, n: mix(lin(PAL["trunk"][0]), lin(PAL["trunk"][1]), co.z / 3))
    cz = th + 1.4
    leaves = []
    if STYLE == "b":
        # brinquedo: uma esfera de torno, perfeita, e uma menor
        leaves.append(blob((0, 0, cz + 0.2), 1.9 if tall else 1.7, (1, 1, 1.05 if tall else 0.95), seed, 4, 0.0))
    else:
        n = 5 if tall else 4
        leaves.append(blob((0, 0, cz + 0.5), 1.55, (1, 1, 0.95), seed))
        for i in range(n):
            a = i / n * math.tau + rnd.uniform(-0.3, 0.3)
            r = rnd.uniform(0.85, 1.1)
            leaves.append(blob((math.cos(a) * r, math.sin(a) * r, cz + rnd.uniform(-0.3, 0.4)), rnd.uniform(1.05, 1.35),
                               (1, 1, 0.9), seed + i * 3.1))
    paint(leaves, painted(PAL["leaf"], cz - 1.6, cz + 1.9, seed))
    export(name, parts + leaves)


def pine(name, seed):
    reset()
    parts = [trunk(1.4, 0.3, 0.22)]
    paint(parts, lambda co, n: mix(lin(PAL["trunk"][0]), lin(PAL["trunk"][1]), co.z / 2))
    tiers = []
    z = 1.0
    for i, (r, h) in enumerate([(1.9, 2.2), (1.5, 1.9), (1.05, 1.7)]):
        o = cone(z, h, r, 0.05 if STYLE == "b" else 0.12, seg=24 if STYLE == "b" else 14, round_k=0.12)
        if STYLE != "b":
            sub = o.modifiers.new("s", "SUBSURF")
            sub.levels = 1
            d = o.modifiers.new("d", "DISPLACE")
            t = bpy.data.textures.new("n%d" % i, "CLOUDS")
            t.noise_scale = 0.6
            d.texture = t
            d.strength = PAL["bumps"] * 1.4
        tiers.append(o)
        z += h * 0.58
    apply_mods(tiers)
    paint(tiers, painted(PAL["pine"], 1.0, z + 1.0, seed))
    export(name, parts + tiers)


def poplar(name, seed):
    reset()
    parts = [trunk(1.6, 0.26, 0.18)]
    paint(parts, lambda co, n: mix(lin(PAL["trunk"][0]), lin(PAL["trunk"][1]), co.z / 2))
    lv = [blob((0, 0, 3.2), 1.25, (1, 1, 1.75), seed, 4 if STYLE == "b" else 3)]
    if STYLE != "b":
        lv.append(blob((0.35, 0.2, 2.3), 0.95, (1, 1, 1.2), seed + 2))
    paint(lv, painted(PAL["poplar"], 1.4, 5.4, seed))
    export(name, parts + lv)


def bush(name, seed):
    reset()
    rnd = random.Random(seed)
    if STYLE == "b":
        lv = [blob((0, 0, 0.55), 0.75, (1.1, 1.0, 0.85), seed, 4, 0.0), blob((0.7, 0.2, 0.4), 0.5, (1, 1, 0.9), seed, 4, 0.0)]
    else:
        lv = [blob((rnd.uniform(-0.4, 0.4), rnd.uniform(-0.3, 0.3), 0.5), rnd.uniform(0.55, 0.75), (1, 1, 0.85), seed + i)
              for i in range(3)]
    paint(lv, painted(PAL["bush"], 0.0, 1.3, seed, 0.62))
    export(name, lv)


def rock(name, seed):
    reset()
    o = blob((0, 0, 0.35), 0.75, (1.3, 1.0, 0.65), seed, 2, 0.35 if STYLE != "b" else 0.05)
    for p in o.data.polygons:
        p.use_smooth = STYLE != "a"
    paint([o], painted(PAL["rock"], 0.0, 0.9, seed, 0.6))
    for p in o.data.polygons:
        p.use_smooth = STYLE != "a"
    export(name, [o])


os.makedirs(OUT, exist_ok=True)
oak("tree_s5", 1.3, True)
oak("tree_round_s5", 4.1, False)
pine("tree_s6", 2.2)
poplar("tree_round_s6", 3.7)
bush("bush", 5.5)
rock("rock", 6.6)
