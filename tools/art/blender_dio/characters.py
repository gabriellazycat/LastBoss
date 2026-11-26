"""Herói, rato e lobo do diorama (26/11/2026, branches diorama-b e diorama-c): bonecos em partes rígidas, cada
parte um objeto com a origem na junta (quadril, ombro, pescoço, eixo da roda). A animação não sai daqui: o
tools/art/import_dio.gd anima as partes pelo nome ("@quad", "@pulltoy", "@biped") e grava a VAT ou a cena do herói.
  b  brinquedo de madeira: formas de torno lisas, tinta de brinquedo; o rato é um carrinho de puxar com rodas;
  c  feltro: bolhas fofas e irregulares, cores de lã, pontos de bordado nos olhos.
Olhos: um ponto de cor só, sem pupila nem brilho (regra dos modelos); o herói não tem olhos (elmo fechado).
"C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --factory-startup -P tools/art/blender_dio/characters.py -- <saída> <b|c>
Grava <saída>/rat.glb, wolf.glb e knight.glb, de frente para -Y do Blender (+Z no glTF).
Cor: os bichos levam cor linear (o import_dio converte); o herói vai como cena e leva a cor já em sRGB."""
import math
import os
import sys

import bmesh
import bpy
from mathutils import Matrix, Vector, noise

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = argv[0] if argv else "."
STYLE = argv[1] if len(argv) > 1 else "b"
FELT = STYLE == "c"


def srgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))


def lin(h):
    return tuple(x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in srgb(h))


P = {
    "b": {"rat": "#9aa3ad", "rat2": "#c9ced4", "pink": "#f08a9a", "eye": "#2a2430", "wheel": "#e2b04a", "axle": "#8a5a34",
          "wolf": "#6f7f99", "wolf2": "#e8dcc4", "wolf3": "#4e5b70", "nose": "#2a2430",
          "tunic": "#d8423a", "steel": "#b9c3cf", "steel2": "#8e9aab", "skin": "#f1c7a0", "wood": "#a8714a",
          "gold": "#f2c14e", "shield": "#3f74c4", "boot": "#5b3f2c"},
    "c": {"rat": "#a59e9a", "rat2": "#d8cfc8", "pink": "#e8a2a6", "eye": "#2d2628", "wheel": "#c9a46a", "axle": "#8a6a52",
          "wolf": "#8a8f9a", "wolf2": "#eee4d4", "wolf3": "#6b707c", "nose": "#2d2628",
          "tunic": "#b8574a", "steel": "#c9c6c0", "steel2": "#a19d97", "skin": "#efcfb3", "wood": "#9c7458",
          "gold": "#e2bd6a", "shield": "#5a7fa8", "boot": "#6a4c3a"},
}[STYLE]

GROUPS = {}   # nome da parte -> lista de objetos (juntados no fim)
PIVOT = {}    # nome da parte -> pivô (mundo)
SRGB_OUT = False


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    GROUPS.clear()
    PIVOT.clear()


def _mesh_obj(bm, part, col):
    me = bpy.data.meshes.new(part)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(part, me)
    bpy.context.collection.objects.link(o)
    me.color_attributes.new("Col", "FLOAT_COLOR", "CORNER")
    c = srgb(col) if SRGB_OUT else lin(col)
    ca = me.color_attributes["Col"]
    for li, loop in enumerate(me.loops):
        v = me.vertices[loop.vertex_index].co
        k = 1.0 + (noise.noise(v * 4.0) * 0.08 if FELT else 0.0)
        ca.data[li].color = (c[0] * k, c[1] * k, c[2] * k, 1.0)
    for p in me.polygons:
        p.use_smooth = True
    GROUPS.setdefault(part, []).append(o)
    return o


def ball(part, c, r, col, sc=(1, 1, 1), sub=3, bump=None):
    bump = (0.12 if FELT else 0.0) if bump is None else bump
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=sub, radius=r)
    for v in bm.verts:
        d = v.co.normalized()
        k = noise.noise(d * 2.1 + Vector(c) * 3.0) * bump * r
        v.co = Vector((v.co.x * sc[0], v.co.y * sc[1], v.co.z * sc[2])) + d * k + Vector(c)
    return _mesh_obj(bm, part, col)


def tube(part, a, b, r0, r1, col, seg=14):
    a, b = Vector(a), Vector(b)
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=seg, radius1=r0, radius2=r1, depth=(b - a).length)
    q = (b - a).normalized().to_track_quat("Z", "Y")
    m = Matrix.Translation((a + b) / 2) @ q.to_matrix().to_4x4()
    for v in bm.verts:
        v.co = m @ v.co
    o = _mesh_obj(bm, part, col)
    if not FELT:
        bv = o.modifiers.new("b", "BEVEL")
        bv.width = min(r0, r1, 0.06) * 0.6 + 0.01
        bv.segments = 3
    return o


def block(part, lo, hi, col, bevel=0.05):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        v.co = Vector((lo[0] + (v.co.x + 0.5) * (hi[0] - lo[0]), lo[1] + (v.co.y + 0.5) * (hi[1] - lo[1]),
                       lo[2] + (v.co.z + 0.5) * (hi[2] - lo[2])))
    o = _mesh_obj(bm, part, col)
    bv = o.modifiers.new("b", "BEVEL")
    bv.width = bevel
    bv.segments = 3
    return o


def disc(part, c, r, t, col, axis="X", seg=20):
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=seg, radius1=r, radius2=r, depth=t)
    rot = {"X": Matrix.Rotation(math.pi / 2, 4, "Y"), "Y": Matrix.Rotation(math.pi / 2, 4, "X"), "Z": Matrix.Identity(4)}[axis]
    for v in bm.verts:
        v.co = Matrix.Translation(c) @ rot @ v.co
    o = _mesh_obj(bm, part, col)
    bv = o.modifiers.new("b", "BEVEL")
    bv.width = min(t * 0.35, 0.04)
    bv.segments = 2
    return o


def finish(name):
    """Junta cada grupo num objeto só, com a origem no pivô, e exporta."""
    for part, objs in GROUPS.items():
        for o in objs:
            bpy.context.view_layer.objects.active = o
            for m in list(o.modifiers):
                bpy.ops.object.modifier_apply(modifier=m.name)
        bpy.ops.object.select_all(action="DESELECT")
        for o in objs:
            o.select_set(True)
        bpy.context.view_layer.objects.active = objs[0]
        if len(objs) > 1:
            bpy.ops.object.join()
        o = bpy.context.view_layer.objects.active
        o.name = part
        o.data.name = part
        piv = Vector(PIVOT.get(part, (0, 0, 0)))
        o.data.transform(Matrix.Translation(-piv))
        o.location = piv
    bpy.ops.object.select_all(action="SELECT")
    path = os.path.join(OUT, name + ".glb")
    bpy.ops.export_scene.gltf(filepath=path, use_selection=True, export_format="GLB", export_vertex_color="ACTIVE",
                              export_all_vertex_colors=False, export_animations=False)
    print("dio-char:", name, sorted(GROUPS))


def eyes(part, x, y, z, r):
    for s in (-1, 1):
        ball(part, (s * x, y, z), r, P["eye"], (1, 0.6, 1), 2, 0.0)


# ---------------------------------------------------------------- rato

def rat():
    reset()
    # corpo em gota, frente para -Y
    PIVOT["body"] = (0, 0, 0.45)
    ball("body", (0, 0.05, 0.45), 0.42, P["rat"], (0.85, 1.25, 0.82))
    ball("body", (0, -0.05, 0.36), 0.3, P["rat2"], (0.75, 1.0, 0.6))   # barriga clara
    PIVOT["head"] = (0, -0.4, 0.55)
    ball("head", (0, -0.6, 0.58), 0.28, P["rat"], (0.9, 1.15, 0.9))
    ball("head", (0, -0.88, 0.55), 0.07, P["pink"], (1, 1, 1), 2, 0.0)   # nariz
    for s in (-1, 1):
        disc("head", (s * 0.2, -0.5, 0.86), 0.16, 0.05, P["rat"], "Y")
        disc("head", (s * 0.2, -0.53, 0.86), 0.1, 0.03, P["pink"], "Y")
    eyes("head", 0.12, -0.8, 0.66, 0.045)
    PIVOT["tail"] = (0, 0.5, 0.4)
    pts = [(0, 0.5, 0.4), (0, 0.8, 0.5), (0, 1.0, 0.68), (0, 1.08, 0.88)]
    for i in range(len(pts) - 1):
        tube("tail", pts[i], pts[i + 1], 0.045 - i * 0.01, 0.035 - i * 0.01, P["pink"], 8)
    if not FELT:
        # carrinho de puxar: base de tábua e quatro rodas
        PIVOT["body"] = (0, 0, 0.45)
        block("body", (-0.3, -0.5, 0.12), (0.3, 0.45, 0.2), P["axle"], 0.03)
        for y, part in ((-0.32, "wheel_f"), (0.3, "wheel_b")):
            PIVOT[part] = (0, y, 0.13)
            for s in (-1, 1):
                disc(part, (s * 0.33, y, 0.13), 0.13, 0.07, P["wheel"], "X")
            tube(part, (-0.36, y, 0.13), (0.36, y, 0.13), 0.025, 0.025, P["axle"], 8)
        # cordinha de puxar com bolinha
        tube("head", (0, -0.9, 0.5), (0, -1.15, 0.2), 0.012, 0.012, P["axle"], 6)
        ball("head", (0, -1.17, 0.18), 0.05, P["wheel"], (1, 1, 1), 2, 0.0)
    else:
        for x, y, part in ((-0.2, -0.28, "leg_fl"), (0.2, -0.28, "leg_fr"), (-0.2, 0.3, "leg_bl"), (0.2, 0.3, "leg_br")):
            PIVOT[part] = (x, y, 0.3)
            ball(part, (x, y, 0.1), 0.11, P["rat"], (1, 1.3, 0.8))
    finish("rat")


# ---------------------------------------------------------------- lobo

def wolf():
    reset()
    PIVOT["body"] = (0, 0, 0.75)
    if FELT:
        ball("body", (0, 0.05, 0.78), 0.45, P["wolf"], (0.85, 1.5, 0.85))
        ball("body", (0, -0.25, 0.68), 0.32, P["wolf2"], (0.8, 0.9, 0.75))
    else:
        tube("body", (0, 0.5, 0.78), (0, -0.45, 0.8), 0.33, 0.36, P["wolf"], 18)
        ball("body", (0, 0.5, 0.78), 0.33, P["wolf"], (1, 0.6, 1), 3, 0.0)
        ball("body", (0, -0.45, 0.8), 0.36, P["wolf"], (1, 0.6, 1), 3, 0.0)
        ball("body", (0, -0.42, 0.68), 0.26, P["wolf2"], (1, 0.8, 0.9), 3, 0.0)
    PIVOT["head"] = (0, -0.55, 1.0)
    ball("head", (0, -0.75, 1.15), 0.3, P["wolf"], (0.95, 1.0, 0.9))
    if FELT:
        ball("head", (0, -1.0, 1.06), 0.17, P["wolf2"], (0.85, 1.2, 0.75))
    else:
        tube("head", (0, -0.85, 1.07), (0, -1.15, 1.05), 0.16, 0.12, P["wolf2"], 14)
    ball("head", (0, -1.17 if not FELT else -1.17, 1.08), 0.06, P["nose"], (1, 1, 1), 2, 0.0)
    for s in (-1, 1):
        bm = bmesh.new()
        bmesh.ops.create_cone(bm, cap_ends=True, segments=4 if not FELT else 10, radius1=0.12, radius2=0.0, depth=0.28)
        for v in bm.verts:
            v.co = Vector((v.co.x + s * 0.17, v.co.y - 0.68, v.co.z + 1.47))
        _mesh_obj(bm, "head", P["wolf3"])
    eyes("head", 0.13, -0.98, 1.24, 0.045)
    PIVOT["tail"] = (0, 0.6, 0.9)
    if FELT:
        ball("tail", (0, 0.85, 1.05), 0.16, P["wolf"], (0.9, 1.7, 0.9))
    else:
        tube("tail", (0, 0.6, 0.9), (0, 0.95, 1.25), 0.1, 0.05, P["wolf3"], 10)
    for x, y, part in ((-0.2, -0.4, "leg_fl"), (0.2, -0.4, "leg_fr"), (-0.2, 0.42, "leg_bl"), (0.2, 0.42, "leg_br")):
        PIVOT[part] = (x, y, 0.62)
        if FELT:
            ball(part, (x, y, 0.32), 0.12, P["wolf"], (1, 1, 2.4))
            ball(part, (x, y - 0.03, 0.06), 0.1, P["wolf2"], (1, 1.2, 0.7))
        else:
            tube(part, (x, y, 0.62), (x, y, 0.08), 0.1, 0.09, P["wolf"], 12)
            ball(part, (x, y - 0.02, 0.08), 0.1, P["wolf3"], (1, 1.2, 0.7), 2, 0.0)
    finish("wolf")


# ---------------------------------------------------------------- cavaleiro (herói)

def knight():
    global SRGB_OUT
    reset()
    SRGB_OUT = True
    # boneco de pino: corpo em sino, cabeça redonda com elmo, braços de pino, pernas curtas
    PIVOT["body"] = (0, 0, 0.75)
    tube("body", (0, 0, 0.55), (0, 0, 1.35), 0.42, 0.3, P["tunic"], 20)
    ball("body", (0, 0, 1.35), 0.3, P["tunic"], (1, 1, 0.5), 3, 0.0)
    tube("body", (0, 0, 0.95), (0, 0, 1.05), 0.4, 0.38, P["boot"], 20)   # cinto
    ball("body", (0, -0.38, 1.0), 0.06, P["gold"], (1, 0.6, 1), 2, 0.0)   # fivela
    PIVOT["head"] = (0, 0, 1.45)
    ball("head", (0, 0, 1.78), 0.34, P["steel"], (1, 1, 1.05))
    tube("head", (0, 0, 1.62), (0, 0, 1.7), 0.36, 0.36, P["steel2"], 20)   # aba do elmo
    block("head", (-0.2, -0.36, 1.74), (0.2, -0.26, 1.8), P["eye"], 0.015)   # fresta do visor
    ball("head", (0, 0, 2.14), 0.07, P["gold"], (1, 1, 1), 2, 0.0)
    tube("head", (0, 0.05, 2.1), (0, 0.18, 2.35), 0.05, 0.08, P["tunic"], 10)   # pluma
    for s, part in ((-1, "arm_l"), (1, "arm_r")):
        PIVOT[part] = (s * 0.42, 0, 1.25)
        tube(part, (s * 0.42, 0, 1.25), (s * 0.5, -0.05, 0.85), 0.11, 0.1, P["tunic"], 12)
        ball(part, (s * 0.5, -0.06, 0.8), 0.11, P["skin"], (1, 1, 1), 2, 0.0)
    # espada na mão direita (aponta para a frente), escudo redondo no braço esquerdo
    block("arm_r", (0.46, -0.85, 0.76), (0.54, -0.15, 0.84), P["steel"], 0.02)
    block("arm_r", (0.4, -0.18, 0.74), (0.6, -0.12, 0.86), P["gold"], 0.02)
    block("arm_r", (0.47, -0.12, 0.77), (0.53, 0.05, 0.83), P["wood"], 0.015)
    disc("arm_l", (-0.62, -0.08, 0.95), 0.36, 0.08, P["shield"], "X")
    disc("arm_l", (-0.67, -0.08, 0.95), 0.12, 0.06, P["gold"], "X")
    for s, part in ((-1, "leg_l"), (1, "leg_r")):
        PIVOT[part] = (s * 0.17, 0, 0.55)
        tube(part, (s * 0.17, 0, 0.55), (s * 0.17, 0, 0.12), 0.11, 0.1, P["steel2"], 12)
        ball(part, (s * 0.17, -0.06, 0.1), 0.13, P["boot"], (1, 1.4, 0.7), 2, 0.0)
    SRGB_OUT = False
    finish("knight")


os.makedirs(OUT, exist_ok=True)
rat()
wolf()
knight()
