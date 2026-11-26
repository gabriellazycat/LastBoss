"""Rato e escudeiro do diorama, em feltro nas cores das cartas (escolhido em 26/11/2026): bonecos em partes rígidas,
cada parte um objeto com a origem na junta (quadril, ombro, pescoço). Bolhas fofas e irregulares de feltro, com as
cores e as formas da arte das cartas (rat_brute, rat_horde, hero_escudeiro). A animação não sai daqui: o
tools/art/import_dio.gd anima as partes pelo nome ("@quad", "@biped") e grava a VAT ou a cena do herói.
Olhos: um ponto de cor só, sem pupila nem brilho (regra dos modelos); o herói não tem olhos (elmo fechado).
"C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --factory-startup -P tools/art/blender_dio/characters.py -- <saída>
Grava <saída>/rat.glb e knight.glb, de frente para -Y do Blender (+Z no glTF).
Cor: o rato leva cor linear (o import_dio converte); o herói vai como cena e leva a cor já em sRGB."""
import math
import os
import sys

import bmesh
import bpy
from mathutils import Matrix, Vector, noise

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = argv[0] if argv else "."


def srgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))


def lin(h):
    return tuple(x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in srgb(h))


# Cores amostradas da arte das cartas (rat_brute, rat_horde, hero_escudeiro), em sRGB.
P = {"rat": "#7e93a5", "rat2": "#b2bec4", "rat3": "#5d6874", "pink": "#eaa9ab", "pink2": "#d68e93",
     "eye": "#2b2a33", "tooth": "#f1e6cf",
     "steel": "#a6afb9", "steel2": "#7f8a98", "steel3": "#6f7a88", "tabard": "#5689b8", "tabard2": "#3c6690",
     "leather": "#7a5a42", "boot": "#5f4a3c", "visor": "#2a2e38", "blade": "#dfe4e8", "shield": "#7f97ad",
     "shield2": "#5c7590", "gold": "#d8b46a"}

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
        k = 1.0 + noise.noise(v * 4.0) * 0.08   # fibra: leve variação de cor da lã
        ca.data[li].color = (c[0] * k, c[1] * k, c[2] * k, 1.0)
    for p in me.polygons:
        p.use_smooth = True
    GROUPS.setdefault(part, []).append(o)
    return o


def ball(part, c, r, col, sc=(1, 1, 1), sub=3, bump=None):
    bump = 0.12 if bump is None else bump   # feltro: superfície fofa e irregular
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
    return _mesh_obj(bm, part, col)


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
    """Ratazana das cartas: corpo de gota corpulento cinza-azulado, barriga mais clara, orelhas grandes rosa por
    dentro, focinho rosa, olhos de ponto, rabo rosa comprido em curva e patinhas rosa."""
    reset()
    PIVOT["body"] = (0, 0, 0.42)
    ball("body", (0, 0.08, 0.46), 0.46, P["rat"], (0.92, 1.3, 0.86))
    ball("body", (0, 0.28, 0.6), 0.34, P["rat"], (0.95, 1.0, 0.8))        # lombo alto atrás, como na carta
    ball("body", (0, -0.12, 0.3), 0.3, P["rat2"], (0.8, 1.05, 0.55))      # barriga clara
    PIVOT["head"] = (0, -0.38, 0.52)
    ball("head", (0, -0.62, 0.5), 0.3, P["rat"], (0.95, 1.05, 0.9))
    ball("head", (0, -0.86, 0.43), 0.17, P["rat"], (0.85, 1.25, 0.8))     # focinho
    ball("head", (0, -0.86, 0.36), 0.12, P["rat2"], (0.85, 1.1, 0.6))
    ball("head", (0, -1.04, 0.45), 0.06, P["pink"], (1.2, 1, 0.9), 2, 0.0)         # nariz
    ball("head", (0, -0.98, 0.3), 0.045, P["tooth"], (1.3, 0.5, 1.3), 2, 0.0)      # dentes da frente
    for sx in (-1, 1):
        # orelha: concha grande, cinza por fora e rosa por dentro, virada para a frente e para o lado
        ball("head", (sx * 0.22, -0.5, 0.8), 0.17, P["rat"], (1.0, 0.35, 1.15), 3, 0.0)
        ball("head", (sx * 0.22, -0.56, 0.8), 0.12, P["pink"], (0.95, 0.25, 1.05), 3, 0.0)
    eyes("head", 0.14, -0.83, 0.59, 0.05)
    PIVOT["tail"] = (0, 0.6, 0.42)
    pts = [(0, 0.6, 0.42), (0, 0.92, 0.33), (0.14, 1.24, 0.3), (0.34, 1.52, 0.36), (0.5, 1.74, 0.48), (0.56, 1.88, 0.62)]
    for i in range(len(pts) - 1):
        tube("tail", pts[i], pts[i + 1], 0.07 - i * 0.012, 0.06 - i * 0.012, P["pink"], 10)
        if i > 0:
            ball("tail", pts[i], 0.065 - i * 0.012, P["pink"], (1, 1, 1), 2, 0.0)       # emenda lisa
    for x, y, part in ((-0.24, -0.3, "leg_fl"), (0.24, -0.3, "leg_fr"), (-0.26, 0.36, "leg_bl"), (0.26, 0.36, "leg_br")):
        PIVOT[part] = (x, y, 0.3)
        ball(part, (x, y, 0.18), 0.12, P["rat"], (0.9, 1.1, 1.1))
        ball(part, (x, y - 0.06, 0.04), 0.08, P["pink"], (1.1, 1.5, 0.5), 2, 0.0)
    finish("rat")


# ---------------------------------------------------------------- escudeiro (herói)

def kite(part, c, w, h, t, col, col2):
    """Escudo de bico (como o da carta): arredondado em cima e em ponta embaixo, no plano YZ, com borda."""
    def shape(sc, dx, colr, th):
        bm = bmesh.new()
        pts = []
        for i in range(9):
            a = math.pi * i / 8
            pts.append((math.cos(a) * w * 0.5 * sc, h * 0.1 + math.sin(a) * h * 0.22 * sc))
        pts.append((-w * 0.47 * sc, -h * 0.12 * sc))
        pts.append((-w * 0.3 * sc, -h * 0.42 * sc))
        pts.append((0.0, -h * 0.62 * sc))
        pts.append((w * 0.3 * sc, -h * 0.42 * sc))
        pts.append((w * 0.47 * sc, -h * 0.12 * sc))
        pts = [pts[0]] + list(reversed(pts[1:]))
        front = [bm.verts.new((c[0] + dx - th / 2, c[1] + u, c[2] + v)) for (u, v) in pts]
        back = [bm.verts.new((c[0] + dx + th / 2, c[1] + u, c[2] + v)) for (u, v) in pts]
        bm.faces.new(front)
        bm.faces.new(list(reversed(back)))
        n = len(pts)
        for i in range(n):
            bm.faces.new((front[i], front[(i + 1) % n], back[(i + 1) % n], back[i]))
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        o = _mesh_obj(bm, part, colr)
        bv = o.modifiers.new("b", "BEVEL")
        bv.width = th * 0.3
        bv.segments = 2
        bv.limit_method = "ANGLE"
        return o
    shape(1.0, 0.0, col2, t)
    shape(0.84, -t * 0.55, col, t * 0.4)


def knight():
    """Escudeiro das cartas: armadura de aço inteira, tabardo azul com cinto de couro, elmo fechado com o visor
    escuro (sem olhos), escudo de bico azulado no braço esquerdo e espada longa na mão direita. Um pouco cabeçudo."""
    global SRGB_OUT
    reset()
    SRGB_OUT = True
    PIVOT["body"] = (0, 0, 0.78)
    tube("body", (0, 0, 0.66), (0, 0, 1.36), 0.3, 0.34, P["steel"], 20)            # peitoral
    ball("body", (0, 0, 1.36), 0.34, P["steel"], (1, 0.9, 0.45))
    tube("body", (0, 0, 0.5), (0, 0, 1.28), 0.37, 0.33, P["tabard"], 20)            # tabardo azul
    tube("body", (0, 0, 0.46), (0, 0, 0.52), 0.375, 0.37, P["tabard2"], 20)         # barra do tabardo
    tube("body", (0, 0, 0.9), (0, 0, 0.99), 0.36, 0.355, P["leather"], 20)          # cinto
    block("body", (-0.07, -0.38, 0.89), (0.07, -0.33, 1.0), P["gold"], 0.012)       # fivela
    for sx in (-1, 1):
        ball("body", (sx * 0.38, 0, 1.3), 0.17, P["steel"], (1.1, 1.0, 0.85))   # ombreiras
    PIVOT["head"] = (0, 0, 1.45)
    tube("head", (0, 0, 1.5), (0, 0, 1.98), 0.3, 0.3, P["steel"], 20)               # elmo de balde, um pouco grande
    ball("head", (0, 0, 1.96), 0.3, P["steel"], (1, 1, 0.72), 3, 0.0)   # topo do elmo em cúpula
    tube("head", (0, 0, 1.46), (0, 0, 1.53), 0.33, 0.33, P["steel2"], 20)           # gorjal
    block("head", (-0.19, -0.31, 1.72), (0.19, -0.24, 1.81), P["visor"], 0.015)     # fresta do visor
    block("head", (-0.035, -0.32, 1.56), (0.035, -0.26, 1.85), P["steel2"], 0.012)  # nervura do nariz
    for s, part in ((-1, "arm_l"), (1, "arm_r")):
        PIVOT[part] = (s * 0.4, 0, 1.25)
        tube(part, (s * 0.42, 0, 1.24), (s * 0.48, -0.04, 0.86), 0.1, 0.09, P["steel2"], 12)
        ball(part, (s * 0.49, -0.06, 0.8), 0.1, P["steel3"], (1, 1, 1), 2, 0.0)    # manopla
    # espada longa na mão direita (aponta para a frente), guarda e punho de couro
    block("arm_r", (0.46, -1.15, 0.77), (0.52, -0.2, 0.83), P["blade"], 0.015)
    block("arm_r", (0.36, -0.2, 0.74), (0.62, -0.14, 0.86), P["steel3"], 0.015)
    block("arm_r", (0.465, -0.14, 0.775), (0.515, 0.08, 0.825), P["leather"], 0.01)
    ball("arm_r", (0.49, 0.1, 0.8), 0.04, P["steel3"], (1, 1, 1), 2, 0.0)
    kite("arm_l", (-0.62, -0.06, 0.92), 0.62, 0.95, 0.07, P["shield"], P["shield2"])
    for s, part in ((-1, "leg_l"), (1, "leg_r")):
        PIVOT[part] = (s * 0.16, 0, 0.55)
        tube(part, (s * 0.16, 0, 0.55), (s * 0.16, 0, 0.12), 0.11, 0.1, P["steel2"], 12)
        ball(part, (s * 0.16, -0.02, 0.36), 0.1, P["steel"], (1, 1, 0.8), 2, 0.0)  # joelheira
        ball(part, (s * 0.16, -0.06, 0.08), 0.12, P["boot"], (1, 1.45, 0.65), 2, 0.0)
    SRGB_OUT = False
    finish("knight")


os.makedirs(OUT, exist_ok=True)
rat()
knight()
